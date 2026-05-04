import sqlite3
from unittest import mock

import counterpartycore.lib.parser.mempool as mempool_module
import pytest
from counterpartycore.lib import exceptions


def test_parse_mempool_transactions_sql_error(
    mock_db, mock_current_state, mock_deserialize, mock_blocks, mock_ledger_blocks
):
    """Test parse_mempool_transactions with a SQL error"""
    db, cursor = mock_db

    # Simulate a SQL error during execution
    cursor.execute.side_effect = sqlite3.Error("SQL Error")

    with pytest.raises(sqlite3.Error):
        mempool_module.parse_mempool_transactions(db, ["raw_tx"])

    # set_parsing_mempool(True) at the start, then set_parsing_mempool(False) in
    # the `finally` -- must be called even on exception so the singleton is not
    # left stuck in mempool mode.
    mock_current_state.assert_any_call(True)
    mock_current_state.assert_any_call(False)


def test_parse_mempool_transactions_deserialize_error(
    mock_db, mock_current_state, mock_deserialize, mock_blocks, mock_ledger_blocks
):
    """Test parse_mempool_transactions with a deserialization error"""
    db, cursor = mock_db

    cursor.fetchone.side_effect = [
        {"tx_index": 10},  # Last mempool tx
        {"tx_index": 5},  # Last tx
        {"message_index": 100},  # Last message
    ]

    # Simulate an error during deserialization
    mock_deserialize.side_effect = ValueError("Deserialize Error")

    with pytest.raises(ValueError):
        mempool_module.parse_mempool_transactions(db, ["raw_tx"])

    # set_parsing_mempool(True) at the start, then set_parsing_mempool(False) in
    # the `finally` -- must be called even on exception so the singleton is not
    # left stuck in mempool mode.
    mock_current_state.assert_any_call(True)
    mock_current_state.assert_any_call(False)


def test_clean_transaction_from_mempool_sql_error(mock_db):
    """Test clean_transaction_from_mempool with a SQL error"""
    db, cursor = mock_db

    # Simulate a SQL error during execution
    cursor.execute.side_effect = sqlite3.Error("SQL Error")

    with pytest.raises(sqlite3.Error):
        mempool_module.clean_transaction_from_mempool(db, "tx1")


def test_clean_mempool_get_transaction_error(mock_db, mock_ledger_blocks, mock_backend_bitcoind):
    """Test clean_mempool with an error in get_transaction"""
    db, cursor = mock_db

    # Candidate tx_hash configuration (union of mempool + mempool_transactions)
    cursor.fetchall.return_value = [{"tx_hash": "tx1"}]

    # getrawmempool is now called BEFORE the get_transaction loop;
    # we must mock it to avoid hitting the real bitcoind.
    mock_backend_bitcoind.return_value = ["tx1"]

    # Simulate an error in get_transaction
    mock_ledger_blocks.side_effect = ValueError("Get Transaction Error")

    with pytest.raises(ValueError):
        mempool_module.clean_mempool(db)


def test_clean_mempool_getrawmempool_error(mock_db, mock_ledger_blocks, mock_backend_bitcoind):
    """Test clean_mempool with an error in getrawmempool"""
    db, cursor = mock_db

    # Candidate tx_hash configuration (union of mempool + mempool_transactions)
    cursor.fetchall.return_value = [{"tx_hash": "tx1"}]

    mock_ledger_blocks.return_value = None

    # Simulate an error in getrawmempool
    mock_backend_bitcoind.side_effect = ValueError("GetRawMempool Error")

    with pytest.raises(ValueError):
        mempool_module.clean_mempool(db)


def test_parse_mempool_transactions_rollback(
    mock_db, mock_current_state, mock_deserialize, mock_blocks, mock_ledger_blocks
):
    """Test that parse_mempool_transactions correctly rolls back the transaction"""
    db, cursor = mock_db

    db_context = mock.MagicMock()
    db.__enter__.return_value = db_context

    cursor.fetchone.side_effect = [
        {"tx_index": 10},  # Last mempool tx
        {"tx_index": 5},  # Last tx
        {"message_index": 100},  # Last message
    ]

    transaction_events = [
        {
            "tx_hash": "tx1",
            "event": "event1",
            "bindings": "{}",
            "command": "cmd1",
            "category": "cat1",
        }
    ]
    mempool_transactions = [
        {
            "tx_hash": "tx1",
            "tx_index": 11,
            "block_index": 0,
            "block_hash": "mempool",
            "block_time": 123,
        }
    ]

    cursor.fetchall.side_effect = [transaction_events, mempool_transactions]

    mock_deserialize.return_value = {"tx_hash": "tx1", "source": "addr1", "destination": "addr2"}

    mock_ledger_blocks.return_value = None

    mempool_module.parse_mempool_transactions(db, ["raw_tx"])

    # Verify that db.__enter__ was called (start of the transaction)
    assert db.__enter__.called

    # Verify that db.cursor was called
    assert db.cursor.called

    # Verify that MempoolError was raised to perform the rollback
    assert isinstance(db.__exit__.call_args[0][1], exceptions.MempoolError)

    # Verify that mempool insertions were performed after the rollback
    assert cursor.execute.called
