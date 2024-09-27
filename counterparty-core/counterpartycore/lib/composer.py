import binascii

from bitcoin.core.script import (
    OP_CHECKMULTISIG,
    OP_RETURN,
    CScript,
    CTransaction,
    CTxIn,
    CTxOut,
)
from bitcoin.wallet import CBitcoinAddress, P2WPKHBitcoinAddress

from counterpartycore.lib import arc4, backend, config, exceptions, script, transaction, util
from counterpartycore.lib.transaction_helper.common_serializer import make_fully_valid
from counterpartycore.lib.transaction_helper.transaction_outputs import chunks

MAX_INPUTS_SET = 100


def get_script(address):
    if script.is_multisig(address):
        signatures_required, pubkeys, signatures_possible = script.extract_array(address)
        return CScript([signatures_required] + pubkeys + [signatures_possible, OP_CHECKMULTISIG])
    elif script.is_bech32(address):
        return P2WPKHBitcoinAddress(address).to_scriptPubKey()
    else:
        return CBitcoinAddress(address).to_scriptPubKey()


def get_default_value(address):
    if script.is_multisig(address):
        return config.MULTISIG_DUST_SIZE
    else:
        return config.REGULAR_DUST_SIZE


def perpare_non_data_outputs(destinations):
    outputs = []
    for address, value in destinations:
        output_value = value or get_default_value(address)
        outputs.append(CTxOut(output_value, get_script(address)))
    return outputs


def determine_encoding(data, desired_encoding="auto"):
    encoding = desired_encoding
    if desired_encoding == "auto":
        if len(data) + len(config.PREFIX) <= config.OP_RETURN_MAX_SIZE:
            encoding = "opreturn"
        else:
            encoding = "multisig"
    if encoding not in ("multisig", "opreturn"):
        raise exceptions.TransactionError(f"Not supported encoding: {encoding}")
    return encoding


def encrypt_data(data, arc4_key):
    key = arc4.init_arc4(binascii.unhexlify(arc4_key))
    return key.encrypt(data)


def prepare_opreturn_output(data, arc4_key=None):
    if len(data) + len(config.PREFIX) > config.OP_RETURN_MAX_SIZE:
        raise exceptions.TransactionError("One `OP_RETURN` output per transaction.")
    opreturn_data = config.PREFIX + data
    if arc4_key:
        opreturn_data = encrypt_data.encrypt(opreturn_data, arc4_key)
    return [CTxOut(0, CScript([OP_RETURN, opreturn_data]))]


def data_to_pubkey_pairs(data, arc4_key=None):
    # Two pubkeys, minus length byte, minus prefix, minus two nonces,
    # minus two sign bytes.
    chunk_size = (33 * 2) - 1 - len(config.PREFIX) - 2 - 2
    data_array = list(chunks(data, chunk_size))
    pubkey_pairs = []
    for data_chunk in data_array:
        # Get data (fake) public key.
        pad_length = (33 * 2) - 1 - 2 - 2 - len(data_chunk)
        assert pad_length >= 0
        output_data = bytes([len(data_chunk)]) + data_chunk + (pad_length * b"\x00")  # noqa: PLW2901
        if arc4_key:
            output_data = encrypt_data(output_data, arc4_key)
        data_pubkey_1 = make_fully_valid(output_data[:31])
        data_pubkey_2 = make_fully_valid(output_data[31:])
        pubkey_pairs.append((data_pubkey_1, data_pubkey_2))
    return pubkey_pairs


def prepare_multisig_output(data, pubkey, arc4_key=None):
    try:
        dust_return_pubkey = binascii.unhexlify(pubkey)
    except binascii.Error:
        raise script.InputError(f"Invalid pubkey key: {pubkey}")  # noqa: B904
    if not script.is_fully_valid(dust_return_pubkey):
        raise exceptions.ComposeError(f"invalid public key: {pubkey}")
    pubkey_pairs = data_to_pubkey_pairs(data, arc4_key)
    outputs = []
    for pubkey_pair in pubkey_pairs:
        output_script = CScript(
            [1, pubkey_pair[0], pubkey_pair[1], dust_return_pubkey, 3, OP_CHECKMULTISIG]
        )
        outputs.append(CTxOut(config.MULTISIG_DUST_SIZE, output_script))
    return outputs


def prepare_data_outputs(encoding, data, source, pubkey, arc4_key=None):
    data_encoding = determine_encoding(data, encoding)
    if data_encoding == "multisig":
        return prepare_multisig_output(data, source, pubkey, arc4_key)
    if data_encoding == "opreturn":
        return prepare_opreturn_output(data, arc4_key)
    raise exceptions.TransactionError(f"Not supported encoding: {encoding}")


def prepare_outputs(source, destinations, data, pubkey, encoding, arc4_key=None):
    outputs = perpare_non_data_outputs(destinations)
    if data:
        outputs += prepare_data_outputs(encoding, data, source, pubkey, arc4_key)
    return outputs


def prepare_unspent_list(inputs_set: str):
    unspent_list = []
    utxos_list = inputs_set.split(",")
    if len(utxos_list) > MAX_INPUTS_SET:
        raise exceptions.ComposeError(
            f"too many UTXOs in inputs_set (max. {MAX_INPUTS_SET}): {len(utxos_list)}"
        )
    for str_input in utxos_list:
        if not util.is_utxo_format(str_input):
            raise exceptions.ComposeError(f"invalid UTXO: {str_input}")
        try:
            value = backend.bitcoind.get_tx_out_value(
                str_input.split(":")[0], int(str_input.split(":")[1])
            )
        except Exception as e:
            raise exceptions.ComposeError(f"invalid UTXO: {str_input}") from e
        unspent_list.append(
            {
                "txid": str_input.split(":")[0],
                "vout": int(str_input.split(":")[1]),
                "value": value,
            }
        )
    return sorted(unspent_list, key=lambda x: x["value"], reverse=True)


def select_utxos(unspent_list, target_amount):
    total_amount = 0
    selected_utxos = []
    for utxo in unspent_list:
        total_amount += utxo["value"]
        selected_utxos.append(utxo)
        if total_amount >= target_amount:
            break
    return selected_utxos


def utxos_to_txins(utxos: list):
    inputs = []
    for utxo in utxos:
        inputs.append(CTxIn(CScript([utxo["txid"], utxo["vout"]])))
    return inputs


def get_virtual_size(weight):
    return (weight + 3) // 4


def get_needed_fee(tx, satoshis_per_vbyte=None):
    weight = tx.calc_weight()
    virtual_size = get_virtual_size(weight)
    if satoshis_per_vbyte:
        return satoshis_per_vbyte * virtual_size
    else:
        return backend.bitcoind.satoshis_per_vbyte() * virtual_size


def get_minimum_change(source):
    if script.is_multisig(source):
        return config.MULTISIG_DUST_SIZE
    else:
        return config.REGULAR_DUST_SIZE


def prepare_transaction(source, outputs, unspent_list, desired_fee):
    outputs_total = sum(output["value"] for output in outputs)
    target_amount = outputs_total + desired_fee
    selected_utxos = select_utxos(unspent_list, target_amount)
    input_total = sum(input["value"] for input in selected_utxos)
    inputs = utxos_to_txins(selected_utxos)
    change = input_total - target_amount
    change_outputs = []
    if change > get_minimum_change(source):
        change_outputs.append(CTxOut(change, get_script(source)))
    else:
        change = 0
    return inputs, change_outputs, input_total


def construct_transaction(source, outputs, unspent_list, desired_fee):
    inputs, change_outputs, _input_total = prepare_transaction(
        source, outputs, unspent_list, desired_fee
    )
    tx = CTransaction(inputs, outputs + change_outputs)
    return tx


def get_estimated_fee(source, outputs, unspent_list, satoshis_per_vbyte=None):
    # calculate fee for a transaction with desired_fee = 0
    tx = construct_transaction(source, outputs, unspent_list, 0)
    return get_needed_fee(tx, satoshis_per_vbyte)


def compose_transaction(
    db, name, params, pubkey, inputs_set, encoding="auto", exact_fee=None, satoshis_per_vbyte=None
):
    source, destinations, data = transaction.compose_data(db, name, params)
    unspent_list = prepare_unspent_list(inputs_set)

    # prepare non obfuscted outputs
    clear_outputs = prepare_outputs(source, destinations, data, pubkey, encoding)

    if exact_fee:
        desired_fee = exact_fee
    else:
        # use non obfuscated outputs to calculate estimated fee...
        desired_fee = get_estimated_fee(source, clear_outputs, unspent_list, satoshis_per_vbyte)

    # prepare transaction with desired fee and no-obfuscated outputs
    inputs, change_outputs, btc_in = prepare_transaction(
        source, clear_outputs, unspent_list, desired_fee
    )
    # now we have inputs we can prepare obfuscated outputs
    outputs = prepare_outputs(
        source, destinations, data, pubkey, encoding, arc4_key=inputs[0]["txid"]
    )
    tx = CTransaction(inputs, outputs + change_outputs)
    btc_out = sum(output.nValue for output in outputs)
    btc_change = sum(change_output.nValue for change_output in change_outputs)

    return {
        "btc_in": btc_in,
        "btc_out": btc_out,
        "btc_change": btc_change,
        "btc_fee": btc_in - btc_out - btc_change,
        "unsigned_tx_hex": tx.serialize().hex(),
        "data": config.PREFIX + data if data else None,
    }
