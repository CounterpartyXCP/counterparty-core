from ..params import (
    ADDR,
    DP,
)

UTXO_1 = "344dcc8909ca3a137630726d0071dfd2df4f7c855bac150c7d3a8367835c90bc:1"
UTXO_2 = "52e45e01cbe79b442630303fac0372aaf6fbe102ff4dd07ca6be01ba8f3c41b4:0"
UTXO_3 = "ea0962df1a71c3d76e08ee80c7a24b2ea670e31639c39cd897fca3bc008e81a0:0"

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
                            "source_address": ADDR[0],
                            "destination": UTXO_3,
                            "destination_address": ADDR[0],
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
                            "source_address": ADDR[0],
                            "destination": UTXO_1,
                            "destination_address": ADDR[0],
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
