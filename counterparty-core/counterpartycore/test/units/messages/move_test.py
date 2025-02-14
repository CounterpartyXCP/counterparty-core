import pytest
from counterpartycore.lib import exceptions
from counterpartycore.lib.messages import move

DUMMY_UTXO = 64 * "0" + ":0"


def get_utxo(ledger_db, address, asset="XCP"):
    return ledger_db.execute(
        "SELECT * FROM balances WHERE utxo_address = ? and asset = ? AND quantity > 0",
        (
            address,
            asset,
        ),
    ).fetchone()["utxo"]


def test_move_assets_xcp(ledger_db, defaults, blockchain_mock, test_helpers, current_block_index):
    utxo = get_utxo(ledger_db, defaults["addresses"][0])
    tx = blockchain_mock.dummy_tx(
        ledger_db, defaults["addresses"][0], utxo_source=utxo, utxo_destination=DUMMY_UTXO
    )
    move.move_assets(ledger_db, tx)

    test_helpers.check_records(
        ledger_db,
        [
            {
                "table": "debits",
                "values": {
                    "utxo": utxo,
                    "address": None,
                    "asset": "XCP",
                    "quantity": 100,
                    "event": tx["tx_hash"],
                    "block_index": current_block_index,
                    "tx_index": tx["tx_index"],
                    "action": "utxo move",
                },
            },
            {
                "table": "credits",
                "values": {
                    "utxo": DUMMY_UTXO,
                    "address": None,
                    "asset": "XCP",
                    "quantity": 100,
                    "event": tx["tx_hash"],
                    "block_index": current_block_index,
                    "tx_index": tx["tx_index"],
                    "calling_function": "utxo move",
                },
            },
            {
                "table": "sends",
                "values": {
                    "tx_index": tx["tx_index"],
                    "tx_hash": tx["tx_hash"],
                    "block_index": tx["block_index"],
                    "status": "valid",
                    "source": utxo,
                    "source_address": defaults["addresses"][0],
                    "destination": DUMMY_UTXO,
                    "destination_address": defaults["addresses"][0],
                    "asset": "XCP",
                    "quantity": 100,
                    "fee_paid": 0,
                },
            },
        ],
    )


def test_move_assets_divisible(
    ledger_db, defaults, blockchain_mock, test_helpers, current_block_index
):
    utxo = get_utxo(ledger_db, defaults["addresses"][0], "DIVISIBLE")
    tx = blockchain_mock.dummy_tx(
        ledger_db, defaults["addresses"][0], utxo_source=utxo, utxo_destination=DUMMY_UTXO
    )
    move.move_assets(ledger_db, tx)

    test_helpers.check_records(
        ledger_db,
        [
            {
                "table": "debits",
                "values": {
                    "utxo": utxo,
                    "address": None,
                    "asset": "DIVISIBLE",
                    "quantity": 1,
                    "event": tx["tx_hash"],
                    "block_index": current_block_index,
                    "tx_index": tx["tx_index"],
                    "action": "utxo move",
                },
            },
            {
                "table": "credits",
                "values": {
                    "utxo": DUMMY_UTXO,
                    "address": None,
                    "asset": "DIVISIBLE",
                    "quantity": 1,
                    "event": tx["tx_hash"],
                    "block_index": current_block_index,
                    "tx_index": tx["tx_index"],
                    "calling_function": "utxo move",
                },
            },
            {
                "table": "sends",
                "values": {
                    "tx_index": tx["tx_index"],
                    "tx_hash": tx["tx_hash"],
                    "block_index": tx["block_index"],
                    "status": "valid",
                    "source": utxo,
                    "source_address": defaults["addresses"][0],
                    "destination": DUMMY_UTXO,
                    "destination_address": defaults["addresses"][0],
                    "asset": "DIVISIBLE",
                    "quantity": 1,
                    "fee_paid": 0,
                },
            },
        ],
    )


def test_compose(ledger_db, defaults):
    utxo = get_utxo(ledger_db, defaults["addresses"][0])

    assert move.compose(ledger_db, utxo, defaults["addresses"][0]) == (
        utxo,
        [(defaults["addresses"][0], 546)],
        None,
    )

    assert move.compose(ledger_db, utxo, defaults["addresses"][0], 10000) == (
        utxo,
        [(defaults["addresses"][0], 10000)],
        None,
    )

    with pytest.raises(exceptions.ComposeError, match="Invalid source utxo format"):
        move.compose(ledger_db, "utxo", defaults["addresses"][0])

    with pytest.raises(exceptions.ComposeError, match="No assets attached to the source utxo"):
        move.compose(ledger_db, DUMMY_UTXO, defaults["addresses"][0])

    with pytest.raises(exceptions.ComposeError, match="destination must be an address"):
        move.compose(ledger_db, utxo, utxo)

    with pytest.raises(exceptions.ComposeError, match="utxo_value must be an integer"):
        move.compose(ledger_db, utxo, defaults["addresses"][0], utxo_value="string")
