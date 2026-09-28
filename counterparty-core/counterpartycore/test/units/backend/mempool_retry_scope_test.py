from concurrent.futures import ThreadPoolExecutor
from types import SimpleNamespace
from unittest.mock import MagicMock

import apsw
import pytest
from counterpartycore.lib import exceptions
from counterpartycore.lib.backend import bitcoind
from counterpartycore.lib.ledger.currentstate import CurrentState
from counterpartycore.lib.parser import mempool
from counterpartycore.lib.utils import parserhealth


@pytest.fixture(autouse=True)
def watchdog_is_cleared_on_exit():
    original_state = CurrentState().state.copy()
    shared = SimpleNamespace(value=0)
    parserhealth.configure(shared)
    yield
    try:
        assert shared.value == 0
    finally:
        parserhealth.configure(None)
        CurrentState().state.clear()
        CurrentState().state.update(original_state)


def test_scope_is_nested_exception_safe_and_thread_local(monkeypatch):
    monkeypatch.setattr(bitcoind, "is_api_request", lambda: False)
    assert not bitcoind.skip_rpc_retry()
    with bitcoind.no_rpc_retry():
        assert bitcoind.skip_rpc_retry()
        with pytest.raises(ValueError), bitcoind.no_rpc_retry():
            raise ValueError("abort inner scope")
        assert bitcoind.skip_rpc_retry()
        with ThreadPoolExecutor(max_workers=1) as executor:
            assert not executor.submit(bitcoind.skip_rpc_retry).result()
    assert not bitcoind.skip_rpc_retry()


def test_nested_lookup_fails_fast_but_confirmed_rpc_keeps_retry_path(monkeypatch):
    monkeypatch.setattr(bitcoind, "is_api_request", lambda: False)
    safe = MagicMock(side_effect=exceptions.BitcoindRPCError("Transaction not found"))
    normal = MagicMock(return_value="confirmed")
    monkeypatch.setattr(bitcoind, "safe_rpc", safe)
    monkeypatch.setattr(bitcoind, "rpc_call", normal)
    with bitcoind.no_rpc_retry(), pytest.raises(exceptions.BitcoindRPCError):
        bitcoind.rpc("getrawtransaction", ["missing", 1])
    safe.assert_called_once()
    normal.assert_not_called()
    assert bitcoind.rpc("getrawtransaction", ["confirmed", 1]) == "confirmed"
    normal.assert_called_once()


@pytest.mark.parametrize("wrapped", [False, True])
def test_mempool_rpc_failure_rolls_back_without_blacklisting(monkeypatch, wrapped):
    monkeypatch.setattr(mempool, "logger", MagicMock())
    monkeypatch.setattr(bitcoind, "is_api_request", lambda: False)
    db = MagicMock()
    cursor = db.cursor.return_value
    cursor.fetchone.side_effect = [None, None, {"message_index": 0}]
    monkeypatch.setattr(
        mempool.deserialize, "deserialize_tx", lambda *a, **k: {"tx_hash": "ab" * 32}
    )
    monkeypatch.setattr(mempool.ledger.blocks, "get_transaction", lambda *a: None)
    # The duplicate-in-mempool query uses a separate chained cursor result.
    cursor.execute.return_value.fetchone.return_value = None

    def missing_parent(*args, **kwargs):
        assert bitcoind.skip_rpc_retry()
        if wrapped:
            try:
                raise exceptions.BitcoindRPCError("Parent disappeared")
            except exceptions.BitcoindRPCError as error:
                raise exceptions.ParseTransactionError(str(error)) from error
        raise exceptions.BitcoindRPCError("Parent disappeared")

    monkeypatch.setattr(mempool.blocks, "list_tx", missing_parent)
    monkeypatch.setattr(mempool.database, "reset_asset_caches", MagicMock())
    monkeypatch.setattr(mempool.database, "reset_address_caches", MagicMock())
    assert mempool.parse_mempool_transactions(db, ["raw"]) == []
    expected_error = exceptions.ParseTransactionError if wrapped else exceptions.BitcoindRPCError
    assert db.__exit__.call_args.args[0] is expected_error
    assert not bitcoind.skip_rpc_retry()
    assert not CurrentState().parsing_mempool()
    assert not any("INSERT INTO mempool " in str(c) for c in cursor.execute.call_args_list)


def test_speculative_write_is_really_rolled_back(monkeypatch):
    monkeypatch.setattr(mempool, "logger", MagicMock())
    monkeypatch.setattr(bitcoind, "is_api_request", lambda: False)
    db = apsw.Connection(":memory:")
    db.setrowtrace(
        lambda cursor, row: dict(zip((c[0] for c in cursor.getdescription()), row, strict=True))
    )
    db.execute("CREATE TABLE blocks(block_index INTEGER, block_hash TEXT, block_time REAL)")
    db.execute("CREATE TABLE mempool_transactions(tx_index INTEGER)")
    db.execute("CREATE TABLE transactions(tx_index INTEGER)")
    db.execute("CREATE TABLE messages(message_index INTEGER)")
    db.execute("INSERT INTO messages VALUES(0)")
    db.execute("CREATE TABLE mempool(tx_hash BLOB)")
    monkeypatch.setattr(
        mempool.deserialize, "deserialize_tx", lambda *a, **k: {"tx_hash": "ab" * 32}
    )
    monkeypatch.setattr(mempool.ledger.blocks, "get_transaction", lambda *a: None)

    def unavailable(*args, **kwargs):
        assert list(db.execute("SELECT block_index FROM blocks"))
        raise exceptions.BitcoindRPCError("Missing parent")

    monkeypatch.setattr(mempool.blocks, "list_tx", unavailable)
    monkeypatch.setattr(mempool.database, "reset_asset_caches", MagicMock())
    monkeypatch.setattr(mempool.database, "reset_address_caches", MagicMock())
    try:
        assert mempool.parse_mempool_transactions(db, ["raw"]) == []
        assert list(db.execute("SELECT * FROM blocks")) == []
        assert list(db.execute("SELECT * FROM mempool")) == []
        assert not CurrentState().parsing_mempool()
        assert not bitcoind.skip_rpc_retry()
    finally:
        db.close()
