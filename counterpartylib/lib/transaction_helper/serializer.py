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
UTXO_LOCKS = None
UTXO_LOCKS_PER_ADDRESS_MAXSIZE = 5000  # set higher than the max number of UTXOs we should expect to
                                       # manage in an aging cache for any one source address, at any one period


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


def get_script(address):
    if script.is_multisig(address):
        return get_multisig_script(address)
    else:
        try:
            return get_monosig_script(address)
        except script.VersionByteError as e:
            return get_p2sh_script(address)


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


def get_p2sh_script(address):

    # Construct script.
    scripthash = script.base58_check_decode(address, config.P2SH_ADDRESSVERSION)
    tx_script = OP_HASH160
    tx_script += op_push(len(scripthash))
    tx_script += scripthash
    tx_script += OP_EQUAL

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


def serialise(encoding, inputs, destination_outputs, data_output=None, change_output=None, dust_return_pubkey=None):
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

        tx_script = get_script(destination)

        s += var_int(int(len(tx_script)))                      # Script length
        s += tx_script

    # Data output.
    for data_chunk in data_array:
        data_array, value = data_output
        s += value.to_bytes(8, byteorder='little')        # Value

        data_chunk = config.PREFIX + data_chunk

        # Initialise encryption key (once per output).
        assert isinstance(inputs[0]['txid'], str)
        key = arc4.init_arc4(binascii.unhexlify(inputs[0]['txid']))  # Arbitrary, easy‐to‐find, unique key.

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

        tx_script = get_script(change_address)

        s += var_int(int(len(tx_script)))                      # Script length
        s += tx_script

    s += (0).to_bytes(4, byteorder='little')                # LockTime
    return s


def make_p2sh_encoding_redeemscript(datachunk, n, pubKey):
    _logger = logger.getChild('p2sh_encoding')
    assert len(datachunk) <= bitcoinlib.core.script.MAX_SCRIPT_ELEMENT_SIZE

    dataRedeemScript = [bitcoinlib.core.script.OP_HASH160, bitcoinlib.core.Hash160(datachunk), bitcoinlib.core.script.OP_EQUALVERIFY]

    redeemScript = CScript(dataRedeemScript +
                           [pubKey, bitcoinlib.core.script.OP_CHECKSIGVERIFY,
                            n, bitcoinlib.core.script.OP_DROP,  # deduplicate push dropped to meet BIP62 rules
                            bitcoinlib.core.script.OP_DEPTH, 0, bitcoinlib.core.script.OP_EQUAL])  # prevent scriptSig malleability

    _logger.debug('datachunk %s' % (binascii.hexlify(datachunk)))
    _logger.debug('dataRedeemScript %s (%s)' % (repr(CScript(dataRedeemScript)), binascii.hexlify(CScript(dataRedeemScript))))

    _logger.debug('redeemScript %s (%s)' % (repr(redeemScript), binascii.hexlify(redeemScript)))

    outputScript = redeemScript.to_p2sh_scriptPubKey()
    scriptSig = CScript([datachunk]) + redeemScript  # PUSH(datachunk) + redeemScript

    _logger.debug('scriptSig %s (%s)' % (repr(scriptSig), binascii.hexlify(scriptSig)))
    _logger.debug('outputScript %s (%s)' % (repr(outputScript), binascii.hexlify(outputScript)))

    return scriptSig, redeemScript, outputScript


def serialise_p2sh_pretx(inputs, source, source_value, data_output, change_output=None, pubkey=None):
    assert data_output  # we don't do this unless there's data

    data_array, data_value = data_output

    s  = (1).to_bytes(4, byteorder='little')  # Version

    # Number of inputs.
    s += var_int(int(len(inputs)))

    # List of Inputs.
    for i in range(len(inputs)):
        txin = inputs[i]
        s += binascii.unhexlify(bytes(txin['txid'], 'utf-8'))[::-1]  # TxOutHash
        s += txin['vout'].to_bytes(4, byteorder='little')            # TxOutIndex

        tx_script = binascii.unhexlify(bytes(txin['scriptPubKey'], 'utf-8'))
        s += var_int(int(len(tx_script)))  # Script length
        s += tx_script                     # Script
        s += b'\xff' * 4                   # Sequence

    # Number of outputs.
    n = 1  # at least one for the source
    n += len(data_array)
    if change_output:
        n += 1

    # encode number of outputs
    s += var_int(n)

    # output to source
    tx_script = get_script(source)
    s += source_value.to_bytes(8, byteorder='little')  # Value
    s += var_int(int(len(tx_script)))                  # Script length
    s += tx_script

    # P2SH for data encodeded inputs
    for n, data_chunk in enumerate(data_array):
        data_chunk = config.PREFIX + data_chunk  # prefix the data_chunk

        # # initialise encryption key (once per output), use the txid that it's spending as key
        # key = arc4.init_arc4(binascii.unhexlify(inputs[0]['txid']))
        #
        # # encrypt data
        # data_chunk = key.encrypt(data_chunk)

        # get the scripts
        scriptSig, redeemScript, outputScript = make_p2sh_encoding_redeemscript(data_chunk, n, pubkey)

        s += data_value.to_bytes(8, byteorder='little')  # Value
        s += var_int(int(len(outputScript)))             # Script length
        s += outputScript                                # Script

    # Change output.
    if change_output:
        change_address, change_value = change_output
        tx_script = get_script(change_address)

        s += change_value.to_bytes(8, byteorder='little')  # Value
        s += var_int(int(len(tx_script)))                  # Script length
        s += tx_script                                     # Script

    s += (0).to_bytes(4, byteorder='little')  # LockTime

    return s


def serialise_p2sh_datatx(txid, source, destination_outputs, data_output, pubkey=None):
    assert data_output  # we don't do this unless there's data

    txhash = bitcoinlib.core.lx(bitcoinlib.core.b2x(txid))  # reverse txId
    data_array, value = data_output

    # version
    s = (1).to_bytes(4, byteorder='little')

    # number of inputs
    s += var_int(int(len(data_array) + 1))

    # source input
    tx_script = get_script(source)
    s += txhash                               # TxOutHash (reverse txId)
    s += (0).to_bytes(4, byteorder='little')  # TxOutIndex
    s += var_int(int(len(tx_script)))         # Script length
    s += tx_script                            # Script
    s += b'\xff' * 4                          # Sequence

    # list of inputs
    for n, data_chunk in enumerate(data_array):
        data_chunk = config.PREFIX + data_chunk  # prefix the data_chunk

        # # initialise encryption key (once per output), use the txid that it's spending as key
        # key = arc4.init_arc4(txid)
        #
        # # encrypt data
        # data_chunk = key.encrypt(data_chunk)

        # get the scripts
        scriptSig, redeemScript, outputScript = make_p2sh_encoding_redeemscript(data_chunk, n, pubkey)

        substituteScript = scriptSig + outputScript

        s += txhash                                   # TxOutHash
        s += (n + 1).to_bytes(4, byteorder='little')  # TxOutIndex
        s += var_int(len(substituteScript))           # Script length
        s += substituteScript                         # Script
        s += b'\xff' * 4                              # Sequence

    # number of outputs, always 1 for the opreturn
    n = 1
    n += len(destination_outputs)

    # encode output length
    s += var_int(n)

    # destination outputs
    for destination, value in destination_outputs:
        tx_script = get_script(destination)

        s += value.to_bytes(8, byteorder='little')  # Value
        s += var_int(int(len(tx_script)))           # Script length
        s += tx_script                              # Script

    # opreturn to signal P2SH encoding
    key = arc4.init_arc4(txid)
    data_chunk = config.PREFIX + b'P2SH'
    data_chunk = key.encrypt(data_chunk)
    tx_script = OP_RETURN                  # OP_RETURN
    tx_script += op_push(len(data_chunk))  # Push bytes of data chunk
    tx_script += data_chunk                # Data

    # add opreturn
    s += (0).to_bytes(8, byteorder='little')  # Value
    s += var_int(int(len(tx_script)))         # Script length
    s += tx_script                            # Script

    s += (0).to_bytes(4, byteorder='little')  # LockTime

    return s
