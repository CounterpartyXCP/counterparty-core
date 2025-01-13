from ..params import DP

BLOCKS_VECTOR = {
    "blocks": {
        "parse_tx": [
            {
                "in": (
                    {
                        "tx_hash": "db6d9052b576d973196363e11163d492f50926c2f1d1efd67b3d999817b0d04d",
                        "source": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc-mqPCfvqTfYctXMUfmniXeG2nyaN8w6tPmj",
                        "supported": 1,
                        "block_index": DP["default_block_index"],
                        "fee": 10000,
                        "block_time": 155409000,
                        "block_hash": DP["default_block_hash"],
                        "btc_amount": 7800,
                        "data": b"\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x05\xf5\xe1\x00",
                        "tx_index": DP["default_tx_index"],
                        "destination": "mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns",
                    },
                ),
                "out": None,
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
                        "data": b"\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x05\xf5\xe1\x00",
                        "tx_index": DP["default_tx_index"],
                        "destination": "mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns-mqPCfvqTfYctXMUfmniXeG2nyaN8w6tPmj",
                    },
                ),
                "out": None,
            },
        ],
        "get_next_tx_index": [{"in": (), "out": 512}],
    },
}
