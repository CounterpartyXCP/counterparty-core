import os
import sys
import tempfile
import time

import apsw
import requests
import sh


def bootstrap_and_reparse(network):
    DATA_DIR = os.path.join(tempfile.gettempdir(), "counterparty-data")
    if os.path.exists(DATA_DIR):
        sh.rm("-rf", DATA_DIR)
    sh.mkdir(DATA_DIR)

    args = [
        "-vv",
        "--data-dir",
        DATA_DIR,
        "--no-confirm",
        # "--backend-ssl",
    ]
    if network == "testnet4":
        args.append("--testnet4")
        # args += ["--backend-connect", "testnet4.counterparty.io"]
        db_file = "counterparty.testnet4.db"
        api_url = "http://localhost:44000/v2/"
    else:
        args += ["--backend-connect", "api.counterparty.io"]
        db_file = "counterparty.db"
        api_url = "http://localhost:4000/v2/"

    sh_counterparty_server = sh.counterparty_server.bake(*args, _out=sys.stdout, _err_to_out=True)

    sh_counterparty_server("bootstrap")

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

    if False:
        server_process = sh_counterparty_server("start", _bg=True)

        server_ready = False
        while not server_ready:
            try:
                server_ready = requests.get(api_url, timeout=5).json()["result"]["server_ready"]
                if not server_ready:
                    print("Waiting for server to be ready...")
                    time.sleep(1)
            except Exception as e:
                print(e)
                time.sleep(1)
                pass

        server_process.terminate()

    sh.rm("-rf", DATA_DIR)


def test_reparse():
    bootstrap_and_reparse("testnet4")
    # bootstrap_and_reparse("mainnet")
