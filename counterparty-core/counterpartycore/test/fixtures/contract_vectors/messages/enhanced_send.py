import binascii

from counterpartycore.lib import config, exceptions
from counterpartycore.test.fixtures.params import (
    ADDR,
    DP,
    MULTISIGADDR,
    P2SH_ADDR,
    P2WPKH_ADDR,
    SHORT_ADDR_BYTES,
)

ENHANCED_SEND_VECTOR = {
    "versions.enhanced_send": {
        "unpack": [
            {
                "in": (
                    binascii.unhexlify(
                        "000000000004fadf"
                        + "000000174876e800"
                        + "006474849fc9ac0f5bd6b49fe144d14db7d32e2445"
                    ),
                    DP["default_block_index"],
                ),
                "out": (
                    {
                        "asset": "SOUP",
                        "quantity": 100000000000,
                        "address": "1AAAA1111xxxxxxxxxxxxxxxxxxy43CZ9j",
                        "memo": None,
                    }
                ),
            },
            {
                "in": (
                    binascii.unhexlify(
                        "0000000000000001"
                        + "000000000000007b"
                        + "00647484b055e2101927e50aba74957ba134d501d7"
                        + "0deadbeef123"
                    ),
                    DP["default_block_index"],
                ),
                "out": (
                    {
                        "asset": "XCP",
                        "quantity": 123,
                        "address": "1AAAA2222xxxxxxxxxxxxxxxxxxy4pQ3tU",
                        "memo": binascii.unhexlify("0deadbeef123"),
                    }
                ),
            },
            {
                "in": (
                    binascii.unhexlify("0000000000000001" + "000000000000007b" + "0001"),
                    DP["default_block_index"],
                ),
                "error": (exceptions.UnpackError, "invalid message length"),
            },
            {
                "in": (
                    binascii.unhexlify(
                        "0000000000000001"
                        + "000000000000007b"
                        + "006474849fc9ac0f5bd6b49fe144d14db7d32e2445"
                        + "9999999999999999999999999999999999999999999999999999999999999999999999"
                    ),
                    DP["default_block_index"],
                ),
                "error": (exceptions.UnpackError, "memo too long"),
            },
            {
                "in": (
                    binascii.unhexlify(
                        "0000000000000000"
                        + "000000000000007b"
                        + "006474849fc9ac0f5bd6b49fe144d14db7d32e2445"
                    ),
                    DP["default_block_index"],
                ),
                "error": (exceptions.UnpackError, "asset id invalid"),
            },
            {
                "in": (
                    binascii.unhexlify(
                        "0000000000000003"
                        + "000000000000007b"
                        + "006474849fc9ac0f5bd6b49fe144d14db7d32e2445"
                    ),
                    DP["default_block_index"],
                ),
                "error": (exceptions.UnpackError, "asset id invalid"),
            },
            {
                "in": (
                    b"\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x00\x01\x86\xa0\x80u\x1ev\xe8\x19\x91\x96\xd4T\x94\x1cE\xd1\xb3\xa3#\xf1C;\xd6segwit",
                    DP["default_block_index"],
                ),
                "out": (
                    {
                        "address": P2WPKH_ADDR[0],
                        "asset": "XCP",
                        "quantity": 100000,
                        "memo": b"segwit",
                    }
                ),
            },
        ],
        "validate": [
            # ----- tests copied from regular send -----
            {"in": (ADDR[0], ADDR[1], "XCP", DP["quantity"], None, 1), "out": ([])},
            {"in": (ADDR[0], P2SH_ADDR[0], "XCP", DP["quantity"], None, 1), "out": ([])},
            {"in": (P2SH_ADDR[0], ADDR[1], "XCP", DP["quantity"], None, 1), "out": ([])},
            {
                "in": (ADDR[0], ADDR[1], "BTC", DP["quantity"], None, 1),
                "out": ([f"cannot send {config.BTC}"]),
            },
            {
                "in": (ADDR[0], ADDR[1], "XCP", DP["quantity"] / 3, None, 1),
                "out": (["quantity must be in satoshis"]),
            },
            {
                "in": (ADDR[0], ADDR[1], "XCP", -1 * DP["quantity"], None, 1),
                "out": (["negative quantity"]),
            },
            {"in": (ADDR[0], MULTISIGADDR[0], "XCP", DP["quantity"], None, 1), "out": ([])},
            {"in": (ADDR[0], ADDR[1], "MAXI", 2**63 - 1, None, 1), "out": ([])},
            {"in": (ADDR[0], ADDR[1], "MAXI", 2**63, None, 1), "out": (["integer overflow"])},
            {
                "in": (ADDR[0], ADDR[6], "XCP", DP["quantity"], None, 1),
                "out": (["destination requires memo"]),
            },
            {
                # ----- tests specific to enhanced send -----
                "in": (
                    "1AAAA1111xxxxxxxxxxxxxxxxxxy43CZ9j",
                    "1AAAA2222xxxxxxxxxxxxxxxxxxy4pQ3tU",
                    "SOUP",
                    100000000,
                    None,
                    DP["default_block_index"],
                ),
                "out": ([]),
            },
            {
                "in": (
                    "1AAAA1111xxxxxxxxxxxxxxxxxxy43CZ9j",
                    "1AAAA2222xxxxxxxxxxxxxxxxxxy4pQ3tU",
                    "SOUP",
                    100000000,
                    binascii.unhexlify("01ff"),
                    DP["default_block_index"],
                ),
                "out": ([]),
            },
            {
                "in": (
                    "1AAAA1111xxxxxxxxxxxxxxxxxxy43CZ9j",
                    "1AAAA2222xxxxxxxxxxxxxxxxxxy4pQ3tU",
                    "SOUP",
                    0,
                    binascii.unhexlify("01ff"),
                    DP["default_block_index"],
                ),
                "out": (["zero quantity"]),
            },
            {
                "in": (
                    "1AAAA1111xxxxxxxxxxxxxxxxxxy43CZ9j",
                    "",
                    "SOUP",
                    100000000,
                    binascii.unhexlify("01ff"),
                    DP["default_block_index"],
                ),
                "out": (["destination is required"]),
            },
            {
                "in": (
                    "1AAAA1111xxxxxxxxxxxxxxxxxxy43CZ9j",
                    "1AAAA2222xxxxxxxxxxxxxxxxxxy4pQ3tU",
                    "SOUP",
                    100000000,
                    binascii.unhexlify(
                        "9999999999999999999999999999999999999999999999999999999999999999999999"
                    ),
                    DP["default_block_index"],
                ),
                "out": (["memo is too long"]),
            },
        ],
        "compose": [
            # ----- tests copied from regular send -----
            {
                "in": (ADDR[0], ADDR[1], "XCP", DP["quantity"] * 10000000, None, False),
                "error": (exceptions.ComposeError, "insufficient funds"),
            },
            {
                "in": (ADDR[0], ADDR[1], "XCP", DP["quantity"] / 3, None, False),
                "error": (exceptions.ComposeError, "quantity must be an int (in satoshi)"),
            },
            {
                "in": (ADDR[0], ADDR[1], "MAXI", 2**63 + 1, None, False),
                "error": (exceptions.ComposeError, "insufficient funds"),
            },
            {
                "in": (ADDR[0], ADDR[1], "BTC", DP["quantity"], None, False),
                "out": (
                    "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc",
                    [("mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns", 100000000)],
                    None,
                ),
            },
            {
                "in": (ADDR[0], P2SH_ADDR[0], "BTC", DP["quantity"], None, False),
                "out": (
                    "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc",
                    [("2MyJHMUenMWonC35Yi6PHC7i2tkS7PuomCy", 100000000)],
                    None,
                ),
            },
            {
                "comment": "resolve subasset to numeric asset",
                "mock_protocol_changes": {"short_tx_type_id": True},
                "in": (ADDR[0], ADDR[1], "PARENT.already.issued", 100000000, None, False),
                "out": (
                    "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc",
                    [],
                    binascii.unhexlify(
                        "02"
                        + "01530821671b1065"
                        + "0000000005f5e100"
                        + "6f8d6ae8a3b381663118b4e1eff4cfc7d0954dd6ec"
                    ),
                ),
            },
            # ----- tests specific to enhanced send -----
            {
                "mock_protocol_changes": {"short_tx_type_id": True},
                "in": (ADDR[1], ADDR[0], "XCP", DP["small"], None, None),
                "out": (
                    ADDR[1],
                    [],
                    binascii.unhexlify(
                        "02"
                        + "0000000000000001"
                        + "0000000002faf080"
                        + "6f4838d8b3588c4c7ba7c1d06f866e9b3739c63037"
                    ),
                ),
            },
            {
                # memo as hex
                "mock_protocol_changes": {"short_tx_type_id": True},
                "in": (ADDR[1], ADDR[0], "XCP", DP["small"], "12345abcde", True),
                "out": (
                    ADDR[1],
                    [],
                    binascii.unhexlify(
                        "02"
                        + "0000000000000001"
                        + "0000000002faf080"
                        + "6f4838d8b3588c4c7ba7c1d06f866e9b3739c63037"
                        + "12345abcde"
                    ),
                ),
            },
            {
                # pack a string into bytes
                "mock_protocol_changes": {"short_tx_type_id": True},
                "in": (ADDR[1], ADDR[0], "XCP", DP["small"], "hello", False),
                "out": (
                    ADDR[1],
                    [],
                    binascii.unhexlify(
                        "02"
                        + "0000000000000001"
                        + "0000000002faf080"
                        + "6f4838d8b3588c4c7ba7c1d06f866e9b3739c63037"
                        + "68656c6c6f"
                    ),
                ),
            },
            {
                # memo too long
                "mock_protocol_changes": {"short_tx_type_id": True},
                "in": (
                    ADDR[1],
                    ADDR[0],
                    "XCP",
                    DP["small"],
                    "12345678901234567890123456789012345",
                    False,
                ),
                "error": (exceptions.ComposeError, ["memo is too long"]),
            },
            {
                "comment": "enhanced_send to a REQUIRE_MEMO address, without memo",
                "in": (ADDR[0], ADDR[6], "XCP", DP["small"], None, False),
                "error": (exceptions.ComposeError, ["destination requires memo"]),
            },
            {
                "comment": "enhanced_send to a REQUIRE_MEMO address, with memo text",
                "in": (ADDR[0], ADDR[6], "XCP", DP["small"], "12345", False),
                "out": (
                    "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc",
                    [],
                    b'\x00\x00\x00\x02\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x02\xfa\xf0\x80o\xb3\x90\x18~\xf2\x85D"\xac^J.\xb6\xff\xe9$\x96\xbe\xf5#12345',
                ),
            },
            {
                "comment": "enhanced_send to a REQUIRE_MEMO address, with memo hex",
                "in": (ADDR[0], ADDR[6], "XCP", DP["small"], "deadbeef", True),
                "out": (
                    "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc",
                    [],
                    b'\x00\x00\x00\x02\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x02\xfa\xf0\x80o\xb3\x90\x18~\xf2\x85D"\xac^J.\xb6\xff\xe9$\x96\xbe\xf5#\xde\xad\xbe\xef',
                ),
            },
            {
                "comment": "send from a P2WPKH address to a P2PKH one",
                "in": (P2WPKH_ADDR[0], ADDR[0], "XCP", DP["small"], None, False),
                "out": (
                    P2WPKH_ADDR[0],
                    [],
                    b"\x00\x00\x00\x02\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x02\xfa\xf0\x80oH8\xd8\xb3X\x8cL{\xa7\xc1\xd0o\x86n\x9b79\xc607",
                ),
            },
        ],
        "parse": [
            # ----- tests copied from regular send -----
            {
                "mock_protocol_changes": {"short_tx_type_id": True},
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
                        "data": binascii.unhexlify(
                            "00000002"
                            + "0000000000000001"
                            + "0000000005f5e100"
                            + SHORT_ADDR_BYTES[1]
                        ),
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
                            "memo": None,
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
                "comment": "zero quantity send",
                "in": (
                    {
                        "tx_hash": "db6d9052b576d973196363e11163d492f50926c2f1d1efd67b3d999817b0d04d",
                        "block_hash": DP["default_block_hash"],
                        "btc_amount": 7800,
                        "block_index": DP["default_block_index"],
                        "destination": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc",
                        "data": binascii.unhexlify(
                            "00000002"
                            + "0000000000000001"
                            + "0000000000000000"
                            + SHORT_ADDR_BYTES[0]
                        ),
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
                            "status": "invalid: zero quantity",
                            "tx_hash": "db6d9052b576d973196363e11163d492f50926c2f1d1efd67b3d999817b0d04d",
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
                        "data": binascii.unhexlify(
                            "00000002"
                            + "0006cad8dc7f0b66"
                            + "00000000000001f4"
                            + SHORT_ADDR_BYTES[1]
                        ),
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
                        "data": binascii.unhexlify(
                            "00000002"
                            + "0000000000000001"
                            + "0000000005f5e100"
                            + SHORT_ADDR_BYTES[0]
                        ),
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
                        "block_index": DP["default_block_index"],
                        "block_time": 155409000,
                        "fee": 10000,
                        "tx_index": DP["default_tx_index"],
                        "tx_hash": "8fc698cf1fcd51e3d685511185c67c0a73e7b72954c6abbd29fbbbe560e043a0",
                        "btc_amount": 7800,
                        "data": binascii.unhexlify(
                            "00000002"
                            + "0000000000033a3e"
                            + "7fffffffffffffff"
                            + SHORT_ADDR_BYTES[1]
                        ),
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
            # ----- tests specific to enhanced send -----
            {
                "comment": "instead of auto-correcting the quantity to the amount the address holds return invalid: insufficient funds",
                "in": (
                    {
                        "tx_index": DP["default_tx_index"],
                        "data": binascii.unhexlify(
                            "00000002"
                            + "0000000000000001"
                            + "0000000058b11400"
                            + SHORT_ADDR_BYTES[3]
                        ),
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
                            "quantity": 1488000000,
                            "source": "mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH",
                            "status": "invalid: insufficient funds",
                            "tx_hash": "736ecc18f9f41b3ccf67dded1252969e4929404d6ad657b2039b937a7785cf3e",
                            "tx_index": DP["default_tx_index"],
                        },
                    }
                ],
            },
            {
                "mock_protocol_changes": {"short_tx_type_id": True},
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
                        "data": binascii.unhexlify(
                            "00000002"
                            + "0000000000000001"
                            + "0000000005f5e100"
                            + SHORT_ADDR_BYTES[1]
                            + "beefbeef"
                        ),
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
                            "memo": binascii.unhexlify("beefbeef"),
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
                # invalid memo (too long)
                "mock_protocol_changes": {"short_tx_type_id": True},
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
                        "data": binascii.unhexlify(
                            "00000002"
                            + "0000000000000001"
                            + "0000000005f5e100"
                            + SHORT_ADDR_BYTES[1]
                            + "9999999999999999999999999999999999999999999999999999999999999999999999"
                        ),
                        "tx_index": DP["default_tx_index"],
                        "destination": "mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns",
                    },
                ),
                "records": [
                    {
                        "table": "sends",
                        "values": {
                            "asset": None,
                            "block_index": DP["default_block_index"],
                            "destination": None,
                            "quantity": None,
                            "source": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc",
                            "status": "invalid: could not unpack (memo too long)",
                            "tx_hash": "db6d9052b576d973196363e11163d492f50926c2f1d1efd67b3d999817b0d04d",
                            "tx_index": DP["default_tx_index"],
                            "memo": None,
                        },
                    }
                ],
            },
            {
                # invalid: quantity (too large)
                "mock_protocol_changes": {"short_tx_type_id": True},
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
                        "data": binascii.unhexlify(
                            "00000002"
                            + "0000000000000001"
                            + "ffffffffffffffff"
                            + SHORT_ADDR_BYTES[1]
                            + "beefbeef"
                        ),
                        "tx_index": DP["default_tx_index"],
                        "destination": "mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns",
                    },
                ),
                "records": [
                    {
                        "table": "sends",
                        "values": {
                            "asset": None,
                            "block_index": DP["default_block_index"],
                            "destination": None,
                            "quantity": None,
                            "source": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc",
                            "status": "invalid: quantity is too large",
                            "tx_hash": "db6d9052b576d973196363e11163d492f50926c2f1d1efd67b3d999817b0d04d",
                            "tx_index": DP["default_tx_index"],
                            "memo": None,
                        },
                    }
                ],
            },
            {
                "comment": "Send a valid enhanced_send to destination address with REQUIRE_MEMO",
                "in": (
                    {
                        "block_index": DP["default_block_index"],
                        "block_time": 155409000,
                        "fee": 10000,
                        "tx_index": DP["default_tx_index"],
                        "tx_hash": "8fc698cf1fcd51e3d685511185c67c0a73e7b72954c6abbd29fbbbe560e043a0",
                        "btc_amount": 7800,
                        "data": b'\x00\x00\x00\x02\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x02\xfa\xf0\x80o\xb3\x90\x18~\xf2\x85D"\xac^J.\xb6\xff\xe9$\x96\xbe\xf5#12345',
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
                            "quantity": DP["small"],
                            "source": ADDR[0],
                            "status": "valid",
                            "tx_hash": "8fc698cf1fcd51e3d685511185c67c0a73e7b72954c6abbd29fbbbe560e043a0",
                            "tx_index": DP["default_tx_index"],
                        },
                    },
                    {
                        "table": "credits",
                        "values": {
                            "address": ADDR[6],
                            "asset": "XCP",
                            "block_index": DP["default_block_index"],
                            "calling_function": "send",
                            "event": "8fc698cf1fcd51e3d685511185c67c0a73e7b72954c6abbd29fbbbe560e043a0",
                            "quantity": DP["small"],
                        },
                    },
                    {
                        "table": "debits",
                        "values": {
                            "action": "send",
                            "address": ADDR[0],
                            "asset": "XCP",
                            "block_index": DP["default_block_index"],
                            "event": "8fc698cf1fcd51e3d685511185c67c0a73e7b72954c6abbd29fbbbe560e043a0",
                            "quantity": DP["small"],
                        },
                    },
                ],
            },
            {
                "comment": "Parse a send from a P2PKH address to a P2WPKH one",
                "mock_protocol_changes": {"enhanced_sends": True, "segwit_support": True},
                "in": (
                    {
                        "block_index": DP["default_block_index"],
                        "block_time": 155409000,
                        "fee": 10000,
                        "tx_index": DP["default_tx_index"],
                        "tx_hash": "8fc698cf1fcd51e3d685511185c67c0a73e7b72954c6abbd29fbbbe560e043a0",
                        "btc_amount": 7800,
                        "data": b"\x00\x00\x00\x02\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x00\x01\x86\xa0\x80u\x1ev\xe8\x19\x91\x96\xd4T\x94\x1cE\xd1\xb3\xa3#\xf1C;\xd6segwit",
                        "source": ADDR[0],
                        "destination": P2WPKH_ADDR[0],
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
                            "destination": P2WPKH_ADDR[0],
                            "quantity": 100000,
                            "source": ADDR[0],
                            "status": "valid",
                            "tx_hash": "8fc698cf1fcd51e3d685511185c67c0a73e7b72954c6abbd29fbbbe560e043a0",
                            "tx_index": DP["default_tx_index"],
                        },
                    }
                ],
            },
        ],
    },
}
