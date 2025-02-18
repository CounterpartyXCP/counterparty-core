import os
import random
import signal
import time
from io import StringIO

import sh
from counterpartycore.test.integrations import reparsetest
from http2https import PROXY_PORT, start_http_proxy, stop_http_proxy


def test_shutdown():
    sh_counterparty_server, backend_url, db_file, api_url = reparsetest.prepare("mainnet")

    out = StringIO()
    try:
        start_http_proxy(backend_url)
        server_process = sh_counterparty_server(
            "start",
            "--backend-connect",
            "127.0.0.1",
            "--backend-port",
            PROXY_PORT,
            "--wsgi-server",
            "gunicorn",
            _bg=True,
            _out=out,
            _err_to_out=True,
            _bg_exc=False,
        )

        duration = random.randint(1, 60)  # noqa S311
        start_time = time.time()

        print(f"Waiting random time: {duration}s")
        while time.time() - start_time < duration:
            time.sleep(1)

        print("Shutting down server...")
        # server_process.terminate()
        os.kill(server_process.pid, signal.SIGTERM)

    except sh.SignalException_SIGTERM:
        pass
    finally:
        print("Waiting for server to shutdown...")
        time.sleep(30)
        stop_http_proxy()
        print(out.getvalue())
