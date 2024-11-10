from counterpartycore.lib import config, exceptions

from ..params import ADDR, DP

UTXO_1 = "344dcc8909ca3a137630726d0071dfd2df4f7c855bac150c7d3a8367835c90bc:1"
UTXO_2 = "e219be68972de7df99122a0213d7be2f597c14fa48b55457a81641583099fea4:0"
UTXO_3 = "74501a157028760383ae4a8f79f6bce9ef64e60e883ac3285bc239a907c2b42c:0"

ATTACH_VECTOR = {
    "attach": {
        "validate": [
            {
                "in": (
                    ADDR[0],
                    "XCP",
                    100,
                ),
                "out": [],
            },
            {
                "in": (
                    ADDR[0],
                    "XCP",
                    100,
                    1,
                ),
                "out": [],
            },
            {
                "in": (
                    UTXO_1,
                    "XCP",
                    100,
                ),
                "out": ["invalid source address"],
            },
            {
                "in": (ADDR[0], "XCP", 0),
                "out": ["quantity must be greater than zero"],
            },
            {
                "in": (ADDR[0], "XCP", 99999999999999),
                "out": ["insufficient funds for transfer and fee"],
            },
            {
                "in": (ADDR[0], "DIVISIBLE", 99999999999999),
                "out": ["insufficient funds for transfer"],
            },
            {
                "in": (
                    ADDR[0],
                    "BTC",
                    100,
                ),
                "out": ["cannot send bitcoins"],
            },
            {
                "in": (
                    ADDR[0],
                    "XCP",
                    config.MAX_INT + 1,
                ),
                "out": ["integer overflow"],
            },
            {
                "in": (
                    ADDR[0],
                    "XCP",
                    "100",
                ),
                "out": ["quantity must be in satoshis"],
            },
            {
                "in": (
                    ADDR[0],
                    "XCP",
                    100,
                    -1,
                ),
                "out": ["destination vout must be greater than or equal to zero"],
            },
            {
                "in": (
                    ADDR[0],
                    "XCP",
                    100,
                    "1",
                ),
                "out": ["if provided destination must be an integer"],
            },
        ],
        "compose": [
            {
                "in": (
                    ADDR[0],
                    "XCP",
                    100,
                    1,
                ),
                "out": (
                    ADDR[0],
                    [],
                    b"eXCP|100|1",
                ),
            },
            {
                "in": (UTXO_1, "XCP", 100),
                "error": (
                    exceptions.ComposeError,
                    ["invalid source address"],
                ),
            },
            {
                "in": (
                    ADDR[0],
                    "XCP",
                    100,
                ),
                "out": (
                    ADDR[0],
                    [(ADDR[0], None)],
                    b"eXCP|100|",
                ),
            },
        ],
        "unpack": [
            {
                "in": (b"XCP|100|1",),
                "out": ("XCP", 100, 1),
            },
            {
                "in": (b"XCP|100|1", True),
                "out": {"asset": "XCP", "quantity": 100, "destination_vout": 1},
            },
            {
                "in": (b"XCP|100|",),
                "out": ("XCP", 100, None),
            },
        ],
        "parse": [
            {
                "in": (
                    {
                        "fee": 10000,
                        "tx_hash": "72a62abedd38d5f667150929c24dc1d7465dd81ab1502974814d20c1f65d871f",
                        "data": b"eXCP|100|",
                        "source": ADDR[0],
                        "block_index": DP["default_block_index"],
                        "btc_amount": 5430,
                        "tx_index": DP["default_tx_index"],
                        "supported": 1,
                        "destination": ADDR[0],
                        "block_time": 310501000,
                        "block_hash": "46ac6d09237c7961199068fdd13f1508d755483e07c57a4c8f7ff18eb33a05c93ca6a86fa2e2af82fb77a5c337146bb37e279797a3d11970aec4693c46ea5a58",
                        "utxos_info": " 72a62abedd38d5f667150929c24dc1d7465dd81ab1502974814d20c1f65d871f:0 2 1",
                    },
                ),
                "records": [
                    {
                        "table": "debits",
                        "values": {
                            "address": ADDR[0],
                            "asset": "XCP",
                            "quantity": 100,
                            "event": "72a62abedd38d5f667150929c24dc1d7465dd81ab1502974814d20c1f65d871f",
                            "block_index": DP["default_block_index"],
                            "tx_index": DP["default_tx_index"],
                            "action": "attach to utxo",
                        },
                    },
                    {
                        "table": "credits",
                        "values": {
                            "utxo": "72a62abedd38d5f667150929c24dc1d7465dd81ab1502974814d20c1f65d871f:0",
                            "address": None,
                            "asset": "XCP",
                            "quantity": 100,
                            "event": "72a62abedd38d5f667150929c24dc1d7465dd81ab1502974814d20c1f65d871f",
                            "block_index": DP["default_block_index"],
                            "tx_index": DP["default_tx_index"],
                            "calling_function": "attach to utxo",
                        },
                    },
                    {
                        "table": "sends",
                        "values": {
                            "tx_index": DP["default_tx_index"],
                            "tx_hash": "72a62abedd38d5f667150929c24dc1d7465dd81ab1502974814d20c1f65d871f",
                            "block_index": DP["default_block_index"],
                            "status": "valid",
                            "source": ADDR[0],
                            "destination": "72a62abedd38d5f667150929c24dc1d7465dd81ab1502974814d20c1f65d871f:0",
                            "asset": "XCP",
                            "quantity": 100,
                            "fee_paid": 0,
                        },
                    },
                    {
                        "table": "messages",
                        "values": {
                            "block_index": DP["default_block_index"],
                            "command": "insert",
                            "category": "sends",
                            "bindings": '{"asset":"XCP","block_index":310704,"destination":"72a62abedd38d5f667150929c24dc1d7465dd81ab1502974814d20c1f65d871f:0","fee_paid":0,"msg_index":0,"quantity":100,"source":"mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc","status":"valid","tx_hash":"72a62abedd38d5f667150929c24dc1d7465dd81ab1502974814d20c1f65d871f","tx_index":705}',
                            "event": "ATTACH_TO_UTXO",
                        },
                    },
                ],
            },
            {
                "in": (
                    {
                        "fee": 10000,
                        "tx_hash": "72a62abedd38d5f667150929c24dc1d7465dd81ab1502974814d20c1f65d871f",
                        "data": b"eXCP|100|1",
                        "source": ADDR[0],
                        "block_index": DP["default_block_index"],
                        "btc_amount": 5430,
                        "tx_index": DP["default_tx_index"],
                        "supported": 1,
                        "destination": ADDR[0],
                        "block_time": 310501000,
                        "block_hash": "46ac6d09237c7961199068fdd13f1508d755483e07c57a4c8f7ff18eb33a05c93ca6a86fa2e2af82fb77a5c337146bb37e279797a3d11970aec4693c46ea5a58",
                        "utxos_info": " 72a62abedd38d5f667150929c24dc1d7465dd81ab1502974814d20c1f65d871f:0 2 0",
                    },
                ),
                "records": [
                    {
                        "table": "messages",
                        "values": {
                            "block_index": DP["default_block_index"],
                            "command": "insert",
                            "category": "sends",
                            "bindings": '{"asset":"XCP","block_index":310704,"destination":"72a62abedd38d5f667150929c24dc1d7465dd81ab1502974814d20c1f65d871f:1","fee_paid":0,"msg_index":0,"quantity":100,"source":"mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc","status":"valid","tx_hash":"72a62abedd38d5f667150929c24dc1d7465dd81ab1502974814d20c1f65d871f","tx_index":705}',
                            "event": "ATTACH_TO_UTXO",
                        },
                    },
                ],
            },
            {
                "in": (
                    {
                        "fee": 10000,
                        "tx_hash": "72a62abedd38d5f667150929c24dc1d7465dd81ab1502974814d20c1f65d871f",
                        "data": b"eXCP|100|1",
                        "source": ADDR[0],
                        "block_index": DP["default_block_index"],
                        "btc_amount": 5430,
                        "tx_index": DP["default_tx_index"],
                        "supported": 1,
                        "destination": ADDR[0],
                        "block_time": 310501000,
                        "block_hash": "46ac6d09237c7961199068fdd13f1508d755483e07c57a4c8f7ff18eb33a05c93ca6a86fa2e2af82fb77a5c337146bb37e279797a3d11970aec4693c46ea5a58",
                        "utxos_info": " 72a62abedd38d5f667150929c24dc1d7465dd81ab1502974814d20c1f65d871f:0 2 1",
                    },
                ),
                "records": [
                    {
                        "table": "messages",
                        "values": {
                            "block_index": DP["default_block_index"],
                            "command": "insert",
                            "category": "sends",
                            "bindings": '{"block_index":310704,"msg_index":0,"status":"invalid: destination vout is an OP_RETURN output","tx_hash":"72a62abedd38d5f667150929c24dc1d7465dd81ab1502974814d20c1f65d871f","tx_index":705}',
                            "event": "ATTACH_TO_UTXO",
                        },
                    },
                ],
            },
            {
                "in": (
                    {
                        "fee": 10000,
                        "tx_hash": "72a62abedd38d5f667150929c24dc1d7465dd81ab1502974814d20c1f65d871f",
                        "data": b"eXCP|100|3",
                        "source": ADDR[0],
                        "block_index": DP["default_block_index"],
                        "btc_amount": 5430,
                        "tx_index": DP["default_tx_index"],
                        "supported": 1,
                        "destination": ADDR[0],
                        "block_time": 310501000,
                        "block_hash": "46ac6d09237c7961199068fdd13f1508d755483e07c57a4c8f7ff18eb33a05c93ca6a86fa2e2af82fb77a5c337146bb37e279797a3d11970aec4693c46ea5a58",
                        "utxos_info": " 72a62abedd38d5f667150929c24dc1d7465dd81ab1502974814d20c1f65d871f:0 2 1",
                    },
                ),
                "records": [
                    {
                        "table": "messages",
                        "values": {
                            "block_index": DP["default_block_index"],
                            "command": "insert",
                            "category": "sends",
                            "bindings": '{"block_index":310704,"msg_index":0,"status":"invalid: destination vout is greater than the number of outputs","tx_hash":"72a62abedd38d5f667150929c24dc1d7465dd81ab1502974814d20c1f65d871f","tx_index":705}',
                            "event": "ATTACH_TO_UTXO",
                        },
                    },
                ],
            },
            {
                "in": (
                    {
                        "fee": 10000,
                        "tx_hash": "72a62abedd38d5f667150929c24dc1d7465dd81ab1502974814d20c1f65d871f",
                        "data": b"eXCP|100|",
                        "source": ADDR[0],
                        "block_index": DP["default_block_index"],
                        "btc_amount": 5430,
                        "tx_index": DP["default_tx_index"],
                        "supported": 1,
                        "destination": ADDR[0],
                        "block_time": 310501000,
                        "block_hash": "46ac6d09237c7961199068fdd13f1508d755483e07c57a4c8f7ff18eb33a05c93ca6a86fa2e2af82fb77a5c337146bb37e279797a3d11970aec4693c46ea5a58",
                        "utxos_info": "  1 0",  # only one OP_RETURN output
                    },
                ),
                "records": [
                    {
                        "table": "messages",
                        "values": {
                            "block_index": DP["default_block_index"],
                            "command": "insert",
                            "category": "sends",
                            "bindings": '{"block_index":310704,"msg_index":0,"status":"invalid: no UTXO to attach to","tx_hash":"72a62abedd38d5f667150929c24dc1d7465dd81ab1502974814d20c1f65d871f","tx_index":705}',
                            "event": "ATTACH_TO_UTXO",
                        },
                    },
                ],
            },
        ],
    },
}
