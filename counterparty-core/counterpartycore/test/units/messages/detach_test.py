import pytest
from counterpartycore.lib import exceptions
from counterpartycore.lib.messages import detach

DUMMY_UTXO = 64 * "0" + ":1"


def test_validate(defaults):
    assert detach.validate(DUMMY_UTXO) == []
    assert detach.validate(defaults["addresses"][0]) == ["source must be a UTXO"]


def test_compose(ledger_db, defaults):
    assert detach.compose(ledger_db, DUMMY_UTXO, defaults["addresses"][1]) == (
        DUMMY_UTXO,
        [],
        bytes(f"f{defaults['addresses'][1]}", "utf-8"),
    )

    assert detach.compose(ledger_db, DUMMY_UTXO) == (
        DUMMY_UTXO,
        [],
        b"f0",
    )

    with pytest.raises(exceptions.ComposeError, match="destination must be an address"):
        detach.compose(ledger_db, DUMMY_UTXO, DUMMY_UTXO)


def test_unpack(defaults):
    assert detach.unpack(b"0") is None
    assert detach.unpack(bytes(defaults["addresses"][1], "utf-8")) == defaults["addresses"][1]
    assert detach.unpack(bytes(defaults["addresses"][1], "utf-8"), True) == {
        "destination": defaults["addresses"][1]
    }


def get_utxo(ledger_db, address):
    return ledger_db.execute(
        "SELECT * FROM balances WHERE utxo_address = ? AND quantity > 0",
        (address,),
    ).fetchone()["utxo"]


def test_parse_detach_to_destination(ledger_db, blockchain_mock, defaults, test_helpers):
    utxo = get_utxo(ledger_db, defaults["addresses"][0])

    tx = blockchain_mock.dummy_tx(ledger_db, defaults["addresses"][0], utxo_source=utxo)
    message = bytes(defaults["addresses"][1], "utf-8")
    detach.parse(ledger_db, tx, message)

    test_helpers.check_records(
        ledger_db,
        [
            {
                "table": "sends",
                "values": {
                    "tx_index": tx["tx_index"],
                    "tx_hash": tx["tx_hash"],
                    "block_index": tx["block_index"],
                    "status": "valid",
                    "source": utxo,
                    "source_address": defaults["addresses"][0],
                    "destination": defaults["addresses"][1],
                    "asset": "XCP",
                    "quantity": 100,
                    "fee_paid": 0,
                    "send_type": "detach",
                },
            }
        ],
    )


def test_parse_detach_no_destination(ledger_db, blockchain_mock, defaults, test_helpers):
    utxo = get_utxo(ledger_db, defaults["addresses"][0])

    tx = blockchain_mock.dummy_tx(ledger_db, defaults["addresses"][0], utxo_source=utxo)
    message = b"0"
    detach.parse(ledger_db, tx, message)

    test_helpers.check_records(
        ledger_db,
        [
            {
                "table": "sends",
                "values": {
                    "tx_index": tx["tx_index"],
                    "tx_hash": tx["tx_hash"],
                    "block_index": tx["block_index"],
                    "status": "valid",
                    "source": utxo,
                    "source_address": defaults["addresses"][0],
                    "destination": defaults["addresses"][0],
                    "asset": "XCP",
                    "quantity": 100,
                    "fee_paid": 0,
                    "send_type": "detach",
                },
            }
        ],
    )


def test_parse_detach_invalid_destination(ledger_db, blockchain_mock, defaults, test_helpers):
    utxo = get_utxo(ledger_db, defaults["addresses"][0])

    tx = blockchain_mock.dummy_tx(ledger_db, defaults["addresses"][0], utxo_source=utxo)
    message = bytes("invalidadress", "utf-8")
    detach.parse(ledger_db, tx, message)

    test_helpers.check_records(
        ledger_db,
        [
            {
                "table": "sends",
                "values": {
                    "tx_index": tx["tx_index"],
                    "tx_hash": tx["tx_hash"],
                    "block_index": tx["block_index"],
                    "status": "valid",
                    "source": utxo,
                    "source_address": defaults["addresses"][0],
                    "destination": defaults["addresses"][0],
                    "asset": "XCP",
                    "quantity": 100,
                    "fee_paid": 0,
                    "send_type": "detach",
                },
            }
        ],
    )


def test_parse_detach_no_balance(ledger_db, blockchain_mock, defaults, test_helpers):
    tx = blockchain_mock.dummy_tx(ledger_db, defaults["addresses"][0], utxo_source="utxo:0")
    message = b"0"
    detach.parse(ledger_db, tx, message)

    test_helpers.check_records(
        ledger_db,
        [
            {
                "table": "sends",
                "values": {
                    "tx_index": tx["tx_index"],
                    "tx_hash": tx["tx_hash"],
                    "msg_index": 1,
                    "block_index": tx["block_index"],
                    "status": "invalid: source must be a UTXO",
                    "send_type": "detach",
                },
            }
        ],
    )
