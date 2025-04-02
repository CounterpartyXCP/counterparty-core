import binascii
import random

import pytest
from bitcoinutils.script import Script
from bitcoinutils.transactions import Transaction
from counterpartycore.lib import config, exceptions
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


def calculate_reveal_transaction_vsize(data):
    # Calculate the envelope script size
    envelope_script = composer.generate_envelope_script(data)
    envelope_script_serialized = envelope_script.to_hex()
    envelope_script_size = len(envelope_script_serialized) // 2

    # Utility function to calculate varint size
    def varint_size(n):
        if n < 0xFD:
            return 1
        elif n <= 0xFFFF:
            return 3
        elif n <= 0xFFFFFFFF:
            return 5
        else:
            return 9

    # 1. Calculate base size (non-witness data)

    # Transaction header: version(4) + input count(1) + output count(1) + locktime(4)
    tx_header_size = 10

    # Input: txid(32) + vout(4) + script length(1) + empty script(0) + sequence(4)
    tx_input_size = 41

    # Output: amount(8) + script length(1) + OP_RETURN script
    prefix_hex = binascii.hexlify(config.PREFIX).decode("ascii")
    op_return_script_size = 1 + 1 + len(prefix_hex) // 2  # OP_RETURN + data length + data
    tx_output_size = 8 + 1 + op_return_script_size

    # Total base size
    base_size = tx_header_size + tx_input_size + tx_output_size

    # 2. Calculate witness data size

    # Segwit marker and flag (not included in base size for weight calculation)
    segwit_marker_flag_size = 2

    # Witness item count (3 elements: signature, script, control block)
    witness_count_size = 1

    # Signature (estimation for a Schnorr signature in Taproot)
    signature_size = 65
    signature_length_size = varint_size(signature_size)

    # Envelope script
    envelope_script_length_size = varint_size(envelope_script_size)

    # Control block (estimation for a single script path)
    control_block_size = 33  # Leaf version + internal key
    control_block_length_size = varint_size(control_block_size)

    # Total witness size
    witness_size = (
        witness_count_size
        + signature_length_size
        + signature_size
        + envelope_script_length_size
        + envelope_script_size
        + control_block_length_size
        + control_block_size
    )

    # 3. Calculate total size
    total_size = base_size + segwit_marker_flag_size + witness_size

    # 4. Calculate weight: (base size * 3) + total size
    weight = (base_size * 3) + total_size

    # 5. Calculate vsize: (weight + 3) // 4 (integer division to round down)
    vsize = (weight + 3) // 4

    return vsize


def test_get_reveal_transaction_vsize():
    data = b""
    vsize = composer.get_reveal_transaction_vsize(data)
    assert vsize == 97
    assert calculate_reveal_transaction_vsize(data) == 97

    data = b"a"
    vsize = composer.get_reveal_transaction_vsize(data)
    assert vsize == 97
    assert calculate_reveal_transaction_vsize(data) == 98

    data = b"a" * 1000
    vsize = composer.get_reveal_transaction_vsize(data)
    assert vsize == 349
    assert calculate_reveal_transaction_vsize(data) == 349

    data = b"a" * 2000
    vsize = composer.get_reveal_transaction_vsize(data)
    assert vsize == 600
    assert calculate_reveal_transaction_vsize(data) == 601

    data = b"a" * 10000
    vsize = composer.get_reveal_transaction_vsize(data)
    assert vsize == 2612
    assert calculate_reveal_transaction_vsize(data) == 2612

    data = b"a" * 20000
    vsize = composer.get_reveal_transaction_vsize(data)
    assert vsize == 5126
    assert calculate_reveal_transaction_vsize(data) == 5127

    data = b"a" * 400 * 1024
    vsize = composer.get_reveal_transaction_vsize(data)
    assert vsize == 103089
    assert calculate_reveal_transaction_vsize(data) == 103089

    for _i in range(10):
        data = b"a" * random.randint(1, 400000)  # noqa
        vsize = composer.get_reveal_transaction_vsize(data)
        assert (
            calculate_reveal_transaction_vsize(data) - 1
            <= vsize
            <= calculate_reveal_transaction_vsize(data) + 1
        )


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
    assert outputs[0].amount == 330
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
    assert outputs[0].amount == 330
    assert outputs[0].script_pubkey == Script(
        ["OP_1", "a08105b2c25dfe0d5b3ef9471ae2bf886a81206f9e972bc2855d53048ec9a611"]
    )

    outputs = composer.prepare_taproot_output(defaults["p2tr_addresses"][0], b"Hello world", [], {})
    assert len(outputs) == 1
    assert outputs[0].amount == 330
    assert outputs[0].script_pubkey == Script(
        ["OP_1", "dbf963209b9d74c19b2ddadac83fbd16f427f4266369a999feefdc32ab5466f7"]
    )

    outputs = composer.prepare_data_outputs(
        defaults["p2tr_addresses"][0],
        [],
        b"Hello world",
        [
            {
                "txid": "ff" * 32,
            }
        ],
        {"encoding": "taproot"},
    )
    assert len(outputs) == 1
    assert outputs[0].amount == 330
    assert outputs[0].script_pubkey == Script(
        ["OP_1", "dbf963209b9d74c19b2ddadac83fbd16f427f4266369a999feefdc32ab5466f7"]
    )


def test_compose_transaction(ledger_db, defaults):
    params = {
        "memo": "0102030405",
        "memo_is_hex": True,
        "source": defaults["addresses"][0],
        "destination": defaults["addresses"][1],
        "asset": "XCP",
        "quantity": defaults["small"],
    }
    construct_params = {
        "encoding": "taproot",
    }

    result = composer.compose_transaction(ledger_db, "send", params, construct_params)
    assert "envelope_script" in result
    assert "reveal_rawtransaction" in result

    reveal_tx = Transaction.from_raw(result["reveal_rawtransaction"])
    assert len(reveal_tx.inputs) == 1
    assert len(reveal_tx.outputs) == 1
    assert reveal_tx.outputs[0].amount == 0
    assert reveal_tx.outputs[0].script_pubkey == Script(
        ["OP_RETURN", binascii.hexlify(config.PREFIX).decode("ascii")]
    )


def test_check_transaction_sanity(ledger_db, defaults):
    params = {
        "memo": "0102030405",
        "memo_is_hex": True,
        "source": defaults["addresses"][0],
        "destination": defaults["addresses"][1],
        "asset": "XCP",
        "quantity": defaults["small"],
    }
    construct_params = {
        "encoding": "taproot",
        "verbose": True,
    }
    tx_info = (
        defaults["addresses"][0],
        [],
        b"\x02\x01\x01\x04\x80\xf0\xfa\x02\x15\x01\x8dj\xe8\xa3\xb3\x81f1\x18\xb4\xe1\xef\xf4\xcf\xc7\xd0\x95M\xd6\xec\x05\x01\x02\x03\x04\x05",
    )

    result = composer.compose_transaction(ledger_db, "send", params, construct_params)

    result["envelope_script"] = "aaaaaa"

    with pytest.raises(
        exceptions.ComposeError, match="Sanity check error: envelope script does not match the data"
    ):
        composer.check_transaction_sanity(tx_info, result, construct_params)


def test_get_sat_per_vbyte(monkeypatch):
    monkeypatch.setattr(composer, "prepare_fee_parameters", lambda x: (None, None, None))
    sat_per_vbyte = composer.get_sat_per_vbyte({})
    assert sat_per_vbyte == 2

    sat_per_vbyte = composer.get_sat_per_vbyte({"sat_per_vbyte": 10})
    assert sat_per_vbyte == 2

    sat_per_vbyte = composer.get_sat_per_vbyte({"confirmation_target": 10})
    assert sat_per_vbyte == 2
