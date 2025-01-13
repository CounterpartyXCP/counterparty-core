from counterpartycore.lib import exceptions
from counterpartycore.test.fixtures.params import (
    ADDR,
    DP,
)

UTXO_1 = "344dcc8909ca3a137630726d0071dfd2df4f7c855bac150c7d3a8367835c90bc:1"
UTXO_2 = "1e9d0b5cc5b3f56cc59c0e8f3268d6ad10f79337aaf19081580c486caeb4cf53:0"
UTXO_3 = "7b4bb2e22f2a6d03933266f4ad34a4f7bf3ef7d2d4aeeea81edc5de59493eb7c:0"

DETACH_VECTOR = {
    "detach": {
        "validate": [
            {
                "in": (UTXO_1,),
                "out": [],
            },
            {
                "in": (ADDR[0],),
                "out": ["source must be a UTXO"],
            },
        ],
        "compose": [
            {
                "in": (
                    UTXO_2,
                    ADDR[1],
                ),
                "out": (
                    UTXO_2,
                    [],
                    b"fmtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns",
                ),
            },
            {
                "in": (UTXO_2,),
                "out": (
                    UTXO_2,
                    [],
                    b"f0",
                ),
            },
            {
                "in": (UTXO_1, UTXO_1),
                "error": (exceptions.ComposeError, "destination must be an address"),
            },
        ],
        "unpack": [
            {
                "in": (b"mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns",),
                "out": "mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns",
            },
            {
                "in": (b"0",),
                "out": None,
            },
            {
                "in": (b"mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns", True),
                "out": {"destination": "mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns"},
            },
        ],
        "parse": [
            {
                "in": (
                    {
                        "fee": 10000,
                        "tx_hash": "72a62abedd38d5f667150929c24dc1d7465dd81ab1502974814d20c1f65d871f",
                        "data": b"fmtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns",  # ADDR[1]
                        "source": ADDR[0],
                        "block_index": DP["default_block_index"],
                        "btc_amount": 5430,
                        "tx_index": DP["default_tx_index"],
                        "supported": 1,
                        "destination": ADDR[0],
                        "block_time": 310501000,
                        "block_hash": "46ac6d09237c7961199068fdd13f1508d755483e07c57a4c8f7ff18eb33a05c93ca6a86fa2e2af82fb77a5c337146bb37e279797a3d11970aec4693c46ea5a58",
                        "utxos_info": "1e9d0b5cc5b3f56cc59c0e8f3268d6ad10f79337aaf19081580c486caeb4cf53:0 4f0433ba841038e2e16328445930dd7bca35309b14b0da4451c8f94c631368b8:2 2 ",
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
                            "source": "1e9d0b5cc5b3f56cc59c0e8f3268d6ad10f79337aaf19081580c486caeb4cf53:0",
                            "source_address": ADDR[0],
                            "destination": ADDR[1],
                            "asset": "XCP",
                            "quantity": 100,
                            "fee_paid": 0,
                            "send_type": "detach",
                        },
                    },
                ],
            },
            {
                "in": (
                    {
                        "fee": 10000,
                        "tx_hash": "72a62abedd38d5f667150929c24dc1d7465dd81ab1502974814d20c1f65d871f",
                        "data": b"f0",
                        "source": ADDR[0],
                        "block_index": DP["default_block_index"],
                        "btc_amount": 5430,
                        "tx_index": DP["default_tx_index"],
                        "supported": 1,
                        "destination": ADDR[0],
                        "block_time": 310501000,
                        "block_hash": "46ac6d09237c7961199068fdd13f1508d755483e07c57a4c8f7ff18eb33a05c93ca6a86fa2e2af82fb77a5c337146bb37e279797a3d11970aec4693c46ea5a58",
                        "utxos_info": "1e9d0b5cc5b3f56cc59c0e8f3268d6ad10f79337aaf19081580c486caeb4cf53:0,7b4bb2e22f2a6d03933266f4ad34a4f7bf3ef7d2d4aeeea81edc5de59493eb7c:0 4f0433ba841038e2e16328445930dd7bca35309b14b0da4451c8f94c631368b8:2 2 ",
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
                            "source": "1e9d0b5cc5b3f56cc59c0e8f3268d6ad10f79337aaf19081580c486caeb4cf53:0",
                            "source_address": ADDR[0],
                            "destination": ADDR[0],
                            "asset": "XCP",
                            "quantity": 100,
                            "fee_paid": 0,
                            "send_type": "detach",
                        },
                    },
                    {
                        "table": "sends",
                        "values": {
                            "tx_index": DP["default_tx_index"],
                            "tx_hash": "72a62abedd38d5f667150929c24dc1d7465dd81ab1502974814d20c1f65d871f",
                            "block_index": DP["default_block_index"],
                            "status": "valid",
                            "source": "7b4bb2e22f2a6d03933266f4ad34a4f7bf3ef7d2d4aeeea81edc5de59493eb7c:0",
                            "source_address": ADDR[0],
                            "destination": ADDR[0],
                            "asset": "DIVISIBLE",
                            "quantity": 1,
                            "fee_paid": 0,
                            "send_type": "detach",
                        },
                    },
                ],
            },
            {
                "in": (
                    {
                        "fee": 10000,
                        "tx_hash": "72a62abedd38d5f667150929c24dc1d7465dd81ab1502974814d20c1f65d871f",
                        "data": b"fmtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns",  # ADDR[1]
                        "source": ADDR[0],
                        "block_index": DP["default_block_index"],
                        "btc_amount": 5430,
                        "tx_index": DP["default_tx_index"],
                        "supported": 1,
                        "destination": ADDR[0],
                        "block_time": 310501000,
                        "block_hash": "46ac6d09237c7961199068fdd13f1508d755483e07c57a4c8f7ff18eb33a05c93ca6a86fa2e2af82fb77a5c337146bb37e279797a3d11970aec4693c46ea5a58",
                        "utxos_info": "nobalance:0,1e9d0b5cc5b3f56cc59c0e8f3268d6ad10f79337aaf19081580c486caeb4cf53:0,7b4bb2e22f2a6d03933266f4ad34a4f7bf3ef7d2d4aeeea81edc5de59493eb7c:0 4f0433ba841038e2e16328445930dd7bca35309b14b0da4451c8f94c631368b8:2 2 ",
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
                            "source": "1e9d0b5cc5b3f56cc59c0e8f3268d6ad10f79337aaf19081580c486caeb4cf53:0",
                            "source_address": ADDR[0],
                            "destination": ADDR[1],
                            "asset": "XCP",
                            "quantity": 100,
                            "fee_paid": 0,
                            "send_type": "detach",
                        },
                    },
                    {
                        "table": "sends",
                        "values": {
                            "tx_index": DP["default_tx_index"],
                            "tx_hash": "72a62abedd38d5f667150929c24dc1d7465dd81ab1502974814d20c1f65d871f",
                            "block_index": DP["default_block_index"],
                            "status": "valid",
                            "source": "7b4bb2e22f2a6d03933266f4ad34a4f7bf3ef7d2d4aeeea81edc5de59493eb7c:0",
                            "source_address": ADDR[0],
                            "destination": ADDR[1],
                            "asset": "DIVISIBLE",
                            "quantity": 1,
                            "fee_paid": 0,
                            "send_type": "detach",
                        },
                    },
                ],
            },
            {
                "in": (
                    {
                        "fee": 10000,
                        "tx_hash": "72a62abedd38d5f667150929c24dc1d7465dd81ab1502974814d20c1f65d871f",
                        "data": b"fINVALID_ADDRESS",  # => ADDR[0]
                        "source": ADDR[0],
                        "block_index": DP["default_block_index"],
                        "btc_amount": 5430,
                        "tx_index": DP["default_tx_index"],
                        "supported": 1,
                        "destination": ADDR[0],
                        "block_time": 310501000,
                        "block_hash": "46ac6d09237c7961199068fdd13f1508d755483e07c57a4c8f7ff18eb33a05c93ca6a86fa2e2af82fb77a5c337146bb37e279797a3d11970aec4693c46ea5a58",
                        "utxos_info": "nobalance:0,1e9d0b5cc5b3f56cc59c0e8f3268d6ad10f79337aaf19081580c486caeb4cf53:0,7b4bb2e22f2a6d03933266f4ad34a4f7bf3ef7d2d4aeeea81edc5de59493eb7c:0 4f0433ba841038e2e16328445930dd7bca35309b14b0da4451c8f94c631368b8:2 2 ",
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
                            "source": "1e9d0b5cc5b3f56cc59c0e8f3268d6ad10f79337aaf19081580c486caeb4cf53:0",
                            "source_address": ADDR[0],
                            "destination": ADDR[0],
                            "asset": "XCP",
                            "quantity": 100,
                            "fee_paid": 0,
                            "send_type": "detach",
                        },
                    },
                    {
                        "table": "sends",
                        "values": {
                            "tx_index": DP["default_tx_index"],
                            "tx_hash": "72a62abedd38d5f667150929c24dc1d7465dd81ab1502974814d20c1f65d871f",
                            "block_index": DP["default_block_index"],
                            "status": "valid",
                            "source": "7b4bb2e22f2a6d03933266f4ad34a4f7bf3ef7d2d4aeeea81edc5de59493eb7c:0",
                            "source_address": ADDR[0],
                            "destination": ADDR[0],
                            "asset": "DIVISIBLE",
                            "quantity": 1,
                            "fee_paid": 0,
                            "send_type": "detach",
                        },
                    },
                ],
            },
        ],
    },
}
