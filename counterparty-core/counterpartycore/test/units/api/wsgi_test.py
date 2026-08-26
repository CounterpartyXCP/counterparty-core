import errno
import os
import threading
import time
from types import SimpleNamespace
from unittest.mock import MagicMock

import pytest
from counterpartycore.lib.api import wsgi


def test_format_bind_address():
    assert wsgi.format_bind_address("127.0.0.1", 4000) == "127.0.0.1:4000"
    assert wsgi.format_bind_address("localhost", 4000) == "localhost:4000"
    assert wsgi.format_bind_address("::1", 4000) == "[::1]:4000"
    assert wsgi.format_bind_address("::", 4000) == "[::]:4000"


def test_lazy_logger(caplog, test_helpers):
    lazy_logger = wsgi.LazyLogger()
    assert lazy_logger.last_message is None
    assert lazy_logger.last_print == 0
    assert lazy_logger.message_delay == 10

    with test_helpers.capture_log(caplog, "Coucou"):
        lazy_logger.debug("Coucou")
    assert lazy_logger.last_message == "Coucou"
    assert lazy_logger.last_print > 0
    last_print = lazy_logger.last_print

    caplog.clear()
    with test_helpers.capture_log(caplog, "Coucou", not_in=True):
        lazy_logger.debug("Coucou")
    assert lazy_logger.last_message == "Coucou"
    assert lazy_logger.last_print == last_print

    lazy_logger.message_delay = 0.1
    time.sleep(0.2)

    caplog.clear()
    with test_helpers.capture_log(caplog, "Coucou"):
        lazy_logger.debug("Coucou")
    assert lazy_logger.last_print > last_print
    last_print = lazy_logger.last_print

    with test_helpers.capture_log(caplog, "Hello", not_in=True):
        lazy_logger.debug("Hello")
    assert lazy_logger.last_print == last_print

    time.sleep(0.2)
    with test_helpers.capture_log(caplog, "Hello"):
        lazy_logger.debug("Hello")
    assert lazy_logger.last_print > last_print


def test_refresh_current_state_api_only(monkeypatch):
    shared_backend_height = SimpleNamespace(value=0)
    monkeypatch.setattr(wsgi.apiwatcher, "get_last_block_parsed", lambda _db: 7)
    monkeypatch.setattr(wsgi.CurrentState, "set_current_block_index", lambda _self, _idx: None)
    monkeypatch.setattr(wsgi.CurrentState, "current_block_index", lambda _self: 7)
    monkeypatch.setattr(wsgi.config, "API_ONLY", True)

    logger = wsgi.LazyLogger()
    logger.debug = MagicMock()

    wsgi.refresh_current_state(object(), shared_backend_height)

    logger.debug.assert_not_called()


def test_refresh_current_state_logs(monkeypatch):
    shared_backend_height = SimpleNamespace(value=int(5 * 10e8 + 100))
    monkeypatch.setattr(wsgi.apiwatcher, "get_last_block_parsed", lambda _db: 1)
    monkeypatch.setattr(wsgi.CurrentState, "set_current_block_index", lambda _self, _idx: None)
    monkeypatch.setattr(wsgi.CurrentState, "current_block_index", lambda _self: 1)
    monkeypatch.setattr(wsgi.config, "API_ONLY", False)
    monkeypatch.setattr(wsgi.config, "BLOCK_FIRST", 10)

    logger = wsgi.LazyLogger()
    logger.debug = MagicMock()

    wsgi.refresh_current_state(object(), shared_backend_height)
    assert logger.debug.call_count == 2

    logger.debug.reset_mock()
    shared_backend_height.value = int(1 * 10e8 + 50)
    monkeypatch.setattr(wsgi.CurrentState, "current_block_index", lambda _self: 5)
    monkeypatch.setattr(wsgi.config, "BLOCK_FIRST", 0)

    wsgi.refresh_current_state(object(), shared_backend_height)
    logger.debug.assert_called_once()


def test_node_status_checker_thread_run_and_stop(monkeypatch):
    closed = {"value": False}

    class DummyDB:
        def close(self):
            closed["value"] = True

    monkeypatch.setattr(wsgi.database, "get_db_connection", lambda _path: DummyDB())

    thread = wsgi.NodeStatusCheckerThread(SimpleNamespace(value=0))

    def fake_refresh(_state_db, _shared_backend_height):
        thread.stop_event.set()

    monkeypatch.setattr(wsgi, "refresh_current_state", fake_refresh)

    thread.run()

    assert closed["value"] is True


def test_node_status_checker_stop_interrupts_sqlite(monkeypatch):
    state_db = MagicMock()
    monkeypatch.setattr(wsgi.database, "get_db_connection", lambda _path: state_db)
    thread = wsgi.NodeStatusCheckerThread(SimpleNamespace(value=0))
    monkeypatch.setattr(thread, "is_alive", lambda: True)
    thread.join = MagicMock()

    thread.stop()

    state_db.interrupt.assert_called_once_with()
    thread.join.assert_called_once_with(timeout=2)


def test_node_status_checker_stop_tolerates_connection_closed_race(monkeypatch):
    state_db = MagicMock()
    state_db.interrupt.side_effect = wsgi.apsw.ConnectionClosedError("closed")
    monkeypatch.setattr(wsgi.database, "get_db_connection", lambda _path: state_db)
    thread = wsgi.NodeStatusCheckerThread(SimpleNamespace(value=0))
    monkeypatch.setattr(thread, "is_alive", lambda: True)
    thread.join = MagicMock()

    thread.stop()

    thread.join.assert_called_once_with(timeout=2)


def test_node_status_checker_handles_shutdown_interrupt(monkeypatch):
    state_db = MagicMock()
    monkeypatch.setattr(wsgi.database, "get_db_connection", lambda _path: state_db)
    thread = wsgi.NodeStatusCheckerThread(SimpleNamespace(value=0))

    def interrupted_refresh(_state_db, _shared_backend_height):
        thread.stop_event.set()
        raise wsgi.apsw.InterruptError("interrupted")

    monkeypatch.setattr(wsgi, "refresh_current_state", interrupted_refresh)

    thread.run()

    state_db.close.assert_called_once_with()


def test_werkzeug_application_run_and_stop(monkeypatch):
    server_ready_value = SimpleNamespace(value=0)
    shared_backend_height = SimpleNamespace(value=0)

    class DummyServer:
        def __init__(self):
            self.served = False
            self.shutdown_called = False
            self.closed = False

        def serve_forever(self):
            self.served = True

        def shutdown(self):
            self.shutdown_called = True

        def server_close(self):
            self.closed = True

    class DummyThread:
        def __init__(self, _shared_backend_height):
            self.started = False
            self.stopped = False

        def start(self):
            self.started = True

        def stop(self, deadline=None):
            self.stopped = True

    dummy_server = DummyServer()

    monkeypatch.setattr(wsgi, "make_server", lambda *_args, **_kwargs: dummy_server)
    monkeypatch.setattr(wsgi, "NodeStatusCheckerThread", DummyThread)
    monkeypatch.setattr(wsgi.CurrentState, "set_backend_height_value", lambda _self, _value: None)

    app = wsgi.WerkzeugApplication(lambda *_args, **_kwargs: None)
    app.run(server_ready_value, shared_backend_height)
    assert dummy_server.served is True

    app.stop()
    assert dummy_server.shutdown_called is True
    assert dummy_server.closed is True
    assert server_ready_value.value == 2


def test_waitress_application_run_ignores_bad_fd(monkeypatch):
    server_ready_value = SimpleNamespace(value=0)
    shared_backend_height = SimpleNamespace(value=0)

    class DummyServer:
        def __init__(self):
            self.closed = False

        def run(self):
            raise OSError(errno.EBADF, "Bad file descriptor")

        def close(self):
            self.closed = True

    class DummyThread:
        def __init__(self, _shared_backend_height):
            self.started = False
            self.stopped = False

        def start(self):
            self.started = True

        def stop(self, deadline=None):
            self.stopped = True

    dummy_server = DummyServer()

    monkeypatch.setattr(
        wsgi.waitress.server, "create_server", lambda *_args, **_kwargs: dummy_server
    )
    monkeypatch.setattr(wsgi, "NodeStatusCheckerThread", DummyThread)
    monkeypatch.setattr(wsgi.CurrentState, "set_backend_height_value", lambda _self, _value: None)

    app = wsgi.WaitressApplication(lambda *_args, **_kwargs: None)
    app.run(server_ready_value, shared_backend_height)

    app.stop()
    assert dummy_server.closed is True
    assert server_ready_value.value == 2


def test_wsgi_application_selects_server(monkeypatch):
    monkeypatch.setattr(wsgi.config, "WSGI_SERVER", "werkzeug")
    app = wsgi.WSGIApplication(lambda *_args, **_kwargs: None)
    assert isinstance(app.server, wsgi.WerkzeugApplication)

    monkeypatch.setattr(wsgi.config, "WSGI_SERVER", "gunicorn")
    app = wsgi.WSGIApplication(lambda *_args, **_kwargs: None)
    assert isinstance(app.server, wsgi.GunicornApplication)

    monkeypatch.setattr(wsgi.config, "WSGI_SERVER", "waitress")
    app = wsgi.WSGIApplication(lambda *_args, **_kwargs: None)
    assert isinstance(app.server, wsgi.WaitressApplication)


def test_gunicorn_application_run_and_stop(monkeypatch):
    server_ready_value = SimpleNamespace(value=0)
    shared_backend_height = SimpleNamespace(value=0)

    class DummyThread:
        def __init__(self, _shared_backend_height):
            self.started = False
            self.stopped = False

        def start(self):
            self.started = True

        def stop(self, deadline=None):
            self.stopped = True

    class DummyArbiter:
        def __init__(self, app):
            self.app = app
            self.run_called = False
            self.killed = False

        def run(self):
            self.run_called = True

        def kill_all_workers(self, deadline=None):
            self.killed = True

    monkeypatch.setattr(wsgi, "NodeStatusCheckerThread", DummyThread)
    monkeypatch.setattr(wsgi, "GunicornArbiter", DummyArbiter)
    monkeypatch.setattr(wsgi.CurrentState, "set_backend_height_value", lambda _self, _value: None)

    app = wsgi.GunicornApplication(lambda *_args, **_kwargs: None)
    app.load_config()
    app.run(server_ready_value, shared_backend_height)
    assert isinstance(app.arbiter, DummyArbiter)
    assert app.arbiter.run_called is True

    app.stop()
    assert app.arbiter.killed is True
    assert server_ready_value.value == 2


def test_node_status_checker_is_a_daemon_thread(monkeypatch):
    """Same reason as APIWatcher: without this the bounded join below bounds
    nothing, because a surviving non-daemon thread blocks interpreter shutdown."""
    monkeypatch.setattr(wsgi.database, "get_db_connection", lambda _path: MagicMock())

    thread = wsgi.NodeStatusCheckerThread(SimpleNamespace(value=0))

    assert thread.daemon is True


def test_node_status_checker_stop_does_not_interrupt_a_connection_being_closed(monkeypatch):
    """apsw calls sqlite3_interrupt() holding the GIL, but close() releases it
    around sqlite3_close_v2(): an unsynchronised interrupt can reach a handle
    that is already being freed, so the two must never overlap."""
    state_db = MagicMock()
    monkeypatch.setattr(wsgi.database, "get_db_connection", lambda _path: state_db)

    thread = wsgi.NodeStatusCheckerThread(SimpleNamespace(value=0))
    monkeypatch.setattr(
        wsgi, "refresh_current_state", lambda *_args, **_kwargs: thread.stop_event.set()
    )

    closing = threading.Event()
    in_close = threading.Event()
    overlapped = []

    def slow_close():
        closing.set()
        in_close.set()
        time.sleep(0.05)
        in_close.clear()

    state_db.close.side_effect = slow_close
    state_db.interrupt.side_effect = lambda: overlapped.append(in_close.is_set())

    thread.start()
    assert closing.wait(timeout=5), "checker never reached its close"
    thread.stop(deadline=time.monotonic() + 5)

    assert not thread.is_alive()
    # The interrupt waited for the close to finish. Without the lock it runs
    # immediately and sees a close in flight.
    assert overlapped == [False]


def test_gunicorn_stop_reserves_budget_for_the_workers(monkeypatch):
    """A checker that ignores its interrupt must not leave the workers a
    zero-second grace period, which would SIGKILL every in-flight request."""
    app = wsgi.GunicornApplication.__new__(wsgi.GunicornApplication)
    app.current_state_thread = MagicMock()
    app.arbiter = MagicMock()
    app.master_pid = os.getpid()
    app.server_ready_value = SimpleNamespace(value=0)

    deadline = time.monotonic() + 9
    app.stop(deadline=deadline)

    checker_deadline = app.current_state_thread.stop.call_args.kwargs["deadline"]
    assert checker_deadline < deadline
    # The workers keep the rest of the budget, not whatever the checker left over.
    assert app.arbiter.kill_all_workers.call_args.kwargs["deadline"] == deadline
    assert deadline - checker_deadline > 5


def test_gunicorn_stop_without_deadline_keeps_the_default(monkeypatch):
    app = wsgi.GunicornApplication.__new__(wsgi.GunicornApplication)
    app.current_state_thread = MagicMock()
    app.arbiter = MagicMock()
    app.master_pid = os.getpid()
    app.server_ready_value = SimpleNamespace(value=0)

    app.stop()

    assert app.current_state_thread.stop.call_args.kwargs["deadline"] is None
    assert app.arbiter.kill_all_workers.call_args.kwargs["deadline"] is None


def test_gunicorn_worker_shutdown_does_not_signal_workers_that_already_exited(monkeypatch):
    """The liveness check must run at least once even on an expired deadline,
    otherwise a clean stop is reported as an unresponsive one."""
    arbiter = wsgi.GunicornArbiter.__new__(wsgi.GunicornArbiter)
    arbiter.workers_pids = [101, 102]
    signals = []
    monkeypatch.setattr(wsgi.os, "waitpid", lambda pid, _flags: (pid, 0))
    monkeypatch.setattr(wsgi.os, "kill", lambda pid, sig: signals.append((pid, sig)))

    arbiter.kill_all_workers(deadline=time.monotonic() - 1)

    assert signals == [(101, wsgi.signal.SIGTERM), (102, wsgi.signal.SIGTERM)]
    assert arbiter.workers_pids == []


def test_gunicorn_worker_shutdown_reaps_zombies_instead_of_killing_them(monkeypatch):
    """Workers are our own children, so an exited one stays a zombie until it is
    reaped and `kill(pid, 0)` still reports it as alive. Waiting on liveness
    alone would burn the whole deadline and then SIGKILL processes already dead."""
    arbiter = wsgi.GunicornArbiter.__new__(wsgi.GunicornArbiter)
    arbiter.workers_pids = [101, 102]
    signals = []
    reaped = []

    def fake_waitpid(pid, _flags):
        reaped.append(pid)
        if pid == 102:
            # Already collected by the arbiter's own reap_workers.
            raise ChildProcessError(errno.ECHILD, "No child processes")
        return pid, 0

    monkeypatch.setattr(wsgi.os, "waitpid", fake_waitpid)
    monkeypatch.setattr(
        wsgi.helpers, "is_process_alive", lambda _pid: pytest.fail("zombies read as alive")
    )
    monkeypatch.setattr(wsgi.os, "kill", lambda pid, sig: signals.append((pid, sig)))

    arbiter.kill_all_workers(deadline=time.monotonic() + 5)

    assert reaped == [101, 102]
    assert signals == [(101, wsgi.signal.SIGTERM), (102, wsgi.signal.SIGTERM)]
    assert arbiter.workers_pids == []


def test_gunicorn_application_uses_ipv6_bind(monkeypatch):
    monkeypatch.setattr(wsgi.config, "API_HOST", "::1")
    monkeypatch.setattr(wsgi.config, "API_PORT", 4000)

    app = wsgi.GunicornApplication(lambda *_args, **_kwargs: None)

    assert app.options["bind"] == "[::1]:4000"


def test_gunicorn_worker_shutdown_escalates_at_deadline(monkeypatch):
    arbiter = wsgi.GunicornArbiter.__new__(wsgi.GunicornArbiter)
    arbiter.workers_pids = [101, 102]
    signals = []
    monkeypatch.setattr(wsgi.os, "waitpid", lambda _pid, _flags: (0, 0))
    monkeypatch.setattr(wsgi.os, "kill", lambda pid, sig: signals.append((pid, sig)))

    arbiter.kill_all_workers(deadline=time.monotonic())

    assert signals == [
        (101, wsgi.signal.SIGTERM),
        (102, wsgi.signal.SIGTERM),
        (101, wsgi.signal.SIGKILL),
        (102, wsgi.signal.SIGKILL),
    ]
    assert arbiter.workers_pids == []
