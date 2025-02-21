import random
import socket
import time
from io import StringIO

from counterpartycore.lib.cli import server
from counterpartycore.lib.cli.main import arg_parser
from counterpartycore.test.integrations import reparsetest


def is_port_in_used(port):
    s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    try:
        s.bind(("127.0.0.1", port))
        return False
    except socket.error:
        return True
    finally:
        s.close()


def test_shutdown():
    reparsetest.prepare("testnet4")

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

        log_stream = StringIO()
        server.initialise_log_and_config(args, log_stream=log_stream)

        test_duration = random.randint(1, 60)  # noqa S311
        start_time = time.time()

        print("Test duration: ", test_duration)

        counterparty_server = server.CounterpartyServer(args, log_stream)
        counterparty_server.start()
        while time.time() - start_time < test_duration:
            counterparty_server.join(1)

        assert is_port_in_used(44000)

    finally:
        print("Shutting down server...")
        counterparty_server.stop()

    logs = log_stream.getvalue()

    assert "Ledger.Main - Shutting down..." in logs
    assert "Ledger.Main - Asset Conservation Checker thread stopped." in logs
    assert "Ledger.BackendHeight - BackendHeight Thread stopped." in logs
    assert "Ledger.Main - API Server v1 thread stopped." in logs
    assert "Ledger.Main - API Server process stopped." in logs
    assert "Ledger.Main - Shutdown complete." in logs

    assert not is_port_in_used(44000)
