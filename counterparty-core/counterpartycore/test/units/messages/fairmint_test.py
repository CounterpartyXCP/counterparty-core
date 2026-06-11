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
        "PAIDFAIRMIN",  # asset
        "10",  # quantity
    ) == ["quantity must be an integer"]

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

    with pytest.raises(exceptions.ComposeError, match="quantity must be an integer"):
        fairmint.compose(
            ledger_db,
            defaults["addresses"][1],  # source
            "PAIDFAIRMIN",  # asset
            "10",  # quantity
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


def test_compose_resolves_subasset_longname(ledger_db, defaults):
    asset_longname = "PARENT.already.issued"
    asset_name = "A95428959342453541"
    ledger_db.execute(
        """
        INSERT INTO fairminters (
            tx_hash, tx_index, block_index, source, asset, asset_parent,
            asset_longname, description, price, quantity_by_price, hard_cap,
            burn_payment, max_mint_per_tx, premint_quantity, start_block,
            end_block, minted_asset_commission_int, soft_cap,
            soft_cap_deadline_block, lock_description, lock_quantity,
            divisible, status
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        """,
        (
            "a" * 64,
            10_000,
            1,
            defaults["addresses"][0],
            asset_name,
            "PARENT",
            asset_longname,
            "",
            0,
            1,
            0,
            False,
            10,
            0,
            0,
            0,
            0,
            0,
            0,
            False,
            False,
            True,
            "open",
        ),
    )

    # validate() operates on the canonical (resolved) asset name and must NOT
    # resolve subasset longnames itself: it is on the consensus parse path, so
    # resolving there would alter the stored status of a legacy-format fairmint
    # carrying a subasset longname without a protocol change.
    assert fairmint.validate(ledger_db, defaults["addresses"][1], asset_name, 0) == []
    assert fairmint.validate(ledger_db, defaults["addresses"][1], asset_longname, 0) == [
        f"fairminter not found for asset: `{asset_longname}`"
    ]
    # compose() resolves the longname before validating, so composing with the
    # longname is equivalent to composing with the canonical asset name.
    assert fairmint.compose(
        ledger_db, defaults["addresses"][1], asset_longname, 0
    ) == fairmint.compose(
        ledger_db,
        defaults["addresses"][1],
        asset_name,
        0,
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
                {
                    "table": "transactions_status",
                    "values": {
                        "tx_index": tx["tx_index"],
                        "valid": True,
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
