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
from Crypto.Cipher import ARC4
from bitcoin.core.script import CScript
from bitcoin.core import x
from bitcoin.core import b2lx

from counterpartylib.lib import config
from counterpartylib.lib import exceptions
from counterpartylib.lib import util
from counterpartylib.lib import script
from counterpartylib.lib import backend

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

D = decimal.Decimal

def print_coin(coin):
    return 'amount: {}; txid: {}; vout: {}; confirmations: {}'.format(coin['amount'], coin['txid'], coin['vout'], coin.get('confirmations', '?')) # simplify and make deterministic

def var_int (i):
    if i < 0xfd:
        return (i).to_bytes(1, byteorder='little')
    elif i <= 0xffff:
        return b'\xfd' + (i).to_bytes(2, byteorder='little')
    elif i <= 0xffffffff:
        return b'\xfe' + (i).to_bytes(4, byteorder='little')
    else:
        return b'\xff' + (i).to_bytes(8, byteorder='little')

def op_push (i):
    if i < 0x4c:
        return (i).to_bytes(1, byteorder='little')              # Push i bytes.
    elif i <= 0xff:
        return b'\x4c' + (i).to_bytes(1, byteorder='little')    # OP_PUSHDATA1
    elif i <= 0xffff:
        return b'\x4d' + (i).to_bytes(2, byteorder='little')    # OP_PUSHDATA2
    else:
        return b'\x4e' + (i).to_bytes(4, byteorder='little')    # OP_PUSHDATA4

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

def get_multisig_script(address):

    # Unpack multi‐sig address.
    signatures_required, pubkeys, signatures_possible = script.extract_array(address)

    # Required signatures.
    if signatures_required == 1:
        op_required = OP_1
    elif signatures_required == 2:
        op_required = OP_2
    elif signatures_required == 3:
        op_required = OP_3
    else:
        raise script.InputError('Required signatures must be 1, 2 or 3.')

    # Required signatures.
    # Note 1-of-1 addresses are not supported (they don't go through extract_array anyway).
    if signatures_possible == 2:
        op_total = OP_2
    elif signatures_possible == 3:
        op_total = OP_3
    else:
        raise script.InputError('Total possible signatures must be 2 or 3.')

    # Construct script.
    tx_script = op_required                                # Required signatures
    for public_key in pubkeys:
        public_key = binascii.unhexlify(public_key)
        tx_script += op_push(len(public_key))              # Push bytes of public key
        tx_script += public_key                            # Data chunk (fake) public key
    tx_script += op_total                                  # Total signatures
    tx_script += OP_CHECKMULTISIG                          # OP_CHECKMULTISIG

    return tx_script

def get_monosig_script(address):

    # Construct script.
    pubkeyhash = script.base58_check_decode(address, config.ADDRESSVERSION)
    tx_script = OP_DUP                                     # OP_DUP
    tx_script += OP_HASH160                                # OP_HASH160
    tx_script += op_push(20)                               # Push 0x14 bytes
    tx_script += pubkeyhash                                # pubKeyHash
    tx_script += OP_EQUALVERIFY                            # OP_EQUALVERIFY
    tx_script += OP_CHECKSIG                               # OP_CHECKSIG

    return tx_script

def make_fully_valid(pubkey_start):
    """Take a too short data pubkey and make it look like a real pubkey.

    Take an obfuscated chunk of data that is two bytes too short to be a pubkey and
    add a sign byte to its beginning and a nonce byte to its end. Choose these
    bytes so that the resulting sequence of bytes is a fully valid pubkey (i.e. on
    the ECDSA curve). Find the correct bytes by guessing randomly until the check
    passes. (In parsing, these two bytes are ignored.)
    """
    assert type(pubkey_start) == bytes
    assert len(pubkey_start) == 31    # One sign byte and one nonce byte required (for 33 bytes).

    random_bytes = hashlib.sha256(pubkey_start).digest()      # Deterministically generated, for unit tests.
    sign = (random_bytes[0] & 0b1) + 2                  # 0x02 or 0x03
    nonce = initial_nonce = random_bytes[1]

    pubkey = b''
    while not script.is_fully_valid(pubkey):
        # Increment nonce.
        nonce += 1
        assert nonce != initial_nonce

        # Construct a possibly fully valid public key.
        pubkey = bytes([sign]) + pubkey_start + bytes([nonce % 256])

    assert len(pubkey) == 33
    return pubkey


def serialise (encoding, inputs, destination_outputs, data_output=None, change_output=None, dust_return_pubkey=None):
    s  = (1).to_bytes(4, byteorder='little')                # Version

    # Number of inputs.
    s += var_int(int(len(inputs)))

    # List of Inputs.
    for i in range(len(inputs)):
        txin = inputs[i]
        s += binascii.unhexlify(bytes(txin['txid'], 'utf-8'))[::-1]         # TxOutHash
        s += txin['vout'].to_bytes(4, byteorder='little')   # TxOutIndex

        tx_script = binascii.unhexlify(bytes(txin['scriptPubKey'], 'utf-8'))
        s += var_int(int(len(tx_script)))                      # Script length
        s += tx_script                                         # Script
        s += b'\xff' * 4                                    # Sequence

    # Number of outputs.
    n = 0
    n += len(destination_outputs)
    if data_output:
        data_array, value = data_output
        for data_chunk in data_array: n += 1
    else:
        data_array = []
    if change_output: n += 1
    s += var_int(n)

    # Destination output.
    for destination, value in destination_outputs:
        s += value.to_bytes(8, byteorder='little')          # Value

        if script.is_multisig(destination):
            tx_script = get_multisig_script(destination)
        else:
            tx_script = get_monosig_script(destination)

        s += var_int(int(len(tx_script)))                      # Script length
        s += tx_script

    # Data output.
    for data_chunk in data_array:
        data_array, value = data_output
        s += value.to_bytes(8, byteorder='little')        # Value

        data_chunk = config.PREFIX + data_chunk

        # Initialise encryption key (once per output).
        key = ARC4.new(binascii.unhexlify(inputs[0]['txid']))  # Arbitrary, easy‐to‐find, unique key.

        if encoding == 'multisig':
            assert dust_return_pubkey
            # Get data (fake) public key.
            pad_length = (33 * 2) - 1 - 2 - 2 - len(data_chunk)
            assert pad_length >= 0
            data_chunk = bytes([len(data_chunk)]) + data_chunk + (pad_length * b'\x00')
            data_chunk = key.encrypt(data_chunk)
            data_pubkey_1 = make_fully_valid(data_chunk[:31])
            data_pubkey_2 = make_fully_valid(data_chunk[31:])

            # Construct script.
            tx_script = OP_1                                   # OP_1
            tx_script += op_push(33)                           # Push bytes of data chunk (fake) public key    (1/2)
            tx_script += data_pubkey_1                         # (Fake) public key                  (1/2)
            tx_script += op_push(33)                           # Push bytes of data chunk (fake) public key    (2/2)
            tx_script += data_pubkey_2                         # (Fake) public key                  (2/2)
            tx_script += op_push(len(dust_return_pubkey))  # Push bytes of source public key
            tx_script += dust_return_pubkey                       # Source public key
            tx_script += OP_3                                  # OP_3
            tx_script += OP_CHECKMULTISIG                      # OP_CHECKMULTISIG
        elif encoding == 'opreturn':
            data_chunk = key.encrypt(data_chunk)
            tx_script = OP_RETURN                                  # OP_RETURN
            tx_script += op_push(len(data_chunk))                  # Push bytes of data chunk (NOTE: OP_SMALLDATA?)
            tx_script += data_chunk                                # Data
        elif encoding == 'pubkeyhash':
            pad_length = 20 - 1 - len(data_chunk)
            assert pad_length >= 0
            data_chunk = bytes([len(data_chunk)]) + data_chunk + (pad_length * b'\x00')
            data_chunk = key.encrypt(data_chunk)
            # Construct script.
            tx_script = OP_DUP                                     # OP_DUP
            tx_script += OP_HASH160                                # OP_HASH160
            tx_script += op_push(20)                               # Push 0x14 bytes
            tx_script += data_chunk                                # (Fake) pubKeyHash
            tx_script += OP_EQUALVERIFY                            # OP_EQUALVERIFY
            tx_script += OP_CHECKSIG                               # OP_CHECKSIG
        else:
            raise exceptions.TransactionError('Unknown encoding‐scheme.')

        s += var_int(int(len(tx_script)))                      # Script length
        s += tx_script

    # Change output.
    if change_output:
        change_address, change_value = change_output
        s += change_value.to_bytes(8, byteorder='little')   # Value

        if script.is_multisig(change_address):
            tx_script = get_multisig_script(change_address)
        else:
            tx_script = get_monosig_script(change_address)

        s += var_int(int(len(tx_script)))                      # Script length
        s += tx_script

    s += (0).to_bytes(4, byteorder='little')                # LockTime
    return s

def chunks(l, n):
    """ Yield successive n‐sized chunks from l.
    """
    for i in range(0, len(l), n):
        yield l[i:i+n]

def construct (db, tx_info, encoding='auto',
               fee_per_kb=config.DEFAULT_FEE_PER_KB,
               regular_dust_size=config.DEFAULT_REGULAR_DUST_SIZE,
               multisig_dust_size=config.DEFAULT_MULTISIG_DUST_SIZE,
               op_return_value=config.DEFAULT_OP_RETURN_VALUE,
               exact_fee=None, fee_provided=0, provided_pubkeys=None,
               allow_unconfirmed_inputs=False, unspent_tx_hash=None):

    (source, destination_outputs, data) = tx_info

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

    # Data encoding methods (choose and validate).
    if data:
        if encoding == 'auto':
            if len(data) + len(config.PREFIX) <= config.OP_RETURN_MAX_SIZE:
                encoding = 'opreturn'
            else:
                encoding = 'multisig'
        elif encoding not in ('pubkeyhash', 'multisig', 'opreturn'):
            raise exceptions.TransactionError('Unknown encoding‐scheme.')

    # Divide data into chunks.
    if data:
        if encoding == 'pubkeyhash':
            # Prefix is also a suffix here.
            chunk_size = 20 - 1 - 8
        elif encoding == 'multisig':
            # Two pubkeys, minus length byte, minus prefix, minus two nonces,
            # minus two sign bytes.
            chunk_size = (33 * 2) - 1 - 8 - 2 - 2
        elif encoding == 'opreturn':
            chunk_size = config.OP_RETURN_MAX_SIZE
            if len(data) + len(config.PREFIX) > chunk_size:
                raise exceptions.TransactionError('One `OP_RETURN` output per transaction.')
        data_array = list(chunks(data, chunk_size))
    else:
        data_array = []

    # Data outputs.
    if data:
        if encoding == 'multisig':
            data_value = multisig_dust_size
        elif encoding == 'opreturn':
            data_value = op_return_value
        else:
            # Pay‐to‐PubKeyHash, e.g.
            data_value = regular_dust_size
        data_output = (data_array, data_value)
    else:
        data_output = None
    data_btc_out = sum([data_value for data_chunk in data_array])


    '''Inputs'''

    # Source.
        # If public key is necessary for construction of (unsigned)
        # transaction, use the public key provided, or find it from the
        # blockchain.
    if source:
        script.validate(source)
    if encoding == 'multisig':
        dust_return_pubkey = get_dust_return_pubkey(source, provided_pubkeys, encoding)
    else:
        dust_return_pubkey = None

    # Calculate collective size of outputs, for fee calculation.
    if encoding == 'multisig':
        data_output_size = 81       # 71 for the data
    elif encoding == 'opreturn':
        data_output_size = 90       # 80 for the data
    else:
        data_output_size = 25 + 9   # Pay‐to‐PubKeyHash (25 for the data?)
    outputs_size = ((25 + 9) * len(destination_outputs)) + (len(data_array) * data_output_size)

    # Get inputs.
    multisig_inputs = not data
    if unspent_tx_hash is not None:
        unspent = backend.get_unspent_txouts(source, unconfirmed=allow_unconfirmed_inputs, unspent_tx_hash=unspent_tx_hash, multisig_inputs=multisig_inputs)
    else:
        unspent = backend.get_unspent_txouts(source, unconfirmed=allow_unconfirmed_inputs, multisig_inputs=multisig_inputs)

    unspent = backend.sort_unspent_txouts(unspent)
    logger.debug('Sorted UTXOs: {}'.format([print_coin(coin) for coin in unspent]))

    inputs = []
    btc_in = 0
    change_quantity = 0
    sufficient_funds = False
    final_fee = fee_per_kb
    for coin in unspent:
        logger.debug('New input: {}'.format(print_coin(coin)))
        inputs.append(coin)
        btc_in += round(coin['amount'] * config.UNIT)

        # If exact fee is specified, use that. Otherwise, calculate size of tx
        # and base fee on that (plus provide a minimum fee for selling BTC).
        if exact_fee:
            final_fee = exact_fee
        else:
            size = 181 * len(inputs) + outputs_size + 10
            necessary_fee = (int(size / 1000) + 1) * fee_per_kb
            final_fee = max(fee_provided, necessary_fee)
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


    '''Finish'''

    # Change output.
    if change_quantity:
        if script.is_multisig(source):
            change_address = backend.multisig_pubkeyhashes_to_pubkeys(source, provided_pubkeys)
        else:
            change_address = source
        change_output = (change_address, change_quantity)
    else:
        change_output = None


    # Serialise inputs and outputs.
    unsigned_tx = serialise(encoding, inputs, destination_outputs,
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
        parsed_source, parsed_destination, x, y, parsed_data = blocks.get_tx_info2(unsigned_tx_hex)
    except exceptions.BTCOnlyError:
        # Skip BTC‐only transactions.
        return unsigned_tx_hex
    desired_source = script.make_canonical(desired_source)

    # Check desired info against parsed info.
    desired = (desired_source, desired_destination, desired_data)
    parsed = (parsed_source, parsed_destination, parsed_data)
    if desired != parsed:
        raise exceptions.TransactionError('Constructed transaction does not parse correctly: {} ≠ {}'.format(desired, parsed))

    return unsigned_tx_hex

# vim: tabstop=8 expandtab shiftwidth=4 softtabstop=4
