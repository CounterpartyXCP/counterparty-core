from bitcoinutils.keys import P2pkhAddress, P2wpkhAddress
from bitcoinutils.script import Script, b_to_h
from bitcoinutils.transactions import TxOutput

from counterpartycore.lib import config, exceptions

from ..params import (
    ADDR,
    DEFAULT_PARAMS,
    MULTISIGADDR,
    P2WPKH_ADDR,
)

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
                "out": P2pkhAddress(ADDR[0]).to_script_pub_key(),
            },
            {
                "comment": "P2WPKH address",
                "in": (P2WPKH_ADDR[0],),
                "out": P2wpkhAddress(P2WPKH_ADDR[0]).to_script_pub_key(),
            },
            {
                "comment": "multisig address",
                "in": (MULTISIGADDR[0], PROVIDED_PUBKEYS),
                "out": Script(
                    [
                        1,
                        DEFAULT_PARAMS["pubkey"][ADDR[0]],
                        DEFAULT_PARAMS["pubkey"][ADDR[1]],
                        2,
                        "OP_CHECKMULTISIG",
                    ]
                ),
            },
        ],
        "perpare_non_data_outputs": [
            {
                "in": ([(ADDR[0], 0)],),
                "out": [TxOutput(546, P2pkhAddress(ADDR[0]).to_script_pub_key())],
            },
            {
                "in": ([(MULTISIGADDR[0], 0)], PROVIDED_PUBKEYS),
                "out": [
                    TxOutput(
                        1000,
                        Script(
                            [
                                1,
                                DEFAULT_PARAMS["pubkey"][ADDR[0]],
                                DEFAULT_PARAMS["pubkey"][ADDR[1]],
                                2,
                                "OP_CHECKMULTISIG",
                            ]
                        ),
                    )
                ],
            },
            {
                "in": ([(ADDR[0], 2024)],),
                "out": [TxOutput(2024, P2pkhAddress(ADDR[0]).to_script_pub_key())],
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
                    TxOutput(
                        0,
                        Script(
                            [
                                "OP_RETURN",
                                b_to_h(
                                    b"\x8a]\xda\x15\xfbo\x05b\xc2cr\x0b8B\xb2:\xa8h\x13\xc7\xd1"
                                ),
                            ]
                        ),
                    )
                ],
            },
            {
                "in": (b"Hello, World!",),
                "out": [TxOutput(0, Script(["OP_RETURN", b_to_h(b"TESTXXXXHello, World!")]))],
            },
        ],
        "data_to_pubkey_pairs": [
            {
                "in": (b"Hello, World!" * 10,),
                "out": [
                    (
                        "023548656c6c6f2c20576f726c642148656c6c6f2c20576f726c642148656c6c9b",
                        "036f2c20576f726c642148656c6c6f2c20576f726c642148000000000000000094",
                    ),
                    (
                        "0235656c6c6f2c20576f726c642148656c6c6f2c20576f726c642148656c6c6f3c",
                        "032c20576f726c642148656c6c6f2c20576f726c64214865000000000000000009",
                    ),
                    (
                        "02186c6c6f2c20576f726c642148656c6c6f2c20576f726c642100000000000047",
                        "03000000000000000000000000000000000000000000000000000000000000000c",
                    ),
                ],
            },
            {
                "in": (b"Hello, World!" * 10, ARC4_KEY),
                "out": [
                    (
                        "03eb50ec2dcf58711add696c0b334fda08ab76108fd09b84e5294f6c7a42fa3333",
                        "02f184ec22681ff3dde4091fc9a75fd0024ee446f4499a2a9ec04b4f8b05a071da",
                    ),
                    (
                        "02eb7de52dcc1b7d6de57472037626f701ab755383a7a399fb210a05574bfa300d",
                        "02b2889b1a7501fb988d2416c9a41cdc7576f958fc0cf3079ec04b4f8b05a071a2",
                    ),
                    (
                        "03c674e52e8f170a55f86a7a461f0bfe01a8365ff49fbe87f3642b4d3227965f81",
                        "029ea8cc75076d9fb9c5417aa5cb30fc22198b34982dbb629ec04b4f8b05a07134",
                    ),
                ],
            },
        ],
        "prepare_multisig_output": [
            {
                "comment": "No encryption",
                "in": (b"Hello, World!" * 10, ADDR[0], PROVIDED_PUBKEYS),
                "out": [
                    TxOutput(
                        config.DEFAULT_MULTISIG_DUST_SIZE,
                        Script(
                            [
                                1,
                                "023548656c6c6f2c20576f726c642148656c6c6f2c20576f726c642148656c6c9b",
                                "036f2c20576f726c642148656c6c6f2c20576f726c642148000000000000000094",
                                DEFAULT_PARAMS["pubkey"][ADDR[0]],
                                3,
                                "OP_CHECKMULTISIG",
                            ]
                        ),
                    ),
                    TxOutput(
                        config.DEFAULT_MULTISIG_DUST_SIZE,
                        Script(
                            [
                                1,
                                "0235656c6c6f2c20576f726c642148656c6c6f2c20576f726c642148656c6c6f3c",
                                "032c20576f726c642148656c6c6f2c20576f726c64214865000000000000000009",
                                DEFAULT_PARAMS["pubkey"][ADDR[0]],
                                3,
                                "OP_CHECKMULTISIG",
                            ]
                        ),
                    ),
                    TxOutput(
                        config.DEFAULT_MULTISIG_DUST_SIZE,
                        Script(
                            [
                                1,
                                "02186c6c6f2c20576f726c642148656c6c6f2c20576f726c642100000000000047",
                                "03000000000000000000000000000000000000000000000000000000000000000c",
                                DEFAULT_PARAMS["pubkey"][ADDR[0]],
                                3,
                                "OP_CHECKMULTISIG",
                            ]
                        ),
                    ),
                ],
            },
            {
                "comment": "Encrypted",
                "in": (b"Hello, World!" * 10, ADDR[0], PROVIDED_PUBKEYS, ARC4_KEY),
                "out": [
                    TxOutput(
                        config.DEFAULT_MULTISIG_DUST_SIZE,
                        Script(
                            [
                                1,
                                "03eb50ec2dcf58711add696c0b334fda08ab76108fd09b84e5294f6c7a42fa3333",
                                "02f184ec22681ff3dde4091fc9a75fd0024ee446f4499a2a9ec04b4f8b05a071da",
                                DEFAULT_PARAMS["pubkey"][ADDR[0]],
                                3,
                                "OP_CHECKMULTISIG",
                            ]
                        ),
                    ),
                    TxOutput(
                        config.DEFAULT_MULTISIG_DUST_SIZE,
                        Script(
                            [
                                1,
                                "02eb7de52dcc1b7d6de57472037626f701ab755383a7a399fb210a05574bfa300d",
                                "02b2889b1a7501fb988d2416c9a41cdc7576f958fc0cf3079ec04b4f8b05a071a2",
                                DEFAULT_PARAMS["pubkey"][ADDR[0]],
                                3,
                                "OP_CHECKMULTISIG",
                            ]
                        ),
                    ),
                    TxOutput(
                        config.DEFAULT_MULTISIG_DUST_SIZE,
                        Script(
                            [
                                1,
                                "03c674e52e8f170a55f86a7a461f0bfe01a8365ff49fbe87f3642b4d3227965f81",
                                "029ea8cc75076d9fb9c5417aa5cb30fc22198b34982dbb629ec04b4f8b05a07134",
                                DEFAULT_PARAMS["pubkey"][ADDR[0]],
                                3,
                                "OP_CHECKMULTISIG",
                            ]
                        ),
                    ),
                ],
            },
        ],
        "prepare_data_outputs": [
            {
                "in": ("opreturn", b"Hello, World!", ADDR[0], None),
                "out": [TxOutput(0, Script(["OP_RETURN", b_to_h(b"TESTXXXXHello, World!")]))],
            },
            {
                "in": ("opreturn", b"Hello, World!" * 10, ADDR[0], PROVIDED_PUBKEYS),
                "error": (exceptions.TransactionError, "One `OP_RETURN` output per transaction"),
            },
            {
                "in": ("multisig", b"Hello, World!" * 10, ADDR[0], PROVIDED_PUBKEYS),
                "out": [
                    TxOutput(
                        config.DEFAULT_MULTISIG_DUST_SIZE,
                        Script(
                            [
                                1,
                                "023548656c6c6f2c20576f726c642148656c6c6f2c20576f726c642148656c6c9b",
                                "036f2c20576f726c642148656c6c6f2c20576f726c642148000000000000000094",
                                DEFAULT_PARAMS["pubkey"][ADDR[0]],
                                3,
                                "OP_CHECKMULTISIG",
                            ]
                        ),
                    ),
                    TxOutput(
                        config.DEFAULT_MULTISIG_DUST_SIZE,
                        Script(
                            [
                                1,
                                "0235656c6c6f2c20576f726c642148656c6c6f2c20576f726c642148656c6c6f3c",
                                "032c20576f726c642148656c6c6f2c20576f726c64214865000000000000000009",
                                DEFAULT_PARAMS["pubkey"][ADDR[0]],
                                3,
                                "OP_CHECKMULTISIG",
                            ]
                        ),
                    ),
                    TxOutput(
                        config.DEFAULT_MULTISIG_DUST_SIZE,
                        Script(
                            [
                                1,
                                "02186c6c6f2c20576f726c642148656c6c6f2c20576f726c642100000000000047",
                                "03000000000000000000000000000000000000000000000000000000000000000c",
                                DEFAULT_PARAMS["pubkey"][ADDR[0]],
                                3,
                                "OP_CHECKMULTISIG",
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
                    TxOutput(9999, P2pkhAddress(ADDR[0]).to_script_pub_key()),
                    TxOutput(0, Script(["OP_RETURN", b_to_h(b"TESTXXXXHello, World!")])),
                ],
            },
            {
                "in": (ADDR[0], [(ADDR[0], 9999)], b"Hello, World!", None, "opreturn", ARC4_KEY),
                "out": [
                    TxOutput(9999, P2pkhAddress(ADDR[0]).to_script_pub_key()),
                    TxOutput(
                        0,
                        Script(
                            [
                                "OP_RETURN",
                                b_to_h(
                                    b"\x8a]\xda\x15\xfbo\x05b\xc2cr\x0b8B\xb2:\xa8h\x13\xc7\xd1"
                                ),
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
                    TxOutput(9999, P2pkhAddress(ADDR[0]).to_script_pub_key()),
                    TxOutput(
                        config.DEFAULT_MULTISIG_DUST_SIZE,
                        Script(
                            [
                                1,
                                "023548656c6c6f2c20576f726c642148656c6c6f2c20576f726c642148656c6c9b",
                                "036f2c20576f726c642148656c6c6f2c20576f726c642148000000000000000094",
                                DEFAULT_PARAMS["pubkey"][ADDR[0]],
                                3,
                                "OP_CHECKMULTISIG",
                            ]
                        ),
                    ),
                    TxOutput(
                        config.DEFAULT_MULTISIG_DUST_SIZE,
                        Script(
                            [
                                1,
                                "0235656c6c6f2c20576f726c642148656c6c6f2c20576f726c642148656c6c6f3c",
                                "032c20576f726c642148656c6c6f2c20576f726c64214865000000000000000009",
                                DEFAULT_PARAMS["pubkey"][ADDR[0]],
                                3,
                                "OP_CHECKMULTISIG",
                            ]
                        ),
                    ),
                    TxOutput(
                        config.DEFAULT_MULTISIG_DUST_SIZE,
                        Script(
                            [
                                1,
                                "02186c6c6f2c20576f726c642148656c6c6f2c20576f726c642100000000000047",
                                "03000000000000000000000000000000000000000000000000000000000000000c",
                                DEFAULT_PARAMS["pubkey"][ADDR[0]],
                                3,
                                "OP_CHECKMULTISIG",
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
                    TxOutput(9999, P2pkhAddress(ADDR[0]).to_script_pub_key()),
                    TxOutput(
                        config.DEFAULT_MULTISIG_DUST_SIZE,
                        Script(
                            [
                                1,
                                "03eb50ec2dcf58711add696c0b334fda08ab76108fd09b84e5294f6c7a42fa3333",
                                "02f184ec22681ff3dde4091fc9a75fd0024ee446f4499a2a9ec04b4f8b05a071da",
                                DEFAULT_PARAMS["pubkey"][ADDR[0]],
                                3,
                                "OP_CHECKMULTISIG",
                            ]
                        ),
                    ),
                    TxOutput(
                        config.DEFAULT_MULTISIG_DUST_SIZE,
                        Script(
                            [
                                1,
                                "02eb7de52dcc1b7d6de57472037626f701ab755383a7a399fb210a05574bfa300d",
                                "02b2889b1a7501fb988d2416c9a41cdc7576f958fc0cf3079ec04b4f8b05a071a2",
                                DEFAULT_PARAMS["pubkey"][ADDR[0]],
                                3,
                                "OP_CHECKMULTISIG",
                            ]
                        ),
                    ),
                    TxOutput(
                        config.DEFAULT_MULTISIG_DUST_SIZE,
                        Script(
                            [
                                1,
                                "03c674e52e8f170a55f86a7a461f0bfe01a8365ff49fbe87f3642b4d3227965f81",
                                "029ea8cc75076d9fb9c5417aa5cb30fc22198b34982dbb629ec04b4f8b05a07134",
                                DEFAULT_PARAMS["pubkey"][ADDR[0]],
                                3,
                                "OP_CHECKMULTISIG",
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
