from ..params import (
    DP,
)

UTXO_1 = "344dcc8909ca3a137630726d0071dfd2df4f7c855bac150c7d3a8367835c90bc:1"
UTXO_2 = "57be7a922f829587d929c39a595044a9b848c1a961d65b1b412ccb382e861d3e:0"
UTXO_3 = "b55b034f8a10faa953f2f156c9b00a277ba7840c6d065e9a7767a6fe22636ce2:0"

MOVE_VECTOR = {
    "move": {
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
                ],
            },
            {
                "in": (
                    {
                        "tx_index": DP["default_tx_index"],
                        "tx_hash": "72a62abedd38d5f667150929c24dc1d7465dd81ab1502974814d20c1f65d871f",
                        "block_index": DP["default_block_index"],
                        "utxos_info": f"{UTXO_3} {UTXO_1}",
                    },
                ),
                "records": [
                    {
                        "table": "debits",
                        "values": {
                            "utxo": UTXO_3,
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
                            "utxo": UTXO_1,
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
                            "source": UTXO_3,
                            "destination": UTXO_1,
                            "asset": "DIVISIBLE",
                            "quantity": 1,
                            "fee_paid": 0,
                        },
                    },
                ],
            },
        ],
    },
}
