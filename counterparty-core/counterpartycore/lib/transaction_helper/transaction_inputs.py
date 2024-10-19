import binascii
import decimal
import hashlib
import logging
import threading

import bitcoin as bitcoinlib
import cachetools

from counterpartycore.lib import backend, config, exceptions, script, util
from counterpartycore.lib.transaction_helper import p2sh_serializer, transaction_outputs

logger = logging.getLogger(config.LOGGER_NAME)
D = decimal.Decimal

MAX_INPUTS_SET = 100


class BaseThreadSafeCache:
    def __init__(self, *args, **kwargs):
        # Note: reading is thread safe out of the box
        self.lock = threading.Lock()
        self.__cache = self.create_cache(*args, **kwargs)

    def create_cache(self, *args, **kwargs):
        raise NotImplementedError

    def get(self, key, default=None):
        return self.__cache.get(key, default)

    def pop(self, key, default=None):
        with self.lock:
            return self.__cache.pop(key, default)

    def delete(self, key):
        with self.lock:
            try:
                del self.__cache[key]
            except KeyError:
                pass

    def _get_cache(self):
        return self.__cache

    def set(self, key, value):
        with self.lock:
            try:
                self.__cache[key] = value
            except KeyError:
                pass

    def keys(self):
        return self.__cache.keys()

    def __len__(self):
        return len(self.__cache)

    def __iter__(self):
        return iter(self.__cache)

    def __contains__(self, key):
        return key in self.__cache


class ThreadSafeTTLCache(BaseThreadSafeCache):
    def create_cache(self, *args, **kwargs):
        return cachetools.TTLCache(*args, **kwargs)


def make_outkey_vin(txhex, vout):
    txbin = binascii.unhexlify(txhex) if isinstance(txhex, str) else txhex
    assert isinstance(vout, int)

    tx = bitcoinlib.core.CTransaction.deserialize(txbin)
    outkey = [(vin.prevout.hash, vin.prevout.n) for vin in tx.vin]
    outkey = hashlib.sha256((f"{outkey}{vout}").encode("ascii")).digest()

    return outkey


def make_outkey(output):
    return f"{output['txid']}{output['vout']}"


def print_coin(coin):
    return f"amount: {coin['amount']:.8f}; txid: {coin['txid']}; vout: {coin['vout']}; confirmations: {coin.get('confirmations', '?')}"  # simplify and make deterministic


class UTXOLocks(metaclass=util.SingletonMeta):
    # set higher than the max number of UTXOs we should expect to
    # manage in an aging cache for any one source address, at any one period
    # UTXO_P2SH_ENCODING_LOCKS is TTLCache for UTXOs that are used for chaining p2sh encoding
    #  instead of a simple (txid, vout) key we use [(vin.prevout.hash, vin.prevout.n) for vin tx1.vin]
    # we cache the make_outkey_vin to avoid having to fetch raw txs too often

    def __init__(self, utxo_locks_max_addresses=None):
        self.init(utxo_locks_max_addresses)

    def init(self, utxo_locks_max_addresses=None):
        # config
        self.utxo_p2sh_encoding_locks = ThreadSafeTTLCache(10000, 180)
        self.utxo_p2sh_encoding_locks_cache = ThreadSafeTTLCache(1000, 600)
        self.utxo_locks_max_age = config.UTXO_LOCKS_MAX_AGE
        self.utxo_locks_max_addresses = utxo_locks_max_addresses or config.UTXO_LOCKS_MAX_ADDRESSES
        self.utxo_locks_per_address_maxsize = 5000

        self.utxo_locks = None
        if self.utxo_locks_max_addresses > 0:
            self.utxo_locks = util.DictCache(self.utxo_locks_max_addresses)

    def make_outkey_vin_txid(self, txid, vout):
        if (txid, vout) not in self.utxo_p2sh_encoding_locks_cache:
            txhex = backend.bitcoind.getrawtransaction(txid, verbose=False)
            self.utxo_p2sh_encoding_locks_cache.set((txid, vout), make_outkey_vin(txhex, vout))

        return self.utxo_p2sh_encoding_locks_cache.get((txid, vout))

    def filter_unspents(self, source, unspent, exclude_utxos):
        filter_unspents_utxo_locks = []
        if self.utxo_locks is not None and source in self.utxo_locks:
            filter_unspents_utxo_locks = self.utxo_locks[source].keys()
        filter_unspents_p2sh_locks = self.utxo_p2sh_encoding_locks.keys()  # filter out any locked UTXOs to prevent creating transactions that spend the same UTXO when they're created at the same time
        filtered_unspent = []
        for output in unspent:
            if (
                make_outkey(output) not in filter_unspents_utxo_locks
                and self.make_outkey_vin_txid(output["txid"], output["vout"])
                not in filter_unspents_p2sh_locks
                and (
                    not exclude_utxos
                    or not isinstance(exclude_utxos, str)
                    or f"{output['txid']}:{output['vout']}" not in exclude_utxos.split(",")
                )
            ):
                filtered_unspent.append(output)
        return filtered_unspent

    def lock_utxos(self, source, inputs):
        # Lock the source's inputs (UTXOs) chosen for this transaction
        if self.utxo_locks is not None:
            if source not in self.utxo_locks:
                self.utxo_locks[source] = ThreadSafeTTLCache(
                    self.utxo_locks_per_address_maxsize, self.utxo_locks_max_age
                )
            for tx_input in inputs:
                self.utxo_locks[source].set(make_outkey(tx_input), tx_input)

    def lock_p2sh_utxos(self, unsigned_pretx):
        self.utxo_p2sh_encoding_locks.set(make_outkey_vin(unsigned_pretx, 0), True)

    def unlock_utxos(self, source, inputs):
        if self.utxo_locks is not None and inputs:
            for input in inputs:
                self.utxo_locks[source].pop(make_outkey(input), None)


def sort_unspent_txouts(unspent, dust_size=config.DEFAULT_REGULAR_DUST_SIZE):
    # Filter out all dust amounts to avoid bloating the resultant transaction
    unspent = list(filter(lambda x: x["value"] > dust_size, unspent))
    # Sort by amount, using the largest UTXOs available
    if config.REGTEST:
        # REGTEST has a lot of coinbase inputs that can't be spent due to maturity
        # this doesn't usually happens on mainnet or testnet because most fednodes aren't mining
        unspent = sorted(unspent, key=lambda x: (x["confirmations"], x["value"]), reverse=True)
    else:
        unspent = sorted(unspent, key=lambda x: x["value"], reverse=True)

    return unspent


def construct_coin_selection(
    size_for_fee,
    encoding,
    data_array,
    source,
    allow_unconfirmed_inputs,
    unspent_tx_hash,
    inputs_set,
    fee_per_kb,
    estimate_fee_per_kb_nblocks,
    exact_fee,
    fee_provided,
    destination_btc_out,
    data_btc_out,
    regular_dust_size,
    multisig_dust_size,
    disable_utxo_locks,
    exclude_utxos,
):
    if inputs_set:
        if isinstance(inputs_set, str):
            new_inputs_set = []
            utxos_list = inputs_set.split(",")
            if len(utxos_list) > MAX_INPUTS_SET:
                raise exceptions.ComposeError(
                    f"too many UTXOs in inputs_set (max. {MAX_INPUTS_SET}): {len(utxos_list)}"
                )
            for str_input in utxos_list:
                if not util.is_utxo_format(str_input):
                    raise exceptions.ComposeError(f"invalid UTXO: {str_input}")
                try:
                    amount = backend.bitcoind.get_tx_out_amount(
                        str_input.split(":")[0], int(str_input.split(":")[1])
                    )
                except Exception as e:
                    raise exceptions.ComposeError(f"invalid UTXO: {str_input}") from e
                new_inputs_set.append(
                    {
                        "txid": str_input.split(":")[0],
                        "vout": int(str_input.split(":")[1]),
                        "amount": amount,
                    }
                )
            use_inputs = unspent = new_inputs_set
        elif isinstance(inputs_set, list):
            use_inputs = unspent = inputs_set
        else:
            raise exceptions.ComposeError(f"invalid inputs_set: {inputs_set}")
    else:
        if unspent_tx_hash is not None:
            unspent = backend.addrindexrs.get_unspent_txouts(
                source,
                unconfirmed=allow_unconfirmed_inputs,
                unspent_tx_hash=unspent_tx_hash,
            )
        else:
            unspent = backend.addrindexrs.get_unspent_txouts(
                source, unconfirmed=allow_unconfirmed_inputs
            )
        logger.trace(f"TX Construct - Unspent UTXOs: {[print_coin(coin) for coin in unspent]}")
        if len(unspent) == 0:
            raise exceptions.BalanceError(
                f"Insufficient {config.BTC} at address {source}: no unspent outputs."
            )

        if encoding == "multisig":
            dust = multisig_dust_size
        else:
            dust = regular_dust_size

        unspent = sort_unspent_txouts(unspent, dust_size=dust)
        # self.logger.debug(f"Sorted candidate UTXOs: {[print_coin(coin) for coin in unspent]}")
        use_inputs = unspent

    use_inputs = unspent = UTXOLocks().filter_unspents(source, unspent, exclude_utxos)

    # dont override fee_per_kb if specified
    estimate_fee_per_kb = None
    if fee_per_kb is not None:
        estimate_fee_per_kb = False
    else:
        fee_per_kb = config.DEFAULT_FEE_PER_KB

    if estimate_fee_per_kb is None:
        estimate_fee_per_kb = config.ESTIMATE_FEE_PER_KB

    # use backend estimated fee_per_kb
    if estimate_fee_per_kb:
        estimated_fee_per_kb = backend.bitcoind.fee_per_kb(
            estimate_fee_per_kb_nblocks, config.ESTIMATE_FEE_MODE
        )
        if estimated_fee_per_kb is not None:
            fee_per_kb = max(
                estimated_fee_per_kb, fee_per_kb
            )  # never drop below the default fee_per_kb

    logger.trace(f"TX Construct - Fee/KB {fee_per_kb / config.UNIT:.8f}")

    inputs = []
    btc_in = 0
    change_quantity = 0
    sufficient_funds = False
    final_fee = fee_per_kb
    desired_input_count = 1

    if encoding == "multisig" and data_array and util.enabled("bytespersigop"):
        desired_input_count = len(data_array) * 2

    # pop inputs until we can pay for the fee
    use_inputs_index = 0
    for coin in use_inputs:
        logger.trace(f"TX Construct - New input: {print_coin(coin)}")
        inputs.append(coin)
        btc_in += round(coin["amount"] * config.UNIT)

        # If exact fee is specified, use that. Otherwise, calculate size of tx
        # and base fee on that (plus provide a minimum fee for selling BTC).
        size = 181 * len(inputs) + size_for_fee + 10
        if exact_fee:
            final_fee = exact_fee
        else:
            necessary_fee = int(size / 1000 * fee_per_kb)
            final_fee = max(fee_provided, necessary_fee)
            logger.trace(
                f"TX Construct - final_fee inputs: {len(inputs)} size: {size} final_fee {final_fee}"
            )

        # Check if good.
        btc_out = destination_btc_out + data_btc_out
        change_quantity = btc_in - (btc_out + final_fee)
        logger.trace(
            f"TX Construct - Size: {size} Fee: {final_fee / config.UNIT:.8f} Change quantity: {change_quantity / config.UNIT:.8f} BTC"
        )

        # If after the sum of all the utxos the change is dust, then it will be added to the miners instead of returning an error
        if (
            (use_inputs_index == len(use_inputs) - 1)
            and (change_quantity > 0)
            and (change_quantity < regular_dust_size)
        ):
            sufficient_funds = True
            final_fee = final_fee + change_quantity
            change_quantity = 0
        # If change is necessary, must not be a dust output.
        elif change_quantity == 0 or change_quantity >= regular_dust_size:
            sufficient_funds = True
            if len(inputs) >= desired_input_count:
                break

        use_inputs_index = use_inputs_index + 1

    if not sufficient_funds:
        # Approximate needed change, fee by with most recently calculated
        # quantities.
        btc_out = destination_btc_out + data_btc_out
        total_btc_out = btc_out + max(change_quantity, 0) + final_fee

        need = f"{D(total_btc_out) / D(config.UNIT)} {config.BTC}"
        include_fee = f"{D(final_fee) / D(config.UNIT)} {config.BTC}"
        available = f"{D(btc_in) / D(config.UNIT)} {config.BTC}"
        error_message = f"Insufficient {config.BTC} at address {source}. Need: {need} (Including fee: {include_fee}), available: {available}."
        error_message += f" These fees are estimated for a confirmation target of {estimate_fee_per_kb_nblocks} blocks, you can reduce them by using the `confirmation_target` parameter with a higher value or by manually setting the fees with the `fee` parameter."

        if not allow_unconfirmed_inputs:
            error_message += " To spend unconfirmed coins, use the flag `--unconfirmed`. (Unconfirmed coins cannot be spent from multi‐sig addresses.)"

        raise exceptions.BalanceError(error_message)

    if not disable_utxo_locks:
        UTXOLocks().lock_utxos(source, inputs)

    # ensure inputs have scriptPubKey
    #   this is not provided by indexd
    inputs = script.ensure_script_pub_key_for_inputs(inputs)

    return inputs, change_quantity, btc_in, final_fee


def prepare_inputs(
    source,
    data,
    destination_outputs,
    destination_btc_out,
    data_array,
    data_btc_out,
    provided_pubkeys,
    encoding,
    p2sh_pretx_txid,
    allow_unconfirmed_inputs,
    unspent_tx_hash,
    inputs_set,
    fee_per_kb,
    estimate_fee_per_kb_nblocks,
    exact_fee,
    fee_provided,
    regular_dust_size,
    multisig_dust_size,
    disable_utxo_locks,
    exclude_utxos,
):
    btc_in = 0
    final_fee = 0
    # Calculate collective size of outputs, for fee calculation
    p2pkhsize = 25 + 9
    if encoding == "multisig":
        data_output_size = 81  # 71 for the data
    elif encoding == "opreturn":
        # prefix + data + 10 bytes script overhead
        data_output_size = len(config.PREFIX) + 10
        if data is not None:
            data_output_size = data_output_size + len(data)
    else:
        data_output_size = p2pkhsize  # Pay‐to‐PubKeyHash (25 for the data?)

    if encoding == "p2sh":
        # calculate all the p2sh outputs
        size_for_fee, datatx_necessary_fee, data_value, data_btc_out = (
            p2sh_serializer.calculate_outputs(
                destination_outputs, data_array, fee_per_kb, exact_fee
            )
        )
        # replace the data value
        # data_output = (data_array, data_value)
    else:
        sum_data_output_size = len(data_array) * data_output_size
        size_for_fee = ((25 + 9) * len(destination_outputs)) + sum_data_output_size

    if not (encoding == "p2sh" and p2sh_pretx_txid):
        inputs, change_quantity, n_btc_in, n_final_fee = construct_coin_selection(
            size_for_fee,
            encoding,
            data_array,
            source,
            allow_unconfirmed_inputs,
            unspent_tx_hash,
            inputs_set,
            fee_per_kb,
            estimate_fee_per_kb_nblocks,
            exact_fee,
            fee_provided,
            destination_btc_out,
            data_btc_out,
            regular_dust_size,
            multisig_dust_size,
            disable_utxo_locks,
            exclude_utxos,
        )
        btc_in = n_btc_in
        final_fee = n_final_fee
    else:
        # when encoding is P2SH and the pretx txid is passed we can skip coinselection
        inputs, change_quantity = None, None

    # Normalize source
    if script.is_multisig(source):
        source_address = transaction_outputs.multisig_pubkeyhashes_to_pubkeys(
            source, provided_pubkeys
        )
    else:
        source_address = source

    if change_quantity:
        change_output = (source_address, change_quantity)
    else:
        change_output = None

    return inputs, change_output, btc_in, final_fee
