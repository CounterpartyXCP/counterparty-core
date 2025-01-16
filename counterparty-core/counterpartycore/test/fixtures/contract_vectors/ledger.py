from fractions import Fraction

from counterpartycore.lib import exceptions

from ..params import (
    ADDR,
)
from ..params import DEFAULT_PARAMS as DP

LEDGER_VECTOR = {
    "ledger.ledger": {
        "last_message": [
            {
                "in": (),
                "out": {
                    "message_index": 1743,
                    "block_index": 310703,
                    "command": "parse",
                    "category": "blocks",
                    "bindings": '{"block_index":310703,"ledger_hash":"3e8ba9968f58a14dd4950aa1a1f02d58edfd246a2ac733a5fac4aa2c04505e3e","messages_hash":"794d8c3df2ea1ce1b68833e0c33f7a846445f6da53dadceaaff41aac66dd5c83","transaction_count":0,"txlist_hash":"c76b69cb9056ed5b35e10737d93aa2fde389690899503f46f3ca18d419ce4dd2"}',
                    "timestamp": 0,
                    "event": "BLOCK_PARSED",
                    "tx_hash": None,
                    "event_hash": "7c68ff23281790be67a757e3ba0eb0a0bcd57ca2cae307531a1ae9de28f9c939",
                },
            }
        ],
        "generate_asset_id": [
            {"in": ("BTC", DP["default_block_index"]), "out": 0},
            {"in": ("XCP", DP["default_block_index"]), "out": 1},
            {"in": ("BCD", 308000), "error": (exceptions.AssetNameError, "too short")},
            {
                "in": ("ABCD", 308000),
                "error": (exceptions.AssetNameError, "non‐numeric asset name starts with ‘A’"),
            },
            {
                "in": (f"A{26**12}", 308000),
                "error": (exceptions.AssetNameError, "numeric asset name not in range"),
            },
            {
                "in": (f"A{2**64}", 308000),
                "error": (exceptions.AssetNameError, "numeric asset name not in range"),
            },
            {"in": (f"A{26**12 + 1}", 308000), "out": 26**12 + 1},
            {"in": (f"A{2**64 - 1}", 308000), "out": 2**64 - 1},
            {
                "in": ("LONGASSETNAMES", 308000),
                "error": (exceptions.AssetNameError, "long asset names must be numeric"),
            },
            {
                "in": ("BCDE_F", 308000),
                "error": (exceptions.AssetNameError, "invalid character:"),
            },
            {"in": ("BAAA", 308000), "out": 26**3},
            {"in": ("ZZZZZZZZZZZZ", 308000), "out": 26**12 - 1},
        ],
        "generate_asset_name": [
            {"in": (0, DP["default_block_index"]), "out": "BTC"},
            {"in": (1, DP["default_block_index"]), "out": "XCP"},
            {"in": (26**12 - 1, 308000), "out": "ZZZZZZZZZZZZ"},
            {"in": (26**3, 308000), "out": "BAAA"},
            {"in": (2**64 - 1, 308000), "out": f"A{2**64 - 1}"},
            {"in": (26**12 + 1, 308000), "out": f"A{26**12 + 1}"},
            {"in": (26**3 - 1, 308000), "error": (exceptions.AssetIDError, "too low")},
            {"in": (2**64, 308000), "error": (exceptions.AssetIDError, "too high")},
        ],
        "price": [{"in": (1, 10), "out": Fraction(1, 10)}],
        "get_asset_id": [
            {"in": ("XCP", DP["default_block_index"]), "out": 1},
            {"in": ("BTC", DP["default_block_index"]), "out": 0},
            {
                "in": ("foobar", DP["default_block_index"]),
                "error": (exceptions.AssetError, "No such asset: foobar"),
            },
        ],
        "resolve_subasset_longname": [
            {"in": ("XCP",), "out": "XCP"},
            {"in": ("PARENT",), "out": "PARENT"},
            {"in": ("PARENT.nonexistent.subasset",), "out": "PARENT.nonexistent.subasset"},
            {"in": ("PARENT.ILEGAL^^^",), "out": "PARENT.ILEGAL^^^"},
            {"in": ("PARENT.already.issued",), "out": f"A{26**12 + 101}"},
        ],
        "debit": [
            {"in": (ADDR[0], "XCP", 1, 0), "out": None},
            {
                "in": (ADDR[0], "BTC", DP["quantity"], 0),
                "error": (exceptions.DebitError, "Cannot debit bitcoins."),
            },
            {
                "in": (ADDR[0], "BTC", -1 * DP["quantity"], 0),
                "error": (exceptions.DebitError, "Negative quantity."),
            },
            {
                "in": (ADDR[0], "BTC", 1.1 * DP["quantity"], 0),
                "error": (exceptions.DebitError, "Quantity must be an integer."),
            },
            {
                "in": (ADDR[0], "XCP", 2**40, 0),
                "error": (exceptions.DebitError, "Insufficient funds."),
            },
        ],
        "credit": [
            {"in": (ADDR[0], "XCP", 1, 0), "out": None},
            {
                "in": (ADDR[0], "BTC", DP["quantity"], 0),
                "error": (exceptions.CreditError, "Cannot debit bitcoins."),
            },
            {
                "in": (ADDR[0], "BTC", -1 * DP["quantity"], 0),
                "error": (exceptions.CreditError, "Negative quantity."),
            },
            {
                "in": (ADDR[0], "BTC", 1.1 * DP["quantity"], 0),
                "error": (exceptions.CreditError, "Quantity must be an integer."),
            },
        ],
        "is_divisible": [
            {"in": ("XCP",), "out": True},
            {"in": ("BTC",), "out": True},
            {"in": ("DIVISIBLE",), "out": True},
            {"in": ("NODIVISIBLE",), "out": False},
            {"in": ("foobar",), "error": (exceptions.AssetError, "No such asset: foobar")},
        ],
        "value_in": [
            {
                "in": (
                    1.1,
                    "leverage",
                ),
                "out": 1,
            },
            {
                "in": (
                    1 / 10,
                    "fraction",
                ),
                "out": 0.1,
            },
            {
                "in": (
                    1,
                    "NODIVISIBLE",
                ),
                "out": 1,
            },
            {
                "in": (
                    1.111111111111,
                    "DIVISIBLE",
                ),
                "error": (
                    exceptions.QuantityError,
                    "Divisible assets have only eight decimal places of precision.",
                ),
            },
            {
                "in": (
                    1.1,
                    "NODIVISIBLE",
                ),
                "error": (exceptions.QuantityError, "Fractional quantities of indivisible assets."),
            },
        ],
        "value_out": [
            {
                "in": (
                    1.1,
                    "leverage",
                ),
                "out": "1.1",
            },
            {
                "in": (
                    1 / 10,
                    "fraction",
                ),
                "out": "10.0%",
            },
            {
                "in": (
                    1,
                    "NODIVISIBLE",
                ),
                "out": 1,
            },
            {
                "in": (
                    1.1,
                    "NODIVISIBLE",
                ),
                "error": (exceptions.QuantityError, "Fractional quantities of indivisible assets."),
            },
        ],
        "xcp_created": [{"in": (), "out": 604506847920}],
        "xcp_destroyed": [{"in": (), "out": 725000000}],
        "xcp_supply": [
            {
                "in": (),
                "out": 603781847920,
            }
        ],
        "creations": [
            {
                "in": (),
                "out": {
                    "XCP": 604506847920,
                    "CALLABLE": 1000,
                    "DIVIDEND": 100,
                    "DIVISIBLE": 100000000000,
                    "FREEFAIRMIN": 10,
                    "LOCKED": 1000,
                    "LOCKEDPREV": 1000,
                    "MAXI": 9223372036854775807,
                    "NODIVISIBLE": 1000,
                    "PAIDFAIRMIN": 0,
                    "PAYTOSCRIPT": 1000,
                    "A95428956661682277": 100000000,
                    "PARENT": 100000000,
                    "QAIDFAIRMIN": 20,
                    "RAIDFAIRMIN": 20,
                    "TESTDISP": 1000,
                    "A160361285792733729": 50,
                },
            }
        ],
        "destructions": [{"in": (), "out": {"XCP": 725000000}}],
        "asset_supply": [
            {
                "in": ("DIVISIBLE",),
                "out": 100000000000,
            }
        ],
        "supplies": [
            {
                "in": (),
                "out": {
                    "XCP": 603781847920,
                    "A95428956661682277": 100000000,
                    "CALLABLE": 1000,
                    "DIVIDEND": 100,
                    "DIVISIBLE": 100000000000,
                    "FREEFAIRMIN": 10,
                    "LOCKED": 1000,
                    "LOCKEDPREV": 1000,
                    "MAXI": 9223372036854775807,
                    "NODIVISIBLE": 1000,
                    "PAIDFAIRMIN": 0,
                    "PARENT": 100000000,
                    "PAYTOSCRIPT": 1000,
                    "QAIDFAIRMIN": 20,
                    "RAIDFAIRMIN": 20,
                    "A160361285792733729": 50,
                    "TESTDISP": 1000,
                },
            }
        ],
        "get_balance": [
            {"in": (ADDR[0], "XCP"), "out": 91674999900},
            {"in": (ADDR[0], "foobar"), "out": 0},
        ],
        "get_asset_name": [
            {"in": (1, DP["default_block_index"]), "out": "XCP"},
            {"in": (0, DP["default_block_index"]), "out": "BTC"},
            {"in": (453, DP["default_block_index"]), "out": 0},
        ],
        "holders": [
            {
                "in": ("XCP",),
                "out": [
                    {
                        "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc",
                        "address_quantity": 91674999900,
                        "escrow": None,
                    },
                    {
                        "address": "mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns",
                        "address_quantity": 99999990,
                        "escrow": None,
                    },
                    {
                        "address": "1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2",
                        "address_quantity": 300000000,
                        "escrow": None,
                    },
                    {
                        "address": "myAtcJEHAsDLbTkai6ipWDZeeL7VkxXsiM",
                        "address_quantity": 92999138821,
                        "escrow": None,
                    },
                    {
                        "address": "munimLLHjPhGeSU5rYB2HN79LJa8bRZr5b",
                        "address_quantity": 92949130360,
                        "escrow": None,
                    },
                    {
                        "address": "mwtPsLQxW9xpm7gdLmwWvJK5ABdPUVJm42",
                        "address_quantity": 92949122099,
                        "escrow": None,
                    },
                    {
                        "address": "mrPk7hTeZWjjSCrMTC2ET4SAUThQt7C4uK",
                        "address_quantity": 14999857,
                        "escrow": None,
                    },
                    {
                        "address": "2MyJHMUenMWonC35Yi6PHC7i2tkS7PuomCy",
                        "address_quantity": 46449548498,
                        "escrow": None,
                    },
                    {
                        "address": "tb1qw508d6qejxtdg4y5r3zarvary0c5xw7kxpjzsx",
                        "address_quantity": 92999030129,
                        "escrow": None,
                    },
                    {
                        "address": "mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH",
                        "address_quantity": 0,
                        "escrow": None,
                    },
                    {
                        "address": "mqPCfvqTfYctXMUfmniXeG2nyaN8w6tPmj",
                        "address_quantity": 92945878046,
                        "escrow": None,
                    },
                    {
                        "address": "mvCounterpartyXXXXXXXXXXXXXXW24Hef",
                        "address_quantity": 0,
                        "escrow": None,
                    },
                    {
                        "address": "1e9d0b5cc5b3f56cc59c0e8f3268d6ad10f79337aaf19081580c486caeb4cf53:0",
                        "address_quantity": 100,
                        "escrow": None,
                    },
                    {
                        "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc",
                        "address_quantity": 100000000,
                        "escrow": "e7038bdcd8fe79d282000f04123f98549c7abb40163fc9580b02486b4c1a55cf",
                    },
                    {
                        "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc",
                        "address_quantity": 100000000,
                        "escrow": "fd6aeb0164a5356b037899060e4de0a10adce4c991d2dd8c89dcbdadbe110d38",
                    },
                    {
                        "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc",
                        "address_quantity": 100000000,
                        "escrow": "b6c0ce5991e1ab4b46cdd25f612cda202d123872c6250831bc0f510a90c1238e",
                    },
                    {
                        "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc",
                        "address_quantity": 100000000,
                        "escrow": "65e649d58b95602b04172375dbd86783b7379e455a2bc801338d9299d10425a5",
                    },
                    {
                        "address": "mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns",
                        "address_quantity": 10,
                        "escrow": "7a2ab30a4e996078632806cebc56e62cc6b04ce45a027394faa6e3dee71bf886",
                    },
                    {
                        "address": "2MyJHMUenMWonC35Yi6PHC7i2tkS7PuomCy",
                        "address_quantity": 10,
                        "escrow": "a6b4d83090c07d9c14c4e76f066a003af1aed246a71c90b4c4f0f47b8040db97",
                    },
                    {
                        "address": "munimLLHjPhGeSU5rYB2HN79LJa8bRZr5b",
                        "address_quantity": 100,
                        "escrow": None,
                    },
                ],
            },
            {
                "in": ("DIVISIBLE",),
                "out": [
                    {
                        "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc",
                        "address_quantity": 98799999999,
                        "escrow": None,
                    },
                    {
                        "address": "mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns",
                        "address_quantity": 100000000,
                        "escrow": None,
                    },
                    {
                        "address": "1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2",
                        "address_quantity": 1000000000,
                        "escrow": None,
                    },
                    {
                        "address": "2MyJHMUenMWonC35Yi6PHC7i2tkS7PuomCy",
                        "address_quantity": 100000000,
                        "escrow": None,
                    },
                    {
                        "address": "7b4bb2e22f2a6d03933266f4ad34a4f7bf3ef7d2d4aeeea81edc5de59493eb7c:0",
                        "address_quantity": 1,
                        "escrow": None,
                    },
                ],
            },
        ],
        "last_db_index": [{"in": (), "out": DP["default_block_index"] - 1}],
        "get_credits_by_asset": [
            {
                "in": ("A160361285792733729",),
                "out": [
                    {
                        "block_index": 310504,
                        "address": "mvCounterpartyXXXXXXXXXXXXXXW24Hef",
                        "asset": "A160361285792733729",
                        "quantity": 20,
                        "calling_function": "escrowed premint",
                        "event": "d0110ffec4330d438c7abf22615be38468b9127e9d178d4334616b5f05733c79",
                        "tx_index": 505,
                        "utxo": None,
                        "utxo_address": None,
                    },
                    {
                        "block_index": 310505,
                        "address": "mvCounterpartyXXXXXXXXXXXXXXW24Hef",
                        "asset": "A160361285792733729",
                        "quantity": 10,
                        "calling_function": "escrowed fairmint",
                        "event": "576d7993ac32b52a21ee8693061ff0b5fc8ee7dfe8d8c6bec438ee98313d6e57",
                        "tx_index": 506,
                        "utxo": None,
                        "utxo_address": None,
                    },
                    {
                        "block_index": 310506,
                        "address": "mvCounterpartyXXXXXXXXXXXXXXW24Hef",
                        "asset": "A160361285792733729",
                        "quantity": 20,
                        "calling_function": "escrowed fairmint",
                        "event": "b3f38f734f84ad73390e8c319ca0c68774f087c4c7874f989ddf218f021144fc",
                        "tx_index": 507,
                        "utxo": None,
                        "utxo_address": None,
                    },
                    {
                        "block_index": 310506,
                        "address": "mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns",
                        "asset": "A160361285792733729",
                        "quantity": 7,
                        "calling_function": "unescrowed fairmint",
                        "event": "576d7993ac32b52a21ee8693061ff0b5fc8ee7dfe8d8c6bec438ee98313d6e57",
                        "tx_index": 506,
                        "utxo": None,
                        "utxo_address": None,
                    },
                    {
                        "block_index": 310506,
                        "address": "mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns",
                        "asset": "A160361285792733729",
                        "quantity": 3,
                        "calling_function": "fairmint commission",
                        "event": "576d7993ac32b52a21ee8693061ff0b5fc8ee7dfe8d8c6bec438ee98313d6e57",
                        "tx_index": 506,
                        "utxo": None,
                        "utxo_address": None,
                    },
                    {
                        "block_index": 310506,
                        "address": "mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns",
                        "asset": "A160361285792733729",
                        "quantity": 14,
                        "calling_function": "unescrowed fairmint",
                        "event": "b3f38f734f84ad73390e8c319ca0c68774f087c4c7874f989ddf218f021144fc",
                        "tx_index": 507,
                        "utxo": None,
                        "utxo_address": None,
                    },
                    {
                        "block_index": 310506,
                        "address": "mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns",
                        "asset": "A160361285792733729",
                        "quantity": 6,
                        "calling_function": "fairmint commission",
                        "event": "b3f38f734f84ad73390e8c319ca0c68774f087c4c7874f989ddf218f021144fc",
                        "tx_index": 507,
                        "utxo": None,
                        "utxo_address": None,
                    },
                    {
                        "block_index": 310506,
                        "address": "mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns",
                        "asset": "A160361285792733729",
                        "quantity": 20,
                        "calling_function": "premint",
                        "event": "d0110ffec4330d438c7abf22615be38468b9127e9d178d4334616b5f05733c79",
                        "tx_index": 0,
                        "utxo": None,
                        "utxo_address": None,
                    },
                ],
            }
        ],
        "get_debits_by_asset": [
            {
                "in": ("A160361285792733729",),
                "out": [
                    {
                        "block_index": 310506,
                        "address": "mvCounterpartyXXXXXXXXXXXXXXW24Hef",
                        "asset": "A160361285792733729",
                        "quantity": 50,
                        "action": "unescrowed fairmint",
                        "event": "d0110ffec4330d438c7abf22615be38468b9127e9d178d4334616b5f05733c79",
                        "tx_index": 0,
                        "utxo": None,
                        "utxo_address": None,
                    }
                ],
            }
        ],
    },
}
