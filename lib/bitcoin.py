"""
Craft, sign and broadcast Bitcoin transactions.
Interface with Bitcoind.
"""

import sys
import binascii
import json
import hashlib
import requests
import re
import time

from . import (config, exceptions)

# Constants
OP_RETURN = b'\x6a'
OP_PUSHDATA1 = b'\x4c'
OP_DUP = b'\x76'
OP_HASH160 = b'\xa9'
OP_EQUALVERIFY = b'\x88'
OP_CHECKSIG = b'\xac'
OP_1 = b'\x51'
OP_2 = b'\x52'
OP_CHECKMULTISIG = b'\xae'
b58_digits = '123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz'

request_session = None
dhash = lambda x: hashlib.sha256(hashlib.sha256(x).digest()).digest()

def connect (host, payload, headers):
    global request_session
    if not request_session: request_session = requests.Session()
    TRIES = 12
    for i in range(TRIES):
        try:
            response = request_session.post(host, data=json.dumps(payload), headers=headers)
            return response
        except requests.exceptions.ConnectionError:
            print('Could not connect to Bitcoind. Sleeping for five seconds. (Try {}/{})'.format(i+1, TRIES), file=sys.stderr)
            time.sleep(5)
    return None

def rpc (method, params):
    headers = {'content-type': 'application/json'}
    payload = {
        "method": method,
        "params": params,
        "jsonrpc": "2.0",
        "id": 0,
    }

    response = connect(config.BITCOIND_RPC, payload, headers)
    if response == None:
        if config.TESTNET: network = 'testnet'
        else: network = 'mainnet'
        raise exceptions.BitcoindRPCError('Cannot communicate with Bitcoind. (counterpartyd is set to run on {}, is Bitcoind?)'.format(network))

    if response.status_code == 401:
        raise exceptions.BitcoindRPCError('Bitcoind RPC: unauthorized')

    # Return result, with error handling.
    response_json = response.json()
    if 'error' not in response_json.keys() or response_json['error'] == None:
        return response_json['result']
    elif response_json['error']['code'] == -5:   # RPC_INVALID_ADDRESS_OR_KEY
        raise exceptions.BitcoindError('{} Is txindex enabled in Bitcoind?'.format(response_json['error']))
    else:
        raise exceptions.BitcoindError('{}'.format(response_json['error']))

def base58_decode (s, version):
    # Convert the string to an integer
    n = 0
    for c in s:
        n *= 58
        if c not in b58_digits:
            raise exceptions.InvalidBase58Error('Not a valid base58 character:', c)
        digit = b58_digits.index(c)
        n += digit

    # Convert the integer to bytes
    h = '%x' % n
    if len(h) % 2:
        h = '0' + h
    res = binascii.unhexlify(h.encode('utf8'))

    # Add padding back.
    pad = 0
    for c in s[:-1]:
        if c == b58_digits[0]: pad += 1
        else: break
    k = version * pad + res

    addrbyte, data, chk0 = k[0:1], k[1:-4], k[-4:]
    if addrbyte != version:
        raise exceptions.VersionByteError('mainnet–testnet mismatch')
    chk1 = dhash(addrbyte + data)[:4]
    if chk0 != chk1:
        raise exceptions.Base58ChecksumError('Checksum mismatch: %r ≠ %r' % (chk0, chk1))
    return data

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

def serialise (inputs, destination_output=None, data_output=None, change_output=None, multisig=False, source=None):
    s  = (1).to_bytes(4, byteorder='little')                # Version

    # Number of inputs.
    s += var_int(int(len(inputs)))

    # List of Inputs.
    for i in range(len(inputs)):
        txin = inputs[i]
        s += binascii.unhexlify(bytes(txin['txid'], 'utf-8'))[::-1]         # TxOutHash
        s += txin['vout'].to_bytes(4, byteorder='little')   # TxOutIndex

        # No signature.
        script = b''
        s += var_int(int(len(script)))                      # Script length
        s += script                                         # Script
        s += b'\xff' * 4                                    # Sequence

    # Number of outputs.
    n = 0
    if destination_output: n += 1
    if data_output:
        data_array, value = data_output
        for data_chunk in data_array: n += 1
    else:
        data_array = []
    if change_output: n += 1
    s += var_int(n)

    # Destination output.
    if destination_output:
        address, value = destination_output
        pubkeyhash = base58_decode(address, config.ADDRESSVERSION)
        s += value.to_bytes(8, byteorder='little')          # Value
        script = OP_DUP                                     # OP_DUP
        script += OP_HASH160                                # OP_HASH160
        script += op_push(20)                               # Push 0x14 bytes
        script += pubkeyhash                                # pubKeyHash
        script += OP_EQUALVERIFY                            # OP_EQUALVERIFY
        script += OP_CHECKSIG                               # OP_CHECKSIG
        s += var_int(int(len(script)))                      # Script length
        s += script

    # Data output.
    for data_chunk in data_array:
        data_array, value = data_output # DUPE
        s += (value).to_bytes(8, byteorder='little')        # Value

        if multisig:
            # Get source public key.
            from pycoin.ecdsa import generator_secp256k1, public_pair_for_secret_exponent
            from pycoin.encoding import wif_to_tuple_of_secret_exponent_compressed, public_pair_to_sec
            private_key_wif = rpc('dumpprivkey', [source])
            secret_exponent, compressed = wif_to_tuple_of_secret_exponent_compressed(private_key_wif)
            public_pair = public_pair_for_secret_exponent(generator_secp256k1, secret_exponent)
            source_pubkey = public_pair_to_sec(public_pair, compressed=compressed)

            # Get data (fake) public key.
            pad_length = 33 - 1 - len(data_chunk)
            assert pad_length >= 0
            data_pubkey = bytes([len(data_chunk)]) + data_chunk + (pad_length * b'\x00')

            script = OP_1                                   # OP_1
            script += op_push(len(source_pubkey))           # Push bytes of source public key
            script += source_pubkey                         # Source public key
            script += op_push(len(data_pubkey))             # Push bytes of data chunk (fake) public key
            script += data_pubkey                           # Data chunk (fake) public key
            script += OP_2                                  # OP_2
            script += OP_CHECKMULTISIG                      # OP_CHECKMULTISIG
        else:
            script = OP_RETURN                              # OP_RETURN
            script += op_push(len(data_chunk))              # Push bytes of data chunk (NOTE: OP_SMALLDATA?)
            script += data_chunk                            # Data chunk
        s += var_int(int(len(script)))                      # Script length
        s += script

    # Change output.
    if change_output:
        address, value = change_output
        pubkeyhash = base58_decode(address, config.ADDRESSVERSION)
        s += value.to_bytes(8, byteorder='little')          # Value
        script = OP_DUP                                     # OP_DUP
        script += OP_HASH160                                # OP_HASH160
        script += op_push(20)                               # Push 0x14 bytes
        script += pubkeyhash                                # pubKeyHash
        script += OP_EQUALVERIFY                            # OP_EQUALVERIFY
        script += OP_CHECKSIG                               # OP_CHECKSIG
        s += var_int(int(len(script)))                      # Script length
        s += script

    s += (0).to_bytes(4, byteorder='little')                # LockTime
    return s

def get_inputs (source, total_btc_out, test=False):
    """List unspent inputs for source."""
    if not test:
        listunspent = rpc('listunspent', [])
    else:
        import os
        CURR_DIR = os.path.dirname(os.path.realpath(os.path.join(os.getcwd(), os.path.expanduser(__file__))))
        with open(CURR_DIR + '/../test/listunspent.test.json', 'r') as listunspent_test_file:   # HACK
            listunspent = json.load(listunspent_test_file)
    unspent = [coin for coin in listunspent if coin['address'] == source]
    inputs, total_btc_in = [], 0
    for coin in unspent:                                                      
        inputs.append(coin)
        total_btc_in += round(coin['amount'] * config.UNIT)
        if total_btc_in >= total_btc_out:
            return inputs, total_btc_in
    return None, None

# Replace test flag with fake bitcoind JSON-RPC server.
def transaction (source, destination, btc_amount, fee, data, test=False, multisig=True):
    if test: multisig = False   # TODO

    # Validate addresses.
    for address in (source, destination):
        if address:
            try:
                base58_decode(address, config.ADDRESSVERSION)
            except Exception:
                raise exceptions.InvalidAddressError('Invalid Bitcoin address:',
                                          address)

    # Check that the source is in wallet.
    if not test:
        if not rpc('validateaddress', [source])['ismine']:
            raise exceptions.InvalidAddressError('Not one of your Bitcoin addresses:', source)

    # Check that the destination output isn't a dust output.
    if destination:
        if not btc_amount >= config.DUST_SIZE:
            raise exceptions.TXConstructionError('Destination output is below the dust target value.')
    else:
        assert not btc_amount

    # Divide data into chunks.
    if data:
        def chunks(l, n):
            """ Yield successive n‐sized chunks from l.
            """
            for i in range(0, len(l), n): yield l[i:i+n]
        if multisig:
            data_array = list(chunks(data, 33 - 1))
        else:
            data_array = list(chunks(data, 80))
            assert len(data_array) == 1 # Only one OP_RETURN output currently supported (messages should all be shorter than 80 bytes, at the moment).
    else:
        data_array = []

    # Calculate total BTC to be sent.
    total_btc_out = fee
    if multisig: data_value = config.DUST_SIZE
    else: data_value = config.DATA_VALUE
    for data_chunk in data_array: total_btc_out += data_value
    if destination: total_btc_out += btc_amount

    # Construct inputs.
    inputs, total_btc_in = get_inputs(source, total_btc_out, test)
    if not inputs:
        raise exceptions.BalanceError('Insufficient bitcoins at address {}. (Need {} BTC.)'.format(source, total_btc_out / config.UNIT))

    # Construct outputs.
    if destination: destination_output = (destination, btc_amount)
    else: destination_output = None
    if data: data_output = (data_array, data_value)
    else: data_output = None
    change_amount = total_btc_in - total_btc_out    # No check to make sure that the change output is above the dust target_value.
    if change_amount: change_output = (source, change_amount)
    else: change_output = None

    # Serialise inputs and outputs.
    transaction = serialise(inputs, destination_output, data_output, change_output, multisig=multisig, source=source)
    unsigned_tx_hex = binascii.hexlify(transaction).decode('utf-8')
    
    return unsigned_tx_hex

def transmit (unsigned_tx_hex, ask=True, unsigned=False):
    # Confirm transaction.
    if ask and not unsigned:
        if config.TESTNET: print('Attention: TESTNET!') 
        if config.TESTCOIN: print('Attention: TESTCOIN!\n') 
        if input('Confirm? (y/N) ') != 'y':
            print('Transaction aborted.', file=sys.stderr)
            sys.exit(1)
    if unsigned:
        return unsigned_tx_hex
    else:
        # Sign transaction.
        result = rpc('signrawtransaction', [unsigned_tx_hex])
        if result['complete']:
            signed_tx_hex = result['hex']
            return rpc('sendrawtransaction', [signed_tx_hex])

# vim: tabstop=8 expandtab shiftwidth=4 softtabstop=4
