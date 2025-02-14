import binascii
import re

import pytest
from counterpartycore.lib import config, exceptions
from counterpartycore.lib.utils import address


def test_is_pubkeyhash(defaults):
    # valid bitcoin address"
    assert address.is_pubkeyhash("mnMrocns5kBjPZxRxXb5A1gx7gAoRZWPP6")

    # valid P2SH bitcoin address, but is_pubkeyhash specifically checks for valid P2PKH address"
    assert not address.is_pubkeyhash(defaults["p2sh_addresses"][0])

    # invalid checksum"
    assert not address.is_pubkeyhash("mnMrocns5kBjPZxRxXb5A1gx7gAoRZWPP7")

    # invalid version byte"
    assert not address.is_pubkeyhash("LnMrocns5kBjPZxRxXb5A1gx7gAoRZWPP6")


def test_pubkeyhash_array(defaults):
    # invalid PubKeyHashes. Multi-signature address must use PubKeyHashes, not public keys."
    with pytest.raises(
        exceptions.MultiSigAddressError,
        match="Invalid PubKeyHashes. Multi-signature address must use PubKeyHashes, not public keys.",
    ):
        address.pubkeyhash_array(
            "1_xxxxxxxxxxxWRONGxxxxxxxxxxxxxxxxxx_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2"
        )

    assert address.pubkeyhash_array(
        "1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2"
    ) == [
        "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc",
        "mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns",
    ]


def test_validate(defaults):
    assert address.validate("mnMrocns5kBjPZxRxXb5A1gx7gAoRZWPP6") is None
    assert address.validate(defaults["p2sh_addresses"][0]) is None
    assert address.validate(defaults["p2ms_addresses"][0]) is None

    with pytest.raises(exceptions.Base58Error, match="invalid base58 string"):
        address.validate("mnMrocns5kBjPZxRxXb5A1gx7gAoRZWPP7")

    with pytest.raises(
        exceptions.MultiSigAddressError,
        match=re.escape(
            "Invalid PubKeyHashes. Multi-signature address must use PubKeyHashes, not public keys."
        ),
    ):
        address.validate(
            "1_" + defaults["p2sh_addresses"][0] + "_mnMrocns5kBjPZxRxXb5A1gx7gAoRZWPP6_2"
        )


def test_pack(defaults):
    original_addres_version = config.ADDRESSVERSION
    original_p2sh_address_version = config.P2SH_ADDRESSVERSION
    config.ADDRESSVERSION = config.ADDRESSVERSION_MAINNET
    config.P2SH_ADDRESSVERSION = config.P2SH_ADDRESSVERSION_MAINNET

    assert address.pack("1AAAA1111xxxxxxxxxxxxxxxxxxy43CZ9j") == binascii.unhexlify(
        "006474849fc9ac0f5bd6b49fe144d14db7d32e2445"
    )
    assert address.pack("1AAAA2222xxxxxxxxxxxxxxxxxxy4pQ3tU") == binascii.unhexlify(
        "00647484b055e2101927e50aba74957ba134d501d7"
    )
    assert address.pack("3AAAA1111xxxxxxxxxxxxxxxxxxy3SsDsZ") == binascii.unhexlify(
        "055ce31be63403fa7b19f2614272547c15c8df86b9"
    )

    config.ADDRESSVERSION = original_addres_version
    config.P2SH_ADDRESSVERSION = original_p2sh_address_version

    assert address.pack("2MtAV7xpAzU69E8GxRF2Vd2xt79kDnif6F5") == binascii.unhexlify(
        "C40A12AD889AECC8F6213BFD6BD47911CAB1C30E5F"
    )

    with pytest.raises(
        Exception,
        match=re.escape("The address BADBASE58III is not a valid bitcoin address (regtest)"),
    ):
        address.pack("BADBASE58III")


def test_unpack():
    assert (
        address.unpack(binascii.unhexlify("006474849fc9ac0f5bd6b49fe144d14db7d32e2445"))
        == "1AAAA1111xxxxxxxxxxxxxxxxxxy43CZ9j"
    )
    assert (
        address.unpack(binascii.unhexlify("00647484b055e2101927e50aba74957ba134d501d7"))
        == "1AAAA2222xxxxxxxxxxxxxxxxxxy4pQ3tU"
    )
    assert (
        address.unpack(binascii.unhexlify("055ce31be63403fa7b19f2614272547c15c8df86b9"))
        == "3AAAA1111xxxxxxxxxxxxxxxxxxy3SsDsZ"
    )
    assert (
        address.unpack(binascii.unhexlify("C40A12AD889AECC8F6213BFD6BD47911CAB1C30E5F"))
        == "2MtAV7xpAzU69E8GxRF2Vd2xt79kDnif6F5"
    )


def test_is_valid_address():
    assert address.is_valid_address("18H63wjcZqaBwifMjopS9jSZejivq7Lgq4", "mainnet")
    assert address.is_valid_address("1MWqsvFhABHULk24U81tV9aTaWJj2z5m7Z", "mainnet")
    assert address.is_valid_address("1EDrzMiWkB1yW3YKbceDX25kuxpicUSPqn", "mainnet")
    assert address.is_valid_address(
        "2_1HFhTq3rzAaodxjU4dJ8ctxwUHZ6gHMDS7_1workshyTLmwVf1PvnDMLPUi3MZZWXzH8_2",
        "mainnet",
    )
    assert address.is_valid_address(
        "2_17VLRV4y7g15KNhCepYvgigHHvREzbEmRn_1FkQMTyqzD2BK5PsmWX13AeJAHz5NEw7gq_1HhfcdD1hRaim17m5qLEwGgHY7PBTb1Dof_3",
        "mainnet",
    )
    assert address.is_valid_address("bc1q707uusxpdv60jz8973z8rudj6y4ae73vwerhx8", "mainnet")
    assert address.is_valid_address("bc1q7rdrecerefrzenl6eq94fqxzhjj02shf0hm490", "mainnet")
    assert address.is_valid_address("bc1qx8g8dca9clxs4z6y4fdtmw6x2qcyffymtp4eed", "mainnet")
    assert address.is_valid_address("3Hcy4ypuvSnbySZAxSj2jiCfFCRzqvCXwC", "mainnet")
    assert address.is_valid_address("3FA93F7DgJEBkAvq1d9WFrrrFGGppkYHYd", "mainnet")
    assert address.is_valid_address("35cNLGf1SRG7R1Hkuh4V5dP4qfHmsyqUTk", "mainnet")
    assert address.is_valid_address("tb1q5ljtmkhtkhgrxdxaqvvut2trtrrsjgx8fsxfl5", "testnet3")
    assert address.is_valid_address("tb1qv9g0n4qltu9hss0khegwmg94lxn6sy6haqhj7a", "testnet3")
    assert address.is_valid_address("mtuTqahviyGpNL3qT5zV88Gm1YAbD2zZg8", "testnet3")
    assert not address.is_valid_address("mtuTqahviyGpNL3qT5zV88Gm1YAbD2zZg", "testnet3")
    assert not address.is_valid_address("tc1qv9g0n4qltu9hss0khegwmg94lxn6sy6haqhj7a", "testnet3")
    assert not address.is_valid_address("35cNLGf1SRG7R1Hkuh4V5dP4qfHmsyqUTk0", "mainnet")
    assert not address.is_valid_address("toto", "mainnet")
    assert not address.is_valid_address("toto", "testnet3")
    assert address.is_valid_address("mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "testnet3")
    assert address.is_valid_address("mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns", "testnet3")
