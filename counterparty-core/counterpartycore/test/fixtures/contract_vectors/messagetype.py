import binascii

from counterpartycore.lib import config

MESSAGE_TYPE_VECTOR = {
    "parser.messagetype": {
        "unpack": [
            {
                "in": (binascii.unhexlify("01deadbeef"), 310502),
                "out": (1, binascii.unhexlify("deadbeef")),
                "mock_protocol_changes": {"short_tx_type_id": True},
            },
            {
                "in": (binascii.unhexlify("02deadbeef"), 310502),
                "out": (2, binascii.unhexlify("deadbeef")),
                "mock_protocol_changes": {"short_tx_type_id": True},
            },
            {
                "in": (binascii.unhexlify("00000001deadbeef"), 310502),
                "out": (1, binascii.unhexlify("deadbeef")),
                "mock_protocol_changes": {"short_tx_type_id": True},
            },
            {
                "in": (binascii.unhexlify("00000000deadbeef"), 310502),
                "out": (0, binascii.unhexlify("deadbeef")),
                "mock_protocol_changes": {"short_tx_type_id": True},
            },
            {
                "in": (binascii.unhexlify("00"), 310502),
                "out": (None, None),
                "mock_protocol_changes": {"short_tx_type_id": True},
            },
            {
                "in": (b"f0", 310502),
                "out": (102, b"0"),
                "mock_protocol_changes": {"short_tx_type_id": True},
            },
        ],
        "pack": [
            {"in": (0, 300000), "out": binascii.unhexlify("00000000")},
            {"in": (1, 300000), "out": binascii.unhexlify("00000001")},
            {"in": (0, 310502), "out": binascii.unhexlify("00000000")},
            {
                "in": (1, 310502),
                "out": binascii.unhexlify("01"),
                "mock_protocol_changes": {"short_tx_type_id": True},
            },
            {
                "in": (2, 310502),
                "out": binascii.unhexlify("02"),
                "mock_protocol_changes": {"short_tx_type_id": True},
            },
        ],
        "get_transaction_type": [
            {
                "in": (b"CNTRPRTY00", "", [], 3000000),
                "out": "unknown",
                "mock_protocol_changes": {"short_tx_type_id": True},
            },
            {
                "in": (b"[A95428957753448833|1", "", [], 3000000),
                "out": "fairmint",
                "mock_protocol_changes": {"short_tx_type_id": True},
            },
            {
                "in": (None, "", ["txid:0"], 3000000),
                "out": "utxomove",
                "mock_protocol_changes": {"short_tx_type_id": True, "utxo_support": True},
            },
            {
                "in": (None, "", [""], 3000000),
                "out": "unknown",
                "mock_protocol_changes": {"short_tx_type_id": True},
            },
            {
                "in": (None, "", [""], 2900000),
                "out": "dispense",
                "mock_protocol_changes": {"short_tx_type_id": True},
            },
            {
                "in": (b"eXCPMEME|25000000000|", "", [], 3000000),
                "out": "attach",
                "mock_protocol_changes": {"short_tx_type_id": True},
            },
            {
                "in": (b"fbc1qcxlwq8x9fnhyhgywlnja35l7znt58tud9duqay", "", [], 3000000),
                "out": "detach",
                "mock_protocol_changes": {"short_tx_type_id": True},
            },
            {
                "in": (
                    b"\x02\x00>\xc7\xd9>|n\x19\x00\x00\x00\x00\x00\x00\x00P\x00%?\x9e\x96I\xb3\xf9u\x15$\xb2\x90\xf93Pra\x0c\xcc\x01",
                    "",
                    [],
                    3000000,
                ),
                "out": "enhanced_send",
                "mock_protocol_changes": {"short_tx_type_id": True},
            },
            {
                "in": (None, config.UNSPENDABLE_TESTNET, [""], 3000000),
                "out": "burn",
                "mock_protocol_changes": {"short_tx_type_id": True, "utxo_support": True},
            },
            {
                "in": (None, config.UNSPENDABLE_TESTNET, [""], 5000000),
                "out": "unknown",
                "mock_protocol_changes": {"short_tx_type_id": True, "utxo_support": True},
            },
        ],
    },
}
