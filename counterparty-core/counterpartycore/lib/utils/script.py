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


# Byte values from rust-bitcoin's `blockdata::opcodes::all`.
_OP_PUSHBYTES_2 = 0x02
_OP_PUSHBYTES_40 = 0x28
_OP_PUSHNUM_1 = 0x51
_OP_PUSHNUM_16 = 0x60


def is_witness_program(script_pub_key):
    """Whether `script_pub_key` is a witness program, deciding it exactly as the
    Rust fetcher does.

    `is_segwit_output()` answers a subtly different question, and answers it by
    disassembling the script: it therefore raises `DecodeError` for anything
    `script_to_asm()` cannot parse -- an empty scriptPubKey most obviously,
    where `asm[-1]` is an `IndexError` -- and it reports witness versions 2-16
    as "UNKNOWN". The Rust side
    (`output.script_pubkey.is_witness_program()` in
    `indexer/bitcoin_client.rs`, i.e. rust-bitcoin's `Script::witness_version`)
    never throws and never disassembles: it is a pure byte-shape test.

    Both compute the same `is_segwit` flag for the same input, so they have to
    agree -- see `bitcoind.get_vin_info_legacy()`, which is the Python fallback
    taken exactly when the deserializer could not resolve the prevout itself. A
    node on the fallback must stay byte-identical to one that was not. Kept
    separate from `is_segwit_output()`, which keeps its own semantics for the
    composer (off the consensus path).
    """
    if isinstance(script_pub_key, str):
        try:
            script_pub_key = binascii.unhexlify(script_pub_key)
        except binascii.Error:
            return False
    if not 4 <= len(script_pub_key) <= 42:
        return False
    push_opbyte = script_pub_key[1]
    if push_opbyte < _OP_PUSHBYTES_2 or push_opbyte > _OP_PUSHBYTES_40:
        return False
    # The push must cover exactly the rest of the script.
    if len(script_pub_key) - 2 != push_opbyte:
        return False
    version_opbyte = script_pub_key[0]
    return version_opbyte == 0 or _OP_PUSHNUM_1 <= version_opbyte <= _OP_PUSHNUM_16


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
