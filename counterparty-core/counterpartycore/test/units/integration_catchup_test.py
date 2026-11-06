"""Catchup's total deadline applies to every poll, without live processes or RPC."""

import importlib
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
        process=Mock(pid=9001),
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
    monkeypatch.setattr(
        module, "os", SimpleNamespace(getpgid=lambda pid: 9001, killpg=state.killpg)
    )
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
