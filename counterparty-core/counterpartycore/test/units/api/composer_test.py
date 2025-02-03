import binascii
import re
from io import BytesIO

import bitcoin
import pytest
from bitcoinutils.keys import P2pkhAddress, P2wpkhAddress
from bitcoinutils.script import Script
from bitcoinutils.transactions import Transaction, TxInput, TxOutput, TxWitnessInput
from counterpartycore.lib import config, exceptions
from counterpartycore.lib.api import composer
from counterpartycore.test.fixtures.defaults import DEFAULT_PARAMS as DEFAULTS

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

    assert composer.address_to_script_pub_key(defaults["p2tr_addresses"][0], [], {}) == Script(
        ["OP_1", "8790903eefbbb8ac03e5e884f76127186e3d18d9c93331f10dd112ad44264156"]
    )

    original_network = config.NETWORK_NAME
    config.NETWORK_NAME = "mainnet"

    assert composer.address_to_script_pub_key(
        "bc1prkn4gm5crk3m4c3489zlllnrsrxmznnymh3vncnae44g7llnc36ssj07ew", [], {}
    ) == Script(["OP_1", "1da7546e981da3bae2353945fffe6380cdb14e64dde2c9e27dcd6a8f7ff3c475"])

    config.NETWORK_NAME = original_network


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
        },
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

    with pytest.raises(
        exceptions.ComposeError,
        match=re.escape(
            "invalid UTXOs: ae241be7be83ebb14902757ad94854f787d9730fc553d6f695346c9375c0d8c1:1: script_pub_key not found, you can provide it with the `inputs_set` parameter, using <txid>:<vout>:<value>:<script_pub_key> format"
        ),
    ):
        composer.complete_unspent_list(
            [
                {
                    "txid": "ae241be7be83ebb14902757ad94854f787d9730fc553d6f695346c9375c0d8c1",
                    "vout": 1,
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
            "004830450000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000148304500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001"
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
            "txid": "b5a7c328c75b122325d2e6ed64774e9b37cefbfca6370872931597368ff7cecd",
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
        result = composer.prepare_unspent_list(
            ledger_db,
            defaults["addresses"][0],
            {"exclude_utxos": "676b03b94f43d4a23db55f2ac95e6aff6bfcbc4fdf855cbe3ee80d9a312e576a:0"},
        )
        print(result)

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
        "rawtransaction": "02000000019d432fbcb46dae959f9ec603ec55422d82d463e95aa55df185811e8807f7058a0000000000ffffffff039a020000000000001976a9148d6ae8a3b381663118b4e1eff4cfc7d0954dd6ec88ac0000000000000000176a15619710bb8c4782f68f685626d982a854ece3b856da62c59a3b000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788ac00000000",
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
        "rawtransaction": "0200000001f158602f2a74db98193b6296c9df109d2c8cf53871bdccbf479fb9f8742ba0fe0000000000ffffffff039a020000000000001976a9148d6ae8a3b381663118b4e1eff4cfc7d0954dd6ec88ac0000000000000000176a152e60f7159ea0ffcd4b7a67305f073938642f6c399f7ec39a3b000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788ac00000000",
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
        "rawtransaction": "0200000001df00f16eef00114fa2cbdcc5e985c493504582c613d299b571c37466d07771ee0000000000ffffffff02e80300000000000069512103fe3a8c437baa437ebc09890c84f90fbecd7846280bbb4e668a5c12cfb6f6a7f22103d2e817e8f08b35ac0ddd18e91101f2efc25fa096f839c6a86e5c558a299ae03f210282b886c087eb37dc8182f14ba6cc3e9485ed618b95804d44aecc17c300b585b053aed0c29a3b000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788ac00000000",
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
        "rawtransaction": "020000000105f0cbd18027cba6bde130352b2a5317416baa4c19290c715f9bc7548aadd4fa0000000000ffffffff020000000000000000356a337ab25078709fa6c35f0860d2f5b0313c770ba474e92ed2e16686eb546a0a9885f32040ee0005647ef04b01a33d8a7ca9fbf6cb04c89a3b000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788ac00000000"
    }

    result = composer.compose_transaction(ledger_db, "send", params, {})
    assert result == expected

    params = {
        "source": defaults["addresses"][0],
        "asset": "XCP",
        "quantity": 10,
    }

    expected = {
        "rawtransaction": "02000000015aeb41a258e2349d502cfe434d177eb40058484f608a416f22d01e16b40f0add0000000000ffffffff0322020000000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788ac0000000000000000126a100ec2affac401c38d464471bd3d38badde4c59a3b000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788ac00000000",
        "btc_in": 1000000000,
        "btc_out": 546,
        "btc_change": 999998948,
        "btc_fee": 506,
        "data": b"CNTRPRTYeXCP|10|",
        "lock_scripts": ["76a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788ac"],
        "inputs_values": [1000000000],
        "signed_tx_estimated_size": {
            "vsize": 253,
            "adjusted_vsize": 253,
            "sigops_count": 8,
        },
        "psbt": "02000000015aeb41a258e2349d502cfe434d177eb40058484f608a416f22d01e16b40f0add0000000000ffffffff0322020000000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788ac0000000000000000126a100ec2affac401c38d464471bd3d38badde4c59a3b000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788ac00000000",
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
        "rawtransaction": "02000000016b943ec9d681f10b66ee691acfbb6e7319e4f0b26f33f9109d86b1a33c4af3f00000000000ffffffff020000000000000000306a2e318b1f3daa68ee4d01d92c34fc0a32dcd703091e9b73583b32572861cca0c362e4185ba0af70f850ae46f9de0a8c0ec89a3b000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788ac00000000"
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
        "rawtransaction": "020000000108a3e9208d2fc7d68c05bddcb6a2f72a45d121bd074f503f4775dc60710502ae0000000000ffffffff02800bb203000000001976a914a11b66a67b3ff69671c8f82254099faf374b800e88acbcbce837000000001976a9148d6ae8a3b381663118b4e1eff4cfc7d0954dd6ec88ac00000000"
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
        "rawtransaction": "02000000016aaa312bc6d9faef69825ef56bf2aac2fd8e72fdea5cec406b7498612380ccd90000000000ffffffff02e803000000000000695121026777d124966236b53b47ebbd2a4358d18b57e8177e4b83ee3c148d2c8e5156ad2103e5a4feeaa6547dc1615858aae9bdb107c691ddf2ab180d72dbd2a90c7eb8d894210282b886c087eb37dc8182f14ba6cc3e9485ed618b95804d44aecc17c300b585b053aed0c29a3b000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788ac00000000"
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
        "rawtransaction": "0200000001c4c89e2b3af0e583eb6d97619bfc3c649c4e01b7912c25a0c221c24adc7b80180000000000ffffffff020000000000000000356a332df23dca673690a7495c9209cbc099aa5a2a04410cd94a9eecf10f5f90122e3f5de5efd1baaa99cb8f593ec3443fdd82d37d6404c89a3b000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788ac00000000"
    }
    result = composer.compose_transaction(ledger_db, "send", params, {})
    assert result == expected

    params["source"] = defaults["p2tr_addresses"][0]
    expected = {"rawtransaction": ""}
    # result = composer.compose_transaction(ledger_db, "send", params, {"validate": False})
    # assert result == expected


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
        "rawtransaction": "02000000016140ecf663b2c8091eb8699fd8c0363fc177dc64dd869331a16fbeac20b671270000000000ffffffff0222020000000000001976a9148d6ae8a3b381663118b4e1eff4cfc7d0954dd6ec88ac19c69a3b000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788ac00000000",
        "btc_in": 999999999,
        "btc_out": 546,
        "btc_change": 999999001,
        "btc_fee": 452,
        "data": None,
        "lock_scripts": ["76a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788ac"],
        "inputs_values": [999999999],
        "signed_tx_estimated_size": {
            "vsize": 226,
            "adjusted_vsize": 226,
            "sigops_count": 8,
        },
        "psbt": "02000000016140ecf663b2c8091eb8699fd8c0363fc177dc64dd869331a16fbeac20b671270000000000ffffffff0222020000000000001976a9148d6ae8a3b381663118b4e1eff4cfc7d0954dd6ec88ac19c69a3b000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788ac00000000",
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
        "rawtransaction": "02000000016140ecf663b2c8091eb8699fd8c0363fc177dc64dd869331a16fbeac20b671270000000000ffffffff029a020000000000001976a9148d6ae8a3b381663118b4e1eff4cfc7d0954dd6ec88aca1c59a3b000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788ac00000000",
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
        "psbt": "02000000016140ecf663b2c8091eb8699fd8c0363fc177dc64dd869331a16fbeac20b671270000000000ffffffff029a020000000000001976a9148d6ae8a3b381663118b4e1eff4cfc7d0954dd6ec88aca1c59a3b000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788ac00000000",
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


def test_sigops_count():
    # bc9384919ad5d08b2c66e31f29e7c63572c398a87631c03a4ce9e94ff1cbe62f
    # segwit input -> segwit output
    tx_hex = "01000000000101982a1221773c5aba2be5c6290229023281b1774428a5d280b8c15499368056661b00000017160014e83d1d02a3844c34995ec3fc1ef0b49bf02936f5ffffffff01a0b8c900000000001976a914645e1f9be127080712ae9cd36fb2e65b3121060088ac024730440220012432fdcc626510bd77815257bdcf761db2608c76281176fc5a2fa4ed60cda402205061c264051b7811891af1bc802d0ef770dbbc1d5f63fd9bb6902e76653125e60121020ebf45fb179f47e9d818219903069dcff3e3b4c51641f69000610a4c07fb5a0d00000000"
    tx = Transaction.from_raw(tx_hex)
    selected_utxos = [
        {
            "txid": "665680369954c1b880d2a5284477b1813202290229c6e52bba5a3c7721122a98",
            "vout": 27,
            "script_pub_key": "a9145479813889d9026541cdd297a0aa5dd954d4365b87",
        }
    ]
    assert composer.get_size_info(tx, selected_utxos, signed=True) == (136, 136, 5)

    # 598adf5eddc0787c5d09c67b00df46fb9639659f3873f8afff32a5cedbf98ebf
    # segwit input -> segwit output
    tx_hex = "02000000000101911c185f040030407c904b4991a844a4494c26a28d7b29cc86134ec69001e6e90000000000fdffffff017823360c00000000160014d584f88ec3b200e4115e715f7edde287776006120247304402207fb79a106ba2ec21b4c7f30ba73b7356a60055752956c608e89e7a52ce12bfd2022031c8efa6fa8d14d3bd00ddd4777fea526bfc160802c58c0c1f3f6849c317d84d012103edf275f41337c9c6350b36539cf82260b4c926cd93f38e562e5adc60f6670e8143640d00"
    tx = Transaction.from_raw(tx_hex)
    selected_utxos = [
        {
            "txid": "e9e60190c64e1386cc297b8da2264c49a444a891494b907c403000045f181c91",
            "vout": 0,
            "script_pub_key": "00147277a7e315011fa7d878af066e10b72478590ca1",
        }
    ]
    assert composer.get_size_info(tx, selected_utxos, signed=True) == (110, 110, 1)

    # e5a1cf0cb04c3651e64bf341d3b3ea129d26a35f63bde31d0b8a6e80c1736a22
    # legacy input -> legacy output + segwit output
    tx_hex = "0100000008ec782851d410722d97c4b13fbb95ba14cfac9e9a0bceef43c2b5848529a1241c560000006a473044022037228cbd1d9d20a86aecc55befef072de59fe4eedda265849a7287606c2e6b1002206b8c49e39760d856ba00fdbc2809d8509d09215fad7efcb61086e5e86b3c19ee01210241a12b88d94507d92885403150126a55eaa2fb38b0912da706b242e2a808b45afdffffff84c2165c4d9aa6ab5ce4b4cb1dfb1b2ecc019ccfa1b6642866b822c92dde172a460000006a47304402201d2a7da8d597b967f50ee312821d372c7275dcdd86ffd5d2fa8fc59bead140080220184da8fb930a9a6650b429bef3af37b9956ba7369660cb59246323bcea1d950301210241a12b88d94507d92885403150126a55eaa2fb38b0912da706b242e2a808b45afdffffff7a712c7da7f756577482aab61d46d419c1ad77a31512ce18e1ba51377485d6cf4a0000006a4730440220444f2d41a94e8ef7676e50cd9c0b87dd0dd32b11bed9e533c478f0607f0bdc2802202127a067d95b09e5e3ce7fa587ef6d5b2df6e85a8eb266e5170cb0f942c3c30501210241a12b88d94507d92885403150126a55eaa2fb38b0912da706b242e2a808b45afdffffff11e8c9351e4edfd99a9858aea94bebfb902b5482d18da361ef1736a21499cc830b0000006a47304402206ce5ab18f70a7318800e0e24fa945ff5569e766bca121adcf7735a6985556b0b02204bc3cc024db1a072d19baeafdac097bdf067fcf2bfabafdec1924671a9554b6a01210241a12b88d94507d92885403150126a55eaa2fb38b0912da706b242e2a808b45afdffffffdaacdf8d8a45372ee6d0006949133f74f5bd2e1b50e217348aafc111b23309bf300000006a47304402202be975814bbd77c4502d624c9f15d7dec8fee1aa999aee2174430e727ede7fdf022003be894122d422871dda0520d823825c4741b2ccb4db0538a532e5eda46c209f01210241a12b88d94507d92885403150126a55eaa2fb38b0912da706b242e2a808b45afdffffffa74ccffb5220dd9dcd2b1bc9a7ec70011e331e5bc19749330825fb47ba9d37a5a20000006a473044022051e40c746cbe4bb382b6b4fa31d4dc73f83fc5b623beacc90783f1a592b4e3c002201ff36fabe2e18fbd2a4a0160c9ee6c5b9dc0fe597e67dc4c798b5a4445e70c1201210241a12b88d94507d92885403150126a55eaa2fb38b0912da706b242e2a808b45afdfffffff1b904f0ab6d0e49bb2c1f85d128d224fbd5d6804f5384d48ba1fe86a3e92bd4a20000006a4730440220558e1a79139d17282e32ca8103d0c2f4cd37dc7255cfd31e93b6112824645fff022032bff32c3065b13480714d1129fe72e5a647de6e6610939ea85c8117dfe0b1c101210241a12b88d94507d92885403150126a55eaa2fb38b0912da706b242e2a808b45afdffffff1b6fb33bcbf99c65e4a4dbdf3d026a7ad1e2a6a296681dc36ccb321ac61052cba80000006a4730440220476acc5b5ced17d59d724eb739135b3c255c60c85c4a028e318839c4a2b824e00220115b58982b19f1bd49b65673e7b50adaf3fab605e8c6797e4981cbf47850d6d001210241a12b88d94507d92885403150126a55eaa2fb38b0912da706b242e2a808b45afdffffff02a4121c00000000001976a914dc3def004f9ad05d4d0fc3b23a7ab44f2102fd5188ac002d3101000000001600144f6b3f34c3a7290413a034fff4c09fdef19d2e4100000000"
    tx = Transaction.from_raw(tx_hex)
    selected_utxos = [
        {
            "txid": "1c24a1298584b5c243efce0b9a9eaccf14ba95bb3fb1c4972d7210d4512878ec",
            "vout": 86,
            "script_pub_key": "76a914673c5b8e2e7d25bfa24d6cfdf4078cc3460e501088ac",
        },
        {
            "txid": "2a17de2dc922b8662864b6a1cf9c01cc2e1bfb1dcbb4e45caba69a4d5c16c284",
            "vout": 70,
            "script_pub_key": "76a914673c5b8e2e7d25bfa24d6cfdf4078cc3460e501088ac",
        },
        {
            "txid": "cfd685743751bae118ce1215a377adc119d4461db6aa82745756f7a77d2c717a",
            "vout": 74,
            "script_pub_key": "76a914673c5b8e2e7d25bfa24d6cfdf4078cc3460e501088ac",
        },
        {
            "txid": "83cc9914a23617ef61a38dd182542b90fbeb4ba9ae58989ad9df4e1e35c9e811",
            "vout": 11,
            "script_pub_key": "76a914673c5b8e2e7d25bfa24d6cfdf4078cc3460e501088ac",
        },
        {
            "txid": "bf0933b211c1af8a3417e2501b2ebdf5743f13496900d0e62e37458a8ddfacda",
            "vout": 48,
            "script_pub_key": "76a914673c5b8e2e7d25bfa24d6cfdf4078cc3460e501088ac",
        },
        {
            "txid": "a5379dba47fb2508334997c15b1e331e0170eca7c91b2bcd9ddd2052fbcf4ca7",
            "vout": 162,
            "script_pub_key": "76a914673c5b8e2e7d25bfa24d6cfdf4078cc3460e501088ac",
        },
        {
            "txid": "d42be9a386fea18bd484534f80d6d5fb24d228d1851f2cbb490e6dabf004b9f1",
            "vout": 162,
            "script_pub_key": "76a914673c5b8e2e7d25bfa24d6cfdf4078cc3460e501088ac",
        },
        {
            "txid": "cb5210c61a32cb6cc31d6896a2a6e2d17a6a023ddfdba4e4659cf9cb3bb36f1b",
            "vout": 168,
            "script_pub_key": "76a914673c5b8e2e7d25bfa24d6cfdf4078cc3460e501088ac",
        },
    ]
    assert composer.get_size_info(tx, selected_utxos, signed=True) == (1251, 1251, 4)

    # 3558a1a100b89f50608ce46a0e90f49d3c0c6f6ee4b204748d57243d7e4e53fc
    # legacy input -> opreturn output + legacy output
    tx_hex = "02000000012970ac142b2eca71f3702ce42a30e5b390ac8109aedb551934b3a7d262a4ef3c000000006b483045022100b6774a8aad7792a18d8584285bf14d4e961df04f02b054da2877d78caae2ea8b02203ada32c54423cf5374efe545254496487107aba3d0acde07e1e7ac374c4cb2ac01210234ff78c2726fb1ab2238db8b586efffdc7f577981053a5aea1fb3963527a347fffffffff020000000000000000306a2e22f8b90f458f8a77bbe1e50c49e82addc91897910063983ec690599e7fe7a3a45ba9cab73455e81e13eb75010f4aac840100000000001976a914ae8222d073a8fcfe24021484dddbae72a8307f6a88ac00000000"
    tx = Transaction.from_raw(tx_hex)
    selected_utxos = [
        {
            "txid": "3cefa462d2a7b3341955dbae0981ac90b3e5302ae42c70f371ca2e2b14ac7029",
            "vout": 0,
            "script_pub_key": "76a914ae8222d073a8fcfe24021484dddbae72a8307f6a88ac",
        }
    ]
    assert composer.get_size_info(tx, selected_utxos, signed=True) == (249, 249, 4)

    # 9eaaadc946e8bd6502f3a99220fb22fc613a24960bf52622425bd2b237d93d38
    # legacy input -> multisig output + legacy output
    tx_hex = "0100000002a77887272e139cc0c8f6b8b003a19eeb191dc0f8a13e5cf3614c04609783acdd010000006b483045022100e43216b5be8200c50d34645b0751322ab077d5574711be37da36719174d3776c022072e129d4e635b441d9ba9d47bc9dd2089c032cefc1325b2e76e424cf9aed3bc60121021720dc2e2365f6dec79744b692e9c3e561906acd0b47a7382429efbe8d3b09acffffffff5336838dd6c5ee1d773c07149770ced865c2b2709580f1fb2e63b5388c295a90010000006b483045022100f443ff2fe4c9a974a6399eb9349afdd8c99db9c810308c887fd3f1eaf68fd7fb022004d406bfcb8dfa0a015619c940444f30b21f640b7b47a355aa638647ff329f150121021720dc2e2365f6dec79744b692e9c3e561906acd0b47a7382429efbe8d3b09acffffffff0ce8030000000000006951210361886315e46a4ca5ffa68e17c66c4da01795a9521dae3c39578cd5de54c7dd5f2102eb225587684295bf74b33873bebbce47a715ea43cb9623b33134062e87c0b29121021720dc2e2365f6dec79744b692e9c3e561906acd0b47a7382429efbe8d3b09ac53aee8030000000000006951210261886315e46a4ca5ff9ad856144d1fcb6ee29b10249d490834d47a8b07d1954a2103ee3f4c95740ed9f735b1224892eb830af656a310d5c072e664642802ebaec14521021720dc2e2365f6dec79744b692e9c3e561906acd0b47a7382429efbe8d3b09ac53aee8030000000000006951210261886315e46a4ca5ff9ac5266f6938c179e1c026648c061967f104e674d29e612102f42204c82414d1e43dba776ab1bd8d06f415b402c4d572e664645178919fa76f21021720dc2e2365f6dec79744b692e9c3e561906acd0b47a7382429efbe8d3b09ac53aee8030000000000006951210361886315e46a4ca5ff8cdc347828789222a19c6b28cc085d63b51ca36388ca2f2103aa7045c134149ba576aa6e6080a0c108ee17e256848d69ec68664729d199cdc321021720dc2e2365f6dec79744b692e9c3e561906acd0b47a7382429efbe8d3b09ac53aee8030000000000006951210261886315e46a4ca5ffd79c726f226d903bb58b3069cd635a3fed46a1339ec53b2102b97512cb3d0f87a974ea7877bc96c94fb115ea43858460ec68664739c48de6f121021720dc2e2365f6dec79744b692e9c3e561906acd0b47a7382429efbe8d3b09ac53aee8030000000000006951210361886315e46a4ca5ffca88683e792ed47efac770278e1e0966bc18f6668ccf3f2102a97647c5330e8fb266ff2866eefa9649b707b35bd68232e426765578c4cbab8c21021720dc2e2365f6dec79744b692e9c3e561906acd0b47a7382429efbe8d3b09ac53aee8030000000000006951210361886315e46a4ca5ffdd8c647c217cc474a5cf6a7c9f0f5c62ef4ef5608dcb1d2103fa7712c4340f80bd67a97967bbf99e1ae407e053808569eb72275c7a919ca57721021720dc2e2365f6dec79744b692e9c3e561906acd0b47a7382429efbe8d3b09ac53aee8030000000000006951210361886315e46a4ca5ff8cdf3e2820289025f190602d9a085f64ba1bf2348899942103aa701593350482e360ab7936bcaacd4eec0fb100d6d236ba2220032d95c8a27e21021720dc2e2365f6dec79744b692e9c3e561906acd0b47a7382429efbe8d3b09ac53aee8030000000000006951210261886315e46a4ca5ff88d9367d287d9027a599622d9e0c0966be1ea7678ccec32102ff7f13c53d0784e062fe2237bea8974cb051e502808068ed7d72077894c3a25021021720dc2e2365f6dec79744b692e9c3e561906acd0b47a7382429efbe8d3b09ac53aee8030000000000006951210261886315e46a4ca5ff80df627d287e9027a599622d9e0c0967bd11f160ddc6f32102a87340c530008fe06cad2a31bbf09d1ae003b650868764be7020567c969ba32421021720dc2e2365f6dec79744b692e9c3e561906acd0b47a7382429efbe8d3b09ac53aee803000000000000695121027e886315e46a4ca5ff8adc60797b2e9574f6cb3625965d5a67bc18f6668ccff42103a9655b8f0436b78554c81a03dfc9af2ad437d063b0b450dc4446654ba5fa92be21021720dc2e2365f6dec79744b692e9c3e561906acd0b47a7382429efbe8d3b09ac53ae89590700000000001976a914f7468e8e02d92044f3634b4f373a125f4cc5ccbd88ac00000000"
    tx = Transaction.from_raw(tx_hex)
    selected_utxos = [
        {
            "txid": "ddac839760044c61f35c3ea1f8c01d19eb9ea103b0b8f6c8c09c132e278778a7",
            "vout": 1,
            "script_pub_key": "76a914f7468e8e02d92044f3634b4f373a125f4cc5ccbd88ac",
        },
        {
            "txid": "905a298c38b5632efbf1809570b2c265d8ce709714073c771deec5d68d833653",
            "vout": 1,
            "script_pub_key": "76a914f7468e8e02d92044f3634b4f373a125f4cc5ccbd88ac",
        },
    ]
    assert composer.get_size_info(tx, selected_utxos, signed=True) == (4420, 1594, 884)

    # 4ecb2667294f5694629fc17dd1ec95087125af44372b46958ff47fe2476f1c0a
    # segwit input -> op_return output + segwit output
    tx_hex = "020000000001010e19545f5987c06385d31dc5672fbad9c82c60383c7ccccae81f746a8ed100f00400000000fdffffff0200000000000000003c6a3ab05f911468b62997f8af9b77e5d939f22496e23a3e9fa72537e3065e278c351e540762065daf1101b8b9abfc910ebf17c940ad370a09e1cd5c2b12a3030000000000160014807c3e0589bd35991a990a4058678957a137ab460248304502210087ccfc3ba8b9627a7da47d0295f1f8c89426c0d8cb7cd246b3f1185de4f3139c02201776192b1aae5f6bc05b43f91a27750fde35f599d0968167dcf0c0e0424a411e0121032310a8d197323b9e3407e8f032ea5b85249e31eaee5ae0ac7db27d76df2538d000000000"
    tx = Transaction.from_raw(tx_hex)
    selected_utxos = [
        {
            "txid": "f000d18e6a741fe8cacc7c3c38602cc8d9ba2f67c51dd38563c087595f54190e",
            "vout": 4,
            "script_pub_key": "0014807c3e0589bd35991a990a4058678957a137ab46",
        }
    ]
    assert composer.get_size_info(tx, selected_utxos, signed=True) == (179, 179, 1)

    # 16d2a285e9db2ec1364f7d8c2293c99abbff7f805e9bd116a0ba34b4f569b923
    # segwit input -> multisig output + segwit output
    tx_hex = "020000000001019ab51dec20ef06572489bd48772f254a40c656ff2b99c7fa54f790bc9ea55fee0100000000ffffffff04e80300000000000069512102646fcd4e1bba4d406395d1709e29cfe1b33de44f9f9b1598bd0263ce4c0391ee2102fba49c17e222b718b3a649ac1bcf143568545213d415594c5aa363fc9b93bf0721022a58f4bc199c871f622692c3bc6b94b46577294a357346d549267a8947678af353aee80300000000000069512102646fcd4e1bba4d4063670af7a2ec5354d0634510f131c1b47f0b6ef17a5de1fd210264d59cdee619a0131fec03eba098e10e9e8bb2ce8f8090ccd5f6a3894c41584821022a58f4bc199c871f622692c3bc6b94b46577294a357346d549267a8947678af353aee803000000000000695121034a6fcd4e1bba4d406396d5339e829a21ed344ea86e4091a4d3cb16d8c570295c210264d59cdea19f2c1273b83a8ade41b4749e8bb2ce8f8090ccf1f6a3894c41580e21022a58f4bc199c871f622692c3bc6b94b46577294a357346d549267a8947678af353aeb10b02000000000016001450efc3efc606c7891caef1aed700ed4e204be2b302483045022100b1acc9fca64b4a588276971a745b8613b3f534b5214b60c6590790b981bdeb38022071dbd4ea2d365eb971e3535b4c19d81d6e7eea65df6577294dbcfff16f16278d0121022a58f4bc199c871f622692c3bc6b94b46577294a357346d549267a8947678af300000000"
    tx = Transaction.from_raw(tx_hex)
    selected_utxos = [
        {
            "txid": "ee5fa59ebc90f754fac7992bff56c6404a252f7748bd89245706ef20ec1db59a",
            "vout": 1,
            "script_pub_key": "001450efc3efc606c7891caef1aed700ed4e204be2b3",
        }
    ]
    assert composer.get_size_info(tx, selected_utxos, signed=True) == (1205, 452, 241)


def construct_tx(db, source, destination, disable_utxo_locks=False, inputs_set=None):
    composer.UTXOLocks().set_limits(60, 2000)
    return composer.compose_transaction(
        db,
        "send",
        {
            "source": source,
            "destination": destination,
            "asset": "XCP",
            "quantity": 1,
        },
        {
            "disable_utxo_locks": disable_utxo_locks,
            "inputs_set": inputs_set,
        },
    )


def test_utxolocks(ledger_db):
    """it shouldn't use the same UTXO"""
    composer.UTXOLocks().init()

    tx1hex = construct_tx(
        ledger_db, "mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns", "mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns"
    )
    tx2hex = construct_tx(
        ledger_db, "mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns", "mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns"
    )

    tx1f = BytesIO(binascii.unhexlify(tx1hex["rawtransaction"]))
    tx1 = bitcoin.core.CTransaction.stream_deserialize(tx1f)

    tx2f = BytesIO(binascii.unhexlify(tx2hex["rawtransaction"]))
    tx2 = bitcoin.core.CTransaction.stream_deserialize(tx2f)

    assert (tx1.vin[0].prevout.hash, tx1.vin[0].prevout.n) != (
        tx2.vin[0].prevout.hash,
        tx2.vin[0].prevout.n,
    )


def test_utxolocks_custom_input(ledger_db):
    composer.UTXOLocks().init()

    """it should not use the same UTXO"""
    inputs_set = [
        {
            "txid": "b9fc3aa355b77ecb63282fc96e63912a253e98bf9cf441fbfbecc3fb277c4985",
            "txhex": "0100000003114bbc2ce4f18490cd33fa17ad747f2cbb932fe4bd628e7729f18e73caa9c824000000006b4830450220170594244dacb99013340f07ca7da05c91d2f235094481213abf3b3648ff12ab022100ea612f4326e074daeb3f3b92bce7862c7377d16e66930415cb33930e773d8600012103bdd82e7398e604438316511b7be56925256b5b1f64b508432f4b4e3e728db637ffffffff22fcc4468552b950781e3facbf75a27b8d633cb7299f02b4bcc3615d9923bcfb000000006b483045022051ed13a5bf5e9ea753f0b2e4e76d1bea73de912e214314ed96e043ad21f53dee022100f6556d547c5012fcbd3348f71da8fe03eb101f73b7b1b366e3937119cc87a90c01210282b886c087eb37dc8182f14ba6cc3e9485ed618b95804d44aecc17c300b585b0ffffffffe5237334401359af1cc80b3b4af969fab42e92e636ef0523df6b68122f23d952000000006b483045022100cd74fe9ca13e44607521f410468979ed9e0b3addef2a9d48e08bf608d72c446c022058753f930f2d394410c3e6e950788e6b0371d4403ef5a9dc194980218de5ac76012102ab7a70956655c4d4cc44b73587ae70a21ab0db9ba8d704b97d911ea3bf1e5d67ffffffff02ffb3a900000000001976a9148d6ae8a3b381663118b4e1eff4cfc7d0954dd6ec88ac0065cd1d000000001976a914d1ba3ba3d6f5ad06b148bcc04151ecab84fc397988ac00000000",
            "amount": 0.11121663,
            "vout": 0,
            "confirmations": 74,
            "script_pub_key": "76a9148d6ae8a3b381663118b4e1eff4cfc7d0954dd6ec88ac",
            "address": "mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns",
        }
    ]
    inputs_set = "b9fc3aa355b77ecb63282fc96e63912a253e98bf9cf441fbfbecc3fb277c4985:0:11121663:76a9148d6ae8a3b381663118b4e1eff4cfc7d0954dd6ec88ac"

    construct_tx(
        ledger_db,
        "mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns",
        "mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns",
        inputs_set=inputs_set,
    )
    try:
        construct_tx(
            ledger_db,
            "mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns",
            "mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns",
            inputs_set=inputs_set,
        )
    except exceptions.ComposeError as e:
        print(e)
        return

    raise Exception("Should have raised a BalanceError")


def test_compose_attach(ledger_db, defaults):
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
        "inputs_set": f"{utxo_with_balance}:546:76a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788ac",
        "disable_utxo_locks": True,
    }

    expected = {
        "rawtransaction": "02000000016140ecf663b2c8091eb8699fd8c0363fc177dc64dd869331a16fbeac20b671270000000000ffffffff0100000000000000002d6a2b3e469c1362a96b89affa189049413129c8c5352c1cab3e99a708b7a8d7b8bfd11f3fc66d86a5bd1885b6c000000000",
        "btc_in": 546,
        "btc_out": 0,
        "btc_change": 0,
        "btc_fee": 546,
        "data": b"CNTRPRTYfmtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns",
        "lock_scripts": ["76a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788ac"],
        "inputs_values": [546],
        "signed_tx_estimated_size": {
            "vsize": 212,
            "adjusted_vsize": 212,
            "sigops_count": 0,
        },
        "psbt": "02000000016140ecf663b2c8091eb8699fd8c0363fc177dc64dd869331a16fbeac20b671270000000000ffffffff0100000000000000002d6a2b3e469c1362a96b89affa189049413129c8c5352c1cab3e99a708b7a8d7b8bfd11f3fc66d86a5bd1885b6c000000000",
        "params": {
            "source": utxo_with_balance,
            "destination": defaults["addresses"][1],
            "skip_validation": False,
        },
        "name": "detach",
    }

    result = composer.compose_transaction(ledger_db, "detach", params, construct_params)
    assert result == expected
