"""
This module contains p2sh data encoding functions
"""

import binascii
import hashlib
import logging
import struct

import bitcoin as bitcoinlib
from bitcoin.bech32 import CBech32Data
from ripemd import ripemd160 as RIPEMD160  # nosec B413

from counterpartycore.lib import config, exceptions
from counterpartycore.lib.utils import base58

logger = logging.getLogger(config.LOGGER_NAME)


def hash160(x):
    x = hashlib.sha256(x).digest()
    m = RIPEMD160.new()
    m.update(x)
    return m.digest()


def pubkey_to_pubkeyhash(pubkey):
    """Convert public key to PubKeyHash."""
    pubkeyhash = hash160(pubkey)
    pubkey = base58.base58_check_encode(
        binascii.hexlify(pubkeyhash).decode("utf-8"), config.ADDRESSVERSION
    )
    return pubkey


def pubkey_to_p2whash(pubkey):
    """Convert public key to PayToWitness."""
    pubkeyhash = hash160(pubkey)
    pubkey = CBech32Data.from_bytes(0, pubkeyhash)
    return str(pubkey)


def decode_data_push(arr, pos):
    pushlen = 0
    data = b""  # noqa: F841
    opcode = bitcoinlib.core.script.CScriptOp(arr[pos])
    if opcode > 0 and opcode < bitcoinlib.core.script.OP_PUSHDATA1:
        pushlen = arr[pos]
        pos += 1
    elif opcode == bitcoinlib.core.script.OP_PUSHDATA1:
        pushlen = arr[pos + 1]
        pos += 2
    elif opcode == bitcoinlib.core.script.OP_PUSHDATA2:
        (pushlen,) = struct.unpack("<H", arr[pos + 1 : pos + 3])
        pos += 3
    elif opcode == bitcoinlib.core.script.OP_PUSHDATA4:
        (pushlen,) = struct.unpack("<L", arr[pos + 1 : pos + 5])
        pos += 5

    return pos + pushlen, arr[pos : pos + pushlen]


def decode_data_redeem_script(redeem_script, p2sh_is_segwit=False):
    script_len = len(redeem_script)
    found_data = b""

    if (
        script_len == 41
        and redeem_script[0] == bitcoinlib.core.script.OP_DROP
        and redeem_script[35] == bitcoinlib.core.script.OP_CHECKSIGVERIFY
        and redeem_script[37] == bitcoinlib.core.script.OP_DROP
        and redeem_script[38] == bitcoinlib.core.script.OP_DEPTH
        and redeem_script[39] == bitcoinlib.core.script.OP_0
        and redeem_script[40] == bitcoinlib.core.script.OP_EQUAL
    ):
        # - OP_DROP [push] [33-byte pubkey] OP_CHECKSIGVERIFY [n] OP_DROP OP_DEPTH 0 OP_EQUAL
        pubkey = redeem_script[2:35]
        if p2sh_is_segwit:
            source = pubkey_to_p2whash(pubkey)
        else:
            source = pubkey_to_pubkeyhash(pubkey)
        redeem_script_is_valid = True
    elif (
        script_len > 41
        and redeem_script[0] == bitcoinlib.core.script.OP_DROP
        and redeem_script[script_len - 4] == bitcoinlib.core.script.OP_DROP
        and redeem_script[script_len - 3] == bitcoinlib.core.script.OP_DEPTH
        and redeem_script[script_len - 2] == bitcoinlib.core.script.OP_0
        and redeem_script[script_len - 1] == bitcoinlib.core.script.OP_EQUAL
    ):
        # - OP_DROP {arbitrary multisig script} [n] OP_DROP OP_DEPTH 0 OP_EQUAL
        pubkey = None
        source = None
        redeem_script_is_valid = True
    else:
        pubkey = None
        source = None
        redeem_script_is_valid = False

        try:
            opcode = bitcoinlib.core.script.CScriptOp(redeem_script[0])
            if (
                opcode > bitcoinlib.core.script.OP_0
                and opcode < bitcoinlib.core.script.OP_PUSHDATA1
                or opcode
                in (
                    bitcoinlib.core.script.OP_PUSHDATA1,
                    bitcoinlib.core.script.OP_PUSHDATA2,
                    bitcoinlib.core.script.OP_PUSHDATA4,
                )
            ):
                pos = 0
                pos, found_data = decode_data_push(redeem_script, 0)

                if redeem_script[pos] == bitcoinlib.core.script.OP_DROP:
                    pos += 1
                    valid_sig = False
                    opcode = redeem_script[pos]
                    if type(opcode) != type(""):  # noqa: E721
                        if (
                            opcode >= bitcoinlib.core.script.OP_2
                            and opcode <= bitcoinlib.core.script.OP_15
                        ):
                            # it's multisig
                            req_sigs = opcode - bitcoinlib.core.script.OP_1 + 1  # noqa: F841
                            pos += 1
                            pubkey = None
                            num_sigs = 0
                            found_sigs = False
                            while not found_sigs:
                                pos, npubkey = decode_data_push(redeem_script, pos)
                                num_sigs += 1
                                if redeem_script[pos] - bitcoinlib.core.script.OP_1 + 1 == num_sigs:
                                    found_sigs = True

                            pos += 1
                            valid_sig = (
                                redeem_script[pos] == bitcoinlib.core.script.OP_CHECKMULTISIGVERIFY
                            )
                        else:
                            # it's p2pkh
                            pos, pubkey = decode_data_push(redeem_script, pos)

                            if p2sh_is_segwit:
                                source = pubkey_to_p2whash(pubkey)
                            else:
                                source = pubkey_to_pubkeyhash(pubkey)

                            valid_sig = (
                                redeem_script[pos] == bitcoinlib.core.script.OP_CHECKSIGVERIFY
                            )
                        pos += 1

                        if valid_sig:
                            unique_offfset_length = 0

                            for i in range(pos + 1, len(redeem_script)):
                                if redeem_script[i] == bitcoinlib.core.script.OP_DROP:
                                    unique_offfset_length = i - pos - 1
                                    break

                            redeem_script_is_valid = (
                                redeem_script[pos + 1 + unique_offfset_length]
                                == bitcoinlib.core.script.OP_DROP
                                and redeem_script[pos + 2 + unique_offfset_length]
                                == bitcoinlib.core.script.OP_DEPTH
                                and redeem_script[pos + 3 + unique_offfset_length] == 0
                                and redeem_script[pos + 4 + unique_offfset_length]
                                == bitcoinlib.core.script.OP_EQUAL
                            )
        except Exception as e:  # pylint: disable=broad-except  # noqa: F841
            return None, None, False, None

    return pubkey, source, redeem_script_is_valid, found_data


def decode_p2sh_input(asm, p2sh_is_segwit=False):
    """Looks at the scriptSig for the input of the p2sh-encoded data transaction
    [signature] [data] [OP_HASH160 ... OP_EQUAL]
    """
    pubkey, source, redeem_script_is_valid, found_data = decode_data_redeem_script(
        asm[-1], p2sh_is_segwit
    )
    if redeem_script_is_valid:
        # this is a signed transaction, so we got {sig[,sig]} {datachunk} {redeem_script}
        datachunk = found_data
        redeem_script = asm[-1]  # asm[-2:]
    else:
        pubkey, source, redeem_script_is_valid, found_data = decode_data_redeem_script(
            asm[-1], p2sh_is_segwit
        )
        if not redeem_script_is_valid or len(asm) != 3:
            return None, None, None

        # this is an unsigned transaction (last is outputScript), so we got [datachunk] [redeem_script] [temporaryOutputScript]
        datachunk, redeem_script, _substitute_script = asm

    data = datachunk
    if data[: len(config.PREFIX)] == config.PREFIX:
        data = data[len(config.PREFIX) :]
    else:
        if data == b"":
            return source, None, None
        raise exceptions.DecodeError("unrecognised P2SH output")

    return source, None, data
