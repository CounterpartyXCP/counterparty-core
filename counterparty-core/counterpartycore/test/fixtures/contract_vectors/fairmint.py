from counterpartycore.lib import exceptions

from ..params import (
    ADDR,
)
from ..params import DEFAULT_PARAMS as DP

# source
# asset
# quantity,

FAIRMINT_VECTOR = {
    "fairmint": {
        "validate": [
            {
                "in": (
                    ADDR[1],  # source
                    "FREEFAIRMIN",  # asset
                    0,  # quantity
                ),
                "out": ([]),
            },
            {
                "in": (
                    ADDR[1],  # source
                    "PAIDFAIRMIN",  # asset
                    0,  # quantity
                ),
                "out": (["Quantity must be greater than 0"]),
            },
            {
                "in": (
                    ADDR[1],  # source
                    "RAIDFAIRMIN",  # asset
                    11,  # quantity
                ),
                "out": (["Quantity exceeds maximum allowed per transaction"]),
            },
            {
                "in": (
                    ADDR[1],  # source
                    "QAIDFAIRMIN",  # asset
                    35,  # quantity
                ),
                "out": (["asset supply quantity exceeds hard cap"]),
            },
        ],
        "compose": [
            {
                "in": (
                    ADDR[1],  # source
                    "FREEFAIRMIN",  # asset
                    0,  # quantity
                ),
                "out": (
                    "mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns",
                    [],
                    b"[FREEFAIRMIN|0",
                ),
            },
            {
                "in": (
                    ADDR[1],  # source
                    "QAIDFAIRMIN",  # asset
                    35,  # quantity
                ),
                "error": (exceptions.ComposeError, ["asset supply quantity exceeds hard cap"]),
            },
        ],
        "unpack": [
            {"in": (b"FREEFAIRMIN|0", False), "out": ("FREEFAIRMIN", 0)},
            {"in": (b"FREEFAIRMIN|0", True), "out": {"asset": "FREEFAIRMIN", "quantity": 0}},
        ],
        "parse": [
            {
                "in": (
                    {
                        "fee": 10000,
                        "tx_hash": "72a62abedd38d5f667150929c24dc1d7465dd81ab1502974814d20c1f65d871f",
                        "data": b"[FREEFAIRMIN|0",
                        "source": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc",
                        "block_index": DP["default_block_index"],
                        "btc_amount": 5430,
                        "tx_index": DP["default_tx_index"],
                        "supported": 1,
                        "destination": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc",
                        "block_time": 310501000,
                        "block_hash": "46ac6d09237c7961199068fdd13f1508d755483e07c57a4c8f7ff18eb33a05c93ca6a86fa2e2af82fb77a5c337146bb37e279797a3d11970aec4693c46ea5a58",
                    },
                ),
                "records": [
                    {
                        "table": "fairmints",
                        "values": {
                            "tx_hash": "72a62abedd38d5f667150929c24dc1d7465dd81ab1502974814d20c1f65d871f",
                            "block_index": DP["default_block_index"],
                            "source": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc",
                            "fairminter_tx_hash": "83b96c0f72fea31403567852f2bdb4840ffdf18bda2e82df4f27aad633830e29",
                            "asset": "FREEFAIRMIN",
                            "earn_quantity": 10,
                            "paid_quantity": 0,
                            "commission": 0,
                            "status": "valid",
                        },
                    },
                    {
                        "table": "issuances",
                        "values": {
                            "tx_hash": "72a62abedd38d5f667150929c24dc1d7465dd81ab1502974814d20c1f65d871f",
                            "block_index": DP["default_block_index"],
                            "asset": "FREEFAIRMIN",
                            "quantity": 10,
                            "divisible": True,
                            "source": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc",
                            "issuer": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc",
                            "transfer": False,
                            "callable": False,
                            "call_date": 0,
                            "call_price": 0,
                            "description": "",
                            "fee_paid": 0,
                            "locked": False,
                            "reset": False,
                            "status": "valid",
                            "asset_longname": "",
                            "fair_minting": True,
                        },
                    },
                    {
                        "table": "credits",
                        "values": {
                            "block_index": DP["default_block_index"],
                            "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc",
                            "asset": "FREEFAIRMIN",
                            "quantity": 10,
                            "calling_function": "fairmint",
                            "event": "72a62abedd38d5f667150929c24dc1d7465dd81ab1502974814d20c1f65d871f",
                        },
                    },
                ],
            },
            {
                "in": (
                    {
                        "fee": 10000,
                        "tx_hash": "72a62abedd38d5f667150929c24dc1d7465dd81ab1502974814d20c1f65d871f",
                        "data": b"[QAIDFAIRMIN|10",
                        "source": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc",
                        "block_index": DP["default_block_index"],
                        "btc_amount": 5430,
                        "tx_index": DP["default_tx_index"],
                        "supported": 1,
                        "destination": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc",
                        "block_time": 310501000,
                        "block_hash": "46ac6d09237c7961199068fdd13f1508d755483e07c57a4c8f7ff18eb33a05c93ca6a86fa2e2af82fb77a5c337146bb37e279797a3d11970aec4693c46ea5a58",
                    },
                ),
                "records": [
                    {
                        "table": "fairmints",
                        "values": {
                            "tx_hash": "72a62abedd38d5f667150929c24dc1d7465dd81ab1502974814d20c1f65d871f",
                            "block_index": DP["default_block_index"],
                            "source": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc",
                            "fairminter_tx_hash": "f0bb460f8ff563f8ed29064dbbd03a325110a7865fcb8f22068789d3fd2413cb",
                            "asset": "QAIDFAIRMIN",
                            "earn_quantity": 5,
                            "paid_quantity": 100,
                            "commission": 5,
                            "status": "valid",
                        },
                    },
                    {
                        "table": "credits",
                        "values": {
                            "block_index": DP["default_block_index"],
                            "address": "mvCounterpartyXXXXXXXXXXXXXXW24Hef",
                            "asset": "QAIDFAIRMIN",
                            "quantity": 10,
                            "calling_function": "escrowed fairmint",
                            "event": "72a62abedd38d5f667150929c24dc1d7465dd81ab1502974814d20c1f65d871f",
                        },
                    },
                    {
                        "table": "credits",
                        "values": {
                            "block_index": DP["default_block_index"],
                            "address": "mvCounterpartyXXXXXXXXXXXXXXW24Hef",
                            "asset": "XCP",
                            "quantity": 100,
                            "calling_function": "escrowed fairmint",
                            "event": "72a62abedd38d5f667150929c24dc1d7465dd81ab1502974814d20c1f65d871f",
                        },
                    },
                ],
            },
        ],
    }
}
