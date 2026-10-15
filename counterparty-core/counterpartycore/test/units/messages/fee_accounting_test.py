"""XCP usage fees must conserve supply across pool and attach operations."""

import json

import pytest
from counterpartycore.lib import config, ledger
from counterpartycore.lib.api import apiwatcher, statetables
from counterpartycore.lib.ledger.currentstate import CurrentState
from counterpartycore.lib.messages import attach, fairminter, gas, pooldeposit, poolwithdraw, utxo
from counterpartycore.lib.parser import blocks, check


def _new_transaction(db, blockchain_mock, source):
    tx = blockchain_mock.dummy_tx(db, source)
    tx["block_index"] = CurrentState().current_block_index()
    tx["tx_index"] = db.execute("SELECT MAX(tx_index) + 1 AS n FROM transactions").fetchone()["n"]
    tx["tx_hash"] = blockchain_mock.get_dummy_tx_hash(source)
    tx["utxos_info"] = f" {tx['tx_hash']}:0 2 1"
    ledger.events.insert_record(db, "transactions", tx, "NEW_TRANSACTION")
    return tx


def _prepare_fee_action(db, blockchain_mock, defaults, kind, invalid=False):
    source = defaults["addresses"][0]
    quantity = defaults["quantity"]
    if kind == "withdraw":
        # Set up liquidity before introducing nonzero usage fees.
        setup_tx = _new_transaction(db, blockchain_mock, source)
        data = pooldeposit.compose(db, source, "XCP", "DIVISIBLE", quantity, quantity)[2]
        pooldeposit.parse(db, setup_tx, data[1:])
    tx = _new_transaction(db, blockchain_mock, source)
    if kind == "deposit":
        handler = pooldeposit
        args = ("XCP", "DIVISIBLE", quantity, quantity)
        kwargs = {"min_lp_quantity": config.MAX_INT if invalid else 0}
    elif kind == "withdraw":
        handler = poolwithdraw
        args = ("XCP", "DIVISIBLE", quantity * 2 if invalid else quantity // 2)
        kwargs = {}
    elif kind == "fairminter":
        handler = fairminter
        args = ("FEEPOOLTEST",)
        kwargs = {
            "price": 1,
            "quantity_by_price": 1,
            "max_mint_per_tx": 1,
            "hard_cap": 100,
            "soft_cap": 61 if invalid else 60,
            "pool_quantity": 40,
            "soft_cap_deadline_block": tx["block_index"] + 500,
            "end_block": tx["block_index"] + 1000,
            "lp_asset": "A99999999999999999",
        }
    else:
        blockchain_mock.address_and_value_by_utxo[f"{tx['tx_hash']}:0"] = (source, config.UNIT)
        handler = attach if kind == "attach" else utxo
        args = ("XCP", quantity) if kind == "attach" else (None, "XCP", quantity)
        kwargs = {}
    data = handler.compose(db, source, *args, **kwargs, skip_validation=invalid)[2]
    return tx, handler, data[1:]


def _api_xcp_supply(db):
    return db.execute("SELECT supply FROM assets_info WHERE asset = 'XCP'").fetchone()["supply"]


@pytest.mark.parametrize("kind", ["deposit", "withdraw", "fairminter", "attach", "utxo"])
@pytest.mark.parametrize("count", [8063, 8064])
def test_fee_accounting(ledger_db, state_db, defaults, blockchain_mock, monkeypatch, kind, count):
    db = ledger_db
    tx, handler, message = _prepare_fee_action(db, blockchain_mock, defaults, kind)
    check.asset_conservation(db)
    supply_before = ledger.supplies.xcp_supply(db)
    held_before = ledger.supplies.held(db)[config.XCP]
    state_db.execute("ATTACH DATABASE ? AS ledger_db", (db.filename,))
    state_db.execute("DELETE FROM assets_info")
    statetables.populate_assets_info(state_db)
    journal_before = db.execute("SELECT MAX(message_index) AS n FROM messages").fetchone()["n"]
    # Exercise the real floor-average and sigmoid calculation at the threshold,
    # without manufacturing thousands of fixture transactions.
    monkeypatch.setattr(gas, "get_transaction_count_for_last_period", lambda *args: count)
    fee_id = pooldeposit.ID if kind == "fairminter" else handler.ID
    fee = gas.get_transaction_fee(db, fee_id, tx["block_index"])
    assert (fee > 0) == (count == 8064)
    counter_before = gas.get_transaction_count_by_block(db, fee_id, tx["block_index"])
    handler.parse(db, tx, message)

    if kind == "utxo":
        assert (
            db.execute("SELECT status FROM sends WHERE tx_index = ?", (tx["tx_index"],)).fetchone()[
                "status"
            ]
            == "valid"
        )
    else:
        assert db.execute(
            "SELECT valid FROM transactions_status WHERE tx_index = ?", (tx["tx_index"],)
        ).fetchone()["valid"]
    assert gas.get_transaction_count_by_block(db, fee_id, tx["block_index"]) == counter_before + 1
    # The fairminter also pays the existing named-asset issuance fee.
    issuance_fee = config.UNIT // 2 if kind == "fairminter" else 0
    assert held_before - ledger.supplies.held(db)[config.XCP] == fee + issuance_fee
    assert supply_before - ledger.supplies.xcp_supply(db) == fee + issuance_fee

    destructions = db.execute(
        "SELECT * FROM destructions WHERE tx_index = ?", (tx["tx_index"],)
    ).fetchall()
    xcp_burns = [row for row in destructions if row["asset"] == config.XCP]
    assert len(xcp_burns) == int(fee > 0)
    if xcp_burns:
        assert xcp_burns[0]["quantity"] == fee
        assert xcp_burns[0]["source"] == tx["source"]
        assert xcp_burns[0]["status"] == "valid"
    if kind == "withdraw":
        lp_asset = ledger.markets.get_pool(db, "DIVISIBLE", "XCP")["lp_asset"]
        lp_burns = [row for row in destructions if row["asset"] == lp_asset]
        assert len(lp_burns) == 1
        assert lp_burns[0]["quantity"] == defaults["quantity"] // 2

    events = db.execute(
        "SELECT * FROM messages WHERE message_index > ? ORDER BY message_index", (journal_before,)
    ).fetchall()
    fee_events = [event for event in events if event["event"] == "ASSET_DESTRUCTION"]
    fee_events = [event for event in fee_events if json.loads(event["bindings"])["asset"] == "XCP"]
    assert len(fee_events) == int(fee > 0)
    if fee_events:
        tag = {
            "deposit": "pool deposit fee",
            "withdraw": "pool withdraw fee",
            "fairminter": "fairminter pool fee",
            "attach": "attach to utxo fee",
            "utxo": "attach to utxo fee",
        }[kind]
        assert json.loads(fee_events[0]["bindings"]) == {
            "tx_index": tx["tx_index"],
            "tx_hash": tx["tx_hash"],
            "block_index": tx["block_index"],
            "source": tx["source"],
            "asset": "XCP",
            "quantity": fee,
            "tag": tag,
            "status": "valid",
        }
    # Both existing API projection paths consume the actual parser events/rows.
    for event in events:
        apiwatcher.update_assets_info(state_db, event)
    assert _api_xcp_supply(state_db) == ledger.supplies.xcp_supply(db)
    if kind == "withdraw":
        assert (
            state_db.execute(
                "SELECT supply FROM assets_info WHERE asset = ?", (lp_asset,)
            ).fetchone()["supply"]
            == defaults["quantity"] // 2
        )
    state_db.execute("DELETE FROM assets_info")
    statetables.populate_assets_info(state_db)
    assert _api_xcp_supply(state_db) == ledger.supplies.xcp_supply(db)

    check.asset_conservation(db)


@pytest.mark.parametrize("kind", ["deposit", "withdraw", "fairminter"])
def test_invalid_pool_action_does_not_burn_fee(
    ledger_db, defaults, blockchain_mock, monkeypatch, kind
):
    db = ledger_db
    tx, handler, message = _prepare_fee_action(db, blockchain_mock, defaults, kind, invalid=True)
    supply_before = ledger.supplies.xcp_supply(db)
    held_before = ledger.supplies.held(db)[config.XCP]
    monkeypatch.setattr(gas, "get_transaction_count_for_last_period", lambda *args: 8064)
    fee_id = pooldeposit.ID if kind == "fairminter" else handler.ID
    counter_before = gas.get_transaction_count_by_block(db, fee_id, tx["block_index"])
    handler.parse(db, tx, message)
    assert not db.execute(
        "SELECT valid FROM transactions_status WHERE tx_index = ?", (tx["tx_index"],)
    ).fetchone()["valid"]
    assert gas.get_transaction_count_by_block(db, fee_id, tx["block_index"]) == counter_before
    assert ledger.supplies.xcp_supply(db) == supply_before
    assert ledger.supplies.held(db)[config.XCP] == held_before
    assert not db.execute(
        "SELECT * FROM destructions WHERE tx_index = ?", (tx["tx_index"],)
    ).fetchall()
    check.asset_conservation(db)


def test_pool_fee_rollback_and_replay(ledger_db, defaults, blockchain_mock, monkeypatch):
    db = ledger_db
    supply_before = ledger.supplies.xcp_supply(db)
    held_before = ledger.supplies.held(db)[config.XCP]
    block = dict(ledger.blocks.get_last_block(db))
    block["previous_block_hash"] = block["block_hash"]
    block["block_hash"] = blockchain_mock.get_dummy_tx_hash(defaults["addresses"][0])
    block["block_index"] += 1
    block["block_time"] += 600
    block["ledger_hash"] = block["txlist_hash"] = block["messages_hash"] = None
    block["transaction_count"] = 0
    CurrentState().set_current_block_index(block["block_index"], skip_lock_time=True)
    ledger.events.insert_record(db, "blocks", block, "NEW_BLOCK")
    CurrentState().set_current_block_index(block["block_index"])
    tx, handler, message = _prepare_fee_action(db, blockchain_mock, defaults, "deposit")
    monkeypatch.setattr(gas, "get_transaction_count_for_last_period", lambda *args: 8064)
    fee = gas.get_transaction_fee(db, pooldeposit.ID, tx["block_index"])
    handler.parse(db, tx, message)
    assert ledger.supplies.xcp_supply(db) == supply_before - fee
    check.asset_conservation(db)

    blocks.rollback(db, block["block_index"], force=True)
    assert ledger.supplies.xcp_supply(db) == supply_before
    assert ledger.supplies.held(db)[config.XCP] == held_before
    assert not db.execute(
        "SELECT * FROM destructions WHERE tx_index = ?", (tx["tx_index"],)
    ).fetchall()
    check.asset_conservation(db)

    # Replay the same transaction and payload, not a second composition.
    CurrentState().set_current_block_index(block["block_index"], skip_lock_time=True)
    ledger.events.insert_record(db, "blocks", block, "NEW_BLOCK")
    CurrentState().set_current_block_index(block["block_index"])
    ledger.events.insert_record(db, "transactions", tx, "NEW_TRANSACTION")
    handler.parse(db, tx, message)
    assert ledger.supplies.xcp_supply(db) == supply_before - fee
    assert ledger.supplies.held(db)[config.XCP] == held_before - fee
    assert (
        len(
            db.execute(
                "SELECT * FROM destructions WHERE tx_index = ?", (tx["tx_index"],)
            ).fetchall()
        )
        == 1
    )
    check.asset_conservation(db)
