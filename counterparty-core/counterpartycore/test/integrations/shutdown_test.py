import logging
import threading
import time
from types import SimpleNamespace

import apsw
from counterpartycore.lib import config
from counterpartycore.lib.api import wsgi


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
