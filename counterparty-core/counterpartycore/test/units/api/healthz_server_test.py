"""Unit tests for the dedicated, isolated health-check listener (issue #3460).

These tests never start a real WSGI server or open a database: the sampler is driven with injected
providers and a fake task dispatcher, and the HTTP layer is exercised against a small in-process
``ThreadingHTTPServer`` bound to an ephemeral port.
"""

import http.client
import json
import socket
import threading
import time
from collections import deque

import pytest

from counterpartycore.lib import config
from counterpartycore.lib.api import healthz_server
from counterpartycore.lib.api.healthz_server import (
    HealthCheckServer,
    HealthRequestHandler,
    HealthSampler,
    HealthSnapshot,
)


class FakeDispatcher:
    """Mimics waitress' ThreadedTaskDispatcher introspection surface."""

    def __init__(self, total=2, busy=0, draining=0, queue_len=0, queue_wait=None):
        self.threads = set(range(total))
        self.active_count = busy
        self.stop_count = draining
        self.queue = deque()
        for _ in range(queue_len):
            task = type("Task", (), {})()
            if queue_wait is not None:
                task.healthz_enqueued_at = time.monotonic() - queue_wait
            self.queue.append(task)


def make_sampler(
    dispatcher=None,
    *,
    backend_height=100,
    last_parsed=100,
    block_time=None,
    api_only=False,
    saturation_grace=5,
):
    return HealthSampler(
        dispatcher=dispatcher,
        saturation_grace=saturation_grace,
        last_parsed_provider=lambda: last_parsed,
        backend_height_provider=lambda: backend_height,
        block_time_provider=lambda: block_time,
        api_only_provider=lambda: api_only,
    )


# --------------------------------------------------------------------------------------------
# Sampler: readiness ledger axis
# --------------------------------------------------------------------------------------------


def test_caught_up_when_within_lag():
    sampler = make_sampler(backend_height=100, last_parsed=100)
    sampler._tick()
    snap = sampler.current_snapshot()
    assert snap.ready is True
    assert snap.reason is None
    assert snap.lag == 0


def test_behind_backend_reports_degraded():
    sampler = make_sampler(backend_height=200, last_parsed=100, block_time=None)
    sampler._tick()
    snap = sampler.current_snapshot()
    assert snap.ready is False
    assert snap.reason == "behind_backend"
    assert snap.lag == 100


def test_recent_block_time_grace_keeps_ready():
    # Numerically behind, but the last parsed block is recent -> effectively at the tip.
    sampler = make_sampler(backend_height=200, last_parsed=100, block_time=time.time() - 5)
    sampler._tick()
    assert sampler.current_snapshot().ready is True


def test_starting_when_backend_height_unknown():
    sampler = make_sampler(backend_height=None, last_parsed=100)
    sampler._tick()
    snap = sampler.current_snapshot()
    assert snap.ready is False
    assert snap.reason == "starting"


def test_api_only_skips_lag_axis():
    # backend_height is 0 in API_ONLY mode; readiness must still be True (serving a static ledger).
    sampler = make_sampler(api_only=True, backend_height=0, last_parsed=999)
    sampler._tick()
    snap = sampler.current_snapshot()
    assert snap.ready is True
    assert snap.reason is None
    assert snap.backend_height is None


# --------------------------------------------------------------------------------------------
# Sampler: saturation axis
# --------------------------------------------------------------------------------------------


def test_saturation_below_grace_stays_ready():
    disp = FakeDispatcher(total=2, busy=2, queue_len=3)
    sampler = make_sampler(dispatcher=disp, saturation_grace=5)
    sampler._tick()  # saturation just started -> duration ~0 < grace
    snap = sampler.current_snapshot()
    assert snap.saturated is True
    assert snap.ready is True  # ledger caught up, saturation not yet sustained
    assert snap.reason is None


def test_saturation_beyond_grace_reports_degraded():
    disp = FakeDispatcher(total=2, busy=2, queue_len=3)
    sampler = make_sampler(dispatcher=disp, saturation_grace=5)
    sampler._tick()
    # Simulate the pool having been saturated for longer than the grace without sleeping.
    sampler._saturated_since = time.monotonic() - 10
    sampler._tick()
    snap = sampler.current_snapshot()
    assert snap.saturated is True
    assert snap.saturation_seconds >= 5
    assert snap.ready is False
    assert snap.reason == "saturated"


def test_saturation_resets_when_pool_drains():
    disp = FakeDispatcher(total=2, busy=2, queue_len=3)
    sampler = make_sampler(dispatcher=disp, saturation_grace=5)
    sampler._tick()
    sampler._saturated_since = time.monotonic() - 10
    sampler._tick()
    assert sampler.current_snapshot().ready is False
    # Pool drains: queue empties.
    disp.queue.clear()
    sampler._tick()
    snap = sampler.current_snapshot()
    assert snap.saturated is False
    assert snap.saturation_seconds == 0.0
    assert snap.ready is True


def test_saturation_grace_zero_disables_axis():
    disp = FakeDispatcher(total=2, busy=2, queue_len=3)
    sampler = make_sampler(dispatcher=disp, saturation_grace=0)
    sampler._tick()
    sampler._saturated_since = time.monotonic() - 100
    sampler._tick()
    snap = sampler.current_snapshot()
    assert snap.saturated is True
    assert snap.ready is True  # saturation axis disabled -> never sheds


def test_no_dispatcher_reports_no_worker_metrics():
    sampler = make_sampler(dispatcher=None)
    sampler._tick()
    snap = sampler.current_snapshot()
    assert snap.workers is None
    assert snap.ready is True  # saturation axis unavailable, ledger axis governs


def test_worker_metrics_and_queue_wait():
    disp = FakeDispatcher(total=4, busy=3, draining=0, queue_len=2, queue_wait=1.5)
    sampler = make_sampler(dispatcher=disp)
    sampler._tick()
    workers = sampler.current_snapshot().workers
    assert workers.total == 4
    assert workers.busy == 3
    assert workers.idle == 1
    assert workers.queue_depth == 2
    assert workers.queue_head_wait is not None and workers.queue_head_wait >= 1.5


# --------------------------------------------------------------------------------------------
# HTTP layer
# --------------------------------------------------------------------------------------------


class FakeSampler:
    def __init__(self, snapshot, heartbeat_age=0.0, liveness_heartbeat_timeout=30):
        self._snapshot = snapshot
        self._heartbeat_age = heartbeat_age
        self.liveness_heartbeat_timeout = liveness_heartbeat_timeout

    def current_snapshot(self):
        return self._snapshot

    def heartbeat_age(self):
        return self._heartbeat_age


def _ready_snapshot():
    return HealthSnapshot(
        ready=True,
        reason=None,
        backend_height=100,
        last_parsed=100,
        lag=0,
        saturated=False,
        saturation_seconds=0.0,
        workers=healthz_server.WorkerMetrics(2, 0, 2, 0, 0, None),
    )


def _degraded_snapshot(reason="behind_backend"):
    return HealthSnapshot(
        ready=False,
        reason=reason,
        backend_height=200,
        last_parsed=100,
        lag=100,
        saturated=(reason == "saturated"),
        saturation_seconds=7.0 if reason == "saturated" else 0.0,
        workers=None,
    )


class _HttpServerFixture:
    def __init__(self, sampler):
        self.httpd = healthz_server.ThreadingHTTPServer(("127.0.0.1", 0), HealthRequestHandler)
        self.httpd.daemon_threads = True
        self.httpd.sampler = sampler
        self.httpd.started_at_monotonic = time.monotonic()
        self.httpd.live_latencies_ms = deque(maxlen=256)
        self.httpd.ready_latencies_ms = deque(maxlen=256)
        self.port = self.httpd.server_address[1]
        self.thread = threading.Thread(target=self.httpd.serve_forever, daemon=True)
        self.thread.start()

    def get(self, path):
        conn = http.client.HTTPConnection("127.0.0.1", self.port, timeout=5)
        conn.request("GET", path)
        resp = conn.getresponse()
        body = json.loads(resp.read().decode())
        code = resp.status
        conn.close()
        return code, body

    def close(self):
        self.httpd.shutdown()
        self.httpd.server_close()
        self.thread.join(timeout=5)


@pytest.fixture
def ready_server():
    fx = _HttpServerFixture(FakeSampler(_ready_snapshot()))
    yield fx
    fx.close()


def test_http_liveness_ok(ready_server):
    code, body = ready_server.get("/healthz/live")
    assert code == 200
    assert body == {"status": "alive"}


def test_http_liveness_stale_heartbeat_is_unhealthy():
    fx = _HttpServerFixture(
        FakeSampler(_ready_snapshot(), heartbeat_age=100, liveness_heartbeat_timeout=30)
    )
    try:
        code, body = fx.get("/healthz/live")
        assert code == 503
        assert body["reason"] == "heartbeat_stale"
    finally:
        fx.close()


def test_http_readiness_ok(ready_server):
    for path in ("/healthz", "/healthz/ready"):
        code, body = ready_server.get(path)
        assert code == 200
        assert body == {"status": "ready"}


def test_http_readiness_degraded_behind_backend():
    fx = _HttpServerFixture(FakeSampler(_degraded_snapshot("behind_backend")))
    try:
        code, body = fx.get("/healthz/ready")
        assert code == 503
        assert body["status"] == "degraded"
        assert body["reason"] == "behind_backend"
        assert body["lag"] == 100
    finally:
        fx.close()


def test_http_readiness_degraded_saturated():
    fx = _HttpServerFixture(FakeSampler(_degraded_snapshot("saturated")))
    try:
        code, body = fx.get("/healthz/ready")
        assert code == 503
        assert body["reason"] == "saturated"
        assert "saturation_seconds" in body
    finally:
        fx.close()


def test_http_metrics_shape_with_workers(ready_server):
    code, body = ready_server.get("/healthz/metrics")
    assert code == 200
    assert body["workers"]["total"] == 2
    assert body["saturation"]["saturated"] is False
    assert body["readiness"]["ready"] is True
    assert "health_handler" in body
    assert "uptime_seconds" in body["process"]


def test_http_metrics_workers_null_on_gunicorn():
    fx = _HttpServerFixture(FakeSampler(_degraded_snapshot("behind_backend")))
    try:
        code, body = fx.get("/healthz/metrics")
        assert code == 200
        assert body["workers"] is None  # no introspectable pool (gunicorn/werkzeug)
    finally:
        fx.close()


def test_http_unknown_path_404(ready_server):
    code, _ = ready_server.get("/nope")
    assert code == 404


def test_http_liveness_stays_fast(ready_server):
    # The whole point of the isolated listener: liveness responds quickly and never fails.
    for _ in range(20):
        start = time.monotonic()
        code, _ = ready_server.get("/healthz/live")
        assert code == 200
        assert (time.monotonic() - start) < 1.0


# --------------------------------------------------------------------------------------------
# Lifecycle
# --------------------------------------------------------------------------------------------


def test_bind_failure_is_non_fatal():
    # Occupy a port, then try to start a health server on the same port.
    sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    sock.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    sock.bind(("127.0.0.1", 0))
    sock.listen(1)
    taken_port = sock.getsockname()[1]
    try:
        server = HealthCheckServer(
            host="127.0.0.1", port=taken_port, dispatcher=None, saturation_grace=5
        )
        # Must not raise, and must degrade gracefully (no live httpd).
        server.start()
        assert server.httpd is None
        server.stop()  # also must not raise
    finally:
        sock.close()


def test_start_stop_serves_requests(monkeypatch):
    monkeypatch.setattr(config, "API_ONLY", True, raising=False)
    server = HealthCheckServer(host="127.0.0.1", port=0, dispatcher=None, saturation_grace=5)
    server.start()
    try:
        assert server.httpd is not None
        port = server.httpd.server_address[1]
        conn = http.client.HTTPConnection("127.0.0.1", port, timeout=5)
        conn.request("GET", "/healthz/live")
        assert conn.getresponse().status == 200
        conn.close()
    finally:
        server.stop()
