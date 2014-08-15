"""
Craft, sign and broadcast Bitcoin transactions.
Interface with Bitcoind.
"""

import os
import sys
import binascii
import json
import hashlib
import re
import time
import getpass
import decimal
import logging

import requests
from pycoin.ecdsa import generator_secp256k1, public_pair_for_secret_exponent
from pycoin.encoding import wif_to_tuple_of_secret_exponent_compressed, public_pair_to_sec, is_sec_compressed, EncodingError
from Crypto.Cipher import ARC4

from . import config, exceptions, util, blockchain

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

D = decimal.Decimal
dhash = lambda x: hashlib.sha256(hashlib.sha256(x).digest()).digest()
bitcoin_rpc_session = None

def print_coin(coin):
    return 'amount: {}; txid: {}; vout: {}; confirmations: {}'.format(coin['amount'], coin['txid'], coin['vout'], coin.get('confirmations', '?')) # simplify and make deterministic

def get_block_count():
    return int(rpc('getblockcount', []))

def get_block_hash(block_index):
    return rpc('getblockhash', [block_index])

def is_valid (address):
    return rpc('validateaddress', [address])['isvalid']

def is_mine (address):
    return rpc('validateaddress', [address])['ismine']

def send_raw_transaction (tx_hex):
    return rpc('sendrawtransaction', [tx_hex])

def get_raw_transaction (tx_hash, json=True):
    if json:
        return rpc('getrawtransaction', [tx_hash, 1])
    else:
        return rpc('getrawtransaction', [tx_hash])

def get_block (block_hash):
    return rpc('getblock', [block_hash])

def get_block_hash (block_index):
    return rpc('getblockhash', [block_index])

def decode_raw_transaction (unsigned_tx_hex):
    return rpc('decoderawtransaction', [unsigned_tx_hex])

def get_wallet ():
    for group in rpc('listaddressgroupings', []):
        for bunch in group:
            yield bunch

def get_mempool ():
    return rpc('getrawmempool', [])

def get_info():
    return rpc('getinfo', [])

def bitcoind_check (db):
    """Checks blocktime of last block to see if {} Core is running behind.""".format(config.BTC_NAME)
    block_count = rpc('getblockcount', [])
    block_hash = rpc('getblockhash', [block_count])
    block = rpc('getblock', [block_hash])
    time_behind = time.time() - block['time']   # How reliable is the block time?!
    if time_behind > 60 * 60 * 2:   # Two hours.
        raise exceptions.BitcoindError('Bitcoind is running about {} seconds behind.'.format(round(time_behind)))

def connect (host, payload, headers):
    global bitcoin_rpc_session
    if not bitcoin_rpc_session: bitcoin_rpc_session = requests.Session()
    TRIES = 12
    for i in range(TRIES):
        try:
            response = bitcoin_rpc_session.post(host, data=json.dumps(payload), headers=headers, verify=config.BACKEND_RPC_SSL_VERIFY)
            if i > 0: print('Successfully connected.', file=sys.stderr)
            return response
        except requests.exceptions.SSLError as e:
            raise e
        except requests.exceptions.ConnectionError:
            logging.debug('Could not connect to Bitcoind. (Try {}/{})'.format(i+1, TRIES))
            time.sleep(5)
    return None

def wallet_unlock ():
    getinfo = get_info()
    if 'unlocked_until' in getinfo:
        if getinfo['unlocked_until'] >= 60:
            return True # Wallet is unlocked for at least the next 60 seconds.
        else:
            passphrase = getpass.getpass('Enter your Bitcoind[‐Qt] wallet passhrase: ')
            print('Unlocking wallet for 60 (more) seconds.')
            rpc('walletpassphrase', [passphrase, 60])
    else:
        return True    # Wallet is unencrypted.

def rpc (method, params):
    headers = {'content-type': 'application/json'}
    payload = {
        "method": method,
        "params": params,
        "jsonrpc": "2.0",
        "id": 0,
    }

    '''
    if config.UNITTEST:
        CURR_DIR = os.path.dirname(os.path.realpath(os.path.join(os.getcwd(), os.path.expanduser(__file__))))
        CURR_DIR += '/../test/'
        open(CURR_DIR + '/rpc.new', 'a') as f
        f.write(payload)
    '''

    response = connect(config.BACKEND_RPC, payload, headers)
    if response == None:
        if config.TESTNET: network = 'testnet'
        else: network = 'mainnet'
        raise exceptions.BitcoindRPCError('Cannot communicate with {} Core. ({} is set to run on {}, is {} Core?)'.format(config.BTC_NAME, config.XCP_CLIENT, network, config.BTC_NAME))
    elif response.status_code not in (200, 500):
        raise exceptions.BitcoindRPCError(str(response.status_code) + ' ' + response.reason)

    '''
    if config.UNITTEST:
        print(response)
        f.close()
    '''

    # Return result, with error handling.
    response_json = response.json()
    if 'error' not in response_json.keys() or response_json['error'] == None:
        return response_json['result']
    elif response_json['error']['code'] == -5:   # RPC_INVALID_ADDRESS_OR_KEY
        raise exceptions.BitcoindError('{} Is txindex enabled in {} Core?'.format(response_json['error'], config.BTC_NAME))
    elif response_json['error']['code'] == -4:   # Unknown private key (locked wallet?)
        # If address in wallet, attempt to unlock.
        address = params[0]
        validate_address = rpc('validateaddress', [address])
        if validate_address['isvalid']:
            if validate_address['ismine']:
                raise exceptions.BitcoindError('Wallet is locked.')
            else:   # When will this happen?
                raise exceptions.BitcoindError('Source address not in wallet.')
        else:
            raise exceptions.AddressError('Invalid address.')
    elif response_json['error']['code'] == -1 and response_json['message'] == 'Block number out of range.':
        time.sleep(10)
        return rpc('getblockhash', [block_index])

    # elif config.UNITTEST:
    #     print(method)
    else:
        raise exceptions.BitcoindError('{}'.format(response_json['error']))

def base58_encode(binary):
    # Convert big‐endian bytes to integer
    n = int('0x0' + binascii.hexlify(binary).decode('utf8'), 16)

    # Divide that integer into base58
    res = []
    while n > 0:
        n, r = divmod (n, 58)
        res.append(b58_digits[r])
    res = ''.join(res[::-1])
    return res

def base58_check_encode(b, version):
    b = binascii.unhexlify(bytes(b, 'utf-8'))
    d = version + b

    binary = d + dhash(d)[:4]
    res = base58_encode(binary)

    # Encode leading zeros as base58 zeros
    czero = 0
    pad = 0
    for c in d:
        if c == czero: pad += 1
        else: break
    return b58_digits[0] * pad + res

# TODO: This should be called base58_check_decode.
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
        raise exceptions.VersionByteError('incorrect version byte')
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

def serialise (encoding, inputs, destination_outputs, data_output=None, change_output=None, source=None, public_key=None):
    s  = (1).to_bytes(4, byteorder='little')                # Version

    # Number of inputs.
    s += var_int(int(len(inputs)))

    # List of Inputs.
    for i in range(len(inputs)):
        txin = inputs[i]
        s += binascii.unhexlify(bytes(txin['txid'], 'utf-8'))[::-1]         # TxOutHash
        s += txin['vout'].to_bytes(4, byteorder='little')   # TxOutIndex

        script = binascii.unhexlify(bytes(txin['scriptPubKey'], 'utf-8'))
        s += var_int(int(len(script)))                      # Script length
        s += script                                         # Script
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
    for address, value in destination_outputs:
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
        s += value.to_bytes(8, byteorder='little')        # Value

        if encoding == 'multisig':
            # Get data (fake) public key.
            pad_length = 33 - 1 - len(data_chunk)
            assert pad_length >= 0
            data_pubkey = bytes([len(data_chunk)]) + data_chunk + (pad_length * b'\x00')
            # Construct script.
            script = OP_1                                   # OP_1
            script += op_push(len(public_key))              # Push bytes of source public key
            script += public_key                            # Source public key
            script += op_push(len(data_pubkey))             # Push bytes of data chunk (fake) public key
            script += data_pubkey                           # Data chunk (fake) public key
            script += OP_2                                  # OP_2
            script += OP_CHECKMULTISIG                      # OP_CHECKMULTISIG
        elif encoding == 'opreturn':
            script = OP_RETURN                              # OP_RETURN
            script += op_push(len(data_chunk))              # Push bytes of data chunk (NOTE: OP_SMALLDATA?)
            script += data_chunk                            # Data chunk
        elif encoding == 'pubkeyhash':
            pad_length = 20 - 1 - len(data_chunk)
            assert pad_length >= 0
            obj1 = ARC4.new(binascii.unhexlify(inputs[0]['txid']))  # Arbitrary, easy‐to‐find, unique key.
            pubkeyhash = bytes([len(data_chunk)]) + data_chunk + (pad_length * b'\x00')
            pubkeyhash_encrypted = obj1.encrypt(pubkeyhash)
            # Construct script.
            script = OP_DUP                                     # OP_DUP
            script += OP_HASH160                                # OP_HASH160
            script += op_push(20)                               # Push 0x14 bytes
            script += pubkeyhash_encrypted                      # pubKeyHash
            script += OP_EQUALVERIFY                            # OP_EQUALVERIFY
            script += OP_CHECKSIG                               # OP_CHECKSIG
        else:
            raise exceptions.TransactionError('Unknown encoding‐scheme.')

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

def input_value_weight(amount):
    # Prefer outputs less than dust size, then bigger is better.
    if amount * config.UNIT <= config.DEFAULT_REGULAR_DUST_SIZE:
        return 0
    else:
        return 1 / amount

def sort_unspent_txouts(unspent, allow_unconfirmed_inputs):
    # Get deterministic results (for multiAPIConsensus type requirements), sort by timestamp and vout index.
    # (Oldest to newest so the nodes don’t have to be exactly caught up to each other for consensus to be achieved.)
    try:
        unspent = sorted(unspent, key=util.sortkeypicker(['ts', 'vout']))
    except KeyError: # If timestamp isn’t given.
        pass

    # Sort by amount.
    unspent = sorted(unspent,key=lambda x:input_value_weight(x['amount']))

    # Remove unconfirmed txouts, if desired.
    if allow_unconfirmed_inputs:
        # Hackish: Allow only inputs which are either already confirmed or were seen only recently. (Skip outputs from slow‐to‐confirm transanctions.)
        try:
            unspent = [coin for coin in unspent if (coin['confirmations'] > 0 or (time.time() - coin['ts']) < 6 * 3600)] # Cutoff: six hours
        except (KeyError, TypeError):
            pass
    else:
        unspent = [coin for coin in unspent if coin['confirmations'] > 0]

    return unspent

def private_key_to_public_key (private_key_wif):
    # allowable_wif_prefixes = [
    try:
        secret_exponent, compressed = wif_to_tuple_of_secret_exponent_compressed(private_key_wif, is_test=config.TESTNET)
    except EncodingError:
        raise exceptions.AltcoinSupportError('pycoin: unsupported WIF prefix')
    public_pair = public_pair_for_secret_exponent(generator_secp256k1, secret_exponent)
    public_key = public_pair_to_sec(public_pair, compressed=compressed)
    public_key_hex = binascii.hexlify(public_key).decode('utf-8')
    return public_key_hex

def transaction (tx_info, encoding='auto', fee_per_kb=config.DEFAULT_FEE_PER_KB,
                 regular_dust_size=config.DEFAULT_REGULAR_DUST_SIZE,
                 multisig_dust_size=config.DEFAULT_MULTISIG_DUST_SIZE,
                 op_return_value=config.DEFAULT_OP_RETURN_VALUE, exact_fee=None,
                 fee_provided=0, public_key_hex=None,
                 allow_unconfirmed_inputs=False):

    (source, destination_outputs, data) = tx_info

    # Data encoding methods.
    if data:
        if encoding == 'auto':
            if len(data) <= 40:
                # encoding = 'opreturn'
                encoding = 'multisig'   # BTCGuild isn’t mining OP_RETURN?!
            else:
                encoding = 'multisig'

        if encoding not in ('pubkeyhash', 'multisig', 'opreturn'):
            raise exceptions.TransactionError('Unknown encoding‐scheme.')

    if exact_fee and not isinstance(exact_fee, int):
        raise exceptions.TransactionError('Exact fees must be in satoshis.')
    if not isinstance(fee_provided, int):
        raise exceptions.TransactionError('Fee provided must be in satoshis.')

    # If public key is necessary for construction of (unsigned) transaction,
    # either use the public key provided, or derive it from a private key
    # retrieved from wallet.
    public_key = None
    if encoding in ('multisig', 'pubkeyhash'):
        # If no public key was provided, derive from private key.
        if not public_key_hex:
            # Get private key.
            if config.UNITTEST:
                private_key_wif = config.UNITTEST_PRIVKEY[source]
            else:
                private_key_wif = rpc('dumpprivkey', [source])

            # Derive public key.
            public_key_hex = private_key_to_public_key(private_key_wif)

        #convert public key hex into public key pair (sec)
        try:
            sec = binascii.unhexlify(public_key_hex)
            is_compressed = is_sec_compressed(sec)
            public_key = sec
        except (EncodingError, binascii.Error):
            raise exceptions.InputError('Invalid private key.')

    # Protocol change.
    if encoding == 'pubkeyhash' and get_block_count() < 293000 and not config.TESTNET:
        raise exceptions.TransactionError('pubkeyhash encoding unsupported before block 293000')

    # Validate source and all destination addresses.
    destinations = [address for address, value in destination_outputs]
    for address in destinations + [source]:
        if address:
            try:
                base58_decode(address, config.ADDRESSVERSION)
            except Exception:   # TODO
                raise exceptions.AddressError('Invalid Bitcoin address:', address)

    # Check that the source is in wallet.
    if not config.UNITTEST and encoding in ('multisig') and not public_key:
        if not rpc('validateaddress', [source])['ismine']:
            raise exceptions.AddressError('Not one of your Bitcoin addresses:', source)

    # Check that the destination output isn't a dust output.
    # Set null values to dust size.
    new_destination_outputs = []
    for address, value in destination_outputs:
        if encoding == 'multisig':
            if value == None: value = multisig_dust_size
            if not value >= multisig_dust_size:
                raise exceptions.TransactionError('Destination output is below the dust target value.')
        else:
            if value == None: value = regular_dust_size
            if not value >= regular_dust_size:
                raise exceptions.TransactionError('Destination output is below the dust target value.')
        new_destination_outputs.append((address, value))
    destination_outputs = new_destination_outputs

    # Divide data into chunks.
    if data:
        def chunks(l, n):
            """ Yield successive n‐sized chunks from l.
            """
            for i in range(0, len(l), n): yield l[i:i+n]
        if encoding == 'pubkeyhash':
            data_array = list(chunks(data + config.PREFIX, 20 - 1)) # Prefix is also a suffix here.
        elif encoding == 'multisig':
            data_array = list(chunks(data, 33 - 1))
        elif encoding == 'opreturn':
            data_array = list(chunks(data, config.OP_RETURN_MAX_SIZE))
            assert len(data_array) == 1 # Only one OP_RETURN output currently supported (OP_RETURN messages should all be shorter than 40 bytes, at the moment).
    else:
        data_array = []

    # Calculate total BTC to be sent.
    btc_out = 0
    if encoding == 'multisig': data_value = multisig_dust_size
    elif encoding == 'opreturn': data_value = op_return_value
    else: data_value = regular_dust_size # Pay‐to‐PubKeyHash
    btc_out = sum([data_value for data_chunk in data_array])
    btc_out += sum([value for address, value in destination_outputs])

    # Get size of outputs.
    if encoding == 'multisig': data_output_size = 81        # 71 for the data
    elif encoding == 'opreturn': data_output_size = 90      # 80 for the data
    else: data_output_size = 25 + 9                         # Pay‐to‐PubKeyHash (25 for the data?)
    outputs_size = ((25 + 9) * len(destination_outputs)) + (len(data_array) * data_output_size)

    # Get inputs.
    unspent = get_unspent_txouts(source, normalize=True)
    unspent = sort_unspent_txouts(unspent, allow_unconfirmed_inputs)
    logging.debug('Sorted UTXOs: {}'.format([print_coin(coin) for coin in unspent]))

    inputs, btc_in = [], 0
    change_quantity = 0
    sufficient_funds = False
    final_fee = fee_per_kb
    for coin in unspent:
        logging.debug('New input: {}'.format(print_coin(coin)))
        inputs.append(coin)
        btc_in += round(coin['amount'] * config.UNIT)

        # If exact fee is specified, use that. Otherwise, calculate size of tx and base fee on that (plus provide a minimum fee for selling BTC).
        if exact_fee:
            final_fee = exact_fee
        else:
            size = 181 * len(inputs) + outputs_size + 10
            necessary_fee = (int(size / 1000) + 1) * fee_per_kb
            final_fee = max(fee_provided, necessary_fee)
            assert final_fee >= 1 * fee_per_kb

        # Check if good.
        change_quantity = btc_in - (btc_out + final_fee)
        logging.debug('Change quantity: {} BTC'.format(change_quantity / config.UNIT))
        if change_quantity == 0 or change_quantity >= regular_dust_size: # If change is necessary, must not be a dust output.
            sufficient_funds = True
            break
    if not sufficient_funds:
        # Approximate needed change, fee by with most recently calculated quantities.
        total_btc_out = btc_out + max(change_quantity, 0) + final_fee
        raise exceptions.BalanceError('Insufficient bitcoins at address {}. (Need approximately {} {}.) To spend unconfirmed coins, use the flag `--unconfirmed`.'.format(source, total_btc_out / config.UNIT, config.BTC))

    # Construct outputs.
    if data: data_output = (data_array, data_value)
    else: data_output = None
    if change_quantity: change_output = (source, change_quantity)
    else: change_output = None

    # Serialise inputs and outputs.
    unsigned_tx = serialise(encoding, inputs, destination_outputs, data_output, change_output, source=source, public_key=public_key)
    unsigned_tx_hex = binascii.hexlify(unsigned_tx).decode('utf-8')
    return unsigned_tx_hex

def sign_tx (unsigned_tx_hex, private_key_wif=None):
    """Sign unsigned transaction serialisation."""

    if private_key_wif:
        # TODO: Hack! (pybitcointools is Python 2 only)
        import subprocess
        i = 0
        tx_hex = unsigned_tx_hex
        while True: # pybtctool doesn’t implement `signall`
            try:
                tx_hex = subprocess.check_output(['pybtctool', 'sign', tx_hex, str(i), private_key_wif], stderr=subprocess.DEVNULL)
            except Exception as e:
                break
        if tx_hex != unsigned_tx_hex:
            signed_tx_hex = tx_hex.decode('utf-8')
            return signed_tx_hex[:-1]   # Get rid of newline.
        else:
            raise exceptions.TransactionError('Could not sign transaction with pybtctool.')

    else:   # Assume source is in wallet and wallet is unlocked.
        result = rpc('signrawtransaction', [unsigned_tx_hex])
        if result['complete']:
            signed_tx_hex = result['hex']
        else:
            raise exceptions.TransactionError('Could not sign transaction with Bitcoin Core.')

    return signed_tx_hex

def broadcast_tx (signed_tx_hex):
    return send_raw_transaction(signed_tx_hex)

def normalize_quantity(quantity, divisible=True):
    if divisible:
        return float((D(quantity) / D(config.UNIT)).quantize(D('.00000000'), rounding=decimal.ROUND_HALF_EVEN))
    else: return quantity

def get_btc_supply(normalize=False):
    """returns the total supply of {} (based on what Bitcoin Core says the current block height is)""".format(config.BTC)
    block_count = get_block_count()
    blocks_remaining = block_count
    total_supply = 0
    reward = 50.0
    while blocks_remaining > 0:
        if blocks_remaining >= 210000:
            blocks_remaining -= 210000
            total_supply += 210000 * reward
            reward /= 2
        else:
            total_supply += (blocks_remaining * reward)
            blocks_remaining = 0
    return total_supply if normalize else int(total_supply * config.UNIT)

def get_unspent_txouts(address, normalize=False):
    """returns a list of unspent outputs for a specific address
    @return: A list of dicts, with each entry in the dict having the following keys:
    """
    if config.UNITTEST:
        CURR_DIR = os.path.dirname(os.path.realpath(os.path.join(os.getcwd(), os.path.expanduser(__file__))))
        with open(CURR_DIR + '/../test/listunspent.test.json', 'r') as listunspent_test_file:   # HACK
            wallet_unspent = json.load(listunspent_test_file)
            return [output for output in wallet_unspent if output['address'] == address]

    if rpc('validateaddress', [address])['ismine']:
        wallet_unspent = rpc('listunspent', [0, 999999])
        return [output for output in wallet_unspent if output['address'] == address]
    else:
        return blockchain.listunspent(address)

# vim: tabstop=8 expandtab shiftwidth=4 softtabstop=4
