import binascii

from counterpartycore.lib import config, exceptions
from counterpartycore.test.fixtures.params import ADDR, DP

MPMA_VECTOR = {
    "versions.mpma": {
        "unpack": [
            {
                "comment": "Should throw on empty data",
                "in": (binascii.unhexlify(""), DP["default_block_index"]),
                "error": (exceptions.UnpackError, "could not unpack"),
            },
            {
                "comment": "0 addresses in a send is an error",
                "in": (binascii.unhexlify("0000"), DP["default_block_index"]),
                "error": (exceptions.DecodeError, "address list can't be empty"),
            },
            {
                "comment": "Should throw on incomplete data",
                "in": (binascii.unhexlify("0001ffff"), DP["default_block_index"]),
                "error": (exceptions.UnpackError, "truncated data"),
            },
            {
                "in": (
                    binascii.unhexlify(
                        "00026f4e5638a01efbb2f292481797ae1dcfcdaeb98d006f8d6ae8a3b381663118b4e1eff4cfc7d0954dd6ec400000000000000060000000005f5e10040000000017d78400"
                    ),
                    DP["default_block_index"],
                ),
                "out": ({"XCP": [(ADDR[2], DP["quantity"]), (ADDR[1], DP["quantity"])]}),
            },
            {
                "in": (
                    binascii.unhexlify(
                        "00026f4e5638a01efbb2f292481797ae1dcfcdaeb98d006f8d6ae8a3b381663118b4e1eff4cfc7d0954dd6ec400000000000000060000000005f5e100c4deadbeef8000000002faf0800"
                    ),
                    DP["default_block_index"],
                ),
                "out": (
                    {
                        "XCP": [
                            (ADDR[2], DP["quantity"], binascii.unhexlify("DEADBEEF"), True),
                            (ADDR[1], DP["quantity"]),
                        ]
                    }
                ),
            },
            {
                "in": (
                    binascii.unhexlify(
                        "00026f4e5638a01efbb2f292481797ae1dcfcdaeb98d006f8d6ae8a3b381663118b4e1eff4cfc7d0954dd6ec400000000000000060000000005f5e1008844454144424545468000000002faf0800"
                    ),
                    DP["default_block_index"],
                ),
                "out": (
                    {
                        "XCP": [
                            (ADDR[2], DP["quantity"], "DEADBEEF", False),
                            (ADDR[1], DP["quantity"]),
                        ]
                    }
                ),
            },
            {
                "in": (
                    binascii.unhexlify(
                        "00036f4e5638a01efbb2f292481797ae1dcfcdaeb98d006f6c39ee7c8f3a5ffa6121b0304a7a0de9d3d9a1526f8d6ae8a3b381663118b4e1eff4cfc7d0954dd6ec4000000000000000640000000017d784000000000002faf08020000000005f5e1000"
                    ),
                    DP["default_block_index"],
                ),
                "out": (
                    {
                        "XCP": [
                            (ADDR[3], DP["quantity"]),
                            (ADDR[2], DP["quantity"]),
                            (ADDR[1], DP["quantity"]),
                        ]
                    }
                ),
            },
            {
                "in": (
                    binascii.unhexlify(
                        "00036f4e5638a01efbb2f292481797ae1dcfcdaeb98d006f6c39ee7c8f3a5ffa6121b0304a7a0de9d3d9a1526f8d6ae8a3b381663118b4e1eff4cfc7d0954dd6ec4000002896f8d2d9800000000017d784010006cad8dc7f0b66200000000000000014000000000000000440000000017d784000"
                    ),
                    DP["default_block_index"],
                ),
                "out": (
                    {
                        "XCP": [(ADDR[3], DP["quantity"])],
                        "NODIVISIBLE": [(ADDR[1], 1)],
                        "DIVISIBLE": [(ADDR[2], DP["quantity"])],
                    }
                ),
            },
            {
                "in": (
                    binascii.unhexlify(
                        "00026f4e5638a01efbb2f292481797ae1dcfcdaeb98d006f8d6ae8a3b381663118b4e1eff4cfc7d0954dd6ecc4deadbeef8000000000000000c000000000bebc2008000000002faf0800"
                    ),
                    DP["default_block_index"],
                ),
                "out": (
                    {
                        "XCP": [
                            (ADDR[2], DP["quantity"], binascii.unhexlify("DEADBEEF"), True),
                            (ADDR[1], DP["quantity"], binascii.unhexlify("DEADBEEF"), True),
                        ]
                    }
                ),
            },
            {
                "in": (
                    binascii.unhexlify(
                        "00026f4e5638a01efbb2f292481797ae1dcfcdaeb98d006f8d6ae8a3b381663118b4e1eff4cfc7d0954dd6ecc4deadbeef8000000000000000c000000000bebc201897ddfbd5b0000000005f5e1000"
                    ),
                    DP["default_block_index"],
                ),
                "out": (
                    {
                        "XCP": [
                            (ADDR[2], DP["quantity"], binascii.unhexlify("BEEFDEAD"), True),
                            (ADDR[1], DP["quantity"], binascii.unhexlify("DEADBEEF"), True),
                        ]
                    }
                ),
            },
            {
                "in": (
                    binascii.unhexlify(
                        "00026f4e5638a01efbb2f292481797ae1dcfcdaeb98d006f8d6ae8a3b381663118b4e1eff4cfc7d0954dd6ec4000002896f8d2d990000000005f5e100400000000000000040000000005f5e100000300026f4e5638a01efbb2f292481797ae1dcfcdaeb98d006f8d6ae8a3b381663118b4e1eff4cfc7d0954dd6ec4000002896f8d2d990000000005f5e100400000000000000040000000005f5e10000"
                    ),
                    DP["default_block_index"],
                ),
                "out": (
                    {
                        "DIVISIBLE": [(ADDR[1], DP["quantity"])],
                        "XCP": [(ADDR[2], DP["quantity"])],
                    }
                ),
            },
            {
                # Test derived from block 618232 on BTC mainnet
                "in": (
                    binascii.unhexlify(
                        "0004002e9943921a473dee1e04a579c1762ff6e9ac34e4006c7beeb1af092be778a2c0b8df639f2f8e9c987600a9055398b92818794b38b15794096f752167e25f00f3a6b6e4a093e5a5b9da76977a5270fd4d62553e40000091f59f36daf0000000271d94900180000004e3b29200200000009c76524002000000138eca4800806203d0c908232420000000000000000b000000000000000140024a67f0f279952000000000000000058000000000000000a00000000000000014000000908a3200cb000000000000000058000000000000000a000000000000000120000000000000002075410426156245525daa71f2e84a40797bcf28099a2c508662a8a33324a703597b9aa2661a79a82ffb4caaa9b15f4094622fbfa85f8b9dc7381f991f5a265421391cc3ad0075740087"
                    ),
                    DP["default_block_index"],
                ),
                "out": (
                    {
                        "MAFIACASH": [
                            ("15FPgnpZuNyZLVLsyB6UdFicsVvWFJXNve", 42000000000),
                            ("1PDJv8u8zw4Fgqr4uCb2yim9fgTs5zfM4s", 42000000000),
                            ("1GQhaWqejcGJ4GhQar7SjcCfadxvf5DNBD", 42000000000),
                            ("1AtcSh7uxenQ6AR5xqr6agAegWRUF5N4uh", 42000000000),
                        ],
                        "PAWNTHELAMBO": [
                            ("15FPgnpZuNyZLVLsyB6UdFicsVvWFJXNve", 1),
                            ("1PDJv8u8zw4Fgqr4uCb2yim9fgTs5zfM4s", 1),
                        ],
                        "SHADILOUNGE": [
                            ("15FPgnpZuNyZLVLsyB6UdFicsVvWFJXNve", 1),
                            ("1PDJv8u8zw4Fgqr4uCb2yim9fgTs5zfM4s", 1),
                            ("1GQhaWqejcGJ4GhQar7SjcCfadxvf5DNBD", 1),
                        ],
                        "TIKIPEPE": [
                            ("15FPgnpZuNyZLVLsyB6UdFicsVvWFJXNve", 1),
                            ("1PDJv8u8zw4Fgqr4uCb2yim9fgTs5zfM4s", 1),
                            ("1GQhaWqejcGJ4GhQar7SjcCfadxvf5DNBD", 1),
                            ("1AtcSh7uxenQ6AR5xqr6agAegWRUF5N4uh", 1),
                        ],
                    }
                ),
            },
            {
                # Test derived from block 647547 on BTC mainnet
                "in": (
                    binascii.unhexlify(
                        "00010042276049e5518791be2ffe2c301f5dfe9ef85dd0400001720034b0410000000000000001500000006a79811e000000000000000054000079cec1665f4800000000000000050000000ca91f2d660000000000000005402736c8de6e34d54000000000000001500c5e4c71e081ceb00000000000000054000000045dc03ec4000000000000000500004af1271cf5fc00000000000000054001e71f8464432780000000000000015000002e1e4191f0d0000000000000005400012bc4aaac2a54000000000000001500079c7e774e411c00000000000000054000000045dc0a6f00000000000000015000002e1e486f661000000000000000540001c807abe13908000000000000000475410426156245525daa71f2e84a40797bcf28099a2c508662a8a33324a703597b9aa2661a79a82ffb4caaa9b15f4094622fbfa85f8b9dc7381f991f5a265421391cc3ad0075740087"
                    ),
                    DP["default_block_index"],
                ),
                "out": (
                    {
                        "BELLAMAFIA": [("172nmZbxDR6erc5PqNqV28fnMj7g6besru", 5)],
                        "DONPABLO": [("172nmZbxDR6erc5PqNqV28fnMj7g6besru", 5)],
                        "GEISHAPEPE": [("172nmZbxDR6erc5PqNqV28fnMj7g6besru", 1)],
                        "GUARDDOG": [("172nmZbxDR6erc5PqNqV28fnMj7g6besru", 5)],
                        "MATRYOSHKAPP": [("172nmZbxDR6erc5PqNqV28fnMj7g6besru", 5)],
                        "PEPEACIDTRIP": [("172nmZbxDR6erc5PqNqV28fnMj7g6besru", 5)],
                        "PEPEAIR": [("172nmZbxDR6erc5PqNqV28fnMj7g6besru", 1)],
                        "PEPECIGARS": [("172nmZbxDR6erc5PqNqV28fnMj7g6besru", 5)],
                        "PEPEDRACULA": [("172nmZbxDR6erc5PqNqV28fnMj7g6besru", 5)],
                        "PEPEHEMAN": [("172nmZbxDR6erc5PqNqV28fnMj7g6besru", 5)],
                        "PEPEHITMAN": [("172nmZbxDR6erc5PqNqV28fnMj7g6besru", 5)],
                        "PEPEJERICHO": [("172nmZbxDR6erc5PqNqV28fnMj7g6besru", 5)],
                        "PEPEKFC": [("172nmZbxDR6erc5PqNqV28fnMj7g6besru", 5)],
                        "PEPEWYATT": [("172nmZbxDR6erc5PqNqV28fnMj7g6besru", 5)],
                        "XCHAINPEPE": [("172nmZbxDR6erc5PqNqV28fnMj7g6besru", 1)],
                    }
                ),
            },
        ],
        "validate": [
            {"in": (ADDR[0], [], 1), "out": (["send list cannot be empty"])},
            {
                "in": (ADDR[0], [("XCP", ADDR[1], DP["quantity"])], 1),
                "out": (["send list cannot have only one element"]),
            },
            {
                "in": (ADDR[0], [("XCP", ADDR[2], DP["quantity"]), ("XCP", ADDR[1], 0.1)], 1),
                "out": ([f"quantities must be an int (in satoshis) for XCP to {ADDR[1]}"]),
            },
            {
                "in": (
                    ADDR[0],
                    [("XCP", ADDR[2], DP["quantity"]), ("XCP", ADDR[1], -DP["quantity"])],
                    1,
                ),
                "out": ([f"negative quantity for XCP to {ADDR[1]}"]),
            },
            {
                "in": (ADDR[0], [("XCP", ADDR[2], DP["quantity"]), ("XCP", ADDR[1], 0)], 1),
                "out": ([f"zero quantity for XCP to {ADDR[1]}"]),
            },
            {
                "in": (
                    ADDR[0],
                    [("XCP", ADDR[2], DP["quantity"]), ("XCP", ADDR[1], config.MAX_INT + 1)],
                    1,
                ),
                "out": ([f"integer overflow for XCP to {ADDR[1]}"]),
            },
            {
                "in": (
                    ADDR[0],
                    [("XCP", ADDR[2], DP["quantity"]), ("XCP", None, DP["quantity"])],
                    1,
                ),
                "out": (["destination is required for XCP"]),
            },
            {
                "in": (
                    ADDR[0],
                    [("XCP", ADDR[2], DP["quantity"]), ("BTC", ADDR[1], DP["quantity"])],
                    1,
                ),
                "out": ([f"cannot send BTC to {ADDR[1]}"]),
            },
            {
                "in": (
                    ADDR[0],
                    [("XCP", ADDR[2], DP["quantity"]), ("XCP", ADDR[6], DP["quantity"])],
                    1,
                ),
                "out": ([f"destination {ADDR[6]} requires memo"]),
            },
            {
                "in": (
                    ADDR[0],
                    [("XCP", ADDR[2], DP["quantity"]), ("XCP", ADDR[1], DP["quantity"])],
                    1,
                ),
                "out": ([]),
            },
            {
                "in": (
                    ADDR[0],
                    [("XCP", ADDR[2], DP["quantity"]), ("XCP", ADDR[2], DP["quantity"] + 1)],
                    1,
                ),
                "out": (["cannot specify more than once a destination per asset"]),
            },
            {
                "in": (
                    ADDR[0],
                    [
                        ("XCP", ADDR[2], DP["quantity"]),
                        ("XCP", ADDR[6], DP["quantity"], "DEADBEEF", True),
                    ],
                    1,
                ),
                "out": ([]),
            },
        ],
        "compose": [
            {
                "in": (ADDR[0], [("XCP", ADDR[1], DP["quantity"] * 1000000)], None, None),
                "error": (exceptions.ComposeError, "insufficient funds for XCP"),
            },
            {
                "in": (
                    ADDR[0],
                    [("XCP", ADDR[2], DP["quantity"]), ("XCP", ADDR[1], 0.1)],
                    None,
                    None,
                ),
                "error": (
                    exceptions.ComposeError,
                    "quantities must be an int (in satoshis) for XCP",
                ),
            },
            {
                "in": (
                    ADDR[0],
                    [
                        ("XCP", ADDR[2], DP["quantity"]),
                        ("XCP", ADDR[1], DP["quantity"] * 10000),
                    ],
                    None,
                    None,
                ),
                "error": (exceptions.ComposeError, "insufficient funds for XCP"),
            },
            {
                "in": (
                    ADDR[0],
                    [("XCP", ADDR[2], DP["quantity"]), ("XCP", ADDR[1], DP["quantity"])],
                    None,
                    None,
                ),
                "mock_protocol_changes": {"short_tx_type_id": True},
                "out": (
                    ADDR[0],
                    [],
                    binascii.unhexlify(
                        "0300026f4e5638a01efbb2f292481797ae1dcfcdaeb98d006f8d6ae8a3b381663118b4e1eff4cfc7d0954dd6ec400000000000000060000000005f5e10040000000017d78400"
                    ),
                ),
            },
            {
                "in": (
                    ADDR[0],
                    [
                        ("XCP", ADDR[2], DP["quantity"], "DEADBEEF", True),
                        ("XCP", ADDR[1], DP["quantity"]),
                    ],
                    None,
                    None,
                ),
                "mock_protocol_changes": {"short_tx_type_id": True},
                "out": (
                    ADDR[0],
                    [],
                    binascii.unhexlify(
                        "0300026f4e5638a01efbb2f292481797ae1dcfcdaeb98d006f8d6ae8a3b381663118b4e1eff4cfc7d0954dd6ec400000000000000060000000005f5e100c4deadbeef8000000002faf0800"
                    ),
                ),
            },
            {
                "in": (
                    ADDR[0],
                    [
                        ("XCP", ADDR[2], DP["quantity"], "DEADBEEF", False),
                        ("XCP", ADDR[1], DP["quantity"]),
                    ],
                    None,
                    None,
                ),
                "mock_protocol_changes": {"short_tx_type_id": True},
                "out": (
                    ADDR[0],
                    [],
                    binascii.unhexlify(
                        "0300026f4e5638a01efbb2f292481797ae1dcfcdaeb98d006f8d6ae8a3b381663118b4e1eff4cfc7d0954dd6ec400000000000000060000000005f5e1008844454144424545468000000002faf0800"
                    ),
                ),
            },
            {
                "in": (
                    ADDR[0],
                    [
                        ("XCP", ADDR[3], DP["quantity"]),
                        ("XCP", ADDR[2], DP["quantity"]),
                        ("XCP", ADDR[1], DP["quantity"]),
                    ],
                    None,
                    None,
                ),
                "mock_protocol_changes": {"short_tx_type_id": True},
                "out": (
                    ADDR[0],
                    [],
                    binascii.unhexlify(
                        "0300036f4e5638a01efbb2f292481797ae1dcfcdaeb98d006f6c39ee7c8f3a5ffa6121b0304a7a0de9d3d9a1526f8d6ae8a3b381663118b4e1eff4cfc7d0954dd6ec4000000000000000640000000017d784000000000002faf08020000000005f5e1000"
                    ),
                ),
            },
            {
                "in": (
                    ADDR[0],
                    [
                        ("XCP", ADDR[3], DP["quantity"]),
                        ("DIVISIBLE", ADDR[2], DP["quantity"]),
                        ("NODIVISIBLE", ADDR[1], 1),
                    ],
                    None,
                    None,
                ),
                "mock_protocol_changes": {"short_tx_type_id": True},
                "out": (
                    ADDR[0],
                    [],
                    binascii.unhexlify(
                        "0300036f4e5638a01efbb2f292481797ae1dcfcdaeb98d006f6c39ee7c8f3a5ffa6121b0304a7a0de9d3d9a1526f8d6ae8a3b381663118b4e1eff4cfc7d0954dd6ec4000002896f8d2d9800000000017d784010006cad8dc7f0b66200000000000000014000000000000000440000000017d784000"
                    ),
                ),
            },
            {
                "in": (
                    ADDR[0],
                    [("XCP", ADDR[2], DP["quantity"]), ("XCP", ADDR[1], DP["quantity"])],
                    "DEADBEEF",
                    True,
                ),
                "mock_protocol_changes": {"short_tx_type_id": True},
                "out": (
                    ADDR[0],
                    [],
                    binascii.unhexlify(
                        "0300026f4e5638a01efbb2f292481797ae1dcfcdaeb98d006f8d6ae8a3b381663118b4e1eff4cfc7d0954dd6ecc4deadbeef8000000000000000c000000000bebc2008000000002faf0800"
                    ),
                ),
            },
            {
                "in": (
                    ADDR[0],
                    [("XCP", ADDR[2], DP["quantity"]), ("XCP", ADDR[1], DP["quantity"])],
                    "DEADBEEF",
                    False,
                ),
                "mock_protocol_changes": {"short_tx_type_id": True},
                "out": (
                    ADDR[0],
                    [],
                    binascii.unhexlify(
                        "0300026f4e5638a01efbb2f292481797ae1dcfcdaeb98d006f8d6ae8a3b381663118b4e1eff4cfc7d0954dd6ec8844454144424545468000000000000000c000000000bebc2008000000002faf0800"
                    ),
                ),
            },
            {
                "in": (
                    ADDR[0],
                    [
                        ("XCP", ADDR[2], DP["quantity"], "BEEFDEAD", True),
                        ("XCP", ADDR[1], DP["quantity"]),
                    ],
                    "DEADBEEF",
                    True,
                ),
                "mock_protocol_changes": {"short_tx_type_id": True},
                "out": (
                    ADDR[0],
                    [],
                    binascii.unhexlify(
                        "0300026f4e5638a01efbb2f292481797ae1dcfcdaeb98d006f8d6ae8a3b381663118b4e1eff4cfc7d0954dd6ecc4deadbeef8000000000000000c000000000bebc201897ddfbd5b0000000005f5e1000"
                    ),
                ),
            },
            {
                "in": (
                    ADDR[0],
                    [("XCP", ADDR[2], DP["quantity"]), ("DIVISIBLE", ADDR[1], DP["quantity"])],
                    None,
                    None,
                ),
                "mock_protocol_changes": {"short_tx_type_id": True},
                "out": (
                    ADDR[0],
                    [],
                    binascii.unhexlify(
                        "0300026f4e5638a01efbb2f292481797ae1dcfcdaeb98d006f8d6ae8a3b381663118b4e1eff4cfc7d0954dd6ec4000002896f8d2d990000000005f5e100400000000000000040000000005f5e10000"
                    ),
                ),
            },
            {
                "in": (ADDR[0], [("XCP", ADDR[1], DP["quantity"])], ["memo1"], None),
                "error": (exceptions.ComposeError, "`memo` must be a string"),
            },
            {
                "in": (ADDR[0], [("XCP", ADDR[1], DP["quantity"])], "memo1", "nobool"),
                "error": (exceptions.ComposeError, "`memo_is_hex` must be a boolean"),
            },
        ],
        "parse": [
            {
                "in": (
                    {
                        "tx_hash": "db6d9052b576d973196363e11163d492f50926c2f1d1efd67b3d999817b0d04d",
                        "source": ADDR[0],
                        "supported": 1,
                        "block_index": DP["default_block_index"],
                        "fee": 10000,
                        "block_time": 155409000,
                        "block_hash": DP["default_block_hash"],
                        "btc_amount": 7800,
                        "data": binascii.unhexlify("00000000")
                        + binascii.unhexlify(
                            "00026f4e5638a01efbb2f292481797ae1dcfcdaeb98d006f8d6ae8a3b381663118b4e1eff4cfc7d0954dd6ec400000000000000060000000005f5e10040000000017d78400"
                        ),
                        "tx_index": DP["default_tx_index"],
                        "destination": ADDR[0],
                    },
                ),
                "records": [
                    {
                        "table": "sends",
                        "values": {
                            "asset": "XCP",
                            "block_index": DP["default_block_index"],
                            "destination": ADDR[2],
                            "quantity": DP["quantity"],
                            "source": ADDR[0],
                            "status": "valid",
                            "memo": None,
                            "msg_index": 0,
                            "tx_hash": "db6d9052b576d973196363e11163d492f50926c2f1d1efd67b3d999817b0d04d",
                            "tx_index": DP["default_tx_index"],
                        },
                    },
                    {
                        "table": "sends",
                        "values": {
                            "asset": "XCP",
                            "block_index": DP["default_block_index"],
                            "destination": ADDR[1],
                            "quantity": DP["quantity"],
                            "source": ADDR[0],
                            "status": "valid",
                            "memo": None,
                            "msg_index": 1,
                            "tx_hash": "db6d9052b576d973196363e11163d492f50926c2f1d1efd67b3d999817b0d04d",
                            "tx_index": DP["default_tx_index"],
                        },
                    },
                    {
                        "table": "credits",
                        "values": {
                            "address": ADDR[1],
                            "asset": "XCP",
                            "block_index": DP["default_block_index"],
                            "calling_function": "mpma send",
                            "event": "db6d9052b576d973196363e11163d492f50926c2f1d1efd67b3d999817b0d04d",
                            "quantity": DP["quantity"],
                        },
                    },
                    {
                        "table": "credits",
                        "values": {
                            "address": ADDR[2],
                            "asset": "XCP",
                            "block_index": DP["default_block_index"],
                            "calling_function": "mpma send",
                            "event": "db6d9052b576d973196363e11163d492f50926c2f1d1efd67b3d999817b0d04d",
                            "quantity": DP["quantity"],
                        },
                    },
                    {
                        "table": "debits",
                        "values": {
                            "action": "mpma send",
                            "address": ADDR[0],
                            "asset": "XCP",
                            "block_index": DP["default_block_index"],
                            "event": "db6d9052b576d973196363e11163d492f50926c2f1d1efd67b3d999817b0d04d",
                            "quantity": DP["quantity"] * 2,
                        },
                    },
                ],
            },
            {
                "in": (
                    {
                        "tx_hash": "db6d9052b576d973196363e11163d492f50926c2f1d1efd67b3d999817b0d04d",
                        "source": ADDR[0],
                        "supported": 1,
                        "block_index": DP["default_block_index"],
                        "fee": 10000,
                        "block_time": 155409000,
                        "block_hash": DP["default_block_hash"],
                        "btc_amount": 7800,
                        "data": binascii.unhexlify("00000000")
                        + binascii.unhexlify(
                            "00026f4e5638a01efbb2f292481797ae1dcfcdaeb98d006f8d6ae8a3b381663118b4e1eff4cfc7d0954dd6ecc4deadbeef8000000000000000c000000000bebc201897ddfbd5b0000000005f5e1000"
                        ),
                        "tx_index": DP["default_tx_index"],
                        "destination": ADDR[0],
                    },
                ),
                "records": [
                    {
                        "table": "sends",
                        "values": {
                            "asset": "XCP",
                            "block_index": DP["default_block_index"],
                            "destination": ADDR[2],
                            "quantity": DP["quantity"],
                            "source": ADDR[0],
                            "status": "valid",
                            "memo": binascii.unhexlify("BEEFDEAD"),
                            "msg_index": 0,
                            "tx_hash": "db6d9052b576d973196363e11163d492f50926c2f1d1efd67b3d999817b0d04d",
                            "tx_index": DP["default_tx_index"],
                        },
                    },
                    {
                        "table": "sends",
                        "values": {
                            "asset": "XCP",
                            "block_index": DP["default_block_index"],
                            "destination": ADDR[1],
                            "quantity": DP["quantity"],
                            "source": ADDR[0],
                            "status": "valid",
                            "memo": binascii.unhexlify("DEADBEEF"),
                            "msg_index": 1,
                            "tx_hash": "db6d9052b576d973196363e11163d492f50926c2f1d1efd67b3d999817b0d04d",
                            "tx_index": DP["default_tx_index"],
                        },
                    },
                    {
                        "table": "credits",
                        "values": {
                            "address": ADDR[1],
                            "asset": "XCP",
                            "block_index": DP["default_block_index"],
                            "calling_function": "mpma send",
                            "event": "db6d9052b576d973196363e11163d492f50926c2f1d1efd67b3d999817b0d04d",
                            "quantity": DP["quantity"],
                        },
                    },
                    {
                        "table": "credits",
                        "values": {
                            "address": ADDR[2],
                            "asset": "XCP",
                            "block_index": DP["default_block_index"],
                            "calling_function": "mpma send",
                            "event": "db6d9052b576d973196363e11163d492f50926c2f1d1efd67b3d999817b0d04d",
                            "quantity": DP["quantity"],
                        },
                    },
                    {
                        "table": "debits",
                        "values": {
                            "action": "mpma send",
                            "address": ADDR[0],
                            "asset": "XCP",
                            "block_index": DP["default_block_index"],
                            "event": "db6d9052b576d973196363e11163d492f50926c2f1d1efd67b3d999817b0d04d",
                            "quantity": DP["quantity"] * 2,
                        },
                    },
                ],
            },
            {
                "in": (
                    {
                        "tx_hash": "db6d9052b576d973196363e11163d492f50926c2f1d1efd67b3d999817b0d04d",
                        "source": ADDR[0],
                        "supported": 1,
                        "block_index": DP["default_block_index"],
                        "fee": 10000,
                        "block_time": 155409000,
                        "block_hash": DP["default_block_hash"],
                        "btc_amount": 7800,
                        "data": binascii.unhexlify("00000000")
                        + binascii.unhexlify(
                            "00026f4e5638a01efbb2f292481797ae1dcfcdaeb98d006f8d6ae8a3b381663118b4e1eff4cfc7d0954dd6ec4000002896f8d2d990000000005f5e100400000000000000040000000005f5e100000300026f4e5638a01efbb2f292481797ae1dcfcdaeb98d006f8d6ae8a3b381663118b4e1eff4cfc7d0954dd6ec4000002896f8d2d990000000005f5e100400000000000000040000000005f5e10000"
                        ),
                        "tx_index": DP["default_tx_index"],
                        "destination": ADDR[0],
                    },
                ),
                "records": [
                    {
                        "table": "sends",
                        "values": {
                            "asset": "XCP",
                            "block_index": DP["default_block_index"],
                            "destination": ADDR[2],
                            "quantity": DP["quantity"],
                            "source": ADDR[0],
                            "status": "valid",
                            "memo": None,
                            "msg_index": 1,
                            "tx_hash": "db6d9052b576d973196363e11163d492f50926c2f1d1efd67b3d999817b0d04d",
                            "tx_index": DP["default_tx_index"],
                        },
                    },
                    {
                        "table": "sends",
                        "values": {
                            "asset": "DIVISIBLE",
                            "block_index": DP["default_block_index"],
                            "destination": ADDR[1],
                            "quantity": DP["quantity"],
                            "source": ADDR[0],
                            "status": "valid",
                            "memo": None,
                            "msg_index": 0,
                            "tx_hash": "db6d9052b576d973196363e11163d492f50926c2f1d1efd67b3d999817b0d04d",
                            "tx_index": DP["default_tx_index"],
                        },
                    },
                    {
                        "table": "credits",
                        "values": {
                            "address": ADDR[1],
                            "asset": "DIVISIBLE",
                            "block_index": DP["default_block_index"],
                            "calling_function": "mpma send",
                            "event": "db6d9052b576d973196363e11163d492f50926c2f1d1efd67b3d999817b0d04d",
                            "quantity": DP["quantity"],
                        },
                    },
                    {
                        "table": "credits",
                        "values": {
                            "address": ADDR[2],
                            "asset": "XCP",
                            "block_index": DP["default_block_index"],
                            "calling_function": "mpma send",
                            "event": "db6d9052b576d973196363e11163d492f50926c2f1d1efd67b3d999817b0d04d",
                            "quantity": DP["quantity"],
                        },
                    },
                    {
                        "table": "debits",
                        "values": {
                            "action": "mpma send",
                            "address": ADDR[0],
                            "asset": "XCP",
                            "block_index": DP["default_block_index"],
                            "event": "db6d9052b576d973196363e11163d492f50926c2f1d1efd67b3d999817b0d04d",
                            "quantity": DP["quantity"],
                        },
                    },
                    {
                        "table": "debits",
                        "values": {
                            "action": "mpma send",
                            "address": ADDR[0],
                            "asset": "DIVISIBLE",
                            "block_index": DP["default_block_index"],
                            "event": "db6d9052b576d973196363e11163d492f50926c2f1d1efd67b3d999817b0d04d",
                            "quantity": DP["quantity"],
                        },
                    },
                ],
            },
        ],
    },
}
