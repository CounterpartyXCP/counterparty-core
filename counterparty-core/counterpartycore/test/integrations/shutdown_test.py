"""Shutdown coverage for the API process (issue #3486).

Two complementary tests:

- `test_waitress_shutdown_interrupts_blocked_node_status_query` is local and
  deterministic. It drives the production WSGI backend against a genuinely
  blocked APSW query, so it cannot turn a missing public backend into a passing
  skip, and it fails if the cross-thread interrupt stops working.
- `test_shutdown` is the end-to-end counterpart: a real testnet4 server, started
  and stopped, asserting that every thread reports its own stop, that the API
  child exits inside the parent's budget, and that the port is released. It needs
  the public testnet4 backend and skips if that backend rate-limits the start --
  which is why the deterministic test above exists, not a reason to drop this one.
"""

import logging
import random
import re
import socket
import threading
import time
from io import StringIO
from types import SimpleNamespace

import apsw
import pytest
from counterpartycore.lib import config
from counterpartycore.lib.api import wsgi
from counterpartycore.lib.cli import server
from counterpartycore.lib.cli.initialise import initialise_log_and_config
from counterpartycore.lib.cli.main import arg_parser
from counterpartycore.test.integrations import reparsetest

# Marker logged once every essential thread has been started.
SERVER_READY_LOG = "Watching for new blocks..."
# Generous timeout for the server to reach the "ready" state. Hitting it
# almost always means the public testnet4 backend rate-limited us during
# startup (429), not a real shutdown regression -- skip instead of fail.
SERVER_READY_TIMEOUT = 180
# The parent force-kills the API child after ten seconds. Staying inside that
# budget is the whole point of #3486, so assert it rather than just the exit.
API_CHILD_STOP_BUDGET = 10


def test_waitress_shutdown_interrupts_blocked_node_status_query(monkeypatch, tmp_path):
    """Exercise the production WSGI backend with a real cross-thread SQLite interrupt.

    This test is deliberately local and deterministic: it cannot turn a missing
    public backend into a passing skip, as the former Testnet4 shutdown test did.
    """
    state_db = apsw.Connection(str(tmp_path / "state.db"))
    query_started = threading.Event()

    def progress_handler():
        query_started.set()
        return False

    state_db.set_progress_handler(progress_handler, 100)

    def blocked_refresh(connection, _shared_backend_height):
        connection.execute(
            """
            WITH RECURSIVE counter(value) AS (
                VALUES(0)
                UNION ALL
                SELECT value + 1 FROM counter WHERE value < 1000000000
            )
            SELECT sum(value) FROM counter
            """
        ).fetchone()

    monkeypatch.setattr(wsgi.database, "get_db_connection", lambda _path: state_db)
    monkeypatch.setattr(wsgi, "refresh_current_state", blocked_refresh)
    monkeypatch.setattr(wsgi.config, "API_HOST", "127.0.0.1", raising=False)
    monkeypatch.setattr(wsgi.config, "API_PORT", 0, raising=False)
    monkeypatch.setattr(wsgi.config, "WAITRESS_THREADS", 1, raising=False)
    monkeypatch.setattr(wsgi.config, "STATE_DATABASE", str(tmp_path / "state.db"), raising=False)
    monkeypatch.setattr(
        wsgi.log,
        "re_set_up",
        lambda *_args, **_kwargs: logging.getLogger(config.LOGGER_NAME),
    )
    monkeypatch.setattr(wsgi.CurrentState, "set_backend_height_value", lambda _self, _value: None)

    def application(_environ, start_response):
        start_response("200 OK", [("Content-Type", "text/plain")])
        return [b"ok"]

    waitress = wsgi.WaitressApplication(application)
    server_errors = []

    def run_server():
        try:
            waitress.run(SimpleNamespace(value=0), SimpleNamespace(value=0))
        except Exception as exc:  # pragma: no cover  # pylint: disable=broad-exception-caught
            server_errors.append(exc)

    server_thread = threading.Thread(target=run_server, name="WaitressIntegration")
    server_thread.start()
    try:
        assert query_started.wait(timeout=5), (
            f"NodeStatusChecker never entered the blocking query; server errors: {server_errors!r}"
        )

        started_at = time.monotonic()
        waitress.stop(deadline=started_at + 2)
        elapsed = time.monotonic() - started_at
        server_thread.join(timeout=2)
    finally:
        if server_thread.is_alive():
            waitress.stop(deadline=time.monotonic() + 2)
            server_thread.join(timeout=2)

    assert elapsed < 2
    assert not waitress.current_state_thread.is_alive()
    assert not server_thread.is_alive()
    assert server_errors == []


def is_port_in_used(port):
    s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    try:
        s.bind(("127.0.0.1", port))
        return False
    except socket.error:
        return True
    finally:
        s.close()


def wait_for_server_ready(log_stream, timeout):
    deadline = time.time() + timeout
    while time.time() < deadline:
        if SERVER_READY_LOG in log_stream.getvalue():
            return True
        time.sleep(0.5)
    return False


def test_shutdown():
    reparsetest.prepare("testnet4")

    counterparty_server = None
    log_stream = StringIO()
    try:
        parser = arg_parser(no_config_file=True)
        args = parser.parse_args(
            [
                "--testnet4",
                "--data-dir",
                reparsetest.DATA_DIR,
                "--cache-dir",
                reparsetest.DATA_DIR,
                "start",
                "--backend-connect",
                "testnet4.counterparty.io",
                "--backend-port",
                "48332",
                "--backend-ssl",
                "--wsgi-server",
                "gunicorn",
            ]
        )

        initialise_log_and_config(args, log_stream=log_stream)

        counterparty_server = server.CounterpartyServer(args, log_stream)
        counterparty_server.start()

        if not wait_for_server_ready(log_stream, SERVER_READY_TIMEOUT):
            pytest.skip(
                f"Server did not reach ready state within {SERVER_READY_TIMEOUT}s "
                "(likely backend rate-limit); cannot validate shutdown."
            )

        # Server is fully up. Let it run a random extra duration so shutdown
        # is exercised at varying points in the steady-state loop.
        extra_duration = random.randint(10, 60)  # noqa S311
        print("Extra run duration after ready: ", extra_duration)
        deadline = time.time() + extra_duration
        while time.time() < deadline:
            counterparty_server.join(1)

    finally:
        print("Shutting down server...")
        if counterparty_server is not None:
            counterparty_server.stop()

    logs = log_stream.getvalue()

    assert "Ledger.Main - Shutting down..." in logs
    assert "Ledger.Main - Asset Conservation Checker thread stopped." in logs
    assert "Ledger.BackendHeight - BackendHeight Thread stopped." in logs
    assert "Ledger.Main - Shutdown complete." in logs
    # No v1 assertion: the legacy JSON-RPC API is off unless `--enable-api-v1` is
    # passed, so this exercises the default deployment, where it never starts.

    # The API child must stop on its own, inside the parent's grace period: the
    # incident behind #3486 was a child that did not and had to be force-killed,
    # which then made the next start pay a cold-cache API watcher init.
    assert "Terminating forcefully" not in logs
    assert "API Server process is still alive" not in logs

    # Two acceptable outcomes, and neither involves a kill: the parent timed the
    # child's exit, or the child had already exited on its own by the time the
    # parent got to it (the stop event reaches it before the signal does).
    stopped = re.search(r"Ledger\.Main - API Server process stopped in ([0-9.]+)s\.", logs)
    already_stopped = "Ledger.Main - API Server process was already stopped." in logs
    assert stopped is not None or already_stopped, "API Server process did not report a clean stop"
    if stopped is not None:
        assert float(stopped.group(1)) < API_CHILD_STOP_BUDGET

    assert not is_port_in_used(44000)
