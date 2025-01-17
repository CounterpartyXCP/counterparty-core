from counterpartycore.lib import config, exceptions
from counterpartycore.test.fixtures.params import (
    ADDR,
)
from counterpartycore.test.fixtures.params import DEFAULT_PARAMS as DP

DISPENSER_VECTOR = {
    "dispenser": {
        "validate": [
            {
                "in": (ADDR[0], config.XCP, 100, 100, 100, 0, None, DP["burn_start"], None),
                "out": (1, None),
            },
            {
                "in": (ADDR[0], config.XCP, 200, 100, 100, 0, None, DP["burn_start"], None),
                "out": (None, ["escrow_quantity must be greater or equal than give_quantity"]),
            },
            {
                "in": (ADDR[0], config.BTC, 100, 100, 100, 0, None, DP["burn_start"], None),
                "out": (None, [f"cannot dispense {config.BTC}"]),
            },
            {
                "in": (ADDR[0], config.XCP, 100, 100, 100, 5, None, DP["burn_start"], None),
                "out": (None, ["invalid status 5"]),
            },
            {
                "in": (ADDR[0], "PARENT", 100, 1000000000, 100, 0, None, DP["burn_start"], None),
                "out": (
                    None,
                    ["address doesn't have enough balance of PARENT (100000000 < 1000000000)"],
                ),
            },
            {
                "in": (ADDR[5], config.XCP, 100, 100, 120, 0, None, DP["burn_start"], None),
                "out": (
                    None,
                    [
                        f"address has a dispenser already opened for asset {config.XCP} with a different mainchainrate"
                    ],
                ),
            },
            {
                "in": (ADDR[5], config.XCP, 120, 120, 100, 0, None, DP["burn_start"], None),
                "out": (
                    None,
                    [
                        f"address has a dispenser already opened for asset {config.XCP} with a different give_quantity"
                    ],
                ),
            },
            {
                "in": (ADDR[0], "PARENT", 0, 0, 0, 10, None, DP["burn_start"], None),
                "out": (None, ["address doesn't have an open dispenser for asset PARENT"]),
            },
            {
                "in": (
                    ADDR[0],
                    config.XCP,
                    config.MAX_INT + 1,
                    100,
                    100,
                    0,
                    None,
                    DP["burn_start"],
                    None,
                ),
                "out": (
                    None,
                    [
                        "escrow_quantity must be greater or equal than give_quantity",
                        "integer overflow",
                    ],
                ),
            },
            {
                "in": (
                    ADDR[0],
                    config.XCP,
                    100,
                    config.MAX_INT + 1,
                    100,
                    0,
                    None,
                    DP["burn_start"],
                    None,
                ),
                "out": (
                    None,
                    [
                        "address doesn't have enough balance of XCP (91674999900 < 9223372036854775808)",
                        "integer overflow",
                    ],
                ),
            },
            {
                "in": (
                    ADDR[0],
                    config.XCP,
                    100,
                    100,
                    config.MAX_INT + 1,
                    0,
                    None,
                    DP["burn_start"],
                    None,
                ),
                "out": (None, ["integer overflow"]),
            },
            {
                "in": (ADDR[0], config.XCP, 100, 100, 100, 0, ADDR[5], DP["burn_start"], None),
                "out": (None, ["dispenser must be created by source"]),
            },
        ],
        "compose": [
            {
                "in": (ADDR[0], config.XCP, 100, 100, 100, 0),
                "out": (
                    ADDR[0],
                    [],
                    b"\x00\x00\x00\x0c\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x00\x00\x00d\x00\x00\x00\x00\x00\x00\x00d\x00\x00\x00\x00\x00\x00\x00d\x00",
                ),
            },
            {
                "in": (ADDR[5], config.XCP, 0, 0, 0, 10),
                "out": (
                    ADDR[5],
                    [],
                    b"\x00\x00\x00\x0c\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\n",
                ),
            },
            {
                "in": (ADDR[0], "PARENT", 100, 10000, 2345, 0),
                "out": (
                    ADDR[0],
                    [],
                    b"\x00\x00\x00\x0c\x00\x00\x00\x00\n\xa4\t}\x00\x00\x00\x00\x00\x00\x00d\x00\x00\x00\x00\x00\x00'\x10\x00\x00\x00\x00\x00\x00\t)\x00",
                ),
            },
            {
                "in": (ADDR[0], config.XCP, config.MAX_INT + 1, 100, 100, 0),
                "error": (
                    exceptions.ComposeError,
                    [
                        "escrow_quantity must be greater or equal than give_quantity",
                        "integer overflow",
                    ],
                ),
            },
            {
                "in": (ADDR[0], "PARENT", 100, 10000, 2345, 0, ADDR[5]),
                "error": (
                    exceptions.ComposeError,
                    ["dispenser must be created by source"],
                ),
            },
        ],
        "parse": [
            {
                "mock_protocol_changes": {"dispensers": True},
                "in": (
                    {
                        "tx_hash": "db6d9052b576d973196363e11163d492f50926c2f1d1efd67b3d999817b0d04d",
                        "source": ADDR[0],
                        "supported": 1,
                        "block_index": DP["default_block_index"],
                        "fee": 10000,
                        "block_time": 155409000,
                        "block_hash": DP["default_block_hash"],
                        "btc_amount": 17630,
                        "tx_index": DP["default_tx_index"],
                        "destination": ADDR[0],
                        "data": b"\x00\x00\x00\x0c\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x00\x00\x00d\x00\x00\x00\x00\x00\x00\x00d\x00\x00\x00\x00\x00\x00\x00d\x00",
                    },
                ),
                "records": [
                    {
                        "table": "dispensers",
                        "values": {
                            "tx_index": DP["default_tx_index"],
                            "tx_hash": "db6d9052b576d973196363e11163d492f50926c2f1d1efd67b3d999817b0d04d",
                            "block_index": DP["default_block_index"],
                            "source": ADDR[0],
                            "asset": config.XCP,
                            "give_quantity": 100,
                            "escrow_quantity": 100,
                            "satoshirate": 100,
                            "status": 0,
                            "give_remaining": 100,
                        },
                    },
                    {
                        "table": "debits",
                        "values": {
                            "action": "open dispenser",
                            "address": ADDR[0],
                            "asset": config.XCP,
                            "block_index": DP["default_block_index"],
                            "event": "db6d9052b576d973196363e11163d492f50926c2f1d1efd67b3d999817b0d04d",
                            "quantity": 100,
                        },
                    },
                ],
            },
            {
                "mock_protocol_changes": {"dispensers": True},
                "in": (
                    {
                        "tx_hash": "db6d9052b576d973196363e11163d492f50926c2f1d1efd67b3d999817b0d04d",
                        "source": ADDR[5],
                        "supported": 1,
                        "block_index": DP["default_block_index"],
                        "fee": 10000,
                        "block_time": 155409000,
                        "block_hash": DP["default_block_hash"],
                        "btc_amount": 17630,
                        "tx_index": DP["default_tx_index"],
                        "destination": ADDR[5],
                        "data": b"\x00\x00\x00\x0c\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\n",
                    },
                ),
                "records": [
                    {
                        "table": "dispensers",
                        "values": {  # Some values here correspond to the original TX that opened the dispenser
                            "tx_index": 108,
                            "tx_hash": "0d53631a5f5b18632791ee65aa9723b29b57eb5a6e12d034804b786d99102a03",
                            "block_index": DP["default_block_index"],
                            "source": ADDR[5],
                            "asset": config.XCP,
                            "give_quantity": 100,
                            "escrow_quantity": 100,
                            "satoshirate": 100,
                            "status": 10,
                            "give_remaining": 0,
                        },
                    },
                    {
                        "table": "credits",
                        "values": {
                            "calling_function": "close dispenser",
                            "address": ADDR[5],
                            "asset": config.XCP,
                            "block_index": DP["default_block_index"],
                            "event": "db6d9052b576d973196363e11163d492f50926c2f1d1efd67b3d999817b0d04d",
                            "quantity": 100,
                        },
                    },
                ],
            },
            {
                "mock_protocol_changes": {"dispensers": True},
                "in": (
                    {
                        "tx_hash": "db6d9052b576d973196363e11163d492f50926c2f1d1efd67b3d999817b0d04d",
                        "source": ADDR[5],
                        "supported": 1,
                        "block_index": 2344638,
                        "fee": 10000,
                        "block_time": 155409000,
                        "block_hash": DP["default_block_hash"],
                        "btc_amount": 0,
                        "tx_index": DP["default_tx_index"],
                        "destination": "",
                        # compose(ADDR[0], config.XCP, 100, 100, config.MAX_INT + 1, 0)
                        # generated with overflow checking commented out
                        "data": b"\x00\x00\x00\x0c\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x00\x00\x00d\x00\x00\x00\x00\x00\x00\x00d\x80\x00\x00\x00\x00\x00\x00\x00\x00",
                    },
                ),
                #'error': ("Warning", "Not storing [dispenser] tx [db6d9052b576d973196363e11163d492f50926c2f1d1efd67b3d999817b0d04d]: invalid: address has a dispenser already opened for asset XCP with a different mainchainrate; integer overflow")
                "out": None,
            },
            {
                "mock_protocol_changes": {"dispensers": True},
                "in": (
                    {
                        "tx_hash": "db6d9052b576d973196363e11163d492f50926c2f1d1efd67b3d999817b0d04d",
                        "source": ADDR[0],
                        "supported": 1,
                        "block_index": DP["default_block_index"],
                        "fee": 10000,
                        "block_time": 155409000,
                        "block_hash": DP["default_block_hash"],
                        "btc_amount": 17630,
                        "tx_index": DP["default_tx_index"],
                        "destination": ADDR[0],
                        # source != open_address
                        "data": b"\x00\x00\x00\x0c\x00\x00\x00\x00\n\xa4\t}\x00\x00\x00\x00\x00\x00\x00d\x00\x00\x00\x00\x00\x00\x10\x00\x00\x00\x00\x00\x00\t)\x00",
                    },
                ),
                "out": None,
            },
        ],
        "is_dispensable": [
            {"mock_protocol_changes": {"dispensers": True}, "in": (ADDR[5], 200), "out": True},
            {"mock_protocol_changes": {"dispensers": True}, "in": (ADDR[0], 200), "out": False},
        ],
    },
    "dispense": {
        "compose": [
            {
                "in": (ADDR[0], ADDR[5], 100),
                "out": (
                    ADDR[0],
                    [(ADDR[5], 100)],
                    b"\r\x00",
                ),
            },
            {
                "in": (ADDR[0], ADDR[5], 10),
                "error": (
                    exceptions.ComposeError,
                    [
                        "not enough BTC to trigger dispenser for XCP",
                        "not enough BTC to trigger dispenser for TESTDISP",
                    ],
                ),
            },
            {
                "in": (ADDR[0], ADDR[5], 10000),
                "error": (
                    exceptions.ComposeError,
                    [
                        "dispenser for XCP doesn't have enough asset to give",
                        "dispenser for TESTDISP doesn't have enough asset to give",
                    ],
                ),
            },
            {
                "in": (ADDR[0], ADDR[2], 10),
                "error": (
                    exceptions.ComposeError,
                    ["address doesn't have any open dispenser"],
                ),
            },
        ],
        "parse": [
            {
                "mock_protocol_changes": {"dispensers": True},
                "in": (
                    {
                        "tx_hash": "db6d9052b576d973196363e11163d492f50926c2f1d1efd67b3d999817b0d04d",
                        "source": ADDR[0],
                        "supported": 1,
                        "block_index": DP["default_block_index"],
                        "fee": 10000,
                        "block_time": 155409000,
                        "block_hash": DP["default_block_hash"],
                        "btc_amount": 100,
                        "tx_index": DP["default_tx_index"],
                        "destination": ADDR[5],
                        "data": b"",
                    },
                ),
                "records": [
                    {
                        "table": "dispensers",
                        "values": {  # Some values here correspond to the original TX that opened the dispenser
                            "tx_index": 108,
                            "tx_hash": "0d53631a5f5b18632791ee65aa9723b29b57eb5a6e12d034804b786d99102a03",
                            "block_index": DP["default_block_index"],
                            "source": ADDR[5],
                            "asset": config.XCP,
                            "give_quantity": 100,
                            "escrow_quantity": 100,
                            "satoshirate": 100,
                            "status": 10,
                            "give_remaining": 0,
                        },
                    },
                    {
                        "table": "credits",
                        "values": {
                            "calling_function": "dispense",
                            "address": ADDR[0],
                            "asset": config.XCP,
                            "block_index": DP["default_block_index"],
                            "event": "db6d9052b576d973196363e11163d492f50926c2f1d1efd67b3d999817b0d04d",
                            "quantity": 100,
                        },
                    },
                ],
            },
            {
                "mock_protocol_changes": {
                    "dispensers": True
                },  # Same test as above, but with excess BTC, should give out the same amount of XCP
                "in": (
                    {
                        "tx_hash": "db6d9052b576d973196363e11163d492f50926c2f1d1efd67b3d999817b0d04d",
                        "source": ADDR[0],
                        "supported": 1,
                        "block_index": DP["default_block_index"],
                        "fee": 10000,
                        "block_time": 155409000,
                        "block_hash": DP["default_block_hash"],
                        "btc_amount": 300,
                        "tx_index": DP["default_tx_index"],
                        "destination": ADDR[5],
                        "data": b"",
                    },
                ),
                "records": [
                    {
                        "table": "dispensers",
                        "values": {  # Some values here correspond to the original TX that opened the dispenser
                            "tx_index": 108,
                            "tx_hash": "0d53631a5f5b18632791ee65aa9723b29b57eb5a6e12d034804b786d99102a03",
                            "block_index": DP["default_block_index"],
                            "source": ADDR[5],
                            "asset": config.XCP,
                            "give_quantity": 100,
                            "escrow_quantity": 100,
                            "satoshirate": 100,
                            "status": 10,
                            "give_remaining": 0,
                        },
                    },
                    {
                        "table": "credits",
                        "values": {
                            "calling_function": "dispense",
                            "address": ADDR[0],
                            "asset": config.XCP,
                            "block_index": DP["default_block_index"],
                            "event": "db6d9052b576d973196363e11163d492f50926c2f1d1efd67b3d999817b0d04d",
                            "quantity": 100,
                        },
                    },
                ],
            },
        ],
    },
}
