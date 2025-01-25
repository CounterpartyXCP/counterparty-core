import binascii
import re

import pytest
from bitcoinutils.keys import P2pkhAddress, P2wpkhAddress
from bitcoinutils.script import Script
from bitcoinutils.transactions import TxOutput
from counterpartycore.lib import exceptions
from counterpartycore.lib.api import composer
from counterpartycore.pytest.fixtures.defaults import DEFAULT_PARAMS as DEFAULTS

PROVIDED_PUBKEYS = ",".join(
    [DEFAULTS["pubkey"][DEFAULTS["addresses"][0]], DEFAULTS["pubkey"][DEFAULTS["addresses"][1]]]
)

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
                        "9d56dd13f3650963c263720b3842b23aa86813c7d1",
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
    assert composer.data_to_pubkey_pairs(b"Hello, World!" * 10, ARC4_KEY) == [
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
