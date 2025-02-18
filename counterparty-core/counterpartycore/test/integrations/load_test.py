import time
from io import StringIO

from counterpartycore.test.integrations import reparsetest
from counterpartycore.test.integrations.locustrunner import run_locust


def test_load():
    sh_counterparty_server, backend_url, db_file, api_url = reparsetest.prepare("mainnet")
    sh_counterparty_server("bootstrap")

    try:
        out = StringIO()
        server_process = sh_counterparty_server(
            "start",
            "--api-only",
            "--backend-connect",
            "api.counterparty.io",
            "--backend-port",
            "8332",
            "--backend-ssl",
            "--wsgi-server",
            "gunicorn",
            _bg=True,
            _out=out,
            _err_to_out=True,
        )

        while "API.Watcher - Catch up completed" not in out.getvalue():
            print("Waiting for server to be ready...")
            time.sleep(1)

        env = run_locust(db_file)

        print(env.stats.serialize_errors())
        assert env.stats.total.num_failures == 0
        assert env.stats.total.avg_response_time < 1500  # ms
        assert env.stats.total.get_response_time_percentile(0.95) < 2000  # ms
    finally:
        print(out.getvalue())
        server_process.terminate()
