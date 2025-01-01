import binascii

from bitcoinutils.keys import P2pkhAddress, P2wpkhAddress
from bitcoinutils.script import Script, b_to_h
from bitcoinutils.transactions import Transaction, TxInput, TxOutput

from counterpartycore.lib import config, exceptions

from ..params import (
    ADDR,
    DEFAULT_PARAMS,
    MULTISIGADDR,
    P2WPKH_ADDR,
)

PROVIDED_PUBKEYS = ",".join([DEFAULT_PARAMS["pubkey"][ADDR[0]], DEFAULT_PARAMS["pubkey"][ADDR[1]]])

ARC4_KEY = "0000000000000000000000000000000000000000000000000000000000000000"
UTXO_1 = "344dcc8909ca3a137630726d0071dfd2df4f7c855bac150c7d3a8367835c90bc:1"
UTXO_2 = "4f0433ba841038e2e16328445930dd7bca35309b14b0da4451c8f94c631368b8:1"
UTXO_3 = "1fc2e5a57f584b2f2edd05676e75c33d03eed1d3098cc0550ea33474e3ec9db1:1"

MULTISIG_PAIRS = [
    (
        "02e34ccc12f76f0562d24e7b0b3b01be4d90750dcf94eda3f22947221e07c1300e",
        "02ecc4a8544f08f3d5aa6d5af2a442904638c351f441d44ebe97243de761813949",
    ),
    (
        "02e34ccc12f76f0562d263720b3842b23aa86813c7d1848efb2944611270f92d2a",
        "03f2cced3d6201f3d6e9612dcab95c980351ee58f4429742c9af3923ef24e814be",
    ),
    (
        "02fe4ccc12f76f0562d26a72087b4ec502b5761b82b8a987fb2a076d6548e43335",
        "02fa89cc75076d9fb9c5417aa5cb30fc22198b34982dbb629ec04b4f8b05a071ab",
    ),
]
OPRETURN_DATA = b"\x8a]\xda\x15\xfbo\x05b\xc2cr\x0b8B\xb2:\xa8h\x13\xc7\xd1"

COMPOSER_VECTOR = {
    "composer": {
        "address_to_script_pub_key": [
            {
                "comment": "P2PKH address",
                "in": (ADDR[0], [], {}),
                "out": P2pkhAddress(ADDR[0]).to_script_pub_key(),
            },
            {
                "comment": "P2WPKH address",
                "in": (P2WPKH_ADDR[0], [], {}),
                "out": P2wpkhAddress(P2WPKH_ADDR[0]).to_script_pub_key(),
            },
            {
                "comment": "multisig address",
                "in": (MULTISIGADDR[0], [], {"pubkeys": PROVIDED_PUBKEYS}),
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
        "create_tx_output": [
            {
                "comment": "from address",
                "in": (666, ADDR[0], [], {}),
                "out": TxOutput(666, P2pkhAddress(ADDR[0]).to_script_pub_key()),
            },
            {
                "comment": "from script",
                "in": (666, P2pkhAddress(ADDR[0]).to_script_pub_key().to_hex(), [], {}),
                "out": TxOutput(666, P2pkhAddress(ADDR[0]).to_script_pub_key()),
            },
            {
                "comment": "from script",
                "in": (666, "00aaff", [], {}),
                "out": TxOutput(666, Script.from_raw("00aaff")),
            },
            {
                "comment": "from invalid script",
                "in": (666, "00aafff", [], {}),
                "error": (
                    exceptions.ComposeError,
                    "Invalid script or address for output: 00aafff (error: invalid script)",
                ),
            },
            {
                "comment": "from invalid address",
                "in": (666, "toto", [], {}),
                "error": (
                    exceptions.ComposeError,
                    "Invalid script or address for output: toto (error: Invalid address: toto)",
                ),
            },
        ],
        "regular_dust_size": [
            {
                "in": ({},),
                "out": 546,
            },
            {
                "in": ({"regular_dust_size": 666},),
                "out": 666,
            },
            {
                "in": ({"regular_dust_size": None},),
                "out": 546,
            },
        ],
        "multisig_dust_size": [
            {
                "in": ({},),
                "out": 1000,
            },
            {
                "in": ({"multisig_dust_size": 666},),
                "out": 666,
            },
            {
                "in": ({"multisig_dust_size": None},),
                "out": 1000,
            },
        ],
        "dust_size": [
            {
                "in": (ADDR[0], {}),
                "out": 546,
            },
            {
                "in": (ADDR[0], {"regular_dust_size": 666}),
                "out": 666,
            },
            {
                "in": (MULTISIGADDR[0], {}),
                "out": 1000,
            },
            {
                "in": (MULTISIGADDR[0], {"multisig_dust_size": 666}),
                "out": 666,
            },
        ],
        "perpare_non_data_outputs": [
            {
                "comment": "P2PKH address",
                "in": ([(ADDR[0], 0)], [], {}),
                "out": [TxOutput(546, P2pkhAddress(ADDR[0]).to_script_pub_key())],
            },
            {
                "comment": "Multisig address",
                "in": ([(MULTISIGADDR[0], 0)], [], {"pubkeys": PROVIDED_PUBKEYS}),
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
                "in": ([(ADDR[0], 2024)], [], {}),
                "out": [TxOutput(2024, P2pkhAddress(ADDR[0]).to_script_pub_key())],
            },
        ],
        "determine_encoding": [
            {
                "in": (b"Hello, World!", {}),
                "out": "opreturn",
            },
            {
                "in": (b"Hello, World!" * 100, {}),
                "out": "multisig",
            },
            {
                "in": (b"Hello, World!", {"encoding": "p2sh"}),
                "error": (exceptions.ComposeError, "Not supported encoding: p2sh"),
            },
            {
                "in": (b"Hello, World!", {"encoding": "toto"}),
                "error": (exceptions.ComposeError, "Not supported encoding: toto"),
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
                                b_to_h(OPRETURN_DATA),
                            ]
                        ),
                    )
                ],
            },
        ],
        "is_valid_pubkey": [
            {
                "in": (DEFAULT_PARAMS["pubkey"][ADDR[0]],),
                "out": True,
            },
            {
                "in": (DEFAULT_PARAMS["pubkey"][ADDR[0]][::-1],),
                "out": False,
            },
        ],
        "search_pubkey": [
            {
                "in": (ADDR[0], [], {}),
                "out": DEFAULT_PARAMS["pubkey"][ADDR[0]],
            },
            {
                "in": (ADDR[0], [], {"pubkeys": PROVIDED_PUBKEYS}),
                "out": DEFAULT_PARAMS["pubkey"][ADDR[0]],
            },
        ],
        "make_valid_pubkey": [
            {
                "in": (binascii.unhexlify("aa" * 31),),
                "out": b"\x02\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa|",
            },
            {
                "in": (binascii.unhexlify("bb" * 31),),
                "out": b"\x03\xbb\xbb\xbb\xbb\xbb\xbb\xbb\xbb\xbb\xbb\xbb\xbb\xbb\xbb\xbb\xbb\xbb\xbb\xbb\xbb\xbb\xbb\xbb\xbb\xbb\xbb\xbb\xbb\xbb\xbb\xbb\xc4",
            },
        ],
        "data_to_pubkey_pairs": [
            {
                "in": (b"Hello, World!" * 10, ARC4_KEY),
                "out": MULTISIG_PAIRS,
            },
        ],
        "prepare_multisig_output": [
            {
                "comment": "Encrypted",
                "in": (ADDR[0], b"Hello, World!" * 10, ARC4_KEY, [], {"pubkeys": PROVIDED_PUBKEYS}),
                "out": [
                    TxOutput(
                        config.DEFAULT_MULTISIG_DUST_SIZE,
                        Script(
                            [
                                1,
                                MULTISIG_PAIRS[0][0],
                                MULTISIG_PAIRS[0][1],
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
                                MULTISIG_PAIRS[1][0],
                                MULTISIG_PAIRS[1][1],
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
                                MULTISIG_PAIRS[2][0],
                                MULTISIG_PAIRS[2][1],
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
                "in": (ADDR[0], b"Hello, World!", [{"txid": ARC4_KEY}], {}),
                "out": [TxOutput(0, Script(["OP_RETURN", b_to_h(OPRETURN_DATA)]))],
            },
            {
                "in": (
                    ADDR[0],
                    b"Hello, World!" * 10,
                    [{"txid": ARC4_KEY}],
                    {"pubkeys": PROVIDED_PUBKEYS, "encoding": "opreturn"},
                ),
                "error": (exceptions.ComposeError, "One `OP_RETURN` output per transaction"),
            },
            {
                "in": (
                    ADDR[0],
                    b"Hello, World!" * 10,
                    [{"txid": ARC4_KEY}],
                    {"pubkeys": PROVIDED_PUBKEYS, "encoding": "multisig"},
                ),
                "out": [
                    TxOutput(
                        config.DEFAULT_MULTISIG_DUST_SIZE,
                        Script(
                            [
                                1,
                                MULTISIG_PAIRS[0][0],
                                MULTISIG_PAIRS[0][1],
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
                                MULTISIG_PAIRS[1][0],
                                MULTISIG_PAIRS[1][1],
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
                                MULTISIG_PAIRS[2][0],
                                MULTISIG_PAIRS[2][1],
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
                    b"Hello, World!" * 10,
                    [],
                    {"pubkeys": PROVIDED_PUBKEYS, "encoding": "p2sh"},
                ),
                "error": (exceptions.ComposeError, "Not supported encoding: p2sh"),
            },
        ],
        "prepare_more_outputs": [
            {
                "in": (f"546:{ADDR[0]}", [], {}),
                "out": [TxOutput(546, P2pkhAddress(ADDR[0]).to_script_pub_key())],
            },
            {
                "comment": "Multisig address",
                "in": (f"546:{MULTISIGADDR[0]}", [], {"pubkeys": PROVIDED_PUBKEYS}),
                "out": [
                    TxOutput(
                        546,
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
                "in": (f"2024:{ADDR[0]}", [], {}),
                "out": [TxOutput(2024, P2pkhAddress(ADDR[0]).to_script_pub_key())],
            },
            {
                "in": ("666:00aaff", [], {}),
                "out": [TxOutput(666, Script.from_raw("00aaff"))],
            },
            {
                "in": (
                    f"546:{ADDR[0]},546:{MULTISIGADDR[0]},2024:{ADDR[0]},666:00aaff",
                    [],
                    {"pubkeys": PROVIDED_PUBKEYS},
                ),
                "out": [
                    TxOutput(546, P2pkhAddress(ADDR[0]).to_script_pub_key()),
                    TxOutput(
                        546,
                        Script(
                            [
                                1,
                                DEFAULT_PARAMS["pubkey"][ADDR[0]],
                                DEFAULT_PARAMS["pubkey"][ADDR[1]],
                                2,
                                "OP_CHECKMULTISIG",
                            ]
                        ),
                    ),
                    TxOutput(2024, P2pkhAddress(ADDR[0]).to_script_pub_key()),
                    TxOutput(666, Script.from_raw("00aaff")),
                ],
            },
        ],
        "prepare_outputs": [
            {
                "in": (ADDR[0], [(ADDR[0], 9999)], b"Hello, World!", [{"txid": ARC4_KEY}], {}),
                "out": [
                    TxOutput(9999, P2pkhAddress(ADDR[0]).to_script_pub_key()),
                    TxOutput(0, Script(["OP_RETURN", b_to_h(OPRETURN_DATA)])),
                ],
            },
            {
                "in": (ADDR[0], [(ADDR[0], 9999)], b"Hello, World!", [{"txid": ARC4_KEY}], {}),
                "out": [
                    TxOutput(9999, P2pkhAddress(ADDR[0]).to_script_pub_key()),
                    TxOutput(
                        0,
                        Script(
                            [
                                "OP_RETURN",
                                b_to_h(OPRETURN_DATA),
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
                    [{"txid": ARC4_KEY}],
                    {"pubkeys": PROVIDED_PUBKEYS, "encoding": "multisig"},
                ),
                "out": [
                    TxOutput(9999, P2pkhAddress(ADDR[0]).to_script_pub_key()),
                    TxOutput(
                        config.DEFAULT_MULTISIG_DUST_SIZE,
                        Script(
                            [
                                1,
                                MULTISIG_PAIRS[0][0],
                                MULTISIG_PAIRS[0][1],
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
                                MULTISIG_PAIRS[1][0],
                                MULTISIG_PAIRS[1][1],
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
                                MULTISIG_PAIRS[2][0],
                                MULTISIG_PAIRS[2][1],
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
                    [{"txid": ARC4_KEY}],
                    {
                        "pubkeys": PROVIDED_PUBKEYS,
                        "encoding": "multisig",
                        "more_outputs": f"546:{ADDR[0]}",
                    },
                ),
                "out": [
                    TxOutput(9999, P2pkhAddress(ADDR[0]).to_script_pub_key()),
                    TxOutput(
                        config.DEFAULT_MULTISIG_DUST_SIZE,
                        Script(
                            [
                                1,
                                MULTISIG_PAIRS[0][0],
                                MULTISIG_PAIRS[0][1],
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
                                MULTISIG_PAIRS[1][0],
                                MULTISIG_PAIRS[1][1],
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
                                MULTISIG_PAIRS[2][0],
                                MULTISIG_PAIRS[2][1],
                                DEFAULT_PARAMS["pubkey"][ADDR[0]],
                                3,
                                "OP_CHECKMULTISIG",
                            ]
                        ),
                    ),
                    TxOutput(546, P2pkhAddress(ADDR[0]).to_script_pub_key()),
                ],
            },
        ],
        "complete_unspent_list": [
            {
                "in": (
                    [
                        {
                            "txid": "ae241be7be83ebb14902757ad94854f787d9730fc553d6f695346c9375c0d8c1",
                            "vout": 0,
                        }
                    ],
                ),
                "out": [
                    {
                        "txid": "ae241be7be83ebb14902757ad94854f787d9730fc553d6f695346c9375c0d8c1",
                        "vout": 0,
                        "value": 199909140,
                        "amount": 1.9990914,
                        "script_pub_key": "76a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788ac",
                        "is_segwit": False,
                    }
                ],
            },
            {
                "in": (
                    [
                        {
                            "txid": "ae241be7be83ebb14902757ad94854f787d9730fc553d6f695346c9375c0d8c2",
                            "vout": 0,
                        }
                    ],
                ),
                "error": (
                    exceptions.ComposeError,
                    "invalid UTXO: ae241be7be83ebb14902757ad94854f787d9730fc553d6f695346c9375c0d8c2:0 (transaction not found)",
                ),
            },
        ],
        "prepare_inputs_set": [
            {
                "in": ("aabb",),
                "error": (exceptions.ComposeError, "invalid UTXO: aabb (invalid format)"),
            },
            {
                "in": ("aa:bb:cc:dd:ee",),
                "error": (exceptions.ComposeError, "invalid UTXO: aa:bb:cc:dd:ee (invalid format)"),
            },
            {
                "in": ("aa:3:cc:dd",),
                "error": (exceptions.ComposeError, "invalid UTXO: aa:3:cc:dd (invalid format)"),
            },
            {
                "in": ("ae241be7be83ebb14902757ad94854f787d9730fc553d6f695346c9375c0d8c1:0:aa",),
                "error": (
                    exceptions.ComposeError,
                    "invalid UTXO: ae241be7be83ebb14902757ad94854f787d9730fc553d6f695346c9375c0d8c1:0:aa (invalid value)",
                ),
            },
            {
                "in": (
                    "ae241be7be83ebb14902757ad94854f787d9730fc553d6f695346c9375c0d8c1:0:100:aagh",
                ),
                "error": (
                    exceptions.ComposeError,
                    "invalid UTXO: ae241be7be83ebb14902757ad94854f787d9730fc553d6f695346c9375c0d8c1:0:100:aagh (invalid script_pub_key)",
                ),
            },
            {
                "in": (
                    "ae241be7be83ebb14902757ad94854f787d9730fc553d6f695346c9375c0d8c1:0:100:aa00",
                ),
                "out": [
                    {
                        "txid": "ae241be7be83ebb14902757ad94854f787d9730fc553d6f695346c9375c0d8c1",
                        "vout": 0,
                        "value": 100,
                        "script_pub_key": "aa00",
                    }
                ],
            },
            {
                "in": (
                    "ae241be7be83ebb14902757ad94854f787d9730fc553d6f695346c9375c0d8c1:0:100:aa00,ae241be7be83ebb14902757ad94854f787d9730fc553d6f695346c9375c0d8c2:0:200:aa00",
                ),
                "out": [
                    {
                        "txid": "ae241be7be83ebb14902757ad94854f787d9730fc553d6f695346c9375c0d8c1",
                        "vout": 0,
                        "value": 100,
                        "script_pub_key": "aa00",
                    },
                    {
                        "txid": "ae241be7be83ebb14902757ad94854f787d9730fc553d6f695346c9375c0d8c2",
                        "vout": 0,
                        "value": 200,
                        "script_pub_key": "aa00",
                    },
                ],
            },
        ],
        "utxo_to_address": [
            {
                "in": ("d4be9b18026da66d35949ca0a6944e8404e9e9787c05abc5f37bbf5afaabd600:0",),
                "out": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc",
            },
            {
                "in": ("ae241be7be83ebb14902757ad94854f787d9730fc553d6f695346c9375c0d8c1:0",),
                "out": ADDR[0],
            },
            {
                "in": ("ae241be7be83ebb14902757ad94854f787d9730fc553d6f695346c9375c0d8c2:0",),
                "error": (
                    exceptions.ComposeError,
                    "invalid UTXO: ae241be7be83ebb14902757ad94854f787d9730fc553d6f695346c9375c0d8c2:0 (not found in the database or Bitcoin Core)",
                ),
            },
        ],
        "prepare_unspent_list": [
            {
                "in": (
                    ADDR[0],
                    {},
                ),
                "out": [
                    {
                        "txid": "ae241be7be83ebb14902757ad94854f787d9730fc553d6f695346c9375c0d8c1",
                        "vout": 0,
                        "value": 199909140,
                        "amount": 1.9990914,
                        "script_pub_key": "76a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788ac",
                        "is_segwit": False,
                    }
                ],
            }
        ],
        "utxos_to_txins": [
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
                ),
                "out": [
                    TxInput(UTXO_1.split(":")[0], int(UTXO_1.split(":")[1])),
                    TxInput(UTXO_2.split(":")[0], int(UTXO_2.split(":")[1])),
                    TxInput(UTXO_3.split(":")[0], int(UTXO_3.split(":")[1])),
                ],
            }
        ],
        "get_needed_fee": [
            {
                "in": (
                    Transaction(
                        [
                            TxInput(UTXO_1.split(":")[0], int(UTXO_1.split(":")[1])),
                            TxInput(UTXO_2.split(":")[0], int(UTXO_2.split(":")[1])),
                            TxInput(UTXO_3.split(":")[0], int(UTXO_3.split(":")[1])),
                        ],
                        [
                            TxOutput(9999, P2pkhAddress(ADDR[0]).to_script_pub_key()),
                            TxOutput(
                                config.DEFAULT_MULTISIG_DUST_SIZE,
                                Script(
                                    [
                                        1,
                                        MULTISIG_PAIRS[0][0],
                                        MULTISIG_PAIRS[0][1],
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
                                        MULTISIG_PAIRS[1][0],
                                        MULTISIG_PAIRS[1][1],
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
                                        MULTISIG_PAIRS[2][0],
                                        MULTISIG_PAIRS[2][1],
                                        DEFAULT_PARAMS["pubkey"][ADDR[0]],
                                        3,
                                        "OP_CHECKMULTISIG",
                                    ]
                                ),
                            ),
                        ],
                    ),
                    3,
                ),
                "out": 1527,
            },
            {
                "in": (
                    Transaction(
                        [
                            TxInput(UTXO_1.split(":")[0], int(UTXO_1.split(":")[1])),
                            TxInput(UTXO_2.split(":")[0], int(UTXO_2.split(":")[1])),
                            TxInput(UTXO_3.split(":")[0], int(UTXO_3.split(":")[1])),
                        ],
                        [
                            TxOutput(9999, P2pkhAddress(ADDR[0]).to_script_pub_key()),
                            TxOutput(
                                config.DEFAULT_MULTISIG_DUST_SIZE,
                                Script(
                                    [
                                        1,
                                        MULTISIG_PAIRS[0][0],
                                        MULTISIG_PAIRS[0][1],
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
                                        MULTISIG_PAIRS[1][0],
                                        MULTISIG_PAIRS[1][1],
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
                                        MULTISIG_PAIRS[2][0],
                                        MULTISIG_PAIRS[2][1],
                                        DEFAULT_PARAMS["pubkey"][ADDR[0]],
                                        3,
                                        "OP_CHECKMULTISIG",
                                    ]
                                ),
                            ),
                        ],
                    ),
                    6,
                ),
                "out": 3054,
            },
        ],
    }
}
