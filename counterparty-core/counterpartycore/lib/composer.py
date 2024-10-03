import binascii

from bitcoinutils.keys import P2pkhAddress, P2wpkhAddress, PublicKey
from bitcoinutils.script import Script, b_to_h
from bitcoinutils.transactions import Transaction, TxInput, TxOutput

from counterpartycore.lib import arc4, backend, config, exceptions, script, transaction, util
from counterpartycore.lib.transaction_helper.common_serializer import make_fully_valid
from counterpartycore.lib.transaction_helper.transaction_outputs import chunks

MAX_INPUTS_SET = 100


def search_pubkey(address, provides_pubkeys=None):
    if provides_pubkeys is None:
        raise exceptions.ComposeError("no pubkeys provided")
    for pubkey in provides_pubkeys:
        try:
            if not pubkey:
                raise exceptions.ComposeError(f"invalid pubkey: {pubkey}")
            check_address = PublicKey.from_hex(pubkey).get_address(compressed=True).to_string()
            print(check_address)
            if check_address == address:
                return pubkey
            check_address = PublicKey.from_hex(pubkey).get_address(compressed=False).to_string()
            print(check_address)
            if check_address == address:
                return pubkey
        except ValueError as e:
            raise exceptions.ComposeError(f"invalid pubkey: {pubkey}") from e
    raise exceptions.ComposeError(f"`{address}` pubkey not found in provided pubkeys")


def get_script(address, pubkeys=None):
    if script.is_multisig(address):
        signatures_required, addresses, signatures_possible = script.extract_array(address)
        pubkeys = [search_pubkey(address, pubkeys) for address in addresses]
        return Script(
            [signatures_required] + pubkeys + [signatures_possible] + ["OP_CHECKMULTISIG"]
        )
    if script.is_bech32(address):
        return P2wpkhAddress(address).to_script_pub_key()
    return P2pkhAddress(address).to_script_pub_key()


def get_default_value(address):
    if script.is_multisig(address):
        return config.DEFAULT_MULTISIG_DUST_SIZE
    return config.DEFAULT_REGULAR_DUST_SIZE


def perpare_non_data_outputs(destinations, pubkeys=None):
    outputs = []
    for address, value in destinations:
        output_value = value or get_default_value(address)
        outputs.append(TxOutput(output_value, get_script(address, pubkeys)))
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
        raise exceptions.TransactionError("One `OP_RETURN` output per transaction")
    opreturn_data = config.PREFIX + data
    if arc4_key:
        opreturn_data = encrypt_data(opreturn_data, arc4_key)
    return [TxOutput(0, Script(["OP_RETURN", b_to_h(opreturn_data)]))]


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
        pubkey_pairs.append((b_to_h(data_pubkey_1), b_to_h(data_pubkey_2)))
    return pubkey_pairs


def prepare_multisig_output(data, source, pubkeys, arc4_key=None):
    source_pubkey = search_pubkey(source, pubkeys)
    pubkey_pairs = data_to_pubkey_pairs(data, arc4_key)
    outputs = []
    for pubkey_pair in pubkey_pairs:
        output_script = Script(
            [1, pubkey_pair[0], pubkey_pair[1], source_pubkey, 3, "OP_CHECKMULTISIG"]
        )
        outputs.append(TxOutput(config.DEFAULT_MULTISIG_DUST_SIZE, output_script))
    return outputs


def prepare_data_outputs(encoding, data, source, pubkeys, arc4_key=None):
    data_encoding = determine_encoding(data, encoding)
    if data_encoding == "multisig":
        return prepare_multisig_output(data, source, pubkeys, arc4_key)
    if data_encoding == "opreturn":
        return prepare_opreturn_output(data, arc4_key)
    raise exceptions.TransactionError(f"Not supported encoding: {encoding}")


def prepare_outputs(source, destinations, data, pubkeys, encoding, arc4_key=None):
    outputs = perpare_non_data_outputs(destinations)
    if data:
        outputs += prepare_data_outputs(encoding, data, source, pubkeys, arc4_key)
    return outputs


def prepare_unspent_list(inputs_set: str):
    unspent_list = []
    utxos_list = inputs_set.split(",")
    if len(utxos_list) > MAX_INPUTS_SET:
        raise exceptions.ComposeError(
            f"too many UTXOs in inputs_set (max. {MAX_INPUTS_SET}): {len(utxos_list)}"
        )
    for utxo in utxos_list:
        if not util.is_utxo_format(utxo):
            raise exceptions.ComposeError(f"invalid UTXO: {utxo}")
        txid, vout = utxo.split(":")
        vout = int(vout)
        try:
            value = backend.bitcoind.get_utxo_value(txid, vout)
        except Exception as e:
            raise exceptions.ComposeError(f"invalid UTXO: {utxo}") from e
        unspent_list.append(
            {
                "txid": txid,
                "vout": vout,
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
    if total_amount < target_amount:
        raise exceptions.ComposeError(f"Insufficient funds for the target amount: {target_amount}")
    return selected_utxos


def utxos_to_txins(utxos: list):
    inputs = []
    for utxo in utxos:
        inputs.append(TxInput(utxo["txid"], utxo["vout"]))
    return inputs


def get_needed_fee(tx, satoshis_per_vbyte=None):
    virtual_size = tx.get_vsize()
    if satoshis_per_vbyte:
        return satoshis_per_vbyte * virtual_size
    return backend.bitcoind.satoshis_per_vbyte() * virtual_size


def get_minimum_change(source):
    if script.is_multisig(source):
        return config.MULTISIG_DUST_SIZE
    return config.REGULAR_DUST_SIZE


def prepare_transaction(source, outputs, pubkeys, unspent_list, desired_fee):
    outputs_total = sum(output["value"] for output in outputs)
    target_amount = outputs_total + desired_fee
    selected_utxos = select_utxos(unspent_list, target_amount)
    input_total = sum(input["value"] for input in selected_utxos)
    inputs = utxos_to_txins(selected_utxos)
    change = input_total - target_amount
    change_outputs = []
    if change > get_minimum_change(source):
        change_outputs.append(TxOutput(change, get_script(source, pubkeys)))
    else:
        change = 0
    return inputs, change_outputs, input_total


def construct_transaction(source, outputs, pubkeys, unspent_list, desired_fee):
    inputs, change_outputs, _input_total = prepare_transaction(
        source, outputs, pubkeys, unspent_list, desired_fee
    )
    tx = Transaction(inputs, outputs + change_outputs)
    return tx


def get_estimated_fee(source, outputs, pubkeys, unspent_list, satoshis_per_vbyte=None):
    # calculate fee for a transaction with desired_fee = 0
    tx = construct_transaction(source, outputs, pubkeys, unspent_list, 0)
    return get_needed_fee(tx, satoshis_per_vbyte)


def compose_transaction(
    db, name, params, pubkeys, inputs_set, encoding="auto", exact_fee=None, satoshis_per_vbyte=None
):
    source, destinations, data = transaction.compose_data(db, name, params)
    unspent_list = prepare_unspent_list(inputs_set)

    # prepare non obfuscted outputs
    clear_outputs = prepare_outputs(source, destinations, data, pubkeys, encoding)

    if exact_fee:
        desired_fee = exact_fee
    else:
        # use non obfuscated outputs to calculate estimated fee...
        desired_fee = get_estimated_fee(
            source, clear_outputs, pubkeys, unspent_list, satoshis_per_vbyte
        )

    # prepare transaction with desired fee and no-obfuscated outputs
    inputs, change_outputs, btc_in = prepare_transaction(
        source, clear_outputs, pubkeys, unspent_list, desired_fee
    )
    # now we have inputs we can prepare obfuscated outputs
    outputs = prepare_outputs(
        source, destinations, data, pubkeys, encoding, arc4_key=inputs[0]["txid"]
    )
    tx = Transaction(inputs, outputs + change_outputs)
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
