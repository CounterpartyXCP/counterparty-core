"""Exercise API lifecycle state without starting threads, listeners or databases."""

from types import SimpleNamespace
from unittest.mock import Mock

import pytest
from counterpartycore.lib.api import apiserver, healthz_server


@pytest.mark.parametrize("health_enabled", [True, False], ids=["health", "no-health"])
@pytest.mark.parametrize(
    "exit_path, expected_state, exit_code",
    [
        pytest.param("owner-return", 2, None, id="owner-returns"),
        pytest.param("owner-exit", 2, 0, id="owner-exits"),
        pytest.param("worker-exit", 1, 0, id="worker-retires"),
        pytest.param("startup-error", 2, 1, id="startup-fails"),
    ],
)
def test_run_apiserver_lifecycle_state(
    monkeypatch, health_enabled, exit_path, expected_state, exit_code
):
    ready = SimpleNamespace(value=0)
    process = SimpleNamespace(pid=100)
    sampler = None

    # Replace only apiserver's view of the PID; no fork or process-wide OS patch.
    monkeypatch.setattr(apiserver, "os", SimpleNamespace(getpid=lambda: process.pid))
    monkeypatch.setattr(apiserver.signal, "signal", Mock())
    for name in (
        "logger",
        "sentry",
        "initialise_log_and_config",
        "ConnectionPoolMonitor",
        "database",
        "check_database_version",
        "init_flask_app",
        "CurrentState",
        "ParentProcessChecker",
        "LedgerDBConnectionPool",
        "StateDBConnectionPool",
    ):
        monkeypatch.setattr(apiserver, name, Mock())
    monkeypatch.setattr(apiserver.apiwatcher, "APIWatcher", Mock())
    monkeypatch.setattr(apiserver.apiwatcher, "watcher_has_failed", lambda: False)
    for name, value in {
        "MEMORY_PROFILE": False,
        "NO_HEALTHZ_SERVER": not health_enabled,
        "API_HOST": "127.0.0.1",
        "HEALTHZ_PORT": 0,
        "STATE_DATABASE": "unused-state.db",
    }.items():
        monkeypatch.setattr(apiserver.config, name, value, raising=False)

    def make_health_server(**kwargs):
        nonlocal sampler
        # Use the real sampler and the serving callback supplied by run_apiserver.
        # API-only mode isolates readiness from backend height and block age.
        sampler = healthz_server.HealthSampler(
            last_parsed_provider=lambda: 100,
            backend_height_provider=lambda: 0,
            block_time_provider=lambda: None,
            api_only_provider=lambda: True,
            serving_provider=kwargs["serving_provider"],
        )
        sampler._tick()
        assert ready.value == 0
        assert sampler.current_snapshot().ready is False
        assert sampler.current_snapshot().reason == "starting"
        return Mock()

    health_factory = Mock(side_effect=make_health_server)
    monkeypatch.setattr(apiserver.healthz_server, "HealthCheckServer", health_factory)

    def run_wsgi(_ready, _backend_height):
        assert ready.value == 1
        if sampler is not None:
            sampler._tick()
            assert sampler.current_snapshot().ready is True
        if exit_path == "worker-exit":
            # Gunicorn forks inside run(), then a retiring worker raises SystemExit
            # through the inherited run_apiserver() frame while the owner stays up.
            process.pid += 1
        if exit_path in ("owner-exit", "worker-exit"):
            raise SystemExit(0)

    wsgi_server = Mock()
    wsgi_server.run.side_effect = run_wsgi
    wsgi_factory = Mock(return_value=wsgi_server)
    if exit_path == "startup-error":
        wsgi_factory.side_effect = OSError("could not bind API socket")
    monkeypatch.setattr(apiserver.wsgi, "WSGIApplication", wsgi_factory)

    args = {"rebuild_state_db": False, "refresh_state_db": False}
    call_args = (args, ready, Mock(), SimpleNamespace(value=0), 99, None)
    if exit_code is None:
        apiserver.run_apiserver(*call_args)
    else:
        with pytest.raises(SystemExit) as exc:
            apiserver.run_apiserver(*call_args)
        assert exc.value.code == exit_code

    assert ready.value == expected_state
    if health_enabled:
        sampler._tick()
        assert sampler.current_snapshot().ready is (expected_state == 1)
        assert sampler.current_snapshot().reason == (None if expected_state == 1 else "starting")
    else:
        health_factory.assert_not_called()
    if exit_path == "startup-error":
        wsgi_server.run.assert_not_called()
    else:
        wsgi_server.run.assert_called_once()
