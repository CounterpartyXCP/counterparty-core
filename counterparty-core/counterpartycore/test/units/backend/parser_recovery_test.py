"""No live node, database or network is required by these recovery tests."""

import http.client
import json
import multiprocessing
import time
from types import SimpleNamespace
from unittest.mock import MagicMock

import pytest
from counterpartycore.lib.api import apiserver, healthz_server
from counterpartycore.lib.utils import parserhealth


@pytest.fixture(autouse=True)
def clear_progress():
    parserhealth.configure(None)
    yield
    parserhealth.configure(None)


def sampler(progress, **overrides):
    kwargs = dict(
        last_parsed_provider=lambda: 100,
        backend_height_provider=lambda: 100,
        block_time_provider=lambda: None,
        api_only_provider=lambda: False,
        serving_provider=lambda: True,
        mempool_progress_provider=lambda: progress.value,
    )
    kwargs.update(overrides)
    return healthz_server.HealthSampler(**kwargs)


def live(health):
    handler = SimpleNamespace(server=SimpleNamespace(sampler=health))
    return healthz_server.HealthRequestHandler._liveness(handler)


def test_stuck_mempool_fails_liveness_even_when_sampler_and_api_are_alive(monkeypatch):
    now = [1000.0]
    monkeypatch.setattr(parserhealth.time, "monotonic", lambda: now[0])
    shared = multiprocessing.get_context("spawn").Value("d", 0)
    parserhealth.configure(shared)
    health = sampler(shared)
    parserhealth.begin()
    health._tick()
    assert live(health)[0] == 200
    now[0] += 121
    health._tick()  # sampler remains alive; backend is still at the same tip
    assert live(health)[1]["reason"] == "mempool_parser_stalled"
    parserhealth.finish()  # rollback/completion disarms the signal
    health._tick()
    assert live(health)[0] == 200


def test_progressing_batch_can_exceed_total_timeout(monkeypatch):
    now = [1000.0]
    monkeypatch.setattr(parserhealth.time, "monotonic", lambda: now[0])
    shared = SimpleNamespace(value=0)
    parserhealth.configure(shared)
    health = sampler(shared)
    parserhealth.begin()
    for _ in range(10):
        now[0] += 100
        parserhealth.progress()
        health._tick()
        assert live(health)[0] == 200


@pytest.mark.parametrize("mode", ["idle", "confirmed", "starting", "rebuilding", "api_only"])
def test_legitimate_long_operations_do_not_trigger_recovery(monkeypatch, mode):
    now = [1000.0]
    monkeypatch.setattr(parserhealth.time, "monotonic", lambda: now[0])
    # A stale signal is explicitly ignored in API lifecycle/maintenance modes.
    shared = SimpleNamespace(value=1000.0 if mode in ("starting", "rebuilding", "api_only") else 0)
    health = sampler(
        shared,
        serving_provider=lambda: mode != "starting",
        api_only_provider=lambda: mode == "api_only",
        backend_height_provider=lambda: 200 if mode == "confirmed" else 100,
    )
    monkeypatch.setattr(
        healthz_server.dbstatus, "current", lambda: MagicMock() if mode == "rebuilding" else None
    )
    now[0] += 3600
    health._tick()
    assert live(health)[0] == 200


def _read_shared_timestamp(shared, result, proceed):
    result.put("ready")
    proceed.wait(timeout=10)
    result.put(shared.value)


def test_progress_signal_survives_spawn():
    context = multiprocessing.get_context("spawn")
    shared = context.Value("d", 0)
    parserhealth.configure(shared)
    parserhealth.begin()
    result = context.Queue()
    proceed = context.Event()
    child = context.Process(target=_read_shared_timestamp, args=(shared, result, proceed))
    child.start()
    try:
        assert result.get(timeout=10) == "ready"
        shared.value = 42.0  # Must be visible after spawn, not a copied startup value.
        proceed.set()
        assert result.get(timeout=10) == shared.value
        child.join(timeout=10)
        assert child.exitcode == 0
    finally:
        if child.is_alive():
            child.terminate()
            child.join(timeout=5)
        result.close()


def test_api_process_receives_shared_progress(monkeypatch):
    factory = MagicMock()
    monkeypatch.setattr(apiserver, "Process", factory)
    shared = multiprocessing.get_context("spawn").Value("d", 0)
    api = apiserver.APIServer(MagicMock(), MagicMock(), mempool_progress=shared)
    api.start(SimpleNamespace(), None)
    assert factory.call_args.kwargs["args"][-1] is shared
    assert factory.call_args.kwargs["target"] is apiserver.run_apiserver


def test_live_http_listener_detects_stall_and_recovers_without_height_change(monkeypatch):
    shared = multiprocessing.get_context("spawn").Value("d", 0)
    real_sampler = healthz_server.HealthSampler

    def isolated_sampler(**kwargs):
        return real_sampler(
            last_parsed_provider=lambda: 100,
            backend_height_provider=lambda: 100,
            block_time_provider=lambda: None,
            api_only_provider=lambda: False,
            **kwargs,
        )

    monkeypatch.setattr(healthz_server, "HealthSampler", isolated_sampler)
    server = healthz_server.HealthCheckServer(
        "127.0.0.1", 0, mempool_progress_provider=lambda: shared.value
    )
    server.start()
    try:
        assert server.httpd is not None

        def assert_response(expected, reason):
            deadline = time.monotonic() + 5
            while time.monotonic() < deadline:
                connection = http.client.HTTPConnection(
                    "127.0.0.1", server.httpd.server_address[1], timeout=1
                )
                try:
                    connection.request("GET", "/healthz/live")
                    response = connection.getresponse()
                    body = json.loads(response.read())
                    if response.status == expected:
                        assert body.get("reason", body["status"]) == reason
                        return
                finally:
                    connection.close()
                time.sleep(0.05)
            pytest.fail(f"health listener did not return {expected} {reason}")

        assert_response(200, "alive")
        shared.value = time.monotonic() - parserhealth.STALL_TIMEOUT_SECONDS - 1
        assert_response(503, "mempool_parser_stalled")
        shared.value = 0
        assert_response(200, "alive")
    finally:
        server.stop()
