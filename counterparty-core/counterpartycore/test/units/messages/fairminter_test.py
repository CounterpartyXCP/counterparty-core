from decimal import Decimal

from counterpartycore.lib.messages import fairminter


def test_validate(ledger_db, defaults):
    assert (
        fairminter.validate(
            ledger_db,
            defaults["addresses"][1],  # source
            "FAIRMINTED",  # asset
            "",  # asset_parent,
            0,  # price=0,
            1,  # quantity_by_price,
            10,  # max_mint_per_tx,
        )
        == []
    )

    assert (
        fairminter.validate(
            ledger_db,
            defaults["addresses"][1],  # source
            "FAIRMINTED",  # asset
            "",  # asset_parent,
            1000,  # price=0,
        )
        == []
    )

    assert fairminter.validate(
        ledger_db,
        defaults["addresses"][1],  # source
        "FAIRMINTED1",  # asset
    ) == [
        "Invalid asset name: ('invalid character:', '1')",
        "Price or max_mint_per_tx must be > 0.",
    ]

    assert (
        fairminter.validate(
            ledger_db,
            defaults["addresses"][1],  # source
            "A1603612687792733727",  # asset
            "",  # asset_parent,
            0,  # price=0,
            1,  # quantity_by_price,
            10,  # max_mint_per_tx,
        )
        == []
    )

    assert fairminter.validate(
        ledger_db,
        defaults["addresses"][1],  # source
        "A1603612687",  # asset
        "",  # asset_parent,
        0,  # price=0,
        1,  # quantity_by_price,
        10,  # max_mint_per_tx,
    ) == ["Invalid asset name: numeric asset name not in range"]

    assert fairminter.validate(
        ledger_db,
        defaults["addresses"][1],  # source
        "FAIRMINTED",  # asset
        "",  # asset_parent,
        0,  # price=0,
        1,  # quantity_by_price,
        -10,  # max_mint_per_tx,
    ) == ["`max_mint_per_tx` must be >= 0."]

    assert fairminter.validate(
        ledger_db,
        defaults["addresses"][1],  # source
        "FAIRMINTED",  # asset
        "",  # asset_parent,
        0,  # price=0,
        1,  # quantity_by_price,
        -10,  # max_mint_per_tx,
        40,  # hard_cap=0,
        50,  # premint_quantity=0,
        50,  # start_block=0,
        49,  # end_block=0,
        55,  # soft_cap=0,
        0,  # soft_cap_deadline_block=0,
        500,  # minted_asset_commission=0.0,
        0,  # burn_payment=False,
    ) == [
        "`max_mint_per_tx` must be >= 0.",
        "`burn_payment` must be a boolean.",
        "minted_asset_commission must be a float",
        "Premint quantity must be < hard cap.",
        "Start block must be <= end block.",
        "Soft cap must be < hard cap.",
        "Soft cap deadline block must be specified if soft cap is specified.",
    ]

    assert fairminter.validate(
        ledger_db,
        defaults["addresses"][1],  # source
        "LOCKEDPREV",  # asset
        "",  # asset_parent,
        0,  # price=0,
        1,  # quantity_by_price,
        10,  # max_mint_per_tx,
    ) == [
        "Asset `LOCKEDPREV` is locked.",
        "Asset `LOCKEDPREV` is not issued by `mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns`.",
    ]

    assert (
        fairminter.validate(
            ledger_db,
            defaults["addresses"][0],  # source
            "DIVISIBLE",  # asset
            "",  # asset_parent,
            0,  # price=0,
            1,  # quantity_by_price,
            10,  # max_mint_per_tx,
        )
        == []
    )

    assert fairminter.validate(
        ledger_db,
        defaults["addresses"][0],  # source
        "DIVISIBLE",  # asset
        "",  # asset_parent,
        0,  # price=0,
        1,  # quantity_by_price,
        10,  # max_mint_per_tx,
        defaults["quantity"] * 900,  # hard_cap=0,
    ) == ["Hard cap of asset `DIVISIBLE` is already reached."]

    assert (
        fairminter.validate(
            ledger_db,
            defaults["addresses"][0],  # source
            "SUBASSET",  # asset
            "DIVISIBLE",  # asset_parent,
            0,  # price=0,
            1,  # quantity_by_price,
            10,  # max_mint_per_tx,
        )
        == []
    )

    assert fairminter.validate(
        ledger_db,
        defaults["addresses"][0],  # source
        "SUBASSET",  # asset
        "NOASSET",  # asset_parent,
        0,  # price=0,
        1,  # quantity_by_price,
        10,  # max_mint_per_tx,
    ) == ["Asset parent does not exist"]

    assert fairminter.validate(
        ledger_db,
        defaults["addresses"][0],  # source
        "FREEFAIRMIN",  # asset
        "",  # asset_parent,
        0,  # price=0,
        1,  # quantity_by_price,
        10,  # max_mint_per_tx,
    ) == ["Fair minter already opened for `FREEFAIRMIN`."]


def test_compose(ledger_db, defaults):
    assert fairminter.compose(
        ledger_db,
        defaults["addresses"][1],  # source
        "FAIRMINTED",  # asset
        "",  # asset_parent,
        0,  # price=0,
        1,  # quantity_by_price,
        10,  # max_mint_per_tx,
    ) == (
        defaults["addresses"][1],
        [],
        b"ZFAIRMINTED||0|1|10|0|0|0|0|0|0|0|0|0|0|1|",
    )

    assert fairminter.compose(
        ledger_db,
        defaults["addresses"][1],  # source
        "FAIRMINTED",  # asset
        "",  # asset_parent,
        0,  # price,
        1,  # quantity_by_price,
        10,  # max_mint_per_tx,
        1000,  # hard_cap,
        100,  # premint_quantity,
        800000,  # start_block,
        900000,  # end_block,
        50,  # soft_cap,
        850000,  # soft_cap_deadline_block,
        0.1,  # minted_asset_commission,
        False,  # burn_payment,
        False,  # lock_description,
        True,  # lock_quantity,
        True,  # divisible,
        "une asset super top",  # description
    ) == (
        defaults["addresses"][1],
        [],
        b"ZFAIRMINTED||0|1|10|1000|100|800000|900000|50|850000|10000000|0|0|1|1|une asset super top",
    )


def test_unpack():
    assert fairminter.unpack(
        b"FAIRMINTED||0|1|10|1000|100|800000|900000|50|850000|10000000|0|0|1|1|une asset super top",
        True,
    ) == {
        "asset": "FAIRMINTED",
        "asset_parent": "",
        "price": 0,
        "quantity_by_price": 1,
        "max_mint_per_tx": 10,
        "hard_cap": 1000,
        "premint_quantity": 100,
        "start_block": 800000,
        "end_block": 900000,
        "soft_cap": 50,
        "soft_cap_deadline_block": 850000,
        "minted_asset_commission": Decimal("0.1"),
        "burn_payment": False,
        "lock_description": False,
        "lock_quantity": True,
        "divisible": True,
        "description": "une asset super top",
    }

    assert fairminter.unpack(
        b"FAIRMINTED||0|1|10|1000|100|800000|900000|50|850000|10000000|0|0|1|1|une asset super top",
        False,
    ) == (
        "FAIRMINTED",
        "",
        0,
        1,
        10,
        1000,
        100,
        800000,
        900000,
        50,
        850000,
        Decimal("0.1"),
        False,
        False,
        True,
        True,
        "une asset super top",
    )


def test_parse_fairminter_start_block(
    ledger_db, blockchain_mock, defaults, test_helpers, current_block_index
):
    tx = blockchain_mock.dummy_tx(ledger_db, defaults["addresses"][0])
    message = (
        b"FAIRMINTED||0|1|10|1000|100|800000|900000|50|850000|10000000|0|0|1|1|une asset super top"
    )
    fairminter.parse(ledger_db, tx, message)

    test_helpers.check_records(
        ledger_db,
        [
            {
                "table": "fairminters",
                "values": {
                    "tx_hash": tx["tx_hash"],
                    "block_index": tx["block_index"],
                    "asset": "FAIRMINTED",
                    "asset_parent": None,
                    "price": 0,
                    "quantity_by_price": 1,
                    "max_mint_per_tx": 10,
                    "hard_cap": 1000,
                    "premint_quantity": 100,
                    "start_block": 800000,
                    "end_block": 900000,
                    "soft_cap": 50,
                    "soft_cap_deadline_block": 850000,
                    "minted_asset_commission_int": 10000000,
                    "burn_payment": False,
                    "lock_description": False,
                    "lock_quantity": True,
                    "divisible": True,
                    "description": "une asset super top",
                    "status": "pending",
                },
            },
            {
                "table": "issuances",
                "values": {
                    "tx_hash": tx["tx_hash"],
                    "block_index": tx["block_index"],
                    "asset": "FAIRMINTED",
                    "quantity": 100,
                    "divisible": True,
                    "source": defaults["addresses"][0],
                    "issuer": defaults["addresses"][0],
                    "transfer": False,
                    "callable": False,
                    "call_date": 0,
                    "call_price": 0,
                    "description": "une asset super top",
                    "fee_paid": 50000000,
                    "locked": False,
                    "reset": False,
                    "status": "valid",
                    "asset_longname": None,
                    "fair_minting": True,
                },
            },
            {
                "table": "assets",
                "values": {
                    "asset_id": "27217170918239",
                    "asset_name": "FAIRMINTED",
                    "block_index": tx["block_index"],
                    "asset_longname": None,
                },
            },
            {
                "table": "credits",
                "values": {
                    "block_index": current_block_index,
                    "address": defaults["unspendable"],
                    "asset": "FAIRMINTED",
                    "quantity": 100,
                    "calling_function": "escrowed premint",
                    "event": tx["tx_hash"],
                },
            },
        ],
    )


def test_parse_fairminter_soft_cap(
    ledger_db, blockchain_mock, defaults, test_helpers, current_block_index
):
    tx = blockchain_mock.dummy_tx(ledger_db, defaults["addresses"][0])
    message = b"FAIRMINTED||0|1|10|1000|100|0|900000|50|850000|10000000|0|0|1|1|une asset super top"
    fairminter.parse(ledger_db, tx, message)

    test_helpers.check_records(
        ledger_db,
        [
            {
                "table": "fairminters",
                "values": {
                    "tx_hash": tx["tx_hash"],
                    "block_index": tx["block_index"],
                    "asset": "FAIRMINTED",
                    "asset_parent": None,
                    "price": 0,
                    "quantity_by_price": 1,
                    "max_mint_per_tx": 10,
                    "hard_cap": 1000,
                    "premint_quantity": 100,
                    "start_block": 0,
                    "end_block": 900000,
                    "soft_cap": 50,
                    "soft_cap_deadline_block": 850000,
                    "minted_asset_commission_int": 10000000,
                    "burn_payment": False,
                    "lock_description": False,
                    "lock_quantity": True,
                    "divisible": True,
                    "description": "une asset super top",
                    "status": "open",
                },
            },
            {
                "table": "credits",
                "values": {
                    "block_index": current_block_index,
                    "address": defaults["unspendable"],
                    "asset": "FAIRMINTED",
                    "quantity": 100,
                    "calling_function": "escrowed premint",
                    "event": tx["tx_hash"],
                },
            },
        ],
    )


def test_parse_fairminter_no_start(
    ledger_db, blockchain_mock, defaults, test_helpers, current_block_index
):
    tx = blockchain_mock.dummy_tx(ledger_db, defaults["addresses"][0])
    message = b"FAIRMINTED||0|1|10|1000|100|0|900000|0|0|10000000|0|0|1|1|une asset super top"
    fairminter.parse(ledger_db, tx, message)

    test_helpers.check_records(
        ledger_db,
        [
            {
                "table": "fairminters",
                "values": {
                    "tx_hash": tx["tx_hash"],
                    "block_index": tx["block_index"],
                    "source": defaults["addresses"][0],
                    "asset": "FAIRMINTED",
                    "asset_parent": None,
                    "price": 0,
                    "quantity_by_price": 1,
                    "max_mint_per_tx": 10,
                    "hard_cap": 1000,
                    "premint_quantity": 100,
                    "start_block": 0,
                    "end_block": 900000,
                    "soft_cap": 0,
                    "soft_cap_deadline_block": 0,
                    "minted_asset_commission_int": 10000000,
                    "burn_payment": False,
                    "lock_description": False,
                    "lock_quantity": True,
                    "divisible": True,
                    "description": "une asset super top",
                    "status": "open",
                },
            },
            {
                "table": "credits",
                "values": {
                    "block_index": current_block_index,
                    "address": defaults["addresses"][0],
                    "asset": "FAIRMINTED",
                    "quantity": 100,
                    "calling_function": "premint",
                    "event": tx["tx_hash"],
                },
            },
        ],
    )
