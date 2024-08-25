from decimal import Decimal

from ..params import (
    ADDR,
)
from ..params import DEFAULT_PARAMS as DP

# source
# asset
# asset_parent,
# price=0,
# max_mint_per_tx,
# hard_cap=0,
# premint_quantity=0,
# start_block=0,
# end_block=0,
# soft_cap=0,
# soft_cap_deadline_block=0,
# minted_asset_commission=0.0,
# burn_payment=False,
# lock_description=False,
# lock_quantity=True,
# divisible=True,
# description="",

FAIRMINTER_VECTOR = {
    "fairminter": {
        "validate": [
            {
                "in": (
                    ADDR[1],  # source
                    "FAIRMINTED",  # asset
                    "",  # asset_parent,
                    0,  # price=0,
                    10,  # max_mint_per_tx,
                ),
                "out": ([]),
            },
            {
                "in": (
                    ADDR[1],  # source
                    "FAIRMINTED",  # asset
                    "",  # asset_parent,
                    1000,  # price=0,
                ),
                "out": ([]),
            },
            {
                "in": (
                    ADDR[1],  # source
                    "FAIRMINTED1",  # asset
                ),
                "out": (
                    [
                        "Invalid asset name: ('invalid character:', '1')",
                        "Price or max_mint_per_tx must be > 0.",
                    ]
                ),
            },
            {
                "in": (
                    ADDR[1],  # source
                    "A1603612687792733727",  # asset
                    "",  # asset_parent,
                    0,  # price=0,
                    10,  # max_mint_per_tx,
                ),
                "out": ([]),
            },
            {
                "in": (
                    ADDR[1],  # source
                    "A1603612687",  # asset
                    "",  # asset_parent,
                    0,  # price=0,
                    10,  # max_mint_per_tx,
                ),
                "out": (["Invalid asset name: numeric asset name not in range"]),
            },
            {
                "in": (
                    ADDR[1],  # source
                    "FAIRMINTED",  # asset
                    "",  # asset_parent,
                    0,  # price=0,
                    -10,  # max_mint_per_tx,
                ),
                "out": (["`max_mint_per_tx` must be >= 0."]),
            },
            {
                "in": (
                    ADDR[1],  # source
                    "FAIRMINTED",  # asset
                    "",  # asset_parent,
                    0,  # price=0,
                    -10,  # max_mint_per_tx,
                    40,  # hard_cap=0,
                    50,  # premint_quantity=0,
                    50,  # start_block=0,
                    49,  # end_block=0,
                    55,  # soft_cap=0,
                    0,  # soft_cap_deadline_block=0,
                    500,  # minted_asset_commission=0.0,
                    0,  # burn_payment=False,
                ),
                "out": (
                    [
                        "`max_mint_per_tx` must be >= 0.",
                        "`burn_payment` must be a boolean.",
                        "minted_asset_commission must be a float",
                        "Premint quantity must be < hard cap.",
                        "Start block must be <= end block.",
                        "Soft cap must be < hard cap.",
                        "Soft cap deadline block must be specified if soft cap is specified.",
                    ]
                ),
            },
            {
                "in": (
                    ADDR[1],  # source
                    "LOCKEDPREV",  # asset
                    "",  # asset_parent,
                    0,  # price=0,
                    10,  # max_mint_per_tx,
                ),
                "out": (
                    [
                        "Asset `LOCKEDPREV` is locked.",
                        "Asset `LOCKEDPREV` is not issued by `mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns`.",
                    ]
                ),
            },
            {
                "in": (
                    ADDR[0],  # source
                    "DIVISIBLE",  # asset
                    "",  # asset_parent,
                    0,  # price=0,
                    10,  # max_mint_per_tx,
                ),
                "out": ([]),
            },
            {
                "in": (
                    ADDR[0],  # source
                    "DIVISIBLE",  # asset
                    "",  # asset_parent,
                    0,  # price=0,
                    10,  # max_mint_per_tx,
                    DP["quantity"] * 900,  # hard_cap=0,
                ),
                "out": (["Hard cap of asset `DIVISIBLE` is already reached."]),
            },
            {
                "in": (
                    ADDR[0],  # source
                    "SUBASSET",  # asset
                    "DIVISIBLE",  # asset_parent,
                    0,  # price=0,
                    10,  # max_mint_per_tx,
                ),
                "out": ([]),
            },
            {
                "in": (
                    ADDR[0],  # source
                    "SUBASSET",  # asset
                    "NOASSET",  # asset_parent,
                    0,  # price=0,
                    10,  # max_mint_per_tx,
                ),
                "out": (["Asset parent does not exist"]),
            },
            {
                "in": (
                    ADDR[0],  # source
                    "FREEFAIRMIN",  # asset
                    "",  # asset_parent,
                    0,  # price=0,
                    10,  # max_mint_per_tx,
                ),
                "out": (["Fair minter already opened for `FREEFAIRMIN`."]),
            },
        ],
        "compose": [
            {
                "in": (
                    ADDR[1],  # source
                    "FAIRMINTED",  # asset
                    "",  # asset_parent,
                    0,  # price=0,
                    10,  # max_mint_per_tx,
                ),
                "out": (
                    "mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns",
                    [],
                    b"ZFAIRMINTED||0|10|0|0|0|0|0|0|0|0|0|0|1|",
                ),
            },
            {
                "in": (
                    ADDR[1],  # source
                    "FAIRMINTED",  # asset
                    "",  # asset_parent,
                    0,  # price,
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
                    "une asset super top",  # description,
                ),
                "out": (
                    "mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns",
                    [],
                    b"ZFAIRMINTED||0|10|1000|100|800000|900000|50|850000|10000000|0|0|1|1|une asset super top",
                ),
            },
        ],
        "unpack": [
            {
                "in": (
                    b"FAIRMINTED||0|10|1000|100|800000|900000|50|850000|10000000|0|0|1|1|une asset super top",
                    True,
                ),
                "out": (
                    {
                        "asset": "FAIRMINTED",
                        "asset_parent": "",
                        "price": 0,
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
                ),
            },
            {
                "in": (
                    b"FAIRMINTED||0|10|1000|100|800000|900000|50|850000|10000000|0|0|1|1|une asset super top",
                    False,
                ),
                "out": (
                    "FAIRMINTED",
                    "",
                    0,
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
                ),
            },
        ],
        "parse": [
            {
                "comment": "Fairminter with start block and soft cap",
                "in": (
                    {
                        "fee": 10000,
                        "tx_hash": "72a62abedd38d5f667150929c24dc1d7465dd81ab1502974814d20c1f65d871f",
                        "data": b"ZFAIRMINTED||0|10|1000|100|800000|900000|50|850000|10000000|0|0|1|1|une asset super top",
                        "source": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc",
                        "block_index": DP["default_block_index"],
                        "btc_amount": 5430,
                        "tx_index": DP["default_tx_index"],
                        "supported": 1,
                        "destination": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc",
                        "block_time": 310501000,
                        "block_hash": "46ac6d09237c7961199068fdd13f1508d755483e07c57a4c8f7ff18eb33a05c93ca6a86fa2e2af82fb77a5c337146bb37e279797a3d11970aec4693c46ea5a58",
                    },
                ),
                "records": [
                    {
                        "table": "fairminters",
                        "values": {
                            "tx_hash": "72a62abedd38d5f667150929c24dc1d7465dd81ab1502974814d20c1f65d871f",
                            "block_index": DP["default_block_index"],
                            "asset": "FAIRMINTED",
                            "asset_parent": "",
                            "price": 0,
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
                            "tx_hash": "72a62abedd38d5f667150929c24dc1d7465dd81ab1502974814d20c1f65d871f",
                            "block_index": DP["default_block_index"],
                            "asset": "FAIRMINTED",
                            "quantity": 100,
                            "divisible": True,
                            "source": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc",
                            "issuer": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc",
                            "transfer": False,
                            "callable": False,
                            "call_date": 0,
                            "call_price": 0,
                            "description": "une asset super top",
                            "fee_paid": 50000000,
                            "locked": False,
                            "reset": False,
                            "status": "valid",
                            "asset_longname": "",
                            "fair_minting": True,
                        },
                    },
                    {
                        "table": "assets",
                        "values": {
                            "asset_id": "27217170918239",
                            "asset_name": "FAIRMINTED",
                            "block_index": DP["default_block_index"],
                            "asset_longname": None,
                        },
                    },
                    {
                        "table": "credits",
                        "values": {
                            "block_index": DP["default_block_index"],
                            "address": "mvCounterpartyXXXXXXXXXXXXXXW24Hef",
                            "asset": "FAIRMINTED",
                            "quantity": 100,
                            "calling_function": "escrowed premint",
                            "event": "72a62abedd38d5f667150929c24dc1d7465dd81ab1502974814d20c1f65d871f",
                        },
                    },
                ],
            },
            {
                "comment": "Fairminter without start block and with soft cap",
                "in": (
                    {
                        "fee": 10000,
                        "tx_hash": "72a62abedd38d5f667150929c24dc1d7465dd81ab1502974814d20c1f65d871f",
                        "data": b"ZFAIRMINTED||0|10|1000|100|0|900000|50|850000|10000000|0|0|1|1|une asset super top",
                        "source": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc",
                        "block_index": DP["default_block_index"],
                        "btc_amount": 5430,
                        "tx_index": DP["default_tx_index"],
                        "supported": 1,
                        "destination": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc",
                        "block_time": 310501000,
                        "block_hash": "46ac6d09237c7961199068fdd13f1508d755483e07c57a4c8f7ff18eb33a05c93ca6a86fa2e2af82fb77a5c337146bb37e279797a3d11970aec4693c46ea5a58",
                    },
                ),
                "records": [
                    {
                        "table": "fairminters",
                        "values": {
                            "tx_hash": "72a62abedd38d5f667150929c24dc1d7465dd81ab1502974814d20c1f65d871f",
                            "block_index": DP["default_block_index"],
                            "asset": "FAIRMINTED",
                            "asset_parent": "",
                            "price": 0,
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
                            "block_index": DP["default_block_index"],
                            "address": "mvCounterpartyXXXXXXXXXXXXXXW24Hef",
                            "asset": "FAIRMINTED",
                            "quantity": 100,
                            "calling_function": "escrowed premint",
                            "event": "72a62abedd38d5f667150929c24dc1d7465dd81ab1502974814d20c1f65d871f",
                        },
                    },
                ],
            },
            {
                "comment": "Fairminter without start block and without soft cap",
                "in": (
                    {
                        "fee": 10000,
                        "tx_hash": "72a62abedd38d5f667150929c24dc1d7465dd81ab1502974814d20c1f65d871f",
                        "data": b"ZFAIRMINTED||0|10|1000|100|0|900000|0|0|10000000|0|0|1|1|une asset super top",
                        "source": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc",
                        "block_index": DP["default_block_index"],
                        "btc_amount": 5430,
                        "tx_index": DP["default_tx_index"],
                        "supported": 1,
                        "destination": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc",
                        "block_time": 310501000,
                        "block_hash": "46ac6d09237c7961199068fdd13f1508d755483e07c57a4c8f7ff18eb33a05c93ca6a86fa2e2af82fb77a5c337146bb37e279797a3d11970aec4693c46ea5a58",
                    },
                ),
                "records": [
                    {
                        "table": "fairminters",
                        "values": {
                            "tx_hash": "72a62abedd38d5f667150929c24dc1d7465dd81ab1502974814d20c1f65d871f",
                            "block_index": DP["default_block_index"],
                            "source": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc",
                            "asset": "FAIRMINTED",
                            "asset_parent": "",
                            "price": 0,
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
                            "block_index": DP["default_block_index"],
                            "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc",
                            "asset": "FAIRMINTED",
                            "quantity": 100,
                            "calling_function": "premint",
                            "event": "72a62abedd38d5f667150929c24dc1d7465dd81ab1502974814d20c1f65d871f",
                        },
                    },
                ],
            },
        ],
    }
}
