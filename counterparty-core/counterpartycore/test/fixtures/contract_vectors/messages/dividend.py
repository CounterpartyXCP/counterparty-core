import binascii

from counterpartycore.test.fixtures.params import ADDR, DP

DIVIDEND_VECTOR = {
    "dividend": {
        "validate": [
            {
                "in": (
                    ADDR[0],
                    DP["quantity"] * 1000,
                    "DIVISIBLE",
                    "XCP",
                    DP["default_block_index"],
                ),
                "out": (None, None, ["insufficient funds (XCP)"], 0),
            },
            {
                "in": (
                    ADDR[0],
                    DP["quantity"] * -1000,
                    "DIVISIBLE",
                    "XCP",
                    DP["default_block_index"],
                ),
                "out": (None, None, ["non‐positive quantity per unit"], 0),
            },
            {
                "comment": "cannot pay dividends to holders of BTC",
                "in": (ADDR[0], DP["quantity"], "BTC", "XCP", DP["default_block_index"]),
                "out": (
                    None,
                    None,
                    ["cannot pay dividends to holders of BTC", "only issuer can pay dividends"],
                    0,
                ),
            },
            {
                "comment": "cannot pay dividends to holders of XCP",
                "in": (ADDR[0], DP["quantity"], "XCP", "XCP", DP["default_block_index"]),
                "out": (
                    None,
                    None,
                    [
                        "cannot pay dividends to holders of XCP",
                        "only issuer can pay dividends",
                        "insufficient funds (XCP)",
                    ],
                    0,
                ),
            },
            {
                "comment": "no such asset, NOASSET",
                "in": (ADDR[0], DP["quantity"], "NOASSET", "XCP", DP["default_block_index"]),
                "out": (None, None, ["no such asset, NOASSET."], 0),
            },
            {
                "comment": "non‐positive quantity per unit",
                "in": (ADDR[0], 0, "DIVISIBLE", "XCP", DP["default_block_index"]),
                "out": (None, None, ["non‐positive quantity per unit", "zero dividend"], 0),
            },
            {
                "in": (ADDR[1], DP["quantity"], "DIVISIBLE", "XCP", DP["default_block_index"]),
                "out": (
                    None,
                    None,
                    ["only issuer can pay dividends", "insufficient funds (XCP)"],
                    0,
                ),
            },
            {
                "in": (
                    ADDR[0],
                    DP["quantity"],
                    "DIVISIBLE",
                    "NOASSET",
                    DP["default_block_index"],
                ),
                "out": (None, None, ["no such dividend asset, NOASSET."], 0),
            },
            {
                "in": (ADDR[0], 8359090909, "DIVISIBLE", "XCP", DP["default_block_index"]),
                "out": (None, None, ["insufficient funds (XCP)"], 0),
            },
            {
                "in": (ADDR[2], 100000000, "DIVIDEND", "DIVIDEND", DP["default_block_index"]),
                "out": (None, None, ["insufficient funds (XCP)"], 0),
            },
            {
                "in": (ADDR[2], 2**63, "DIVIDEND", "DIVIDEND", DP["default_block_index"]),
                "out": (None, None, ["integer overflow", "insufficient funds (DIVIDEND)"], 0),
            },
        ],
        "compose": [
            {
                "in": (ADDR[0], DP["quantity"], "DIVISIBLE", "XCP"),
                "out": (
                    "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc",
                    [],
                    b"\x00\x00\x002\x00\x00\x00\x00\x05\xf5\xe1\x00\x00\x00\x00\xa2[\xe3Kf\x00\x00\x00\x00\x00\x00\x00\x01",
                ),
            },
            {
                "in": (ADDR[0], 1, "DIVISIBLE", "PARENT.already.issued"),
                "out": (
                    "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc",
                    [],
                    binascii.unhexlify("000000320000000000000001000000a25be34b6601530821671b1065"),
                ),
            },
        ],
        "parse": [
            {
                "comment": "dividend 1",
                "in": (
                    {
                        "tx_hash": "450c4ced564fa52a84746ecd79d64db6f124bddee19ff2c3cd926adea673ce4c",
                        "supported": 1,
                        "source": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc",
                        "data": b"\x00\x00\x002\x00\x00\x00\x00\x05\xf5\xe1\x00\x00\x00\x00\xa2[\xe3Kf\x00\x00\x00\x00\x00\x00\x00\x01",
                        "tx_index": DP["default_tx_index"],
                        "block_hash": "2d62095b10a709084b1854b262de77cb9f4f7cd76ba569657df8803990ffbfc6c12bca3c18a44edae9498e1f0f054072e16eef32dfa5e3dd4be149009115b4b8",
                        "block_index": DP["default_block_index"],
                        "btc_amount": 0,
                        "fee": 10000,
                        "destination": "",
                        "block_time": 155409000,
                    },
                ),
                "records": [
                    {
                        "table": "dividends",
                        "values": {
                            "asset": "DIVISIBLE",
                            "block_index": DP["default_block_index"],
                            "dividend_asset": "XCP",
                            "fee_paid": 80000,
                            "quantity_per_unit": 100000000,
                            "source": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc",
                            "status": "valid",
                            "tx_hash": "450c4ced564fa52a84746ecd79d64db6f124bddee19ff2c3cd926adea673ce4c",
                            "tx_index": DP["default_tx_index"],
                        },
                    },
                    {
                        "table": "credits",
                        "values": {
                            "address": "mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns",
                            "asset": "XCP",
                            "block_index": DP["default_block_index"],
                            "calling_function": "dividend",
                            "event": "450c4ced564fa52a84746ecd79d64db6f124bddee19ff2c3cd926adea673ce4c",
                            "quantity": 100000000,
                        },
                    },
                    {
                        "table": "credits",
                        "values": {
                            "address": "1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2",
                            "asset": "XCP",
                            "block_index": DP["default_block_index"],
                            "calling_function": "dividend",
                            "event": "450c4ced564fa52a84746ecd79d64db6f124bddee19ff2c3cd926adea673ce4c",
                            "quantity": 1000000000,
                        },
                    },
                    {
                        "table": "credits",
                        "values": {
                            "address": "2MyJHMUenMWonC35Yi6PHC7i2tkS7PuomCy",
                            "asset": "XCP",
                            "block_index": DP["default_block_index"],
                            "calling_function": "dividend",
                            "event": "450c4ced564fa52a84746ecd79d64db6f124bddee19ff2c3cd926adea673ce4c",
                            "quantity": 100000000,
                        },
                    },
                    {
                        "table": "debits",
                        "values": {
                            "action": "dividend",
                            "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc",
                            "asset": "XCP",
                            "block_index": DP["default_block_index"],
                            "event": "450c4ced564fa52a84746ecd79d64db6f124bddee19ff2c3cd926adea673ce4c",
                            "quantity": 1200000001,
                        },
                    },
                    {
                        "table": "debits",
                        "values": {
                            "action": "dividend fee",
                            "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc",
                            "asset": "XCP",
                            "block_index": DP["default_block_index"],
                            "event": "450c4ced564fa52a84746ecd79d64db6f124bddee19ff2c3cd926adea673ce4c",
                            "quantity": 80000,
                        },
                    },
                ],
            },
            {
                "comment": "dividend 2",
                "in": (
                    {
                        "tx_index": DP["default_tx_index"],
                        "btc_amount": 0,
                        "block_time": 155409000,
                        "source": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc",
                        "tx_hash": "5a36e9d939e70917695065b11b728f7ccbc7b828ae3baca1115885d8889e67c7",
                        "fee": 10000,
                        "block_index": DP["default_block_index"],
                        "block_hash": "2d62095b10a709084b1854b262de77cb9f4f7cd76ba569657df8803990ffbfc6c12bca3c18a44edae9498e1f0f054072e16eef32dfa5e3dd4be149009115b4b8",
                        "supported": 1,
                        "destination": "",
                        "data": b"\x00\x00\x002\x00\x00\x00\x00\x00\x00\x00\x01\x00\x06\xca\xd8\xdc\x7f\x0bf\x00\x00\x00\x00\x00\x00\x00\x01",
                    },
                ),
                "records": [
                    {
                        "table": "dividends",
                        "values": {
                            "asset": "NODIVISIBLE",
                            "block_index": DP["default_block_index"],
                            "dividend_asset": "XCP",
                            "fee_paid": 40000,
                            "quantity_per_unit": 1,
                            "source": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc",
                            "status": "valid",
                            "tx_hash": "5a36e9d939e70917695065b11b728f7ccbc7b828ae3baca1115885d8889e67c7",
                            "tx_index": DP["default_tx_index"],
                        },
                    },
                    {
                        "table": "credits",
                        "values": {
                            "address": "mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns",
                            "asset": "XCP",
                            "block_index": DP["default_block_index"],
                            "calling_function": "dividend",
                            "event": "5a36e9d939e70917695065b11b728f7ccbc7b828ae3baca1115885d8889e67c7",
                            "quantity": 5,
                        },
                    },
                    {
                        "table": "credits",
                        "values": {
                            "address": "1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2",
                            "asset": "XCP",
                            "block_index": DP["default_block_index"],
                            "calling_function": "dividend",
                            "event": "5a36e9d939e70917695065b11b728f7ccbc7b828ae3baca1115885d8889e67c7",
                            "quantity": 10,
                        },
                    },
                    {
                        "table": "debits",
                        "values": {
                            "action": "dividend",
                            "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc",
                            "asset": "XCP",
                            "block_index": DP["default_block_index"],
                            "event": "5a36e9d939e70917695065b11b728f7ccbc7b828ae3baca1115885d8889e67c7",
                            "quantity": 15,
                        },
                    },
                    {
                        "table": "debits",
                        "values": {
                            "action": "dividend fee",
                            "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc",
                            "asset": "XCP",
                            "block_index": DP["default_block_index"],
                            "event": "5a36e9d939e70917695065b11b728f7ccbc7b828ae3baca1115885d8889e67c7",
                            "quantity": 40000,
                        },
                    },
                ],
            },
        ],
    },
}
