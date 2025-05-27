import binascii
import re

import bitcoin
import pytest
from counterparty_rs import utils
from counterpartycore.lib import config, exceptions
from counterpartycore.lib.utils import address
from counterpartycore.test.mocks.counterpartydbs import ProtocolChangesDisabled


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
    with ProtocolChangesDisabled(["taproot_support"]):
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

    with ProtocolChangesDisabled(["taproot_support"]):
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
    with ProtocolChangesDisabled(["taproot_support"]):
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
    with ProtocolChangesDisabled(["taproot_support"]):
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
        assert not address.is_valid_address(
            "tc1qv9g0n4qltu9hss0khegwmg94lxn6sy6haqhj7a", "testnet3"
        )
        assert not address.is_valid_address("35cNLGf1SRG7R1Hkuh4V5dP4qfHmsyqUTk0", "mainnet")
        assert not address.is_valid_address("toto", "mainnet")
        assert not address.is_valid_address("toto", "testnet3")
        assert address.is_valid_address("mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "testnet3")
        assert address.is_valid_address("mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns", "testnet3")
        assert address.is_valid_address(
            "bc1qrp33g0q5c5txsp9arysrx4k6zdkfs4nce4xj0gdcccefvpysxf3qccfmv3", "mainnet"
        )
        assert address.is_valid_address(
            "tb1pqqqqp399et2xygdj5xreqhjjvcmzhxw4aywxecjdzew6hylgvsesf3hn0c", "testnet3"
        )
        assert address.is_valid_address(
            "bcrt1qrp33g0q5c5txsp9arysrx4k6zdkfs4nce4xj0gdcccefvpysxf3qzf4jry", "regtest"
        )


def address_roundtrip(address, network):
    """Test that an address can be packed and then unpacked correctly"""
    # Pack the address
    packed = bytes(utils.pack_address(address, network))
    # Decode the address from compact format
    unpacked = utils.unpack_address(packed, network)
    # Verify that the decoded address matches the original
    assert address == unpacked, f"Failed for {address} on {network}"
    # For debugging, also print the hex form
    print(f"{address} ({network}) -> {binascii.hexlify(packed).decode()} -> {unpacked}")
    return packed


def test_p2pkh_addresses():
    """Test P2PKH addresses on different networks"""
    # Mainnet P2PKH
    packed = address_roundtrip("1BvBMSEYstWetqTFn5Au4m4GFg7xJaNVN2", "mainnet")
    assert packed[0] == 0x01  # Verify P2PKH prefix
    assert len(packed) == 21  # Verify length

    # Testnet P2PKH
    packed = address_roundtrip("mipcBbFg9gMiCh81Kj8tqqdgoZub1ZJRfn", "testnet3")
    assert packed[0] == 0x01
    assert len(packed) == 21

    # Regtest P2PKH
    packed = address_roundtrip("mipcBbFg9gMiCh81Kj8tqqdgoZub1ZJRfn", "regtest")
    assert packed[0] == 0x01
    assert len(packed) == 21


def test_p2sh_addresses():
    """Test P2SH addresses on different networks"""
    # Mainnet P2SH
    packed = address_roundtrip("3J98t1WpEZ73CNmQviecrnyiWrnqRhWNLy", "mainnet")
    assert packed[0] == 0x02  # Verify P2SH prefix
    assert len(packed) == 21  # Verify length

    # Testnet P2SH
    packed = address_roundtrip("2MzQwSSnBHWHqSAqtTVQ6v47XtaisrJa1Vc", "testnet3")
    assert packed[0] == 0x02
    assert len(packed) == 21

    # Regtest P2SH
    packed = address_roundtrip("2MzQwSSnBHWHqSAqtTVQ6v47XtaisrJa1Vc", "regtest")
    assert packed[0] == 0x02
    assert len(packed) == 21


def test_p2wpkh_addresses():
    """Test P2WPKH (Segwit v0) addresses on different networks"""
    # Mainnet P2WPKH
    packed = address_roundtrip("bc1qw508d6qejxtdg4y5r3zarvary0c5xw7kv8f3t4", "mainnet")
    assert packed[0] == 0x03  # Verify Witness prefix
    assert packed[1] == 0x00  # Verify Segwit version (v0)
    assert len(packed) == 22  # 1 (prefix) + 1 (version) + 20 (pubkey hash)

    # Testnet P2WPKH
    packed = address_roundtrip("tb1qw508d6qejxtdg4y5r3zarvary0c5xw7kxpjzsx", "testnet3")
    assert packed[0] == 0x03
    assert packed[1] == 0x00
    assert len(packed) == 22

    # Regtest P2WPKH
    packed = address_roundtrip("bcrt1qw508d6qejxtdg4y5r3zarvary0c5xw7kygt080", "regtest")
    assert packed[0] == 0x03
    assert packed[1] == 0x00
    assert len(packed) == 22


def test_p2wsh_addresses():
    """Test P2WSH (Segwit v0) addresses on different networks"""
    # Mainnet P2WSH
    packed = address_roundtrip(
        "bc1qrp33g0q5c5txsp9arysrx4k6zdkfs4nce4xj0gdcccefvpysxf3qccfmv3", "mainnet"
    )
    assert packed[0] == 0x03  # Verify Witness prefix
    assert packed[1] == 0x00  # Verify Segwit version (v0)
    assert len(packed) == 34  # 1 (prefix) + 1 (version) + 32 (script hash)

    # Testnet P2WSH
    packed = address_roundtrip(
        "tb1qrp33g0q5c5txsp9arysrx4k6zdkfs4nce4xj0gdcccefvpysxf3q0sl5k7", "testnet3"
    )
    assert packed[0] == 0x03
    assert packed[1] == 0x00
    assert len(packed) == 34

    # Regtest P2WSH
    packed = address_roundtrip(
        "bcrt1qrp33g0q5c5txsp9arysrx4k6zdkfs4nce4xj0gdcccefvpysxf3qzf4jry", "regtest"
    )
    assert packed[0] == 0x03
    assert packed[1] == 0x00
    assert len(packed) == 34


def test_p2tr_addresses():
    """Test P2TR (Taproot, Segwit v1) addresses on different networks"""
    # Mainnet P2TR
    packed = address_roundtrip(
        "bc1p0xlxvlhemja6c4dqv22uapctqupfhlxm9h8z3k2e72q4k9hcz7vqzk5jj0", "mainnet"
    )
    assert packed[0] == 0x03  # Verify Witness prefix
    assert packed[1] == 0x01  # Verify Segwit version (v1 for Taproot)
    assert len(packed) == 34  # 1 (prefix) + 1 (version) + 32 (x-only pubkey)

    # Testnet P2TR
    packed = address_roundtrip(
        "tb1pqqqqp399et2xygdj5xreqhjjvcmzhxw4aywxecjdzew6hylgvsesf3hn0c", "testnet3"
    )
    assert packed[0] == 0x03
    assert packed[1] == 0x01
    assert len(packed) == 34

    # Regtest P2TR
    packed = address_roundtrip(
        "bcrt1pn8p562k8ztfd76lrnsgt4s3su5l630rwzra0jwaxgamurpj0elkqsflm7x", "regtest"
    )
    assert packed[0] == 0x03
    assert packed[1] == 0x01
    assert len(packed) == 34


def test_invalid_addresses():
    """Test for invalid addresses that should raise exceptions"""
    # Invalid address
    with pytest.raises(
        exceptions.AddressError,
        match=re.escape("The address invalid_address is not a valid bitcoin address (mainnet)"),
    ):
        config.NETWORK_NAME = "mainnet"
        address.pack("invalid_address")

    # Invalid network
    with pytest.raises(exceptions.AddressError):
        config.NETWORK_NAME = "invalid_network"
        address.pack("1BvBMSEYstWetqTFn5Au4m4GFg7xJaNVN2")

    # Valid address on wrong network
    with pytest.raises(exceptions.AddressError):
        config.NETWORK_NAME = "testnet3"
        address.pack("1BvBMSEYstWetqTFn5Au4m4GFg7xJaNVN2")

    # Unpacking invalid data
    with pytest.raises(
        exceptions.DecodeError,
        match=re.escape("b'\\x05' is not a valid packed bitcoin address (mainnet)"),
    ):
        config.NETWORK_NAME = "mainnet"
        address.unpack(b"\x05")  # Invalid prefix

    with pytest.raises(exceptions.DecodeError):
        config.NETWORK_NAME = "mainnet"
        address.unpack(b"\x01\x01\x02")  # Incorrect length for P2PKH

    with pytest.raises(exceptions.DecodeError):
        config.NETWORK_NAME = "mainnet"
        address.unpack(b"\x03\xff\x01\x02")  # Invalid witness version

    config.NETWORK_NAME = "regtest"


def test_pack_legacy():
    with ProtocolChangesDisabled(["taproot_support", "segwit_support"]):
        assert (
            address.pack_legacy("mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc")
            == b"oH8\xd8\xb3X\x8cL{\xa7\xc1\xd0o\x86n\x9b79\xc607"
        )

        with pytest.raises(bitcoin.base58.InvalidBase58Error):
            address.pack_legacy("bcrt1qw508d6qejxtdg4y5r3zarvary0c5xw7kygt080")
            address.pack_legacy("invalid_address")
