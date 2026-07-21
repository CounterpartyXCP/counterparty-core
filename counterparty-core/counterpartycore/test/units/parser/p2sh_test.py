import binascii
import struct

import bitcoin as bitcoinlib
import pytest
from counterpartycore.lib import config, exceptions
from counterpartycore.lib.parser import deserialize, p2sh
from counterpartycore.lib.utils import script


def test_p2sh_signed_multisig_script_decoding():
    txHex = "0100000001bae95e59f83e55035f566dc0e3034f79f0d670dc6d6a0d207a11b4e49e9baecf00000000fd0301483045022100d2d38c2d98285e44a271e91894622fa85044469257dbfc15a49e1ba98cddaf8002202b06bf0ca9d65af9f9c96db13c7585b4cd66cabedba269f9b70659dd8e456c46014cb84c8d434e5452505254591e5a3ae08000000000000000000000000073434950203620737570706f727473207573696e672070327368206164647265737365732061732074686520736f7572636520616464726573732062757420726571756972657320616e206164646974696f6e616c20696e70757420696e207468652064617461207472616e73616374696f6e2e752102e53b79237cacdc221cff4c0fb320223cac3e0fe30a682a22f19a70a3975aa3f8ad0075740087ffffffff0100000000000000000e6a0c804e42751677319b884a2d1b00000000"

    ctx = deserialize.deserialize_tx(txHex, parse_vouts=True)
    vin = ctx["vin"][0]
    asm = script.script_to_asm(vin["script_sig"])
    new_source, new_destination, new_data = p2sh.decode_p2sh_input(asm)

    assert new_data == binascii.unhexlify(
        "1e5a3ae08000000000000000000000000073434950203620737570706f727473207573696e672070327368206164647265737365732061732074686520736f7572636520616464726573732062757420726571756972657320616e206164646974696f6e616c20696e70757420696e207468652064617461207472616e73616374696f6e2e"
    )


# Test pubkey_to_p2whash function (lines 38-40)
def test_pubkey_to_p2whash():
    # Use a valid 33-byte compressed public key
    pubkey = bytes.fromhex("02e53b79237cacdc221cff4c0fb320223cac3e0fe30a682a22f19a70a3975aa3f8")
    result = p2sh.pubkey_to_p2whash(pubkey)
    # Result should be a bech32 address starting with bcrt1 for regtest
    assert result.startswith("bcrt1")


# Test decode_data_push with OP_PUSHDATA2 (lines 52-54)
def test_decode_data_push_pushdata2():
    # Create data with OP_PUSHDATA2 (0x4d) followed by 2-byte little-endian length
    data_len = 256  # Requires PUSHDATA2
    data = b"A" * data_len
    arr = bytes([bitcoinlib.core.script.OP_PUSHDATA2]) + struct.pack("<H", data_len) + data
    pos, result = p2sh.decode_data_push(arr, 0)
    assert result == data
    assert pos == 3 + data_len


# Test decode_data_push with OP_PUSHDATA4 (lines 55-57)
def test_decode_data_push_pushdata4():
    # Create data with OP_PUSHDATA4 (0x4e) followed by 4-byte little-endian length
    data_len = 100
    data = b"B" * data_len
    arr = bytes([bitcoinlib.core.script.OP_PUSHDATA4]) + struct.pack("<L", data_len) + data
    pos, result = p2sh.decode_data_push(arr, 0)
    assert result == data
    assert pos == 5 + data_len


# Test decode_data_redeem_script with script_len == 41 branch (lines 76-81)
def test_decode_data_redeem_script_41_bytes_p2pkh():
    # Build a 41-byte redeem script matching the pattern:
    # OP_DROP [push 33] [33-byte pubkey] OP_CHECKSIGVERIFY [n] OP_DROP OP_DEPTH 0 OP_EQUAL
    pubkey = bytes.fromhex("02e53b79237cacdc221cff4c0fb320223cac3e0fe30a682a22f19a70a3975aa3f8")
    redeem_script = (
        bytes(
            [
                bitcoinlib.core.script.OP_DROP,  # 0
                33,  # push 33 bytes (1)
            ]
        )
        + pubkey
        + bytes(
            [  # 2-34
                bitcoinlib.core.script.OP_CHECKSIGVERIFY,  # 35
                1,  # n value (36)
                bitcoinlib.core.script.OP_DROP,  # 37
                bitcoinlib.core.script.OP_DEPTH,  # 38
                bitcoinlib.core.script.OP_0,  # 39
                bitcoinlib.core.script.OP_EQUAL,  # 40
            ]
        )
    )
    assert len(redeem_script) == 41

    pubkey_out, source, is_valid, found_data = p2sh.decode_data_redeem_script(redeem_script)
    assert is_valid is True
    assert pubkey_out == pubkey
    assert source is not None
    assert found_data == b""


# Test decode_data_redeem_script with script_len == 41 and p2sh_is_segwit=True (lines 77-78)
def test_decode_data_redeem_script_41_bytes_segwit():
    pubkey = bytes.fromhex("02e53b79237cacdc221cff4c0fb320223cac3e0fe30a682a22f19a70a3975aa3f8")
    redeem_script = (
        bytes(
            [
                bitcoinlib.core.script.OP_DROP,
                33,
            ]
        )
        + pubkey
        + bytes(
            [
                bitcoinlib.core.script.OP_CHECKSIGVERIFY,
                1,
                bitcoinlib.core.script.OP_DROP,
                bitcoinlib.core.script.OP_DEPTH,
                bitcoinlib.core.script.OP_0,
                bitcoinlib.core.script.OP_EQUAL,
            ]
        )
    )

    pubkey_out, source, is_valid, found_data = p2sh.decode_data_redeem_script(
        redeem_script, p2sh_is_segwit=True
    )
    assert is_valid is True
    assert source.startswith("bcrt1")  # bech32 address


# Test decode_data_redeem_script with script_len > 41 multisig branch (lines 91-93)
def test_decode_data_redeem_script_multisig_branch():
    # Build a script > 41 bytes with the multisig pattern:
    # OP_DROP {arbitrary multisig script} [n] OP_DROP OP_DEPTH 0 OP_EQUAL
    multisig_script = b"A" * 50  # Arbitrary content
    redeem_script = (
        bytes(
            [
                bitcoinlib.core.script.OP_DROP,
            ]
        )
        + multisig_script
        + bytes(
            [
                1,  # n value
                bitcoinlib.core.script.OP_DROP,
                bitcoinlib.core.script.OP_DEPTH,
                bitcoinlib.core.script.OP_0,
                bitcoinlib.core.script.OP_EQUAL,
            ]
        )
    )

    pubkey_out, source, is_valid, found_data = p2sh.decode_data_redeem_script(redeem_script)
    assert is_valid is True
    assert pubkey_out is None
    assert source is None


# Test decode_data_redeem_script with multisig processing (lines 120-131)
def test_decode_data_redeem_script_multisig_processing():
    # Build a proper multisig redeem script:
    # [data push] OP_DROP OP_2 [pubkey1] [pubkey2] OP_2 OP_CHECKMULTISIGVERIFY [n] OP_DROP OP_DEPTH 0 OP_EQUAL
    data_chunk = config.PREFIX + b"test_data"
    pubkey1 = bytes.fromhex("02e53b79237cacdc221cff4c0fb320223cac3e0fe30a682a22f19a70a3975aa3f8")
    pubkey2 = bytes.fromhex("0317b2c8f82ee9bb26f8da5e53b1e7bfafa7bf5e4e0b7b0f0e29bb28c0f6c3d8a1")

    redeem_script = (
        bytes(
            [
                len(data_chunk),  # data push
            ]
        )
        + data_chunk
        + bytes(
            [
                bitcoinlib.core.script.OP_DROP,
                bitcoinlib.core.script.OP_2,  # 2-of-2 multisig
                33,  # push 33 bytes
            ]
        )
        + pubkey1
        + bytes(
            [
                33,  # push 33 bytes
            ]
        )
        + pubkey2
        + bytes(
            [
                bitcoinlib.core.script.OP_2,  # 2 pubkeys
                bitcoinlib.core.script.OP_CHECKMULTISIGVERIFY,
                1,  # unique offset
                bitcoinlib.core.script.OP_DROP,
                bitcoinlib.core.script.OP_DEPTH,
                0,
                bitcoinlib.core.script.OP_EQUAL,
            ]
        )
    )

    pubkey_out, source, is_valid, found_data = p2sh.decode_data_redeem_script(redeem_script)
    assert is_valid is True
    assert pubkey_out is None  # multisig has no single pubkey
    assert found_data == data_chunk


# Test decode_data_redeem_script with p2pkh and p2sh_is_segwit=True (line 139)
def test_decode_data_redeem_script_p2pkh_segwit():
    # Build a p2pkh redeem script with segwit:
    # [data push] OP_DROP [pubkey push] OP_CHECKSIGVERIFY [n] OP_DROP OP_DEPTH 0 OP_EQUAL
    data_chunk = config.PREFIX + b"segwit_test"
    pubkey = bytes.fromhex("02e53b79237cacdc221cff4c0fb320223cac3e0fe30a682a22f19a70a3975aa3f8")

    redeem_script = (
        bytes(
            [
                len(data_chunk),
            ]
        )
        + data_chunk
        + bytes(
            [
                bitcoinlib.core.script.OP_DROP,
                33,
            ]
        )
        + pubkey
        + bytes(
            [
                bitcoinlib.core.script.OP_CHECKSIGVERIFY,
                1,  # unique offset
                bitcoinlib.core.script.OP_DROP,
                bitcoinlib.core.script.OP_DEPTH,
                0,
                bitcoinlib.core.script.OP_EQUAL,
            ]
        )
    )

    pubkey_out, source, is_valid, found_data = p2sh.decode_data_redeem_script(
        redeem_script, p2sh_is_segwit=True
    )
    assert is_valid is True
    assert source.startswith("bcrt1")  # bech32 address for segwit


# Test decode_data_redeem_script exception handling (lines 165-166)
def test_decode_data_redeem_script_exception():
    # Pass invalid/malformed redeem script that will cause an exception
    # during parsing (e.g., index out of bounds)
    malformed_script = bytes(
        [
            10,  # Push 10 bytes but don't provide them
        ]
    )

    pubkey_out, source, is_valid, found_data = p2sh.decode_data_redeem_script(malformed_script)
    assert pubkey_out is None
    assert source is None
    assert is_valid is False
    assert found_data is None


# Note: Lines 188-189 (unsigned transaction path) appear to be unreachable dead code.
# The logic at lines 175-186 first decodes asm[-1], and if invalid, decodes asm[-1] again.
# Since both decode calls use the same input, if the first returns False, the second will too.
# This means line 189 can never be reached. The test below documents this behavior.
def test_decode_p2sh_input_unsigned_transaction_path_unreachable():
    # This test documents that the "unsigned transaction" path (line 189) is unreachable.
    # Both decode_data_redeem_script calls at lines 175 and 182 decode asm[-1].
    # If the first returns redeem_script_is_valid=False, the second will too,
    # causing the function to return None at line 186.
    # If the first returns True, we never enter the else branch at line 181.
    invalid_script = b"invalid"
    asm = [b"data", b"redeem", invalid_script]

    # With invalid asm[-1], both decodes return False, hitting line 186
    source, destination, data = p2sh.decode_p2sh_input(asm)
    assert source is None
    assert destination is None
    assert data is None


# Test decode_p2sh_input with empty data (lines 195-196)
def test_decode_p2sh_input_empty_data():
    # Create a redeem script that will return empty data
    pubkey = bytes.fromhex("02e53b79237cacdc221cff4c0fb320223cac3e0fe30a682a22f19a70a3975aa3f8")
    redeem_script = (
        bytes(
            [
                bitcoinlib.core.script.OP_DROP,
                33,
            ]
        )
        + pubkey
        + bytes(
            [
                bitcoinlib.core.script.OP_CHECKSIGVERIFY,
                1,
                bitcoinlib.core.script.OP_DROP,
                bitcoinlib.core.script.OP_DEPTH,
                bitcoinlib.core.script.OP_0,
                bitcoinlib.core.script.OP_EQUAL,
            ]
        )
    )

    # Pass empty datachunk as signature
    asm = [b"", redeem_script]
    source, destination, data = p2sh.decode_p2sh_input(asm)
    assert source is not None
    assert data is None


# Test decode_p2sh_input with unrecognized prefix (line 197)
def test_decode_p2sh_input_unrecognized_prefix():
    # To trigger line 197, we need:
    # 1. A valid redeem script (so redeem_script_is_valid=True at line 178)
    # 2. found_data to be non-empty and NOT start with PREFIX
    # The found_data comes from decode_data_redeem_script's else branch (line 94+)
    # where it extracts data from a data push operation

    # Create a redeem script that will:
    # - NOT match the 41-byte pattern (lines 66-74)
    # - NOT match the >41 multisig pattern (lines 82-89)
    # - Go through the else branch (line 94+) and extract found_data
    # - Be valid (redeem_script_is_valid=True)

    invalid_data = b"invalid_no_prefix"  # Does not start with PREFIX
    pubkey = bytes.fromhex("02e53b79237cacdc221cff4c0fb320223cac3e0fe30a682a22f19a70a3975aa3f8")

    # Build a p2pkh redeem script:
    # [data push] OP_DROP [pubkey push] OP_CHECKSIGVERIFY [n] OP_DROP OP_DEPTH 0 OP_EQUAL
    redeem_script = (
        bytes(
            [
                len(invalid_data),
            ]
        )
        + invalid_data
        + bytes(
            [
                bitcoinlib.core.script.OP_DROP,
                33,
            ]
        )
        + pubkey
        + bytes(
            [
                bitcoinlib.core.script.OP_CHECKSIGVERIFY,
                1,  # unique offset
                bitcoinlib.core.script.OP_DROP,
                bitcoinlib.core.script.OP_DEPTH,
                0,
                bitcoinlib.core.script.OP_EQUAL,
            ]
        )
    )

    # asm[-1] is the redeem_script, which will be decoded
    # found_data will be invalid_data (no PREFIX)
    asm = [b"signature_placeholder", redeem_script]
    with pytest.raises(exceptions.DecodeError, match="unrecognised P2SH output"):
        p2sh.decode_p2sh_input(asm)


# Test decode_p2sh_input returns None when redeem_script is invalid and len != 3
def test_decode_p2sh_input_invalid_redeem_script():
    # Invalid redeem script with wrong length asm
    invalid_redeem_script = b"invalid"
    asm = [b"data", invalid_redeem_script]  # Only 2 elements, not 3

    source, destination, data = p2sh.decode_p2sh_input(asm)
    assert source is None
    assert destination is None
    assert data is None
