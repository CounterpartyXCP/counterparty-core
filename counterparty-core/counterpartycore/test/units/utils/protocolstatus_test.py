import json
import multiprocessing
import time
from types import SimpleNamespace
from unittest.mock import MagicMock

import pytest
import requests
from counterpartycore.lib import config, exceptions
from counterpartycore.lib.cli import server
from counterpartycore.lib.monitors.protocolversion import ProtocolVersionMonitor
from counterpartycore.lib.parser import blocks, check
from counterpartycore.lib.utils import protocolstatus


def requirement(height=100):
    return {
        "change_name": "next_upgrade",
        "version": [config.VERSION_MAJOR + 1, 0, 0],
        "activation_height": height,
    }


def _child_status(state, output):
    config.FORCE = False
    output.put(state.summary(100)["status"])


def test_status_boundaries_and_force(monkeypatch):
    state = protocolstatus.ProtocolStatus()
    assert state.summary(1)["status"] == "unknown"
    state.publish([requirement()])
    assert state.summary(99)["status"] == "upgrade_pending"
    assert state.summary(100)["status"] == "incompatible"
    monkeypatch.setattr(config, "FORCE", True)
    assert state.summary(100)["status"] == "bypassed"
    assert state.summary(100)["force_override"] is True
    state.require_supported(100)


def test_failures_and_age_do_not_erase_known_requirements(monkeypatch):
    state = protocolstatus.ProtocolStatus()
    state.publish([requirement()])
    state.unavailable()
    assert state.summary(99)["status"] == "stale"
    assert state.summary(100)["status"] == "incompatible"
    state.publish([requirement()])
    now = time.time() + protocolstatus.MAX_METADATA_AGE + 1
    monkeypatch.setattr(protocolstatus.time, "time", lambda: now)
    assert state.summary(99)["status"] == "stale"
    assert state.summary(100)["status"] == "incompatible"


def test_activation_barrier_is_sticky_across_refresh_and_height_lag():
    state = protocolstatus.ProtocolStatus()
    state.publish([requirement()])
    state.require_supported(99)
    with pytest.raises(exceptions.VersionUpdateRequiredError):
        state.require_supported(100)
    state.publish([])
    assert state.summary(99)["status"] == "incompatible"
    with pytest.raises(exceptions.VersionUpdateRequiredError):
        state.require_supported(99)


def test_guard_and_api_report_strongest_active_version():
    state = protocolstatus.ProtocolStatus()
    stronger = {**requirement(110), "version": [config.VERSION_MAJOR + 2, 0, 0]}
    state.publish([requirement(), stronger])
    assert state.summary(100)["required_version"] == f"{config.VERSION_MAJOR + 1}.0.0"
    with pytest.raises(exceptions.VersionUpdateRequiredError, match=f"v{config.VERSION_MAJOR + 2}"):
        state.require_supported(110)
    assert state.summary(110)["required_version"] == f"{config.VERSION_MAJOR + 2}.0.0"
    state.publish([])
    assert state.summary(0)["required_version"] == f"{config.VERSION_MAJOR + 2}.0.0"


def test_parser_rejects_activation_before_writes_or_height_advance(monkeypatch):
    state = protocolstatus.ProtocolStatus()
    state.publish([requirement()])
    protocolstatus.configure(state)
    db = MagicMock()
    advance = MagicMock()
    monkeypatch.setattr(blocks.CurrentState, "set_current_block_index", advance)
    with pytest.raises(exceptions.VersionUpdateRequiredError):
        blocks.parse_new_block(db, {"block_index": 100})
    advance.assert_not_called()
    db.cursor.assert_not_called()


def test_status_is_shared_with_spawned_api_process():
    context = multiprocessing.get_context("spawn")
    state = protocolstatus.ProtocolStatus()
    state.publish([requirement()])
    output = context.Queue()
    child = context.Process(target=_child_status, args=(state, output))
    child.start()
    try:
        assert output.get(timeout=10) == "incompatible"
        child.join(timeout=10)
        assert child.exitcode == 0
    finally:
        if child.is_alive():
            child.terminate()
            child.join(timeout=5)
        output.close()


def test_periodic_monitor_is_independent_of_watcher_activity(monkeypatch):
    monitor = ProtocolVersionMonitor()
    monitor.stop_event = MagicMock()
    monitor.stop_event.wait.side_effect = [False, False, True]
    fetch = MagicMock(return_value=True)
    monkeypatch.setattr(check, "software_version", fetch)
    monitor.run()
    assert fetch.call_count == 2
    assert all(call.kwargs == {"enforce": False} for call in fetch.call_args_list)
    assert all(
        call.args == (protocolstatus.CHECK_INTERVAL,)
        for call in monitor.stop_event.wait.call_args_list
    )


def test_monitor_retries_metadata_errors_without_dropping_cache(monkeypatch):
    state = protocolstatus.current()
    state.publish([requirement()])
    monkeypatch.setattr(
        check, "software_version", MagicMock(side_effect=exceptions.VersionCheckError("offline"))
    )
    assert ProtocolVersionMonitor().refresh() == protocolstatus.RETRY_INTERVAL
    assert state.summary(100)["status"] == "incompatible"


def test_oversized_metadata_is_rejected_without_replacing_verified_state():
    state = protocolstatus.ProtocolStatus()
    state.publish([])
    with pytest.raises(exceptions.VersionCheckError, match="status limit"):
        state.publish([{**requirement(), "change_name": "x" * 33000}])
    assert state.summary(1)["status"] == "compatible"


@pytest.mark.parametrize(
    "flag,key",
    [
        ("TESTNET3", "testnet3_block_index"),
        ("TESTNET4", "testnet4_block_index"),
        ("SIGNET", "signet_block_index"),
    ],
)
def test_manifest_uses_network_activation_height(monkeypatch, flag, key):
    monkeypatch.setattr(config, flag, True)
    response = requests.Response()
    response.status_code = 200
    response._content = json.dumps(
        {
            "upgrade": {
                "minimum_version_major": config.VERSION_MAJOR + 1,
                "minimum_version_minor": 0,
                "minimum_version_revision": 0,
                "block_index": 1000,
                key: 100,
            }
        }
    ).encode()
    fetch = MagicMock(return_value=response)
    monkeypatch.setattr(check.requests, "get", fetch)
    check.software_version(enforce=False)
    assert protocolstatus.summary(100)["status"] == "incompatible"
    assert protocolstatus.summary(100)["activation_height"] == 100


@pytest.mark.parametrize(
    "payload", [{}, [], {"upgrade": {"block_index": 1, "minimum_version_major": "12"}}]
)
def test_malformed_manifest_preserves_verified_requirement(monkeypatch, payload):
    state = protocolstatus.current()
    state.publish([requirement()])
    response = requests.Response()
    response.status_code = 200
    response._content = json.dumps(payload).encode()
    monkeypatch.setattr(check.requests, "get", MagicMock(return_value=response))
    with pytest.raises(exceptions.VersionCheckError):
        check.software_version(enforce=False)
    assert state.summary(99)["status"] == "stale"
    assert state.summary(100)["status"] == "incompatible"


def test_monitor_stop_is_interruptible_without_waiting_for_next_poll():
    monitor = ProtocolVersionMonitor()
    monitor.start()
    started = time.monotonic()
    monitor.stop()
    assert not monitor.is_alive()
    assert time.monotonic() - started < 1


def test_startup_incompatibility_is_latched_before_diagnostic_api(monkeypatch):
    height = check.CurrentState().current_block_index()
    response = requests.Response()
    response.status_code = 200
    response._content = json.dumps(
        {
            "upgrade": {
                "minimum_version_major": config.VERSION_MAJOR + 1,
                "minimum_version_minor": 0,
                "minimum_version_revision": 0,
                "block_index": height,
            }
        }
    ).encode()
    monkeypatch.setattr(check.requests, "get", MagicMock(return_value=response))
    with pytest.raises(exceptions.VersionUpdateRequiredError):
        check.software_version()
    protocolstatus.current().publish([])
    assert protocolstatus.summary(0)["status"] == "incompatible"


@pytest.mark.parametrize("phase", ["startup", "catch_up", "watcher"])
def test_server_parks_parser_but_keeps_diagnostic_api_running(monkeypatch, phase):
    monkeypatch.setattr(config, "MEMORY_PROFILE", False)
    monkeypatch.setattr(config, "ENABLE_API_V1", False)
    monkeypatch.setattr(config, "CHECK_ASSET_CONSERVATION", False)
    monkeypatch.setattr(server, "should_bootstrap_database", lambda *_: False)
    for name in ("apply_outstanding_migration", "initialise_db", "optimize"):
        monkeypatch.setattr(server.database, name, MagicMock())
    for name in (
        "create_events_indexes",
        "check_database_version",
        "rollback_empty_block",
        "reset_rust_fetcher_database",
    ):
        monkeypatch.setattr(server.blocks, name, MagicMock())
    monkeypatch.setattr(server.check, "stored_checkpoints", MagicMock())
    upgrade = exceptions.VersionUpdateRequiredError("upgrade required")
    monkeypatch.setattr(
        server.check,
        "software_version",
        MagicMock(side_effect=upgrade if phase == "startup" else None),
    )
    monkeypatch.setattr(
        server.blocks, "catch_up", MagicMock(side_effect=upgrade if phase == "catch_up" else None)
    )
    monkeypatch.setattr(server.ledger.blocks, "last_db_index", MagicMock(return_value=99))
    monkeypatch.setattr(server.CurrentState, "set_current_block_index", MagicMock())
    monkeypatch.setattr(server.CurrentState, "set_backend_height_value", MagicMock())
    monkeypatch.setattr(server, "ensure_backend_is_up", MagicMock())
    monkeypatch.setattr(server, "BackendHeight", MagicMock())
    monkeypatch.setattr(server, "ProtocolVersionMonitor", MagicMock())
    monkeypatch.setattr(server.rsfetcher, "RSFetcher", MagicMock())
    api = MagicMock()
    api.is_ready.return_value = True
    monkeypatch.setattr(server.api_v2, "APIServer", MagicMock(return_value=api))
    watcher = MagicMock(upgrade_required=True)
    monkeypatch.setattr(server.follow, "start_blockchain_watcher", MagicMock(return_value=watcher))
    app = server.CounterpartyServer(
        SimpleNamespace(catch_up="normal", bootstrap_url=None, api_only=False)
    )
    monkeypatch.setattr(app, "_start_pool_monitor", MagicMock())
    wait = MagicMock()
    monkeypatch.setattr(app, "_wait_for_shutdown", wait)

    app.run_server()

    wait.assert_called_once()
    api.start.assert_called_once()
    api.stop.assert_not_called()
    app.protocol_monitor.start.assert_called_once()
    assert watcher.start.call_count == (1 if phase == "watcher" else 0)
