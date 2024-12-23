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


"""
encoding
validate
verbose

exact_fee
sat_per_vbyte
confirmation_target
max_fee

allow_unconfirmed_inputs
exclude_utxos
inputs_set
disable_utxo_lock
use_utxos_with_balances
exclude_utxos_with_balances

mutlisig_pubkey

more_outputs

regular_dust_size (removed)
multisig_dust_size (removed)
extended_tx_info (removed)
old_style_api (removed)
p2sh_pretx_txid (removed)
segwit (removed)
return_psbt (replaced by `verbose`)
return_only_data (replaced by `verbose`)
pubkeys (replaced by `mutlisig_pubkey`)
dust_return_pubkey (replaced by `mutlisig_pubkey`)
unspent_tx_hash (replaced by `inputs_set`)
fee_per_kb (replaced by `sat_per_vbyte`)
fee_provided (replaced by 'max_fee')
"""


def list_unspent(source, allow_unconfirmed_inputs):
    min_conf = 0 if allow_unconfirmed_inputs else 1

    unspent_list = []
    # try with Bitcoin Core
    try:
        unspent_list = backend.bitcoind.safe_rpc("listunspent", [min_conf, 9999999, [source]])
    except exceptions.BitcoindRPCError:
        pass

    # then try with Electrs
    if len(unspent_list) == 0 and config.ELECTRS_URL is None:
        raise exceptions.ComposeError(
            "No UTXOs found with Bitcoin Core and Electr is not configured"
        )
    elif len(unspent_list) == 0:
        unspent_list = backend.electrs.get_utxos(
            source,
            unconfirmed=allow_unconfirmed_inputs,
        )

    return unspent_list


def prepare_inputs_set(inputs_set):
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

    return unspent_list


def prepare_unspent_list(source, transaction_options):
    inputs_set = transaction_options.get("inputs_set")
    if inputs_set is None:
        allow_unconfirmed_inputs = transaction_options.get("allow_unconfirmed_inputs", False)
        unspent_list = list_unspent(source, allow_unconfirmed_inputs)
    else:
        unspent_list = prepare_inputs_set(inputs_set)

    if len(unspent_list) == 0:
        raise exceptions.ComposeError(f"No UTXOs found for {source}")

    return sorted(unspent_list, key=lambda x: x["value"], reverse=True)


def compose_transaction(db, name, params, **construct_kwargs):
    encoding = construct_kwargs.get("encoding", "auto")
    skip_validation = construct_kwargs.get("validate", True)

    source, destinations, data = transaction.compose_data(
        db, name, params, skip_validation=skip_validation
    )

    unspent_list = prepare_unspent_list(construct_kwargs)

    exact_fee = construct_kwargs.get("exact_fee")
    sat_per_vbyte = construct_kwargs.get("sat_per_vbyte")
    pubkeys = construct_kwargs.get("pubkeys")

    # prepare non obfuscted outputs
    clear_outputs = prepare_outputs(source, destinations, data, pubkeys, encoding)

    if exact_fee:
        desired_fee = exact_fee
    else:
        # use non obfuscated outputs to calculate estimated fee...
        desired_fee = get_estimated_fee(source, clear_outputs, pubkeys, unspent_list, sat_per_vbyte)

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

    verbose = construct_kwargs.get("validate", False)
    if verbose:
        unsigned_tx_hex = tx.serialize().hex()
        return {
            "btc_in": btc_in,
            "btc_out": btc_out,
            "btc_change": btc_change,
            "btc_fee": btc_in - btc_out - btc_change,
            "unsigned_tx_hex": unsigned_tx_hex,
            "psbt": backend.bitcoind.convert_to_psbt(unsigned_tx_hex),
            "data": config.PREFIX + data if data else None,
        }
    else:
        return tx.serialize().hex()
