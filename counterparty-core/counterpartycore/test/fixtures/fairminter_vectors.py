from decimal import Decimal

from counterpartycore.lib import config, deserialize, exceptions, script  # noqa: F401

from .params import (
    ADDR,
)

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
    }
}
