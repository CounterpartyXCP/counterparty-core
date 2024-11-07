from counterpartycore.lib import exceptions

from ..params import (
    ADDR,
    DP,
)

UTXO_1 = "344dcc8909ca3a137630726d0071dfd2df4f7c855bac150c7d3a8367835c90bc:1"
UTXO_2 = "e219be68972de7df99122a0213d7be2f597c14fa48b55457a81641583099fea4:0"
UTXO_3 = "74501a157028760383ae4a8f79f6bce9ef64e60e883ac3285bc239a907c2b42c:0"

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
                        "utxos_info": "e219be68972de7df99122a0213d7be2f597c14fa48b55457a81641583099fea4:0 4f0433ba841038e2e16328445930dd7bca35309b14b0da4451c8f94c631368b8:2 2 ",
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
                            "source": "e219be68972de7df99122a0213d7be2f597c14fa48b55457a81641583099fea4:0",
                            "destination": ADDR[1],
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
                        "utxos_info": "e219be68972de7df99122a0213d7be2f597c14fa48b55457a81641583099fea4:0,74501a157028760383ae4a8f79f6bce9ef64e60e883ac3285bc239a907c2b42c:0 4f0433ba841038e2e16328445930dd7bca35309b14b0da4451c8f94c631368b8:2 2 ",
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
                            "source": "e219be68972de7df99122a0213d7be2f597c14fa48b55457a81641583099fea4:0",
                            "destination": ADDR[0],
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
                            "source": "74501a157028760383ae4a8f79f6bce9ef64e60e883ac3285bc239a907c2b42c:0",
                            "destination": ADDR[0],
                            "asset": "DIVISIBLE",
                            "quantity": 1,
                            "fee_paid": 0,
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
                        "utxos_info": "nobalance:0,e219be68972de7df99122a0213d7be2f597c14fa48b55457a81641583099fea4:0,74501a157028760383ae4a8f79f6bce9ef64e60e883ac3285bc239a907c2b42c:0 4f0433ba841038e2e16328445930dd7bca35309b14b0da4451c8f94c631368b8:2 2 ",
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
                            "source": "e219be68972de7df99122a0213d7be2f597c14fa48b55457a81641583099fea4:0",
                            "destination": ADDR[1],
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
                            "source": "74501a157028760383ae4a8f79f6bce9ef64e60e883ac3285bc239a907c2b42c:0",
                            "destination": ADDR[1],
                            "asset": "DIVISIBLE",
                            "quantity": 1,
                            "fee_paid": 0,
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
                        "utxos_info": "nobalance:0,e219be68972de7df99122a0213d7be2f597c14fa48b55457a81641583099fea4:0,74501a157028760383ae4a8f79f6bce9ef64e60e883ac3285bc239a907c2b42c:0 4f0433ba841038e2e16328445930dd7bca35309b14b0da4451c8f94c631368b8:2 2 ",
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
                            "source": "e219be68972de7df99122a0213d7be2f597c14fa48b55457a81641583099fea4:0",
                            "destination": ADDR[0],
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
                            "source": "74501a157028760383ae4a8f79f6bce9ef64e60e883ac3285bc239a907c2b42c:0",
                            "destination": ADDR[0],
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
