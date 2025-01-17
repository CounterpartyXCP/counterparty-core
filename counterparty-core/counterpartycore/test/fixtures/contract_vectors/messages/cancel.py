from counterpartycore.lib import exceptions
from counterpartycore.test.fixtures.params import ADDR, DP

CANCEL_VECTOR = {
    "cancel": {
        "compose": [
            {
                "in": (
                    ADDR[1],
                    "7a2ab30a4e996078632806cebc56e62cc6b04ce45a027394faa6e3dee71bf886",
                ),
                "out": (
                    "mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns",
                    [],
                    b"\x00\x00\x00Fz*\xb3\nN\x99`xc(\x06\xce\xbcV\xe6,\xc6\xb0L\xe4Z\x02s\x94\xfa\xa6\xe3\xde\xe7\x1b\xf8\x86",
                ),
            },
            {
                "in": (ADDR[1], "foobar"),
                "error": (exceptions.ComposeError, ["no open offer with that hash"]),
            },
            {
                "in": (
                    "foobar",
                    "7a2ab30a4e996078632806cebc56e62cc6b04ce45a027394faa6e3dee71bf886",
                ),
                "error": (exceptions.ComposeError, ["incorrect source address"]),
            },
            {
                "in": (
                    ADDR[1],
                    "6f5fbb3c63ae13b50d48a10df5317a1615bd5d9bfd2d46d75950689099e461f5",
                ),
                "error": (exceptions.ComposeError, ["offer not open"]),
            },
        ],
        "parse": [
            {
                "in": (
                    {
                        "block_index": DP["default_block_index"],
                        "btc_amount": 0,
                        "source": "mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns",
                        "data": b"\x00\x00\x00F\xdbN\xa0\x92\xbe\xa6\x03n=\x1e_n\xc8c\xdb\x9b\x90\x02R\xb4\xf4\xd6\xd9\xfa\xa6\x16S#\xf43\xc5\x1e",
                        "block_hash": "46ac6d09237c7961199068fdd13f1508d755483e07c57a4c8f7ff18eb33a05c93ca6a86fa2e2af82fb77a5c337146bb37e279797a3d11970aec4693c46ea5a58",
                        "tx_index": DP["default_tx_index"],
                        "fee": 10000,
                        "block_time": 310501000,
                        "tx_hash": "fb645106e276bfa1abd587f4a251b26f491a2a9ae61ca46a669794109728b122",
                        "destination": "",
                        "supported": 1,
                    },
                ),
                "out": None,
            },
            {
                "in": (
                    {
                        "block_index": DP["default_block_index"],
                        "btc_amount": 0,
                        "source": "mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns",
                        "data": b"\x00\x00\x00Fz*\xb3\nN\x99`xc(\x06\xce\xbcV\xe6,\xc6\xb0L\xe4Z\x02s\x94\xfa\xa6\xe3\xde\xe7\x1b\xf8\x86",
                        "block_hash": "46ac6d09237c7961199068fdd13f1508d755483e07c57a4c8f7ff18eb33a05c93ca6a86fa2e2af82fb77a5c337146bb37e279797a3d11970aec4693c46ea5a58",
                        "tx_index": DP["default_tx_index"],
                        "fee": 10000,
                        "block_time": 310501000,
                        "tx_hash": "fb645106e276bfa1abd587f4a251b26f491a2a9ae61ca46a669794109728b122",
                        "destination": "",
                        "supported": 1,
                    },
                ),
                "records": [
                    {
                        "table": "cancels",
                        "values": {
                            "block_index": DP["default_block_index"],
                            "offer_hash": "7a2ab30a4e996078632806cebc56e62cc6b04ce45a027394faa6e3dee71bf886",
                            "source": "mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns",
                            "status": "valid",
                            "tx_hash": "fb645106e276bfa1abd587f4a251b26f491a2a9ae61ca46a669794109728b122",
                            "tx_index": DP["default_tx_index"],
                        },
                    },
                    {
                        "table": "bets",
                        "values": {
                            "bet_type": 3,
                            "expiration": 1000,
                            "expire_index": 311101,
                            "block_index": DP["default_block_index"],
                            "deadline": 1388000200,
                            "counterwager_quantity": 10,
                            "wager_remaining": 10,
                            "counterwager_remaining": 10,
                            "tx_index": 102,
                            "fee_fraction_int": 5000000,
                            "status": "cancelled",
                            "feed_address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc",
                            "leverage": 5040,
                            "wager_quantity": 10,
                            "source": "mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns",
                            "target_value": 0.0,
                            "tx_hash": "7a2ab30a4e996078632806cebc56e62cc6b04ce45a027394faa6e3dee71bf886",
                        },
                    },
                ],
            },
        ],
    },
}
