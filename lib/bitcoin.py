"""
Craft, sign and broadcast Bitcoin transactions.
Interface with Bitcoind.
"""

import sys
import time
import binascii
import json
import hashlib
import requests

from . import (config, exceptions)

# Constants
OP_RETURN = b'\x6a'
OP_PUSHDATA1 = b'\x4c'
OP_DUP = b'\x76'
OP_HASH160 = b'\xa9'
OP_EQUALVERIFY = b'\x88'
OP_CHECKSIG = b'\xac'
b58_digits = '123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz'
# ADDRESSVERSION = b'\x00'      # mainnet
ADDRESSVERSION = b'\x6F'        # testnet

dhash = lambda x: hashlib.sha256(hashlib.sha256(x).digest()).digest()

def rpc (method, params):
    headers = {'content-type': 'application/json'}
    payload = {
        "method": method,
        "params": params,
        "jsonrpc": "2.0",
        "id": 0,
    }
    return requests.post(config.RPC, data=json.dumps(payload), headers=headers).json()

def bitcoind_check ():
    """Check blocktime of last block to see if `bitcoind` is running behind."""
    block_count = rpc('getblockcount', [])['result']
    block_hash = rpc('getblockhash', [block_count])['result']
    block = rpc('getblock', [block_hash])['result']
    if block['time'] < (time.time() - 60 * 60 * 2):
        raise exceptions.BitcoindBehindWarning('bitcoind is running behind.')  # This kills everything.

    # TODO: Make sure that follow() is running here?

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
    chk1 = dhash(addrbyte + data)[:4]
    if chk0 != chk1:
        raise exceptions.Base58ChecksumError('Checksum mismatch: %r ≠ %r' % (chk0, ch1))
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

# HACK
def eligius (signed_hex):
    import subprocess
    text = '''import mechanize                                                                
browser = mechanize.Browser(factory=mechanize.RobustFactory())
browser.open('http://eligius.st/~wizkid057/newstats/pushtxn.php')
browser.select_form(nr=0)
browser.form['transaction'] = \"''' + signed_hex +  '''\"
browser.submit()
html = browser.response().readlines()
for i in range(0,len(html)):
    if 'string' in html[i]:
        print(html[i].strip())
        break'''
    return subprocess.call(["python2", "-c", text])

def serialize (inputs, outputs, data):
    s  = (1).to_bytes(4, byteorder='little')                # Version

    # Number of inputs.
    s += var_int(int(len(inputs)))

    # List of Inputs.
    for i in range(len(inputs)):
        txin = inputs[i]
        s += binascii.unhexlify(txin['txid'])[::-1]         # TxOutHash
        s += txin['vout'].to_bytes(4, byteorder='little')   # TxOutIndex

        # No signature.
        script = b''
        s += var_int(int(len(script)))                      # Script length
        s += script                                         # Script
        s += b'\xff' * 4                                    # Sequence

    # Number of outputs (including data output).
    s += var_int(len(outputs) + 1)

    # List of regular outputs.
    for address, value in outputs:
        s += value.to_bytes(8, byteorder='little')          # Value
        script = OP_DUP                                     # OP_DUP
        script += OP_HASH160                                # OP_HASH160
        script += op_push(20)                               # Push 0x14 bytes
        script += base58_decode(address, ADDRESSVERSION)    # Address (pubKeyHash)
        script += OP_EQUALVERIFY                            # OP_EQUALVERIFY
        script += OP_CHECKSIG                               # OP_CHECKSIG
        s += var_int(int(len(script)))                      # Script length
        s += script

    # Data output.
    s += (0).to_bytes(8, byteorder='little')                # Value
    script = OP_RETURN                                      # OP_RETURN
    script += op_push(len(data))                            # Push bytes of data (NOTE: OP_SMALLDATA?)
    script += data                                          # Data
    s += var_int(int(len(script)))                          # Script length
    s += script

    s += (0).to_bytes(4, byteorder='little')                # LockTime
    return s

def get_inputs (source, amount, fee):
    """List unspent inputs for source."""
    listunspent = rpc('listunspent', [])['result']
    unspent = [coin for coin in listunspent if coin['address'] == source]
    inputs, total = [], 0
    for coin in unspent:                                                      
        if not coin['confirmations']:
            continue    # Blocks or it didn’t happen. TODO: Reconsider this.
        inputs.append(coin)
        total += int(coin['amount'] * config.UNIT)
        if total >= amount + fee:
            return inputs, total
    return None, None

def transaction (source, destination, btc_amount, fee, data):
    # Validate addresses.
    for address in (source, destination):
        if address:
            if not rpc('validateaddress', [address])['result']['isvalid']:
                raise exceptions.InvalidAddressError('Not a valid Bitcoin address:',
                                          address)

    # Check that the source is in wallet.
    if not rpc('validateaddress', [source])['result']['ismine']:
        raise exceptions.InvalidAddressError('Not one of your Bitcoin addresses:', source)

    # TODO: check that btc_amount >= config.DUST_SIZE

    # Construct inputs.
    inputs, total = get_inputs(source, btc_amount, fee)
    if not inputs:
        raise exceptions.BalanceError('Insufficient bitcoins.')

    # Construct outputs.
    change_amount = total - fee
    outputs = []
    if destination:
        outputs.append((destination, btc_amount))
        change_amount -= btc_amount
    if change_amount:
        outputs.append((source, change_amount))

    # Serialise inputs and outputs.
    transaction = serialize(inputs, outputs, data)
    transaction_hex = binascii.hexlify(transaction).decode('utf-8')

    # Confirm transaction.
    if config.PREFIX == b'TEST': print('Attention: COUNTERPARTY TEST!') 
    if ADDRESSVERSION == b'0x6F': print('\nAttention: BITCOIN TESTNET!\n') 
    if input('Confirm? (y/N) ') != 'y':
        print('Transaction aborted.', file=sys.stderr)
        sys.exit(1)

    # Sign transaction.
    response = rpc('signrawtransaction', [transaction_hex])
    result = response['result']
    if result:
        if result['complete']:
            # return eligius(result['hex'])                     # mainnet HACK
            return rpc('sendrawtransaction', [result['hex']])
    else:
        return response['error']

# vim: tabstop=8 expandtab shiftwidth=4 softtabstop=4
