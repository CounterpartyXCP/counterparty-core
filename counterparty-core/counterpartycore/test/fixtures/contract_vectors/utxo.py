from counterpartycore.lib import config, exceptions

from ..params import (
    ADDR,
    DP,
)

UTXO_1 = "344dcc8909ca3a137630726d0071dfd2df4f7c855bac150c7d3a8367835c90bc:1"

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
                    "insufficient funds",
                    "If source is a UTXO, destination must be an address",
                ],
            },
            {
                "in": (ADDR[0], UTXO_1, "XCP", 0),
                "out": ["quantity must be greater than zero"],
            },
            {
                "in": (ADDR[0], UTXO_1, "XCP", 99999999999999),
                "out": ["insufficient funds"],
            },
            {
                "in": (
                    ADDR[0],
                    UTXO_1,
                    "BTC",
                    100,
                ),
                "out": ["cannot send bitcoins", "insufficient funds"],
            },
            {
                "in": (
                    ADDR[0],
                    UTXO_1,
                    "XCP",
                    config.MAX_INT + 1,
                ),
                "out": ["integer overflow", "insufficient funds"],
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
                    "344dcc8909ca3a137630726d0071dfd2df4f7c855bac150c7d3a8367835c90bc:1",
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
                        },
                    },
                    {
                        "table": "messages",
                        "values": {
                            "block_index": DP["default_block_index"],
                            "command": "insert",
                            "category": "sends",
                            "bindings": '{"asset":"XCP","block_index":310704,"destination":"344dcc8909ca3a137630726d0071dfd2df4f7c855bac150c7d3a8367835c90bc:1","quantity":100,"source":"mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc","status":"valid","tx_hash":"72a62abedd38d5f667150929c24dc1d7465dd81ab1502974814d20c1f65d871f","tx_index":705}',
                            "event": "ATTACH_TO_UTXO",
                        },
                    },
                ],
            }
        ],
    }
}
