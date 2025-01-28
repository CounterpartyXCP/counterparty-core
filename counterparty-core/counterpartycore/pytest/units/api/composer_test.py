import binascii
import re

import pytest
from bitcoinutils.keys import P2pkhAddress, P2wpkhAddress
from bitcoinutils.script import Script
from bitcoinutils.transactions import TxInput, TxOutput, TxWitnessInput
from counterpartycore.lib import config, exceptions
from counterpartycore.lib.api import composer
from counterpartycore.pytest.fixtures.defaults import DEFAULT_PARAMS as DEFAULTS

PROVIDED_PUBKEYS = ",".join(
    [DEFAULTS["pubkey"][DEFAULTS["addresses"][0]], DEFAULTS["pubkey"][DEFAULTS["addresses"][1]]]
)

ARC4_KEY = "0000000000000000000000000000000000000000000000000000000000000000"
UTXO_1 = "344dcc8909ca3a137630726d0071dfd2df4f7c855bac150c7d3a8345235c90bc:1"
UTXO_2 = "4f0433ba841038e2e16328445930dd7bca35309b14b0da4451c8f94c631368b8:1"
UTXO_3 = "1fc2e5a57f584b2f2edd05676e75c33d03eed1d3098cc0550ea33474e3ec9db1:1"

MULTISIG_PAIRS = [
    (
        "02e35bc715f1670f6ed34e7b0b3b01be4d90750dcf94eda3f22947221e07c130ac",
        "02ecc4a8544f08f3d5aa6d5af2a442904638c351f441d44ebe97243de761813949",
    ),
    (
        "03e35bc715f1670f6ed363720b3842b23aa86813c7d1848efb2944611270f92d4f",
        "03f2cced3d6201f3d6e9612dcab95c980351ee58f4429742c9af3923ef24e814be",
    ),
    (
        "03fe5bc715f1670f6ed36a72087b4ec502b5761b82b8a987fb2a076d6548e4330d",
        "02fa89cc75076d9fb9c5417aa5cb30fc22198b34982dbb629ec04b4f8b05a071ab",
    ),
]
OPRETURN_DATA = "9d56dd13f3650963c263720b3842b23aa86813c7d1"


def test_address_to_script_pub_key(defaults):
    assert (
        composer.address_to_script_pub_key(defaults["addresses"][0], [], {})
        == P2pkhAddress(defaults["addresses"][0]).to_script_pub_key()
    )
    assert (
        composer.address_to_script_pub_key(defaults["p2wpkh_addresses"][0], [], {})
        == P2wpkhAddress(defaults["p2wpkh_addresses"][0]).to_script_pub_key()
    )
    assert composer.address_to_script_pub_key(
        defaults["p2ms_addresses"][0], [], {"pubkeys": PROVIDED_PUBKEYS}
    ) == Script(
        [
            1,
            defaults["pubkey"][defaults["addresses"][0]],
            defaults["pubkey"][defaults["addresses"][1]],
            2,
            "OP_CHECKMULTISIG",
        ]
    )


def test_create_tx_output(defaults):
    assert str(composer.create_tx_output(666, defaults["addresses"][0], [], {})) == str(
        TxOutput(666, P2pkhAddress(defaults["addresses"][0]).to_script_pub_key())
    )

    assert str(
        composer.create_tx_output(
            666, P2pkhAddress(defaults["addresses"][0]).to_script_pub_key().to_hex(), [], {}
        )
    ) == str(TxOutput(666, P2pkhAddress(defaults["addresses"][0]).to_script_pub_key()))

    assert str(composer.create_tx_output(666, "00aaff", [], {})) == str(
        TxOutput(666, Script.from_raw("00aaff"))
    )

    with pytest.raises(
        exceptions.ComposeError,
        match=re.escape("Invalid script or address for output: 00aafff (error: invalid script)"),
    ):
        composer.create_tx_output(666, "00aafff", [], {})

    with pytest.raises(
        exceptions.ComposeError,
        match=re.escape(
            "Invalid script or address for output: toto (error: Invalid address: toto)"
        ),
    ):
        composer.create_tx_output(666, "toto", [], {})


def test_dust_size(defaults):
    assert composer.regular_dust_size({}) == 546
    assert composer.regular_dust_size({"regular_dust_size": 666}) == 666
    assert composer.regular_dust_size({"regular_dust_size": None}) == 546
    assert composer.multisig_dust_size({}) == 1000
    assert composer.multisig_dust_size({"multisig_dust_size": 666}) == 666
    assert composer.multisig_dust_size({"multisig_dust_size": None}) == 1000
    assert composer.dust_size(defaults["addresses"][0], {}) == 546
    assert composer.dust_size(defaults["addresses"][0], {"regular_dust_size": 666}) == 666
    assert composer.dust_size(defaults["p2ms_addresses"][0], {}) == 1000
    assert composer.dust_size(defaults["p2ms_addresses"][0], {"multisig_dust_size": 666}) == 666


def test_prepare_non_data_outputs(defaults):
    # P2PKH address
    assert str(composer.perpare_non_data_outputs([(defaults["addresses"][0], 0)], [], {})) == str(
        [TxOutput(546, P2pkhAddress(defaults["addresses"][0]).to_script_pub_key())]
    )

    # Multisig address
    assert str(
        composer.perpare_non_data_outputs(
            [(defaults["p2ms_addresses"][0], 0)], [], {"pubkeys": PROVIDED_PUBKEYS}
        )
    ) == str(
        [
            TxOutput(
                1000,
                Script(
                    [
                        1,
                        defaults["pubkey"][defaults["addresses"][0]],
                        defaults["pubkey"][defaults["addresses"][1]],
                        2,
                        "OP_CHECKMULTISIG",
                    ]
                ),
            )
        ]
    )

    # Custom amount
    assert str(
        composer.perpare_non_data_outputs([(defaults["addresses"][0], 2024)], [], {})
    ) == str([TxOutput(2024, P2pkhAddress(defaults["addresses"][0]).to_script_pub_key())])


def test_determine_encoding():
    assert composer.determine_encoding(b"Hello, World!", {}) == "opreturn"
    assert composer.determine_encoding(b"Hello, World!" * 100, {}) == "multisig"

    with pytest.raises(exceptions.ComposeError, match="Not supported encoding: p2sh"):
        composer.determine_encoding(b"Hello, World!", {"encoding": "p2sh"})

    with pytest.raises(exceptions.ComposeError, match="Not supported encoding: toto"):
        composer.determine_encoding(b"Hello, World!", {"encoding": "toto"})


def test_encrypt_data():
    assert composer.encrypt_data(b"Hello, World!", ARC4_KEY) == b"\x96}\xe5-\xcc\x1b}m\xe5tr\x03v"


def test_prepare_opreturn_output():
    assert str(composer.prepare_opreturn_output(b"Hello, World!", ARC4_KEY)) == str(
        [
            TxOutput(
                0,
                Script(
                    [
                        "OP_RETURN",
                        OPRETURN_DATA,
                    ]
                ),
            )
        ]
    )


def test_is_valid_pubkey(defaults):
    assert composer.is_valid_pubkey(defaults["pubkey"][defaults["addresses"][0]]) is True
    assert composer.is_valid_pubkey(defaults["pubkey"][defaults["addresses"][0]][::-1]) is False


def test_search_pubkey(defaults):
    assert (
        composer.search_pubkey(defaults["addresses"][0], [], {})
        == defaults["pubkey"][defaults["addresses"][0]]
    )
    assert (
        composer.search_pubkey(defaults["addresses"][0], [], {"pubkeys": PROVIDED_PUBKEYS})
        == defaults["pubkey"][defaults["addresses"][0]]
    )


def test_make_valid_pubkey():
    assert composer.make_valid_pubkey(binascii.unhexlify("aa" * 31)) == (
        b"\x02\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa"
        b"\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa|"
    )
    assert composer.make_valid_pubkey(binascii.unhexlify("bb" * 31)) == (
        b"\x03\xbb\xbb\xbb\xbb\xbb\xbb\xbb\xbb\xbb\xbb\xbb\xbb\xbb\xbb\xbb"
        b"\xbb\xbb\xbb\xbb\xbb\xbb\xbb\xbb\xbb\xbb\xbb\xbb\xbb\xbb\xbb\xbb\xc4"
    )


def test_data_to_pubkey_pairs():
    assert composer.data_to_pubkey_pairs(b"Hello, World!" * 10, ARC4_KEY) == MULTISIG_PAIRS


def test_prepare_multisig_output(defaults):
    assert str(
        composer.prepare_multisig_output(
            defaults["addresses"][0],
            b"Hello, World!" * 10,
            ARC4_KEY,
            [],
            {"pubkeys": PROVIDED_PUBKEYS},
        )
    ) == str(
        [
            TxOutput(
                config.DEFAULT_MULTISIG_DUST_SIZE,
                Script(
                    [
                        1,
                        MULTISIG_PAIRS[0][0],
                        MULTISIG_PAIRS[0][1],
                        defaults["pubkey"][defaults["addresses"][0]],
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
                        defaults["pubkey"][defaults["addresses"][0]],
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
                        defaults["pubkey"][defaults["addresses"][0]],
                        3,
                        "OP_CHECKMULTISIG",
                    ]
                ),
            ),
        ]
    )


def test_prepare_data_outputs(defaults):
    # Test case 1: Simple OP_RETURN output
    assert str(
        composer.prepare_data_outputs(
            defaults["addresses"][0], b"Hello, World!", [{"txid": ARC4_KEY}], {}
        )
    ) == str([TxOutput(0, Script(["OP_RETURN", OPRETURN_DATA]))])

    # Test case 2: Error case - multiple OP_RETURN not allowed
    with pytest.raises(exceptions.ComposeError, match="One `OP_RETURN` output per transaction"):
        composer.prepare_data_outputs(
            defaults["addresses"][0],
            b"Hello, World!" * 10,
            [{"txid": ARC4_KEY}],
            {"pubkeys": PROVIDED_PUBKEYS, "encoding": "opreturn"},
        )

    # Test case 3: Multisig encoding
    assert str(
        composer.prepare_data_outputs(
            defaults["addresses"][0],
            b"Hello, World!" * 10,
            [{"txid": ARC4_KEY}],
            {"pubkeys": PROVIDED_PUBKEYS, "encoding": "multisig"},
        )
    ) == str(
        [
            TxOutput(
                config.DEFAULT_MULTISIG_DUST_SIZE,
                Script(
                    [
                        1,
                        MULTISIG_PAIRS[0][0],
                        MULTISIG_PAIRS[0][1],
                        defaults["pubkey"][defaults["addresses"][0]],
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
                        defaults["pubkey"][defaults["addresses"][0]],
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
                        defaults["pubkey"][defaults["addresses"][0]],
                        3,
                        "OP_CHECKMULTISIG",
                    ]
                ),
            ),
        ]
    )

    # Test case 4: Error case - p2sh encoding not supported
    with pytest.raises(exceptions.ComposeError, match="Not supported encoding: p2sh"):
        composer.prepare_data_outputs(
            defaults["addresses"][0],
            b"Hello, World!" * 10,
            [],
            {"pubkeys": PROVIDED_PUBKEYS, "encoding": "p2sh"},
        )


def test_prepare_more_outputs(defaults):
    # Test case 1: Simple P2PKH output
    assert str(composer.prepare_more_outputs(f"546:{defaults['addresses'][0]}", [], {})) == str(
        [TxOutput(546, P2pkhAddress(defaults["addresses"][0]).to_script_pub_key())]
    )

    # Test case 2: Multisig address
    assert str(
        composer.prepare_more_outputs(
            f"546:{defaults['p2ms_addresses'][0]}", [], {"pubkeys": PROVIDED_PUBKEYS}
        )
    ) == str(
        [
            TxOutput(
                546,
                Script(
                    [
                        1,
                        defaults["pubkey"][defaults["addresses"][0]],
                        defaults["pubkey"][defaults["addresses"][1]],
                        2,
                        "OP_CHECKMULTISIG",
                    ]
                ),
            )
        ]
    )

    # Test case 3: Custom amount
    assert str(composer.prepare_more_outputs(f"2024:{defaults['addresses'][0]}", [], {})) == str(
        [TxOutput(2024, P2pkhAddress(defaults["addresses"][0]).to_script_pub_key())]
    )

    # Test case 4: Raw script
    assert str(composer.prepare_more_outputs("666:00aaff", [], {})) == str(
        [TxOutput(666, Script.from_raw("00aaff"))]
    )

    # Test case 5: Multiple outputs
    assert str(
        composer.prepare_more_outputs(
            f"546:{defaults['addresses'][0]},546:{defaults['p2ms_addresses'][0]},2024:{defaults['addresses'][0]},666:00aaff",
            [],
            {"pubkeys": PROVIDED_PUBKEYS},
        )
    ) == str(
        [
            TxOutput(546, P2pkhAddress(defaults["addresses"][0]).to_script_pub_key()),
            TxOutput(
                546,
                Script(
                    [
                        1,
                        defaults["pubkey"][defaults["addresses"][0]],
                        defaults["pubkey"][defaults["addresses"][1]],
                        2,
                        "OP_CHECKMULTISIG",
                    ]
                ),
            ),
            TxOutput(2024, P2pkhAddress(defaults["addresses"][0]).to_script_pub_key()),
            TxOutput(666, Script.from_raw("00aaff")),
        ]
    )


def test_prepare_outputs(defaults):
    # Test case 1 & 2: Simple OP_RETURN output
    expected_output = str(
        [
            TxOutput(9999, P2pkhAddress(defaults["addresses"][0]).to_script_pub_key()),
            TxOutput(0, Script(["OP_RETURN", OPRETURN_DATA])),
        ]
    )

    assert (
        str(
            composer.prepare_outputs(
                defaults["addresses"][0],
                [(defaults["addresses"][0], 9999)],
                b"Hello, World!",
                [{"txid": ARC4_KEY}],
                {},
            )
        )
        == expected_output
    )

    # Test case 3: Multisig encoding
    assert str(
        composer.prepare_outputs(
            defaults["addresses"][0],
            [(defaults["addresses"][0], 9999)],
            b"Hello, World!" * 10,
            [{"txid": ARC4_KEY}],
            {"pubkeys": PROVIDED_PUBKEYS, "encoding": "multisig"},
        )
    ) == str(
        [
            TxOutput(9999, P2pkhAddress(defaults["addresses"][0]).to_script_pub_key()),
            *[
                TxOutput(
                    config.DEFAULT_MULTISIG_DUST_SIZE,
                    Script(
                        [
                            1,
                            pair[0],
                            pair[1],
                            defaults["pubkey"][defaults["addresses"][0]],
                            3,
                            "OP_CHECKMULTISIG",
                        ]
                    ),
                )
                for pair in MULTISIG_PAIRS
            ],
        ]
    )

    # Test case 4: Multisig with additional output
    assert str(
        composer.prepare_outputs(
            defaults["addresses"][0],
            [(defaults["addresses"][0], 9999)],
            b"Hello, World!" * 10,
            [{"txid": ARC4_KEY}],
            {
                "pubkeys": PROVIDED_PUBKEYS,
                "encoding": "multisig",
                "more_outputs": f"546:{defaults['addresses'][0]}",
            },
        )
    ) == str(
        [
            TxOutput(9999, P2pkhAddress(defaults["addresses"][0]).to_script_pub_key()),
            *[
                TxOutput(
                    config.DEFAULT_MULTISIG_DUST_SIZE,
                    Script(
                        [
                            1,
                            pair[0],
                            pair[1],
                            defaults["pubkey"][defaults["addresses"][0]],
                            3,
                            "OP_CHECKMULTISIG",
                        ]
                    ),
                )
                for pair in MULTISIG_PAIRS
            ],
            TxOutput(546, P2pkhAddress(defaults["addresses"][0]).to_script_pub_key()),
        ]
    )


def test_prepare_inputs_set(defaults):
    # Test case 1: Invalid format
    with pytest.raises(
        exceptions.ComposeError, match=re.escape("invalid UTXOs: aabb (invalid format)")
    ):
        composer.prepare_inputs_set("aabb")

    # Test case 2: Invalid format with multiple parts
    with pytest.raises(
        exceptions.ComposeError, match=re.escape("invalid UTXOs: aa:bb:cc:dd:ee (invalid format)")
    ):
        composer.prepare_inputs_set("aa:bb:cc:dd:ee")

    # Test case 3: Another invalid format
    with pytest.raises(
        exceptions.ComposeError, match=re.escape("invalid UTXOs: aa:3:cc:dd (invalid format)")
    ):
        composer.prepare_inputs_set("aa:3:cc:dd")

    # Test case 4: Invalid value
    with pytest.raises(
        exceptions.ComposeError,
        match=re.escape(
            "invalid UTXOs: ae241be7be83ebb14902757ad94854f787d9730fc553d6f695346c9375c0d8c1:0:aa (invalid value)"
        ),
    ):
        composer.prepare_inputs_set(
            "ae241be7be83ebb14902757ad94854f787d9730fc553d6f695346c9375c0d8c1:0:aa"
        )

    # Test case 5: Invalid script_pub_key
    with pytest.raises(
        exceptions.ComposeError,
        match=re.escape(
            "invalid UTXOs: ae241be7be83ebb14902757ad94854f787d9730fc553d6f695346c9375c0d8c1:0:100:aagh (invalid script_pub_key)"
        ),
    ):
        composer.prepare_inputs_set(
            "ae241be7be83ebb14902757ad94854f787d9730fc553d6f695346c9375c0d8c1:0:100:aagh"
        )

    # Test case 6: Valid single input
    assert composer.prepare_inputs_set(
        "ae241be7be83ebb14902757ad94854f787d9730fc553d6f695346c9375c0d8c1:0:100:aa00"
    ) == [
        {
            "txid": "ae241be7be83ebb14902757ad94854f787d9730fc553d6f695346c9375c0d8c1",
            "vout": 0,
            "value": 100,
            "script_pub_key": "aa00",
        }
    ]

    # Test case 7: Valid multiple inputs
    assert composer.prepare_inputs_set(
        "ae241be7be83ebb14902757ad94854f787d9730fc553d6f695346c9375c0d8c1:0:100:aa00,"
        "ae241be7be83ebb14902757ad94854f787d9730fc553d6f695346c9375c0d8c2:0:200:aa00"
    ) == [
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
    ]


def test_ensure_utxo_is_first(defaults, monkeypatch):
    monkeypatch.setattr(
        "counterpartycore.lib.backend.bitcoind.get_utxo_value", lambda txid, vout: 999
    )
    # Test case 1: Reorder UTXOs to ensure specific UTXO is first
    assert composer.ensure_utxo_is_first(
        "ae241be7be83ebb14902757ad94854f787d9730fc553d6f695346c9375c0d8c1:0",
        [
            {"txid": "ae241be7be83ebb14902757ad94854f787d9730fc553d6f695346c9375c0d8c1", "vout": 1},
            {"txid": "ae241be7be83ebb14902757ad94854f787d9730fc553d6f695346c9375c0d8c1", "vout": 0},
        ],
    ) == [
        {"txid": "ae241be7be83ebb14902757ad94854f787d9730fc553d6f695346c9375c0d8c1", "vout": 0},
        {"txid": "ae241be7be83ebb14902757ad94854f787d9730fc553d6f695346c9375c0d8c1", "vout": 1},
    ]

    # Test case 2: Add missing UTXO and ensure it's first
    assert composer.ensure_utxo_is_first(
        "ae241be7be83ebb14902757ad94854f787d9730fc553d6f695346c9375c0d8c1:0",
        [
            {"txid": "ae241be7be83ebb14902757ad94854f787d9730fc553d6f695346c9375c0d8c1", "vout": 1},
        ],
    ) == [
        {
            "txid": "ae241be7be83ebb14902757ad94854f787d9730fc553d6f695346c9375c0d8c1",
            "vout": 0,
            "value": 99900000000,
            "amount": 999,
        },
        {"txid": "ae241be7be83ebb14902757ad94854f787d9730fc553d6f695346c9375c0d8c1", "vout": 1},
    ]


def test_filter_utxos_with_balances(ledger_db, defaults):
    utxo_with_balance = ledger_db.execute("""
        SELECT utxo FROM balances WHERE quantity > 0 AND utxo IS NOT NULL ORDER BY rowid DESC LIMIT 1
    """).fetchone()["utxo"]
    txid, vout = utxo_with_balance.split(":")

    # Test case 1: Default behavior (error without flags)
    with pytest.raises(
        exceptions.ComposeError,
        match=re.escape(
            f"invalid UTXOs: {utxo_with_balance} "
            "(use `use_utxos_with_balances=True` to include them or `exclude_utxos_with_balances=True` to exclude them silently)"
        ),
    ):
        composer.filter_utxos_with_balances(
            ledger_db, defaults["addresses"][0], [{"txid": txid, "vout": vout}], {}
        )

    # Test case 2: Exclude UTXOs with balances
    assert (
        composer.filter_utxos_with_balances(
            ledger_db,
            defaults["addresses"][0],
            [{"txid": txid, "vout": vout}],
            {"exclude_utxos_with_balances": True},
        )
        == []
    )

    # Test case 3: Filter multiple UTXOs
    assert composer.filter_utxos_with_balances(
        ledger_db,
        defaults["addresses"][0],
        [
            {"txid": txid, "vout": vout},
            {"txid": "ae241be7be83ebb14902757ad94854f787d9730fc553d6f695346c9375c0d8c1", "vout": 1},
        ],
        {"exclude_utxos_with_balances": True},
    ) == [{"txid": "ae241be7be83ebb14902757ad94854f787d9730fc553d6f695346c9375c0d8c1", "vout": 1}]

    # Test case 4: Use UTXOs with balances
    assert composer.filter_utxos_with_balances(
        ledger_db,
        defaults["addresses"][0],
        [{"txid": txid, "vout": vout}],
        {"use_utxos_with_balances": True},
    ) == [{"txid": txid, "vout": vout}]


def test_complete_unspent_list(defaults, monkeypatch):
    txs = {
        "ae241be7be83ebb14902757ad94854f787d9730fc553d6f695346c9375c0d8c1": {
            "vout": [
                {
                    "n": 0,
                    "value": 1.9990914,
                    "scriptPubKey": {
                        "hex": "76a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788ac",
                    },
                }
            ]
        }
    }
    monkeypatch.setattr(
        "counterpartycore.lib.backend.bitcoind.getrawtransaction_batch", lambda *args, **kwargs: txs
    )
    # Test case 1: Valid UTXO
    assert composer.complete_unspent_list(
        [
            {
                "txid": "ae241be7be83ebb14902757ad94854f787d9730fc553d6f695346c9375c0d8c1",
                "vout": 0,
            }
        ]
    ) == [
        {
            "txid": "ae241be7be83ebb14902757ad94854f787d9730fc553d6f695346c9375c0d8c1",
            "vout": 0,
            "value": 199909140,
            "amount": 1.9990914,
            "script_pub_key": "76a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788ac",
            "is_segwit": False,
        }
    ]

    # Test case 2: Invalid UTXO (transaction not found)
    with pytest.raises(
        exceptions.ComposeError,
        match=re.escape(
            "invalid UTXOs: ae241be7be83ebb14902757ad94854f787d9730fc553d6f695346c9375c0d8c2:0 (transaction not found)"
        ),
    ):
        composer.complete_unspent_list(
            [
                {
                    "txid": "ae241be7be83ebb14902757ad94854f787d9730fc553d6f695346c9375c0d8c2",
                    "vout": 0,
                }
            ]
        )


def test_utxo_to_address(ledger_db, defaults, monkeypatch):
    def mock_getrawtransaction(txid, verbose=True):
        if txid != "ae241be7be83ebb14902757ad94854f787d9730fc553d6f695346c9375c0d8c2":
            return {
                "vout": [
                    {
                        "scriptPubKey": {
                            "address": defaults["addresses"][0],
                        }
                    }
                ]
            }
        return None

    monkeypatch.setattr(
        "counterpartycore.lib.backend.bitcoind.getrawtransaction", mock_getrawtransaction
    )

    # Test case 1: Valid UTXO with specific address
    assert (
        composer.utxo_to_address(
            ledger_db, "1e9d0b5cc5b3f56cc59c0e8f3268d6ad10f79337aaf19081580c486caeb4cf53:0"
        )
        == defaults["addresses"][0]
    )

    # Test case 2: Valid UTXO with default address
    assert (
        composer.utxo_to_address(
            ledger_db, "ae241be7be83ebb14902757ad94854f787d9730fc553d6f695346c9375c0d8c1:0"
        )
        == defaults["addresses"][0]
    )

    # Test case 3: Invalid UTXO
    with pytest.raises(
        exceptions.ComposeError,
        match=re.escape(
            "invalid UTXOs: ae241be7be83ebb14902757ad94854f787d9730fc553d6f695346c9375c0d8c2:0 (not found in the database or Bitcoin Core)"
        ),
    ):
        composer.utxo_to_address(
            ledger_db, "ae241be7be83ebb14902757ad94854f787d9730fc553d6f695346c9375c0d8c2:0"
        )


def test_utxos_to_txins():
    # Test case 1: Convert UTXOs to TxInputs
    utxos = [
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
    ]
    expected = [
        TxInput(UTXO_1.split(":")[0], int(UTXO_1.split(":")[1])),
        TxInput(UTXO_2.split(":")[0], int(UTXO_2.split(":")[1])),
        TxInput(UTXO_3.split(":")[0], int(UTXO_3.split(":")[1])),
    ]
    assert str(composer.utxos_to_txins(utxos)) == str(expected)


def test_get_dummy_script_sig():
    # Test P2PK
    assert str(
        composer.get_dummy_script_sig(
            "41049464205950188c29d377eebca6535e0f3699ce4069ecd77ffebfbd0bcf95e3c134cb7d2742d800a12df41413a09ef87a80516353a2f0a280547bb5512dc03da8ac"
        )
    ) == str(
        Script.from_raw(
            "48304500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001"
        )
    )

    # Test P2PKH
    assert str(
        composer.get_dummy_script_sig("76a91455ae51684c43435da751ac8d2173b2652eb6410588ac")
    ) == str(
        Script.from_raw(
            "4830450000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000121030000000000000000000000000000000000000000000000000000000000000000"
        )
    )

    # Test P2MS
    p2ms_script = "524104d81fd577272bbe73308c93009eec5dc9fc319fc1ee2e7066e17220a5d47a18314578be2faea34b9f1f8ca078f8621acd4bc22897b03daa422b9bf56646b342a24104ec3afff0b2b66e8152e9018fe3be3fc92b30bf886b3487a525997d00fd9da2d012dce5d5275854adc3106572a5d1e12d4211b228429f5a7b2f7ba92eb0475bb14104b49b496684b02855bc32f5daefa2e2e406db4418f3b86bca5195600951c7d918cdbe5e6d3736ec2abf2dd7610995c3086976b2c0c7b4e459d10b34a316d5a5e753ae"
    assert str(composer.get_dummy_script_sig(p2ms_script)) == str(
        Script.from_raw(
            "00304500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001304500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001"
        )
    )

    # Test P2SH
    assert str(
        composer.get_dummy_script_sig("a914748284390f9e263a4b766a75d0633c50426eb87587")
    ) == str(
        Script.from_raw(
            "00483045000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000014948304500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001"
        )
    )

    # Test P2WPKH
    assert composer.get_dummy_script_sig("0014841b80d2cc75f5345c482af96294d04fdd66b2b7") is None

    # Test P2WSH
    assert (
        composer.get_dummy_script_sig(
            "002065f91a53cb7120057db3d378bd0f7d944167d43a7dcbff15d6afc4823f1d3ed3"
        )
        is None
    )

    # Test P2TR
    assert (
        composer.get_dummy_script_sig(
            "51200f0c8db753acbd17343a39c2f3f4e35e4be6da749f9e35137ab220e7b238a667"
        )
        is None
    )


def test_get_dummy_witness():
    # Test P2WPKH
    assert str(composer.get_dummy_witness("0014841b80d2cc75f5345c482af96294d04fdd66b2b7")) == str(
        TxWitnessInput(
            [
                "304500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001",
                "030000000000000000000000000000000000000000000000000000000000000000",
            ]
        )
    )

    # Test P2WSH
    assert str(
        composer.get_dummy_witness(
            "002065f91a53cb7120057db3d378bd0f7d944167d43a7dcbff15d6afc4823f1d3ed3"
        )
    ) == str(
        TxWitnessInput(
            [
                "4830450000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000121030000000000000000000000000000000000000000000000000000000000000000",
                "002065f91a53cb7120057db3d378bd0f7d944167d43a7dcbff15d6afc4823f1d3ed3",
            ]
        )
    )

    # Test P2TR
    assert str(
        composer.get_dummy_witness(
            "51200f0c8db753acbd17343a39c2f3f4e35e4be6da749f9e35137ab220e7b238a667"
        )
    ) == str(
        TxWitnessInput(
            [
                "0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000"
            ]
        )
    )

    # Test non-witness scripts return None
    assert (
        composer.get_dummy_witness(
            "41049464205950188c29d377eebca6535e0f3699ce4069ecd77ffebfbd0bcf95e3c134cb7d2742d800a12df41413a09ef87a80516353a2f0a280547bb5512dc03da8ac"
        )
        is None
    )
    assert composer.get_dummy_witness("76a91455ae51684c43435da751ac8d2173b2652eb6410588ac") is None
    assert (
        composer.get_dummy_witness(
            "524104d81fd577272bbe73308c93009eec5dc9fc319fc1ee2e7066e17220a5d47a18314578be2faea34b9f1f8ca078f8621acd4bc22897b03daa422b9bf56646b342a24104ec3afff0b2b66e8152e9018fe3be3fc92b30bf886b3487a525997d00fd9da2d012dce5d5275854adc3106572a5d1e12d4211b228429f5a7b2f7ba92eb0475bb14104b49b496684b02855bc32f5daefa2e2e406db4418f3b86bca5195600951c7d918cdbe5e6d3736ec2abf2dd7610995c3086976b2c0c7b4e459d10b34a316d5a5e753ae"
        )
        is None
    )
    assert composer.get_dummy_witness("a914748284390f9e263a4b766a75d0633c50426eb87587") is None


def test_prepare_fee_parameters():
    # Test exact fee
    assert composer.prepare_fee_parameters({"exact_fee": 1000}) == (1000, None, None)

    # Test exact fee with max_fee
    assert composer.prepare_fee_parameters({"exact_fee": 666, "max_fee": 1000}) == (666, None, None)

    # Test max_fee only
    assert composer.prepare_fee_parameters({"max_fee": 1000}) == (None, 2, 1000)

    # Test max_fee with sat_per_vbyte
    assert composer.prepare_fee_parameters({"max_fee": 1000, "sat_per_vbyte": 8}) == (None, 8, 1000)

    # Test max_fee with confirmation_target
    assert composer.prepare_fee_parameters({"max_fee": 1000, "confirmation_target": 8}) == (
        None,
        2,
        1000,
    )


def test_prepare_unspent_list(ledger_db, defaults, monkeypatch):
    txs = {
        "ae241be7be83ebb14902757ad94854f787d9730fc553d6f695346c9375c0d8c1": {
            "vout": [
                {
                    "n": 0,
                    "value": 1.9990914,
                    "scriptPubKey": {
                        "hex": "76a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788ac",
                    },
                }
            ]
        }
    }
    monkeypatch.setattr(
        "counterpartycore.lib.backend.bitcoind.getrawtransaction_batch", lambda *args, **kwargs: txs
    )

    # Test case 1: Basic case
    assert composer.prepare_unspent_list(ledger_db, defaults["addresses"][0], {}) == [
        {
            "txid": "5dd47b76f2f4c4d5453b71eb5f57457eb4f4ca0bd8e70d7b3ab17dfb2d23062b",
            "vout": 0,
            "value": 1000000000,
            "amount": 10,
            "script_pub_key": "76a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788ac",
            "is_segwit": False,
        }
    ]

    # Test case 2: With inputs_set parameter
    assert composer.prepare_unspent_list(
        ledger_db,
        defaults["addresses"][0],
        {"inputs_set": "ae241be7be83ebb14902757ad94854f787d9730fc553d6f695346c9375c0d8c1:0"},
    ) == [
        {
            "txid": "ae241be7be83ebb14902757ad94854f787d9730fc553d6f695346c9375c0d8c1",
            "vout": 0,
            "value": 199909140,
            "amount": 1.9990914,
            "script_pub_key": "76a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788ac",
            "is_segwit": False,
        }
    ]

    # Test case 3: With exclude_utxos parameter
    with pytest.raises(
        exceptions.ComposeError,
        match=re.escape(
            f"No UTXOs found for {defaults['addresses'][0]}, provide UTXOs with the `inputs_set` parameter"
        ),
    ):
        composer.prepare_unspent_list(
            ledger_db,
            defaults["addresses"][0],
            {"exclude_utxos": "af0c7a06e5e610f00b082de51c5cccd641fd925f113c142120da2b2b10897b8c:0"},
        )

    # Test case 4: With unspent_tx_hash parameter
    with pytest.raises(
        exceptions.ComposeError,
        match=re.escape(
            f"No UTXOs found for {defaults['addresses'][0]}, provide UTXOs with the `inputs_set` parameter"
        ),
    ):
        composer.prepare_unspent_list(
            ledger_db,
            defaults["addresses"][0],
            {"unspent_tx_hash": "ae241be7be83ebb14902757ad94854f787d9730fc553d6f695346c9375c0d8c2"},
        )


def test_prepare_inputs_and_change(ledger_db, defaults):
    # Test case 1: using exact_fee
    assert str(
        composer.prepare_inputs_and_change(
            ledger_db,
            defaults["addresses"][0],
            [TxOutput(666, P2pkhAddress(defaults["addresses"][0]).to_script_pub_key())],
            [
                {
                    "txid": "ae241be7be83ebb14902757ad94854f787d9730fc553d6f695346c9375c0d8c1",
                    "vout": 0,
                    "value": 199909140,
                    "amount": 1.9990914,
                    "script_pub_key": "76a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788ac",
                    "is_segwit": False,
                }
            ],
            {"exact_fee": 1000},
        )
    ) == str(
        (
            [
                {
                    "txid": "ae241be7be83ebb14902757ad94854f787d9730fc553d6f695346c9375c0d8c1",
                    "vout": 0,
                    "value": 199909140,
                    "amount": 1.9990914,
                    "script_pub_key": "76a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788ac",
                    "is_segwit": False,
                }
            ],
            199909140,
            [
                TxOutput(
                    199909140 - 666 - 1000,
                    P2pkhAddress(defaults["addresses"][0]).to_script_pub_key(),
                )
            ],
        )
    )

    # Test case 2: using exact_fee and change_address
    assert str(
        composer.prepare_inputs_and_change(
            ledger_db,
            defaults["addresses"][0],
            [TxOutput(666, P2pkhAddress(defaults["addresses"][0]).to_script_pub_key())],
            [
                {
                    "txid": "ae241be7be83ebb14902757ad94854f787d9730fc553d6f695346c9375c0d8c1",
                    "vout": 0,
                    "value": 199909140,
                    "amount": 1.9990914,
                    "script_pub_key": "76a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788ac",
                    "is_segwit": False,
                }
            ],
            {"exact_fee": 1000, "change_address": defaults["addresses"][1]},
        )
    ) == str(
        (
            [
                {
                    "txid": "ae241be7be83ebb14902757ad94854f787d9730fc553d6f695346c9375c0d8c1",
                    "vout": 0,
                    "value": 199909140,
                    "amount": 1.9990914,
                    "script_pub_key": "76a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788ac",
                    "is_segwit": False,
                }
            ],
            199909140,
            [
                TxOutput(
                    199909140 - 666 - 1000,
                    P2pkhAddress(defaults["addresses"][1]).to_script_pub_key(),
                )
            ],
        )
    )

    # Test case 3: using exact_fee, change_address and use_all_inputs_set
    assert str(
        composer.prepare_inputs_and_change(
            ledger_db,
            defaults["addresses"][0],
            [TxOutput(666, P2pkhAddress(defaults["addresses"][0]).to_script_pub_key())],
            [
                {
                    "txid": "ae241be7be83ebb14902757ad94854f787d9730fc553d6f695346c9375c0d8c1",
                    "vout": 0,
                    "value": 199909140,
                    "amount": 1.9990914,
                    "script_pub_key": "76a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788ac",
                    "is_segwit": False,
                },
                {
                    "txid": "ae241be7be83ebb14902757ad94854f787d9730fc553d6f695346c9375c0d8c1",
                    "vout": 1,
                    "value": 199909140,
                    "amount": 1.9990914,
                    "script_pub_key": "76a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788ac",
                    "is_segwit": False,
                },
            ],
            {
                "exact_fee": 1000,
                "change_address": defaults["addresses"][1],
                "use_all_inputs_set": True,
            },
        )
    ) == str(
        (
            [
                {
                    "txid": "ae241be7be83ebb14902757ad94854f787d9730fc553d6f695346c9375c0d8c1",
                    "vout": 0,
                    "value": 199909140,
                    "amount": 1.9990914,
                    "script_pub_key": "76a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788ac",
                    "is_segwit": False,
                },
                {
                    "txid": "ae241be7be83ebb14902757ad94854f787d9730fc553d6f695346c9375c0d8c1",
                    "vout": 1,
                    "value": 199909140,
                    "amount": 1.9990914,
                    "script_pub_key": "76a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788ac",
                    "is_segwit": False,
                },
            ],
            199909140 * 2,
            [
                TxOutput(
                    199909140 * 2 - 666 - 1000,
                    P2pkhAddress(defaults["addresses"][1]).to_script_pub_key(),
                )
            ],
        )
    )

    # Test case 4: using default construct_params
    assert str(
        composer.prepare_inputs_and_change(
            ledger_db,
            defaults["addresses"][0],
            [TxOutput(666, P2pkhAddress(defaults["addresses"][0]).to_script_pub_key())],
            [
                {
                    "txid": "ae241be7be83ebb14902757ad94854f787d9730fc553d6f695346c9375c0d8c1",
                    "vout": 0,
                    "value": 199909140,
                    "amount": 1.9990914,
                    "script_pub_key": "76a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788ac",
                    "is_segwit": False,
                }
            ],
            {},
        )
    ) == str(
        (
            [
                {
                    "txid": "ae241be7be83ebb14902757ad94854f787d9730fc553d6f695346c9375c0d8c1",
                    "vout": 0,
                    "value": 199909140,
                    "amount": 1.9990914,
                    "script_pub_key": "76a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788ac",
                    "is_segwit": False,
                }
            ],
            199909140,
            [
                TxOutput(
                    199909140 - 666 - 452,
                    P2pkhAddress(defaults["addresses"][0]).to_script_pub_key(),
                )
            ],
        )
    )

    # Test case 5: using max_fee
    assert str(
        composer.prepare_inputs_and_change(
            ledger_db,
            defaults["addresses"][0],
            [TxOutput(666, P2pkhAddress(defaults["addresses"][0]).to_script_pub_key())],
            [
                {
                    "txid": "ae241be7be83ebb14902757ad94854f787d9730fc553d6f695346c9375c0d8c1",
                    "vout": 0,
                    "value": 199909140,
                    "amount": 1.9990914,
                    "script_pub_key": "76a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788ac",
                    "is_segwit": False,
                }
            ],
            {"max_fee": 200},
        )
    ) == str(
        (
            [
                {
                    "txid": "ae241be7be83ebb14902757ad94854f787d9730fc553d6f695346c9375c0d8c1",
                    "vout": 0,
                    "value": 199909140,
                    "amount": 1.9990914,
                    "script_pub_key": "76a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788ac",
                    "is_segwit": False,
                }
            ],
            199909140,
            [
                TxOutput(
                    199909140 - 666 - 200,
                    P2pkhAddress(defaults["addresses"][0]).to_script_pub_key(),
                )
            ],
        )
    )

    # Test case 6: using high fee so no change
    assert str(
        composer.prepare_inputs_and_change(
            ledger_db,
            defaults["addresses"][0],
            [TxOutput(666, P2pkhAddress(defaults["addresses"][0]).to_script_pub_key())],
            [
                {
                    "txid": "ae241be7be83ebb14902757ad94854f787d9730fc553d6f695346c9375c0d8c1",
                    "vout": 0,
                    "value": 199909140,
                    "amount": 1.9990914,
                    "script_pub_key": "76a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788ac",
                    "is_segwit": False,
                }
            ],
            {"exact_fee": 199909140 - 666 - 10},
        )
    ) == str(
        (
            [
                {
                    "txid": "ae241be7be83ebb14902757ad94854f787d9730fc553d6f695346c9375c0d8c1",
                    "vout": 0,
                    "value": 199909140,
                    "amount": 1.9990914,
                    "script_pub_key": "76a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788ac",
                    "is_segwit": False,
                }
            ],
            199909140,
            [],
        )
    )

    # Test case 7: not enough funds
    with pytest.raises(
        exceptions.ComposeError,
        match=re.escape(
            f"Insufficient funds for the target amount: 199909140 < {199909140 + 1000}"
        ),
    ):
        composer.prepare_inputs_and_change(
            ledger_db,
            defaults["addresses"][0],
            [TxOutput(199909140, P2pkhAddress(defaults["addresses"][0]).to_script_pub_key())],
            [
                {
                    "txid": "ae241be7be83ebb14902757ad94854f787d9730fc553d6f695346c9375c0d8c1",
                    "vout": 0,
                    "value": 199909140,
                    "amount": 1.9990914,
                    "script_pub_key": "76a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788ac",
                    "is_segwit": False,
                }
            ],
            {"exact_fee": 1000},
        )


def test_construct(ledger_db, defaults):
    # Test case 1: Basic construction
    result = composer.construct(
        ledger_db,
        (defaults["addresses"][0], [(defaults["addresses"][1], 666)], b"Hello, World!"),
        {},
    )
    assert result == {
        "btc_change": 999998818,
        "btc_fee": 516,
        "btc_in": 1000000000,
        "btc_out": 666,
        "data": b"CNTRPRTYHello, World!",
        "lock_scripts": ["76a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788ac"],
        "rawtransaction": "02000000019bce2dde4009a982fc2b56013f9ff51a8ca2ff955a61414e746d78984aade08f0000000000ffffffff039a020000000000001976a9148d6ae8a3b381663118b4e1eff4cfc7d0954dd6ec88ac0000000000000000176a1506be63513fbe7892e68f2c4bd5eb064ea674b0545d62c59a3b000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788ac00000000",
        "signed_tx_estimated_size": {
            "adjusted_vsize": 258,
            "sigops_count": 8,
            "vsize": 258,
        },
        "inputs_values": [1000000000],
    }

    # Test case 2: Construction with exact fee
    result = composer.construct(
        ledger_db,
        (defaults["addresses"][0], [(defaults["addresses"][1], 666)], b"Hello, World!"),
        {"exact_fee": 1000},
    )
    assert result == {
        "btc_change": 1000000000 - 666 - 1000,
        "btc_fee": 1000,
        "btc_in": 1000000000,
        "btc_out": 666,
        "data": b"CNTRPRTYHello, World!",
        "lock_scripts": ["76a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788ac"],
        "rawtransaction": "0200000001fdb01ccb92813426315c01b1bddc0f8a6ac5a745afdabfae4ed05988f5b628be0000000000ffffffff039a020000000000001976a9148d6ae8a3b381663118b4e1eff4cfc7d0954dd6ec88ac0000000000000000176a15239838415c13a8c64dfecc8d17396a555318d194b77ec39a3b000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788ac00000000",
        "signed_tx_estimated_size": {
            "adjusted_vsize": 258,
            "sigops_count": 8,
            "vsize": 258,
        },
        "inputs_values": [1000000000],
    }


def test_check_transaction_sanity(defaults):
    # Test case 1: Valid transaction
    composer.check_transaction_sanity(
        (defaults["addresses"][0], [(defaults["addresses"][1], 666)], b"Hello, World!"),
        {
            "btc_change": 1000000000 - 666 - 1000,
            "btc_fee": 1000,
            "btc_in": 1000000000,
            "btc_out": 666,
            "data": b"CNTRPRTYHello, World!",
            "lock_scripts": ["76a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788ac"],
            "rawtransaction": "020000000162cfa1417799553e305c053c5c92a8bdcccfcf5ee01d2aeabf0450e06fcabd070000000000ffffffff039a020000000000001976a9148d6ae8a3b381663118b4e1eff4cfc7d0954dd6ec88ac0000000000000000176a15d59bb23339e70a3709c14a8db5ae9927cb1140b78f7ec39a3b000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788ac00000000",
            "inputs_values": [1000000000],
        },
        {"exact_fee": 1000},
    )

    # Test case 2: Invalid source address
    with pytest.raises(
        exceptions.ComposeError,
        match="Sanity check error: source address does not match the first input address",
    ):
        composer.check_transaction_sanity(
            (defaults["addresses"][1], [(defaults["addresses"][1], 666)], b"Hello, World!"),
            {
                "btc_change": 1000000000 - 666 - 1000,
                "btc_fee": 1000,
                "btc_in": 1000000000,
                "btc_out": 666,
                "data": b"CNTRPRTYHello, World!",
                "lock_scripts": ["76a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788ac"],
                "rawtransaction": "020000000162cfa1417799553e305c053c5c92a8bdcccfcf5ee01d2aeabf0450e06fcabd070000000000ffffffff039a020000000000001976a9148d6ae8a3b381663118b4e1eff4cfc7d0954dd6ec88ac0000000000000000176a15d59bb23339e70a3709c14a8db5ae9927cb1140b78f7ec39a3b000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788ac00000000",
                "inputs_values": [1000000000],
            },
            {"exact_fee": 1000},
        )

    # Test case 3: Invalid destination address
    with pytest.raises(
        exceptions.ComposeError,
        match="Sanity check error: destination address does not match the output address",
    ):
        composer.check_transaction_sanity(
            (defaults["addresses"][0], [(defaults["addresses"][0], 666)], b"Hello, World!"),
            {
                "btc_change": 1000000000 - 666 - 1000,
                "btc_fee": 1000,
                "btc_in": 1000000000,
                "btc_out": 666,
                "data": b"CNTRPRTYHello, World!",
                "lock_scripts": ["76a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788ac"],
                "rawtransaction": "020000000162cfa1417799553e305c053c5c92a8bdcccfcf5ee01d2aeabf0450e06fcabd070000000000ffffffff039a020000000000001976a9148d6ae8a3b381663118b4e1eff4cfc7d0954dd6ec88ac0000000000000000176a15d59bb23339e70a3709c14a8db5ae9927cb1140b78f7ec39a3b000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788ac00000000",
                "inputs_values": [1000000000],
            },
            {"exact_fee": 1000},
        )

    # Test case 4: Invalid destination value
    with pytest.raises(
        exceptions.ComposeError,
        match="Sanity check error: destination value does not match the output value",
    ):
        composer.check_transaction_sanity(
            (defaults["addresses"][0], [(defaults["addresses"][1], 665)], b"Hello, World!"),
            {
                "btc_change": 1000000000 - 666 - 1000,
                "btc_fee": 1000,
                "btc_in": 1000000000,
                "btc_out": 666,
                "data": b"CNTRPRTYHello, World!",
                "lock_scripts": ["76a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788ac"],
                "rawtransaction": "020000000162cfa1417799553e305c053c5c92a8bdcccfcf5ee01d2aeabf0450e06fcabd070000000000ffffffff039a020000000000001976a9148d6ae8a3b381663118b4e1eff4cfc7d0954dd6ec88ac0000000000000000176a15d59bb23339e70a3709c14a8db5ae9927cb1140b78f7ec39a3b000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788ac00000000",
                "inputs_values": [1000000000],
            },
            {"exact_fee": 1000},
        )

    # Test case 5: Invalid data
    with pytest.raises(
        exceptions.ComposeError, match="Sanity check error: data does not match the output data"
    ):
        composer.check_transaction_sanity(
            (defaults["addresses"][0], [(defaults["addresses"][1], 666)], b"Hello, World!!!"),
            {
                "btc_change": 1000000000 - 666 - 1000,
                "btc_fee": 1000,
                "btc_in": 1000000000,
                "btc_out": 666,
                "data": b"CNTRPRTYHello, World!",
                "lock_scripts": ["76a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788ac"],
                "rawtransaction": "020000000162cfa1417799553e305c053c5c92a8bdcccfcf5ee01d2aeabf0450e06fcabd070000000000ffffffff039a020000000000001976a9148d6ae8a3b381663118b4e1eff4cfc7d0954dd6ec88ac0000000000000000176a15d59bb23339e70a3709c14a8db5ae9927cb1140b78f7ec39a3b000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788ac00000000",
                "inputs_values": [1000000000],
            },
            {"exact_fee": 1000},
        )


def test_prepare_construct_params(defaults):
    # Test case 1: Basic parameter conversion
    params = {
        "fee_per_kb": 1024,
        "fee_provided": 666,
        "dust_return_pubkey": defaults["pubkey"][defaults["addresses"][0]],
        "return_psbt": True,
        "regular_dust_size": 357,
        "multisig_dust_size": 1200,
        "extended_tx_info": True,
        "old_style_api": True,
        "p2sh_pretx_txid": "aabbb",
        "segwit": True,
        "unspent_tx_hash": "aabbcc",
    }

    expected_params = {
        "sat_per_vbyte": 1,
        "max_fee": 666,
        "mutlisig_pubkey": defaults["pubkey"][defaults["addresses"][0]],
        "verbose": True,
        "regular_dust_size": 357,
        "multisig_dust_size": 1200,
        "extended_tx_info": True,
        "old_style_api": True,
        "p2sh_pretx_txid": "aabbb",
        "segwit": True,
        "unspent_tx_hash": "aabbcc",
    }

    expected_warnings = [
        "The `fee_per_kb` parameter is deprecated, use `sat_per_vbyte` instead",
        "The `fee_provided` parameter is deprecated, use `max_fee` instead",
        "The `dust_return_pubkey` parameter is deprecated, use `mutlisig_pubkey` instead",
        "The `return_psbt` parameter is deprecated, use `verbose` instead",
        "The `regular_dust_size` parameter is deprecated, automatically calculated",
        "The `multisig_dust_size` parameter is deprecated, automatically calculated",
        "The `extended_tx_info` parameter is deprecated (api v1 only), use api v2 instead",
        "The `old_style_api` parameter is deprecated (api v1 only), use api v2 instead",
        "The `p2sh_pretx_txid` parameter is ignored, p2sh disabled",
        "The `segwit` parameter is ignored, segwit automatically detected",
        "The `unspent_tx_hash` parameter is deprecated, use `inputs_set` instead",
    ]

    result_params, result_warnings = composer.prepare_construct_params(params)
    assert result_params == expected_params
    assert result_warnings == expected_warnings

    # Test case 2: Fee per kb conversion
    params = {
        "fee_per_kb": 1023,
        "fee_provided": 666,
        "dust_return_pubkey": defaults["pubkey"][defaults["addresses"][0]],
        "return_psbt": True,
        "regular_dust_size": 357,
        "multisig_dust_size": 1200,
        "extended_tx_info": True,
        "old_style_api": True,
        "p2sh_pretx_txid": "aabbb",
        "segwit": True,
        "unspent_tx_hash": "aabbcc",
    }

    expected_params = {
        "sat_per_vbyte": 1023 / 1024,
        "max_fee": 666,
        "mutlisig_pubkey": defaults["pubkey"][defaults["addresses"][0]],
        "verbose": True,
        "regular_dust_size": 357,
        "multisig_dust_size": 1200,
        "extended_tx_info": True,
        "old_style_api": True,
        "p2sh_pretx_txid": "aabbb",
        "segwit": True,
        "unspent_tx_hash": "aabbcc",
    }

    result_params, result_warnings = composer.prepare_construct_params(params)
    assert result_params == expected_params
    assert result_warnings == expected_warnings


def test_compose_transaction(ledger_db, defaults, monkeypatch):
    # Test case 1: Order transaction
    params = {
        "source": defaults["addresses"][0],
        "give_asset": "BTC",
        "give_quantity": defaults["small"],
        "get_asset": "XCP",
        "get_quantity": defaults["small"] * 2,
        "expiration": defaults["expiration"],
        "fee_required": 0,
    }

    construct_params = {"encoding": "multisig", "fee_provided": defaults["fee_provided"]}

    expected = {
        "rawtransaction": "02000000012bcf50aeef3c40f99a12b4d8fbbb44c5fc5b8be41ca7285961c8dcd51d0662050000000000ffffffff02e8030000000000006951210231590b2a3519b6e6d491c3d386fb6df1d8ec0d29f374c92ca76427fb3c0ca90e21038868d0e45b46abe2661b5bd940daa02115b551d7edcde32becdc89393ffd03b0210282b886c087eb37dc8182f14ba6cc3e9485ed618b95804d44aecc17c300b585b053aed0c29a3b000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788ac00000000",
        "warnings": ["The `fee_provided` parameter is deprecated, use `max_fee` instead"],
    }

    result = composer.compose_transaction(ledger_db, "order", params, construct_params)
    assert result == expected

    params = {
        "memo": "0102030405",
        "memo_is_hex": True,
        "source": defaults["addresses"][0],
        "destination": defaults["addresses"][1],
        "asset": "XCP",
        "quantity": defaults["small"],
    }

    expected = {
        "rawtransaction": "02000000015b798032404ccc61fe2f11cb6d9c840263cd4793a244bfbdb2013fbf8d3addde0000000000ffffffff020000000000000000356a33fe7270fdddb64c2b53d02d679eddf371b4bb315338af8739d36f6711db76fb4e88a26b439970cc8287433f54625855e015d09c04c89a3b000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788ac00000000"
    }

    result = composer.compose_transaction(ledger_db, "send", params, {})
    assert result == expected

    params = {
        "source": defaults["addresses"][0],
        "asset": "XCP",
        "quantity": 10,
    }

    expected = {
        "rawtransaction": "02000000015bb36cf251b75a6d085839ad91c858fd65cf3537603053649fb3ee3370a4a7910000000000ffffffff0310270000000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788ac0000000000000000126a103cc66cc99089349dd3c3b0f1c09e82ecf6a09a3b000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788ac00000000",
        "btc_in": 1000000000,
        "btc_out": 10000,
        "btc_change": 999989494,
        "btc_fee": 506,
        "data": b"CNTRPRTYeXCP|10|",
        "lock_scripts": ["76a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788ac"],
        "inputs_values": [1000000000],
        "signed_tx_estimated_size": {
            "vsize": 253,
            "adjusted_vsize": 253,
            "sigops_count": 8,
        },
        "psbt": "02000000015bb36cf251b75a6d085839ad91c858fd65cf3537603053649fb3ee3370a4a7910000000000ffffffff0310270000000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788ac0000000000000000126a103cc66cc99089349dd3c3b0f1c09e82ecf6a09a3b000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788ac00000000",
        "params": {
            "source": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc",
            "asset": "XCP",
            "quantity": 10,
            "utxo_value": None,
            "destination_vout": None,
            "skip_validation": False,
        },
        "name": "attach",
    }

    result = composer.compose_transaction(ledger_db, "attach", params, {"verbose": True})
    assert result == expected


def test_compose_send(ledger_db, defaults):
    # Test basic send
    params = {
        "source": defaults["addresses"][0],
        "destination": defaults["addresses"][1],
        "asset": "XCP",
        "quantity": 10,
    }

    expected = {
        "rawtransaction": "02000000010ca08a26c41f6a9b497240bc5711739bb36db8229587a48b4fddf2c99b1ebfe90000000000ffffffff020000000000000000306a2eeb96319326aa064443d65ad19271864fbd4370bee64234c8b5ff7477aaaccfd02fff53f7af5db276d900ba3479c10ec89a3b000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788ac00000000"
    }

    result = composer.compose_transaction(ledger_db, "send", params, {})
    assert result == expected


def test_compose_burn(ledger_db, defaults):
    params = {
        "source": defaults["addresses"][1],
        "quantity": defaults["burn_quantity"],
    }

    construct_params = {"encoding": "multisig", "disable_utxo_locks": True}

    expected = {
        "rawtransaction": "020000000164caf0bf9b5dac8f475262b387846ea4aa5882b0bea0c52b84f76671dde023bc0000000000ffffffff02800bb203000000001976a914a11b66a67b3ff69671c8f82254099faf374b800e88acbcbce837000000001976a9148d6ae8a3b381663118b4e1eff4cfc7d0954dd6ec88ac00000000"
    }

    result = composer.compose_transaction(ledger_db, "burn", params, construct_params)
    assert result == expected


def test_compose_issuance(ledger_db, defaults):
    params = {
        "source": defaults["addresses"][0],
        "transfer_destination": None,
        "asset": "BSSET",
        "quantity": 1000,
        "divisible": True,
        "description": "",
    }

    construct_params = {"encoding": "multisig"}

    expected = {
        "rawtransaction": "02000000013017424ffd15ffcd2903dffb9b314ab2e4b38ccc40d43a70a687337c19628f940000000000ffffffff02e803000000000000695121021c5923d86d0a0f96778ff7bfa06980bcccdfd820eb7e07ed006ff97165f3842d2103257bb6b8c1206e06c36796ef3467d8b4a84af369c83784474dcbe8f01ef9b844210282b886c087eb37dc8182f14ba6cc3e9485ed618b95804d44aecc17c300b585b053aed0c29a3b000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788ac00000000"
    }

    result = composer.compose_transaction(ledger_db, "issuance", params, construct_params)
    assert result == expected


def test_compose_enhanced_send(ledger_db, defaults, monkeypatch):
    params = {
        "memo": "0102030405",
        "memo_is_hex": True,
        "source": defaults["addresses"][0],
        "destination": defaults["addresses"][1],
        "asset": "XCP",
        "quantity": defaults["small"],
    }

    expected = {
        "rawtransaction": "0200000001c50cd6f19c1ef5fca06e3df19639102c2c003d4473e4ad03e74ad32b6395688d0000000000ffffffff020000000000000000356a33f491bf12f92e5bdd71a8470868018cdea73404c3506158d16e76d5e8ab7d7fcf514ea09ec71de638e0cdaf544897caaef4aec204c89a3b000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788ac00000000"
    }

    result = composer.compose_transaction(ledger_db, "send", params, {})
    assert result == expected


def test_compose_move(ledger_db, defaults):
    utxo_with_balance = ledger_db.execute("""
        SELECT utxo FROM balances WHERE quantity > 0 AND utxo IS NOT NULL ORDER BY rowid DESC LIMIT 1
    """).fetchone()["utxo"]
    # Test basic move
    params = {
        "source": utxo_with_balance,
        "destination": defaults["addresses"][1],
    }

    construct_params = {
        "verbose": True,
        "inputs_set": f"{utxo_with_balance}:999999999:76a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788ac",
        "disable_utxo_locks": True,
    }

    expected = {
        "rawtransaction": "0200000001337752c7b25ac513939f56bbdd5b2d227e5cc89df56aba5e8a817fb98030d81c0000000000ffffffff0210270000000000001976a9148d6ae8a3b381663118b4e1eff4cfc7d0954dd6ec88ac2ba19a3b000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788ac00000000",
        "btc_in": 999999999,
        "btc_out": 10000,
        "btc_change": 999989547,
        "btc_fee": 452,
        "data": None,
        "lock_scripts": ["76a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788ac"],
        "inputs_values": [999999999],
        "signed_tx_estimated_size": {
            "vsize": 226,
            "adjusted_vsize": 226,
            "sigops_count": 8,
        },
        "psbt": "0200000001337752c7b25ac513939f56bbdd5b2d227e5cc89df56aba5e8a817fb98030d81c0000000000ffffffff0210270000000000001976a9148d6ae8a3b381663118b4e1eff4cfc7d0954dd6ec88ac2ba19a3b000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788ac00000000",
        "params": {
            "source": utxo_with_balance,
            "destination": "mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns",
            "utxo_value": None,
            "skip_validation": False,
        },
        "name": "move",
    }

    result = composer.compose_transaction(ledger_db, "move", params, construct_params)
    assert result == expected

    # Test move with utxo_value
    params = {
        "source": utxo_with_balance,
        "destination": defaults["addresses"][1],
        "utxo_value": 666,
    }

    expected = {
        "rawtransaction": "0200000001337752c7b25ac513939f56bbdd5b2d227e5cc89df56aba5e8a817fb98030d81c0000000000ffffffff029a020000000000001976a9148d6ae8a3b381663118b4e1eff4cfc7d0954dd6ec88aca1c59a3b000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788ac00000000",
        "btc_in": 999999999,
        "btc_out": 666,
        "btc_change": 999998881,
        "btc_fee": 452,
        "data": None,
        "lock_scripts": ["76a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788ac"],
        "inputs_values": [999999999],
        "signed_tx_estimated_size": {
            "vsize": 226,
            "adjusted_vsize": 226,
            "sigops_count": 8,
        },
        "psbt": "0200000001337752c7b25ac513939f56bbdd5b2d227e5cc89df56aba5e8a817fb98030d81c0000000000ffffffff029a020000000000001976a9148d6ae8a3b381663118b4e1eff4cfc7d0954dd6ec88aca1c59a3b000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788ac00000000",
        "params": {
            "source": utxo_with_balance,
            "destination": "mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns",
            "utxo_value": 666,
            "skip_validation": False,
        },
        "name": "move",
    }

    result = composer.compose_transaction(ledger_db, "move", params, construct_params)
    assert result == expected
