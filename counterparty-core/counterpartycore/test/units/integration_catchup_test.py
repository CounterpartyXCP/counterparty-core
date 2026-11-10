"""Catchup's total deadline applies to every poll, without live processes or RPC."""

import importlib
import json
import signal
import subprocess
from pathlib import Path
from types import SimpleNamespace
from unittest.mock import Mock, call

import pytest


@pytest.fixture
def polling(monkeypatch):
    # Integration helpers use sibling imports when pytest runs their directory.
    monkeypatch.syspath_prepend(str(Path(__file__).resolve().parents[1] / "integrations"))
    module = importlib.import_module("reparsetest")
    state = SimpleNamespace(
        module=module,
        now=0.0,
        responses=[{"server_ready": False, "counterparty_height": 122}],
        timeouts=[],
        sleeps=[],
        request_duration=0.0,
        # poll() returning None: the server is still running.
        process=Mock(pid=9001, **{"poll.return_value": None}),
        killpg=Mock(),
    )

    def sleep(seconds):
        assert 0 < seconds <= 1
        state.sleeps.append(seconds)
        state.now += seconds

    def get(url, timeout):
        assert url == "http://fixture.invalid/v2/"
        assert 0 < timeout <= 5
        index = len(state.timeouts)
        if index >= 10:
            pytest.fail("Catchup kept polling beyond its deadline")
        state.timeouts.append(timeout)
        state.now += state.request_duration
        response = state.responses[min(index, len(state.responses) - 1)]
        if isinstance(response, Exception):
            raise response
        return SimpleNamespace(json=lambda: {"result": response})

    monkeypatch.setattr(
        module,
        "time",
        SimpleNamespace(monotonic=lambda: state.now, time=lambda: state.now, sleep=sleep),
    )
    monkeypatch.setattr(module, "requests", SimpleNamespace(get=get))
    state.popen = Mock(return_value=state.process)
    monkeypatch.setattr(
        module,
        "subprocess",
        SimpleNamespace(
            Popen=state.popen,
            STDOUT=subprocess.STDOUT,
            TimeoutExpired=subprocess.TimeoutExpired,
        ),
    )
    monkeypatch.setattr(module, "os", SimpleNamespace(killpg=state.killpg))
    return state


def catchup(state, **kwargs):
    state.module.catchup(
        ["--regtest"], "http://fixture.invalid/v2/", timeout_minutes=0.05, **kwargs
    )


@pytest.mark.parametrize("minimum", [None, 123])
def test_successful_unready_or_below_target_response_expires(polling, minimum):
    if minimum is not None:
        polling.responses[0]["server_ready"] = True
    with pytest.raises(TimeoutError, match="server not ready after"):
        catchup(polling, min_block_index=minimum)
    assert polling.now == 3
    assert polling.timeouts == [3, 2, 1]
    assert polling.sleeps == [1, 1, 1]
    polling.killpg.assert_called_once_with(9001, signal.SIGTERM)
    polling.process.wait.assert_called_once_with(timeout=15)


@pytest.mark.parametrize("response", [OSError("fixture connection failure"), None])
def test_network_or_malformed_response_uses_same_budget(polling, response):
    polling.responses = [response]
    with pytest.raises(TimeoutError):
        catchup(polling)
    assert polling.now == 3
    assert polling.timeouts == [3, 2, 1]
    polling.killpg.assert_called_once_with(9001, signal.SIGTERM)


def test_ready_response_before_deadline_and_process_group_cleanup(polling):
    polling.responses.append({"server_ready": True})
    catchup(polling)
    assert polling.now == 1
    assert polling.timeouts == [3, 2]
    polling.killpg.assert_called_once_with(9001, signal.SIGTERM)
    args, options = polling.popen.call_args
    assert args == (["counterparty-server", "--regtest", "start"],)
    assert options["start_new_session"] is True


def test_target_height_preserves_existing_readiness_override(polling):
    polling.responses = [{"server_ready": False, "counterparty_height": 123}]
    catchup(polling, min_block_index=123)
    assert polling.sleeps == []


def test_late_success_cannot_reset_or_escape_deadline(polling):
    polling.responses = [{"server_ready": True}]
    polling.request_duration = 4
    with pytest.raises(TimeoutError):
        catchup(polling)
    assert polling.timeouts == [3]
    assert polling.sleeps == []


def test_fractional_remaining_budget_bounds_request_and_sleep(polling):
    with pytest.raises(TimeoutError):
        polling.module.catchup([], "http://fixture.invalid/v2/", timeout_minutes=0.5 / 60)
    assert polling.timeouts == [0.5]
    assert polling.sleeps == [0.5]


def test_deadline_uses_monotonic_clock_not_wall_clock(polling):
    polling.module.time.time = Mock(side_effect=AssertionError("Wall clock must not set deadline"))
    with pytest.raises(TimeoutError):
        catchup(polling)
    polling.module.time.time.assert_not_called()


def test_timeout_preserves_existing_kill_escalation(polling):
    polling.process.wait.side_effect = [subprocess.TimeoutExpired("fixture", 15), 0]
    with pytest.raises(TimeoutError):
        catchup(polling)
    assert polling.killpg.call_args_list == [call(9001, signal.SIGTERM), call(9001, signal.SIGKILL)]
    assert polling.process.wait.call_args_list == [call(timeout=15), call()]


def test_server_exit_fails_fast_instead_of_polling_a_dead_api(polling):
    """An API startup failure used to leave catchup polling a dead API for the
    whole recovery budget (105 minutes on signet and testnet4)."""
    polling.process.poll.side_effect = [None, 1]
    polling.process.returncode = 1
    with pytest.raises(RuntimeError, match="exited with code 1 before becoming ready"):
        catchup(polling)
    assert polling.timeouts == [3]
    assert polling.sleeps == [1]
    polling.killpg.assert_called_once_with(9001, signal.SIGTERM)


def test_cleanup_of_an_exited_server_keeps_the_original_error(polling):
    polling.process.poll.return_value = 1
    polling.process.returncode = 1
    polling.killpg.side_effect = ProcessLookupError
    with pytest.raises(RuntimeError, match="before becoming ready"):
        catchup(polling)
    polling.process.wait.assert_called_once_with(timeout=15)


@pytest.fixture
def cached_run(monkeypatch):
    monkeypatch.syspath_prepend(str(Path(__file__).resolve().parents[1] / "integrations"))
    module = importlib.import_module("reparsetest")
    expected = [
        {
            "block_index": height,
            "ledger_hash": f"original-ledger-{height}",
            "txlist_hash": f"original-txlist-{height}",
        }
        for height in range(101, 201)
    ]
    real_marker_reader = importlib.import_module("cache_manager").is_tip_catchup_verified
    state = SimpleNamespace(
        module=module,
        expected=expected,
        events=[],
        state_db_ready=False,
        height=200,
        saved_heights=[],
    )

    def build_state_db(action):
        assert action == "build-state-db"
        state.state_db_ready = True
        state.events.append("build-state-db")

    def rollback_cached(command, block_index):
        assert command is state.command
        assert state.state_db_ready, "Rollback requires the restored State DB's tables"
        assert block_index == expected[0]["block_index"]
        state.height = block_index - 1
        state.events.append("rollback")

    def catchup_cached(args, api_url, min_block_index=None, timeout_minutes=20):
        assert args == ["--signet"]
        assert api_url == "http://fixture.invalid/v2/"
        if min_block_index is not None:
            assert timeout_minutes == 20
            assert min_block_index == expected[-1]["block_index"]
            state.height = min_block_index
            state.events.append("replay")
        else:
            # A real server start also creates the State DB. Model that so the
            # old ordering fails on discarded progress, not a missing mock side effect.
            state.state_db_ready = True
            state.height = 300
            state.events.append("tip")

    def verify_hashes(db_path, hashes):
        assert db_path == "fixture.db"
        assert hashes is expected
        assert len(hashes) == 100
        assert state.height == expected[-1]["block_index"]
        state.events.append("verify")

    def save_cache(network, db_path, *, tip_catchup_verified=False):
        assert (network, db_path) == ("signet", "fixture.db")
        assert tip_catchup_verified is True
        state.saved_heights.append(state.height)
        state.events.append("save")

    state.command = Mock(side_effect=build_state_db)
    state.catchup = Mock(side_effect=catchup_cached)
    state.verify = Mock(side_effect=verify_hashes)
    state.cache = Mock(
        restore_db_from_cache=Mock(side_effect=lambda *_: state.events.append("restore")),
        load_hashes=Mock(return_value={"hashes": expected}),
        is_tip_catchup_verified=real_marker_reader,
        get_rollback_block_index=Mock(return_value=101),
        verify_hashes=state.verify,
        save_cache=Mock(side_effect=save_cache),
    )
    monkeypatch.setattr(module, "cache_manager", state.cache)
    monkeypatch.setattr(
        module,
        "prepare",
        Mock(
            return_value=(state.command, ["--signet"], "fixture.db", "http://fixture.invalid/v2/")
        ),
    )
    monkeypatch.setattr(module, "rollback", Mock(side_effect=rollback_cached))
    monkeypatch.setattr(module, "catchup", state.catchup)
    monkeypatch.setattr(module, "cleanup", Mock(side_effect=lambda: state.events.append("cleanup")))
    return state


def test_cached_run_verifies_original_hashes_then_saves_advanced_tip(cached_run):
    cached_run.module._run_with_cache("signet")
    assert cached_run.events == [
        "restore",
        "build-state-db",
        "rollback",
        "replay",
        "verify",
        "tip",
        "save",
        "cleanup",
    ]
    cached_run.command.assert_called_once_with("build-state-db")
    cached_run.module.prepare.assert_called_once_with("signet", use_existing_data=True)
    assert cached_run.catchup.call_args_list == [
        call(["--signet"], "http://fixture.invalid/v2/", min_block_index=200),
        call(["--signet"], "http://fixture.invalid/v2/", timeout_minutes=105),
    ]
    assert cached_run.expected == [
        {
            "block_index": height,
            "ledger_hash": f"original-ledger-{height}",
            "txlist_hash": f"original-txlist-{height}",
        }
        for height in range(101, 201)
    ]
    assert cached_run.saved_heights == [300]
    cached_run.cache.save_cache.assert_called_once_with(
        "signet", "fixture.db", tip_catchup_verified=True
    )


def test_verified_cache_retains_strict_warm_budget(cached_run):
    cached_run.cache.load_hashes.return_value["tip_catchup_verified"] = 1
    cached_run.module._run_with_cache("signet")
    assert cached_run.catchup.call_args_list == [
        call(["--signet"], "http://fixture.invalid/v2/", min_block_index=200),
        call(["--signet"], "http://fixture.invalid/v2/", timeout_minutes=20),
    ]
    assert cached_run.events.index("verify") < cached_run.events.index("tip")


@pytest.mark.parametrize("network", ["mainnet", "testnet3", "regtest", "signet", "testnet4"])
@pytest.mark.parametrize("verified", [False, True])
def test_recovery_budget_is_limited_to_the_two_network_fixtures(cached_run, network, verified):
    expected = 105 if network in ("signet", "testnet4") and not verified else 20
    assert cached_run.module._tip_catchup_timeout(network, verified) == expected


def test_warm_timeout_has_no_recovery_retry_or_save(cached_run):
    cached_run.cache.load_hashes.return_value["tip_catchup_verified"] = 1
    replay = cached_run.catchup.side_effect

    def fail_tip(*args, **kwargs):
        if kwargs.get("min_block_index") is None:
            assert kwargs["timeout_minutes"] == 20
            raise TimeoutError("warm tip failed")
        return replay(*args, **kwargs)

    cached_run.catchup.side_effect = fail_tip
    with pytest.raises(TimeoutError, match="warm tip failed"):
        cached_run.module._run_with_cache("signet")
    assert cached_run.catchup.call_count == 2
    cached_run.cache.save_cache.assert_not_called()


@pytest.mark.parametrize("fails", [False, True])
def test_initial_fixture_uses_one_bounded_recovery_and_marks_only_success(
    cached_run, monkeypatch, fails
):
    monkeypatch.setattr(
        cached_run.module,
        "bootstrap",
        Mock(side_effect=lambda *_: cached_run.events.append("bootstrap")),
    )
    if fails:
        cached_run.catchup.side_effect = TimeoutError("initial tip failed")
        with pytest.raises(TimeoutError, match="initial tip failed"):
            cached_run.module._run_without_cache("signet")
        cached_run.cache.save_cache.assert_not_called()
    else:
        cached_run.module._run_without_cache("signet")
        assert cached_run.events == ["bootstrap", "tip", "save", "cleanup"]
        cached_run.cache.save_cache.assert_called_once_with(
            "signet", "fixture.db", tip_catchup_verified=True
        )
    cached_run.catchup.assert_called_once_with(
        ["--signet"], "http://fixture.invalid/v2/", timeout_minutes=105
    )
    cached_run.verify.assert_not_called()


@pytest.mark.parametrize("marker", [True, False, None, 0, 2, 1.0, "1"])
def test_unknown_cached_flow_never_replays_advances_or_saves(cached_run, marker):
    cached_run.cache.load_hashes.return_value["tip_catchup_verified"] = marker
    with pytest.raises(ValueError, match="Unsupported integration cache"):
        cached_run.module._run_with_cache("signet")
    assert cached_run.events == ["restore"]
    cached_run.catchup.assert_not_called()
    cached_run.cache.save_cache.assert_not_called()


@pytest.mark.parametrize(
    "phase,error_type",
    [
        ("build", RuntimeError),
        ("replay", TimeoutError),
        ("verify", AssertionError),
        ("tip", TimeoutError),
    ],
)
def test_cached_run_never_saves_failed_preparation_verification_or_catchup(
    cached_run, phase, error_type
):
    failure = error_type(f"fixture {phase} failed")
    if phase == "build":
        cached_run.command.side_effect = failure
    elif phase == "verify":
        cached_run.verify.side_effect = failure
    else:
        original_catchup = cached_run.catchup.side_effect

        def catchup_or_fail(*args, **kwargs):
            is_replay = kwargs.get("min_block_index") is not None
            if (phase == "replay") == is_replay:
                raise failure
            return original_catchup(*args, **kwargs)

        cached_run.catchup.side_effect = catchup_or_fail

    with pytest.raises(error_type, match=f"fixture {phase} failed"):
        cached_run.module._run_with_cache("signet")
    cached_run.cache.save_cache.assert_not_called()
    assert cached_run.saved_heights == []
    if phase in {"build", "replay", "verify"}:
        assert "tip" not in cached_run.events


def test_failed_integration_cannot_publish_a_new_cache_key():
    workflow = Path(__file__).resolve().parents[4] / ".github/workflows/pytest_action.yml"
    cache_step = workflow.read_text().split("- name: Save integration cache\n", 1)[1]
    cache_step = cache_step.split("\n      - ", 1)[0]
    assert "if: success() && inputs.integration_cache_network != ''" in cache_step
    assert "always()" not in cache_step


def test_only_the_two_network_cache_jobs_get_the_recovery_job_limit():
    workflow = Path(__file__).resolve().parents[4] / ".github/workflows/pytest_action.yml"
    text = workflow.read_text()
    assert (
        "timeout-minutes: ${{ (inputs.integration_cache_network == 'signet' || "
        "inputs.integration_cache_network == 'testnet4') && 120 || 360 }}"
    ) in text
    assert text.count("timeout-minutes:") == 1
    assert text.count("integration-v7-${{ inputs.integration_cache_network }}-") == 3


@pytest.fixture
def cache_files(monkeypatch, tmp_path):
    monkeypatch.syspath_prepend(str(Path(__file__).resolve().parents[1] / "integrations"))
    module = importlib.import_module("cache_manager")
    monkeypatch.setenv("COUNTERPARTY_INTEGRATION_CACHE_DIR", str(tmp_path / "cache"))
    db_path = tmp_path / "fixture.db"
    db = module.apsw.Connection(str(db_path))
    try:
        db.execute("CREATE TABLE blocks(block_index INTEGER,ledger_hash TEXT,txlist_hash TEXT)")
        db.executemany(
            "INSERT INTO blocks VALUES(?,?,?)",
            [(height, f"{height:064x}", f"{height + 1:064x}") for height in range(101, 201)],
        )
    finally:
        db.close()
    return module, db_path


@pytest.mark.parametrize("verified", [False, True])
def test_fixture_marker_round_trip_only_after_explicit_verified_save(cache_files, verified):
    module, db_path = cache_files
    if verified:
        module.save_cache("signet", str(db_path), tip_catchup_verified=True)
    else:
        module.save_cache("signet", str(db_path))
    assert module.cache_exists("signet")
    saved = module.load_hashes("signet")
    assert saved["last_block_index"] == 200
    assert saved["hash_count"] == 100
    assert len(saved["hashes"]) == 100
    assert module.is_tip_catchup_verified(saved) is verified
    if verified:
        assert type(saved["tip_catchup_verified"]) is int
        assert saved["tip_catchup_verified"] == 1
    else:
        assert "tip_catchup_verified" not in saved


@pytest.mark.parametrize("marker", [True, False, None, 0, 2, 1.0, "1"])
@pytest.mark.parametrize("has_db", [False, True])
def test_unknown_marker_never_discards_goldens_or_bootstraps(cache_files, marker, has_db):
    module, db_path = cache_files
    module.save_cache("signet", str(db_path))
    hashes_path = Path(module.get_hashes_path("signet"))
    metadata = json.loads(hashes_path.read_text())
    metadata["tip_catchup_verified"] = marker
    # A future/unknown flow must fail before even malformed hashes trigger discard.
    metadata["hashes"] = []
    hashes_path.write_text(json.dumps(metadata))
    original_bytes = hashes_path.read_bytes()
    cached_db = Path(module.get_cached_db_path("signet"))
    if not has_db:
        cached_db.unlink()
    with pytest.raises(ValueError, match="Unsupported integration cache"):
        module.cache_exists("signet")
    assert hashes_path.read_bytes() == original_bytes
    assert cached_db.exists() is has_db


@pytest.mark.parametrize("network", ["signet", "testnet4"])
def test_state_db_build_uses_the_prepared_network_and_cache_paths(monkeypatch, network):
    monkeypatch.syspath_prepend(str(Path(__file__).resolve().parents[1] / "integrations"))
    module = importlib.import_module("reparsetest")
    prepared_command = Mock()
    command_factory = Mock(bake=Mock(return_value=prepared_command))
    monkeypatch.setattr(module.sh, "counterparty_server", command_factory)
    command, server_args, _, _ = module.prepare(network, use_existing_data=True)
    command("build-state-db")
    prepared_command.assert_called_once_with("build-state-db")
    command_factory.bake.assert_called_once_with(
        *server_args, _out=module.sys.stdout, _err_to_out=True
    )
    assert f"--{network}" in server_args
    for flag in ("--data-dir", "--cache-dir"):
        assert server_args[server_args.index(flag) + 1] == module.DATA_DIR
