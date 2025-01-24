from counterpartycore.lib import exceptions
from counterpartycore.test.fixtures.params import ADDR, DP, MULTISIGADDR, P2SH_ADDR

BURN_VECTOR = {
    "burn": {
        "validate": [
            {
                "in": (ADDR[0], DP["unspendable"], DP["burn_quantity"], DP["burn_start"]),
                "out": ([]),
            },
            {
                "in": (ADDR[0], DP["unspendable"], 1.1 * DP["burn_quantity"], DP["burn_start"]),
                "out": (["quantity must be in satoshis"]),
            },
            {
                "in": (ADDR[0], ADDR[1], DP["burn_quantity"], DP["burn_start"]),
                "out": (["wrong destination address"]),
            },
            {
                "in": (ADDR[0], DP["unspendable"], -1 * DP["burn_quantity"], DP["burn_start"]),
                "out": (["negative quantity"]),
            },
            {
                "in": (ADDR[0], DP["unspendable"], DP["burn_quantity"], DP["burn_start"] - 2),
                "out": (["too early"]),
            },
            {
                "in": (ADDR[0], DP["unspendable"], DP["burn_quantity"], DP["burn_end"] + 1),
                "out": (["too late"]),
            },
            {
                "in": (ADDR[0], ADDR[1], 1.1 * DP["burn_quantity"], DP["burn_start"] - 2),
                "out": (["wrong destination address", "quantity must be in satoshis"]),
            },
            {
                "in": (ADDR[0], ADDR[1], DP["burn_quantity"], DP["burn_start"] - 2),
                "out": (["wrong destination address", "too early"]),
            },
            {
                "in": (
                    MULTISIGADDR[0],
                    DP["unspendable"],
                    DP["burn_quantity"],
                    DP["burn_start"],
                ),
                "out": ([]),
            },
            {
                "comment": "p2sh",
                "in": (P2SH_ADDR[0], DP["unspendable"], DP["burn_quantity"], DP["burn_start"]),
                "out": ([]),
            },
        ],
        "compose": [
            {
                "in": (ADDR[1], DP["burn_quantity"]),
                "out": (
                    "mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns",
                    [("mvCounterpartyXXXXXXXXXXXXXXW24Hef", 62000000)],
                    None,
                ),
            },
            {
                "in": (ADDR[0], DP["burn_quantity"]),
                "error": (exceptions.ComposeError, "1 BTC may be burned per address"),
            },
            {
                "in": (MULTISIGADDR[0], int(DP["quantity"] / 2)),
                "out": (
                    "1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2",
                    [("mvCounterpartyXXXXXXXXXXXXXXW24Hef", 50000000)],
                    None,
                ),
            },
            {
                "comment": "p2sh",
                "in": (P2SH_ADDR[0], int(DP["burn_quantity"] / 2)),
                "out": (P2SH_ADDR[0], [("mvCounterpartyXXXXXXXXXXXXXXW24Hef", 31000000)], None),
            },
        ],
        "parse": [
            {
                "in": (
                    {
                        "block_index": DP["default_block_index"],
                        "destination": "mvCounterpartyXXXXXXXXXXXXXXW24Hef",
                        "fee": 10000,
                        "block_time": 155409000,
                        "supported": 1,
                        "btc_amount": 62000000,
                        "data": b"",
                        "source": "mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns",
                        "tx_index": DP["default_tx_index"],
                        "tx_hash": "db6d9052b576d973196363e11163d492f50926c2f1d1efd67b3d999817b0d04d",
                        "block_hash": DP["default_block_hash"],
                    },
                ),
                "records": [
                    {
                        "table": "burns",
                        "values": {
                            "block_index": DP["default_block_index"],
                            "burned": 62000000,
                            "earned": 92994113884,
                            "source": "mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns",
                            "status": "valid",
                            "tx_hash": "db6d9052b576d973196363e11163d492f50926c2f1d1efd67b3d999817b0d04d",
                            "tx_index": DP["default_tx_index"],
                        },
                    },
                    {
                        "table": "credits",
                        "values": {
                            "address": "mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns",
                            "asset": "XCP",
                            "block_index": DP["default_block_index"],
                            "calling_function": "burn",
                            "event": "db6d9052b576d973196363e11163d492f50926c2f1d1efd67b3d999817b0d04d",
                            "quantity": 92994113884,
                        },
                    },
                ],
            },
            {
                "in": (
                    {
                        "supported": 1,
                        "tx_hash": "db6d9052b576d973196363e11163d492f50926c2f1d1efd67b3d999817b0d04d",
                        "btc_amount": 50000000,
                        "block_index": DP["default_block_index"],
                        "block_hash": DP["default_block_hash"],
                        "fee": 10000,
                        "data": b"",
                        "block_time": 155409000,
                        "source": "1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2",
                        "tx_index": DP["default_tx_index"],
                        "destination": "mvCounterpartyXXXXXXXXXXXXXXW24Hef",
                    },
                ),
                "records": [
                    {
                        "table": "burns",
                        "values": {
                            "block_index": DP["default_block_index"],
                            "burned": 50000000,
                            "earned": 74995253132,
                            "source": "1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2",
                            "status": "valid",
                            "tx_hash": "db6d9052b576d973196363e11163d492f50926c2f1d1efd67b3d999817b0d04d",
                            "tx_index": DP["default_tx_index"],
                        },
                    },
                    {
                        "table": "credits",
                        "values": {
                            "address": "1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2",
                            "asset": "XCP",
                            "block_index": DP["default_block_index"],
                            "calling_function": "burn",
                            "event": "db6d9052b576d973196363e11163d492f50926c2f1d1efd67b3d999817b0d04d",
                            "quantity": 74995253132,
                        },
                    },
                ],
            },
        ],
    },
}
