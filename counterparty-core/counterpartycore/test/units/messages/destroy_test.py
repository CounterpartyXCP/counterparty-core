import pytest
from counterpartycore.lib import exceptions
from counterpartycore.lib.messages import destroy


def test_validate(ledger_db, defaults):
    assert destroy.validate(ledger_db, defaults["addresses"][0], None, "XCP", 1) is None

    assert destroy.validate(ledger_db, defaults["p2sh_addresses"][0], None, "XCP", 1) is None

    with pytest.raises(exceptions.ValidateError, match="asset invalid"):
        destroy.validate(ledger_db, defaults["addresses"][0], None, "foobar", 1)

    with pytest.raises(exceptions.ValidateError, match="destination exists"):
        destroy.validate(ledger_db, defaults["addresses"][0], defaults["addresses"][1], "XCP", 1)

    with pytest.raises(exceptions.ValidateError, match="cannot destroy BTC"):
        destroy.validate(ledger_db, defaults["addresses"][0], None, "BTC", 1)

    with pytest.raises(exceptions.ValidateError, match="quantity not integer"):
        destroy.validate(ledger_db, defaults["addresses"][0], None, "XCP", 1.1)

    with pytest.raises(exceptions.ValidateError, match="integer overflow, quantity too large"):
        destroy.validate(ledger_db, defaults["addresses"][0], None, "XCP", 2**63)

    with pytest.raises(exceptions.ValidateError, match="quantity negative"):
        destroy.validate(ledger_db, defaults["addresses"][0], None, "XCP", -1)

    with pytest.raises(exceptions.BalanceError, match="balance insufficient"):
        destroy.validate(ledger_db, defaults["addresses"][0], None, "XCP", 2**62)


def test_pack(ledger_db):
    assert destroy.pack(ledger_db, "XCP", 1, bytes(9999999)) == (
        b"n\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00"
    )


def test_compose(ledger_db, defaults):
    assert destroy.compose(ledger_db, defaults["addresses"][0], "XCP", 1, bytes(9999999)) == (
        defaults["addresses"][0],
        [],
        b"n\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00",
    )

    assert destroy.compose(ledger_db, defaults["addresses"][0], "XCP", 1, b"WASTE") == (
        defaults["addresses"][0],
        [],
        b"n\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x00\x00\x00\x01WASTE",
    )

    assert destroy.compose(ledger_db, defaults["addresses"][0], "XCP", 1, b"WASTEEEEE") == (
        defaults["addresses"][0],
        [],
        b"n\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x00\x00\x00\x01WASTEEEEE",
    )

    assert destroy.compose(
        ledger_db, defaults["addresses"][0], "PARENT.already.issued", 1, b"WASTEEEEE"
    ) == (
        defaults["addresses"][0],
        [],
        b'n\x01S\x08"\x06\xe4c%\x00\x00\x00\x00\x00\x00\x00\x01WASTEEEEE',
    )


def test_parse_wastee(ledger_db, blockchain_mock, defaults, test_helpers):
    tx = blockchain_mock.dummy_tx(ledger_db, defaults["addresses"][0])
    message = b"\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x00\x00\x00\x01WASTEEEEE"
    destroy.parse(ledger_db, tx, message)

    test_helpers.check_records(
        ledger_db,
        [
            {
                "table": "destructions",
                "values": {
                    "asset": "XCP",
                    "block_index": tx["block_index"],
                    "quantity": 1,
                    "source": defaults["addresses"][0],
                    "status": "valid",
                    "tag": b"WASTEEEEE",
                    "tx_hash": tx["tx_hash"],
                    "tx_index": tx["tx_index"],
                },
            }
        ],
    )


def test_parse_wastee2(ledger_db, blockchain_mock, defaults, test_helpers):
    tx = blockchain_mock.dummy_tx(ledger_db, defaults["addresses"][0])
    message = b"\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x00\x00\x00\x01WASTE\x00\x00\x00"
    destroy.parse(ledger_db, tx, message)

    test_helpers.check_records(
        ledger_db,
        [
            {
                "table": "destructions",
                "values": {
                    "asset": "XCP",
                    "block_index": tx["block_index"],
                    "quantity": 1,
                    "source": defaults["addresses"][0],
                    "status": "valid",
                    "tag": b"WASTE\x00\x00\x00",
                    "tx_hash": tx["tx_hash"],
                    "tx_index": tx["tx_index"],
                },
            }
        ],
    )
