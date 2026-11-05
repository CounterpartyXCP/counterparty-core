"""Pinned Waitress fixtures use only ephemeral loopback sockets, no backend."""

import json
import socket
from contextlib import contextmanager
from dataclasses import asdict
from types import SimpleNamespace
from unittest.mock import Mock

import pytest
from counterpartycore.lib.api import admission, wsgi
from waitress import server as waitress_server
from waitress import wasyncore


@contextmanager
def listener(count=1, connection_limit=100):
    sockets = []
    server = None
    socket_map = {}
    try:
        for _ in range(count):
            sock = socket.socket()
            sockets.append(sock)
            sock.bind(("127.0.0.1", 0))
        server = waitress_server.create_server(
            lambda environ, start_response: [],
            sockets=sockets,
            map=socket_map,
            threads=1,
            connection_limit=connection_limit,
        )
        yield server
    finally:
        if server is not None:
            server.task_dispatcher.shutdown()
        wasyncore.close_all(socket_map)
        for sock in sockets:
            sock.close()


def test_real_idle_workers_can_have_connection_admission_pressure():
    clients = []
    with listener(connection_limit=4) as server:
        try:
            initial = admission.sample(server)
            assert initial.accepted_channels == 0
            assert initial.socket_map_entries == 2  # listener + wakeup trigger
            for _ in range(2):
                client = socket.create_connection(server.socket.getsockname(), timeout=1)
                clients.append(client)
                server.handle_accept()
            metrics = admission.sample(server)
            assert metrics.accepted_channels == 2
            assert metrics.socket_map_entries == 4
            assert metrics.at_limit_listeners == 1
            # The event loop has not latched overflow yet; sampling must not do it.
            assert metrics.overflow_listeners == 0
            assert server.task_dispatcher.active_count == 0
            assert len(server.task_dispatcher.queue) == 0
            assert server.readable() is False
            metrics = admission.sample(server)
            assert metrics.accepting_listeners == 1
            assert metrics.overflow_listeners == 1
        finally:
            for client in clients:
                client.close()


def test_shared_multi_listener_map_is_not_double_counted():
    with listener(count=2) as server:
        assert isinstance(server, waitress_server.MultiSocketServer)
        metrics = admission.sample(server)
        assert metrics.listeners == 2
        assert metrics.socket_map_entries == len(server.map) == 4
        assert metrics.connection_limit == 100  # not 200
        assert metrics.accepting_listeners == 2
        listeners = [
            v for v in server.map.values() if isinstance(v, waitress_server.BaseWSGIServer)
        ]
        # Also handle shared channel maps without inventing additional channels.
        listeners[0].active_channels[123] = object()
        listeners[1].active_channels = listeners[0].active_channels
        assert admission.sample(server).accepted_channels == 1
        listeners[0].active_channels.clear()  # remove fixture-only object before shutdown


@pytest.mark.parametrize(
    "attribute,value",
    [
        ("active_channels", None),
        ("_map", None),
        ("accepting", 1),
        ("in_connection_overflow", None),
        ("adj", SimpleNamespace(connection_limit=0)),
        ("adj", SimpleNamespace(connection_limit=True)),
    ],
)
def test_changed_introspection_is_unknown(attribute, value):
    with listener() as server:
        original = getattr(server, attribute)
        try:
            setattr(server, attribute, value)
            assert admission.sample(server) is None
        finally:
            setattr(server, attribute, original)


def test_unsupported_absent_and_closed_multi_listener_are_unknown():
    assert admission.sample(None) is None
    assert admission.sample(object()) is None
    assert admission.sample(object.__new__(waitress_server.BaseWSGIServer)) is None
    with listener(count=2) as server:
        server.close()
        assert admission.sample(server) is None


def test_unexpected_listener_topology_is_bounded_and_unknown():
    server = object.__new__(waitress_server.MultiSocketServer)
    listener_object = object.__new__(waitress_server.BaseWSGIServer)
    server.map = dict.fromkeys(range(17), listener_object)
    assert admission.sample(server) is None


def test_different_multi_listener_limits_do_not_invent_a_capacity():
    with listener(count=2) as server:
        listeners = [
            v for v in server.map.values() if isinstance(v, waitress_server.BaseWSGIServer)
        ]
        listeners[0].adj = SimpleNamespace(connection_limit=10)
        assert admission.sample(server) is None


def test_counts_only_and_no_call_to_readable_or_channel_contents():
    with listener() as server:
        server.readable = Mock(side_effect=AssertionError("must not mutate the listener"))
        server.active_channels[456] = object()
        serialized = json.dumps(asdict(admission.sample(server)))
        assert "127.0.0.1" not in serialized
        assert "456" not in serialized
        assert "socket_map_entries" in serialized
        server.readable.assert_not_called()
        server.active_channels.clear()


def test_wsgi_delegates_only_for_waitress():
    wrapper = object.__new__(wsgi.WSGIApplication)
    wrapper.server = object()
    assert wrapper.get_admission_metrics() is None
    backend = object.__new__(wsgi.WaitressApplication)
    wrapper.server = backend
    with listener() as server:
        backend.server = server
        assert wrapper.get_admission_metrics() == admission.sample(server)
