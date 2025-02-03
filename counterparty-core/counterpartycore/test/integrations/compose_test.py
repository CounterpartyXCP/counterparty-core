import os
import sys
import tempfile
import time
from io import StringIO

import requests
import sh


def print_docker_output(out, printed_line_count):
    unprinted_lines = out.getvalue().splitlines()[printed_line_count:]
    printed_line = []
    for line in unprinted_lines:
        print(line)
        printed_line.append(line)
        printed_line_count += 1
    return printed_line_count, "\n".join(printed_line)


def rpc_call(url, method, params):
    import json

    headers = {"content-type": "application/json"}
    payload = {
        "method": method,
        "params": params,
        "jsonrpc": "2.0",
        "id": 0,
    }
    return requests.post(
        url,
        data=json.dumps(payload),
        headers=headers,
        timeout=30,
    ).json()


def test_docker_compose():
    sh.docker("system", "prune", "--all", "--force", _out=sys.stdout, _err_to_out=True)

    try:
        DATA_DIR = os.path.join(tempfile.gettempdir(), "counterparty-docker-data")
        print(f"DATA_DIR: {DATA_DIR}")
        if os.path.exists(DATA_DIR):
            with sh.contrib.sudo(password="", _with=True):
                sh.rm("-rf", DATA_DIR)
        os.makedirs(DATA_DIR)

        out = StringIO()
        sh.docker(
            "compose",
            "--profile",
            "regtest",
            "up",
            _bg=True,
            _out=out,
            _err_to_out=True,
            _env={"COUNTERPARTY_DOCKER_DATA": DATA_DIR},
        )
        printed_line_count = 0
        start_time = time.time()
        while True:
            printed_line_count, printed_line = print_docker_output(out, printed_line_count)
            if "Ledger.Main - Watching for new blocks..." in printed_line:
                break
            if time.time() - start_time > 60 * 20:
                raise Exception("Timeout: not ready after 5 minutes")
            time.sleep(0.1)
    finally:
        try:
            sh.docker("compose", "--profile", "regtest", "stop", _out=sys.stdout, _err_to_out=True)
        except sh.ErrorReturnCode:
            pass
        sh.docker("system", "prune", "--all", "--force", _out=sys.stdout, _err_to_out=True)
