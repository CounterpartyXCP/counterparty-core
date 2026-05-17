import random
import socket
import time
from io import StringIO

import pytest

from counterpartycore.lib.cli import server
from counterpartycore.lib.cli.initialise import initialise_log_and_config
from counterpartycore.lib.cli.main import arg_parser
from counterpartycore.test.integrations import reparsetest

# Marker logged once every essential thread has been started.
SERVER_READY_LOG = "Watching for new blocks..."
# Generous timeout for the server to reach the "ready" state. Hitting it
# almost always means the public testnet4 backend rate-limited us during
# startup (429), not a real shutdown regression — skip instead of fail.
SERVER_READY_TIMEOUT = 180


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
    assert "Ledger.Main - API Server v1 thread stopped." in logs
    assert "Ledger.Main - API Server process stopped." in logs
    assert "Ledger.Main - Shutdown complete." in logs

    assert not is_port_in_used(44000)
