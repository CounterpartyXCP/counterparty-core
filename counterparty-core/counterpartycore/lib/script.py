"""
None of the functions/objects in this module need be passed `db`.

Naming convention: a `pub` is either a pubkey or a pubkeyhash
"""

import binascii

import bitcoin as bitcoinlib
from counterparty_rs import b58, utils

from counterpartycore.lib import config, exceptions, opcodes


def base58_check_encode(original, version):
    return b58.b58_encode(version + binascii.unhexlify(original))


def base58_check_decode(s, version):
    try:
        decoded = bytes(b58.b58_decode(s))
    except ValueError:
        raise exceptions.Base58Error("invalid base58 string")  # noqa: B904

    if decoded[0] != ord(version):
        raise exceptions.VersionByteError("incorrect version byte")

    return decoded[1:]


def is_multisig(address):
    """Check if the address is multi-signature."""
    array = address.split("_")
    return len(array) > 1


def test_array(signatures_required, pubs, signatures_possible):
    """Check if multi-signature data is valid."""
    try:
        signatures_required, signatures_possible = (
            int(signatures_required),
            int(signatures_possible),
        )
    except (ValueError, TypeError):
        raise exceptions.MultiSigAddressError("Signature values not integers.")  # noqa: B904
    if signatures_required < 1 or signatures_required > 3:
        raise exceptions.MultiSigAddressError("Invalid signatures_required.")
    if signatures_possible < 2 or signatures_possible > 3:
        raise exceptions.MultiSigAddressError("Invalid signatures_possible.")
    for pubkey in pubs:
        if "_" in pubkey:
            raise exceptions.MultiSigAddressError("Invalid characters in pubkeys/pubkeyhashes.")
    if signatures_possible != len(pubs):
        raise exceptions.InputError(
            "Incorrect number of pubkeys/pubkeyhashes in multi-signature address."
        )


def construct_array(signatures_required, pubs, signatures_possible):
    """Create a multi-signature address."""
    test_array(signatures_required, pubs, signatures_possible)
    address = "_".join([str(signatures_required)] + sorted(pubs) + [str(signatures_possible)])
    return address


def extract_array(address):
    """Extract data from multi-signature address."""
    assert is_multisig(address)
    array = address.split("_")
    signatures_required, pubs, signatures_possible = array[0], sorted(array[1:-1]), array[-1]
    test_array(signatures_required, pubs, signatures_possible)
    return int(signatures_required), pubs, int(signatures_possible)


def script_to_asm(scriptpubkey):
    try:
        if isinstance(scriptpubkey, bitcoinlib.core.script.CScript):
            scriptpubkey = bytes(scriptpubkey)
        elif isinstance(scriptpubkey, str):
            scriptpubkey = binascii.unhexlify(scriptpubkey)
        asm = utils.script_to_asm(scriptpubkey)
        if asm[-1] == opcodes.OP_CHECKMULTISIG:  # noqa: F405
            asm[-2] = int.from_bytes(asm[-2], "big")
            asm[0] = int.from_bytes(asm[0], "big")
        return asm
    except BaseException as e:  # noqa: F841
        raise exceptions.DecodeError("invalid script")  # noqa: B904


def script_to_address(scriptpubkey):
    if isinstance(scriptpubkey, str):
        scriptpubkey = binascii.unhexlify(scriptpubkey)
    try:
        script = bytes(scriptpubkey, "utf-8") if type(scriptpubkey) == str else bytes(scriptpubkey)  # noqa: E721
        return utils.script_to_address(script, config.NETWORK_NAME)
    except BaseException as e:  # noqa: F841
        raise exceptions.DecodeError("scriptpubkey decoding error")  # noqa: B904


def script_to_address2(scriptpubkey):
    if isinstance(scriptpubkey, str):
        scriptpubkey = binascii.unhexlify(scriptpubkey)
    try:
        script = bytes(scriptpubkey, "utf-8") if type(scriptpubkey) == str else bytes(scriptpubkey)  # noqa: E721
        return utils.script_to_address2(script, config.NETWORK_NAME)
    except BaseException as e:  # noqa: F841
        raise exceptions.DecodeError("scriptpubkey decoding error")  # noqa: B904
