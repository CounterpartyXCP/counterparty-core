import os
import sys
import time

import apsw
import requests
import sh
from counterpartycore.lib.messages.data import checkpoints

# DATA_DIR = os.path.join(tempfile.gettempdir(), "counterparty-data")
DATA_DIR = os.path.join(os.path.expanduser("~/.cache"), "counterparty-test-data")


def prepare(network):
    if os.path.exists(DATA_DIR):
        sh.rm("-rf", DATA_DIR)
    sh.mkdir(DATA_DIR)

    args = [
        # "-vv",
        "--data-dir",
        DATA_DIR,
        "--cache-dir",
        DATA_DIR,
        "--no-confirm",
        "--backend-ssl",
    ]
    if network == "testnet4":
        args += [
            "--testnet4",
            "--backend-connect",
            "testnet4.counterparty.io",
            "--backend-port",
            "48332",
            "--profile",
        ]
        db_file = "counterparty.testnet4.db"
        api_url = "http://localhost:44000/v2/"
    elif network == "signet":
        args += [
            "--signet",
            "--backend-connect",
            "signet.counterparty.io",
            "--backend-port",
            "38332",
            "--profile",
        ]
        db_file = "counterparty.signet.db"
        api_url = "http://localhost:34000/v2/"
    else:
        args += ["--backend-connect", "api.counterparty.io", "--backend-port", "8332"]
        db_file = "counterparty.db"
        api_url = "http://localhost:4000/v2/"

    db_file = os.path.join(DATA_DIR, db_file)
    sh_counterparty_server = sh.counterparty_server.bake(*args, _out=sys.stdout, _err_to_out=True)

    return sh_counterparty_server, db_file, api_url


def bootstrap(sh_counterparty_server, network="testnet4"):
    sh_counterparty_server(
        "bootstrap",
        "--bootstrap-url",
        f"https://storage.googleapis.com/counterparty-bootstrap/counterparty.{network}.db.latest.zst",
    )


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


def rolllback(sh_counterparty_server, network):
    if network == "testnet4":
        network_checkpoints = checkpoints.CHECKPOINTS_TESTNET4
    elif network == "signet":
        network_checkpoints = checkpoints.CHECKPOINTS_SIGNET
    else:
        network_checkpoints = checkpoints.CHECKPOINTS_MAINNET
    rollback_from = max(0, list(network_checkpoints.keys())[-1] - 200000)
    sh_counterparty_server("rollback", rollback_from)


def catchup(sh_counterparty_server, api_url):
    try:
        server_process = sh_counterparty_server("start", _bg=True)

        server_ready = False
        start_time = time.time()
        error = None
        while not server_ready:
            try:
                server_ready = requests.get(api_url, timeout=5).json()["result"]["server_ready"]
                if not server_ready:
                    print("Waiting for server to be ready...")
                    time.sleep(1)
            except Exception:
                # after 20 minutes we should not have an error
                # unless the server crashed
                if time.time() - start_time > 60 * 20:
                    error = "Timeout: not ready after 20 minutes"
                    break
                time.sleep(1)
                pass
    finally:
        server_process.terminate()
        if error:
            raise Exception(error)


def cleanup():
    sh.rm("-rf", DATA_DIR)


def bootstrap_reparse_rollback_and_catchup(network):
    sh_counterparty_server, db_file, api_url = prepare(network)

    bootstrap(sh_counterparty_server, network)
    reparse(sh_counterparty_server, db_file)
    rolllback(sh_counterparty_server, network)
    catchup(sh_counterparty_server, api_url)

    cleanup()
