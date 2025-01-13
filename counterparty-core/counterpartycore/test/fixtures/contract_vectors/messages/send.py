import binascii

from counterpartycore.lib import exceptions
from counterpartycore.test.fixtures.params import (
    ADDR,
    MULTISIGADDR,
    P2SH_ADDR,
    P2WPKH_ADDR,
)
from counterpartycore.test.fixtures.params import DEFAULT_PARAMS as DP

SEND_VECTOR = {
    "send": {
        "validate": [
            {"in": (ADDR[0], ADDR[1], "XCP", DP["quantity"], 1), "out": ([])},
            {"in": (ADDR[0], P2SH_ADDR[0], "XCP", DP["quantity"], 1), "out": ([])},
            {"in": (P2SH_ADDR[0], ADDR[1], "XCP", DP["quantity"], 1), "out": ([])},
            {
                "in": (ADDR[0], ADDR[1], "BTC", DP["quantity"], 1),
                "out": (["cannot send bitcoins"]),
            },
            {
                "in": (ADDR[0], ADDR[1], "XCP", DP["quantity"] / 3, 1),
                "out": (["quantity must be in satoshis"]),
            },
            {
                "in": (ADDR[0], ADDR[1], "XCP", -1 * DP["quantity"], 1),
                "out": (["negative quantity"]),
            },
            {"in": (ADDR[0], MULTISIGADDR[0], "XCP", DP["quantity"], 1), "out": ([])},
            {"in": (ADDR[0], ADDR[1], "MAXI", 2**63 - 1, 1), "out": ([])},
            {"in": (ADDR[0], ADDR[1], "MAXI", 2**63, 1), "out": (["integer overflow"])},
            {
                "in": (ADDR[0], ADDR[6], "XCP", DP["quantity"], 1),
                "out": (["destination requires memo"]),
            },
        ],
        "compose": [
            {
                "in": (ADDR[0], ADDR[1], "XCP", DP["small"]),
                "out": (
                    "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc",
                    [("mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns", None)],
                    b"\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x02\xfa\xf0\x80",
                ),
            },
            {
                "in": (P2SH_ADDR[0], ADDR[1], "XCP", DP["small"]),
                "out": (
                    P2SH_ADDR[0],
                    [("mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns", None)],
                    b"\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x02\xfa\xf0\x80",
                ),
            },
            {
                "in": (ADDR[0], P2SH_ADDR[0], "XCP", DP["small"]),
                "out": (
                    "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc",
                    [(P2SH_ADDR[0], None)],
                    b"\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x02\xfa\xf0\x80",
                ),
            },
            {
                "in": (ADDR[0], ADDR[1], "XCP", DP["quantity"] * 10000000),
                "error": (exceptions.ComposeError, "insufficient funds"),
            },
            {
                "in": (ADDR[0], ADDR[1], "XCP", DP["quantity"] / 3),
                "error": (exceptions.ComposeError, "quantity must be an int (in satoshi)"),
            },
            {
                "in": (ADDR[0], MULTISIGADDR[0], "XCP", DP["quantity"]),
                "out": (
                    "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc",
                    [
                        (
                            "1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2",
                            None,
                        )
                    ],
                    b"\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x05\xf5\xe1\x00",
                ),
            },
            {
                "in": (MULTISIGADDR[0], ADDR[0], "XCP", DP["quantity"]),
                "out": (
                    "1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2",
                    [("mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", None)],
                    b"\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x05\xf5\xe1\x00",
                ),
            },
            {
                "in": (MULTISIGADDR[0], MULTISIGADDR[1], "XCP", DP["quantity"]),
                "out": (
                    "1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2",
                    [
                        (
                            "1_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2",
                            None,
                        )
                    ],
                    b"\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x05\xf5\xe1\x00",
                ),
            },
            {
                "in": (ADDR[0], ADDR[1], "MAXI", 2**63 - 1),
                "out": (
                    "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc",
                    [("mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns", None)],
                    b"\x00\x00\x00\x00\x00\x00\x00\x00\x00\x03:>\x7f\xff\xff\xff\xff\xff\xff\xff",
                ),
            },
            {
                "in": (ADDR[0], ADDR[1], "MAXI", 2**63 + 1),
                "error": (exceptions.ComposeError, "insufficient funds"),
            },
            {
                "in": (ADDR[0], ADDR[1], "BTC", DP["quantity"]),
                "out": (
                    "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc",
                    [("mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns", 100000000)],
                    None,
                ),
            },
            {
                "in": (ADDR[0], P2SH_ADDR[0], "BTC", DP["quantity"]),
                "out": (
                    "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc",
                    [("2MyJHMUenMWonC35Yi6PHC7i2tkS7PuomCy", 100000000)],
                    None,
                ),
            },
            {
                "comment": "resolve subasset to numeric asset",
                "in": (ADDR[0], ADDR[1], "PARENT.already.issued", 100000000),
                "out": (
                    "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc",
                    [("mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns", None)],
                    binascii.unhexlify("0000000001530821671b10650000000005f5e100"),
                ),
            },
            {
                "comment": "send to a REQUIRE_MEMO address, without memo",
                "in": (ADDR[0], ADDR[6], "XCP", 100000000),
                "error": (exceptions.ComposeError, ["destination requires memo"]),
            },
            {
                "comment": "send to a REQUIRE_MEMO address, with memo text, before enhanced_send activation",
                "in": (
                    {
                        "source": ADDR[0],
                        "destination": ADDR[6],
                        "asset": "XCP",
                        "quantity": 100000000,
                        "memo": "12345",
                        "use_enhanced_send": True,
                    }
                ),
                "error": (exceptions.ComposeError, "enhanced sends are not enabled"),
            },
            {
                "comment": "send from a standard P2PKH address to a P2WPKH address",
                "mock_protocol_changes": {"enhanced_sends": True, "segwit_support": True},
                "in": (
                    {
                        "source": ADDR[0],
                        "destination": P2WPKH_ADDR[0],
                        "asset": "XCP",
                        "quantity": 100000,
                        "memo": "segwit",
                        "use_enhanced_send": True,
                    }
                ),
                "out": (
                    "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc",
                    [],
                    b"\x00\x00\x00\x02\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x00\x01\x86\xa0\x80u\x1ev\xe8\x19\x91\x96\xd4T\x94\x1cE\xd1\xb3\xa3#\xf1C;\xd6segwit",
                ),
            },
            {
                "comment": "send to multiple addresses, before mpma_sends activation",
                "mock_protocol_changes": {
                    "enhanced_sends": True,
                    "options_require_memo": True,
                    "mpma_sends": False,
                },
                "in": (
                    {
                        "source": ADDR[0],
                        "destination": [ADDR[1], ADDR[2]],
                        "asset": ["XCP", "XCP"],
                        "quantity": [100000000, 100000000],
                        "memo": "12345",
                        "use_enhanced_send": True,
                    }
                ),
                "error": (exceptions.ComposeError, "mpma sends are not enabled"),
            },
        ],
        "parse": [
            {
                "in": (
                    {
                        "tx_hash": "db6d9052b576d973196363e11163d492f50926c2f1d1efd67b3d999817b0d04d",
                        "source": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc",
                        "supported": 1,
                        "block_index": DP["default_block_index"],
                        "fee": 10000,
                        "block_time": 155409000,
                        "block_hash": DP["default_block_hash"],
                        "btc_amount": 7800,
                        "data": b"\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x05\xf5\xe1\x00",
                        "tx_index": DP["default_tx_index"],
                        "destination": "mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns",
                    },
                ),
                "records": [
                    {
                        "table": "sends",
                        "values": {
                            "asset": "XCP",
                            "block_index": DP["default_block_index"],
                            "destination": "mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns",
                            "quantity": 100000000,
                            "source": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc",
                            "status": "valid",
                            "tx_hash": "db6d9052b576d973196363e11163d492f50926c2f1d1efd67b3d999817b0d04d",
                            "tx_index": DP["default_tx_index"],
                        },
                    },
                    {
                        "table": "credits",
                        "values": {
                            "address": "mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns",
                            "asset": "XCP",
                            "block_index": DP["default_block_index"],
                            "calling_function": "send",
                            "event": "db6d9052b576d973196363e11163d492f50926c2f1d1efd67b3d999817b0d04d",
                            "quantity": 100000000,
                        },
                    },
                    {
                        "table": "debits",
                        "values": {
                            "action": "send",
                            "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc",
                            "asset": "XCP",
                            "block_index": DP["default_block_index"],
                            "event": "db6d9052b576d973196363e11163d492f50926c2f1d1efd67b3d999817b0d04d",
                            "quantity": 100000000,
                        },
                    },
                ],
            },
            {
                "in": (
                    {
                        "tx_hash": "db6d9052b576d973196363e11163d492f50926c2f1d1efd67b3d999817b0d04d",
                        "block_hash": DP["default_block_hash"],
                        "btc_amount": 7800,
                        "block_index": DP["default_block_index"],
                        "destination": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc",
                        "data": b"\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x0b\xeb\xc2\x00",
                        "block_time": 155409000,
                        "fee": 10000,
                        "source": "mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH",
                        "tx_index": DP["default_tx_index"],
                        "supported": 1,
                    },
                ),
                "records": [
                    {
                        "table": "sends",
                        "values": {
                            "asset": "XCP",
                            "block_index": DP["default_block_index"],
                            "destination": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc",
                            "quantity": 0,
                            "source": "mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH",
                            "status": "valid",
                            "tx_hash": "db6d9052b576d973196363e11163d492f50926c2f1d1efd67b3d999817b0d04d",
                            "tx_index": DP["default_tx_index"],
                        },
                    }
                ],
            },
            {
                "in": (
                    {
                        "tx_index": DP["default_tx_index"],
                        "data": b"\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00X\xb1\x14\x00",
                        "source": "mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH",
                        "block_time": 310501000,
                        "block_hash": "46ac6d09237c7961199068fdd13f1508d755483e07c57a4c8f7ff18eb33a05c93ca6a86fa2e2af82fb77a5c337146bb37e279797a3d11970aec4693c46ea5a58",
                        "tx_hash": "736ecc18f9f41b3ccf67dded1252969e4929404d6ad657b2039b937a7785cf3e",
                        "supported": 1,
                        "destination": "mqPCfvqTfYctXMUfmniXeG2nyaN8w6tPmj",
                        "btc_amount": 5430,
                        "block_index": DP["default_block_index"],
                        "fee": 10000,
                    },
                ),
                "records": [
                    {
                        "table": "sends",
                        "values": {
                            "asset": "XCP",
                            "block_index": DP["default_block_index"],
                            "destination": "mqPCfvqTfYctXMUfmniXeG2nyaN8w6tPmj",
                            "quantity": 0,
                            "source": "mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH",
                            "status": "valid",
                            "tx_hash": "736ecc18f9f41b3ccf67dded1252969e4929404d6ad657b2039b937a7785cf3e",
                            "tx_index": DP["default_tx_index"],
                        },
                    }
                ],
            },
            {
                "in": (
                    {
                        "block_index": DP["default_block_index"],
                        "btc_amount": 7800,
                        "tx_hash": "db6d9052b576d973196363e11163d492f50926c2f1d1efd67b3d999817b0d04d",
                        "block_time": 155409000,
                        "fee": 10000,
                        "tx_index": DP["default_tx_index"],
                        "data": b"\x00\x00\x00\x00\x00\x06\xca\xd8\xdc\x7f\x0bf\x00\x00\x00\x00\x00\x00\x01\xf4",
                        "block_hash": DP["default_block_hash"],
                        "destination": "mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns",
                        "source": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc",
                        "supported": 1,
                    },
                ),
                "records": [
                    {
                        "table": "sends",
                        "values": {
                            "asset": "NODIVISIBLE",
                            "block_index": DP["default_block_index"],
                            "destination": "mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns",
                            "quantity": 500,
                            "source": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc",
                            "status": "valid",
                            "tx_hash": "db6d9052b576d973196363e11163d492f50926c2f1d1efd67b3d999817b0d04d",
                            "tx_index": DP["default_tx_index"],
                        },
                    },
                    {
                        "table": "credits",
                        "values": {
                            "address": "mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns",
                            "asset": "NODIVISIBLE",
                            "block_index": DP["default_block_index"],
                            "calling_function": "send",
                            "event": "db6d9052b576d973196363e11163d492f50926c2f1d1efd67b3d999817b0d04d",
                            "quantity": 500,
                        },
                    },
                    {
                        "table": "debits",
                        "values": {
                            "action": "send",
                            "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc",
                            "asset": "NODIVISIBLE",
                            "block_index": DP["default_block_index"],
                            "event": "db6d9052b576d973196363e11163d492f50926c2f1d1efd67b3d999817b0d04d",
                            "quantity": 500,
                        },
                    },
                ],
            },
            {
                "in": (
                    {
                        "btc_amount": 7800,
                        "block_hash": DP["default_block_hash"],
                        "fee": 10000,
                        "tx_index": DP["default_tx_index"],
                        "destination": "1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2",
                        "data": b"\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x05\xf5\xe1\x00",
                        "source": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc",
                        "tx_hash": "db6d9052b576d973196363e11163d492f50926c2f1d1efd67b3d999817b0d04d",
                        "supported": 1,
                        "block_time": 155409000,
                        "block_index": DP["default_block_index"],
                    },
                ),
                "records": [
                    {
                        "table": "sends",
                        "values": {
                            "asset": "XCP",
                            "block_index": DP["default_block_index"],
                            "destination": "1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2",
                            "quantity": 100000000,
                            "source": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc",
                            "status": "valid",
                            "tx_hash": "db6d9052b576d973196363e11163d492f50926c2f1d1efd67b3d999817b0d04d",
                            "tx_index": DP["default_tx_index"],
                        },
                    },
                    {
                        "table": "credits",
                        "values": {
                            "address": "1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2",
                            "asset": "XCP",
                            "block_index": DP["default_block_index"],
                            "calling_function": "send",
                            "event": "db6d9052b576d973196363e11163d492f50926c2f1d1efd67b3d999817b0d04d",
                            "quantity": 100000000,
                        },
                    },
                    {
                        "table": "debits",
                        "values": {
                            "action": "send",
                            "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc",
                            "asset": "XCP",
                            "block_index": DP["default_block_index"],
                            "event": "db6d9052b576d973196363e11163d492f50926c2f1d1efd67b3d999817b0d04d",
                            "quantity": 100000000,
                        },
                    },
                ],
            },
            {
                "in": (
                    {
                        "data": b"\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x05\xf5\xe1\x00",
                        "source": "1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2",
                        "tx_hash": "db6d9052b576d973196363e11163d492f50926c2f1d1efd67b3d999817b0d04d",
                        "supported": 1,
                        "block_time": 155409000,
                        "fee": 10000,
                        "tx_index": DP["default_tx_index"],
                        "btc_amount": 7800,
                        "block_hash": DP["default_block_hash"],
                        "block_index": DP["default_block_index"],
                        "destination": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc",
                    },
                ),
                "records": [
                    {
                        "table": "sends",
                        "values": {
                            "asset": "XCP",
                            "block_index": DP["default_block_index"],
                            "destination": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc",
                            "quantity": 100000000,
                            "source": "1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2",
                            "status": "valid",
                            "tx_hash": "db6d9052b576d973196363e11163d492f50926c2f1d1efd67b3d999817b0d04d",
                            "tx_index": DP["default_tx_index"],
                        },
                    },
                    {
                        "table": "credits",
                        "values": {
                            "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc",
                            "asset": "XCP",
                            "block_index": DP["default_block_index"],
                            "calling_function": "send",
                            "event": "db6d9052b576d973196363e11163d492f50926c2f1d1efd67b3d999817b0d04d",
                            "quantity": 100000000,
                        },
                    },
                    {
                        "table": "debits",
                        "values": {
                            "action": "send",
                            "address": "1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2",
                            "asset": "XCP",
                            "block_index": DP["default_block_index"],
                            "event": "db6d9052b576d973196363e11163d492f50926c2f1d1efd67b3d999817b0d04d",
                            "quantity": 100000000,
                        },
                    },
                ],
            },
            {
                "in": (
                    {
                        "source": "1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2",
                        "destination": "1_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2",
                        "supported": 1,
                        "block_time": 155409000,
                        "fee": 10000,
                        "block_index": DP["default_block_index"],
                        "tx_hash": "db6d9052b576d973196363e11163d492f50926c2f1d1efd67b3d999817b0d04d",
                        "btc_amount": 7800,
                        "data": b"\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x05\xf5\xe1\x00",
                        "tx_index": DP["default_tx_index"],
                        "block_hash": DP["default_block_hash"],
                    },
                ),
                "records": [
                    {
                        "table": "sends",
                        "values": {
                            "asset": "XCP",
                            "block_index": DP["default_block_index"],
                            "destination": "1_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2",
                            "quantity": 100000000,
                            "source": "1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2",
                            "status": "valid",
                            "tx_hash": "db6d9052b576d973196363e11163d492f50926c2f1d1efd67b3d999817b0d04d",
                            "tx_index": DP["default_tx_index"],
                        },
                    },
                    {
                        "table": "credits",
                        "values": {
                            "address": "1_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2",
                            "asset": "XCP",
                            "block_index": DP["default_block_index"],
                            "calling_function": "send",
                            "event": "db6d9052b576d973196363e11163d492f50926c2f1d1efd67b3d999817b0d04d",
                            "quantity": 100000000,
                        },
                    },
                    {
                        "table": "debits",
                        "values": {
                            "action": "send",
                            "address": "1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2",
                            "asset": "XCP",
                            "block_index": DP["default_block_index"],
                            "event": "db6d9052b576d973196363e11163d492f50926c2f1d1efd67b3d999817b0d04d",
                            "quantity": 100000000,
                        },
                    },
                ],
            },
            {
                "in": (
                    {
                        "block_index": DP["default_block_index"],
                        "block_time": 155409000,
                        "fee": 10000,
                        "tx_index": DP["default_tx_index"],
                        "tx_hash": "8fc698cf1fcd51e3d685511185c67c0a73e7b72954c6abbd29fbbbe560e043a0",
                        "btc_amount": 7800,
                        "data": b"\x00\x00\x00\x00\x00\x00\x00\x00\x00\x03:>\x7f\xff\xff\xff\xff\xff\xff\xff",
                        "source": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc",
                        "destination": "mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns",
                        "supported": 1,
                        "block_hash": DP["default_block_hash"],
                    },
                ),
                "records": [
                    {
                        "table": "sends",
                        "values": {
                            "asset": "MAXI",
                            "block_index": DP["default_block_index"],
                            "destination": "mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns",
                            "quantity": 9223372036854775807,
                            "source": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc",
                            "status": "valid",
                            "tx_hash": "8fc698cf1fcd51e3d685511185c67c0a73e7b72954c6abbd29fbbbe560e043a0",
                            "tx_index": DP["default_tx_index"],
                        },
                    },
                    {
                        "table": "credits",
                        "values": {
                            "address": "mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns",
                            "asset": "MAXI",
                            "block_index": DP["default_block_index"],
                            "calling_function": "send",
                            "event": "8fc698cf1fcd51e3d685511185c67c0a73e7b72954c6abbd29fbbbe560e043a0",
                            "quantity": 9223372036854775807,
                        },
                    },
                    {
                        "table": "debits",
                        "values": {
                            "action": "send",
                            "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc",
                            "asset": "MAXI",
                            "block_index": DP["default_block_index"],
                            "event": "8fc698cf1fcd51e3d685511185c67c0a73e7b72954c6abbd29fbbbe560e043a0",
                            "quantity": 9223372036854775807,
                        },
                    },
                ],
            },
            {
                "comment": "Reject a send without memo to a REQUIRE_MEMO address",
                "mock_protocol_changes": {"options_require_memo": True},
                "in": (
                    {
                        "block_index": DP["default_block_index"],
                        "block_time": 155409000,
                        "fee": 10000,
                        "tx_index": DP["default_tx_index"],
                        "tx_hash": "8fc698cf1fcd51e3d685511185c67c0a73e7b72954c6abbd29fbbbe560e043a0",
                        "btc_amount": 7800,
                        "data": b"\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x02\xfa\xf0\x80",
                        "source": ADDR[0],
                        "destination": ADDR[6],
                        "supported": 1,
                        "block_hash": DP["default_block_hash"],
                    },
                ),
                "records": [
                    {
                        "table": "sends",
                        "values": {
                            "asset": "XCP",
                            "block_index": DP["default_block_index"],
                            "destination": ADDR[6],
                            "quantity": 50000000,
                            "source": ADDR[0],
                            "status": "invalid: destination requires memo",
                            "tx_hash": "8fc698cf1fcd51e3d685511185c67c0a73e7b72954c6abbd29fbbbe560e043a0",
                            "tx_index": DP["default_tx_index"],
                        },
                    }
                ],
            },
        ],
    },
}
