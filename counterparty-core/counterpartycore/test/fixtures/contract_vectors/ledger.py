from fractions import Fraction

from counterpartycore.lib import exceptions
from counterpartycore.lib.ledger import CreditError, DebitError
from counterpartycore.lib.util import QuantityError

from ..params import (
    ADDR,
)
from ..params import DEFAULT_PARAMS as DP

LEDGER_VECTOR = {
    "ledger": {
        "generate_asset_id": [
            {"in": ("BTC", DP["default_block_index"]), "out": 0},
            {"in": ("XCP", DP["default_block_index"]), "out": 1},
            {"in": ("BCD", 308000), "error": (exceptions.AssetNameError, "too short")},
            {
                "in": ("ABCD", 308000),
                "error": (exceptions.AssetNameError, "non‐numeric asset name starts with ‘A’"),
            },
            {
                "in": (f"A{26 ** 12}", 308000),
                "error": (exceptions.AssetNameError, "numeric asset name not in range"),
            },
            {
                "in": (f"A{2 ** 64}", 308000),
                "error": (exceptions.AssetNameError, "numeric asset name not in range"),
            },
            {"in": (f"A{26 ** 12 + 1}", 308000), "out": 26**12 + 1},
            {"in": (f"A{2 ** 64 - 1}", 308000), "out": 2**64 - 1},
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
            {"in": (2**64 - 1, 308000), "out": f"A{2 ** 64 - 1}"},
            {"in": (26**12 + 1, 308000), "out": f"A{26 ** 12 + 1}"},
            {"in": (26**3 - 1, 308000), "error": (exceptions.AssetIDError, "too low")},
            {"in": (2**64, 308000), "error": (exceptions.AssetIDError, "too high")},
        ],
        "price": [{"in": (1, 10), "out": Fraction(1, 10)}],
        "last_message": [
            {
                "in": (),
                "out": {
                    "message_index": 1743,
                    "block_index": 310703,
                    "command": "parse",
                    "category": "blocks",
                    "bindings": '{"block_index":310703,"ledger_hash":"435eb1ceec68f0d5dd7beab6e4d110c0ba993cf60bbc0369fd3385b2027dfff7","messages_hash":"db86760cfa68a3e3544cfd0315f1553ed6c0a38bc5de62aee1a3cc9d27fde950","transaction_count":0,"txlist_hash":"0b3a0cb961faf745672ff92ec2fc84299dd7847a2f4fca293082bb116a4b3796"}',
                    "timestamp": 0,
                    "event": "BLOCK_PARSED",
                    "tx_hash": None,
                    "event_hash": "b8f86f88d43c029228dc0e261e6edcfcf665d28c84261a806acfeca46dcac46c",
                },
            }
        ],
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
            {"in": ("PARENT.already.issued",), "out": f"A{26 ** 12 + 101}"},
        ],
        "debit": [
            {"in": (ADDR[0], "XCP", 1, 0), "out": None},
            {
                "in": (ADDR[0], "BTC", DP["quantity"], 0),
                "error": (DebitError, "Cannot debit bitcoins."),
            },
            {
                "in": (ADDR[0], "BTC", -1 * DP["quantity"], 0),
                "error": (DebitError, "Negative quantity."),
            },
            {
                "in": (ADDR[0], "BTC", 1.1 * DP["quantity"], 0),
                "error": (DebitError, "Quantity must be an integer."),
            },
            {"in": (ADDR[0], "XCP", 2**40, 0), "error": (DebitError, "Insufficient funds.")},
        ],
        "credit": [
            {"in": (ADDR[0], "XCP", 1, 0), "out": None},
            {
                "in": (ADDR[0], "BTC", DP["quantity"], 0),
                "error": (CreditError, "Cannot debit bitcoins."),
            },
            {
                "in": (ADDR[0], "BTC", -1 * DP["quantity"], 0),
                "error": (CreditError, "Negative quantity."),
            },
            {
                "in": (ADDR[0], "BTC", 1.1 * DP["quantity"], 0),
                "error": (CreditError, "Quantity must be an integer."),
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
                    QuantityError,
                    "Divisible assets have only eight decimal places of precision.",
                ),
            },
            {
                "in": (
                    1.1,
                    "NODIVISIBLE",
                ),
                "error": (QuantityError, "Fractional quantities of indivisible assets."),
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
                "error": (QuantityError, "Fractional quantities of indivisible assets."),
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
                        "address": "0a84952a231b0044500b309ce0ccc0424f89279442aa625012c444115b69db25:0",
                        "address_quantity": 100,
                        "escrow": None,
                    },
                    {
                        "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc",
                        "address_quantity": 100000000,
                        "escrow": "6d55dc8fe1555cb48b66c764e1d7dcc76bd1792673d09bf4168051dcb6d76efb",
                    },
                    {
                        "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc",
                        "address_quantity": 100000000,
                        "escrow": "0e62cac5cbda7ce67b0cfdea3f5fc677bdae41914f98024cedc12688e6dc858b",
                    },
                    {
                        "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc",
                        "address_quantity": 100000000,
                        "escrow": "ce4828b474d96ed877b1d02d13357041cd4a1f26e3a7f3da23a2ec17fc818490",
                    },
                    {
                        "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc",
                        "address_quantity": 100000000,
                        "escrow": "50cc782f437b5ad64d54e31b76f91e37dc80bb91356c4e13f4ea3beb15d40d88",
                    },
                    {
                        "address": "mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns",
                        "address_quantity": 10,
                        "escrow": "d15d2cc622bcc43f80c9622b0ed4e2f8f48cb14704d2dfdc47d187878d2562b5",
                    },
                    {
                        "address": "2MyJHMUenMWonC35Yi6PHC7i2tkS7PuomCy",
                        "address_quantity": 10,
                        "escrow": "d17ac3eb8e983ec48fd424a9656300f6a4d62bb3cc1c72b899852ea29f4fc757",
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
                        "address": "d4be9b18026da66d35949ca0a6944e8404e9e9787c05abc5f37bbf5afaabd600:0",
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
                        "event": "04ce516e3ba88300c97b70073e09d579d203762c2aa9e531e4077c134701e8c0",
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
                        "event": "1516689ffc1cff3a39f45aec2651566ea0071c58fe5a43790c124324ed39da3c",
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
                        "event": "f43ecb7b700eafe5fd86819eb5d5ccdebdaac835584010fa44f7aea2b5e477b8",
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
                        "event": "1516689ffc1cff3a39f45aec2651566ea0071c58fe5a43790c124324ed39da3c",
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
                        "event": "1516689ffc1cff3a39f45aec2651566ea0071c58fe5a43790c124324ed39da3c",
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
                        "event": "f43ecb7b700eafe5fd86819eb5d5ccdebdaac835584010fa44f7aea2b5e477b8",
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
                        "event": "f43ecb7b700eafe5fd86819eb5d5ccdebdaac835584010fa44f7aea2b5e477b8",
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
                        "event": "04ce516e3ba88300c97b70073e09d579d203762c2aa9e531e4077c134701e8c0",
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
                        "event": "04ce516e3ba88300c97b70073e09d579d203762c2aa9e531e4077c134701e8c0",
                        "tx_index": 0,
                        "utxo": None,
                        "utxo_address": None,
                    }
                ],
            }
        ],
    },
}
