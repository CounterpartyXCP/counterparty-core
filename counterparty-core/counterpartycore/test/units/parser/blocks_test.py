import os
import struct
import tempfile
import time

import pytest
from counterpartycore.lib import backend, config, exceptions, ledger
from counterpartycore.lib.ledger.currentstate import CurrentState
from counterpartycore.lib.messages import (
    cancel,
    destroy,
    dividend,
    send,
    sweep,
)
from counterpartycore.lib.messages.versions import mpma, send1
from counterpartycore.lib.parser import blocks, messagetype
from counterpartycore.lib.utils import database, hashcodec


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
            SELECT utxo_tx_hash, utxo_vout, MAX(rowid), quantity FROM balances
            GROUP BY utxo_tx_hash, utxo_vout
        )
        WHERE utxo_tx_hash IS NOT NULL AND quantity > 0
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


def test_rollback_clears_bitcoind_caches(ledger_db, test_helpers):
    backend.bitcoind.TRANSACTIONS_CACHE["deadbeef"] = {"sentinel": True}
    last_attach = ledger_db.execute(
        "SELECT * FROM sends WHERE send_type='attach' ORDER BY rowid DESC LIMIT 1"
    ).fetchone()
    blocks.rollback(ledger_db, last_attach["block_index"] - 1)
    assert "deadbeef" not in backend.bitcoind.TRANSACTIONS_CACHE


def test_rollback_cleans_orphaned_transactions_status(ledger_db, test_helpers):
    last_attach = ledger_db.execute(
        "SELECT * FROM sends WHERE send_type='attach' ORDER BY rowid DESC LIMIT 1"
    ).fetchone()
    rollback_to = last_attach["block_index"] - 1

    orphan_tx_indexes = [
        row["tx_index"]
        for row in ledger_db.execute(
            "SELECT tx_index FROM transactions WHERE block_index >= ?", (rollback_to,)
        ).fetchall()
    ]
    assert len(orphan_tx_indexes) > 0, "test prerequisite: need txs to be rolled back"

    blocks.rollback(ledger_db, rollback_to)

    leftover = ledger_db.execute(
        """SELECT COUNT(*) AS cnt FROM transactions_status
           WHERE tx_index NOT IN (SELECT tx_index FROM transactions)"""
    ).fetchone()["cnt"]
    assert leftover == 0


def test_reparse(ledger_db, test_helpers, caplog):
    last_block = ledger_db.execute(
        "SELECT block_index, ledger_hash, txlist_hash FROM blocks ORDER BY block_index DESC LIMIT 1"
    ).fetchone()
    ledger_hash_before = last_block["ledger_hash"]
    txlist_hash_before = last_block["txlist_hash"]

    utxos = ledger_db.execute(
        """
        SELECT * FROM (
            SELECT utxo_tx_hash, utxo_vout, MAX(rowid), quantity FROM balances
            GROUP BY utxo_tx_hash, utxo_vout
        )
        WHERE utxo_tx_hash IS NOT NULL AND quantity > 0
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


def test_create_events_indexes(ledger_db):
    sql = "SELECT * FROM sqlite_master WHERE type= 'index' and tbl_name = 'messages'"
    # The compact-hash-storage migration (0010) now creates the runtime
    # ``messages`` indexes inline so ``--api-only`` deployments don't end
    # up with an unindexed messages table. Reset state to exercise the
    # legacy lazy-creation path the helper still has to support.
    for row in ledger_db.execute(sql).fetchall():
        ledger_db.execute(f"DROP INDEX IF EXISTS {row['name']}")  # noqa: S608 # nosec B608
    database.set_config_value(ledger_db, "EVENTS_INDEXES_CREATED", None)
    assert len(ledger_db.execute(sql).fetchall()) == 0
    assert database.get_config_value(ledger_db, "EVENTS_INDEXES_CREATED") is None

    blocks.create_events_indexes(ledger_db)

    assert len(ledger_db.execute(sql).fetchall()) == 6
    assert database.get_config_value(ledger_db, "EVENTS_INDEXES_CREATED") == "True"

    # Calling again is a no-op (``CREATE INDEX IF NOT EXISTS`` is idempotent;
    # the flag-based short-circuit was dropped because it silently skipped
    # creation on DBs where 0010 had dropped the indexes but left the flag).
    blocks.create_events_indexes(ledger_db)
    assert len(ledger_db.execute(sql).fetchall()) == 6


# Tests for update_transaction with unsupported transactions (lines 110-119)
def test_update_transaction_unsupported(ledger_db, defaults, blockchain_mock, test_helpers, caplog):
    """Test update_transaction when transaction is not supported"""
    tx = blockchain_mock.dummy_tx(ledger_db, defaults["addresses"][0], data=b"\x00\x00")
    with test_helpers.capture_log(caplog, "Unsupported transaction"):
        blocks.update_transaction(ledger_db, tx, supported=False)

    # Check that the transaction was marked as unsupported
    cursor = ledger_db.cursor()
    result = cursor.execute(
        "SELECT supported FROM transactions WHERE tx_hash = ?",
        (hashcodec.hash_to_db(tx["tx_hash"]),),
    ).fetchone()
    assert result["supported"] == 0


def test_update_transaction_unsupported_mempool(ledger_db, defaults, blockchain_mock, caplog):
    """Test update_transaction for mempool transactions (no log)"""
    tx = blockchain_mock.dummy_tx(ledger_db, defaults["addresses"][0], data=b"\x00\x00")
    tx["block_index"] = config.MEMPOOL_BLOCK_INDEX
    # Should not log for mempool transactions
    blocks.update_transaction(ledger_db, tx, supported=False)
    assert "Unsupported transaction" not in caplog.text


# Test for parse_tx with struct.error (lines 135-137)
def test_parse_tx_struct_error(ledger_db, defaults, blockchain_mock):
    """Test parse_tx when struct.error is raised during message unpacking"""
    # Create a transaction with invalid data that causes struct.error
    # The data is too short to be unpacked properly
    tx = blockchain_mock.dummy_tx(ledger_db, defaults["addresses"][0], data=b"\x00")
    result = blocks.parse_tx(ledger_db, tx)
    # Should return False for unsupported transaction
    assert result is False


# Test for parse_tx with source containing hyphen (line 155)
def test_parse_tx_source_with_hyphen(ledger_db, defaults, blockchain_mock):
    """Test parse_tx returns False when source contains hyphen (internal format)"""
    tx = blockchain_mock.dummy_tx(ledger_db, defaults["addresses"][0], data=b"\x00\x00\x00\x00")
    # Set source to format with hyphen (triggers split("-") check)
    tx["source"] = "abc-123"
    result = blocks.parse_tx(ledger_db, tx)
    assert result is False


def test_parse_tx_destination_with_hyphen(ledger_db, defaults, blockchain_mock):
    """Test parse_tx returns False when destination contains hyphen"""
    tx = blockchain_mock.dummy_tx(ledger_db, defaults["addresses"][0], data=b"\x00\x00\x00\x00")
    tx["destination"] = "abc-123"
    result = blocks.parse_tx(ledger_db, tx)
    assert result is False


def test_parse_tx_no_source(ledger_db, defaults, blockchain_mock):
    """Test parse_tx returns False when source is empty"""
    tx = blockchain_mock.dummy_tx(ledger_db, defaults["addresses"][0], data=b"\x00\x00\x00\x00")
    tx["source"] = ""
    result = blocks.parse_tx(ledger_db, tx)
    assert result is False


# Test for parse_tx with unsupported message type (lines 238-239)
def test_parse_tx_unsupported_message_type(ledger_db, defaults, blockchain_mock):
    """Test parse_tx with an unsupported message type ID"""
    # Use a message type ID that doesn't match any known type
    data = struct.pack(">I", 9999) + b"test"  # Unknown message type 9999
    tx = blockchain_mock.dummy_tx(ledger_db, defaults["addresses"][0], data=data)
    result = blocks.parse_tx(ledger_db, tx)
    # The transaction was processed but not supported
    assert result is False


# Test for parse_tx exception handling (lines 245-246)
def test_parse_tx_exception(ledger_db, defaults, blockchain_mock, monkeypatch):
    """Test parse_tx raises ParseTransactionError on exception"""
    _source, _destination, data = send.compose(
        ledger_db, defaults["addresses"][0], defaults["addresses"][1], "XCP", 100
    )
    tx = blockchain_mock.dummy_tx(ledger_db, defaults["addresses"][0], data=data)

    # Mock enhancedsend.parse to raise an exception (send.parse calls enhancedsend.parse)
    def mock_parse(*args, **kwargs):
        raise ValueError("Test error")

    monkeypatch.setattr("counterpartycore.lib.messages.versions.enhancedsend.parse", mock_parse)

    with pytest.raises(exceptions.ParseTransactionError, match="Test error"):
        blocks.parse_tx(ledger_db, tx)


# Test for replay_transactions_events with transaction_outputs (lines 287-295)
def test_replay_transactions_events_with_outputs(ledger_db):
    """Test replay_transactions_events includes transaction_outputs"""
    # Get a transaction that has outputs
    cursor = ledger_db.cursor()
    tx_with_outputs = cursor.execute("""
        SELECT t.* FROM transactions t
        JOIN transaction_outputs o ON t.tx_index = o.tx_index
        LIMIT 1
    """).fetchone()

    if tx_with_outputs:
        transactions = [tx_with_outputs]
        # This should not raise any errors
        blocks.replay_transactions_events(ledger_db, transactions)


# Test for parse_block with ParseTransactionError (lines 373-375)
def test_parse_block_transaction_error(ledger_db, monkeypatch, caplog, test_helpers):
    """Test parse_block handles ParseTransactionError"""
    # Get a block with transactions
    cursor = ledger_db.cursor()
    block = cursor.execute(
        "SELECT * FROM blocks WHERE transaction_count > 0 ORDER BY block_index DESC LIMIT 1"
    ).fetchone()

    if block:
        # Set current block index to match the block we're parsing
        CurrentState().set_current_block_index(block["block_index"])

        # Mock parse_tx to raise ParseTransactionError
        def mock_parse_tx(db, tx):
            raise exceptions.ParseTransactionError("Test parse error")

        monkeypatch.setattr("counterpartycore.lib.parser.blocks.parse_tx", mock_parse_tx)

        with pytest.raises(exceptions.ParseTransactionError):
            with test_helpers.capture_log(caplog, "ParseTransactionError"):
                blocks.parse_block(ledger_db, block["block_index"], block["block_time"])


# Test for parse_block mempool case (lines 453-454)
def test_parse_block_mempool(ledger_db):
    """Test parse_block for mempool block returns None values"""
    result = blocks.parse_block(
        ledger_db,
        config.MEMPOOL_BLOCK_INDEX,
        int(time.time()),
    )
    # Mempool blocks return 4 None values
    assert result == (None, None, None, None)


# Test for list_tx mempool handling (lines 468-473)
def test_list_tx_mempool(ledger_db, blockchain_mock, defaults, monkeypatch):
    """Test list_tx for mempool transactions"""
    # Create a decoded tx for mempool
    tx_hash = blockchain_mock.get_dummy_tx_hash(defaults["addresses"][0])

    # Mock get_tx_info to return no counterparty data
    def mock_get_tx_info(db, decoded_tx, block_index):
        return (defaults["addresses"][0], None, 0, 1000, None, None, [])

    monkeypatch.setattr("counterpartycore.lib.parser.blocks.get_tx_info", mock_get_tx_info)

    decoded_tx = {
        "tx_id": tx_hash,
        "tx_hash": tx_hash,
        "coinbase": False,
        "vin": [],
        "vout": [],
    }

    tx_index = blocks.list_tx(
        ledger_db,
        config.MEMPOOL_BLOCK_HASH,
        config.MEMPOOL_BLOCK_INDEX,
        int(time.time()),
        tx_hash,
        100,
        decoded_tx,
    )
    # For non-counterparty tx, tx_index should remain unchanged
    assert tx_index == 100


def test_list_tx_mempool_existing(ledger_db, blockchain_mock, defaults, monkeypatch):
    """Test list_tx returns early for existing mempool transaction"""
    # Get an existing transaction
    existing_tx = ledger_db.execute(
        "SELECT * FROM transactions ORDER BY tx_index DESC LIMIT 1"
    ).fetchone()

    # Mock get_tx_info - but it shouldn't be called since tx exists
    def mock_get_tx_info(db, decoded_tx, block_index):
        return (existing_tx["source"], None, 0, 1000, b"\x00\x00", None, ["", "", "2", "1"])

    monkeypatch.setattr("counterpartycore.lib.parser.blocks.get_tx_info", mock_get_tx_info)

    decoded_tx = {
        "tx_id": existing_tx["tx_hash"],
        "tx_hash": existing_tx["tx_hash"],
        "coinbase": False,
        "vin": [],
        "vout": [],
    }

    tx_index = blocks.list_tx(
        ledger_db,
        config.MEMPOOL_BLOCK_HASH,
        config.MEMPOOL_BLOCK_INDEX,
        int(time.time()),
        existing_tx["tx_hash"],
        100,
        decoded_tx,
    )
    # Should return the same tx_index (not incremented) because tx already exists
    assert tx_index == 100


# Test for list_tx with no source (lines 530-531)
def test_list_tx_no_counterparty_data(ledger_db, blockchain_mock, defaults, monkeypatch):
    """Test list_tx when there's no counterparty data"""
    tx_hash = blockchain_mock.get_dummy_tx_hash(defaults["addresses"][0])

    # Mock get_tx_info to return no data
    def mock_get_tx_info(db, decoded_tx, block_index):
        return (defaults["addresses"][0], None, 0, 1000, None, None, [])

    monkeypatch.setattr("counterpartycore.lib.parser.blocks.get_tx_info", mock_get_tx_info)

    decoded_tx = {
        "tx_id": tx_hash,
        "tx_hash": tx_hash,
        "vin": [],
        "vout": [],
    }

    block = ledger_db.execute("SELECT * FROM blocks ORDER BY block_index DESC LIMIT 1").fetchone()
    tx_index = blocks.list_tx(
        ledger_db,
        block["block_hash"],
        block["block_index"],
        block["block_time"],
        tx_hash,
        100,
        decoded_tx,
    )
    # Should return same tx_index (no counterparty data)
    assert tx_index == 100


# Test for rebuild_database (lines 562-574)
def test_rebuild_database(ledger_db):
    """Test rebuild_database drops and recreates tables"""
    # Check tables exist before rebuild
    cursor = ledger_db.cursor()
    tables_before = cursor.execute("SELECT name FROM sqlite_master WHERE type='table'").fetchall()
    table_names_before = [t["name"] for t in tables_before]
    assert "transactions" in table_names_before
    assert "blocks" in table_names_before

    # Rebuild without transactions
    blocks.rebuild_database(ledger_db, include_transactions=False)

    # Tables should still exist (recreated)
    tables_after = cursor.execute("SELECT name FROM sqlite_master WHERE type='table'").fetchall()
    table_names_after = [t["name"] for t in tables_after]
    assert "balances" in table_names_after


# Test for rollback early return (lines 579-580)
def test_rollback_future_block(ledger_db, test_helpers, caplog):
    """Test rollback returns early when block_index > current_block_index"""
    future_block = CurrentState().current_block_index() + 100

    with test_helpers.capture_log(
        caplog, "Block index is higher than current block index. No need to reparse."
    ):
        blocks.rollback(ledger_db, future_block)

    # Verify database wasn't modified
    last_block = ledger_db.execute(
        "SELECT block_index FROM blocks ORDER BY block_index DESC LIMIT 1"
    ).fetchone()
    assert last_block["block_index"] == CurrentState().current_block_index()


# Test for generate_progression_message with tx_index (line 614)
def test_generate_progression_message_with_tx_index():
    """Test generate_progression_message includes tx_index when provided"""
    block = {"block_index": 100}
    start_time_block = time.time() - 1
    start_time_all = time.time() - 10
    block_parsed_count = 5
    block_count = 10
    tx_index = 500

    message = blocks.generate_progression_message(
        block, start_time_block, start_time_all, block_parsed_count, block_count, tx_index=tx_index
    )

    assert "tx_index: 500" in message
    assert "Block 100" in message
    assert "5/10 blocks parsed" in message


def test_generate_progression_message_without_tx_index():
    """Test generate_progression_message without tx_index"""
    block = {"block_index": 100}
    start_time_block = time.time() - 1
    start_time_all = time.time() - 10
    block_parsed_count = 5
    block_count = 10

    message = blocks.generate_progression_message(
        block, start_time_block, start_time_all, block_parsed_count, block_count
    )

    assert "tx_index" not in message
    assert "Block 100" in message


# Test for reparse early return (lines 624-625)
def test_reparse_future_block(ledger_db, test_helpers, caplog):
    """Test reparse returns early when block_index > current_block_index"""
    future_block = CurrentState().current_block_index() + 100

    with test_helpers.capture_log(
        caplog, "Block index is higher than current block index. No need to reparse."
    ):
        blocks.reparse(ledger_db, future_block)


# Test for rollback_empty_block (lines 851-863)
def test_rollback_empty_block_no_empty(ledger_db):
    """Test rollback_empty_block when no empty blocks exist"""
    # All blocks should have ledger_hash set
    blocks.rollback_empty_block(ledger_db)
    # Should complete without error


def test_rollback_empty_block_with_empty(ledger_db, test_helpers, caplog, monkeypatch):
    """Test rollback_empty_block when empty ledger_hash exists"""
    # Set a block's ledger_hash to NULL
    cursor = ledger_db.cursor()
    last_block = cursor.execute(
        "SELECT block_index FROM blocks ORDER BY block_index DESC LIMIT 1"
    ).fetchone()

    cursor.execute(
        "UPDATE blocks SET ledger_hash = NULL WHERE block_index = ?",
        (last_block["block_index"],),
    )

    # Mock rollback to avoid actual rollback
    rollback_called = []

    def mock_rollback(db, block_index, force=False):
        rollback_called.append(block_index)

    monkeypatch.setattr("counterpartycore.lib.parser.blocks.rollback", mock_rollback)

    with test_helpers.capture_log(caplog, "Ledger hashes are empty from block"):
        blocks.rollback_empty_block(ledger_db)

    assert len(rollback_called) == 1
    assert rollback_called[0] == last_block["block_index"]


# Test for start_rsfetcher error handling (lines 885-899)
def test_start_rsfetcher_invalid_version(monkeypatch):
    """Test start_rsfetcher raises on invalid version"""

    class MockFetcher:
        def start(self, block_index):
            raise exceptions.InvalidVersion("Version mismatch")

        def stop(self):
            pass

    class MockRSFetcher:
        def __init__(self):
            pass

        def start(self, block_index):
            raise exceptions.InvalidVersion("Version mismatch")

        def stop(self):
            pass

    monkeypatch.setattr("counterpartycore.lib.backend.rsfetcher.RSFetcher", lambda: MockRSFetcher())

    with pytest.raises(exceptions.InvalidVersion):
        blocks.start_rsfetcher()


# Test for reset_rust_fetcher_database (line 1036)
def test_reset_rust_fetcher_database(monkeypatch):
    """Test reset_rust_fetcher_database calls rsfetcher.delete_database_directory"""
    delete_called = []

    def mock_delete():
        delete_called.append(True)

    monkeypatch.setattr(
        "counterpartycore.lib.backend.rsfetcher.delete_database_directory", mock_delete
    )

    blocks.reset_rust_fetcher_database()
    assert len(delete_called) == 1


# Test for clean_messages_tables with rebuild (line 544)
def test_clean_messages_tables_block_first(ledger_db, monkeypatch):
    """Test clean_messages_tables calls rebuild_database when block_index == BLOCK_FIRST"""
    rebuild_called = []

    def mock_rebuild(db, include_transactions=True):
        rebuild_called.append(include_transactions)

    monkeypatch.setattr("counterpartycore.lib.parser.blocks.rebuild_database", mock_rebuild)

    blocks.clean_messages_tables(ledger_db, block_index=0)
    assert len(rebuild_called) == 1
    assert rebuild_called[0] is False


# Test for rollback with BLOCK_FIRST (line 588)
def test_rollback_to_block_first(ledger_db, monkeypatch):
    """Test rollback calls rebuild_database when rolling back to BLOCK_FIRST"""
    rebuild_called = []

    def mock_rebuild(db):
        rebuild_called.append(True)

    monkeypatch.setattr("counterpartycore.lib.parser.blocks.rebuild_database", mock_rebuild)

    # Force rollback to BLOCK_FIRST
    blocks.rollback(ledger_db, block_index=0, force=True)
    assert len(rebuild_called) == 1


# Test for catch_up function (lines 920-1032)
def test_catch_up_stopping(ledger_db, monkeypatch):
    """Test catch_up returns early when stopping"""
    # Mock CurrentState().stopping() to return True
    monkeypatch.setattr(
        "counterpartycore.lib.ledger.currentstate.CurrentState.stopping", lambda self: True
    )

    # This should return early without processing
    blocks.catch_up(ledger_db)


def test_catch_up_new_database(ledger_db, monkeypatch, test_helpers, caplog):
    """Test catch_up with new database"""
    # Mock ledger.blocks.last_db_index to return 0
    monkeypatch.setattr("counterpartycore.lib.ledger.blocks.last_db_index", lambda db: 0)

    # Mock backend methods
    monkeypatch.setattr(
        "counterpartycore.lib.backend.bitcoind.getblockcount",
        lambda: config.BLOCK_FIRST - 1,
    )
    monkeypatch.setattr("counterpartycore.lib.backend.bitcoind.get_blocks_behind", lambda: 0)

    with test_helpers.capture_log(caplog, "New database."):
        blocks.catch_up(ledger_db)


# Additional tests for various parse_tx message types
def test_parse_tx_mpma(ledger_db, defaults, blockchain_mock, test_helpers):
    """Test parse_tx with MPMA message"""
    # Create MPMA data - format is (asset, destination, quantity)
    _source, _destinations, data = mpma.compose(
        ledger_db,
        defaults["addresses"][0],
        [
            ("XCP", defaults["addresses"][1], 100),
            ("XCP", defaults["addresses"][2], 200),
        ],
    )
    tx = blockchain_mock.dummy_tx(ledger_db, defaults["addresses"][0], data=data)
    result = blocks.parse_tx(ledger_db, tx)
    assert result is True


def test_parse_tx_dividend(ledger_db, defaults, blockchain_mock):
    """Test parse_tx with dividend message"""
    # Create dividend data manually using struct pack
    # Format: message_type_id (4 bytes) + quantity_per_unit (8 bytes) + asset_id (8 bytes) + dividend_asset_id (8 bytes)
    # Get asset IDs
    dividend_asset = ledger_db.execute(
        "SELECT asset_id FROM assets WHERE asset_name = 'DIVIDEND'"
    ).fetchone()
    xcp_asset = ledger_db.execute("SELECT asset_id FROM assets WHERE asset_name = 'XCP'").fetchone()

    if dividend_asset and xcp_asset:
        # Pack the dividend message
        data = messagetype.pack(
            dividend.ID,
            ledger_db.execute(
                "SELECT block_index FROM blocks ORDER BY block_index DESC LIMIT 1"
            ).fetchone()["block_index"],
        )
        data += struct.pack(
            ">QQQ", 100, int(dividend_asset["asset_id"]), int(xcp_asset["asset_id"])
        )

        tx = blockchain_mock.dummy_tx(ledger_db, defaults["addresses"][2], data=data)
        result = blocks.parse_tx(ledger_db, tx)
        # The result depends on whether the dividend is valid at parse time
        assert result is True


def test_parse_tx_cancel(ledger_db, defaults, blockchain_mock):
    """Test parse_tx with cancel message"""
    # Get an open order to cancel
    open_order = ledger_db.execute(
        "SELECT * FROM orders WHERE source = (SELECT address_id FROM address_list WHERE address = ?) "
        "AND status = 'open' LIMIT 1",
        (defaults["addresses"][0],),
    ).fetchone()

    if open_order:
        _source, _destination, data = cancel.compose(
            ledger_db, defaults["addresses"][0], open_order["tx_hash"]
        )
        tx = blockchain_mock.dummy_tx(ledger_db, defaults["addresses"][0], data=data)
        result = blocks.parse_tx(ledger_db, tx)
        assert result is True


def test_parse_tx_destroy(ledger_db, defaults, blockchain_mock):
    """Test parse_tx with destroy message"""
    _source, _destination, data = destroy.compose(
        ledger_db, defaults["addresses"][0], "XCP", 100, ""
    )
    tx = blockchain_mock.dummy_tx(ledger_db, defaults["addresses"][0], data=data)
    result = blocks.parse_tx(ledger_db, tx)
    assert result is True


def test_parse_tx_sweep(ledger_db, defaults, blockchain_mock):
    """Test parse_tx with sweep message"""
    _source, _destination, data = sweep.compose(
        ledger_db, defaults["addresses"][0], defaults["addresses"][1], 1, "test"
    )
    tx = blockchain_mock.dummy_tx(ledger_db, defaults["addresses"][0], data=data)
    result = blocks.parse_tx(ledger_db, tx)
    assert result is True


# Test for get_next_tx_index
def test_get_next_tx_index(ledger_db):
    """Test get_next_tx_index returns correct next index"""
    last_tx = ledger_db.execute("SELECT MAX(tx_index) as max_idx FROM transactions").fetchone()
    expected = (last_tx["max_idx"] or -1) + 1

    result = blocks.get_next_tx_index(ledger_db)
    assert result == expected


def test_get_next_tx_index_empty_db(empty_ledger_db):
    """Test get_next_tx_index returns 0 for empty database"""
    result = blocks.get_next_tx_index(empty_ledger_db)
    assert result == 0
