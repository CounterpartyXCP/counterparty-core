import pytest
from counterpartycore.lib import exceptions
from counterpartycore.lib.messages import fairmint
from counterpartycore.test.mocks.counterpartydbs import ProtocolChangesDisabled


def test_validate(ledger_db, defaults):
    assert (
        fairmint.validate(
            ledger_db,
            defaults["addresses"][1],  # source
            "FREEFAIRMIN",  # asset
            0,  # quantity
        )
        == []
    )

    assert fairmint.validate(
        ledger_db,
        defaults["addresses"][1],  # source
        "PAIDFAIRMIN",  # asset
        0,  # quantity
    ) == ["Quantity must be greater than 0"]

    assert fairmint.validate(
        ledger_db,
        defaults["addresses"][1],  # source
        "RAIDFAIRMIN",  # asset
        11,  # quantity
    ) == ["Quantity exceeds maximum allowed per transaction"]

    assert fairmint.validate(
        ledger_db,
        defaults["addresses"][1],  # source
        "QAIDFAIRMIN",  # asset
        35,  # quantity
    ) == ["asset supply quantity exceeds hard cap"]

    assert (
        fairmint.validate(
            ledger_db,
            defaults["addresses"][1],  # source
            "SAIDFAIRMIN",  # asset
            2,  # quantity
        )
        == []
    )

    assert fairmint.validate(
        ledger_db,
        defaults["addresses"][1],  # source
        "SAIDFAIRMIN",  # asset
        3,  # quantity
    ) == ["quantity exceeds maximum allowed by address"]

    assert fairmint.validate(
        ledger_db,
        defaults["addresses"][0],  # source
        "TAIDFAIRMIN",  # asset
    ) == ["quantity exceeds maximum allowed by address"]


def test_compose(ledger_db, defaults):
    assert fairmint.compose(
        ledger_db,
        defaults["addresses"][1],  # source
        "FREEFAIRMIN",  # asset
        0,  # quantity
    ) == (
        defaults["addresses"][1],
        [],
        b"[\x82\x1b\x00\x02\xd6\xb1\x16H\xdbu\x00",
    )

    with pytest.raises(exceptions.ComposeError, match="asset supply quantity exceeds hard cap"):
        fairmint.compose(
            ledger_db,
            defaults["addresses"][1],  # source
            "QAIDFAIRMIN",  # asset
            35,  # quantity
        )

    assert fairmint.compose(
        ledger_db,
        defaults["addresses"][1],  # source
        "QAIDFAIRMIN",  # asset
        10,  # quantity
    ) == (
        defaults["addresses"][1],
        [],
        b"[\x82\x1b\x00\x08\x07\xcbZs>\xf5\n",
    )

    with pytest.raises(
        exceptions.ComposeError, match="quantity is not allowed for free fairminters"
    ):
        fairmint.compose(
            ledger_db,
            defaults["addresses"][1],  # source
            "FREEFAIRMIN",  # asset
            35,  # quantity
        )

    with ProtocolChangesDisabled(["fairminter_v2"]):
        assert fairmint.compose(
            ledger_db,
            defaults["addresses"][1],  # source
            "FREEFAIRMIN",  # asset
            0,  # quantity
        ) == (
            defaults["addresses"][1],
            [],
            b"[FREEFAIRMIN|0",
        )

        assert fairmint.compose(
            ledger_db,
            defaults["addresses"][1],  # source
            "QAIDFAIRMIN",  # asset
            10,  # quantity
        ) == (
            defaults["addresses"][1],
            [],
            b"[QAIDFAIRMIN|10",
        )


def test_unpack():
    assert fairmint.unpack(b"\x82\x1b\x00\x02\xd6\xb1\x16H\xdbu\x00", False) == ("FREEFAIRMIN", 0)
    assert fairmint.unpack(b"\x82\x1b\x00\x02\xd6\xb1\x16H\xdbu\x00", True) == {
        "asset": "FREEFAIRMIN",
        "quantity": 0,
    }

    with ProtocolChangesDisabled(["fairminter_v2"]):
        assert fairmint.unpack(b"FREEFAIRMIN|0", False) == ("FREEFAIRMIN", 0)
        assert fairmint.unpack(b"FREEFAIRMIN|0", True) == {
            "asset": "FREEFAIRMIN",
            "quantity": 0,
        }


def tes_parse_freefairmint_legacy(
    ledger_db, blockchain_mock, defaults, test_helpers, current_block_index
):
    with ProtocolChangesDisabled(["fairminter_v2"]):
        tx = blockchain_mock.dummy_tx(ledger_db, defaults["addresses"][0], use_first_tx=True)
        message = b"FREEFAIRMIN|0"
        fairmint.parse(ledger_db, tx, message)

        test_helpers.check_records(
            ledger_db,
            [
                {
                    "table": "fairmints",
                    "values": {
                        "tx_hash": tx["tx_hash"],
                        "block_index": tx["block_index"],
                        "source": defaults["addresses"][0],
                        "asset": "FREEFAIRMIN",
                        "earn_quantity": 10,
                        "paid_quantity": 0,
                        "commission": 0,
                        "status": "valid",
                    },
                },
                {
                    "table": "issuances",
                    "values": {
                        "tx_hash": tx["tx_hash"],
                        "block_index": tx["block_index"],
                        "asset": "FREEFAIRMIN",
                        "quantity": 10,
                        "divisible": True,
                        "source": defaults["addresses"][0],
                        "issuer": defaults["addresses"][0],
                        "transfer": False,
                        "callable": False,
                        "call_date": 0,
                        "call_price": 0,
                        "description": "",
                        "fee_paid": 0,
                        "locked": False,
                        "reset": False,
                        "status": "valid",
                        "asset_longname": None,
                        "fair_minting": True,
                    },
                },
                {
                    "table": "credits",
                    "values": {
                        "block_index": current_block_index,
                        "address": defaults["addresses"][0],
                        "asset": "FREEFAIRMIN",
                        "quantity": 10,
                        "calling_function": "fairmint",
                        "event": tx["tx_hash"],
                    },
                },
            ],
        )


def tes_parse_freefairmint(ledger_db, blockchain_mock, defaults, test_helpers, current_block_index):
    tx = blockchain_mock.dummy_tx(ledger_db, defaults["addresses"][0], use_first_tx=True)
    message = b"\x82\x1b\x00\x02\xd6\xb1\x16H\xdbu\x00"
    fairmint.parse(ledger_db, tx, message)

    test_helpers.check_records(
        ledger_db,
        [
            {
                "table": "fairmints",
                "values": {
                    "tx_hash": tx["tx_hash"],
                    "block_index": tx["block_index"],
                    "source": defaults["addresses"][0],
                    "asset": "FREEFAIRMIN",
                    "earn_quantity": 10,
                    "paid_quantity": 0,
                    "commission": 0,
                    "status": "valid",
                },
            },
            {
                "table": "issuances",
                "values": {
                    "tx_hash": tx["tx_hash"],
                    "block_index": tx["block_index"],
                    "asset": "FREEFAIRMIN",
                    "quantity": 10,
                    "divisible": True,
                    "source": defaults["addresses"][0],
                    "issuer": defaults["addresses"][0],
                    "transfer": False,
                    "callable": False,
                    "call_date": 0,
                    "call_price": 0,
                    "description": "",
                    "fee_paid": 0,
                    "locked": False,
                    "reset": False,
                    "status": "valid",
                    "asset_longname": None,
                    "fair_minting": True,
                },
            },
            {
                "table": "credits",
                "values": {
                    "block_index": current_block_index,
                    "address": defaults["addresses"][0],
                    "asset": "FREEFAIRMIN",
                    "quantity": 10,
                    "calling_function": "fairmint",
                    "event": tx["tx_hash"],
                },
            },
        ],
    )


def test_parse_escrowed_fairmint(
    ledger_db, blockchain_mock, defaults, test_helpers, current_block_index
):
    tx = blockchain_mock.dummy_tx(ledger_db, defaults["addresses"][0], use_first_tx=True)
    message = b"\x82\x1b\x00\x08\x07\xcbZs>\xf5\n"
    fairmint.parse(ledger_db, tx, message)

    test_helpers.check_records(
        ledger_db,
        [
            {
                "table": "fairmints",
                "values": {
                    "tx_hash": tx["tx_hash"],
                    "block_index": tx["block_index"],
                    "source": defaults["addresses"][0],
                    "asset": "QAIDFAIRMIN",
                    "earn_quantity": 5,
                    "paid_quantity": 100,
                    "commission": 5,
                    "status": "valid",
                },
            },
            {
                "table": "credits",
                "values": {
                    "block_index": current_block_index,
                    "address": defaults["unspendable"],
                    "asset": "QAIDFAIRMIN",
                    "quantity": 10,
                    "calling_function": "escrowed fairmint",
                    "event": tx["tx_hash"],
                },
            },
            {
                "table": "credits",
                "values": {
                    "block_index": current_block_index,
                    "address": defaults["unspendable"],
                    "asset": "XCP",
                    "quantity": 100,
                    "calling_function": "escrowed fairmint",
                    "event": tx["tx_hash"],
                },
            },
        ],
    )
