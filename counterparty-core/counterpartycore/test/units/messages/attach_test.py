import pytest
from counterpartycore.lib import config, exceptions
from counterpartycore.lib.messages import attach

DUMMY_UTXO = 64 * "0" + ":1"


def test_validate(ledger_db, defaults):
    address_0 = defaults["addresses"][0]
    assert attach.validate(ledger_db, address_0, "XCP", 100) == []
    assert attach.validate(ledger_db, address_0, "XCP", 100, 1) == []
    assert attach.validate(ledger_db, DUMMY_UTXO, "XCP", 100) == ["invalid source address"]
    assert attach.validate(ledger_db, address_0, "XCP", 0) == ["quantity must be greater than zero"]
    assert attach.validate(ledger_db, address_0, "XCP", 99999999999999) == [
        "insufficient funds for transfer and fee"
    ]
    assert attach.validate(ledger_db, address_0, "DIVISIBLE", 99999999999999) == [
        "insufficient funds for transfer"
    ]
    assert attach.validate(ledger_db, address_0, "BTC", 100) == ["cannot send bitcoins"]
    assert attach.validate(ledger_db, address_0, "XCP", config.MAX_INT + 1) == ["integer overflow"]
    assert attach.validate(ledger_db, address_0, "XCP", "100") == ["quantity must be in satoshis"]
    assert attach.validate(ledger_db, address_0, "XCP", 100, -1) == [
        "destination vout must be greater than or equal to zero"
    ]
    assert attach.validate(ledger_db, address_0, "XCP", 100, "1") == [
        "if provided destination must be an integer"
    ]


def test_compose(ledger_db, defaults):
    address_0 = defaults["addresses"][0]
    assert attach.compose(ledger_db, address_0, "XCP", 100, None, 1) == (
        address_0,
        [],
        b"eXCP|100|1",
    )
    assert attach.compose(ledger_db, address_0, "XCP", 100, 666) == (
        address_0,
        [(address_0, 666)],
        b"eXCP|100|",
    )
    assert attach.compose(ledger_db, address_0, "XCP", 100) == (
        address_0,
        [(address_0, 546)],
        b"eXCP|100|",
    )

    with pytest.raises(exceptions.ComposeError, match="invalid source address"):
        attach.compose(ledger_db, DUMMY_UTXO, "XCP", 100)


def test_unpack():
    assert attach.unpack(b"XCP|100|1") == ("XCP", 100, 1)
    assert attach.unpack(b"XCP|100|1", True) == {
        "asset": "XCP",
        "quantity": 100,
        "destination_vout": 1,
    }
    assert attach.unpack(b"XCP|100|") == ("XCP", 100, None)


def test_parse_without_destination(
    ledger_db, blockchain_mock, current_block_index, test_helpers, defaults
):
    address_0 = defaults["addresses"][0]
    tx = blockchain_mock.dummy_tx(ledger_db, address_0)
    message = b"XCP|100|"
    attach.parse(ledger_db, tx, message)

    utxo = f"{tx['tx_hash']}:0"
    test_helpers.check_records(
        ledger_db,
        [
            {
                "table": "debits",
                "values": {
                    "address": address_0,
                    "asset": "XCP",
                    "quantity": 100,
                    "event": tx["tx_hash"],
                    "block_index": current_block_index,
                    "tx_index": tx["tx_index"],
                    "action": "attach to utxo",
                },
            },
            {
                "table": "credits",
                "values": {
                    "utxo": utxo,
                    "address": None,
                    "asset": "XCP",
                    "quantity": 100,
                    "event": tx["tx_hash"],
                    "block_index": current_block_index,
                    "tx_index": tx["tx_index"],
                    "calling_function": "attach to utxo",
                },
            },
            {
                "table": "sends",
                "values": {
                    "tx_index": tx["tx_index"],
                    "tx_hash": tx["tx_hash"],
                    "block_index": tx["block_index"],
                    "status": "valid",
                    "source": address_0,
                    "destination": utxo,
                    "destination_address": address_0,
                    "asset": "XCP",
                    "quantity": 100,
                    "fee_paid": 0,
                    "send_type": "attach",
                },
            },
            {
                "table": "messages",
                "values": {
                    "block_index": current_block_index,
                    "command": "insert",
                    "category": "sends",
                    "bindings": test_helpers.to_short_json(
                        {
                            "asset": "XCP",
                            "block_index": tx["block_index"],
                            "destination": utxo,
                            "destination_address": address_0,
                            "fee_paid": 0,
                            "quantity": 100,
                            "msg_index": 1,
                            "send_type": "attach",
                            "source": address_0,
                            "status": "valid",
                            "tx_hash": tx["tx_hash"],
                            "tx_index": tx["tx_index"],
                        }
                    ),
                    "event": "ATTACH_TO_UTXO",
                },
            },
        ],
    )


def test_parse_with_destination(
    ledger_db, blockchain_mock, current_block_index, test_helpers, defaults
):
    address_0 = defaults["addresses"][0]
    tx = blockchain_mock.dummy_tx(ledger_db, address_0, op_return_position=0)
    message = b"XCP|100|1"
    attach.parse(ledger_db, tx, message)

    utxo = f"{tx['tx_hash']}:1"
    test_helpers.check_records(
        ledger_db,
        [
            {
                "table": "messages",
                "values": {
                    "block_index": current_block_index,
                    "command": "insert",
                    "category": "sends",
                    "bindings": test_helpers.to_short_json(
                        {
                            "asset": "XCP",
                            "block_index": tx["block_index"],
                            "destination": utxo,
                            "destination_address": address_0,
                            "fee_paid": 0,
                            "quantity": 100,
                            "msg_index": 1,
                            "send_type": "attach",
                            "source": address_0,
                            "status": "valid",
                            "tx_hash": tx["tx_hash"],
                            "tx_index": tx["tx_index"],
                        }
                    ),
                    "event": "ATTACH_TO_UTXO",
                },
            }
        ],
    )


def test_parse_with_op_return_destination(
    ledger_db, blockchain_mock, current_block_index, test_helpers, defaults
):
    address_0 = defaults["addresses"][0]
    tx = blockchain_mock.dummy_tx(ledger_db, address_0, op_return_position=1)
    message = b"XCP|100|1"
    attach.parse(ledger_db, tx, message)

    test_helpers.check_records(
        ledger_db,
        [
            {
                "table": "messages",
                "values": {
                    "block_index": current_block_index,
                    "command": "insert",
                    "category": "sends",
                    "bindings": test_helpers.to_short_json(
                        {
                            "block_index": tx["block_index"],
                            "msg_index": 1,
                            "send_type": "attach",
                            "status": "invalid: destination vout is an OP_RETURN output",
                            "tx_hash": tx["tx_hash"],
                            "tx_index": tx["tx_index"],
                        }
                    ),
                    "event": "ATTACH_TO_UTXO",
                },
            }
        ],
    )


def test_parse_with_invalid_destination(
    ledger_db, blockchain_mock, current_block_index, test_helpers, defaults
):
    address_0 = defaults["addresses"][0]
    tx = blockchain_mock.dummy_tx(ledger_db, address_0)
    message = b"XCP|100|3"
    attach.parse(ledger_db, tx, message)

    test_helpers.check_records(
        ledger_db,
        [
            {
                "table": "messages",
                "values": {
                    "block_index": current_block_index,
                    "command": "insert",
                    "category": "sends",
                    "bindings": test_helpers.to_short_json(
                        {
                            "block_index": tx["block_index"],
                            "msg_index": 1,
                            "send_type": "attach",
                            "status": "invalid: destination vout is greater than the number of outputs",
                            "tx_hash": tx["tx_hash"],
                            "tx_index": tx["tx_index"],
                        }
                    ),
                    "event": "ATTACH_TO_UTXO",
                },
            }
        ],
    )


def test_parse_with_no_destination(
    ledger_db, blockchain_mock, current_block_index, test_helpers, defaults
):
    address_0 = defaults["addresses"][0]
    tx = blockchain_mock.dummy_tx(
        ledger_db, address_0, utxo_destination="", outputs_count=1, op_return_position=0
    )
    message = b"XCP|100|"
    attach.parse(ledger_db, tx, message)

    test_helpers.check_records(
        ledger_db,
        [
            {
                "table": "messages",
                "values": {
                    "block_index": current_block_index,
                    "command": "insert",
                    "category": "sends",
                    "bindings": test_helpers.to_short_json(
                        {
                            "block_index": tx["block_index"],
                            "msg_index": 1,
                            "send_type": "attach",
                            "status": "invalid: no UTXO to attach to",
                            "tx_hash": tx["tx_hash"],
                            "tx_index": tx["tx_index"],
                        }
                    ),
                    "event": "ATTACH_TO_UTXO",
                },
            }
        ],
    )
