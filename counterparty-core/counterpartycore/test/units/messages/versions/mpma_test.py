import binascii
import re

import pytest
from counterpartycore.lib import config, exceptions, ledger
from counterpartycore.lib.messages.versions import mpma


def test_unpack(defaults, current_block_index):
    with pytest.raises(exceptions.UnpackError, match="could not unpack"):
        mpma.unpack(b"")

    with pytest.raises(exceptions.DecodeError, match="address list can't be empty"):
        mpma.unpack(binascii.unhexlify("0000"))

    with pytest.raises(exceptions.UnpackError, match="truncated data"):
        mpma.unpack(binascii.unhexlify("0001ffff"))

    assert mpma.unpack(
        binascii.unhexlify(
            "00026f4e5638a01efbb2f292481797ae1dcfcdaeb98d006f8d6ae8a3b381663118b4e1eff4cfc7d0954dd6ec400000000000000060000000005f5e10040000000017d78400"
        )
    ) == {
        "XCP": [
            (defaults["addresses"][2], defaults["quantity"]),
            (defaults["addresses"][1], defaults["quantity"]),
        ]
    }

    assert mpma.unpack(
        binascii.unhexlify(
            "00026f4e5638a01efbb2f292481797ae1dcfcdaeb98d006f8d6ae8a3b381663118b4e1eff4cfc7d0954dd6ec400000000000000060000000005f5e100c4deadbeef8000000002faf0800"
        )
    ) == {
        "XCP": [
            (defaults["addresses"][2], defaults["quantity"], binascii.unhexlify("DEADBEEF"), True),
            (defaults["addresses"][1], defaults["quantity"]),
        ]
    }

    assert mpma.unpack(
        binascii.unhexlify(
            "00026f4e5638a01efbb2f292481797ae1dcfcdaeb98d006f8d6ae8a3b381663118b4e1eff4cfc7d0954dd6ec400000000000000060000000005f5e1008844454144424545468000000002faf0800"
        )
    ) == {
        "XCP": [
            (defaults["addresses"][2], defaults["quantity"], "DEADBEEF", False),
            (defaults["addresses"][1], defaults["quantity"]),
        ]
    }

    assert mpma.unpack(
        binascii.unhexlify(
            "00036f4e5638a01efbb2f292481797ae1dcfcdaeb98d006f6c39ee7c8f3a5ffa6121b0304a7a0de9d3d9a1526f8d6ae8a3b381663118b4e1eff4cfc7d0954dd6ec4000000000000000640000000017d784000000000002faf08020000000005f5e1000"
        )
    ) == {
        "XCP": [
            (defaults["addresses"][3], defaults["quantity"]),
            (defaults["addresses"][2], defaults["quantity"]),
            (defaults["addresses"][1], defaults["quantity"]),
        ]
    }

    assert mpma.unpack(
        binascii.unhexlify(
            "00036f4e5638a01efbb2f292481797ae1dcfcdaeb98d006f6c39ee7c8f3a5ffa6121b0304a7a0de9d3d9a1526f8d6ae8a3b381663118b4e1eff4cfc7d0954dd6ec4000002896f8d2d9800000000017d784010006cad8dc7f0b66200000000000000014000000000000000440000000017d784000"
        )
    ) == {
        "XCP": [(defaults["addresses"][3], defaults["quantity"])],
        "NODIVISIBLE": [(defaults["addresses"][1], 1)],
        "DIVISIBLE": [(defaults["addresses"][2], defaults["quantity"])],
    }

    assert mpma.unpack(
        binascii.unhexlify(
            "00026f4e5638a01efbb2f292481797ae1dcfcdaeb98d006f8d6ae8a3b381663118b4e1eff4cfc7d0954dd6ecc4deadbeef8000000000000000c000000000bebc2008000000002faf0800"
        )
    ) == {
        "XCP": [
            (defaults["addresses"][2], defaults["quantity"], binascii.unhexlify("DEADBEEF"), True),
            (defaults["addresses"][1], defaults["quantity"], binascii.unhexlify("DEADBEEF"), True),
        ]
    }

    assert mpma.unpack(
        binascii.unhexlify(
            "00026f4e5638a01efbb2f292481797ae1dcfcdaeb98d006f8d6ae8a3b381663118b4e1eff4cfc7d0954dd6ecc4deadbeef8000000000000000c000000000bebc201897ddfbd5b0000000005f5e1000"
        )
    ) == {
        "XCP": [
            (defaults["addresses"][2], defaults["quantity"], binascii.unhexlify("BEEFDEAD"), True),
            (defaults["addresses"][1], defaults["quantity"], binascii.unhexlify("DEADBEEF"), True),
        ]
    }

    assert mpma.unpack(
        binascii.unhexlify(
            "00026f4e5638a01efbb2f292481797ae1dcfcdaeb98d006f8d6ae8a3b381663118b4e1eff4cfc7d0954dd6ec4000002896f8d2d990000000005f5e100400000000000000040000000005f5e100000300026f4e5638a01efbb2f292481797ae1dcfcdaeb98d006f8d6ae8a3b381663118b4e1eff4cfc7d0954dd6ec4000002896f8d2d990000000005f5e100400000000000000040000000005f5e10000"
        )
    ) == {
        "DIVISIBLE": [(defaults["addresses"][1], defaults["quantity"])],
        "XCP": [(defaults["addresses"][2], defaults["quantity"])],
    }

    assert mpma.unpack(
        binascii.unhexlify(
            "0004002e9943921a473dee1e04a579c1762ff6e9ac34e4006c7beeb1af092be778a2c0b8df639f2f8e9c987600a9055398b92818794b38b15794096f752167e25f00f3a6b6e4a093e5a5b9da76977a5270fd4d62553e40000091f59f36daf0000000271d94900180000004e3b29200200000009c76524002000000138eca4800806203d0c908232420000000000000000b000000000000000140024a67f0f279952000000000000000058000000000000000a00000000000000014000000908a3200cb000000000000000058000000000000000a000000000000000120000000000000002075410426156245525daa71f2e84a40797bcf28099a2c508662a8a33324a703597b9aa2661a79a82ffb4caaa9b15f4094622fbfa85f8b9dc7381f991f5a265421391cc3ad0075740087"
        )
    ) == {
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

    assert mpma.unpack(
        binascii.unhexlify(
            "00010042276049e5518791be2ffe2c301f5dfe9ef85dd0400001720034b0410000000000000001500000006a79811e000000000000000054000079cec1665f4800000000000000050000000ca91f2d660000000000000005402736c8de6e34d54000000000000001500c5e4c71e081ceb00000000000000054000000045dc03ec4000000000000000500004af1271cf5fc00000000000000054001e71f8464432780000000000000015000002e1e4191f0d0000000000000005400012bc4aaac2a54000000000000001500079c7e774e411c00000000000000054000000045dc0a6f00000000000000015000002e1e486f661000000000000000540001c807abe13908000000000000000475410426156245525daa71f2e84a40797bcf28099a2c508662a8a33324a703597b9aa2661a79a82ffb4caaa9b15f4094622fbfa85f8b9dc7381f991f5a265421391cc3ad0075740087"
        )
    ) == {
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


def test_validate(ledger_db, defaults, current_block_index):
    assert mpma.validate(ledger_db, []) == (["send list cannot be empty"])

    assert mpma.validate(
        ledger_db,
        [("XCP", defaults["addresses"][1], defaults["quantity"])],
    ) == (["send list cannot have only one element"])

    assert mpma.validate(
        ledger_db,
        [
            ("XCP", defaults["addresses"][2], defaults["quantity"]),
            ("XCP", defaults["addresses"][1], 0.1),
        ],
    ) == ([f"quantities must be an int (in satoshis) for XCP to {defaults['addresses'][1]}"])

    assert mpma.validate(
        ledger_db,
        [
            ("XCP", defaults["addresses"][2], defaults["quantity"]),
            ("XCP", defaults["addresses"][1], -defaults["quantity"]),
        ],
    ) == ([f"negative quantity for XCP to {defaults['addresses'][1]}"])

    assert mpma.validate(
        ledger_db,
        [
            ("XCP", defaults["addresses"][2], defaults["quantity"]),
            ("XCP", defaults["addresses"][1], 0),
        ],
    ) == ([f"zero quantity for XCP to {defaults['addresses'][1]}"])

    assert mpma.validate(
        ledger_db,
        [
            ("XCP", defaults["addresses"][2], defaults["quantity"]),
            ("XCP", defaults["addresses"][1], config.MAX_INT + 1),
        ],
    ) == ([f"integer overflow for XCP to {defaults['addresses'][1]}"])

    assert mpma.validate(
        ledger_db,
        [
            ("XCP", defaults["addresses"][2], defaults["quantity"]),
            ("XCP", None, defaults["quantity"]),
        ],
    ) == (["destination is required for XCP"])

    assert mpma.validate(
        ledger_db,
        [
            ("XCP", defaults["addresses"][2], defaults["quantity"]),
            ("BTC", defaults["addresses"][1], defaults["quantity"]),
        ],
    ) == ([f"cannot send BTC to {defaults['addresses'][1]}"])

    assert mpma.validate(
        ledger_db,
        [
            ("XCP", defaults["addresses"][2], defaults["quantity"]),
            ("XCP", defaults["addresses"][1], defaults["quantity"]),
        ],
    ) == ([])

    assert mpma.validate(
        ledger_db,
        [
            ("XCP", defaults["addresses"][2], defaults["quantity"]),
            ("XCP", defaults["addresses"][2], defaults["quantity"] + 1),
        ],
    ) == (["cannot specify more than once a destination per asset"])

    assert mpma.validate(
        ledger_db,
        [
            ("XCP", defaults["addresses"][2], defaults["quantity"]),
            ("XCP", defaults["addresses"][6], defaults["quantity"], "DEADBEEF", True),
        ],
    ) == ([])

    ledger.events.insert_record(
        ledger_db,
        "addresses",
        {
            "block_index": current_block_index,
            "address": defaults["addresses"][6],
            "options": config.ADDRESS_OPTION_REQUIRE_MEMO,
        },
        "NEW_ADDRESS_OPTIONS",
    )

    assert mpma.validate(
        ledger_db,
        [
            ("XCP", defaults["addresses"][2], defaults["quantity"]),
            ("XCP", defaults["addresses"][6], defaults["quantity"]),
        ],
    ) == ([f"destination {defaults['addresses'][6]} requires memo"])


def test_compose_valid(ledger_db, defaults):
    assert mpma.compose(
        ledger_db,
        defaults["addresses"][0],
        [
            ("XCP", defaults["addresses"][2], defaults["quantity"]),
            ("XCP", defaults["addresses"][1], defaults["quantity"]),
        ],
        None,
        None,
    ) == (
        defaults["addresses"][0],
        [],
        binascii.unhexlify(
            "0300026f4e5638a01efbb2f292481797ae1dcfcdaeb98d006f8d6ae8a3b381663118b4e1eff4cfc7d0954dd6ec400000000000000060000000005f5e10040000000017d78400"
        ),
    )

    assert mpma.compose(
        ledger_db,
        defaults["addresses"][0],
        [
            ("XCP", defaults["addresses"][2], defaults["quantity"], "DEADBEEF", True),
            ("XCP", defaults["addresses"][1], defaults["quantity"]),
        ],
        None,
        None,
    ) == (
        defaults["addresses"][0],
        [],
        binascii.unhexlify(
            "0300026f4e5638a01efbb2f292481797ae1dcfcdaeb98d006f8d6ae8a3b381663118b4e1eff4cfc7d0954dd6ec400000000000000060000000005f5e100c4deadbeef8000000002faf0800"
        ),
    )

    assert mpma.compose(
        ledger_db,
        defaults["addresses"][0],
        [
            ("XCP", defaults["addresses"][2], defaults["quantity"], "DEADBEEF", False),
            ("XCP", defaults["addresses"][1], defaults["quantity"]),
        ],
        None,
        None,
    ) == (
        defaults["addresses"][0],
        [],
        binascii.unhexlify(
            "0300026f4e5638a01efbb2f292481797ae1dcfcdaeb98d006f8d6ae8a3b381663118b4e1eff4cfc7d0954dd6ec400000000000000060000000005f5e1008844454144424545468000000002faf0800"
        ),
    )

    assert mpma.compose(
        ledger_db,
        defaults["addresses"][0],
        [
            ("XCP", defaults["addresses"][3], defaults["quantity"]),
            ("XCP", defaults["addresses"][2], defaults["quantity"]),
            ("XCP", defaults["addresses"][1], defaults["quantity"]),
        ],
        None,
        None,
    ) == (
        defaults["addresses"][0],
        [],
        binascii.unhexlify(
            "0300036f4e5638a01efbb2f292481797ae1dcfcdaeb98d006f6c39ee7c8f3a5ffa6121b0304a7a0de9d3d9a1526f8d6ae8a3b381663118b4e1eff4cfc7d0954dd6ec4000000000000000640000000017d784000000000002faf08020000000005f5e1000"
        ),
    )

    assert mpma.compose(
        ledger_db,
        defaults["addresses"][0],
        [
            ("XCP", defaults["addresses"][3], defaults["quantity"]),
            ("DIVISIBLE", defaults["addresses"][2], defaults["quantity"]),
            ("NODIVISIBLE", defaults["addresses"][1], 1),
        ],
        None,
        None,
    ) == (
        defaults["addresses"][0],
        [],
        binascii.unhexlify(
            "0300036f4e5638a01efbb2f292481797ae1dcfcdaeb98d006f6c39ee7c8f3a5ffa6121b0304a7a0de9d3d9a1526f8d6ae8a3b381663118b4e1eff4cfc7d0954dd6ec4000002896f8d2d9800000000017d784010006cad8dc7f0b66200000000000000014000000000000000440000000017d784000"
        ),
    )

    assert mpma.compose(
        ledger_db,
        defaults["addresses"][0],
        [
            ("XCP", defaults["addresses"][2], defaults["quantity"]),
            ("XCP", defaults["addresses"][1], defaults["quantity"]),
        ],
        "DEADBEEF",
        True,
    ) == (
        defaults["addresses"][0],
        [],
        binascii.unhexlify(
            "0300026f4e5638a01efbb2f292481797ae1dcfcdaeb98d006f8d6ae8a3b381663118b4e1eff4cfc7d0954dd6ecc4deadbeef8000000000000000c000000000bebc2008000000002faf0800"
        ),
    )

    assert mpma.compose(
        ledger_db,
        defaults["addresses"][0],
        [
            ("XCP", defaults["addresses"][2], defaults["quantity"]),
            ("XCP", defaults["addresses"][1], defaults["quantity"]),
        ],
        "DEADBEEF",
        False,
    ) == (
        defaults["addresses"][0],
        [],
        binascii.unhexlify(
            "0300026f4e5638a01efbb2f292481797ae1dcfcdaeb98d006f8d6ae8a3b381663118b4e1eff4cfc7d0954dd6ec8844454144424545468000000000000000c000000000bebc2008000000002faf0800"
        ),
    )

    assert mpma.compose(
        ledger_db,
        defaults["addresses"][0],
        [
            ("XCP", defaults["addresses"][2], defaults["quantity"], "BEEFDEAD", True),
            ("XCP", defaults["addresses"][1], defaults["quantity"]),
        ],
        "DEADBEEF",
        True,
    ) == (
        defaults["addresses"][0],
        [],
        binascii.unhexlify(
            "0300026f4e5638a01efbb2f292481797ae1dcfcdaeb98d006f8d6ae8a3b381663118b4e1eff4cfc7d0954dd6ecc4deadbeef8000000000000000c000000000bebc201897ddfbd5b0000000005f5e1000"
        ),
    )

    assert mpma.compose(
        ledger_db,
        defaults["addresses"][0],
        [
            ("XCP", defaults["addresses"][2], defaults["quantity"]),
            ("DIVISIBLE", defaults["addresses"][1], defaults["quantity"]),
        ],
        None,
        None,
    ) == (
        defaults["addresses"][0],
        [],
        binascii.unhexlify(
            "0300026f4e5638a01efbb2f292481797ae1dcfcdaeb98d006f8d6ae8a3b381663118b4e1eff4cfc7d0954dd6ec4000002896f8d2d990000000005f5e100400000000000000040000000005f5e10000"
        ),
    )


def test_compose_invalid(ledger_db, defaults):
    with pytest.raises(exceptions.ComposeError, match="insufficient funds for XCP"):
        mpma.compose(
            ledger_db,
            defaults["addresses"][0],
            [("XCP", defaults["addresses"][1], defaults["quantity"] * 1000000)],
            None,
            None,
        )

    with pytest.raises(exceptions.ComposeError, match="insufficient funds for XCP"):
        mpma.compose(
            ledger_db,
            defaults["addresses"][0],
            [
                ("XCP", defaults["addresses"][2], defaults["quantity"]),
                ("XCP", defaults["addresses"][1], defaults["quantity"] * 10000),
            ],
            None,
            None,
        )

    with pytest.raises(exceptions.ComposeError, match="`memo` must be a string"):
        mpma.compose(
            ledger_db,
            defaults["addresses"][0],
            [("XCP", defaults["addresses"][1], defaults["quantity"])],
            ["memo1"],
            None,
        )

    with pytest.raises(exceptions.ComposeError, match="`memo_is_hex` must be a boolean"):
        mpma.compose(
            ledger_db,
            defaults["addresses"][0],
            [("XCP", defaults["addresses"][1], defaults["quantity"])],
            "memo1",
            "nobool",
        )

    with pytest.raises(
        exceptions.ComposeError, match=re.escape("quantities must be an int (in satoshis) for XCP")
    ):
        mpma.compose(
            ledger_db,
            defaults["addresses"][0],
            [
                ("XCP", defaults["addresses"][2], defaults["quantity"]),
                ("XCP", defaults["addresses"][1], 0.1),
            ],
            None,
            None,
        )

    with pytest.raises(
        exceptions.ComposeError,
        match=re.escape(f"Address not supported by MPMA send: {defaults['p2tr_addresses'][1]}"),
    ):
        mpma.compose(
            ledger_db,
            defaults["addresses"][0],
            [
                ("XCP", defaults["addresses"][2], defaults["quantity"]),
                ("XCP", defaults["p2tr_addresses"][1], 0.1),
            ],
            None,
            None,
        )


def test_parse_2_sends(ledger_db, blockchain_mock, defaults, test_helpers, current_block_index):
    tx = blockchain_mock.dummy_tx(ledger_db, defaults["addresses"][0])
    message = binascii.unhexlify(
        "00026f4e5638a01efbb2f292481797ae1dcfcdaeb98d006f8d6ae8a3b381663118b4e1eff4cfc7d0954dd6ec400000000000000060000000005f5e10040000000017d78400"
    )
    mpma.parse(ledger_db, tx, message)

    test_helpers.check_records(
        ledger_db,
        [
            {
                "table": "sends",
                "values": {
                    "tx_index": tx["tx_index"],
                    "tx_hash": tx["tx_hash"],
                    "block_index": tx["block_index"],
                    "source": defaults["addresses"][0],
                    "destination": defaults["addresses"][2],
                    "asset": "XCP",
                    "quantity": defaults["quantity"],
                    "status": "valid",
                    "msg_index": 1,
                    "fee_paid": 0,
                    "send_type": "send",
                    "memo": None,
                },
            },
            {
                "table": "sends",
                "values": {
                    "tx_index": tx["tx_index"],
                    "tx_hash": tx["tx_hash"],
                    "block_index": tx["block_index"],
                    "source": defaults["addresses"][0],
                    "destination": defaults["addresses"][1],
                    "asset": "XCP",
                    "quantity": defaults["quantity"],
                    "status": "valid",
                    "msg_index": 2,
                    "fee_paid": 0,
                    "send_type": "send",
                    "memo": None,
                },
            },
            {
                "table": "credits",
                "values": {
                    "address": defaults["addresses"][1],
                    "asset": "XCP",
                    "block_index": current_block_index,
                    "calling_function": "mpma send",
                    "event": tx["tx_hash"],
                    "quantity": defaults["quantity"],
                },
            },
            {
                "table": "credits",
                "values": {
                    "address": defaults["addresses"][2],
                    "asset": "XCP",
                    "block_index": current_block_index,
                    "calling_function": "mpma send",
                    "event": tx["tx_hash"],
                    "quantity": defaults["quantity"],
                },
            },
            {
                "table": "debits",
                "values": {
                    "action": "mpma send",
                    "address": defaults["addresses"][0],
                    "asset": "XCP",
                    "block_index": current_block_index,
                    "event": tx["tx_hash"],
                    "quantity": defaults["quantity"] * 2,
                },
            },
        ],
    )


def test_parse_2_sends_with_memo(
    ledger_db, blockchain_mock, defaults, test_helpers, current_block_index
):
    tx = blockchain_mock.dummy_tx(ledger_db, defaults["addresses"][0])
    message = binascii.unhexlify(
        "00026f4e5638a01efbb2f292481797ae1dcfcdaeb98d006f8d6ae8a3b381663118b4e1eff4cfc7d0954dd6ecc4deadbeef8000000000000000c000000000bebc2008000000002faf0800"
    )
    mpma.parse(ledger_db, tx, message)

    test_helpers.check_records(
        ledger_db,
        [
            {
                "table": "sends",
                "values": {
                    "tx_index": tx["tx_index"],
                    "tx_hash": tx["tx_hash"],
                    "block_index": tx["block_index"],
                    "source": defaults["addresses"][0],
                    "destination": defaults["addresses"][2],
                    "asset": "XCP",
                    "quantity": defaults["quantity"],
                    "status": "valid",
                    "msg_index": 1,
                    "fee_paid": 0,
                    "send_type": "send",
                    "memo": binascii.unhexlify("DEADBEEF"),
                },
            },
            {
                "table": "sends",
                "values": {
                    "tx_index": tx["tx_index"],
                    "tx_hash": tx["tx_hash"],
                    "block_index": tx["block_index"],
                    "source": defaults["addresses"][0],
                    "destination": defaults["addresses"][1],
                    "asset": "XCP",
                    "quantity": defaults["quantity"],
                    "status": "valid",
                    "msg_index": 2,
                    "fee_paid": 0,
                    "send_type": "send",
                    "memo": binascii.unhexlify("DEADBEEF"),
                },
            },
            {
                "table": "credits",
                "values": {
                    "address": defaults["addresses"][1],
                    "asset": "XCP",
                    "block_index": current_block_index,
                    "calling_function": "mpma send",
                    "event": tx["tx_hash"],
                    "quantity": defaults["quantity"],
                },
            },
            {
                "table": "credits",
                "values": {
                    "address": defaults["addresses"][2],
                    "asset": "XCP",
                    "block_index": current_block_index,
                    "calling_function": "mpma send",
                    "event": tx["tx_hash"],
                    "quantity": defaults["quantity"],
                },
            },
            {
                "table": "debits",
                "values": {
                    "action": "mpma send",
                    "address": defaults["addresses"][0],
                    "asset": "XCP",
                    "block_index": current_block_index,
                    "event": tx["tx_hash"],
                    "quantity": defaults["quantity"] * 2,
                },
            },
        ],
    )


def test_parse_2_assets(ledger_db, blockchain_mock, defaults, test_helpers, current_block_index):
    tx = blockchain_mock.dummy_tx(ledger_db, defaults["addresses"][0])
    message = binascii.unhexlify(
        "00026f4e5638a01efbb2f292481797ae1dcfcdaeb98d006f8d6ae8a3b381663118b4e1eff4cfc7d0954dd6ec4000002896f8d2d990000000005f5e100400000000000000040000000005f5e10000"
    )
    mpma.parse(ledger_db, tx, message)

    test_helpers.check_records(
        ledger_db,
        [
            {
                "table": "sends",
                "values": {
                    "tx_index": tx["tx_index"],
                    "tx_hash": tx["tx_hash"],
                    "block_index": tx["block_index"],
                    "source": defaults["addresses"][0],
                    "destination": defaults["addresses"][1],
                    "asset": "DIVISIBLE",
                    "quantity": defaults["quantity"],
                    "status": "valid",
                    "msg_index": 1,
                    "fee_paid": 0,
                    "send_type": "send",
                },
            },
            {
                "table": "sends",
                "values": {
                    "tx_index": tx["tx_index"],
                    "tx_hash": tx["tx_hash"],
                    "block_index": tx["block_index"],
                    "source": defaults["addresses"][0],
                    "destination": defaults["addresses"][2],
                    "asset": "XCP",
                    "quantity": defaults["quantity"],
                    "status": "valid",
                    "msg_index": 2,
                    "fee_paid": 0,
                    "send_type": "send",
                },
            },
            {
                "table": "credits",
                "values": {
                    "address": defaults["addresses"][2],
                    "asset": "XCP",
                    "block_index": current_block_index,
                    "calling_function": "mpma send",
                    "event": tx["tx_hash"],
                    "quantity": defaults["quantity"],
                },
            },
            {
                "table": "credits",
                "values": {
                    "address": defaults["addresses"][1],
                    "asset": "DIVISIBLE",
                    "block_index": current_block_index,
                    "calling_function": "mpma send",
                    "event": tx["tx_hash"],
                    "quantity": defaults["quantity"],
                },
            },
            {
                "table": "debits",
                "values": {
                    "action": "mpma send",
                    "address": defaults["addresses"][0],
                    "asset": "XCP",
                    "block_index": current_block_index,
                    "event": tx["tx_hash"],
                    "quantity": defaults["quantity"],
                },
            },
            {
                "table": "debits",
                "values": {
                    "action": "mpma send",
                    "address": defaults["addresses"][0],
                    "asset": "DIVISIBLE",
                    "block_index": current_block_index,
                    "event": tx["tx_hash"],
                    "quantity": defaults["quantity"],
                },
            },
        ],
    )
