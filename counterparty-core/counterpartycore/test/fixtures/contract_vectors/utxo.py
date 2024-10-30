from counterpartycore.lib import config, exceptions

from ..params import (
    ADDR,
    DP,
)

UTXO_1 = "344dcc8909ca3a137630726d0071dfd2df4f7c855bac150c7d3a8367835c90bc:1"
UTXO_2 = "4f0433ba841038e2e16328445930dd7bca35309b14b0da4451c8f94c631368b8:1"
UTXO_3 = "1fc2e5a57f584b2f2edd05676e75c33d03eed1d3098cc0550ea33474e3ec9db1:1"

UTXO_VECTOR = {
    "utxo": {
        "validate": [
            {
                "in": (
                    ADDR[0],
                    UTXO_1,
                    "XCP",
                    100,
                ),
                "out": [],
            },
            {
                "in": (ADDR[0], ADDR[1], "XCP", 100),
                "out": ["If source is an address, destination must be a UTXO"],
            },
            {
                "in": (UTXO_1, UTXO_1, "XCP", 100),
                "out": [
                    "If source is a UTXO, destination must be an address",
                ],
            },
            {
                "in": (ADDR[0], UTXO_1, "XCP", 0),
                "out": ["quantity must be greater than zero"],
            },
            {
                "in": (ADDR[0], UTXO_1, "XCP", 99999999999999),
                "out": ["insufficient funds for transfer and fee"],
            },
            {
                "in": (
                    ADDR[0],
                    UTXO_1,
                    "BTC",
                    100,
                ),
                "out": ["cannot send bitcoins"],
            },
            {
                "in": (
                    ADDR[0],
                    UTXO_1,
                    "XCP",
                    config.MAX_INT + 1,
                ),
                "out": ["integer overflow"],
            },
            {
                "in": (
                    ADDR[0],
                    UTXO_1,
                    "XCP",
                    "100",
                ),
                "out": ["quantity must be in satoshis"],
            },
        ],
        "compose": [
            {
                "in": (
                    ADDR[0],
                    UTXO_1,
                    "XCP",
                    100,
                ),
                "out": (
                    ADDR[0],
                    [],
                    b"dmn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc|344dcc8909ca3a137630726d0071dfd2df4f7c855bac150c7d3a8367835c90bc:1|XCP|100",
                ),
            },
            {
                "in": (ADDR[0], ADDR[1], "XCP", 100),
                "error": (
                    exceptions.ComposeError,
                    ["If source is an address, destination must be a UTXO"],
                ),
            },
            {
                "in": (
                    UTXO_2,
                    ADDR[1],
                    "XCP",
                    100,
                ),
                "out": (
                    UTXO_2,
                    [],
                    b"d4f0433ba841038e2e16328445930dd7bca35309b14b0da4451c8f94c631368b8:1|mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns||",
                ),
            },
            {
                "in": (
                    ADDR[0],
                    None,
                    "XCP",
                    100,
                ),
                "out": (
                    ADDR[0],
                    [(ADDR[0], None)],
                    b"dmn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc||XCP|100",
                ),
            },
        ],
        "unpack": [
            {
                "in": (
                    b"mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc|344dcc8909ca3a137630726d0071dfd2df4f7c855bac150c7d3a8367835c90bc:1|XCP|100",
                ),
                "out": (
                    ADDR[0],
                    "344dcc8909ca3a137630726d0071dfd2df4f7c855bac150c7d3a8367835c90bc:1",
                    "XCP",
                    100,
                ),
            },
        ],
        "parse": [
            {
                "in": (
                    {
                        "fee": 10000,
                        "tx_hash": "72a62abedd38d5f667150929c24dc1d7465dd81ab1502974814d20c1f65d871f",
                        "data": b"dmn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc|344dcc8909ca3a137630726d0071dfd2df4f7c855bac150c7d3a8367835c90bc:1|XCP|100",
                        "source": ADDR[0],
                        "block_index": DP["default_block_index"],
                        "btc_amount": 5430,
                        "tx_index": DP["default_tx_index"],
                        "supported": 1,
                        "destination": ADDR[0],
                        "block_time": 310501000,
                        "block_hash": "46ac6d09237c7961199068fdd13f1508d755483e07c57a4c8f7ff18eb33a05c93ca6a86fa2e2af82fb77a5c337146bb37e279797a3d11970aec4693c46ea5a58",
                        "utxos_info": "",
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
                        "table": "debits",
                        "values": {
                            "address": ADDR[0],
                            "asset": "XCP",
                            "quantity": 10,
                            "event": "72a62abedd38d5f667150929c24dc1d7465dd81ab1502974814d20c1f65d871f",
                            "block_index": DP["default_block_index"],
                            "tx_index": DP["default_tx_index"],
                            "action": "attach to utxo fee",
                        },
                    },
                    {
                        "table": "credits",
                        "values": {
                            "utxo": UTXO_1,
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
                            "destination": UTXO_1,
                            "asset": "XCP",
                            "quantity": 100,
                            "fee_paid": 10,
                        },
                    },
                    {
                        "table": "messages",
                        "values": {
                            "block_index": DP["default_block_index"],
                            "command": "insert",
                            "category": "sends",
                            "bindings": '{"asset":"XCP","block_index":310704,"destination":"344dcc8909ca3a137630726d0071dfd2df4f7c855bac150c7d3a8367835c90bc:1","fee_paid":10,"msg_index":0,"quantity":100,"source":"mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc","status":"valid","tx_hash":"72a62abedd38d5f667150929c24dc1d7465dd81ab1502974814d20c1f65d871f","tx_index":705}',
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
                        "data": b"d4f0433ba841038e2e16328445930dd7bca35309b14b0da4451c8f94c631368b8:1|mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns|XCP|100",
                        "source": ADDR[0],
                        "block_index": DP["default_block_index"],
                        "btc_amount": 5430,
                        "tx_index": DP["default_tx_index"],
                        "supported": 1,
                        "destination": ADDR[0],
                        "block_time": 310501000,
                        "block_hash": "46ac6d09237c7961199068fdd13f1508d755483e07c57a4c8f7ff18eb33a05c93ca6a86fa2e2af82fb77a5c337146bb37e279797a3d11970aec4693c46ea5a58",
                        "utxos_info": "4f0433ba841038e2e16328445930dd7bca35309b14b0da4451c8f94c631368b8:1 4f0433ba841038e2e16328445930dd7bca35309b14b0da4451c8f94c631368b8:1",
                    },
                ),
                "records": [
                    {
                        "table": "sends",
                        "values": {
                            "tx_index": DP["default_tx_index"],
                            "tx_hash": "72a62abedd38d5f667150929c24dc1d7465dd81ab1502974814d20c1f65d871f",
                            "block_index": DP["default_block_index"],
                            "status": "valid",
                            "source": UTXO_2,
                            "destination": ADDR[1],
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
                            "bindings": '{"asset":"XCP","block_index":310704,"destination":"mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns","fee_paid":0,"msg_index":1,"quantity":100,"source":"4f0433ba841038e2e16328445930dd7bca35309b14b0da4451c8f94c631368b8:1","status":"valid","tx_hash":"72a62abedd38d5f667150929c24dc1d7465dd81ab1502974814d20c1f65d871f","tx_index":705}',
                            "event": "DETACH_FROM_UTXO",
                        },
                    },
                    {
                        "table": "debits",
                        "values": {
                            "utxo": UTXO_2,
                            "asset": "XCP",
                            "quantity": 100,
                            "event": "72a62abedd38d5f667150929c24dc1d7465dd81ab1502974814d20c1f65d871f",
                            "block_index": DP["default_block_index"],
                            "tx_index": DP["default_tx_index"],
                            "action": "detach from utxo",
                        },
                    },
                    {
                        "table": "credits",
                        "values": {
                            "utxo": None,
                            "address": ADDR[1],
                            "asset": "XCP",
                            "quantity": 100,
                            "event": "72a62abedd38d5f667150929c24dc1d7465dd81ab1502974814d20c1f65d871f",
                            "block_index": DP["default_block_index"],
                            "tx_index": DP["default_tx_index"],
                            "calling_function": "detach from utxo",
                        },
                    },
                ],
            },
            {
                "in": (
                    {
                        "fee": 10000,
                        "tx_hash": "72a62abedd38d5f667150929c24dc1d7465dd81ab1502974814d20c1f65d871f",
                        "data": b"d4f0433ba841038e2e16328445930dd7bca35309b14b0da4451c8f94c631368b8:1|mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns|XCP|100",
                        "source": ADDR[0],
                        "block_index": DP["default_block_index"],
                        "btc_amount": 5430,
                        "tx_index": DP["default_tx_index"],
                        "supported": 1,
                        "destination": ADDR[0],
                        "block_time": 310501000,
                        "block_hash": "46ac6d09237c7961199068fdd13f1508d755483e07c57a4c8f7ff18eb33a05c93ca6a86fa2e2af82fb77a5c337146bb37e279797a3d11970aec4693c46ea5a58",
                        "utxos_info": "4f0433ba841038e2e16328445930dd7bca35309b14b0da4451c8f94c631368b8:0 4f0433ba841038e2e16328445930dd7bca35309b14b0da4451c8f94c631368b8:2",
                    },
                ),
                "records": [
                    {
                        "table": "sends",
                        "values": {
                            "tx_index": DP["default_tx_index"],
                            "tx_hash": "72a62abedd38d5f667150929c24dc1d7465dd81ab1502974814d20c1f65d871f",
                            "block_index": DP["default_block_index"],
                            "status": "invalid: UTXO not in the transaction inputs",
                            "source": None,
                            "destination": None,
                            "asset": None,
                            "quantity": None,
                            "fee_paid": 0,
                        },
                    },
                ],
            },
        ],
        "move_assets": [
            {
                "in": (
                    {
                        "tx_index": DP["default_tx_index"],
                        "tx_hash": "72a62abedd38d5f667150929c24dc1d7465dd81ab1502974814d20c1f65d871f",
                        "block_index": DP["default_block_index"],
                        "utxos_info": f"{UTXO_2} {UTXO_3}",
                    },
                ),
                "records": [
                    {
                        "table": "debits",
                        "values": {
                            "utxo": UTXO_2,
                            "address": None,
                            "asset": "XCP",
                            "quantity": 100,
                            "event": "72a62abedd38d5f667150929c24dc1d7465dd81ab1502974814d20c1f65d871f",
                            "block_index": DP["default_block_index"] - 1,
                            "tx_index": DP["default_tx_index"],
                            "action": "utxo move",
                        },
                    },
                    {
                        "table": "credits",
                        "values": {
                            "utxo": UTXO_3,
                            "address": None,
                            "asset": "XCP",
                            "quantity": 100,
                            "event": "72a62abedd38d5f667150929c24dc1d7465dd81ab1502974814d20c1f65d871f",
                            "block_index": DP["default_block_index"] - 1,
                            "tx_index": DP["default_tx_index"],
                            "calling_function": "utxo move",
                        },
                    },
                    {
                        "table": "debits",
                        "values": {
                            "utxo": UTXO_2,
                            "address": None,
                            "asset": "DIVISIBLE",
                            "quantity": 1,
                            "event": "72a62abedd38d5f667150929c24dc1d7465dd81ab1502974814d20c1f65d871f",
                            "block_index": DP["default_block_index"] - 1,
                            "tx_index": DP["default_tx_index"],
                            "action": "utxo move",
                        },
                    },
                    {
                        "table": "credits",
                        "values": {
                            "utxo": UTXO_3,
                            "address": None,
                            "asset": "DIVISIBLE",
                            "quantity": 1,
                            "event": "72a62abedd38d5f667150929c24dc1d7465dd81ab1502974814d20c1f65d871f",
                            "block_index": DP["default_block_index"] - 1,
                            "tx_index": DP["default_tx_index"],
                            "calling_function": "utxo move",
                        },
                    },
                    {
                        "table": "sends",
                        "values": {
                            "tx_index": DP["default_tx_index"],
                            "tx_hash": "72a62abedd38d5f667150929c24dc1d7465dd81ab1502974814d20c1f65d871f",
                            "block_index": DP["default_block_index"],
                            "status": "valid",
                            "source": UTXO_2,
                            "destination": UTXO_3,
                            "asset": "XCP",
                            "quantity": 100,
                            "fee_paid": 0,
                        },
                    },
                    {
                        "table": "sends",
                        "values": {
                            "tx_index": DP["default_tx_index"],
                            "tx_hash": "72a62abedd38d5f667150929c24dc1d7465dd81ab1502974814d20c1f65d871f",
                            "block_index": DP["default_block_index"],
                            "status": "valid",
                            "source": UTXO_2,
                            "destination": UTXO_3,
                            "asset": "DIVISIBLE",
                            "quantity": 1,
                            "fee_paid": 0,
                        },
                    },
                ],
            }
        ],
    }
}
