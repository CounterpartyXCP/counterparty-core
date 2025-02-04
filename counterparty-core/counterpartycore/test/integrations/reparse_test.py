import os
import sys
import tempfile

import apsw
import sh


def test_reparse_testnet4():
    DATA_DIR = os.path.join(tempfile.gettempdir(), "counterparty-data")
    if os.path.exists(DATA_DIR):
        sh.rm("-rf", DATA_DIR)
    sh.mkdir(DATA_DIR)

    sh.counterparty_server(
        "--testnet4",
        "-vv",
        "--data-dir",
        DATA_DIR,
        "--no-confirm",
        "bootstrap",
        _out=sys.stdout,
        _err_to_out=True,
    )

    db = apsw.Connection(os.path.join(DATA_DIR, "counterparty.testnet4.db"))
    last_block = db.execute(
        "SELECT block_index, ledger_hash, txlist_hash FROM blocks ORDER BY block_index DESC LIMIT 1"
    ).fetchone()
    last_block_index = last_block[0]
    ledger_hash_before = last_block[1]
    txlist_hash_before = last_block[2]
    db.close()

    reparse_from = last_block_index - 1000

    sh.counterparty_server(
        "--testnet4",
        "-vv",
        "--data-dir",
        DATA_DIR,
        "reparse",
        reparse_from,
        _out=sys.stdout,
        _err_to_out=True,
    )

    db = apsw.Connection(os.path.join(DATA_DIR, "counterparty.testnet4.db"))
    last_block = db.execute(
        "SELECT ledger_hash, txlist_hash FROM blocks ORDER BY block_index DESC LIMIT 1"
    ).fetchone()
    ledger_hash_after = last_block[0]
    txlist_hash_after = last_block[1]
    db.close()

    assert ledger_hash_before == ledger_hash_after
    assert txlist_hash_before == txlist_hash_after

    sh.rm("-rf", DATA_DIR)
