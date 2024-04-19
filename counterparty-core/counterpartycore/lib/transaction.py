"""
Construct and serialize the Bitcoin transactions that are Counterparty transactions.

This module contains no consensus‐critical code.
"""

import binascii
import decimal
import hashlib
import inspect
import io
import logging
import sys
import threading

import bitcoin as bitcoinlib
import cachetools
from bitcoin.core import CTransaction

from counterpartycore.lib import (
    arc4,  # noqa: F401
    backend,
    config,
    exceptions,
    gettxinfo,
    ledger,
    message_type,
    messages,
    script,
    util,
)
from counterpartycore.lib.kickstart.blocks_parser import BlockchainParser
from counterpartycore.lib.transaction_helper import p2sh_encoding, serializer

# Constants
OP_RETURN = b"\x6a"
OP_PUSHDATA1 = b"\x4c"
OP_DUP = b"\x76"
OP_HASH160 = b"\xa9"
OP_EQUALVERIFY = b"\x88"
OP_CHECKSIG = b"\xac"
OP_0 = b"\x00"
OP_1 = b"\x51"
OP_2 = b"\x52"
OP_3 = b"\x53"
OP_CHECKMULTISIG = b"\xae"
OP_EQUAL = b"\x87"

D = decimal.Decimal


# FILE AS SINGLETON API
#
# We eventually neet to rip this out and just instantiate the TransactionService
# when we explcitly build up a dependency tree.

TRANSACTION_SERVICE_SINGLETON = None


def initialise(force=False):
    global TRANSACTION_SERVICE_SINGLETON  # noqa: PLW0603

    if not force and TRANSACTION_SERVICE_SINGLETON:
        return TRANSACTION_SERVICE_SINGLETON

    utxo_locks = None
    if config.UTXO_LOCKS_MAX_ADDRESSES > 0:
        utxo_locks = util.DictCache(size=config.UTXO_LOCKS_MAX_ADDRESSES)

    TRANSACTION_SERVICE_SINGLETON = TransactionService(
        backend=backend,
        prefix=config.PREFIX,
        ps2h_dust_return_pubkey=config.P2SH_DUST_RETURN_PUBKEY,
        utxo_locks_max_age=config.UTXO_LOCKS_MAX_AGE,
        utxo_locks_max_addresses=config.UTXO_LOCKS_MAX_ADDRESSES,
        default_regular_dust_size=config.DEFAULT_REGULAR_DUST_SIZE,
        default_multisig_dust_size=config.DEFAULT_MULTISIG_DUST_SIZE,
        estimate_fee_mode=config.ESTIMATE_FEE_MODE,
        op_return_max_size=config.OP_RETURN_MAX_SIZE,
        utxo_locks=utxo_locks,
        utxo_p2sh_encoding_locks=ThreadSafeTTLCache(10000, 180),
        utxo_p2sh_encoding_locks_cache=ThreadSafeTTLCache(1000, 600),
    )


def construct(
    db,
    tx_info,
    encoding="auto",
    fee_per_kb=config.DEFAULT_FEE_PER_KB,
    estimate_fee_per_kb=None,
    estimate_fee_per_kb_nblocks=config.ESTIMATE_FEE_CONF_TARGET,
    regular_dust_size=config.DEFAULT_REGULAR_DUST_SIZE,
    multisig_dust_size=config.DEFAULT_MULTISIG_DUST_SIZE,
    op_return_value=config.DEFAULT_OP_RETURN_VALUE,
    exact_fee=None,
    fee_provided=0,
    provided_pubkeys=None,
    dust_return_pubkey=None,
    allow_unconfirmed_inputs=False,
    unspent_tx_hash=None,
    custom_inputs=None,
    disable_utxo_locks=False,
    extended_tx_info=False,
    old_style_api=None,
    segwit=False,
    p2sh_source_multisig_pubkeys=None,
    p2sh_source_multisig_pubkeys_required=None,
    p2sh_pretx_txid=None,
):
    if TRANSACTION_SERVICE_SINGLETON is None:
        raise Exception("Transaction not initialized")

    return TRANSACTION_SERVICE_SINGLETON.construct(
        db,
        tx_info,
        encoding,
        fee_per_kb,
        estimate_fee_per_kb,
        estimate_fee_per_kb_nblocks,
        regular_dust_size,
        multisig_dust_size,
        op_return_value,
        exact_fee,
        fee_provided,
        provided_pubkeys,
        dust_return_pubkey,
        allow_unconfirmed_inputs,
        unspent_tx_hash,
        custom_inputs,
        disable_utxo_locks,
        extended_tx_info,
        old_style_api,
        segwit,
        p2sh_source_multisig_pubkeys,
        p2sh_source_multisig_pubkeys_required,
        p2sh_pretx_txid,
    )


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


# set higher than the max number of UTXOs we should expect to
# manage in an aging cache for any one source address, at any one period
# UTXO_P2SH_ENCODING_LOCKS is TTLCache for UTXOs that are used for chaining p2sh encoding
#  instead of a simple (txid, vout) key we use [(vin.prevout.hash, vin.prevout.n) for vin tx1.vin]
# we cache the make_outkey_vin to avoid having to fetch raw txs too often


class TransactionService:
    def __init__(
        self,
        backend,
        prefix,
        ps2h_dust_return_pubkey,
        utxo_locks_max_age=3.0,
        utxo_locks_max_addresses=1000,
        utxo_locks_per_address_maxsize=5000,
        default_regular_dust_size=config.DEFAULT_REGULAR_DUST_SIZE,
        default_multisig_dust_size=config.DEFAULT_MULTISIG_DUST_SIZE,
        estimate_fee_mode=config.ESTIMATE_FEE_MODE,
        op_return_max_size=config.OP_RETURN_MAX_SIZE,
        utxo_p2sh_encoding_locks=None,
        utxo_p2sh_encoding_locks_cache=None,
        utxo_locks=None,
    ):
        self.logger = logging.getLogger(
            config.LOGGER_NAME
        )  # has to be config.LOGGER_NAME or integration tests fail
        self.backend = backend

        self.utxo_p2sh_encoding_locks = utxo_p2sh_encoding_locks or ThreadSafeTTLCache(10000, 180)
        self.utxo_p2sh_encoding_locks_cache = utxo_p2sh_encoding_locks_cache or ThreadSafeTTLCache(
            1000, 600
        )
        self.utxo_locks = utxo_locks

        self.utxo_locks_max_age = utxo_locks_max_age
        self.utxo_locks_max_addresses = utxo_locks_max_addresses
        self.utxo_locks_per_address_maxsize = utxo_locks_per_address_maxsize

        self.default_regular_dust_size = default_regular_dust_size
        self.default_multisig_dust_size = default_multisig_dust_size
        self.estimate_fee_mode = estimate_fee_mode

        self.prefix = prefix
        self.op_return_max_size = op_return_max_size
        self.ps2h_dust_return_pubkey = ps2h_dust_return_pubkey

    def get_dust_return_pubkey(self, source, provided_pubkeys, encoding):
        """Return the pubkey to which dust from data outputs will be sent.

        This pubkey is used in multi-sig data outputs (as the only real pubkey) to
        make those the outputs spendable. It is derived from the source address, so
        that the dust is spendable by the creator of the transaction.
        """
        # Get hex dust return pubkey.
        # inject `script`
        if script.is_multisig(source):
            a, self_pubkeys, b = script.extract_array(
                self.backend.multisig_pubkeyhashes_to_pubkeys(source, provided_pubkeys)
            )
            dust_return_pubkey_hex = self_pubkeys[0]
        else:
            dust_return_pubkey_hex = self.backend.pubkeyhash_to_pubkey(source, provided_pubkeys)

        # Convert hex public key into the (binary) dust return pubkey.
        try:
            dust_return_pubkey = binascii.unhexlify(dust_return_pubkey_hex)
        except binascii.Error:
            raise script.InputError("Invalid private key.")  # noqa: B904

        return dust_return_pubkey

    def make_outkey_vin_txid(self, txid, vout):
        if (txid, vout) not in self.utxo_p2sh_encoding_locks_cache:
            txhex = self.backend.getrawtransaction(txid, verbose=False)
            self.utxo_p2sh_encoding_locks_cache.set((txid, vout), make_outkey_vin(txhex, vout))

        return self.utxo_p2sh_encoding_locks_cache.get((txid, vout))

    def construct_coin_selection(
        self,
        encoding,
        data_array,
        source,
        allow_unconfirmed_inputs,
        unspent_tx_hash,
        custom_inputs,
        fee_per_kb,
        estimate_fee_per_kb,
        estimate_fee_per_kb_nblocks,
        exact_fee,
        size_for_fee,
        fee_provided,
        destination_btc_out,
        data_btc_out,
        regular_dust_size,
        disable_utxo_locks,
    ):
        # Array of UTXOs, as retrieved by listunspent function from bitcoind
        if custom_inputs:
            use_inputs = unspent = custom_inputs
        else:
            if unspent_tx_hash is not None:
                unspent = self.backend.get_unspent_txouts(
                    source,
                    unconfirmed=allow_unconfirmed_inputs,
                    unspent_tx_hash=unspent_tx_hash,
                )
            else:
                unspent = self.backend.get_unspent_txouts(
                    source, unconfirmed=allow_unconfirmed_inputs
                )

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
                ):
                    filtered_unspent.append(output)
            unspent = filtered_unspent

            if encoding == "multisig":
                dust = self.default_multisig_dust_size
            else:
                dust = self.default_regular_dust_size

            unspent = self.backend.sort_unspent_txouts(unspent, dust_size=dust)
            # self.logger.debug(f"Sorted candidate UTXOs: {[print_coin(coin) for coin in unspent]}")
            use_inputs = unspent

        # use backend estimated fee_per_kb
        if estimate_fee_per_kb:
            estimated_fee_per_kb = self.backend.fee_per_kb(
                estimate_fee_per_kb_nblocks, config.ESTIMATE_FEE_MODE
            )
            if estimated_fee_per_kb is not None:
                fee_per_kb = max(
                    estimated_fee_per_kb, fee_per_kb
                )  # never drop below the default fee_per_kb

        self.logger.debug(f"Fee/KB {fee_per_kb / config.UNIT:.8f}")

        inputs = []
        btc_in = 0
        change_quantity = 0
        sufficient_funds = False
        final_fee = fee_per_kb
        desired_input_count = 1

        if encoding == "multisig" and data_array and ledger.enabled("bytespersigop"):
            desired_input_count = len(data_array) * 2

        # pop inputs until we can pay for the fee
        use_inputs_index = 0
        for coin in use_inputs:
            self.logger.debug(f"New input: {print_coin(coin)}")
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
                self.logger.debug(
                    f"final_fee inputs: {len(inputs)} size: {size} final_fee {final_fee}"
                )

            # Check if good.
            btc_out = destination_btc_out + data_btc_out
            change_quantity = btc_in - (btc_out + final_fee)
            self.logger.debug(
                f"Size: {size} Fee: {final_fee / config.UNIT:.8f} Change quantity: {change_quantity / config.UNIT:.8f} BTC"
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

            error_message = f"Insufficient {config.BTC} at address {source}. (Need approximately {total_btc_out / config.UNIT} {config.BTC}.)"
            if not allow_unconfirmed_inputs:
                error_message += " To spend unconfirmed coins, use the flag `--unconfirmed`. (Unconfirmed coins cannot be spent from multi‐sig addresses.)"
            raise exceptions.BalanceError(error_message)

        # Lock the source's inputs (UTXOs) chosen for this transaction
        if self.utxo_locks is not None and not disable_utxo_locks:
            if source not in self.utxo_locks:
                self.utxo_locks[source] = ThreadSafeTTLCache(
                    self.utxo_locks_per_address_maxsize, self.utxo_locks_max_age
                )

            for input in inputs:
                self.utxo_locks[source].set(make_outkey(input), input)

            # list_unspent = [make_outkey(coin) for coin in unspent]
            # list_used = [make_outkey(input) for input in inputs]
            # list_locked = list(self.utxo_locks[source].keys())
            # self.logger.debug(
            #     f"UTXO locks: Potentials ({len(unspent)}): {list_unspent}, Used: {list_used}, locked UTXOs: {list_locked}"
            # )

        # ensure inputs have scriptPubKey
        #   this is not provided by indexd
        inputs = self.backend.ensure_script_pub_key_for_inputs(inputs)

        return inputs, change_quantity, btc_in, final_fee

    def select_any_coin_from_source(
        self, source, allow_unconfirmed_inputs=True, disable_utxo_locks=False
    ):
        """Get the first (biggest) input from the source address"""

        # Array of UTXOs, as retrieved by listunspent function from bitcoind
        unspent = self.backend.get_unspent_txouts(source, unconfirmed=allow_unconfirmed_inputs)

        filter_unspents_utxo_locks = []
        if self.utxo_locks is not None and source in self.utxo_locks:
            filter_unspents_utxo_locks = self.utxo_locks[source].keys()

        # filter out any locked UTXOs to prevent creating transactions that spend the same UTXO when they're created at the same time
        filtered_unspent = []
        for output in unspent:
            if make_outkey(output) not in filter_unspents_utxo_locks:
                filtered_unspent.append(output)
        unspent = filtered_unspent

        # sort
        unspent = self.backend.sort_unspent_txouts(
            unspent, dust_size=config.DEFAULT_REGULAR_DUST_SIZE
        )

        # use the first input
        input = unspent[0]
        if input is None:
            return None

        # Lock the source's inputs (UTXOs) chosen for this transaction
        if self.utxo_locks is not None and not disable_utxo_locks:
            if source not in self.utxo_locks:
                # TODO: dont ref cache tools directly
                self.utxo_locks[source] = cachetools.TTLCache(
                    self.utxo_locks_per_address_maxsize, self.utxo_locks_max_age
                )

            self.utxo_locks[source].set(make_outkey(input), input)

        return input

    def construct(
        self,
        db,
        tx_info,
        encoding="auto",
        fee_per_kb=config.DEFAULT_FEE_PER_KB,
        estimate_fee_per_kb=None,
        estimate_fee_per_kb_nblocks=config.ESTIMATE_FEE_CONF_TARGET,
        regular_dust_size=config.DEFAULT_REGULAR_DUST_SIZE,
        multisig_dust_size=config.DEFAULT_MULTISIG_DUST_SIZE,
        op_return_value=config.DEFAULT_OP_RETURN_VALUE,
        exact_fee=None,
        fee_provided=0,
        provided_pubkeys=None,
        dust_return_pubkey=None,
        allow_unconfirmed_inputs=False,
        unspent_tx_hash=None,
        custom_inputs=None,
        disable_utxo_locks=False,
        extended_tx_info=False,
        old_style_api=None,
        segwit=False,
        p2sh_source_multisig_pubkeys=None,
        p2sh_source_multisig_pubkeys_required=None,
        p2sh_pretx_txid=None,
    ):
        if estimate_fee_per_kb is None:
            estimate_fee_per_kb = config.ESTIMATE_FEE_PER_KB

        # lazy assign from config, because when set as default it's evaluated before it's configured
        if old_style_api is None:
            old_style_api = config.OLD_STYLE_API

        (source, destination_outputs, data) = tx_info

        if dust_return_pubkey:
            dust_return_pubkey = binascii.unhexlify(dust_return_pubkey)

        if p2sh_source_multisig_pubkeys:
            p2sh_source_multisig_pubkeys = [
                binascii.unhexlify(p) for p in p2sh_source_multisig_pubkeys
            ]

        # Source.
        # If public key is necessary for construction of (unsigned)
        # transaction, use the public key provided, or find it from the
        # blockchain.
        if source:
            script.validate(source)

        source_is_p2sh = script.is_p2sh(source)

        # Normalize source
        if script.is_multisig(source):
            source_address = self.backend.multisig_pubkeyhashes_to_pubkeys(source, provided_pubkeys)
        else:
            source_address = source

        # Sanity checks.
        if exact_fee and not isinstance(exact_fee, int):
            raise exceptions.TransactionError("Exact fees must be in satoshis.")
        if not isinstance(fee_provided, int):
            raise exceptions.TransactionError("Fee provided must be in satoshis.")

        """Determine encoding method"""

        if data:
            desired_encoding = encoding
            # Data encoding methods (choose and validate).
            if desired_encoding == "auto":
                if len(data) + len(self.prefix) <= self.op_return_max_size:
                    encoding = "opreturn"
                else:
                    encoding = (
                        "p2sh"
                        if not old_style_api and ledger.enabled("p2sh_encoding")
                        else "multisig"
                    )  # p2sh is not possible with old_style_api

            elif desired_encoding == "p2sh" and not ledger.enabled("p2sh_encoding"):
                raise exceptions.TransactionError("P2SH encoding not enabled yet")

            elif encoding not in ("pubkeyhash", "multisig", "opreturn", "p2sh"):
                raise exceptions.TransactionError("Unknown encoding‐scheme.")
        else:
            # no data
            encoding = None
        self.logger.debug(f"Constructing {encoding} transaction from {source}.")

        """Destinations"""

        # Destination outputs.
        # Replace multi‐sig addresses with multi‐sig pubkeys. Check that the
        # destination output isn’t a dust output. Set null values to dust size.
        destination_outputs_new = []
        if encoding != "p2sh":
            for address, value in destination_outputs:
                # Value.
                if script.is_multisig(address):
                    dust_size = multisig_dust_size
                else:
                    dust_size = regular_dust_size
                if value == None:  # noqa: E711
                    value = dust_size  # noqa: PLW2901
                elif value < dust_size:
                    raise exceptions.TransactionError("Destination output is dust.")

                # Address.
                script.validate(address)
                if script.is_multisig(address):
                    destination_outputs_new.append(
                        (
                            self.backend.multisig_pubkeyhashes_to_pubkeys(
                                address, provided_pubkeys
                            ),
                            value,
                        )
                    )
                else:
                    destination_outputs_new.append((address, value))

        destination_outputs = destination_outputs_new
        destination_btc_out = sum([value for address, value in destination_outputs])

        """Data"""

        if data:
            # @TODO: p2sh encoding require signable dust key
            if encoding == "multisig":
                # dust_return_pubkey should be set or explicitly set to False to use the default configured for the node
                #  the default for the node is optional so could fail
                if (source_is_p2sh and dust_return_pubkey is None) or (
                    dust_return_pubkey is False and self.ps2h_dust_return_pubkey is None
                ):
                    raise exceptions.TransactionError(
                        "Can't use multisig encoding when source is P2SH and no dust_return_pubkey is provided."
                    )
                elif dust_return_pubkey is False:
                    dust_return_pubkey = binascii.unhexlify(self.ps2h_dust_return_pubkey)

            if not dust_return_pubkey:
                if encoding == "multisig" or encoding == "p2sh" and not source_is_p2sh:
                    dust_return_pubkey = self.get_dust_return_pubkey(
                        source, provided_pubkeys, encoding
                    )
                else:
                    dust_return_pubkey = None

            # Divide data into chunks.
            if encoding == "pubkeyhash":
                # Prefix is also a suffix here.
                chunk_size = 20 - 1 - 8
            elif encoding == "multisig":
                # Two pubkeys, minus length byte, minus prefix, minus two nonces,
                # minus two sign bytes.
                chunk_size = (33 * 2) - 1 - 8 - 2 - 2
            elif encoding == "p2sh":
                pubkeylength = -1
                if dust_return_pubkey is not None:
                    pubkeylength = len(dust_return_pubkey)

                chunk_size = p2sh_encoding.maximum_data_chunk_size(pubkeylength)
            elif encoding == "opreturn":
                chunk_size = config.OP_RETURN_MAX_SIZE
                if len(data) + len(self.prefix) > chunk_size:
                    raise exceptions.TransactionError("One `OP_RETURN` output per transaction.")
            data_array = list(chunks(data, chunk_size))

            # Data outputs.
            if encoding == "multisig":
                data_value = multisig_dust_size
            elif encoding == "p2sh":
                data_value = 0  # this will be calculated later
            elif encoding == "opreturn":
                data_value = op_return_value
            else:
                # Pay‐to‐PubKeyHash, e.g.
                data_value = regular_dust_size
            data_output = (data_array, data_value)

        else:
            data_value = 0
            data_array = []
            data_output = None
            dust_return_pubkey = None

        data_btc_out = data_value * len(data_array)
        self.logger.debug(
            f"data_btc_out={data_btc_out} (data_value={data_value} len(data_array)={len(data_array)})"
        )

        """Inputs"""
        btc_in = 0
        final_fee = 0
        # Calculate collective size of outputs, for fee calculation.
        p2pkhsize = 25 + 9
        if encoding == "multisig":
            data_output_size = 81  # 71 for the data
        elif encoding == "opreturn":
            # prefix + data + 10 bytes script overhead
            data_output_size = len(self.prefix) + 10
            if data is not None:
                data_output_size = data_output_size + len(data)
        else:
            data_output_size = p2pkhsize  # Pay‐to‐PubKeyHash (25 for the data?)

        if encoding == "p2sh":
            # calculate all the p2sh outputs
            size_for_fee, datatx_necessary_fee, data_value, data_btc_out = (
                p2sh_encoding.calculate_outputs(
                    destination_outputs, data_array, fee_per_kb, exact_fee
                )
            )
            # replace the data value
            data_output = (data_array, data_value)
        else:
            sum_data_output_size = len(data_array) * data_output_size
            size_for_fee = ((25 + 9) * len(destination_outputs)) + sum_data_output_size

        if not (encoding == "p2sh" and p2sh_pretx_txid):
            inputs, change_quantity, n_btc_in, n_final_fee = self.construct_coin_selection(
                encoding,
                data_array,
                source,
                allow_unconfirmed_inputs,
                unspent_tx_hash,
                custom_inputs,
                fee_per_kb,
                estimate_fee_per_kb,
                estimate_fee_per_kb_nblocks,
                exact_fee,
                size_for_fee,
                fee_provided,
                destination_btc_out,
                data_btc_out,
                regular_dust_size,
                disable_utxo_locks,
            )
            btc_in = n_btc_in
            final_fee = n_final_fee
        else:
            # when encoding is P2SH and the pretx txid is passed we can skip coinselection
            inputs, change_quantity = None, None

        """Finish"""

        if change_quantity:
            change_output = (source_address, change_quantity)
        else:
            change_output = None

        unsigned_pretx_hex = None
        unsigned_tx_hex = None

        pretx_txid = None
        if encoding == "p2sh":
            assert not (segwit and p2sh_pretx_txid)  # shouldn't do old style with segwit enabled

            if p2sh_pretx_txid:
                pretx_txid = (
                    p2sh_pretx_txid
                    if isinstance(p2sh_pretx_txid, bytes)
                    else binascii.unhexlify(p2sh_pretx_txid)
                )
                unsigned_pretx = None
            else:
                destination_value_sum = sum([value for (destination, value) in destination_outputs])
                source_value = destination_value_sum

                if change_output:
                    # add the difference between source and destination to the change
                    change_value = change_output[1] + (destination_value_sum - source_value)
                    change_output = (change_output[0], change_value)

                unsigned_pretx = serializer.serialise_p2sh_pretx(
                    inputs,
                    source=source_address,
                    source_value=source_value,
                    data_output=data_output,
                    change_output=change_output,
                    pubkey=dust_return_pubkey,
                    multisig_pubkeys=p2sh_source_multisig_pubkeys,
                    multisig_pubkeys_required=p2sh_source_multisig_pubkeys_required,
                )
                unsigned_pretx_hex = binascii.hexlify(unsigned_pretx).decode("utf-8")

            # with segwit we already know the txid and can return both
            if segwit:
                # pretx_txid = hashlib.sha256(unsigned_pretx).digest()  # this should be segwit txid
                ptx = CTransaction.stream_deserialize(
                    io.BytesIO(unsigned_pretx)
                )  # could be a non-segwit tx anyways
                txid_ba = bytearray(ptx.GetTxid())
                txid_ba.reverse()
                pretx_txid = bytes(txid_ba)  # gonna leave the malleability problem to upstream
                self.logger.debug(f"pretx_txid {pretx_txid}")
                print("pretx txid:", binascii.hexlify(pretx_txid))

            if unsigned_pretx:
                # we set a long lock on this, don't want other TXs to spend from it
                self.utxo_p2sh_encoding_locks.set(make_outkey_vin(unsigned_pretx, 0), True)

            # only generate the data TX if we have the pretx txId
            if pretx_txid:
                source_input = None
                if script.is_p2sh(source):
                    source_input = self.select_any_coin_from_source(source)
                    if not source_input:
                        raise exceptions.TransactionError(
                            "Unable to select source input for p2sh source address"
                        )

                unsigned_datatx = serializer.serialise_p2sh_datatx(
                    pretx_txid,
                    source=source_address,
                    source_input=source_input,
                    destination_outputs=destination_outputs,
                    data_output=data_output,
                    pubkey=dust_return_pubkey,
                    multisig_pubkeys=p2sh_source_multisig_pubkeys,
                    multisig_pubkeys_required=p2sh_source_multisig_pubkeys_required,
                )
                unsigned_datatx_hex = binascii.hexlify(unsigned_datatx).decode("utf-8")

                # let the rest of the code work it's magic on the data tx
                unsigned_tx_hex = unsigned_datatx_hex
            else:
                # we're just gonna return the pretx, it doesn't require any of the further checks
                self.logger.warning(f"old_style_api = {old_style_api}")
                return return_result([unsigned_pretx_hex], old_style_api=old_style_api)

        else:
            # Serialise inputs and outputs.
            unsigned_tx = serializer.serialise(
                encoding,
                inputs,
                destination_outputs,
                data_output,
                change_output,
                dust_return_pubkey=dust_return_pubkey,
            )
            unsigned_tx_hex = binascii.hexlify(unsigned_tx).decode("utf-8")

        """Sanity Check"""

        # Desired transaction info.
        (desired_source, desired_destination_outputs, desired_data) = tx_info
        desired_source = script.make_canonical(desired_source)
        desired_destination = (
            script.make_canonical(desired_destination_outputs[0][0])
            if desired_destination_outputs
            else ""
        )
        # NOTE: Include change in destinations for BTC transactions.
        # if change_output and not desired_data and desired_destination != config.UNSPENDABLE:
        #    if desired_destination == '':
        #        desired_destination = desired_source
        #    else:
        #        desired_destination += f'-{desired_source}'
        # NOTE
        if desired_data == None:  # noqa: E711
            desired_data = b""

        # Parsed transaction info.
        try:
            if pretx_txid and unsigned_pretx:
                self.backend.cache_pretx(pretx_txid, unsigned_pretx)
            parsed_source, parsed_destination, x, y, parsed_data, extra = (
                # TODO: inject
                gettxinfo.get_tx_info_new(
                    db,
                    BlockchainParser().deserialize_tx(unsigned_tx_hex),
                    ledger.CURRENT_BLOCK_INDEX,
                    p2sh_is_segwit=script.is_bech32(desired_source),
                    composing=True,
                )
            )

            if encoding == "p2sh":
                # make_canonical can't determine the address, so we blindly change the desired to the parsed
                desired_source = parsed_source

            if pretx_txid and unsigned_pretx:
                self.backend.clear_pretx(pretx_txid)
        except exceptions.BTCOnlyError:
            # Skip BTC‐only transactions.
            if extended_tx_info:
                return {
                    "btc_in": btc_in,
                    "btc_out": destination_btc_out + data_btc_out,
                    "btc_change": change_quantity,
                    "btc_fee": final_fee,
                    "tx_hex": unsigned_tx_hex,
                }
            self.logger.debug("BTC-ONLY")
            return return_result([unsigned_pretx_hex, unsigned_tx_hex], old_style_api=old_style_api)
        desired_source = script.make_canonical(desired_source)

        # Check desired info against parsed info.
        desired = (desired_source, desired_destination, desired_data)
        parsed = (parsed_source, parsed_destination, parsed_data)
        if desired != parsed:
            # Unlock (revert) UTXO locks
            if self.utxo_locks is not None and inputs:
                for input in inputs:
                    self.utxo_locks[source].pop(make_outkey(input), None)

            raise exceptions.TransactionError(
                f"Constructed transaction does not parse correctly: {desired} ≠ {parsed}"
            )

        if extended_tx_info:
            return {
                "btc_in": btc_in,
                "btc_out": destination_btc_out + data_btc_out,
                "btc_change": change_quantity,
                "btc_fee": final_fee,
                "tx_hex": unsigned_tx_hex,
            }
        return return_result([unsigned_pretx_hex, unsigned_tx_hex], old_style_api=old_style_api)


# UTILS


def print_coin(coin):
    return f"amount: {coin['amount']:.8f}; txid: {coin['txid']}; vout: {coin['vout']}; confirmations: {coin.get('confirmations', '?')}"  # simplify and make deterministic


def chunks(l, n):  # noqa: E741
    """Yield successive n‐sized chunks from l."""
    for i in range(0, len(l), n):
        yield l[i : i + n]


def make_outkey(output):
    return f"{output['txid']}{output['vout']}"


def make_outkey_vin(txhex, vout):
    txbin = binascii.unhexlify(txhex) if isinstance(txhex, str) else txhex
    assert isinstance(vout, int)

    tx = bitcoinlib.core.CTransaction.deserialize(txbin)
    outkey = [(vin.prevout.hash, vin.prevout.n) for vin in tx.vin]
    outkey = hashlib.sha256((f"{outkey}{vout}").encode("ascii")).digest()

    return outkey


def return_result(tx_hexes, old_style_api):
    tx_hexes = list(filter(None, tx_hexes))  # filter out None

    if old_style_api:
        if len(tx_hexes) != 1:
            raise Exception("Can't do 2 TXs with old_style_api")

        return tx_hexes[0]
    else:
        if len(tx_hexes) == 1:
            return tx_hexes[0]
        else:
            return tx_hexes


# TODO: this should be lifted
def get_dust_return_pubkey(source, provided_pubkeys, encoding):
    """Return the pubkey to which dust from data outputs will be sent.

    This pubkey is used in multi-sig data outputs (as the only real pubkey) to
    make those the outputs spendable. It is derived from the source address, so
    that the dust is spendable by the creator of the transaction.
    """
    # Get hex dust return pubkey.
    if script.is_multisig(source):
        a, self_pubkeys, b = script.extract_array(
            backend.multisig_pubkeyhashes_to_pubkeys(source, provided_pubkeys)
        )
        dust_return_pubkey_hex = self_pubkeys[0]
    else:
        dust_return_pubkey_hex = backend.pubkeyhash_to_pubkey(source, provided_pubkeys)

    # Convert hex public key into the (binary) dust return pubkey.
    try:
        dust_return_pubkey = binascii.unhexlify(dust_return_pubkey_hex)
    except binascii.Error:
        raise script.InputError("Invalid private key.")  # noqa: B904

    return dust_return_pubkey


COMPOSE_COMMONS_ARGS = {
    "encoding": (str, "auto", "The encoding method to use"),
    "fee_per_kb": (
        int,
        None,
        "The fee per kilobyte of transaction data constant that the server uses when deciding on the dynamic fee to use (in satoshi)",
    ),
    "regular_dust_size": (
        int,
        config.DEFAULT_REGULAR_DUST_SIZE,
        "Specify (in satoshi) to override the (dust) amount of BTC used for each non-(bare) multisig output.",
    ),
    "multisig_dust_size": (
        int,
        config.DEFAULT_MULTISIG_DUST_SIZE,
        "Specify (in satoshi) to override the (dust) amount of BTC used for each (bare) multisig output",
    ),
    "op_return_value": (
        int,
        config.DEFAULT_OP_RETURN_VALUE,
        "The value (in satoshis) to use with any OP_RETURN outputs in the generated transaction. Defaults to 0. Don't use this, unless you like throwing your money away",
    ),
    "pubkey": (
        str,
        None,
        "The hexadecimal public key of the source address (or a list of the keys, if multi-sig). Required when using encoding parameter values of multisig or pubkeyhash.",
    ),
    "allow_unconfirmed_inputs": (
        bool,
        False,
        "Set to true to allow this transaction to utilize unconfirmed UTXOs as inputs",
    ),
    "fee": (
        int,
        None,
        "If you'd like to specify a custom miners' fee, specify it here (in satoshi). Leave as default for the server to automatically choose",
    ),
    "fee_provided": (
        int,
        0,
        "If you would like to specify a maximum fee (up to and including which may be used as the transaction fee), specify it here (in satoshi). This differs from fee in that this is an upper bound value, which fee is an exact value",
    ),
    "unspent_tx_hash": (
        str,
        None,
        "When compiling the UTXOs to use as inputs for the transaction being created, only consider unspent outputs from this specific transaction hash. Defaults to null to consider all UTXOs for the address. Do not use this parameter if you are specifying custom_inputs",
    ),
    "dust_return_pubkey": (
        str,
        None,
        "The dust return pubkey is used in multi-sig data outputs (as the only real pubkey) to make those the outputs spendable. By default, this pubkey is taken from the pubkey used in the first transaction input. However, it can be overridden here (and is required to be specified if a P2SH input is used and multisig is used as the data output encoding.) If specified, specify the public key (in hex format) where dust will be returned to so that it can be reclaimed. Only valid/useful when used with transactions that utilize multisig data encoding. Note that if this value is set to false, this instructs counterparty-server to use the default dust return pubkey configured at the node level. If this default is not set at the node level, the call will generate an exception",
    ),
    "disable_utxo_locks": (
        bool,
        False,
        "By default, UTXO's utilized when creating a transaction are 'locked' for a few seconds, to prevent a case where rapidly generating create_ calls reuse UTXOs due to their spent status not being updated in bitcoind yet. Specify true for this parameter to disable this behavior, and not temporarily lock UTXOs",
    ),
    "extended_tx_info": (
        bool,
        False,
        "When this is not specified or false, the create_ calls return only a hex-encoded string. If this is true, the create_ calls return a data object with the following keys: tx_hex, btc_in, btc_out, btc_change, and btc_fee",
    ),
    "p2sh_pretx_txid": (
        str,
        None,
        "The previous transaction txid for a two part P2SH message. This txid must be taken from the signed transaction",
    ),
    "old_style_api": (bool, True, "Use the old style API"),
    "segwit": (bool, False, "Use segwit"),
}


def split_compose_arams(**kwargs):
    transaction_args = {}
    common_args = {}
    private_key_wif = None
    for key, value in kwargs.items():
        if key in COMPOSE_COMMONS_ARGS:
            common_args[key] = value
        elif key == "privkey":
            private_key_wif = value
        else:
            transaction_args[key] = value
    return transaction_args, common_args, private_key_wif


def get_default_args(func):
    signature = inspect.signature(func)
    return {
        k: v.default
        for k, v in signature.parameters.items()
        if v.default is not inspect.Parameter.empty
    }


def compose_transaction(
    db,
    name,
    params,
    encoding="auto",
    fee_per_kb=None,
    estimate_fee_per_kb=None,
    regular_dust_size=config.DEFAULT_REGULAR_DUST_SIZE,
    multisig_dust_size=config.DEFAULT_MULTISIG_DUST_SIZE,
    op_return_value=config.DEFAULT_OP_RETURN_VALUE,
    pubkey=None,
    allow_unconfirmed_inputs=False,
    fee=None,
    fee_provided=0,
    unspent_tx_hash=None,
    custom_inputs=None,
    dust_return_pubkey=None,
    disable_utxo_locks=False,
    extended_tx_info=False,
    p2sh_source_multisig_pubkeys=None,
    p2sh_source_multisig_pubkeys_required=None,
    p2sh_pretx_txid=None,
    old_style_api=True,
    segwit=False,
    api_v1=False,
):
    """Create and return a transaction."""

    # Get provided pubkeys.
    if isinstance(pubkey, str):
        provided_pubkeys = [pubkey]
    elif isinstance(pubkey, list):
        provided_pubkeys = pubkey
    elif pubkey is None:
        provided_pubkeys = []
    else:
        raise exceptions.TransactionError("Invalid pubkey.")

    # Get additional pubkeys from `source` and `destination` params.
    # Convert `source` and `destination` to pubkeyhash form.
    for address_name in ["source", "destination"]:
        if address_name in params:
            address = params[address_name]
            if isinstance(address, list):
                # pkhshs = []
                # for addr in address:
                #    provided_pubkeys += script.extract_pubkeys(addr)
                #    pkhshs.append(script.make_pubkeyhash(addr))
                # params[address_name] = pkhshs
                pass
            else:
                provided_pubkeys += script.extract_pubkeys(address)
                params[address_name] = script.make_pubkeyhash(address)

    # Check validity of collected pubkeys.
    for pubkey in provided_pubkeys:
        if not script.is_fully_valid(binascii.unhexlify(pubkey)):
            raise script.AddressError(f"invalid public key: {pubkey}")

    compose_method = sys.modules[f"counterpartycore.lib.messages.{name}"].compose
    compose_params = inspect.getfullargspec(compose_method)[0]
    missing_params = [p for p in compose_params if p not in params and p != "db"]
    if api_v1:
        for param in missing_params:
            params[param] = None
    else:
        if len(missing_params) > 0:
            default_values = get_default_args(compose_method)
            for param in missing_params:
                if param in default_values:
                    params[param] = default_values[param]
                else:
                    raise exceptions.ComposeError(
                        f"missing parameters: {', '.join(missing_params)}"
                    )

    # dont override fee_per_kb if specified
    if fee_per_kb is not None:
        estimate_fee_per_kb = False
    else:
        fee_per_kb = config.DEFAULT_FEE_PER_KB

    if "extended_tx_info" in params:
        extended_tx_info = params["extended_tx_info"]
        del params["extended_tx_info"]

    if "old_style_api" in params:
        old_style_api = params["old_style_api"]
        del params["old_style_api"]

    if "segwit" in params:
        segwit = params["segwit"]
        del params["segwit"]

    tx_info = compose_method(db, **params)
    initialise(db)
    return construct(
        db,
        tx_info,
        encoding=encoding,
        fee_per_kb=fee_per_kb,
        estimate_fee_per_kb=estimate_fee_per_kb,
        regular_dust_size=regular_dust_size,
        multisig_dust_size=multisig_dust_size,
        op_return_value=op_return_value,
        provided_pubkeys=provided_pubkeys,
        allow_unconfirmed_inputs=allow_unconfirmed_inputs,
        exact_fee=fee,
        fee_provided=fee_provided,
        unspent_tx_hash=unspent_tx_hash,
        custom_inputs=custom_inputs,
        dust_return_pubkey=dust_return_pubkey,
        disable_utxo_locks=disable_utxo_locks,
        extended_tx_info=extended_tx_info,
        p2sh_source_multisig_pubkeys=p2sh_source_multisig_pubkeys,
        p2sh_source_multisig_pubkeys_required=p2sh_source_multisig_pubkeys_required,
        p2sh_pretx_txid=p2sh_pretx_txid,
        old_style_api=old_style_api,
        segwit=segwit,
    )


COMPOSABLE_TRANSACTIONS = [
    "bet",
    "broadcast",
    "btcpay",
    "burn",
    "cancel",
    "destroy",
    "dispenser",
    "dividend",
    "issuance",
    "mpma",
    "order",
    "send",
    "sweep",
]


def compose(db, source, transaction_name, api_v1=False, **kwargs):
    if transaction_name not in COMPOSABLE_TRANSACTIONS:
        raise exceptions.TransactionError("Transaction type not composable.")
    transaction_args, common_args, _ = split_compose_arams(**kwargs)
    transaction_args["source"] = source
    return compose_transaction(
        db, name=transaction_name, params=transaction_args, api_v1=api_v1, **common_args
    )


def compose_bet(
    db,
    address: str,
    feed_address: str,
    bet_type: int,
    deadline: int,
    wager_quantity: int,
    counterwager_quantity: int,
    expiration: int,
    leverage: int = 5040,
    target_value: float = None,
    **construct_args,
):
    """
    Composes a transaction to issue a bet against a feed.
    :param address: The address that will make the bet
    :param feed_address: The address that hosts the feed to be bet on
    :param bet_type: Bet 0 for Bullish CFD (deprecated), 1 for Bearish CFD (deprecated), 2 for Equal, 3 for NotEqual
    :param deadline: The time at which the bet should be decided/settled, in Unix time (seconds since epoch)
    :param wager_quantity: The quantities of XCP to wager (in satoshis, hence integer).
    :param counterwager_quantity: The minimum quantities of XCP to be wagered against, for the bets to match
    :param target_value: Target value for Equal/NotEqual bet
    :param leverage: Leverage, as a fraction of 5040
    :param expiration: The number of blocks after which the bet expires if it remains unmatched
    """
    return compose_transaction(
        db,
        name="bet",
        params={
            "source": address,
            "feed_address": feed_address,
            "bet_type": bet_type,
            "deadline": deadline,
            "wager_quantity": wager_quantity,
            "counterwager_quantity": counterwager_quantity,
            "target_value": target_value,
            "leverage": leverage,
            "expiration": expiration,
        },
        **construct_args,
    )


def compose_broadcast(
    db, address: str, timestamp: int, value: float, fee_fraction: float, text: str, **construct_args
):
    """
    Composes a transaction to broadcast textual and numerical information to the network.
    :param address: The address that will be sending (must have the necessary quantity of the specified asset)
    :param timestamp: The timestamp of the broadcast, in Unix time
    :param value: Numerical value of the broadcast
    :param fee_fraction: How much of every bet on this feed should go to its operator; a fraction of 1, (i.e. 0.05 is five percent)
    :param text: The textual part of the broadcast
    """
    return compose_transaction(
        db,
        name="broadcast",
        params={
            "source": address,
            "timestamp": timestamp,
            "value": value,
            "fee_fraction": fee_fraction,
            "text": text,
        },
        **construct_args,
    )


def compose_btcpay(db, address: str, order_match_id: str, **construct_args):
    """
    Composes a transaction to pay for a BTC order match.
    :param address: The address that will be sending the payment
    :param order_match_id: The ID of the order match to pay for
    """
    return compose_transaction(
        db,
        name="btcpay",
        params={"source": address, "order_match_id": order_match_id},
        **construct_args,
    )


def compose_burn(db, address: str, quantity: int, overburn: bool = False, **construct_args):
    """
    Composes a transaction to burn a given quantity of BTC for XCP (on mainnet, possible between blocks 278310 and 283810; on testnet it is still available).
    :param address: The address with the BTC to burn
    :param quantity: The quantities of BTC to burn (1 BTC maximum burn per address)
    :param overburn: Whether to allow the burn to exceed 1 BTC for the address
    """
    return compose_transaction(
        db,
        name="burn",
        params={"source": address, "quantity": quantity, "overburn": overburn},
        **construct_args,
    )


def compose_cancel(db, address: str, offer_hash: str, **construct_args):
    """
    Composes a transaction to cancel an open order or bet.
    :param address: The address that placed the order/bet to be cancelled
    :param offer_hash: The hash of the order/bet to be cancelled
    """
    return compose_transaction(
        db,
        name="cancel",
        params={"source": address, "offer_hash": offer_hash},
        **construct_args,
    )


def compose_destroy(db, address: str, asset: str, quantity: int, tag: str, **construct_args):
    """
    Composes a transaction to destroy a quantity of an asset.
    :param address: The address that will be sending the asset to be destroyed
    :param asset: The asset to be destroyed
    :param quantity: The quantity of the asset to be destroyed
    :param tag: A tag for the destruction
    """
    return compose_transaction(
        db,
        name="destroy",
        params={"source": address, "asset": asset, "quantity": quantity, "tag": tag},
        **construct_args,
    )


def compose_dispenser(
    db,
    address: str,
    asset: str,
    give_quantity: int,
    escrow_quantity: int,
    mainchainrate: int,
    status: int,
    open_address: str = None,
    oracle_address: str = None,
    **construct_args,
):
    """
    Opens or closes a dispenser for a given asset at a given rate of main chain asset (BTC). Escrowed quantity on open must be equal or greater than give_quantity. It is suggested that you escrow multiples of give_quantity to ease dispenser operation.
    :param address: The address that will be dispensing (must have the necessary escrow_quantity of the specified asset)
    :param asset: The asset or subasset to dispense
    :param give_quantity: The quantity of the asset to dispense
    :param escrow_quantity: The quantity of the asset to reserve for this dispenser
    :param mainchainrate: The quantity of the main chain asset (BTC) per dispensed portion
    :param status: The state of the dispenser. 0 for open, 1 for open using open_address, 10 for closed
    :param open_address: The address that you would like to open the dispenser on
    :param oracle_address: The address that you would like to use as a price oracle for this dispenser
    """
    return compose_transaction(
        db,
        name="dispenser",
        params={
            "source": address,
            "asset": asset,
            "give_quantity": give_quantity,
            "escrow_quantity": escrow_quantity,
            "mainchainrate": mainchainrate,
            "status": status,
            "open_address": open_address,
            "oracle_address": oracle_address,
        },
        **construct_args,
    )


def compose_dividend(
    db, address: str, quantity_per_unit: int, asset: str, dividend_asset: str, **construct_args
):
    """
    Composes a transaction to issue a dividend to holders of a given asset.
    :param address: The address that will be issuing the dividend (must have the ownership of the asset which the dividend is being issued on)
    :param quantity_per_unit: The amount of dividend_asset rewarded
    :param asset: The asset or subasset that the dividends are being rewarded on
    :param dividend_asset: The asset or subasset that the dividends are paid in
    """
    return compose_transaction(
        db,
        name="dividend",
        params={
            "source": address,
            "quantity_per_unit": quantity_per_unit,
            "asset": asset,
            "dividend_asset": dividend_asset,
        },
        **construct_args,
    )


def compose_issuance(
    db,
    address: str,
    asset: str,
    quantity: int,
    transfer_destination: str = None,
    divisible: bool = True,
    lock: bool = False,
    reset: bool = False,
    description: str = None,
    **construct_args,
):
    """
    Composes a transaction to Issue a new asset, issue more of an existing asset, lock an asset, reset existing supply, or transfer the ownership of an asset.
    :param address: The address that will be issuing or transfering the asset
    :param asset: The assets to issue or transfer. This can also be a subasset longname for new subasset issuances
    :param quantity: The quantity of the asset to issue (set to 0 if transferring an asset)
    :param transfer_destination: The address to receive the asset
    :param divisible: Whether this asset is divisible or not (if a transfer, this value must match the value specified when the asset was originally issued)
    :param lock: Whether this issuance should lock supply of this asset forever
    :param reset: Wether this issuance should reset any existing supply
    :param description: A textual description for the asset
    """
    return compose_transaction(
        db,
        name="issuance",
        params={
            "source": address,
            "asset": asset,
            "quantity": quantity,
            "transfer_destination": transfer_destination,
            "divisible": divisible,
            "lock": lock,
            "reset": reset,
            "description": description,
        },
        **construct_args,
    )


def compose_mpma(
    db,
    source: str,
    assets: str,
    destinations: str,
    quantities: str,
    memo: str,
    memo_is_hex: bool,
    **construct_args,
):
    """
    Composes a transaction to send multiple payments to multiple addresses.
    :param source: The address that will be sending (must have the necessary quantity of the specified asset)
    :param assets: comma-separated list of assets to send
    :param destinations: comma-separated list of addresses to send to
    :param quantities: comma-separated list of quantities to send
    :param memo: The Memo associated with this transaction
    :param memo_is_hex: Whether the memo field is a hexadecimal string
    """
    asset_list = assets.split(",")
    destination_list = destinations.split(",")
    quantity_list = quantities.split(",")
    if len(asset_list) != len(destination_list) or len(asset_list) != len(quantity_list):
        raise exceptions.ComposeError(
            "The number of assets, destinations, and quantities must be equal"
        )
    for quantity in quantity_list:
        if not quantity.isdigit():
            raise exceptions.ComposeError("Quantity must be an integer")
    asset_dest_quant_list = list(zip(asset_list, destination_list, quantity_list))

    return compose_transaction(
        db,
        name="version.mpma",
        params={
            "source": source,
            "asset_dest_quant_list": asset_dest_quant_list,
            "memo": memo,
            "memo_is_hex": memo_is_hex,
        },
        **construct_args,
    )


def compose_order(
    db,
    address: str,
    give_asset: str,
    give_quantity: int,
    get_asset: str,
    get_quantity: int,
    expiration: int,
    fee_required: int,
    **construct_args,
):
    """
    Composes a transaction to place an order on the distributed exchange.
    :param address: The address that will be issuing the order request (must have the necessary quantity of the specified asset to give)
    :param give_asset: The asset that will be given in the trade
    :param give_quantity: The quantity of the asset that will be given
    :param get_asset: The asset that will be received in the trade
    :param get_quantity: The quantity of the asset that will be received
    :param expiration: The number of blocks for which the order should be valid
    :param fee_required: The miners’ fee required to be paid by orders for them to match this one; in BTC; required only if buying BTC (may be zero, though)
    """
    return compose_transaction(
        db,
        name="order",
        params={
            "source": address,
            "give_asset": give_asset,
            "give_quantity": give_quantity,
            "get_asset": get_asset,
            "get_quantity": get_quantity,
            "expiration": expiration,
            "fee_required": fee_required,
        },
        **construct_args,
    )


def compose_send(
    db,
    address: str,
    destination: str,
    asset: str,
    quantity: int,
    memo: str = None,
    memo_is_hex: bool = False,
    use_enhanced_send: bool = True,
    **construct_args,
):
    """
    Composes a transaction to send a quantity of an asset to another address.
    :param address: The address that will be sending (must have the necessary quantity of the specified asset)
    :param destination: The address that will be receiving the asset
    :param asset: The asset or subasset to send
    :param quantity: The quantity of the asset to send
    :param memo: The Memo associated with this transaction
    :param memo_is_hex: Whether the memo field is a hexadecimal string
    :param use_enhanced_send: If this is false, the construct a legacy transaction sending bitcoin dust
    """
    return compose_transaction(
        db,
        name="send",
        params={
            "source": address,
            "destination": destination,
            "asset": asset,
            "quantity": quantity,
            "memo": memo,
            "memo_is_hex": memo_is_hex,
            "use_enhanced_send": use_enhanced_send,
        },
        **construct_args,
    )


def compose_sweep(db, address: str, destination: str, flags: int, memo: str, **construct_args):
    """
    Composes a transaction to Sends all assets and/or transfer ownerships to a destination address.
    :param address: The address that will be sending
    :param destination: The address to receive the assets and/or ownerships
    :param flags: An OR mask of flags indicating how the sweep should be processed. Possible flags are:
                    - FLAG_BALANCES: (integer) 1, specifies that all balances should be transferred.
                    - FLAG_OWNERSHIP: (integer) 2, specifies that all ownerships should be transferred.
                    - FLAG_BINARY_MEMO: (integer) 4, specifies that the memo is in binary/hex form.
    :param memo: The Memo associated with this transaction
    """
    return compose_transaction(
        db,
        name="sweep",
        params={
            "source": address,
            "destination": destination,
            "flags": flags,
            "memo": memo,
        },
        **construct_args,
    )


def info(db, rawtransaction: str, block_index: int = None):
    """
    Returns Counterparty information from a raw transaction in hex format.
    :param rawtransaction: Raw transaction in hex format
    :param block_index: Block index mandatory for transactions before block 335000
    """
    source, destination, btc_amount, fee, data, extra = gettxinfo.get_tx_info(
        db, BlockchainParser().deserialize_tx(rawtransaction), block_index=block_index
    )
    return {
        "source": source,
        "destination": destination,
        "btc_amount": btc_amount,
        "fee": fee,
        "data": util.hexlify(data) if data else "",
    }


def unpack(db, datahex: str, block_index: int = None):
    """
    Unpacks Counterparty data in hex format and returns the message type and data.
    :param datahex: Data in hex format
    :param block_index: Block index of the transaction containing this data
    """
    data = binascii.unhexlify(datahex)
    message_type_id, message = message_type.unpack(data)
    block_index = block_index or ledger.CURRENT_BLOCK_INDEX

    issuance_ids = [
        messages.issuance.ID,
        messages.issuance.LR_ISSUANCE_ID,
        messages.issuance.SUBASSET_ID,
        messages.issuance.LR_SUBASSET_ID,
    ]

    # Unknown message type
    message_data = {"error": "Unknown message type"}
    # Bet
    if message_type_id == messages.bet.ID:
        message_type_name = "bet"
        message_data = messages.bet.unpack(message, return_dict=True)
    # Broadcast
    elif message_type_id == messages.broadcast.ID:
        message_type_name = "broadcast"
        message_data = messages.broadcast.unpack(message, block_index, return_dict=True)
    # BTCPay
    elif message_type_id == messages.btcpay.ID:
        message_type_name = "btcpay"
        message_data = messages.btcpay.unpack(message, return_dict=True)
    # Cancel
    elif message_type_id == messages.cancel.ID:
        message_type_name = "cancel"
        message_data = messages.cancel.unpack(message, return_dict=True)
    # Destroy
    elif message_type_id == messages.destroy.ID:
        message_type_name = "destroy"
        message_data = messages.destroy.unpack(db, message, return_dict=True)
    # Dispenser
    elif message_type_id == messages.dispenser.ID:
        message_type_name = "dispenser"
        message_data = messages.dispenser.unpack(message, return_dict=True)
    # Dividend
    elif message_type_id == messages.dividend.ID:
        message_type_name = "dividend"
        message_data = messages.dividend.unpack(db, message, block_index, return_dict=True)
    # Issuance
    elif message_type_id in issuance_ids:
        message_type_name = "issuance"
        message_data = messages.issuance.unpack(
            db, message, message_type_id, block_index, return_dict=True
        )
    # Order
    elif message_type_id == messages.order.ID:
        message_type_name = "order"
        message_data = messages.order.unpack(db, message, block_index, return_dict=True)
    # Send
    elif message_type_id == messages.send.ID:
        message_type_name = "send"
        message_data = messages.send.unpack(db, message, block_index)
    # Enhanced send
    elif message_type_id == messages.versions.enhanced_send.ID:
        message_type_name = "enhanced_send"
        message_data = messages.versions.enhanced_send.unpack(message, block_index)
    # MPMA send
    elif message_type_id == messages.versions.mpma.ID:
        message_type_name = "mpma_send"
        message_data = messages.versions.mpma.unpack(message, block_index)
    # RPS
    elif message_type_id == messages.rps.ID:
        message_type_name = "rps"
        message_data = messages.rps.unpack(message, return_dict=True)
    # RPS Resolve
    elif message_type_id == messages.rpsresolve.ID:
        message_type_name = "rpsresolve"
        message_data = messages.rpsresolve.unpack(message, return_dict=True)
    # Sweep
    elif message_type_id == messages.sweep.ID:
        message_type_name = "sweep"
        message_data = messages.sweep.unpack(message)

    return {
        "message_type": message_type_name,
        "message_type_id": message_type_id,
        "message_data": message_data,
    }
