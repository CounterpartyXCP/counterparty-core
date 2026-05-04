import binascii

from counterparty_rs import utils  # pylint: disable=no-name-in-module
from counterpartycore.lib import config, exceptions
from counterpartycore.lib.utils import opcodes


def script_to_asm(scriptpubkey):
    try:
        if isinstance(scriptpubkey, str):
            scriptpubkey = binascii.unhexlify(scriptpubkey)
        asm = utils.script_to_asm(scriptpubkey)
        if asm[-1] == opcodes.OP_CHECKMULTISIG:  # noqa: F405
            asm[-2] = int.from_bytes(asm[-2], "big")
            asm[0] = int.from_bytes(asm[0], "big")
        return asm
    except BaseException as e:
        raise exceptions.DecodeError("invalid script") from e


def get_output_type(script_pub_key):
    asm = script_to_asm(script_pub_key)
    if asm[0] == opcodes.OP_RETURN:
        return "OP_RETURN"
    if len(asm) == 2 and asm[1] == opcodes.OP_CHECKSIG:
        return "P2PK"
    if (
        len(asm) == 5
        and asm[0] == opcodes.OP_DUP
        and asm[3] == opcodes.OP_EQUALVERIFY
        and asm[4] == opcodes.OP_CHECKSIG
    ):
        return "P2PKH"
    if len(asm) >= 4 and asm[-1] == opcodes.OP_CHECKMULTISIG and asm[-2] == len(asm) - 3:
        return "P2MS"
    if len(asm) == 3 and asm[0] == opcodes.OP_HASH160 and asm[2] == opcodes.OP_EQUAL:
        return "P2SH"
    if len(asm) == 2 and asm[0] == b"":
        if len(asm[1]) == 32:
            return "P2WSH"
        return "P2WPKH"
    if len(asm) == 2 and asm[0] == b"\x01":
        return "P2TR"
    return "UNKNOWN"


def is_segwit_output(script_pub_key):
    return get_output_type(script_pub_key) in ("P2WPKH", "P2WSH", "P2TR")


def _script_to_address(scriptpubkey, use_legacy=False):
    if isinstance(scriptpubkey, str):
        scriptpubkey = binascii.unhexlify(scriptpubkey)
    try:
        script = (
            bytes(scriptpubkey, "utf-8") if isinstance(scriptpubkey, str) else bytes(scriptpubkey)
        )  # noqa: E721
        if use_legacy:
            return utils.script_to_address_legacy(script, config.NETWORK_NAME)
        return utils.script_to_address(script, config.NETWORK_NAME)
    except BaseException as e:
        raise exceptions.DecodeError("scriptpubkey decoding error") from e


def script_to_address(scriptpubkey):
    return _script_to_address(scriptpubkey, use_legacy=False)


def script_to_address_legacy(scriptpubkey):
    return _script_to_address(scriptpubkey, use_legacy=True)
