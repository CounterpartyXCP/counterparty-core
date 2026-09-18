"""Tests for the rebuild-progress status and the ``rebuilding`` health state (#3485).

A State DB rebuild runs before the API listener exists and takes tens of
minutes. These tests pin the two properties that make it survivable: the health
server answers throughout, and it says *why* it is not ready.
"""

import http.client
import json
import threading
import time
from collections import deque

import pytest
from counterpartycore.lib.api import dbstatus, healthz_server
from counterpartycore.lib.api.healthz_server import (
    HealthRequestHandler,
    HealthSampler,
    HealthSnapshot,
)


@pytest.fixture(autouse=True)
def _clear_status():
    """``dbstatus`` is process-global; never leak a rebuild into another test."""
    dbstatus.finish()
    yield
    dbstatus.finish()


# --------------------------------------------------------------------------------------------
# dbstatus
# --------------------------------------------------------------------------------------------


def test_no_operation_by_default():
    assert dbstatus.current() is None


def test_start_step_finish():
    dbstatus.start("refresh", "re-applying migrations", total=28)
    progress = dbstatus.current()
    assert progress.operation == "refresh"
    assert progress.phase == "re-applying migrations"
    assert progress.step is None
    assert progress.total == 28

    dbstatus.step("applying `0006.create_and_populate_consolidated_tables`", 20)
    progress = dbstatus.current()
    assert progress.step == 20
    assert progress.total == 28, "total must survive a step"
    assert progress.operation == "refresh", "operation must survive a step"

    dbstatus.finish()
    assert dbstatus.current() is None


def test_step_outside_an_operation_is_a_noop():
    dbstatus.step("orphan", 1)
    assert dbstatus.current() is None


def test_elapsed_time_is_measured_from_the_start_not_the_step():
    dbstatus.start("rollback", "pruning")
    started_at = dbstatus.current().started_at
    dbstatus.step("re-applying", 1)
    assert dbstatus.current().started_at == started_at
    assert dbstatus.current().seconds >= 0


def test_context_manager_clears_on_exception():
    with pytest.raises(ValueError, match="boom"), dbstatus.rebuilding("build", "migrating"):
        assert dbstatus.current() is not None
        raise ValueError("boom")
    assert dbstatus.current() is None, "a failed rebuild must not leave the pod unready forever"


def test_as_dict_omits_unknown_counters():
    dbstatus.start("build", "applying migrations")
    body = dbstatus.current().as_dict()
    assert body["operation"] == "build"
    assert body["phase"] == "applying migrations"
    assert "seconds" in body
    assert "step" not in body
    assert "total_steps" not in body


# --------------------------------------------------------------------------------------------
# Sampler: the rebuilding readiness axis
# --------------------------------------------------------------------------------------------


def _sampler(**kwargs):
    defaults = {
        "last_parsed_provider": lambda: 100,
        "backend_height_provider": lambda: 100,
        "block_time_provider": lambda: None,
        "api_only_provider": lambda: False,
        "saturation_grace": 5,
    }
    defaults.update(kwargs)
    return HealthSampler(**defaults)


def test_rebuild_makes_the_pod_unready():
    sampler = _sampler()
    sampler._tick()
    assert sampler.current_snapshot().ready is True

    dbstatus.start("refresh", "re-applying migrations", total=28)
    sampler._tick()
    snap = sampler.current_snapshot()
    assert snap.ready is False
    assert snap.reason == "rebuilding"
    assert snap.rebuild.operation == "refresh"


def test_rebuild_wins_over_the_lag_signal():
    """While the State DB is being dropped and repopulated, the block height read
    from it is meaningless -- reporting ``behind_backend`` would send the
    operator chasing the wrong problem."""
    sampler = _sampler(backend_height_provider=lambda: 200, last_parsed_provider=lambda: 100)
    sampler._tick()
    assert sampler.current_snapshot().reason == "behind_backend"

    dbstatus.start("rollback", "pruning")
    sampler._tick()
    snap = sampler.current_snapshot()
    assert snap.reason == "rebuilding"
    assert snap.last_parsed is None, "a mid-rebuild block height must not be published"


def test_readiness_recovers_when_the_rebuild_ends():
    sampler = _sampler()
    dbstatus.start("build", "applying migrations")
    sampler._tick()
    assert sampler.current_snapshot().ready is False

    dbstatus.finish()
    sampler._tick()
    snap = sampler.current_snapshot()
    assert snap.ready is True
    assert snap.rebuild is None


def test_heartbeat_stays_fresh_during_a_rebuild():
    """Liveness must not fail while rebuilding: that is exactly what killed the
    pod mid-rebuild and restarted the work from zero."""
    sampler = _sampler()
    dbstatus.start("refresh", "re-applying migrations")
    sampler._tick()
    assert sampler.heartbeat_age() < sampler.liveness_heartbeat_timeout


# --------------------------------------------------------------------------------------------
# HTTP surface
# --------------------------------------------------------------------------------------------


class _FakeSampler:
    liveness_heartbeat_timeout = 30

    def __init__(self, snapshot):
        self._snapshot = snapshot

    def current_snapshot(self):
        return self._snapshot

    def heartbeat_age(self):
        return 0.0


def _rebuilding_snapshot():
    dbstatus.start("refresh", "applying `0006.create_and_populate_consolidated_tables`", total=28)
    dbstatus.step("applying `0006.create_and_populate_consolidated_tables`", 20)
    return HealthSnapshot(
        ready=False,
        reason="rebuilding",
        backend_height=900000,
        last_parsed=None,
        lag=None,
        saturated=False,
        saturation_seconds=0.0,
        workers=None,
        rebuild=dbstatus.current(),
    )


@pytest.fixture
def rebuilding_server():
    httpd = healthz_server.ThreadingHTTPServer(("127.0.0.1", 0), HealthRequestHandler)
    httpd.daemon_threads = True
    httpd.sampler = _FakeSampler(_rebuilding_snapshot())
    httpd.started_at_monotonic = time.monotonic()
    httpd.live_latencies_ms = deque(maxlen=256)
    httpd.ready_latencies_ms = deque(maxlen=256)
    port = httpd.server_address[1]
    thread = threading.Thread(target=httpd.serve_forever, daemon=True)
    thread.start()

    def get(path):
        conn = http.client.HTTPConnection("127.0.0.1", port, timeout=5)
        conn.request("GET", path)
        resp = conn.getresponse()
        body = json.loads(resp.read().decode())
        code = resp.status
        conn.close()
        return code, body

    yield get
    httpd.shutdown()
    httpd.server_close()
    thread.join(timeout=5)


def test_http_liveness_ok_while_rebuilding(rebuilding_server):
    assert rebuilding_server("/healthz/live") == (200, {"status": "alive"})


def test_http_readiness_reports_the_rebuild(rebuilding_server):
    code, body = rebuilding_server("/healthz/ready")
    assert code == 503
    assert body["reason"] == "rebuilding"
    assert body["rebuild"]["operation"] == "refresh"
    assert body["rebuild"]["step"] == 20
    assert body["rebuild"]["total_steps"] == 28
    assert "0006" in body["rebuild"]["phase"]


def test_http_metrics_reports_the_rebuild(rebuilding_server):
    _code, body = rebuilding_server("/healthz/metrics")
    assert body["readiness"]["reason"] == "rebuilding"
    assert body["readiness"]["rebuild"]["step"] == 20


# --------------------------------------------------------------------------------------------
# Late dispatcher attachment
# --------------------------------------------------------------------------------------------


def test_server_starts_without_a_dispatcher_and_accepts_one_later():
    """The health server now starts before the WSGI server, so there is no
    worker pool to introspect at first; the gauges must simply read as
    unavailable until one is attached."""
    server = healthz_server.HealthCheckServer(host="127.0.0.1", port=0)
    server.start()
    try:
        assert server.sampler is not None
        assert server.sampler.dispatcher is None
        assert server.sampler.current_snapshot().workers is None

        dispatcher = type(
            "Dispatcher", (), {"threads": {1, 2}, "active_count": 0, "stop_count": 0}
        )()
        dispatcher.queue = deque()
        dispatcher.add_task = lambda task: None
        server.attach_dispatcher(dispatcher)

        assert server.sampler.dispatcher is dispatcher
        server.sampler._tick()
        assert server.sampler.current_snapshot().workers.total == 2
    finally:
        server.stop()


def test_attach_dispatcher_ignores_none():
    server = healthz_server.HealthCheckServer(host="127.0.0.1", port=0)
    server.start()
    try:
        server.attach_dispatcher(None)
        assert server.sampler.dispatcher is None
    finally:
        server.stop()


# --------------------------------------------------------------------------------------------
# The sampler's own DB connection across a rebuild
# --------------------------------------------------------------------------------------------


class _FakeConn:
    def __init__(self):
        self.closed = False

    def close(self):
        self.closed = True


def _owning_sampler(monkeypatch):
    """A sampler that owns its state-DB connection, with the connection factory
    replaced by a counter."""
    opened = []

    def fake_connection(*_args, **_kwargs):
        conn = _FakeConn()
        opened.append(conn)
        return conn

    monkeypatch.setattr(healthz_server.database, "get_db_connection", fake_connection)
    sampler = HealthSampler(
        backend_height_provider=lambda: 100,
        block_time_provider=lambda: None,
        api_only_provider=lambda: False,
    )
    assert sampler._owns_db is True
    return sampler, opened


def test_sampler_opens_its_connection_once_when_idle(monkeypatch):
    sampler, opened = _owning_sampler(monkeypatch)
    conn = sampler._own_db_for_tick(None, False, False)
    assert len(opened) == 1
    assert sampler._own_db_for_tick(conn, False, False) is conn
    assert len(opened) == 1


def test_sampler_does_not_open_during_a_rebuild(monkeypatch):
    """The file may be unlinked or mid-migration; opening it buys nothing and
    can pin a doomed inode."""
    sampler, opened = _owning_sampler(monkeypatch)
    assert sampler._own_db_for_tick(None, False, True) is None
    assert opened == []


def test_sampler_reopens_after_a_rebuild(monkeypatch):
    """``build_state_db()`` unlinks and recreates the file: a connection held
    across it reads a deleted inode and would report a frozen block height for
    the rest of the process's life."""
    sampler, opened = _owning_sampler(monkeypatch)
    stale = sampler._own_db_for_tick(None, False, False)
    assert len(opened) == 1

    # ... a rebuild runs ...
    assert sampler._own_db_for_tick(stale, False, True) is stale
    # ... and finishes: falling edge.
    fresh = sampler._own_db_for_tick(stale, True, False)

    assert stale.closed is True
    assert fresh is not stale
    assert len(opened) == 2


def test_sampler_with_injected_provider_is_left_alone(monkeypatch):
    """Tests (and any future caller) that inject a provider own no connection;
    the rebuild lifecycle must not touch them."""
    sampler, opened = _owning_sampler(monkeypatch)
    sampler._owns_db = False
    assert sampler._own_db_for_tick(None, True, False) is None
    assert opened == []
