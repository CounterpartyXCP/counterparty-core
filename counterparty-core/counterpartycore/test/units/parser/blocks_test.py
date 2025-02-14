import os
import tempfile

from counterpartycore.lib import config, exceptions, ledger
from counterpartycore.lib.ledger.currentstate import CurrentState
from counterpartycore.lib.messages import send
from counterpartycore.lib.messages.versions import send1
from counterpartycore.lib.parser import blocks


def test_parse_tx_simple(ledger_db, defaults, blockchain_mock, test_helpers):
    _source, _destination, data = send.compose(
        ledger_db, defaults["addresses"][0], defaults["addresses"][1], "XCP", 100
    )
    tx = blockchain_mock.dummy_tx(ledger_db, defaults["addresses"][0], data=data)
    blocks.parse_tx(ledger_db, tx)

    test_helpers.check_records(
        ledger_db,
        [
            {
                "table": "sends",
                "values": {
                    "asset": "XCP",
                    "block_index": tx["block_index"],
                    "destination": defaults["addresses"][1],
                    "quantity": 100,
                    "source": defaults["addresses"][0],
                    "status": "valid",
                    "tx_hash": tx["tx_hash"],
                    "tx_index": tx["tx_index"],
                },
            }
        ],
    )


def test_parse_tx_multisig(ledger_db, defaults, blockchain_mock, test_helpers):
    _source, _destination, data = send1.compose(
        ledger_db, defaults["addresses"][0], defaults["p2ms_addresses"][0], "XCP", 100
    )
    tx = blockchain_mock.dummy_tx(
        ledger_db, defaults["addresses"][0], defaults["p2ms_addresses"][0], data=data
    )
    blocks.parse_tx(ledger_db, tx)

    test_helpers.check_records(
        ledger_db,
        [
            {
                "table": "sends",
                "values": {
                    "asset": "XCP",
                    "block_index": tx["block_index"],
                    "destination": defaults["p2ms_addresses"][0],
                    "quantity": 100,
                    "source": defaults["addresses"][0],
                    "status": "valid",
                    "tx_hash": tx["tx_hash"],
                    "tx_index": tx["tx_index"],
                },
            }
        ],
    )


def test_check_database_version(ledger_db, test_helpers, caplog, monkeypatch):
    config.UPGRADE_ACTIONS["regtest"] = {
        "10.9.1": [
            ("refresh_state_db",),
            ("reparse", 100),
            ("rollback", 100),
            ("clear_not_supported_cache",),
        ],
    }

    block_first = config.BLOCK_FIRST
    config.BLOCK_FIRST = CurrentState().current_block_index()
    with test_helpers.capture_log(caplog, "New database detected. Updating database version."):
        blocks.check_database_version(ledger_db)
    config.BLOCK_FIRST = block_first

    config.FORCE = True
    with test_helpers.capture_log(caplog, "FORCE mode enabled. Skipping database version check."):
        blocks.check_database_version(ledger_db)
    config.FORCE = False

    version_string = config.VERSION_STRING
    ledger_db.execute("UPDATE config SET value = '9.0.0' WHERE name = 'VERSION_STRING'")
    config.VERSION_STRING = "9.0.0"
    with test_helpers.capture_log(caplog, "Ledger database is up to date."):
        blocks.check_database_version(ledger_db)

    config.VERSION_STRING = "10.9.1"

    def rollback_mock(db, block_index):
        blocks.logger.info("Rolling back to block %s", block_index)

    def reparse_mock(db, block_index):
        blocks.logger.info("Re-parsing from block %s", block_index)

    monkeypatch.setattr("counterpartycore.lib.parser.blocks.rollback", rollback_mock)
    monkeypatch.setattr("counterpartycore.lib.parser.blocks.reparse", reparse_mock)

    cache_dir = config.CACHE_DIR
    config.CACHE_DIR = tempfile.mkdtemp()
    not_supported_file = os.path.join(config.CACHE_DIR, "not_supported_tx_cache.regtest.txt")
    with open(not_supported_file, "w") as f:
        f.write("test")

    with test_helpers.capture_log(
        caplog,
        [
            "Required actions: [('refresh_state_db',), ('reparse', 100), ('rollback', 100), ('clear_not_supported_cache',)]",
            "Re-parsing from block 100",
            "Rolling back to block 100",
            "Database version number updated.",
        ],
    ):
        blocks.check_database_version(ledger_db)

    assert not os.path.exists(not_supported_file)

    config.VERSION_STRING = version_string
    config.CACHE_DIR = cache_dir


def test_rollback(ledger_db, test_helpers, caplog):
    utxos = ledger_db.execute(
        """
        SELECT * FROM (
            SELECT utxo, MAX(rowid), quantity FROM balances GROUP BY utxo
        )
        WHERE utxo IS NOT NULL AND quantity > 0
        """,
    ).fetchall()
    for utxo in utxos:
        assert ledger.caches.UTXOBalancesCache(ledger_db).has_balance(utxo["utxo"])

    last_attach = ledger_db.execute(
        "SELECT * FROM sends WHERE send_type='attach' ORDER BY rowid DESC LIMIT 1"
    ).fetchone()
    assert ledger.caches.UTXOBalancesCache(ledger_db).has_balance(last_attach["destination"])

    blocks.rollback(ledger_db, last_attach["block_index"] - 1)
    assert not ledger.caches.UTXOBalancesCache(ledger_db).has_balance(last_attach["destination"])

    last_block = ledger_db.execute(
        "SELECT block_index, ledger_hash, txlist_hash FROM blocks ORDER BY block_index DESC LIMIT 1"
    ).fetchone()
    assert last_block["block_index"] == last_attach["block_index"] - 2


def test_reparse(ledger_db, test_helpers, caplog):
    last_block = ledger_db.execute(
        "SELECT block_index, ledger_hash, txlist_hash FROM blocks ORDER BY block_index DESC LIMIT 1"
    ).fetchone()
    ledger_hash_before = last_block["ledger_hash"]
    txlist_hash_before = last_block["txlist_hash"]

    utxos = ledger_db.execute(
        """
        SELECT * FROM (
            SELECT utxo, MAX(rowid), quantity FROM balances GROUP BY utxo
        )
        WHERE utxo IS NOT NULL AND quantity > 0
        """,
    ).fetchall()
    for utxo in utxos:
        assert ledger.caches.UTXOBalancesCache(ledger_db).has_balance(utxo["utxo"])

    last_attach = ledger_db.execute(
        "SELECT * FROM sends WHERE send_type='attach' ORDER BY rowid DESC LIMIT 1"
    ).fetchone()
    assert ledger.caches.UTXOBalancesCache(ledger_db).has_balance(last_attach["destination"])

    blocks.reparse(ledger_db, last_attach["block_index"] - 1)
    assert ledger.caches.UTXOBalancesCache(ledger_db).has_balance(last_attach["destination"])

    last_block = ledger_db.execute(
        "SELECT ledger_hash, txlist_hash FROM blocks ORDER BY block_index DESC LIMIT 1"
    ).fetchone()
    ledger_hash_after = last_block["ledger_hash"]
    txlist_hash_after = last_block["txlist_hash"]
    ledger_db.close()

    assert ledger_hash_before == ledger_hash_after
    assert txlist_hash_before == txlist_hash_after


def test_handle_reorg(ledger_db, monkeypatch, test_helpers, caplog):
    def getblockhash_mock(block_index):
        block = ledger_db.execute(
            "SELECT block_hash FROM blocks WHERE block_index = ?", (block_index,)
        ).fetchone()
        if block:
            return block["block_hash"]
        return "newblockhash"

    def deserialize_block_mock(block, parse_vouts, block_index):
        return None

    monkeypatch.setattr("counterpartycore.lib.backend.bitcoind.getblockhash", getblockhash_mock)
    monkeypatch.setattr("counterpartycore.lib.backend.bitcoind.getblock", lambda block_hash: None)
    monkeypatch.setattr(
        "counterpartycore.lib.parser.deserialize.deserialize_block", deserialize_block_mock
    )

    last_block = ledger_db.execute(
        "SELECT block_index, ledger_hash, txlist_hash FROM blocks ORDER BY block_index DESC LIMIT 1"
    ).fetchone()

    with test_helpers.capture_log(
        caplog, f"Ledger DB rolled back to block {last_block['block_index']}"
    ):
        blocks.handle_reorg(ledger_db)


def test_handle_reorg2(ledger_db, monkeypatch, test_helpers, caplog, current_block_index):
    last_attach = ledger_db.execute(
        "SELECT * FROM sends WHERE send_type='attach' ORDER BY rowid DESC LIMIT 1"
    ).fetchone()
    assert ledger.caches.UTXOBalancesCache(ledger_db).has_balance(last_attach["destination"])

    def getblockhash_mock(block_index):
        if block_index >= last_attach["block_index"] - 1:
            return "newblockhash"
        block = ledger_db.execute(
            "SELECT block_hash FROM blocks WHERE block_index = ?", (block_index,)
        ).fetchone()
        if block:
            return block["block_hash"]
        return "newblockhash"

    def deserialize_block_mock(block, parse_vouts, block_index):
        return None

    monkeypatch.setattr("counterpartycore.lib.backend.bitcoind.getblockhash", getblockhash_mock)
    monkeypatch.setattr("counterpartycore.lib.backend.bitcoind.getblock", lambda block_hash: None)
    monkeypatch.setattr(
        "counterpartycore.lib.parser.deserialize.deserialize_block", deserialize_block_mock
    )

    with test_helpers.capture_log(
        caplog, f"Ledger DB rolled back to block {last_attach['block_index'] - 1}"
    ):
        blocks.handle_reorg(ledger_db)

    last_block = ledger_db.execute(
        "SELECT block_index, ledger_hash, txlist_hash FROM blocks ORDER BY block_index DESC LIMIT 1"
    ).fetchone()

    assert last_block["block_index"] == last_attach["block_index"] - 2

    assert not ledger.caches.UTXOBalancesCache(ledger_db).has_balance(last_attach["destination"])


def test_handle_reorg3(ledger_db, monkeypatch, test_helpers, caplog):
    last_block = ledger_db.execute(
        "SELECT block_index, ledger_hash, txlist_hash FROM blocks ORDER BY block_index DESC LIMIT 1"
    ).fetchone()

    def getblockhash_mock(block_index):
        if block_index == last_block["block_index"]:
            raise exceptions.BlockOutOfRange
        block = ledger_db.execute(
            "SELECT block_hash FROM blocks WHERE block_index = ?", (block_index,)
        ).fetchone()
        if block:
            return block["block_hash"]
        return "newblockhash"

    def deserialize_block_mock(block, parse_vouts, block_index):
        return None

    monkeypatch.setattr("counterpartycore.lib.backend.bitcoind.getblockhash", getblockhash_mock)
    monkeypatch.setattr("counterpartycore.lib.backend.bitcoind.getblock", lambda block_hash: None)
    monkeypatch.setattr(
        "counterpartycore.lib.parser.deserialize.deserialize_block", deserialize_block_mock
    )

    with test_helpers.capture_log(
        caplog, f"Ledger DB rolled back to block {last_block['block_index'] - 1}"
    ):
        blocks.handle_reorg(ledger_db)

    last_block_after = ledger_db.execute(
        "SELECT block_index, ledger_hash, txlist_hash FROM blocks ORDER BY block_index DESC LIMIT 1"
    ).fetchone()

    assert last_block_after["block_index"] == last_block["block_index"] - 2
