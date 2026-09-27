import binascii
import random

import pytest
from bitcoinutils.keys import P2trAddress, PrivateKey, PublicKey
from bitcoinutils.script import Script
from bitcoinutils.transactions import Transaction, TxOutput
from bitcoinutils.utils import ControlBlock
from counterpartycore.lib import config, exceptions
from counterpartycore.lib.api import composer
from counterpartycore.lib.utils import script as script_utils
from counterpartycore.test.fixtures.defaults import DEFAULT_PARAMS as DEFAULTS

PROVIDED_PUBKEYS = ",".join(
    [DEFAULTS["pubkey"][DEFAULTS["addresses"][0]], DEFAULTS["pubkey"][DEFAULTS["addresses"][1]]]
)


def test_generate_raw_reveal_tx():
    raw_tx = composer.generate_raw_reveal_tx(
        "FF" * 32,
        0,
        [TxOutput(0, Script(["OP_RETURN", binascii.hexlify(config.PREFIX).decode("ascii")]))],
    )
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
    construct_params = {"inscription": True}
    private_key = PrivateKey(secret_exponent=1)
    source_pubkey = private_key.get_public_key()

    data = b"Hello, World!"
    envelope_script = composer.generate_envelope_script(data, source_pubkey, construct_params)
    assert envelope_script == Script(
        [
            "OP_FALSE",
            "OP_IF",
            binascii.hexlify(data).decode("ascii"),
            "OP_ENDIF",
            source_pubkey.to_x_only_hex(),
            "OP_CHECKSIG",
        ]
    )

    data = b"a" * 1000
    envelope_script = composer.generate_envelope_script(data, source_pubkey, construct_params)
    assert envelope_script == Script(
        [
            "OP_FALSE",
            "OP_IF",
            binascii.hexlify(b"a" * 520).decode("ascii"),
            binascii.hexlify(b"a" * 480).decode("ascii"),
            "OP_ENDIF",
            source_pubkey.to_x_only_hex(),
            "OP_CHECKSIG",
        ]
    )

    data = b"a" * 1041
    envelope_script = composer.generate_envelope_script(data, source_pubkey, construct_params)
    assert envelope_script == Script(
        [
            "OP_FALSE",
            "OP_IF",
            binascii.hexlify(b"a" * 520).decode("ascii"),
            binascii.hexlify(b"a" * 520).decode("ascii"),
            binascii.hexlify(b"a").decode("ascii"),
            "OP_ENDIF",
            source_pubkey.to_x_only_hex(),
            "OP_CHECKSIG",
        ]
    )

    data = b"Z\x93\x1b\x00\x00\x18\xc0\xfd\xcd\xeb_\x00\x00\x01\n\x00\x19\x03\xe8\x18d\x1a\x00\x0c5\x00\x1a\x00\r\xbb\xa0\x182\x1a\x00\x0c\xf8P\x1a\x00\x98\x96\x80\xf4\xf4\xf5\xf5`Sune asset super top"
    envelope_script = composer.generate_envelope_script(data, source_pubkey, construct_params)
    assert envelope_script == Script(
        [
            "OP_FALSE",
            "OP_IF",
            "6f7264",
            "07",
            "786370",
            "01",
            "746578742f706c61696e",
            "05",
            "92185a1b000018c0fdcdeb5f0000010a001903e818641a000c35001a000dbba018321a000cf8501a00989680f4f4f5f5",
            "OP_0",
            "756e6520617373657420737570657220746f70",
            "OP_ENDIF",
            source_pubkey.to_x_only_hex(),
            "OP_CHECKSIG",
        ]
    )


SOURCE_PUBKEY = PrivateKey(secret_exponent=1).get_public_key()


def calculate_reveal_transaction_vsize(data):
    construct_params = {"inscription": True}

    # Calculate the envelope script size
    envelope_script = composer.generate_envelope_script(data, SOURCE_PUBKEY, construct_params)
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


def reveal_vsize(data):
    db, source, unspent_list, construct_params = None, None, [], {}
    envelope_script = composer.generate_envelope_script(data, SOURCE_PUBKEY, construct_params)
    outputs = composer.get_reveal_outputs(
        db, source, envelope_script, unspent_list, construct_params
    )
    return composer.get_reveal_transaction_vsize(outputs, envelope_script, SOURCE_PUBKEY)


def test_get_reveal_transaction_vsize():
    # The estimate counts a 65-byte signature (SIGHASH_ALL spelled out), which
    # is what `calculate_reveal_transaction_vsize` models too: the reveal fee is
    # paid out of the commit output and cannot be raised afterwards.
    for data in [
        b"",
        b"a",
        b"a" * 1000,
        b"a" * 2000,
        b"a" * 10000,
        b"a" * 20000,
        b"a" * 400 * 1024,
    ]:
        assert reveal_vsize(data) == calculate_reveal_transaction_vsize(data)

    for _i in range(10):
        data = b"a" * random.randint(1, 400000)  # noqa
        assert reveal_vsize(data) == calculate_reveal_transaction_vsize(data)


def expected_commit_script(pubkey_hex, data=b"Hello world"):
    pubkey = PublicKey.from_hex(pubkey_hex)
    envelope_script = composer.generate_envelope_script(data, pubkey, {})
    assert envelope_script.script[-2] == pubkey.to_x_only_hex()
    return pubkey.get_taproot_address([[envelope_script]]).to_script_pub_key()


def test_prepare_taproot_output(ledger_db, defaults):
    # a legacy source has no business here: the reveal must be signed by a
    # P2WPKH or P2TR source key
    with pytest.raises(exceptions.ComposeError, match="requires a P2WPKH or P2TR source"):
        composer.prepare_taproot_output(
            ledger_db,
            defaults["addresses"][0],
            b"Hello world",
            [],
            {"multisig_pubkey": DEFAULTS["pubkey"][DEFAULTS["addresses"][0]]},
        )

    # P2WPKH source with its key provided: the commit commits to that key
    p2wpkh_pubkey = DEFAULTS["pubkey"][DEFAULTS["p2wpkh_addresses"][0]]
    outputs, (reveal_outputs, envelope_script, source_pubkey) = composer.prepare_taproot_output(
        ledger_db,
        defaults["p2wpkh_addresses"][0],
        b"Hello world",
        [],
        {"multisig_pubkey": p2wpkh_pubkey},
    )
    assert len(outputs) == 1
    assert outputs[0].amount == 330
    assert outputs[0].script_pubkey == expected_commit_script(p2wpkh_pubkey)
    assert source_pubkey.to_hex() == p2wpkh_pubkey
    assert envelope_script.script[-2] == source_pubkey.to_x_only_hex()
    assert len(reveal_outputs) == 1

    # a key that is not the source's is refused rather than silently used
    with pytest.raises(exceptions.ComposeError, match="not a key of the source address"):
        composer.prepare_taproot_output(
            ledger_db,
            defaults["p2wpkh_addresses"][0],
            b"Hello world",
            [],
            {"multisig_pubkey": DEFAULTS["pubkey"][DEFAULTS["addresses"][0]]},
        )

    # P2TR source with its internal key provided
    p2tr_pubkey = DEFAULTS["pubkey"][DEFAULTS["p2tr_addresses"][0]]
    outputs = composer.prepare_taproot_output(
        ledger_db,
        defaults["p2tr_addresses"][0],
        b"Hello world",
        [],
        {"multisig_pubkey": p2tr_pubkey},
    )[0]
    assert outputs[0].amount == 330
    assert outputs[0].script_pubkey == expected_commit_script(p2tr_pubkey)

    # P2TR source without a known key: the output key itself closes the envelope
    output_key = P2trAddress(defaults["p2tr_addresses"][0]).to_witness_program()
    outputs = composer.prepare_taproot_output(
        ledger_db, defaults["p2tr_addresses"][0], b"Hello world", [], {}
    )[0]
    assert outputs[0].amount == 330
    assert outputs[0].script_pubkey == expected_commit_script("02" + output_key)

    outputs = composer.prepare_data_outputs(
        ledger_db,
        defaults["p2tr_addresses"][0],
        [],
        b"Hello world",
        [{"txid": "ff" * 32}],
        {"encoding": "taproot"},
    )[0]
    assert len(outputs) == 1
    assert outputs[0].amount == 330
    assert outputs[0].script_pubkey == expected_commit_script("02" + output_key)


def test_get_reveal_source_pubkey(defaults, monkeypatch):
    p2wpkh_address = defaults["p2wpkh_addresses"][0]
    p2wpkh_pubkey = DEFAULTS["pubkey"][p2wpkh_address]
    p2tr_address = defaults["p2tr_addresses"][0]
    p2tr_pubkey = DEFAULTS["pubkey"][p2tr_address]
    output_key = P2trAddress(p2tr_address).to_witness_program()

    # `multisig_pubkey`, also accepted as an x-only key
    assert (
        composer.get_reveal_source_pubkey(
            p2wpkh_address, [], {"multisig_pubkey": p2wpkh_pubkey}
        ).to_hex()
        == p2wpkh_pubkey
    )
    assert (
        composer.get_reveal_source_pubkey(
            p2tr_address, [], {"multisig_pubkey": p2tr_pubkey}
        ).to_hex()
        == p2tr_pubkey
    )
    assert (
        composer.get_reveal_source_pubkey(
            p2tr_address, [], {"multisig_pubkey": p2tr_pubkey[2:]}
        ).to_x_only_hex()
        == p2tr_pubkey[2:]
    )
    assert (
        composer.get_reveal_source_pubkey(
            p2tr_address, [], {"multisig_pubkey": output_key}
        ).to_x_only_hex()
        == output_key
    )
    with pytest.raises(exceptions.ComposeError, match="Invalid multisig pubkey"):
        composer.get_reveal_source_pubkey(p2wpkh_address, [], {"multisig_pubkey": "zz"})
    with pytest.raises(exceptions.ComposeError, match="not a key of the source address"):
        composer.get_reveal_source_pubkey(p2wpkh_address, [], {"multisig_pubkey": p2tr_pubkey})
    with pytest.raises(exceptions.ComposeError, match="not a key of the source address"):
        composer.get_reveal_source_pubkey(p2tr_address, [], {"multisig_pubkey": p2wpkh_pubkey})

    # a matching entry of `pubkeys` (others are for multisig destinations)
    pubkeys = ",".join([DEFAULTS["pubkey"][defaults["addresses"][0]], p2wpkh_pubkey])
    assert (
        composer.get_reveal_source_pubkey(p2wpkh_address, [], {"pubkeys": pubkeys}).to_hex()
        == p2wpkh_pubkey
    )

    # searched in the source's transactions
    monkeypatch.setattr(composer.backend, "search_pubkey", lambda source, tx_hashes: p2wpkh_pubkey)
    assert (
        composer.get_reveal_source_pubkey(p2wpkh_address, [{"txid": "ff" * 32}], {}).to_hex()
        == p2wpkh_pubkey
    )
    monkeypatch.setattr(composer.backend, "search_pubkey", lambda source, tx_hashes: None)
    with pytest.raises(exceptions.ComposeError, match="Pubkey not found"):
        composer.get_reveal_source_pubkey(p2wpkh_address, [], {})
    # a wrong key found on chain is not trusted either
    monkeypatch.setattr(composer.backend, "search_pubkey", lambda source, tx_hashes: p2tr_pubkey)
    with pytest.raises(exceptions.ComposeError, match="Pubkey not found"):
        composer.get_reveal_source_pubkey(p2wpkh_address, [], {})

    # P2TR fallback: the output key
    assert composer.get_reveal_source_pubkey(p2tr_address, [], {}).to_x_only_hex() == output_key

    # sources without a single key
    with pytest.raises(exceptions.ComposeError, match="requires a P2WPKH or P2TR source"):
        composer.get_reveal_source_pubkey(defaults["addresses"][0], [], {})
    with pytest.raises(exceptions.ComposeError, match="requires a P2WPKH or P2TR source"):
        composer.get_reveal_source_pubkey(defaults["p2sh_addresses"][0], [], {})


def test_xonly_matches_script_pub_key(defaults):
    p2wpkh_address = defaults["p2wpkh_addresses"][0]
    p2wpkh_pubkey = DEFAULTS["pubkey"][p2wpkh_address]
    p2tr_address = defaults["p2tr_addresses"][0]
    p2tr_pubkey = DEFAULTS["pubkey"][p2tr_address]
    p2wpkh_script = composer.address_to_script_pub_key(p2wpkh_address).to_hex()
    p2tr_script = composer.address_to_script_pub_key(p2tr_address).to_hex()
    output_key = P2trAddress(p2tr_address).to_witness_program()

    assert composer.xonly_matches_script_pub_key(p2wpkh_pubkey[2:], p2wpkh_script)
    assert not composer.xonly_matches_script_pub_key(p2tr_pubkey[2:], p2wpkh_script)
    assert composer.xonly_matches_script_pub_key(p2tr_pubkey[2:], p2tr_script)
    assert composer.xonly_matches_script_pub_key(output_key, p2tr_script)
    assert not composer.xonly_matches_script_pub_key(p2wpkh_pubkey[2:], p2tr_script)
    legacy_script = composer.address_to_script_pub_key(defaults["addresses"][0]).to_hex()
    assert not composer.xonly_matches_script_pub_key(
        DEFAULTS["pubkey"][defaults["addresses"][0]][2:], legacy_script
    )


def test_compose_transaction(ledger_db, defaults):
    params = {
        "memo": "0102030405",
        "memo_is_hex": True,
        "source": defaults["p2wpkh_addresses"][0],
        "destination": defaults["addresses"][1],
        "asset": "XCP",
        "quantity": defaults["small"],
    }
    construct_params = {
        "encoding": "taproot",
    }

    result = composer.compose_transaction(ledger_db, "send", params, construct_params)
    assert "signed_reveal_rawtransaction" not in result
    for key in composer.REVEAL_RESULT_KEYS:
        assert key in result

    source_pubkey = DEFAULTS["pubkey"][defaults["p2wpkh_addresses"][0]]
    assert result["reveal_pubkey"] == source_pubkey[2:]
    envelope_script = Script.from_raw(result["envelope_script"])
    assert envelope_script.script[-2:] == [source_pubkey[2:], "OP_CHECKSIG"]

    # the reveal is unsigned and spends the commit's first output, a P2TR
    # output committing to the envelope under the source key
    commit_tx = Transaction.from_raw(result["rawtransaction"])
    reveal_tx = Transaction.from_raw(result["reveal_rawtransaction"])
    assert len(reveal_tx.inputs) == 1
    assert reveal_tx.inputs[0].txid == commit_tx.get_txid()
    assert reveal_tx.inputs[0].txout_index == 0
    assert reveal_tx.witnesses == []
    assert len(reveal_tx.outputs) == 1
    assert reveal_tx.outputs[0].amount == 0
    assert reveal_tx.outputs[0].script_pubkey == Script(
        ["OP_RETURN", binascii.hexlify(config.PREFIX).decode("ascii")]
    )
    commit_address = PublicKey.from_hex(source_pubkey).get_taproot_address([[envelope_script]])
    assert commit_tx.outputs[0].script_pubkey == commit_address.to_script_pub_key()
    assert result["reveal_lock_scripts"] == [commit_address.to_script_pub_key().to_hex()]
    assert result["reveal_inputs_values"] == [commit_tx.outputs[0].amount]
    control_block = ControlBlock(
        PublicKey.from_hex(source_pubkey),
        scripts=[envelope_script],
        index=0,
        is_odd=commit_address.is_odd(),
    )
    assert result["reveal_control_block"] == control_block.to_hex()

    # the wallet can sign it with the source key and the node accepts it
    private_key = PrivateKey(
        secret_exponent=int(DEFAULTS["privkey"][defaults["p2wpkh_addresses"][0]], 16)
    )
    assert private_key.get_public_key().to_hex() == source_pubkey
    reveal_tx.has_segwit = True
    sig = private_key.sign_taproot_input(
        reveal_tx,
        0,
        [commit_tx.outputs[0].script_pubkey],
        [commit_tx.outputs[0].amount],
        script_path=True,
        tapleaf_script=envelope_script,
        tweak=False,
    )
    witness = [sig, result["envelope_script"], result["reveal_control_block"]]
    assert (
        script_utils.reveal_source_signature_error(
            result["reveal_lock_scripts"][0],
            composer.address_to_script_pub_key(defaults["p2wpkh_addresses"][0]).to_hex(),
            witness,
        )
        is None
    )


def test_check_transaction_sanity(ledger_db, defaults):
    params = {
        "memo": "0102030405",
        "memo_is_hex": True,
        "source": defaults["p2wpkh_addresses"][0],
        "destination": defaults["addresses"][1],
        "asset": "XCP",
        "quantity": defaults["small"],
    }
    construct_params = {
        "encoding": "taproot",
        "verbose": True,
    }
    result = composer.compose_transaction(ledger_db, "send", params, construct_params)
    tx_info = (
        defaults["p2wpkh_addresses"][0],
        [],
        result["data"][len(config.PREFIX) :],
    )
    composer.check_transaction_sanity(tx_info, result, [], construct_params)

    # garbage in place of the envelope
    tampered = result | {"envelope_script": "aaaaaa"}
    with pytest.raises(
        exceptions.ComposeError, match="Sanity check error: envelope script does not match the data"
    ):
        composer.check_transaction_sanity(tx_info, tampered, [], construct_params)

    # an envelope closed by a key that is not the source's: the sweep-by-payment
    # attack seen from the composer's side
    other_pubkey = PublicKey.from_hex(DEFAULTS["pubkey"][defaults["addresses"][0]])
    other_envelope = composer.generate_envelope_script(tx_info[2], other_pubkey, construct_params)
    tampered = result | {"envelope_script": other_envelope.to_hex()}
    with pytest.raises(exceptions.ComposeError, match="envelope key does not belong to the source"):
        composer.check_transaction_sanity(tx_info, tampered, [], construct_params)

    # the right key around different data
    source_pubkey = PublicKey.from_hex(DEFAULTS["pubkey"][defaults["p2wpkh_addresses"][0]])
    other_data_envelope = composer.generate_envelope_script(
        b"other data", source_pubkey, construct_params
    )
    tampered = result | {"envelope_script": other_data_envelope.to_hex()}
    with pytest.raises(exceptions.ComposeError, match="envelope script does not match the data"):
        composer.check_transaction_sanity(tx_info, tampered, [], construct_params)

    # a reveal that does not spend the commit
    reveal_tx = Transaction.from_raw(result["reveal_rawtransaction"])
    reveal_tx.inputs[0].txout_index = 1
    tampered = result | {"reveal_rawtransaction": reveal_tx.serialize()}
    with pytest.raises(
        exceptions.ComposeError, match="reveal transaction does not spend the commit output"
    ):
        composer.check_transaction_sanity(tx_info, tampered, [], construct_params)


def test_get_sat_per_vbyte(monkeypatch):
    monkeypatch.setattr(composer, "prepare_fee_parameters", lambda x: (None, None, None))
    sat_per_vbyte = composer.get_sat_per_vbyte({})
    assert sat_per_vbyte == 2

    sat_per_vbyte = composer.get_sat_per_vbyte({"sat_per_vbyte": 10})
    assert sat_per_vbyte == 2

    sat_per_vbyte = composer.get_sat_per_vbyte({"confirmation_target": 10})
    assert sat_per_vbyte == 2
