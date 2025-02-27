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


def script_to_address(scriptpubkey):
    if isinstance(scriptpubkey, str):
        scriptpubkey = binascii.unhexlify(scriptpubkey)
    try:
        script = (
            bytes(scriptpubkey, "utf-8") if isinstance(scriptpubkey, str) else bytes(scriptpubkey)
        )  # noqa: E721
        return utils.script_to_address(script, config.NETWORK_NAME)
    except BaseException as e:
        raise exceptions.DecodeError("scriptpubkey decoding error") from e


def script_to_address2(scriptpubkey):
    if isinstance(scriptpubkey, str):
        scriptpubkey = binascii.unhexlify(scriptpubkey)
    try:
        script = (
            bytes(scriptpubkey, "utf-8") if isinstance(scriptpubkey, str) else bytes(scriptpubkey)
        )  # noqa: E721
        return utils.script_to_address2(script, config.NETWORK_NAME)
    except BaseException as e:  # noqa: F841
        raise exceptions.DecodeError("scriptpubkey decoding error") from e
