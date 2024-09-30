from bitcoin import SelectParams
from bitcoin.core import CTxOut
from bitcoin.core.script import OP_CHECKMULTISIG, OP_RETURN, CScript
from bitcoin.wallet import CBitcoinAddress, P2WPKHBitcoinAddress

from counterpartycore.lib import config, exceptions

from ..params import (
    ADDR,
    DEFAULT_PARAMS,
    MULTISIGADDR,
    P2WPKH_ADDR,
)

SelectParams("testnet")

PROVIDED_PUBKEYS = [DEFAULT_PARAMS["pubkey"][ADDR[0]], DEFAULT_PARAMS["pubkey"][ADDR[1]]]
ARC4_KEY = "0000000000000000000000000000000000000000000000000000000000000000"
UTXO_1 = "344dcc8909ca3a137630726d0071dfd2df4f7c855bac150c7d3a8367835c90bc:1"
UTXO_2 = "4f0433ba841038e2e16328445930dd7bca35309b14b0da4451c8f94c631368b8:1"
UTXO_3 = "1fc2e5a57f584b2f2edd05676e75c33d03eed1d3098cc0550ea33474e3ec9db1:1"

COMPOSER_VECTOR = {
    "composer": {
        "get_script": [
            {
                "comment": "P2PKH address",
                "in": (ADDR[0],),
                "out": CBitcoinAddress(ADDR[0]).to_scriptPubKey(),
            },
            {
                "comment": "P2WPKH address",
                "in": (P2WPKH_ADDR[0],),
                "out": P2WPKHBitcoinAddress(P2WPKH_ADDR[0]).to_scriptPubKey(),
            },
            {
                "comment": "multisig address",
                "in": (MULTISIGADDR[0], PROVIDED_PUBKEYS),
                "out": CScript(
                    [
                        1,
                        bytes.fromhex(DEFAULT_PARAMS["pubkey"][ADDR[0]]),
                        bytes.fromhex(DEFAULT_PARAMS["pubkey"][ADDR[1]]),
                        2,
                        OP_CHECKMULTISIG,
                    ]
                ),
            },
        ],
        "perpare_non_data_outputs": [
            {
                "in": ([(ADDR[0], 0)],),
                "out": [CTxOut(546, CBitcoinAddress(ADDR[0]).to_scriptPubKey())],
            },
            {
                "in": ([(MULTISIGADDR[0], 0)], PROVIDED_PUBKEYS),
                "out": [
                    CTxOut(
                        1000,
                        CScript(
                            [
                                1,
                                bytes.fromhex(DEFAULT_PARAMS["pubkey"][ADDR[0]]),
                                bytes.fromhex(DEFAULT_PARAMS["pubkey"][ADDR[1]]),
                                2,
                                OP_CHECKMULTISIG,
                            ]
                        ),
                    )
                ],
            },
            {
                "in": ([(ADDR[0], 2024)],),
                "out": [CTxOut(2024, CBitcoinAddress(ADDR[0]).to_scriptPubKey())],
            },
        ],
        "determine_encoding": [
            {
                "in": (b"Hello, World!",),
                "out": "opreturn",
            },
            {
                "in": (b"Hello, World!" * 100,),
                "out": "multisig",
            },
            {
                "in": (b"Hello, World!", "p2sh"),
                "error": (exceptions.TransactionError, "Not supported encoding: p2sh"),
            },
            {
                "in": (b"Hello, World!", "toto"),
                "error": (exceptions.TransactionError, "Not supported encoding: toto"),
            },
        ],
        "encrypt_data": [
            {
                "in": (b"Hello, World!", ARC4_KEY),
                "out": b"\x96}\xe5-\xcc\x1b}m\xe5tr\x03v",
            },
        ],
        "prepare_opreturn_output": [
            {
                "in": (b"Hello, World!", ARC4_KEY),
                "out": [
                    CTxOut(
                        0,
                        CScript(
                            [
                                OP_RETURN,
                                b"\x8a]\xda\x15\xfbo\x05b\xc2cr\x0b8B\xb2:\xa8h\x13\xc7\xd1",
                            ]
                        ),
                    )
                ],
            },
            {
                "in": (b"Hello, World!",),
                "out": [CTxOut(0, CScript([OP_RETURN, b"TESTXXXXHello, World!"]))],
            },
        ],
        "data_to_pubkey_pairs": [
            {
                "in": (b"Hello, World!" * 10,),
                "out": [
                    (
                        b"\x025Hello, World!Hello, World!Hell\x9b",
                        b"\x03o, World!Hello, World!H\x00\x00\x00\x00\x00\x00\x00\x00\x94",
                    ),
                    (
                        b"\x025ello, World!Hello, World!Hello<",
                        b"\x03, World!Hello, World!He\x00\x00\x00\x00\x00\x00\x00\x00\t",
                    ),
                    (
                        b"\x02\x18llo, World!Hello, World!\x00\x00\x00\x00\x00\x00G",
                        b"\x03\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x0c",
                    ),
                ],
            },
            {
                "in": (b"Hello, World!" * 10, ARC4_KEY),
                "out": [
                    (
                        b"\x03\xebP\xec-\xcfXq\x1a\xddil\x0b3O\xda\x08\xabv\x10\x8f\xd0\x9b\x84\xe5)OlzB\xfa33",
                        b'\x02\xf1\x84\xec"h\x1f\xf3\xdd\xe4\t\x1f\xc9\xa7_\xd0\x02N\xe4F\xf4I\x9a*\x9e\xc0KO\x8b\x05\xa0q\xda',
                    ),
                    (
                        b"\x02\xeb}\xe5-\xcc\x1b}m\xe5tr\x03v&\xf7\x01\xabuS\x83\xa7\xa3\x99\xfb!\n\x05WK\xfa0\r",
                        b"\x02\xb2\x88\x9b\x1au\x01\xfb\x98\x8d$\x16\xc9\xa4\x1c\xdcuv\xf9X\xfc\x0c\xf3\x07\x9e\xc0KO\x8b\x05\xa0q\xa2",
                    ),
                    (
                        b"\x03\xc6t\xe5.\x8f\x17\nU\xf8jzF\x1f\x0b\xfe\x01\xa86_\xf4\x9f\xbe\x87\xf3d+M2'\x96_\x81",
                        b'\x02\x9e\xa8\xccu\x07m\x9f\xb9\xc5Az\xa5\xcb0\xfc"\x19\x8b4\x98-\xbbb\x9e\xc0KO\x8b\x05\xa0q4',
                    ),
                ],
            },
        ],
        "prepare_multisig_output": [
            {
                "comment": "No encryption",
                "in": (b"Hello, World!" * 10, ADDR[0], PROVIDED_PUBKEYS),
                "out": [
                    CTxOut(
                        config.DEFAULT_MULTISIG_DUST_SIZE,
                        CScript(
                            [
                                1,
                                b"\x025Hello, World!Hello, World!Hell\x9b",
                                b"\x03o, World!Hello, World!H\x00\x00\x00\x00\x00\x00\x00\x00\x94",
                                bytes.fromhex(DEFAULT_PARAMS["pubkey"][ADDR[0]]),
                                3,
                                OP_CHECKMULTISIG,
                            ]
                        ),
                    ),
                    CTxOut(
                        config.DEFAULT_MULTISIG_DUST_SIZE,
                        CScript(
                            [
                                1,
                                b"\x025ello, World!Hello, World!Hello<",
                                b"\x03, World!Hello, World!He\x00\x00\x00\x00\x00\x00\x00\x00\t",
                                bytes.fromhex(DEFAULT_PARAMS["pubkey"][ADDR[0]]),
                                3,
                                OP_CHECKMULTISIG,
                            ]
                        ),
                    ),
                    CTxOut(
                        config.DEFAULT_MULTISIG_DUST_SIZE,
                        CScript(
                            [
                                1,
                                b"\x02\x18llo, World!Hello, World!\x00\x00\x00\x00\x00\x00G",
                                b"\x03\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x0c",
                                bytes.fromhex(DEFAULT_PARAMS["pubkey"][ADDR[0]]),
                                3,
                                OP_CHECKMULTISIG,
                            ]
                        ),
                    ),
                ],
            },
            {
                "comment": "Encrypted",
                "in": (b"Hello, World!" * 10, ADDR[0], PROVIDED_PUBKEYS, ARC4_KEY),
                "out": [
                    CTxOut(
                        config.DEFAULT_MULTISIG_DUST_SIZE,
                        CScript(
                            [
                                1,
                                b"\x03\xebP\xec-\xcfXq\x1a\xddil\x0b3O\xda\x08\xabv\x10\x8f\xd0\x9b\x84\xe5)OlzB\xfa33",
                                b'\x02\xf1\x84\xec"h\x1f\xf3\xdd\xe4\t\x1f\xc9\xa7_\xd0\x02N\xe4F\xf4I\x9a*\x9e\xc0KO\x8b\x05\xa0q\xda',
                                bytes.fromhex(DEFAULT_PARAMS["pubkey"][ADDR[0]]),
                                3,
                                OP_CHECKMULTISIG,
                            ]
                        ),
                    ),
                    CTxOut(
                        config.DEFAULT_MULTISIG_DUST_SIZE,
                        CScript(
                            [
                                1,
                                b"\x02\xeb}\xe5-\xcc\x1b}m\xe5tr\x03v&\xf7\x01\xabuS\x83\xa7\xa3\x99\xfb!\n\x05WK\xfa0\r",
                                b"\x02\xb2\x88\x9b\x1au\x01\xfb\x98\x8d$\x16\xc9\xa4\x1c\xdcuv\xf9X\xfc\x0c\xf3\x07\x9e\xc0KO\x8b\x05\xa0q\xa2",
                                bytes.fromhex(DEFAULT_PARAMS["pubkey"][ADDR[0]]),
                                3,
                                OP_CHECKMULTISIG,
                            ]
                        ),
                    ),
                    CTxOut(
                        config.DEFAULT_MULTISIG_DUST_SIZE,
                        CScript(
                            [
                                1,
                                b"\x03\xc6t\xe5.\x8f\x17\nU\xf8jzF\x1f\x0b\xfe\x01\xa86_\xf4\x9f\xbe\x87\xf3d+M2'\x96_\x81",
                                b'\x02\x9e\xa8\xccu\x07m\x9f\xb9\xc5Az\xa5\xcb0\xfc"\x19\x8b4\x98-\xbbb\x9e\xc0KO\x8b\x05\xa0q4',
                                bytes.fromhex(DEFAULT_PARAMS["pubkey"][ADDR[0]]),
                                3,
                                OP_CHECKMULTISIG,
                            ]
                        ),
                    ),
                ],
            },
        ],
        "prepare_data_outputs": [
            {
                "in": ("opreturn", b"Hello, World!", ADDR[0], None),
                "out": [CTxOut(0, CScript([OP_RETURN, b"TESTXXXXHello, World!"]))],
            },
            {
                "in": ("opreturn", b"Hello, World!" * 10, ADDR[0], PROVIDED_PUBKEYS),
                "error": (exceptions.TransactionError, "One `OP_RETURN` output per transaction"),
            },
            {
                "in": ("multisig", b"Hello, World!" * 10, ADDR[0], PROVIDED_PUBKEYS),
                "out": [
                    CTxOut(
                        config.DEFAULT_MULTISIG_DUST_SIZE,
                        CScript(
                            [
                                1,
                                b"\x025Hello, World!Hello, World!Hell\x9b",
                                b"\x03o, World!Hello, World!H\x00\x00\x00\x00\x00\x00\x00\x00\x94",
                                bytes.fromhex(DEFAULT_PARAMS["pubkey"][ADDR[0]]),
                                3,
                                OP_CHECKMULTISIG,
                            ]
                        ),
                    ),
                    CTxOut(
                        config.DEFAULT_MULTISIG_DUST_SIZE,
                        CScript(
                            [
                                1,
                                b"\x025ello, World!Hello, World!Hello<",
                                b"\x03, World!Hello, World!He\x00\x00\x00\x00\x00\x00\x00\x00\t",
                                bytes.fromhex(DEFAULT_PARAMS["pubkey"][ADDR[0]]),
                                3,
                                OP_CHECKMULTISIG,
                            ]
                        ),
                    ),
                    CTxOut(
                        config.DEFAULT_MULTISIG_DUST_SIZE,
                        CScript(
                            [
                                1,
                                b"\x02\x18llo, World!Hello, World!\x00\x00\x00\x00\x00\x00G",
                                b"\x03\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x0c",
                                bytes.fromhex(DEFAULT_PARAMS["pubkey"][ADDR[0]]),
                                3,
                                OP_CHECKMULTISIG,
                            ]
                        ),
                    ),
                ],
            },
            {
                "in": ("p2sh", b"Hello, World!" * 10, ADDR[0], PROVIDED_PUBKEYS),
                "error": (exceptions.TransactionError, "Not supported encoding: p2sh"),
            },
        ],
        "prepare_outputs": [
            {
                "in": (ADDR[0], [(ADDR[0], 9999)], b"Hello, World!", None, "opreturn"),
                "out": [
                    CTxOut(9999, CBitcoinAddress(ADDR[0]).to_scriptPubKey()),
                    CTxOut(0, CScript([OP_RETURN, b"TESTXXXXHello, World!"])),
                ],
            },
            {
                "in": (ADDR[0], [(ADDR[0], 9999)], b"Hello, World!", None, "opreturn", ARC4_KEY),
                "out": [
                    CTxOut(9999, CBitcoinAddress(ADDR[0]).to_scriptPubKey()),
                    CTxOut(
                        0,
                        CScript(
                            [
                                OP_RETURN,
                                b"\x8a]\xda\x15\xfbo\x05b\xc2cr\x0b8B\xb2:\xa8h\x13\xc7\xd1",
                            ]
                        ),
                    ),
                ],
            },
            {
                "in": (
                    ADDR[0],
                    [(ADDR[0], 9999)],
                    b"Hello, World!" * 10,
                    PROVIDED_PUBKEYS,
                    "multisig",
                ),
                "out": [
                    CTxOut(9999, CBitcoinAddress(ADDR[0]).to_scriptPubKey()),
                    CTxOut(
                        config.DEFAULT_MULTISIG_DUST_SIZE,
                        CScript(
                            [
                                1,
                                b"\x025Hello, World!Hello, World!Hell\x9b",
                                b"\x03o, World!Hello, World!H\x00\x00\x00\x00\x00\x00\x00\x00\x94",
                                bytes.fromhex(DEFAULT_PARAMS["pubkey"][ADDR[0]]),
                                3,
                                OP_CHECKMULTISIG,
                            ]
                        ),
                    ),
                    CTxOut(
                        config.DEFAULT_MULTISIG_DUST_SIZE,
                        CScript(
                            [
                                1,
                                b"\x025ello, World!Hello, World!Hello<",
                                b"\x03, World!Hello, World!He\x00\x00\x00\x00\x00\x00\x00\x00\t",
                                bytes.fromhex(DEFAULT_PARAMS["pubkey"][ADDR[0]]),
                                3,
                                OP_CHECKMULTISIG,
                            ]
                        ),
                    ),
                    CTxOut(
                        config.DEFAULT_MULTISIG_DUST_SIZE,
                        CScript(
                            [
                                1,
                                b"\x02\x18llo, World!Hello, World!\x00\x00\x00\x00\x00\x00G",
                                b"\x03\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x0c",
                                bytes.fromhex(DEFAULT_PARAMS["pubkey"][ADDR[0]]),
                                3,
                                OP_CHECKMULTISIG,
                            ]
                        ),
                    ),
                ],
            },
            {
                "in": (
                    ADDR[0],
                    [(ADDR[0], 9999)],
                    b"Hello, World!" * 10,
                    PROVIDED_PUBKEYS,
                    "multisig",
                    ARC4_KEY,
                ),
                "out": [
                    CTxOut(9999, CBitcoinAddress(ADDR[0]).to_scriptPubKey()),
                    CTxOut(
                        config.DEFAULT_MULTISIG_DUST_SIZE,
                        CScript(
                            [
                                1,
                                b"\x03\xebP\xec-\xcfXq\x1a\xddil\x0b3O\xda\x08\xabv\x10\x8f\xd0\x9b\x84\xe5)OlzB\xfa33",
                                b'\x02\xf1\x84\xec"h\x1f\xf3\xdd\xe4\t\x1f\xc9\xa7_\xd0\x02N\xe4F\xf4I\x9a*\x9e\xc0KO\x8b\x05\xa0q\xda',
                                bytes.fromhex(DEFAULT_PARAMS["pubkey"][ADDR[0]]),
                                3,
                                OP_CHECKMULTISIG,
                            ]
                        ),
                    ),
                    CTxOut(
                        config.DEFAULT_MULTISIG_DUST_SIZE,
                        CScript(
                            [
                                1,
                                b"\x02\xeb}\xe5-\xcc\x1b}m\xe5tr\x03v&\xf7\x01\xabuS\x83\xa7\xa3\x99\xfb!\n\x05WK\xfa0\r",
                                b"\x02\xb2\x88\x9b\x1au\x01\xfb\x98\x8d$\x16\xc9\xa4\x1c\xdcuv\xf9X\xfc\x0c\xf3\x07\x9e\xc0KO\x8b\x05\xa0q\xa2",
                                bytes.fromhex(DEFAULT_PARAMS["pubkey"][ADDR[0]]),
                                3,
                                OP_CHECKMULTISIG,
                            ]
                        ),
                    ),
                    CTxOut(
                        config.DEFAULT_MULTISIG_DUST_SIZE,
                        CScript(
                            [
                                1,
                                b"\x03\xc6t\xe5.\x8f\x17\nU\xf8jzF\x1f\x0b\xfe\x01\xa86_\xf4\x9f\xbe\x87\xf3d+M2'\x96_\x81",
                                b'\x02\x9e\xa8\xccu\x07m\x9f\xb9\xc5Az\xa5\xcb0\xfc"\x19\x8b4\x98-\xbbb\x9e\xc0KO\x8b\x05\xa0q4',
                                bytes.fromhex(DEFAULT_PARAMS["pubkey"][ADDR[0]]),
                                3,
                                OP_CHECKMULTISIG,
                            ]
                        ),
                    ),
                ],
            },
        ],
        "prepare_unspent_list": [
            {
                "in": (f"{UTXO_1},{UTXO_2},{UTXO_3}",),
                "out": [
                    {"txid": UTXO_1.split(":")[0], "vout": int(UTXO_1.split(":")[1]), "value": 999},
                    {"txid": UTXO_2.split(":")[0], "vout": int(UTXO_2.split(":")[1]), "value": 999},
                    {"txid": UTXO_3.split(":")[0], "vout": int(UTXO_3.split(":")[1]), "value": 999},
                ],
            }
        ],
        "select_utxos": [
            {
                "in": (
                    [
                        {
                            "txid": UTXO_1.split(":")[0],
                            "vout": int(UTXO_1.split(":")[1]),
                            "value": 999,
                        },
                        {
                            "txid": UTXO_2.split(":")[0],
                            "vout": int(UTXO_2.split(":")[1]),
                            "value": 999,
                        },
                        {
                            "txid": UTXO_3.split(":")[0],
                            "vout": int(UTXO_3.split(":")[1]),
                            "value": 999,
                        },
                    ],
                    500,
                ),
                "out": [
                    {"txid": UTXO_1.split(":")[0], "vout": int(UTXO_1.split(":")[1]), "value": 999},
                ],
            },
            {
                "in": (
                    [
                        {
                            "txid": UTXO_1.split(":")[0],
                            "vout": int(UTXO_1.split(":")[1]),
                            "value": 999,
                        },
                        {
                            "txid": UTXO_2.split(":")[0],
                            "vout": int(UTXO_2.split(":")[1]),
                            "value": 999,
                        },
                        {
                            "txid": UTXO_3.split(":")[0],
                            "vout": int(UTXO_3.split(":")[1]),
                            "value": 999,
                        },
                    ],
                    1000,
                ),
                "out": [
                    {"txid": UTXO_1.split(":")[0], "vout": int(UTXO_1.split(":")[1]), "value": 999},
                    {"txid": UTXO_2.split(":")[0], "vout": int(UTXO_2.split(":")[1]), "value": 999},
                ],
            },
            {
                "in": (
                    [
                        {
                            "txid": UTXO_1.split(":")[0],
                            "vout": int(UTXO_1.split(":")[1]),
                            "value": 999,
                        },
                        {
                            "txid": UTXO_2.split(":")[0],
                            "vout": int(UTXO_2.split(":")[1]),
                            "value": 999,
                        },
                        {
                            "txid": UTXO_3.split(":")[0],
                            "vout": int(UTXO_3.split(":")[1]),
                            "value": 999,
                        },
                    ],
                    2000,
                ),
                "out": [
                    {"txid": UTXO_1.split(":")[0], "vout": int(UTXO_1.split(":")[1]), "value": 999},
                    {"txid": UTXO_2.split(":")[0], "vout": int(UTXO_2.split(":")[1]), "value": 999},
                    {"txid": UTXO_3.split(":")[0], "vout": int(UTXO_3.split(":")[1]), "value": 999},
                ],
            },
            {
                "in": (
                    [
                        {
                            "txid": UTXO_1.split(":")[0],
                            "vout": int(UTXO_1.split(":")[1]),
                            "value": 999,
                        },
                        {
                            "txid": UTXO_2.split(":")[0],
                            "vout": int(UTXO_2.split(":")[1]),
                            "value": 999,
                        },
                        {
                            "txid": UTXO_3.split(":")[0],
                            "vout": int(UTXO_3.split(":")[1]),
                            "value": 999,
                        },
                    ],
                    3000,
                ),
                "error": (
                    exceptions.ComposeError,
                    "Insufficient funds for the target amount: 3000",
                ),
            },
        ],
    }
}
