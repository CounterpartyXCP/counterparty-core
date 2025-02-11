import os
import sys
import tempfile
import time

import apsw
import requests
import sh
from http2https import PROXY_PORT, start_http_proxy, stop_http_proxy

DATA_DIR = os.path.join(tempfile.gettempdir(), "counterparty-data")


def prepare(network):
    if os.path.exists(DATA_DIR):
        sh.rm("-rf", DATA_DIR)
    sh.mkdir(DATA_DIR)

    args = [
        "-vv",
        "--data-dir",
        DATA_DIR,
        "--cache-dir",
        DATA_DIR,
        "--no-confirm",
        "--backend-connect",
        "127.0.0.1",
        "--backend-port",
        PROXY_PORT,
    ]
    if network == "testnet4":
        args.append("--testnet4")
        backend_url = "https://testnet4.counterparty.io:48332"
        db_file = "counterparty.testnet4.db"
        api_url = "http://localhost:44000/v2/"
    else:
        backend_url = "https://api.counterparty.io:8332"
        db_file = "counterparty.db"
        api_url = "http://localhost:4000/v2/"

    db_file = os.path.join(DATA_DIR, db_file)
    sh_counterparty_server = sh.counterparty_server.bake(*args, _out=sys.stdout, _err_to_out=True)

    return sh_counterparty_server, backend_url, db_file, api_url


def bootstrap(sh_counterparty_server):
    sh_counterparty_server("bootstrap")


def reparse(sh_counterparty_server, db_file):
    db = apsw.Connection(os.path.join(DATA_DIR, db_file))
    last_block = db.execute(
        "SELECT block_index, ledger_hash, txlist_hash FROM blocks ORDER BY block_index DESC LIMIT 1"
    ).fetchone()
    last_block_index = last_block[0]
    ledger_hash_before = last_block[1]
    txlist_hash_before = last_block[2]
    db.close()

    reparse_from = last_block_index - 1000

    sh_counterparty_server("reparse", reparse_from)

    db = apsw.Connection(os.path.join(DATA_DIR, db_file))
    last_block = db.execute(
        "SELECT ledger_hash, txlist_hash FROM blocks ORDER BY block_index DESC LIMIT 1"
    ).fetchone()
    ledger_hash_after = last_block[0]
    txlist_hash_after = last_block[1]
    db.close()

    assert ledger_hash_before == ledger_hash_after
    assert txlist_hash_before == txlist_hash_after


def catchup(sh_counterparty_server, backend_url, api_url):
    try:
        start_http_proxy(backend_url)
        server_process = sh_counterparty_server("start", _bg=True)

        server_ready = False
        while not server_ready:
            try:
                server_ready = requests.get(api_url, timeout=5).json()["result"]["server_ready"]
                if not server_ready:
                    print("Waiting for server to be ready...")
                    time.sleep(1)
            except Exception:
                # print(e)
                time.sleep(1)
                pass
    finally:
        stop_http_proxy()
        server_process.terminate()


def cleanup():
    sh.rm("-rf", DATA_DIR)


def bootstrap_reparse_and_catchup(network):
    sh_counterparty_server, backend_url, db_file, api_url = prepare(network)

    bootstrap(sh_counterparty_server)
    reparse(sh_counterparty_server, db_file)
    catchup(sh_counterparty_server, backend_url, api_url)

    cleanup()
