from counterpartycore.lib import exceptions
from counterpartycore.test.fixtures.params import ADDR, DP, P2SH_ADDR

DESTROY_VECTOR = {
    "destroy": {
        "validate": [
            {"in": (ADDR[0], None, "XCP", 1), "out": None},
            {"in": (P2SH_ADDR[0], None, "XCP", 1), "out": None},
            {
                "in": (ADDR[0], None, "foobar", 1),
                "error": (exceptions.ValidateError, "asset invalid"),
            },
            {
                "in": (ADDR[0], ADDR[1], "XCP", 1),
                "error": (exceptions.ValidateError, "destination exists"),
            },
            {
                "in": (ADDR[0], None, "BTC", 1),
                "error": (exceptions.ValidateError, "cannot destroy BTC"),
            },
            {
                "in": (ADDR[0], None, "XCP", 1.1),
                "error": (exceptions.ValidateError, "quantity not integer"),
            },
            {
                "in": (ADDR[0], None, "XCP", 2**63),
                "error": (exceptions.ValidateError, "integer overflow, quantity too large"),
            },
            {
                "in": (ADDR[0], None, "XCP", -1),
                "error": (exceptions.ValidateError, "quantity negative"),
            },
            {
                "in": (ADDR[0], None, "XCP", 2**62),
                "error": (exceptions.BalanceError, "balance insufficient"),
            },
        ],
        "pack": [
            {
                "in": ("XCP", 1, bytes(9999999)),
                "out": b"\x00\x00\x00n\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00",
            }
        ],
        #'unpack': [{
        #    'in': (b'\x00\x00\x00n\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x00\x00\x00\x00',),
        #    'error': (exceptions.UnpackError, 'could not unpack')
        # }],
        "compose": [
            {
                "in": (ADDR[0], "XCP", 1, bytes(9999999)),
                "out": (
                    ADDR[0],
                    [],
                    b"\x00\x00\x00n\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00",
                ),
            },
            {
                "in": (ADDR[0], "XCP", 1, b"WASTE"),
                "out": (
                    ADDR[0],
                    [],
                    b"\x00\x00\x00n\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x00\x00\x00\x01WASTE",
                ),
            },
            {
                "in": (ADDR[0], "XCP", 1, b"WASTEEEEE"),
                "out": (
                    ADDR[0],
                    [],
                    b"\x00\x00\x00n\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x00\x00\x00\x01WASTEEEEE",
                ),
            },
            {
                "in": (ADDR[0], "PARENT.already.issued", 1, b"WASTEEEEE"),
                "out": (
                    ADDR[0],
                    [],
                    b"\x00\x00\x00n\x01S\x08!g\x1b\x10e\x00\x00\x00\x00\x00\x00\x00\x01WASTEEEEE",
                ),
            },
        ],
        "parse": [
            {
                "in": (
                    {
                        "tx_hash": "db6d9052b576d973196363e11163d492f50926c2f1d1efd67b3d999817b0d04d",
                        "source": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc",
                        "supported": 1,
                        "block_index": DP["default_block_index"],
                        "fee": 10000,
                        "block_time": 155409000,
                        "block_hash": DP["default_block_hash"],
                        "btc_amount": 7800,
                        "destination": None,
                        "data": b"\x00\x00\x00n\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x00\x00\x00\x01WASTE\x00\x00\x00",
                        "tx_index": DP["default_tx_index"],
                    },
                ),
                "records": [
                    {
                        "table": "destructions",
                        "values": {
                            "asset": "XCP",
                            "block_index": DP["default_block_index"],
                            "quantity": 1,
                            "source": ADDR[0],
                            "status": "valid",
                            "tag": b"WASTE\x00\x00\x00",
                            "tx_hash": "db6d9052b576d973196363e11163d492f50926c2f1d1efd67b3d999817b0d04d",
                            "tx_index": DP["default_tx_index"],
                        },
                    },
                ],
            },
            {
                "in": (
                    {
                        "tx_hash": "db6d9052b576d973196363e11163d492f50926c2f1d1efd67b3d999817b0d04d",
                        "source": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc",
                        "supported": 1,
                        "block_index": DP["default_block_index"],
                        "fee": 10000,
                        "block_time": 155409000,
                        "block_hash": DP["default_block_hash"],
                        "btc_amount": 7800,
                        "destination": ADDR[1],
                        "data": b"\x00\x00\x00n\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x00\x00\x00\x01WASTE\x00\x00\x00",
                        "tx_index": DP["default_tx_index"],
                    },
                ),
                "records": [
                    {
                        "table": "destructions",
                        "values": {
                            "asset": "XCP",
                            "block_index": DP["default_block_index"],
                            "quantity": 1,
                            "source": ADDR[0],
                            "status": "invalid: destination exists",
                            "tag": b"WASTE\x00\x00\x00",
                            "tx_hash": "db6d9052b576d973196363e11163d492f50926c2f1d1efd67b3d999817b0d04d",
                            "tx_index": DP["default_tx_index"],
                        },
                    },
                ],
            },
        ],
    },
}
