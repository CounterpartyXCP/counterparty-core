import binascii
import string
import time
from collections import OrderedDict

from bitcoinutils.keys import P2pkhAddress, P2wpkhAddress, PublicKey
from bitcoinutils.script import Script, b_to_h
from bitcoinutils.transactions import Transaction, TxInput, TxOutput

from counterpartycore.lib import (
    arc4,
    backend,
    config,
    exceptions,
    ledger,
    script,
    transaction,
    util,
)
from counterpartycore.lib.transaction_helper.common_serializer import make_fully_valid
from counterpartycore.lib.transaction_helper.transaction_outputs import chunks

MAX_INPUTS_SET = 100


def get_script(address):
    if script.is_multisig(address):
        raise exceptions.TransactionError("Multisig address not supported for non-data outputs")
    try:
        if script.is_bech32(address):
            return P2wpkhAddress(address).to_script_pub_key()
        return P2pkhAddress(address).to_script_pub_key()
    except Exception as e:
        raise exceptions.ComposeError(f"Invalid address: {address}") from e


################
#   Outputs    #
################


def perpare_non_data_outputs(destinations):
    outputs = []
    for address, value in destinations:
        output_value = value or config.DEFAULT_REGULAR_DUST_SIZE
        outputs.append(TxOutput(output_value, get_script(address)))
    return outputs


def determine_encoding(data, construct_params):
    desired_encoding = construct_params.get("encoding", "auto")
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


def prepare_opreturn_output(data, arc4_key):
    if len(data) + len(config.PREFIX) > config.OP_RETURN_MAX_SIZE:
        raise exceptions.TransactionError("One `OP_RETURN` output per transaction")
    opreturn_data = config.PREFIX + data
    opreturn_data = encrypt_data(opreturn_data, arc4_key)
    return [TxOutput(0, Script(["OP_RETURN", b_to_h(opreturn_data)]))]


def is_valid_pubkey(pubkey):
    try:
        PublicKey.from_hex(pubkey).get_address(compressed=True).to_string()
        return True
    except Exception:
        return False


def search_pubkey(source, unspent_list, construct_params):
    # if pubkeys are provided, check it and return
    multisig_pubkey = construct_params.get("multisig_pubkey")
    if multisig_pubkey is not None:
        if not is_valid_pubkey(multisig_pubkey):
            raise exceptions.ComposeError(f"Invalid multisig pubkey: {multisig_pubkey}")
        return multisig_pubkey

    # else search with Bitcoin Core
    tx_hashes = [utxo["txid"] for utxo in unspent_list]
    multisig_pubkey = backend.bitcoind.search_pubkey_in_transactions(source, tx_hashes)
    if multisig_pubkey is not None:
        return multisig_pubkey

    # else search with Electrs
    if config.ELECTRS_URL is None:
        raise exceptions.ComposeError(
            "No multisig pubkey found with Bitcoin Core and Electrs is not configured, use the `multisig_pubkey` parameter to provide it"
        )

    multisig_pubkey = backend.electrs.search_pubkey(source)
    if multisig_pubkey is not None:
        return multisig_pubkey

    raise exceptions.ComposeError(
        f"No multisig pubkey found for {source}, use the `multisig_pubkey` parameter to provide it"
    )


def data_to_pubkey_pairs(data, arc4_key):
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
        output_data = encrypt_data(output_data, arc4_key)
        data_pubkey_1 = make_fully_valid(output_data[:31])
        data_pubkey_2 = make_fully_valid(output_data[31:])
        pubkey_pairs.append((b_to_h(data_pubkey_1), b_to_h(data_pubkey_2)))
    return pubkey_pairs


def prepare_multisig_output(source, data, arc4_key, unspent_list, construct_params):
    multisig_pubkey = search_pubkey(source, unspent_list, construct_params)
    pubkey_pairs = data_to_pubkey_pairs(data, arc4_key)
    outputs = []
    for pubkey_pair in pubkey_pairs:
        output_script = Script(
            [1, pubkey_pair[0], pubkey_pair[1], multisig_pubkey, 3, "OP_CHECKMULTISIG"]
        )
        outputs.append(TxOutput(config.DEFAULT_MULTISIG_DUST_SIZE, output_script))
    return outputs


def prepare_data_outputs(source, data, unspent_list, construct_params):
    encoding = determine_encoding(data, construct_params)
    arc4_key = unspent_list[0]["txid"]
    if encoding == "multisig":
        return prepare_multisig_output(source, data, arc4_key, unspent_list, construct_params)
    if encoding == "opreturn":
        return prepare_opreturn_output(data, arc4_key)
    raise exceptions.TransactionError(f"Not supported encoding: {encoding}")


def prepare_outputs(source, destinations, data, unspent_list, construct_params):
    outputs = perpare_non_data_outputs(destinations)
    if data:
        outputs += prepare_data_outputs(source, data, unspent_list, construct_params)
    return outputs


def prepare_more_outputs(more_outputs):
    output_list = [output.split(":") for output in more_outputs.split(",")]
    outputs = []
    for output in output_list:
        if len(output) != 2:
            raise exceptions.ComposeError(f"Invalid output format: {output}")
        address, value = output

        try:
            value = int(value)
        except ValueError as e:
            raise exceptions.ComposeError(f"Invalid value for output: {output}") from e

        try:
            # if hex string we assume it is a script
            if all(c in string.hexdigits for c in address):
                script = Script.from_raw(address, has_segwit=True)
            else:
                script = get_script(address)
        except Exception as e:
            raise exceptions.ComposeError(f"Invalid script or address for output: {output}") from e

        outputs.append(TxOutput(value, script))

    return outputs


################
#   Inputs     #
################


class UTXOLocks(metaclass=util.SingletonMeta):
    def __init__(self):
        self.locks = OrderedDict()
        self.max_age = config.UTXO_LOCKS_MAX_AGE
        self.max_size = config.UTXO_LOCKS_MAX_ADDRESSES

    def lock(self, utxo):
        self.locks[utxo] = time.time()
        if len(self.locks) > self.max_size:
            self.locks.popitem(last=False)

    def locked(self, utxo):
        if utxo not in self.locks:
            return False
        if time.time() - self.locks[utxo] > self.max_age:
            del self.locks[utxo]
            return False
        return True

    def filter_unspent_list(self, unspent_list):
        return [utxo for utxo in unspent_list if not self.locked(f"{utxo['txid']}:{utxo['vout']}")]

    def lock_inputs(self, inputs):
        for input in inputs:
            self.lock(f"{input.txid}:{input.txout_index}")


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
            "No UTXOs found with Bitcoin Core and Electr is not configured, use the `inputs_set` parameter to provide UTXOs"
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
        utxo_parts = utxo.split(":")

        if len(utxo_parts) == 2:
            txid, vout = utxo.split(":")
            value = None
        elif len(utxo_parts) == 3:
            txid, vout, value = utxo.split(":")
            try:
                value = int(value)
            except ValueError as e:
                raise exceptions.ComposeError(f"invalid value for UTXO: {utxo}") from e
        else:
            raise exceptions.ComposeError(f"invalid UTXO format: {utxo}")

        if not util.is_utxo_format(f"{txid}:{vout}"):
            raise exceptions.ComposeError(f"invalid UTXO format: {utxo}")

        if value is None:
            try:
                value = backend.bitcoind.get_utxo_value(txid, vout)
            except Exception as e:
                raise exceptions.ComposeError(f"value not found for UTXO: {utxo}") from e

        unspent_list.append(
            {
                "txid": txid,
                "vout": vout,
                "value": value,
            }
        )
    return unspent_list


def utxo_to_address(db, utxo):
    sql = "SELECT utxo_address FROM balances WHERE utxo = ? LIMIT 1"
    balance = db.execute(sql, (utxo,)).fetchone()
    if balance:
        return balance["utxo_address"]
    raise exceptions.ComposeError(f"the address corresponding to {utxo} not found in the database")


def ensure_utxo_is_first(utxo, unspent_list):
    txid, vout = utxo.split(":")
    vout = int(vout)
    new_unspent_list = []
    for unspent in unspent_list:
        if unspent["txid"] == txid and unspent["vout"] == vout:
            new_unspent_list.insert(0, unspent)
        else:
            new_unspent_list.append(unspent)

    first_utxo = new_unspent_list[0]
    if first_utxo["txid"] != txid or first_utxo["vout"] != vout:
        try:
            value = backend.bitcoind.get_utxo_value(txid, vout)
        except Exception as e:
            raise exceptions.ComposeError(f"value not found for UTXO: {utxo}") from e
        new_unspent_list.insert(
            0,
            {
                "txid": txid,
                "vout": vout,
                "value": value,
            },
        )
    return new_unspent_list


def filter_utxos_with_balances(db, unspent_list, construct_params):
    use_utxos_with_balances = construct_params.get("use_utxos_with_balances", False)
    if use_utxos_with_balances:
        return unspent_list

    exclude_utxos_with_balances = construct_params.get("exclude_utxos_with_balances", False)
    new_unspent_list = []
    for utxo in unspent_list:
        str_input = f"{utxo['txid']}:{utxo['vout']}"
        utxo_balances = ledger.get_utxo_balances(db, str_input)
        with_balances = len(utxo_balances) > 0 and any(
            [balance["quantity"] > 0 for balance in utxo_balances]
        )
        if exclude_utxos_with_balances and with_balances:
            continue
        if with_balances:
            raise exceptions.ComposeError(f"UTXO {str_input} has balances")
        new_unspent_list.append(utxo)


def prepare_unspent_list(db, source, construct_params):
    inputs_set = construct_params.get("inputs_set")

    if inputs_set is None:
        # get unspent list from Bitcoin Core or Electrs
        allow_unconfirmed_inputs = construct_params.get("allow_unconfirmed_inputs", False)
        if util.is_utxo_format(source):
            source_address = utxo_to_address(db, source)
        else:
            source_address = source
        unspent_list = list_unspent(source_address, allow_unconfirmed_inputs)
    else:
        # prepare unspent list provided by the user
        unspent_list = prepare_inputs_set(inputs_set)

    # exclude utxos if explicitly requested
    exclude_utxos = construct_params.get("exclude_utxos")
    if exclude_utxos is not None:
        exclude_utxos_list = exclude_utxos.split(",")
        unspent_list = [
            utxo
            for utxo in unspent_list
            if f"{utxo['txid']}:{utxo['vout']}" not in exclude_utxos_list
        ]

    # excluded locked utxos
    if not construct_params.get("disable_utxo_lock", False):
        unspent_list = UTXOLocks().filter_unspent_list(unspent_list)

    # exclude utxos with balances if needed
    filter_utxos_with_balances(db, unspent_list, construct_params)

    # sort unspent list by value
    unspent_list = sorted(unspent_list, key=lambda x: x["value"], reverse=True)

    # if source is an utxo, ensure it is first in the unspent list
    if util.is_utxo_format(source):
        unspent_list = ensure_utxo_is_first(source, unspent_list)

    if len(unspent_list) == 0:
        raise exceptions.ComposeError(
            f"No UTXOs found for {source}, provide UTXOs with the `inputs_set` parameter"
        )

    return unspent_list


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


###################
#   Composition   #
##################


def get_needed_fee(tx, satoshis_per_vbyte):
    virtual_size = tx.get_vsize()
    return satoshis_per_vbyte * virtual_size


def prepare_fee_parameters(construct_params):
    exact_fee = construct_params.get("exact_fee")
    sat_per_vbyte = construct_params.get("sat_per_vbyte")
    confirmation_target = construct_params.get("confirmation_target")
    max_fee = construct_params.get("max_fee")
    if exact_fee is not None:
        sat_per_vbyte, confirmation_target, max_fee = None, None, None
    elif sat_per_vbyte is None:
        if confirmation_target is not None:
            sat_per_vbyte = backend.bitcoind.satoshis_per_vbyte(confirmation_target)
        else:
            sat_per_vbyte = backend.bitcoind.satoshis_per_vbyte()
    return exact_fee, sat_per_vbyte, max_fee


def prepare_inputs_and_change(db, source, outputs, unspent_list, construct_params):
    # prepare fee parameters
    exact_fee, sat_per_vbyte, max_fee = prepare_fee_parameters(construct_params)

    change_address = construct_params.get("change_address")
    if change_address is None:
        if util.is_utxo_format(source):
            change_address = utxo_to_address(db, source)
        else:
            change_address = source

    change_outputs = []
    # try with one input and increase until the change is enough for the fee
    input_count = 1
    while True:
        if input_count > len(unspent_list):
            raise exceptions.ComposeError("Insufficient funds for the target amount")

        selected_utxos = unspent_list[:input_count]
        inputs = utxos_to_txins(selected_utxos)
        btc_in = sum(utxo["value"] for utxo in selected_utxos)
        outputs_total = sum(output["value"] for output in outputs)
        change_amount = btc_in - outputs_total

        # if change is negative, try with more inputs
        if change_amount <= 0:
            input_count += 1
            continue
        # if change is not enough for exact_fee, try with more inputs
        if exact_fee is not None and change_amount < exact_fee:
            input_count += 1
            continue

        # if change is enough for exact_fee, add change output and break
        if exact_fee is not None:
            change_amount = change_amount - exact_fee
            if change_amount > config.REGULAR_DUST_SIZE:
                change_outputs.append(TxOutput(change_amount, get_script(change_address)))
            break

        # else calculate needed fee
        tx = Transaction(inputs, outputs + [TxOutput(change_amount, get_script(change_address))])
        needed_fee = get_needed_fee(tx, sat_per_vbyte)
        if max_fee is not None:
            needed_fee = min(needed_fee, max_fee)
        # if change is enough for needed fee, add change output and break
        if change_amount > needed_fee:
            change_amount = change_amount - needed_fee
            if change_amount > config.REGULAR_DUST_SIZE:
                change_outputs.append(TxOutput(change_amount, get_script(change_address)))
            break
        # else try with more inputs
        input_count += 1

    return inputs, btc_in, change_outputs


"""
+encoding
+validate
+verbose

+exact_fee
+sat_per_vbyte
+confirmation_target
+max_fee

+inputs_set
+allow_unconfirmed_inputs
+exclude_utxos
+use_utxos_with_balances
+exclude_utxos_with_balances
+disable_utxo_lock

+mutlisig_pubkey

+change_address
-more_outputs

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


def compose_transaction(db, name, params, construct_params):
    # prepare data
    skip_validation = construct_params.get("validate", True)
    source, destinations, data = transaction.compose_data(
        db, name, params, skip_validation=skip_validation
    )

    # prepare unspent list
    unspent_list = prepare_unspent_list(db, source, construct_params)

    # prepare outputs
    outputs = prepare_outputs(source, destinations, data, unspent_list, construct_params)

    # prepare inputs and change
    inputs, btc_in, change_outputs = prepare_inputs_and_change(
        source, outputs, unspent_list, construct_params
    )

    # Add more outputs if needed
    more_outputs = construct_params.get("more_outputs")
    if more_outputs:
        prepare_more_outputs(more_outputs)

    if not construct_params.get("disable_utxo_lock", False):
        UTXOLocks().lock_inputs(inputs)

    # construct transaction
    tx = Transaction(inputs, outputs + change_outputs)
    btc_out = sum(output.nValue for output in outputs)
    btc_change = sum(change_output.nValue for change_output in change_outputs)
    verbose = construct_params.get("validate", False)

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
