"""
Construct and serialize the Bitcoin transactions that are Counterparty transactions.

This module contains no consensus‐critical code.
"""

import os
import sys
import binascii
import json
import hashlib
import re
import time
import decimal
import logging
logger = logging.getLogger(__name__)
import requests
import bitcoin as bitcoinlib
from bitcoin.core.script import CScript
from bitcoin.core import x
from bitcoin.core import b2lx
import cachetools

from counterpartylib.lib import config
from counterpartylib.lib import exceptions
from counterpartylib.lib import util
from counterpartylib.lib import script
from counterpartylib.lib import backend
from counterpartylib.lib import arc4
from counterpartylib.lib.transaction_helper import serializer

from counterpartylib.lib.transaction_helper import serializer

from counterpartylib.lib.transaction_helper import serializer

# Constants
OP_RETURN = b'\x6a'
OP_PUSHDATA1 = b'\x4c'
OP_DUP = b'\x76'
OP_HASH160 = b'\xa9'
OP_EQUALVERIFY = b'\x88'
OP_CHECKSIG = b'\xac'
OP_1 = b'\x51'
OP_2 = b'\x52'
OP_3 = b'\x53'
OP_CHECKMULTISIG = b'\xae'
OP_EQUAL = b'\x87'

D = decimal.Decimal

# UTXO_LOCKS is None or DictCache per address
UTXO_LOCKS = None
# set higher than the max number of UTXOs we should expect to
# manage in an aging cache for any one source address, at any one period
UTXO_LOCKS_PER_ADDRESS_MAXSIZE = 5000

# UTXO_P2SH_ENCODING_LOCKS is TTLCache for UTXOs that are used for chaining p2sh encoding
#  instead of a simple (txid, vout) key we use [(vin.prevout.hash, vin.prevout.n) for vin tx1.vin]
UTXO_P2SH_ENCODING_LOCKS = None
# we cache the make_outkey_vin to avoid having to fetch raw txs too often
UTXO_P2SH_ENCODING_LOCKS_CACHE = None


def initialise():
    global UTXO_LOCKS, UTXO_P2SH_ENCODING_LOCKS, UTXO_P2SH_ENCODING_LOCKS_CACHE

    if config.UTXO_LOCKS_MAX_ADDRESSES > 0:  # initialize if configured
        UTXO_LOCKS = util.DictCache(size=config.UTXO_LOCKS_MAX_ADDRESSES)

    UTXO_P2SH_ENCODING_LOCKS = cachetools.TTLCache(10000, 180)
    UTXO_P2SH_ENCODING_LOCKS_CACHE = cachetools.TTLCache(1000, 600)


def print_coin(coin):
    return 'amount: {:.8f}; txid: {}; vout: {}; confirmations: {}'.format(coin['amount'], coin['txid'], coin['vout'], coin.get('confirmations', '?')) # simplify and make deterministic


def chunks(l, n):
    """ Yield successive n‐sized chunks from l.
    """
    for i in range(0, len(l), n):
        yield l[i:i+n]


def make_outkey(output):
    return '{}{}'.format(output['txid'], output['vout'])


def make_outkey_vin_txid(txid, vout):
    global UTXO_P2SH_ENCODING_LOCKS_CACHE

    if (txid, vout) not in UTXO_P2SH_ENCODING_LOCKS_CACHE:
        txhex = backend.getrawtransaction(txid, verbose=False)
        UTXO_P2SH_ENCODING_LOCKS_CACHE[(txid, vout)] = make_outkey_vin(txhex, vout)

    return UTXO_P2SH_ENCODING_LOCKS_CACHE[(txid, vout)]


def make_outkey_vin(txhex, vout):
    txbin = binascii.unhexlify(txhex) if isinstance(txhex, str) else txhex
    assert isinstance(vout, int)

    tx = bitcoinlib.core.CTransaction.deserialize(txbin)
    outkey = [(vin.prevout.hash, vin.prevout.n) for vin in tx.vin]
    outkey = hashlib.sha256(("%s%s" % (outkey, vout)).encode('ascii')).digest()

    return outkey


def get_dust_return_pubkey(source, provided_pubkeys, encoding):
    """Return the pubkey to which dust from data outputs will be sent.

    This pubkey is used in multi-sig data outputs (as the only real pubkey) to
    make those the outputs spendable. It is derived from the source address, so
    that the dust is spendable by the creator of the transaction.
    """
    # Get hex dust return pubkey.
    if script.is_multisig(source):
        a, self_pubkeys, b = script.extract_array(backend.multisig_pubkeyhashes_to_pubkeys(source, provided_pubkeys))
        dust_return_pubkey_hex = self_pubkeys[0]
    else:
        dust_return_pubkey_hex = backend.pubkeyhash_to_pubkey(source, provided_pubkeys)

    # Convert hex public key into the (binary) dust return pubkey.
    try:
        dust_return_pubkey = binascii.unhexlify(dust_return_pubkey_hex)
    except binascii.Error:
        raise script.InputError('Invalid private key.')

    return dust_return_pubkey


def construct_coin_selection(source, allow_unconfirmed_inputs, unspent_tx_hash, custom_inputs,
                             fee_per_kb, exact_fee, size_for_fee, fee_provided, destination_btc_out, data_btc_out,
                             regular_dust_size, disable_utxo_locks):

    global UTXO_LOCKS, UTXO_P2SH_ENCODING_LOCKS

    # Array of UTXOs, as retrieved by listunspent function from bitcoind
    use_inputs = custom_inputs
    unspent = []
    if custom_inputs is None:
        if unspent_tx_hash is not None:
            unspent = backend.get_unspent_txouts(source, unconfirmed=allow_unconfirmed_inputs, unspent_tx_hash=unspent_tx_hash)
        else:
            unspent = backend.get_unspent_txouts(source, unconfirmed=allow_unconfirmed_inputs)

        filter_unspents_utxo_locks = []
        if UTXO_LOCKS is not None and source in UTXO_LOCKS:
            filter_unspents_utxo_locks = UTXO_LOCKS[source].keys()
        filter_unspents_p2sh_locks = UTXO_P2SH_ENCODING_LOCKS.keys()

        # filter out any locked UTXOs to prevent creating transactions that spend the same UTXO when they're created at the same time
        filtered_unspent = []
        for output in unspent:
            if make_outkey(output) not in filter_unspents_utxo_locks and make_outkey_vin_txid(output['txid'], output['vout']) not in filter_unspents_p2sh_locks:
                filtered_unspent.append(output)
        unspent = filtered_unspent

        unspent = backend.sort_unspent_txouts(unspent)
        logger.debug('Sorted candidate UTXOs: {}'.format([print_coin(coin) for coin in unspent]))
        use_inputs = unspent

    inputs = []
    btc_in = 0
    change_quantity = 0
    sufficient_funds = False
    final_fee = fee_per_kb

    # pop inputs until we can pay for the fee
    for coin in use_inputs:
        logger.debug('New input: {}'.format(print_coin(coin)))
        inputs.append(coin)
        btc_in += round(coin['amount'] * config.UNIT)

        # If exact fee is specified, use that. Otherwise, calculate size of tx
        # and base fee on that (plus provide a minimum fee for selling BTC).
        if exact_fee:
            final_fee = exact_fee
        else:
            size = 181 * len(inputs) + size_for_fee
            necessary_fee = (int(size / 1000) + 1) * fee_per_kb
            final_fee = max(fee_provided, necessary_fee)

            logger.getChild('p2shdebug').debug('final_fee inputs: %d size: %d final_fee %s' % (len(inputs), size, final_fee))

            assert final_fee >= 1 * fee_per_kb

        # Check if good.
        btc_out = destination_btc_out + data_btc_out
        change_quantity = btc_in - (btc_out + final_fee)
        logger.debug('Change quantity: {} BTC'.format(change_quantity / config.UNIT))
        # If change is necessary, must not be a dust output.
        if change_quantity == 0 or change_quantity >= regular_dust_size:
            sufficient_funds = True
            break

    if not sufficient_funds:
        # Approximate needed change, fee by with most recently calculated
        # quantities.
        btc_out = destination_btc_out + data_btc_out
        total_btc_out = btc_out + max(change_quantity, 0) + final_fee
        raise exceptions.BalanceError('Insufficient {} at address {}. (Need approximately {} {}.) To spend unconfirmed coins, use the flag `--unconfirmed`. (Unconfirmed coins cannot be spent from multi‐sig addresses.)'.format(config.BTC, source, total_btc_out / config.UNIT, config.BTC))

    # Lock the source's inputs (UTXOs) chosen for this transaction
    if UTXO_LOCKS is not None and not disable_utxo_locks:
        if source not in UTXO_LOCKS:
            UTXO_LOCKS[source] = cachetools.TTLCache(
                UTXO_LOCKS_PER_ADDRESS_MAXSIZE, config.UTXO_LOCKS_MAX_AGE)

        for input in inputs:
            UTXO_LOCKS[source][make_outkey(input)] = input

        logger.debug("UTXO locks: Potentials ({}): {}, Used: {}, locked UTXOs: {}".format(
            len(unspent), [make_outkey(coin) for coin in unspent],
            [make_outkey(input) for input in inputs], list(UTXO_LOCKS[source].keys())))

    return inputs, change_quantity


def return_result(tx_hexes, old_style_api):
        tx_hexes = list(filter(None, tx_hexes))  # filter out None

        if old_style_api:
            if len(tx_hexes) != 1:
                raise Exception("Can't do 2 TXs with old_style_api")

            return tx_hexes[0]
        else:
            return tx_hexes


def construct (db, tx_info, encoding='auto',
               fee_per_kb=config.DEFAULT_FEE_PER_KB,
               regular_dust_size=config.DEFAULT_REGULAR_DUST_SIZE,
               multisig_dust_size=config.DEFAULT_MULTISIG_DUST_SIZE,
               op_return_value=config.DEFAULT_OP_RETURN_VALUE,
               exact_fee=None, fee_provided=0, provided_pubkeys=None, dust_return_pubkey=None,
               allow_unconfirmed_inputs=False, unspent_tx_hash=None, custom_inputs=None, disable_utxo_locks=False,
               old_style_api=None, segwit=False, p2sh_pretx_txid=None):

    global UTXO_LOCKS, UTXO_P2SH_ENCODING_LOCKS

    # lazy assign from config, because when set as default it's evaluated before it's configured
    if old_style_api is None:
        old_style_api = config.OLD_STYLE_API

    (source, destination_outputs, data) = tx_info

    if dust_return_pubkey:
        dust_return_pubkey = binascii.unhexlify(dust_return_pubkey)

    # Source.
        # If public key is necessary for construction of (unsigned)
        # transaction, use the public key provided, or find it from the
        # blockchain.
    if source:
        script.validate(source)

    source_is_p2sh = script.is_p2sh(source)

    # Normalize source
    if script.is_multisig(source):
        source_address = backend.multisig_pubkeyhashes_to_pubkeys(source, provided_pubkeys)
    else:
        source_address = source

    # Sanity checks.
    if exact_fee and not isinstance(exact_fee, int):
        raise exceptions.TransactionError('Exact fees must be in satoshis.')
    if not isinstance(fee_provided, int):
        raise exceptions.TransactionError('Fee provided must be in satoshis.')

    '''Destinations'''

    # Destination outputs.
        # Replace multi‐sig addresses with multi‐sig pubkeys. Check that the
        # destination output isn’t a dust output. Set null values to dust size.
    destination_outputs_new = []
    for (address, value) in destination_outputs:

        # Value.
        if script.is_multisig(address):
            dust_size = multisig_dust_size
        else:
            dust_size = regular_dust_size
        if value == None:
            value = dust_size
        elif value < dust_size:
            raise exceptions.TransactionError('Destination output is dust.')

        # Address.
        script.validate(address)
        if script.is_multisig(address):
            destination_outputs_new.append((backend.multisig_pubkeyhashes_to_pubkeys(address, provided_pubkeys), value))
        else:
            destination_outputs_new.append((address, value))

    destination_outputs = destination_outputs_new
    destination_btc_out = sum([value for address, value in destination_outputs])


    '''Data'''

    if data:
        # Data encoding methods (choose and validate).
        if encoding == 'auto':
            if len(data) + len(config.PREFIX) <= config.OP_RETURN_MAX_SIZE:
                encoding = 'opreturn'
            else:
                encoding = 'p2sh' if not old_style_api and util.enabled('p2sh_encoding') else 'multisig'  # p2sh is not possible with old_style_api

        elif encoding == 'p2sh' and not util.enabled('p2sh_encoding'):
            raise exceptions.TransactionError('P2SH encoding not enabled yet')

        elif encoding not in ('pubkeyhash', 'multisig', 'opreturn', 'p2sh'):
            raise exceptions.TransactionError('Unknown encoding‐scheme.')


        # @TODO: p2sh encoding require signable dust key
        if encoding == 'multisig':
            # dust_return_pubkey should be set or explicitly set to False to use the default configured for the node
            #  the default for the node is optional so could fail
            if (source_is_p2sh and dust_return_pubkey is None) or (dust_return_pubkey is False and config.P2SH_DUST_RETURN_PUBKEY is None):
                raise exceptions.TransactionError("Can't use multisig encoding when source is P2SH and no dust_return_pubkey is provided.")
            elif dust_return_pubkey is False:
                dust_return_pubkey = binascii.unhexlify(config.P2SH_DUST_RETURN_PUBKEY)

        # Divide data into chunks.
        if encoding == 'pubkeyhash':
            # Prefix is also a suffix here.
            chunk_size = 20 - 1 - 8
        elif encoding == 'multisig':
            # Two pubkeys, minus length byte, minus prefix, minus two nonces,
            # minus two sign bytes.
            chunk_size = (33 * 2) - 1 - 8 - 2 - 2
        elif encoding == 'p2sh':
            chunk_size = 500  # @TODO
        elif encoding == 'opreturn':
            chunk_size = config.OP_RETURN_MAX_SIZE
            if len(data) + len(config.PREFIX) > chunk_size:
                raise exceptions.TransactionError('One `OP_RETURN` output per transaction.')
        data_array = list(chunks(data, chunk_size))

        # Data outputs.
        if encoding == 'multisig':
            data_value = multisig_dust_size
        elif encoding == 'p2sh':
            data_value = multisig_dust_size  # @TODO
        elif encoding == 'opreturn':
            data_value = op_return_value
        else:
            # Pay‐to‐PubKeyHash, e.g.
            data_value = regular_dust_size
        data_output = (data_array, data_value)

        if not dust_return_pubkey:
            if encoding == 'multisig' or encoding == 'p2sh':
                dust_return_pubkey = get_dust_return_pubkey(source, provided_pubkeys, encoding)
            else:
                dust_return_pubkey = None
    else:
        data_value = 0
        data_array = []
        data_output = None
        dust_return_pubkey = None

    data_btc_out = data_value * len(data_array)
    logger.getChild('p2shdebug').debug('data_btc_out=%s (data_value=%d len(data_array)=%d)' % (data_btc_out, data_value, len(data_array)))

    '''Inputs'''

    # Calculate collective size of outputs, for fee calculation.
    if encoding == 'multisig':
        data_output_size = 81       # 71 for the data
    elif encoding == 'opreturn':
        data_output_size = 90       # 80 for the data
    else:
        data_output_size = 25 + 9   # Pay‐to‐PubKeyHash (25 for the data?)

    # we don't zpad the p2sh encoding so exact size, we add the data size to it eventhough it's gonna be in the input
    if encoding == 'p2sh':
        datatx_size = 10  # 10 base
        datatx_size += 181  # 181 for source input
        datatx_size += (25 + 9) * len(destination_outputs)  # destination outputs
        datatx_size += 13  # opreturn that signals P2SH encoding
        datatx_size += len(data_array) * (9 + 181)  # size of p2sh inputs, excl data
        datatx_size += sum([len(data_chunk) for data_chunk in data_array])  # data in scriptSig
        datatx_necessary_fee = (int(datatx_size / 1000) + 1) * fee_per_kb

        pretx_size_output_size = 10  # 10 base
        pretx_size_output_size += 29  # size of output to source
        pretx_size_output_size += len(data_array) * 29  # size of P2SH output

        size_for_fee = datatx_size + pretx_size_output_size

        logger.getChild('p2shdebug').debug('datatx size: %d fee: %d' % (datatx_size, datatx_necessary_fee))
        logger.getChild('p2shdebug').debug('pretx output size: %d' % (pretx_size_output_size, ))
        logger.getChild('p2shdebug').debug('size_for_fee: %d' % (size_for_fee, ))

    else:
        sum_data_output_size = len(data_array) * data_output_size
        size_for_fee = ((25 + 9) * len(destination_outputs)) + sum_data_output_size

    # when encoding=P2SH and the pretx txid is passed we can skip coinselection
    if not (encoding == 'p2sh' and p2sh_pretx_txid):
        inputs, change_quantity = construct_coin_selection(
            source, allow_unconfirmed_inputs, unspent_tx_hash, custom_inputs,
            fee_per_kb, exact_fee, size_for_fee, fee_provided, destination_btc_out, data_btc_out,
            regular_dust_size, disable_utxo_locks
        )
    else:
        inputs, change_quantity = None, None

    '''Finish'''

    if change_quantity:
        change_output = (source_address, change_quantity)
    else:
        change_output = None

    unsigned_pretx_hex = None
    unsigned_tx_hex = None

    if encoding == 'p2sh':
        assert not (segwit and p2sh_pretx_txid)  # shouldn't do old style with segwit enabled

        pretx_txid = None
        if p2sh_pretx_txid:
            pretx_txid = p2sh_pretx_txid if isinstance(p2sh_pretx_txid, bytes) else binascii.unhexlify(p2sh_pretx_txid)
            unsigned_pretx = None
        else:
            destination_value_sum = sum([value for (destination, value) in destination_outputs])
            source_value = destination_value_sum + datatx_necessary_fee
            source_value -= (len(data_array) * data_value)  # substract the value we can use from the data inputs

            logger.getChild('p2shdebug').debug('source_value %d' % (source_value, ))
            logger.getChild('p2shdebug').debug('change_value %d' % (change_output[1], ))
            if change_output:
                change_value = change_output[1]
                # substract source_value from change
                change_value -= source_value
                # add destination_value_sum to change, it's already in source_value
                change_value += destination_value_sum
                change_output = (change_output[0], change_value)

            unsigned_pretx = serializer.serialise_p2sh_pretx(inputs,
                                                             source=source_address,
                                                             source_value=source_value,
                                                             data_output=data_output,
                                                             change_output=change_output,
                                                             pubkey=dust_return_pubkey)
            unsigned_pretx_hex = binascii.hexlify(unsigned_pretx).decode('utf-8')

        # with segwit we already know the txid and can return both
        if segwit:
            pretx_txid = hashlib.sha256(unsigned_pretx).digest()  # this should be segwit txid
            logger.getChild('p2shdebug').debug('pretx_txid %s' % pretx_txid)

        if unsigned_pretx:
            # we set a long lock on this, don't want other TXs to spend from it
            UTXO_P2SH_ENCODING_LOCKS[make_outkey_vin(unsigned_pretx, 0)] = True

        # only generate the data TX if we have the pretx txId
        if pretx_txid:
            unsigned_datatx = serializer.serialise_p2sh_datatx(pretx_txid,
                                                               source=source_address,
                                                               destination_outputs=destination_outputs,
                                                               data_output=data_output,
                                                               pubkey=dust_return_pubkey)
            unsigned_datatx_hex = binascii.hexlify(unsigned_datatx).decode('utf-8')

            # let the rest of the code work it's magic on the data tx
            unsigned_tx_hex = unsigned_datatx_hex
        else:
            # we're just gonna return the pretx, it doesn't require any of the further checks
            logger.warn('old_style_api = %s' % old_style_api)
            return return_result([unsigned_pretx_hex], old_style_api=old_style_api)

    else:
        # Serialise inputs and outputs.
        unsigned_tx = serializer.serialise(encoding, inputs, destination_outputs,
                                data_output, change_output,
                                dust_return_pubkey=dust_return_pubkey)
        unsigned_tx_hex = binascii.hexlify(unsigned_tx).decode('utf-8')


    '''Sanity Check'''

    from counterpartylib.lib import blocks

    # Desired transaction info.
    (desired_source, desired_destination_outputs, desired_data) = tx_info
    desired_source = script.make_canonical(desired_source)
    desired_destination = script.make_canonical(desired_destination_outputs[0][0]) if desired_destination_outputs else ''
    # NOTE: Include change in destinations for BTC transactions.
    # if change_output and not desired_data and desired_destination != config.UNSPENDABLE:
    #    if desired_destination == '':
    #        desired_destination = desired_source
    #    else:
    #        desired_destination += '-{}'.format(desired_source)
    # NOTE
    if desired_data == None:
        desired_data = b''

    # Parsed transaction info.
    try:
        parsed_source, parsed_destination, x, y, parsed_data = blocks._get_tx_info(unsigned_tx_hex)
    except exceptions.BTCOnlyError:
        # Skip BTC‐only transactions.
        logger.getChild('p2shdebug').debug('BTC-ONLY')
        return return_result([unsigned_pretx_hex, unsigned_tx_hex], old_style_api=old_style_api)
    desired_source = script.make_canonical(desired_source)

    # Check desired info against parsed info.
    desired = (desired_source, desired_destination, desired_data)
    parsed = (parsed_source, parsed_destination, parsed_data)
    if desired != parsed:
        # Unlock (revert) UTXO locks
        if UTXO_LOCKS is not None and inputs:
            for input in inputs:
                UTXO_LOCKS[source].pop(make_outkey(input), None)

        raise exceptions.TransactionError('Constructed transaction does not parse correctly: {} ≠ {}'.format(desired, parsed))

    return return_result([unsigned_pretx_hex, unsigned_tx_hex], old_style_api=old_style_api)


# vim: tabstop=8 expandtab shiftwidth=4 softtabstop=4
