import binascii
import math

from bitcoinutils.script import Script
from bitcoinutils.transactions import Transaction
from counterpartycore.lib import config
from counterpartycore.lib.api import composer
from counterpartycore.test.fixtures.defaults import DEFAULT_PARAMS as DEFAULTS

PROVIDED_PUBKEYS = ",".join(
    [DEFAULTS["pubkey"][DEFAULTS["addresses"][0]], DEFAULTS["pubkey"][DEFAULTS["addresses"][1]]]
)


def test_generate_raw_reveal_tx():
    raw_tx = composer.generate_raw_reveal_tx("FF" * 32, 0)
    tx = Transaction.from_raw(raw_tx)
    assert len(tx.inputs) == 1
    assert len(tx.outputs) == 1
    assert tx.inputs[0].txid == "ff" * 32
    assert tx.inputs[0].txout_index == 0
    assert tx.outputs[0].amount == 0
    assert tx.outputs[0].script_pubkey == Script(
        ["OP_RETURN", binascii.hexlify(config.PREFIX).decode("ascii")]
    )


def test_generate_envelope_script():
    data = b"Hello, World!"
    envelope_script = composer.generate_envelope_script(data)
    assert envelope_script == Script(
        ["OP_FALSE", "OP_IF", binascii.hexlify(data).decode("ascii"), "OP_ENDIF"]
    )

    data = b"a" * 1000
    envelope_script = composer.generate_envelope_script(data)
    assert envelope_script == Script(
        [
            "OP_FALSE",
            "OP_IF",
            binascii.hexlify(b"a" * 520).decode("ascii"),
            binascii.hexlify(b"a" * 480).decode("ascii"),
            "OP_ENDIF",
        ]
    )

    data = b"a" * 1041
    envelope_script = composer.generate_envelope_script(data)
    assert envelope_script == Script(
        [
            "OP_FALSE",
            "OP_IF",
            binascii.hexlify(b"a" * 520).decode("ascii"),
            binascii.hexlify(b"a" * 520).decode("ascii"),
            binascii.hexlify(b"a").decode("ascii"),
            "OP_ENDIF",
        ]
    )


# TODO: fix it and use it if possible
def calculate_vsize(data_size):
    # Base size of a minimal transaction
    base_size = 97

    # Special case for empty data or a single byte
    if data_size <= 1:
        return base_size

    # Number of chunks of 520 bytes
    chunks = math.ceil(data_size / 520)

    # Base cost per byte (after hex conversion and witness weighting)
    byte_cost = 0.5 / 4  # hex (×2) then witness weight (÷4)

    # Initialization of the total vsize
    vsize = base_size + (data_size * byte_cost)

    # Overhead for each chunk according to Bitcoin's varint encoding rules
    varint_overhead = 0
    for i in range(chunks):
        # Size of this chunk (last chunk may be partial)
        chunk_size = min(520, data_size - i * 520)
        # Size after conversion to hexadecimal
        hex_size = chunk_size * 2

        # Application of varint encoding rules
        if hex_size <= 252:
            # 1 byte for the varint
            varint_overhead += 1 / 4  # witness factor
        elif hex_size <= 65535:
            # 3 bytes for the varint (1 marker + 2 value)
            varint_overhead += 3 / 4
        else:
            # 5 bytes for the varint (1 marker + 4 value)
            varint_overhead += 5 / 4

    vsize += varint_overhead

    return math.ceil(vsize)


def test_get_reveal_transaction_vsize():
    data = b""
    envelope_script = composer.generate_envelope_script(data)
    vsize = composer.get_reveal_transaction_vsize(envelope_script)
    assert vsize == 97

    data = b"a"
    envelope_script = composer.generate_envelope_script(data)
    vsize = composer.get_reveal_transaction_vsize(envelope_script)
    assert vsize == 97

    data = b"a" * 1000
    envelope_script = composer.generate_envelope_script(data)
    vsize = composer.get_reveal_transaction_vsize(envelope_script)
    assert vsize == 349

    data = b"a" * 2000
    envelope_script = composer.generate_envelope_script(data)
    vsize = composer.get_reveal_transaction_vsize(envelope_script)
    assert vsize == 600

    data = b"a" * 10000
    envelope_script = composer.generate_envelope_script(data)
    vsize = composer.get_reveal_transaction_vsize(envelope_script)
    assert vsize == 2612

    data = b"a" * 20000
    envelope_script = composer.generate_envelope_script(data)
    vsize = composer.get_reveal_transaction_vsize(envelope_script)
    assert vsize == 5126

    data = b"a" * 400 * 1024
    envelope_script = composer.generate_envelope_script(data)
    vsize = composer.get_reveal_transaction_vsize(envelope_script)
    assert vsize == 103089


def test_prepare_taproot_output(defaults):
    outputs = composer.prepare_taproot_output(
        defaults["addresses"][0],
        b"Hello world",
        [],
        {
            "multisig_pubkey": DEFAULTS["pubkey"][DEFAULTS["addresses"][0]],
        },
    )
    assert len(outputs) == 1
    assert outputs[0].amount == 200
    assert outputs[0].script_pubkey == Script(
        ["OP_1", "f5f05f105fff2aa11354afd243beeb8a45ce37becc0dd52da01b6612bfb0bc36"]
    )

    outputs = composer.prepare_taproot_output(
        defaults["p2wpkh_addresses"][0],
        b"Hello world",
        [],
        {
            "multisig_pubkey": DEFAULTS["pubkey"][DEFAULTS["p2wpkh_addresses"][0]],
        },
    )
    assert len(outputs) == 1
    assert outputs[0].amount == 200
    assert outputs[0].script_pubkey == Script(
        ["OP_1", "a08105b2c25dfe0d5b3ef9471ae2bf886a81206f9e972bc2855d53048ec9a611"]
    )

    outputs = composer.prepare_taproot_output(defaults["p2tr_addresses"][0], b"Hello world", [], {})
    assert len(outputs) == 1
    assert outputs[0].amount == 200
    assert outputs[0].script_pubkey == Script(
        ["OP_1", "dbf963209b9d74c19b2ddadac83fbd16f427f4266369a999feefdc32ab5466f7"]
    )
