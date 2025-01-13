from counterpartycore.lib import exceptions
from counterpartycore.test.fixtures.params import ADDR, DP

SWEEP_VECTOR = {
    "sweep": {
        "validate": [
            {"in": (ADDR[6], ADDR[5], 1, None, DP["burn_start"]), "out": ([], 50000000.0)},
            {"in": (ADDR[6], ADDR[5], 2, None, DP["burn_start"]), "out": ([], 50000000.0)},
            {"in": (ADDR[6], ADDR[5], 3, None, DP["burn_start"]), "out": ([], 50000000.0)},
            {"in": (ADDR[6], ADDR[5], 1, "test", DP["burn_start"]), "out": ([], 50000000.0)},
            {"in": (ADDR[6], ADDR[5], 1, b"test", DP["burn_start"]), "out": ([], 50000000.0)},
            {
                "in": (ADDR[6], ADDR[5], 0, None, DP["burn_start"]),
                "out": (["must specify which kind of transfer in flags"], 50000000.0),
            },
            {
                "in": (ADDR[6], ADDR[6], 1, None, DP["burn_start"]),
                "out": (["destination cannot be the same as source"], 50000000.0),
            },
            {
                "in": (ADDR[6], ADDR[5], 8, None, DP["burn_start"]),
                "out": (["invalid flags 8"], 50000000.0),
            },
            {
                "in": (
                    ADDR[6],
                    ADDR[5],
                    1,
                    "012345678900123456789001234567890012345",
                    DP["burn_start"],
                ),
                "out": (["memo too long"], 50000000.0),
            },
            {
                "in": (ADDR[7], ADDR[5], 1, None, DP["burn_start"]),
                "out": (
                    ["insufficient XCP balance for sweep. Need 0.5 XCP for antispam fee"],
                    50000000.0,
                ),
            },
            {
                "in": (ADDR[8], ADDR[5], 1, None, DP["burn_start"]),
                "out": (
                    ["insufficient XCP balance for sweep. Need 0.5 XCP for antispam fee"],
                    50000000.0,
                ),
            },
        ],
        "compose": [
            {
                "in": (ADDR[6], ADDR[5], 1, None),
                "out": (
                    "mwtPsLQxW9xpm7gdLmwWvJK5ABdPUVJm42",
                    [],
                    b"\x00\x00\x00\x04o\x9c\x8d\x1fT\x05E\x1d\xe6\x07\x0b\xf1\xdb\x86\xabj\xcc\xb4\x95\xb6%\x01",
                ),
            },
            {
                "in": (ADDR[6], ADDR[5], 2, None),
                "out": (
                    "mwtPsLQxW9xpm7gdLmwWvJK5ABdPUVJm42",
                    [],
                    b"\x00\x00\x00\x04o\x9c\x8d\x1fT\x05E\x1d\xe6\x07\x0b\xf1\xdb\x86\xabj\xcc\xb4\x95\xb6%\x02",
                ),
            },
            {
                "in": (ADDR[6], ADDR[5], 3, None),
                "out": (
                    "mwtPsLQxW9xpm7gdLmwWvJK5ABdPUVJm42",
                    [],
                    b"\x00\x00\x00\x04o\x9c\x8d\x1fT\x05E\x1d\xe6\x07\x0b\xf1\xdb\x86\xabj\xcc\xb4\x95\xb6%\x03",
                ),
            },
            {
                "in": (ADDR[6], ADDR[5], 3, "test"),
                "out": (
                    "mwtPsLQxW9xpm7gdLmwWvJK5ABdPUVJm42",
                    [],
                    b"\x00\x00\x00\x04o\x9c\x8d\x1fT\x05E\x1d\xe6\x07\x0b\xf1\xdb\x86\xabj\xcc\xb4\x95\xb6%\x03test",
                ),
            },
            {
                "in": (ADDR[6], ADDR[5], 7, "cafebabe"),
                "out": (
                    "mwtPsLQxW9xpm7gdLmwWvJK5ABdPUVJm42",
                    [],
                    b"\x00\x00\x00\x04o\x9c\x8d\x1fT\x05E\x1d\xe6\x07\x0b\xf1\xdb\x86\xabj\xcc\xb4\x95\xb6%\x07\xca\xfe\xba\xbe",
                ),
            },
            {
                "in": (ADDR[8], ADDR[5], 1, None),
                "error": (
                    exceptions.ComposeError,
                    ["insufficient XCP balance for sweep. Need 0.5 XCP for antispam fee"],
                ),
            },
        ],
        "unpack": [
            {
                "in": (
                    b"o\x9c\x8d\x1fT\x05E\x1d\xe6\x07\x0b\xf1\xdb\x86\xabj\xcc\xb4\x95\xb6%\x01",
                ),
                "out": {"destination": ADDR[5], "flags": 1, "memo": None},
            },
            {
                "in": (
                    b"o\x9c\x8d\x1fT\x05E\x1d\xe6\x07\x0b\xf1\xdb\x86\xabj\xcc\xb4\x95\xb6%\x02",
                ),
                "out": {"destination": ADDR[5], "flags": 2, "memo": None},
            },
            {
                "in": (
                    b"o\x9c\x8d\x1fT\x05E\x1d\xe6\x07\x0b\xf1\xdb\x86\xabj\xcc\xb4\x95\xb6%\x03test",
                ),
                "out": {"destination": ADDR[5], "flags": 3, "memo": "test"},
            },
            {
                "in": (
                    b"o\x9c\x8d\x1fT\x05E\x1d\xe6\x07\x0b\xf1\xdb\x86\xabj\xcc\xb4\x95\xb6%\x07\xca\xfe\xba\xbe",
                ),
                "out": {"destination": ADDR[5], "flags": 7, "memo": b"\xca\xfe\xba\xbe"},
            },
        ],
        "parse": [
            {
                "mock_protocol_changes": {"sweep_send": True},
                "in": (
                    {
                        "tx_hash": "db6d9052b576d973196363e11163d492f50926c2f1d1efd67b3d999817b0d04d",
                        "source": ADDR[6],
                        "supported": 1,
                        "block_index": DP["default_block_index"],
                        "fee": 10000,
                        "block_time": 155409000,
                        "block_hash": DP["default_block_hash"],
                        "btc_amount": 17630,
                        "tx_index": DP["default_tx_index"],
                        "destination": ADDR[5],
                        "data": b"\x00\x00\x00\x03o\x9c\x8d\x1fT\x05E\x1d\xe6\x07\x0b\xf1\xdb\x86\xabj\xcc\xb4\x95\xb6%\x01",
                    },
                ),
                "records": [
                    {
                        "table": "sweeps",
                        "values": {
                            "block_index": DP["default_block_index"],
                            "destination": ADDR[5],
                            "source": ADDR[6],
                            "status": "valid",
                            "flags": 1,
                            "tx_hash": "db6d9052b576d973196363e11163d492f50926c2f1d1efd67b3d999817b0d04d",
                            "tx_index": DP["default_tx_index"],
                        },
                    },
                    {
                        "table": "credits",
                        "values": {
                            "address": ADDR[5],
                            "asset": "XCP",
                            "block_index": DP["default_block_index"],
                            "calling_function": "sweep",
                            "event": "db6d9052b576d973196363e11163d492f50926c2f1d1efd67b3d999817b0d04d",
                            "quantity": 92899122099,
                        },
                    },
                    {
                        "table": "debits",
                        "values": {
                            "action": "sweep",
                            "address": ADDR[6],
                            "asset": "XCP",
                            "block_index": DP["default_block_index"],
                            "event": "db6d9052b576d973196363e11163d492f50926c2f1d1efd67b3d999817b0d04d",
                            "quantity": 92899122099,
                        },
                    },
                    {
                        "table": "credits",
                        "values": {
                            "address": ADDR[5],
                            "asset": "LOCKEDPREV",
                            "block_index": DP["default_block_index"],
                            "calling_function": "sweep",
                            "event": "db6d9052b576d973196363e11163d492f50926c2f1d1efd67b3d999817b0d04d",
                            "quantity": 1000,
                        },
                    },
                    {
                        "table": "debits",
                        "values": {
                            "action": "sweep",
                            "address": ADDR[6],
                            "asset": "LOCKEDPREV",
                            "block_index": DP["default_block_index"],
                            "event": "db6d9052b576d973196363e11163d492f50926c2f1d1efd67b3d999817b0d04d",
                            "quantity": 1000,
                        },
                    },
                ],
            },
            {
                "mock_protocol_changes": {"sweep_send": True},
                "in": (
                    {
                        "tx_hash": "db6d9052b576d973196363e11163d492f50926c2f1d1efd67b3d999817b0d04d",
                        "source": ADDR[6],
                        "supported": 1,
                        "block_index": DP["default_block_index"],
                        "fee": 10000,
                        "block_time": 155409000,
                        "block_hash": DP["default_block_hash"],
                        "btc_amount": 17630,
                        "tx_index": DP["default_tx_index"],
                        "destination": ADDR[5],
                        "data": b"\x00\x00\x00\x03o\x9c\x8d\x1fT\x05E\x1d\xe6\x07\x0b\xf1\xdb\x86\xabj\xcc\xb4\x95\xb6%\x02",
                    },
                ),
                "records": [
                    {
                        "table": "sweeps",
                        "values": {
                            "block_index": DP["default_block_index"],
                            "destination": ADDR[5],
                            "source": ADDR[6],
                            "status": "valid",
                            "flags": 2,
                            "tx_hash": "db6d9052b576d973196363e11163d492f50926c2f1d1efd67b3d999817b0d04d",
                            "tx_index": DP["default_tx_index"],
                        },
                    },
                    {
                        "table": "issuances",
                        "values": {
                            "quantity": 0,
                            "asset_longname": None,
                            "issuer": ADDR[5],
                            "status": "valid",
                            "locked": 0,
                            "asset": "LOCKEDPREV",
                            "fee_paid": 0,
                            "callable": 0,
                            "call_date": 0,
                            "call_price": 0.0,
                            "tx_hash": "db6d9052b576d973196363e11163d492f50926c2f1d1efd67b3d999817b0d04d",
                            "description": "changed",
                            "divisible": 1,
                            "source": ADDR[6],
                            "block_index": DP["default_block_index"],
                            "tx_index": DP["default_tx_index"],
                            "transfer": True,
                        },
                    },
                ],
            },
        ],
    },
}
