from counterpartycore.lib import config, exceptions

from ..params import (
    ADDR,
)

UTXO_1 = "344dcc8909ca3a137630726d0071dfd2df4f7c855bac150c7d3a8367835c90bc:1"
UTXO_2 = "e219be68972de7df99122a0213d7be2f597c14fa48b55457a81641583099fea4:0"
UTXO_3 = "74501a157028760383ae4a8f79f6bce9ef64e60e883ac3285bc239a907c2b42c:0"

ATTACH_VECTOR = {
    "attach": {
        "validate": [
            {
                "in": (
                    ADDR[0],
                    "XCP",
                    100,
                ),
                "out": [],
            },
            {
                "in": (
                    ADDR[0],
                    "XCP",
                    100,
                    1,
                ),
                "out": [],
            },
            {
                "in": (
                    UTXO_1,
                    "XCP",
                    100,
                ),
                "out": ["invalid source address"],
            },
            {
                "in": (ADDR[0], "XCP", 0),
                "out": ["quantity must be greater than zero"],
            },
            {
                "in": (ADDR[0], "XCP", 99999999999999),
                "out": ["insufficient funds for transfer and fee"],
            },
            {
                "in": (ADDR[0], "DIVISIBLE", 99999999999999),
                "out": ["insufficient funds for transfer"],
            },
            {
                "in": (
                    ADDR[0],
                    "BTC",
                    100,
                ),
                "out": ["cannot send bitcoins"],
            },
            {
                "in": (
                    ADDR[0],
                    "XCP",
                    config.MAX_INT + 1,
                ),
                "out": ["integer overflow"],
            },
            {
                "in": (
                    ADDR[0],
                    "XCP",
                    "100",
                ),
                "out": ["quantity must be in satoshis"],
            },
            {
                "in": (
                    ADDR[0],
                    "XCP",
                    100,
                    -1,
                ),
                "out": ["destination vout must be greater than or equal to zero"],
            },
            {
                "in": (
                    ADDR[0],
                    "XCP",
                    100,
                    "1",
                ),
                "out": ["if provided destination must be an integer"],
            },
        ],
        "compose": [
            {
                "in": (
                    ADDR[0],
                    "XCP",
                    100,
                    1,
                ),
                "out": (
                    ADDR[0],
                    [],
                    b"eXCP|100|1",
                ),
            },
            {
                "in": (UTXO_1, "XCP", 100),
                "error": (
                    exceptions.ComposeError,
                    ["invalid source address"],
                ),
            },
            {
                "in": (
                    ADDR[0],
                    "XCP",
                    100,
                ),
                "out": (
                    ADDR[0],
                    [(ADDR[0], None)],
                    b"eXCP|100|",
                ),
            },
        ],
        "unpack": [
            {
                "in": (b"XCP|100|1",),
                "out": ("XCP", 100, 1),
            },
            {
                "in": (b"XCP|100|1", True),
                "out": {"asset": "XCP", "quantity": 100, "destination_vout": 1},
            },
            {
                "in": (b"XCP|100|",),
                "out": ("XCP", 100, None),
            },
        ],
    },
}
