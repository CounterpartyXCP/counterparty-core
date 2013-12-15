#! /usr/bin/env python3


import sys
import os
import argparse
import time
import binascii
import struct
import json
import hashlib

import sqlite3
import requests
import appdirs
import decimal
D = decimal.Decimal
decimal.getcontext().prec = 8


# Bitcoin protocol
UNIT = 100000000                # The same across currencies.
DUST_SIZE = 5430
MIN_FEE = 30000

OP_RETURN = b'\x6a'
OP_PUSHDATA1 = b'\x4c'
OP_DUP = b'\x76'
OP_HASH160 = b'\xa9'
OP_EQUALVERIFY = b'\x88'
OP_CHECKSIG = b'\xac'

b58_digits = '123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz'
# ADDRESSVERSION = b'\x00'      # mainnet
ADDRESSVERSION = b'\x6F'        # testnet


# Counterparty protocol
# PREFIX = b'CPCOINXXXX'        # 10 bytes
PREFIX = b'TEST'                # 4 bytes (possibly accidentally created)

# BLOCK_FIRST = 273648          # mainnet
BLOCK_FIRST = 153560            # testnet

TXTYPE_FORMAT = '>I'
SEND_FORMAT = '>QQ'             # asset_id, amount
ORDER_FORMAT = '>QQQQHQ'        # give_id, give_amount, get_id, get_amount, expiration, fee_required
BTCPAYMENT_FORMAT = '>32s32s'   # tx0_hash, tx1_hash
ISSUANCE_FORMAT = '>QQ?'        # asset_id, amount, divisible

# Obsolete in Python 3.4.
ASSET_NAME = {0: 'BTC', 1: 'XCP'}
ASSET_ID = {'BTC': 0, 'XCP': 1}
MESSAGE_TYPE_NAME = {0: 'send', 10: 'order', 11: 'btcpayment', 20: 'issuance'}
MESSAGE_TYPE_ID = {'send': 0, 'order': 10, 'btcpayment': 11, 'issuance': 20}


# Exceptions
class BitcoinConfError(Exception):
    pass
class UselessError (Exception):
    pass
class InvalidAddressError (Exception):
    pass
class BalanceError (Exception):
    pass
class IssuanceError (Exception):
    pass
class InvalidDealError (Exception):
    pass
class Base58Error (Exception):
    pass
class InvalidBase58Error (Base58Error):
    pass
class Base58ChecksumError (Base58Error):
    pass


# Warnings
class DBVersionWarning (Exception):
    pass
class BitcoindBehindWarning (Exception):
    pass


# JSON‐RPC Options
CONFIGFILE = os.path.expanduser('~') + '/.bitcoin/bitcoin.conf'
RPCCONNECT = 'localhost'
# RPCPORT = '8332'  # mainnet
RPCPORT = '18332'   # testnet
try:
    with open(CONFIGFILE, 'r') as configfile:
        for line in configfile.readlines():
            if line.startswith('#'):
                continue
            array = line.replace('\n', '').split('=')
            if len(array) != 2:
                continue
            key, value = array[:2]
            if key == 'rpcuser': RPCUSER = value
            elif key == 'rpcpassword': RPCPASSWORD = value
            elif key == 'rpcconnect': RPCCONNECT = value
            elif key == 'rpcport': RPCCONNECT = value
except Exception:
    raise BitcoinConfError('Put a (valid) copy of your bitcoin.conf in\
        ~/.bitcoin/bitcoin.conf')
    sys.exit(1)
RPC = 'http://'+RPCUSER+':'+RPCPASSWORD+'@'+RPCCONNECT+':'+RPCPORT

# Database location
data_dir = appdirs.user_data_dir('Counterparty', 'Counterparty')
if not os.path.isdir(data_dir):
    os.mkdir(data_dir)
DB_VERSION = 1
LEDGER = data_dir + '/ledger.' + str(DB_VERSION) + '.db'


json_print = lambda x: print(json.dumps(x, sort_keys=True, indent=4))
dhash = lambda x: hashlib.sha256(hashlib.sha256(x).digest()).digest()


def base58_decode (s, version):
    # Convert the string to an integer
    n = 0
    for c in s:
        n *= 58
        if c not in b58_digits:
            raise InvalidBase58Error('Not a valid base58 character:', c)
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
        raise Base58ChecksumError('Checksum mismatch: %r ≠ %r' % (chk0, ch1))
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


def rpc (method, params):
    headers = {'content-type': 'application/json'}
    payload = {
        "method": method,
        "params": params,
        "jsonrpc": "2.0",
        "id": 0,
    }
    return requests.post(RPC, data=json.dumps(payload), headers=headers).json()

def bitcoind_check ():
    """Check blocktime of last block to see if `bitcoind` is running behind."""
    block_count = rpc('getblockcount', [])['result']
    block_hash = rpc('getblockhash', [block_count])['result']
    block = rpc('getblock', [block_hash])['result']
    if block['time'] < (time.time() - 60 * 60 * 2):
        raise BitcoindBehindWarning('bitcoind is running behind.')  # This kills everything.

    # TODO: Make sure that follow() is running here?


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
            continue    # Blocks or it didn’t happen.
        inputs.append(coin)
        total += int(coin['amount'] * UNIT)
        if total >= amount + fee:
            return inputs, total
    return None, None

def transaction (source, destination, btc_amount, fee, data):
    # Validate addresses.
    for address in (source, destination):
        if address:
            if not rpc('validateaddress', [address])['result']['isvalid']:
                raise InvalidAddressError('Not a valid Bitcoin address:',
                                          address)

    # Check that the source is in wallet.
    if not rpc('validateaddress', [source])['result']['ismine']:
        raise InvalidAddressError('Not one of your Bitcoin addresses:', source)

    # Construct inputs.
    inputs, total = get_inputs(source, btc_amount, fee)
    if not inputs:
        raise BalanceError('Insufficient bitcoins.')

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
    if PREFIX == b'TEST': print('Attention: COUNTERPARTY TEST!') 
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


def send (source, destination, amount, asset_id):
    if balance(source, asset_id) < amount:
        raise BalanceError('Insufficient funds. (Check that the database is up‐to‐date.)')
    data = PREFIX + struct.pack(TXTYPE_FORMAT, MESSAGE_TYPE_ID['send']) + struct.pack(SEND_FORMAT, asset_id, amount)
    return transaction(source, destination, DUST_SIZE, MIN_FEE, data)

def order (source, give_id, give_amount, get_id, get_amount, expiration, fee_required, fee_provided):
    if balance(source, give_id) < give_amount:
        raise BalanceError('Insufficient funds. (Check that the database is up‐to‐date.)')
    data = PREFIX + struct.pack(TXTYPE_FORMAT, MESSAGE_TYPE_ID['order']) + struct.pack(ORDER_FORMAT, give_id, give_amount, get_id, get_amount, expiration, fee_required)
    return transaction(source, None, DUST_SIZE, fee_provided, data)

def btcpayment (deal_id):
    tx0_hash, tx1_hash = deal_id[:64], deal_id[64:] # UTF‐8 encoding means that the indices are doubled.
    tx0_hash_bytes, tx1_hash_bytes = binascii.unhexlify(tx0_hash), binascii.unhexlify(tx1_hash)
    data = PREFIX + struct.pack(TXTYPE_FORMAT, MESSAGE_TYPE_ID['btcpayment']) + struct.pack(BTCPAYMENT_FORMAT, tx0_hash_bytes, tx1_hash_bytes)

    db = sqlite3.connect(LEDGER)
    db.row_factory = sqlite3.Row
    cursor = db.cursor()

    cursor.execute('''SELECT * FROM deals \
                      WHERE (tx0_hash=? AND tx1_hash=?)''',
                   (tx0_hash, tx1_hash))
    deal = cursor.fetchone()
    assert not cursor.fetchone()
    try:
        if not deal['backward_id']:
            source = deal['tx1_address']
            destination = deal['tx0_address']
            btc_amount = deal['backward_amount']
        else:
            source = deal['tx0_address']
            destination = deal['tx1_address']
            btc_amount = deal['forward_amount']
        if source == destination:
            raise UselessError('You’re trying to buy from yourself!')
    except TypeError:
        raise InvalidDealError('Invalid Deal ID:', deal_id)

    return transaction(source, destination, btc_amount, MIN_FEE, data)

def issuance (source, asset_id, amount, divisible):
    db = sqlite3.connect(LEDGER)
    db.row_factory = sqlite3.Row
    cursor = db.cursor()
    # Avoid duplicates.
    cursor.execute('''SELECT * FROM issuances WHERE (asset_id=? AND validity=?)''', (asset_id, 'Valid'))
    if cursor.fetchone():
        raise IssuanceError('Asset ID already claimed.')
    data = PREFIX + struct.pack(TXTYPE_FORMAT, MESSAGE_TYPE_ID['issuance']) + struct.pack(ISSUANCE_FORMAT, asset_id, amount, divisible)
    db.close()
    return transaction(source, None, DUST_SIZE, MIN_FEE, data)


def make_deal (db, cursor, give_id, give_amount, get_id, get_amount,
        ask_price, expiration, fee_required, tx1):
    cursor.execute('''SELECT * FROM orders \
                      WHERE (give_id=? AND get_id=? AND block_index>=?) \
                      ORDER BY ask_price ASC, tx_index''',
                   (get_id, give_id, tx1['block_index'] - expiration))
    give_remaining = give_amount
    for tx0 in cursor.fetchall():
        # NOTE: tx0 is an order; tx1 is a transaction.

        # Check whether fee conditions are satisfied.
        if not get_id and tx0['fee_provided'] < fee_required: continue
        elif not give_id and tx1['fee'] < tx0['fee_required']: continue

        # Make sure that that both orders still have funds remaining [to be sold].
        if tx0['give_remaining'] <= 0 or give_remaining <= 0: continue

        # If the prices agree, make the trade. The found order sets the price,
        # and they trade as much as they can.
        price = D(tx0['get_amount']) / D(tx0['give_amount'])
        if price <= 1/ask_price:  # Ugly
            forward_amount = min(D(tx0['give_remaining']),
                                     get_amount / price)
            backward_amount = give_amount * forward_amount/D(tx0['give_amount'])

            forward_id, backward_id = get_id, give_id
            forward_name, backward_name = ASSET_NAME[forward_id], ASSET_NAME[backward_id]
            deal_id = tx0['tx_hash'] + tx1['tx_hash']

            cursor, forward_divisible = is_divisible(cursor, forward_id)
            if forward_divisible: forward_unit = UNIT
            else: forward_unit = 1
            cursor, backward_divisible = is_divisible(cursor, forward_id)
            if backward_divisible: backward_unit = UNIT
            else: backward_unit = 1
            print('\t\tDeal:', forward_amount/forward_unit, forward_name, 'for', backward_amount/backward_unit, backward_name, 'at', price, backward_name + '/' + forward_name, '(' + deal_id + ')') # TODO

            if ASSET_ID['BTC'] in (give_id, get_id):
                validity = 'Valid: waiting for bitcoins'
            else:
                validity = 'Valid'
                # Credit.
                db, cursor = credit(db, cursor, tx1['source'], get_id,
                                    forward_amount)
                db, cursor = credit(db, cursor, tx0['source'], tx0['get_id'],
                                    backward_amount)

            # Debit the order, even if it involves giving bitcoins, and so one
            # can’t debit the sending account.
            give_remaining -= backward_amount

            # Update give_remaining.
            cursor.execute('''UPDATE orders \
                              SET give_remaining=? \
                              WHERE tx_hash=?''',
                          (int(tx0['give_remaining'] - forward_amount),
                           tx0['tx_hash']))
            cursor.execute('''UPDATE orders \
                              SET give_remaining=? \
                              WHERE tx_hash=?''',
                          (int(give_remaining),
                           tx1['tx_hash']))

            # Record order fulfillment.
            cursor.execute('''INSERT into deals(
                                tx0_index,
                                tx0_hash,
                                tx0_address,
                                tx1_index,
                                tx1_hash,
                                tx1_address,
                                forward_id,
                                forward_amount,
                                backward_id,
                                backward_amount,
                                tx0_block_index,
                                tx1_block_index,
                                tx0_expiration,
                                tx1_expiration,
                                validity) VALUES(?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)''',
                                (tx0['tx_index'],
                                tx0['tx_hash'],
                                tx0['source'],
                                tx1['tx_index'],
                                tx1['tx_hash'],
                                tx1['source'],
                                forward_id,
                                int(forward_amount),
                                backward_id,
                                int(backward_amount),
                                tx0['block_index'],
                                tx1['block_index'],
                                tx0['expiration'],
                                expiration,
                                validity)
                          )
            db.commit()
    return db, cursor


def balance (source, asset_id):
    db = sqlite3.connect(LEDGER)
    db.row_factory = sqlite3.Row
    cursor = db.cursor()
    if not asset_id == 0: # If not BTC…
        try:
            cursor.execute('''SELECT * FROM balances \
                              WHERE (address=? and asset_id=?)''',
                           (source, asset_id))
            balance = cursor.fetchone()['amount']
            assert not cursor.fetchone()
        except Exception: # Be specific.
            balance = None
    else:   # HACK (fragile)
        import subprocess
        # balance = int(subprocess.check_output(['curl','-s', 'http://blockchain.info/q/addressbalance/' + source]))    # mainnet
        balance = 100 * UNIT    # *** testnet DOUBLE HACK! ***
    cursor.close()
    return balance

# This will never even try to debit bitcoins.
def debit (db, cursor, address, asset_id, amount):
    cursor.execute('''SELECT * FROM balances WHERE (address=? and asset_id=?)''',
                   (address, asset_id))
    try:
        old_balance = cursor.fetchone()['amount']
    except TypeError:
        old_balance = 0
    finally:
        assert not cursor.fetchone()
        if old_balance >= amount:
            cursor.execute('''UPDATE balances SET amount=? WHERE (address=? and asset_id=?)''',
                           (int(old_balance - amount), address, asset_id)) 
            validity = 'Valid'
        else:
            validity = 'Invalid: insufficient funds'
    db.commit()
    return db, cursor, validity

def credit (db, cursor, address, asset_id, amount):
    old_balance = balance(address, asset_id)
    if old_balance == None:
        cursor.execute('''INSERT INTO balances(
                            address,
                            asset_id,
                            amount) VALUES(?,?,?)''',
                            (address,
                            asset_id,
                            amount)
                      )
    else:
        cursor.execute('''UPDATE balances SET amount=? WHERE (address=? and asset_id=?)''',
                   (old_balance + amount, address, asset_id)) 
    db.commit()
    return db, cursor

def is_divisible(cursor, asset_id):
    cursor.execute('''SELECT * FROM issuances \
                      WHERE asset_id=?''', (asset_id,))
    asset = cursor.fetchone()
    assert not cursor.fetchone()
    return cursor, asset['divisible']

def parse_send (db, cursor, tx, message):
    # Ask for forgiveness…
    validity = 'Valid'

    # Unpack message.
    try:
        asset_id, amount = struct.unpack(SEND_FORMAT, message)
    except Exception:
        asset_id, amount = None, None
        validity = 'Invalid: could not unpack'

    # Debit.
    if validity == 'Valid':
        db, cursor, validity = debit(db, cursor, tx['source'], asset_id, amount)

    # Credit.
    if validity == 'Valid':
        db, cursor = credit(db, cursor, tx['destination'], asset_id, amount)

    # Add parsed transaction to message‐type–specific table.
    cursor.execute('''INSERT INTO sends(
                        tx_index,
                        tx_hash,
                        block_index,
                        source,
                        destination,
                        asset_id,
                        amount,
                        validity) VALUES(?,?,?,?,?,?,?,?)''',
                        (tx['tx_index'],
                        tx['tx_hash'],
                        tx['block_index'],
                        tx['source'],
                        tx['destination'],
                        asset_id,
                        amount,
                        validity)
                  )
    cursor, divisible = is_divisible(cursor, asset_id)
    if divisible:
        unit = UNIT
    else:
        unit = 1
    try:    # TEMP
        asset_name = ASSET_NAME[asset_id]
    except Exception:
        asset_name = asset_id
    print('\tSend:', amount/unit, asset_name, 'from', tx['source'], 'to', tx['destination'], '(' + tx['tx_hash'] + ')')
    return db, cursor


def parse_order (db, cursor, tx1, message):
    # Ask for forgiveness…
    validity = 'Valid'

    # Unpack message.
    try:
        give_id, give_amount, get_id, get_amount, expiration, fee_required = struct.unpack(ORDER_FORMAT, message)
    except Exception:
        give_id, give_amount, get_id, get_amount, expiration, fee_required = None, None, None, None, None, None
        validity = 'Invalid: could not unpack'

    assert give_id != get_id    # TODO

    give_amount = D(give_amount)
    get_amount = D(get_amount)
    ask_price = get_amount / give_amount

    # Debit the address that makes the order. Check for sufficient funds.
    if validity == 'Valid':
        if balance(tx1['source'], give_id) >= give_amount:
            if give_id:  # No need (or way) to debit BTC.
                db, cursor, validity = debit(db, cursor, tx1['source'], give_id, give_amount)
        else:
            validity = 'Invalid: insufficient funds.'

    # Add parsed transaction to message‐type–specific table.
    cursor.execute('''INSERT INTO orders(
                        tx_index,
                        tx_hash,
                        block_index,
                        source,
                        give_id,
                        give_amount,
                        give_remaining,
                        get_id,
                        get_amount,
                        ask_price,
                        expiration,
                        fee_required,
                        fee_provided,
                        validity) VALUES(?,?,?,?,?,?,?,?,?,?,?,?,?,?)''',
                        (tx1['tx_index'],
                        tx1['tx_hash'],
                        tx1['block_index'],
                        tx1['source'],
                        give_id,
                        int(give_amount),
                        int(give_amount),
                        get_id,
                        int(get_amount),
                        float(ask_price),
                        expiration,
                        fee_required,
                        tx1['fee'],
                        validity)
                  )
    db.commit()

    if validity == 'Valid':
        give_name, get_name = ASSET_NAME[give_id], ASSET_NAME[get_id]
        cursor, give_divisible = is_divisible(cursor, give_id)
        if give_divisible: give_unit = UNIT
        else: give_unit = 1
        cursor, get_divisible = is_divisible(cursor, get_id)
        if get_divisible: get_unit = UNIT
        else: get_unit = 1
        print('\tOrder: sell', give_amount/give_unit, give_name, 'for', get_amount/get_unit, get_name, 'at', ask_price, get_name + '/' + give_name, 'in', expiration, 'blocks', '(' + tx1['tx_hash'] + ')') # TODO (and fee_required, fee_provided)

        db, cursor = make_deal(db, cursor, give_id, give_amount, get_id, get_amount, ask_price, expiration, fee_required, tx1)

    return db, cursor

def parse_btcpayment (db, cursor, tx, message):
    # Ask for forgiveness…
    validity = 'Valid'

    # Unpack message.
    try:
        tx0_hash_bytes, tx1_hash_bytes = struct.unpack(BTCPAYMENT_FORMAT, message)
        tx0_hash, tx1_hash = binascii.hexlify(tx0_hash_bytes).decode('utf-8'), binascii.hexlify(tx1_hash_bytes).decode('utf-8')
    except Exception:
        tx0_hash, tx1_hash = None, None
        validity = 'Invalid: could not unpack'

    cursor.execute('''SELECT * FROM deals WHERE (tx0_hash=? AND tx1_hash=?)''', (tx0_hash, tx1_hash))
    deal = cursor.fetchone()
    assert not cursor.fetchone()
    # Credit source address for the currency that he bought with the bitcoins.
    # BTC must be paid all at once and come from the ‘correct’ address.
    if deal['tx0_address'] == tx['source'] and tx['btc_amount'] >= deal['forward_amount']:
        cursor.execute('''UPDATE deals SET validity=? WHERE (tx0_hash=? AND tx1_hash=?)''', ('Valid', tx0_hash, tx1_hash))
        db.commit()
        if deal['backward_id']:    # Gratuitous
            db, cursor = credit(db, cursor, tx['source'], deal['backward_id'], deal['backward_amount'])
    if deal['tx1_address'] == tx['source'] and tx['btc_amount'] >= deal['backward_amount']:
        cursor.execute('''UPDATE deals SET validity=? WHERE (tx0_hash=? AND tx1_hash=?)''', ('Valid', tx0_hash, tx1_hash))
        if deal['forward_id']:     # Gratuitous
            db, cursor = credit(db, cursor, tx['source'], deal['forward_id'], deal['forward_amount'])

    deal_id = tx0_hash + tx1_hash
    print('\tBTC payment for deal:', deal_id, '(' + tx['tx_hash'] + ')')

    return db, cursor

def parse_issuance (db, cursor, tx, message):
    # Ask for forgiveness…
    validity = 'Valid'

    # Unpack message.
    try:
        asset_id, amount, divisible = struct.unpack(ISSUANCE_FORMAT, message)
    except Exception:
        asset_id, amount, divisible = None, None
        validity = 'Invalid: could not unpack'

    # Avoid duplicates.
    cursor.execute('''SELECT * FROM issuances WHERE (asset_id=? AND validity=?)''', (asset_id, 'Valid'))
    if cursor.fetchone():
        validity = 'Invalid: duplicate Asset ID'

    # Credit.
    if validity == 'Valid':
        db, cursor = credit(db, cursor, tx['source'], asset_id, amount)
        if divisible: unit = UNIT
        else: unit = 1
        print('\tIssuance:', tx['source'], 'created', amount/unit, 'of asset', asset_id, '(' + tx['tx_hash'] + ')')

    # Add parsed transaction to message‐type–specific table.
    cursor.execute('''INSERT INTO issuances(
                        asset_id,
                        amount,
                        divisible,
                        tx_index,
                        tx_hash,
                        block_index,
                        source,
                        validity) VALUES(?,?,?,?,?,?,?,?)''',
                        (asset_id,
                        amount,
                        divisible,
                        tx['tx_index'],
                        tx['tx_hash'],
                        tx['block_index'],
                        tx['source'],
                        validity)
                  )

    return db, cursor



def initialise(db, cursor):
    cursor.execute('''CREATE TABLE IF NOT EXISTS blocks(
                        block_index INTEGER PRIMARY KEY,
                        block_hash TEXT UNIQUE,
                        block_time INTEGER)
                   ''')

    cursor.execute('''CREATE TABLE IF NOT EXISTS transactions(
                        tx_index INTEGER PRIMARY KEY,
                        tx_hash TEXT UNIQUE,
                        block_index INTEGER,
                        block_time INTEGER,
                        source TEXT,
                        destination TEXT,
                        btc_amount INTEGER,
                        fee INTEGER,
                        data BLOB,
                        supported TEXT DEFAULT 'True')
                    ''')

    # Purge database of blocks, transactions from before BLOCK_FIRST.
    cursor.execute('''DELETE FROM blocks WHERE block_index<?''', (BLOCK_FIRST,))
    cursor.execute('''DELETE FROM transactions WHERE block_index<?''', (BLOCK_FIRST,))

    cursor.execute('''DROP TABLE IF EXISTS balances''')
    cursor.execute('''CREATE TABLE balances(
                        address TEXT,
                        asset_id INTEGER,
                        amount INTEGER)
                   ''')

    cursor.execute('''DROP TABLE IF EXISTS sends''')
    cursor.execute('''CREATE TABLE sends(
                        tx_index INTEGER PRIMARY KEY,
                        tx_hash TEXT UNIQUE,
                        block_index INTEGER,
                        source TEXT,
                        destination TEXT,
                        asset_id INTEGER,
                        amount INTEGER,
                        validity TEXT)
                   ''')

    cursor.execute('''DROP TABLE IF EXISTS orders''')
    cursor.execute('''CREATE TABLE orders(
                        tx_index INTEGER PRIMARY KEY,
                        tx_hash TEXT UNIQUE,
                        block_index INTEGER,
                        source TEXT,
                        give_id INTEGER,
                        give_amount INTEGER,
                        give_remaining INTEGER,
                        get_id INTEGER,
                        get_amount INTEGER,
                        ask_price REAL,
                        expiration INTEGER,
                        fee_required INTEGER,
                        fee_provided INTEGER,
                        validity TEXT)
                   ''')

    cursor.execute('''DROP TABLE IF EXISTS deals''')
    cursor.execute('''CREATE TABLE deals(
                        tx0_index INTEGER,
                        tx0_hash TEXT,
                        tx0_address TEXT,
                        tx1_index INTEGER,
                        tx1_hash TEXT,
                        tx1_address TEXT,
                        forward_id INTEGER,
                        forward_amount INTEGER,
                        backward_id INTEGER,
                        backward_amount INTEGER,
                        tx0_block_index INTEGER,
                        tx1_block_index INTEGER,
                        tx0_expiration INTEGER,
                        tx1_expiration INTEGER,
                        validity TEXT)
                   ''')

    cursor.execute('''DROP TABLE IF EXISTS issuances''')
    cursor.execute('''CREATE TABLE issuances(
                        asset_id INTEGER PRIMARY KEY,
                        amount INTEGER,
                        divisible BOOL,
                        tx_index INTEGER UNIQUE,
                        tx_hash TEXT UNIQUE,
                        block_index INTEGER,
                        source TEXT,
                        validity TEXT)
                   ''')

    # TEMP
    for asset_id in (0,1):
        cursor.execute('''INSERT INTO issuances(
                            asset_id,
                            amount,
                            divisible,
                            tx_index,
                            tx_hash,
                            block_index,
                            source,
                            validity) VALUES(?,?,?,?,?,?,?,?)''',
                            (asset_id,
                            0,
                            True,
                            None,
                            None,
                            None,
                            None,
                            'Valid')
                      )

    return db, cursor


def parse_block (db, cursor, block_index):
    """This is a separate function from follow() so that changing the parsing
    rules doesn’t require a full database rebuild. If parsing rules are changed
    (but not data identification), then just restart `counterparty.py follow`.

    """
    print('Block:', block_index) #

    # Initialize XCP balances.
    if block_index == BLOCK_FIRST:
        for address in ('mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',
                        'mnkzHBHRkBWoP9aFtocDe5atxmRfSRHnjR'):
            db, cursor = credit(db, cursor, address, ASSET_ID['XCP'], 10000 * int(UNIT))
        db.commit()

    # Parse transactions, sorting them by type.
    cursor.execute('''SELECT * FROM transactions \
                      WHERE block_index=? ORDER BY tx_index''',
                   (block_index,))
        
    for tx in cursor.fetchall():
        if tx['data'][:len(PREFIX)] == PREFIX:
            post_prefix = tx['data'][len(PREFIX):]
        else:
            continue
        message_type_id = struct.unpack(TXTYPE_FORMAT, post_prefix[:4])[0]
        message = post_prefix[4:]
        # TODO: Make sure that message lengths are correct. (struct.unpack is fragile.)
        if message_type_id == MESSAGE_TYPE_ID['send']:
            db, cursor = parse_send(db, cursor, tx, message)
        elif message_type_id == MESSAGE_TYPE_ID['order']:
            db, cursor = parse_order(db, cursor, tx, message)
        elif message_type_id == MESSAGE_TYPE_ID['btcpayment']:
            db, cursor = parse_btcpayment(db, cursor, tx, message)
        elif message_type_id == MESSAGE_TYPE_ID['issuance']:
            db, cursor = parse_issuance(db, cursor, tx, message)
        else:
            # Mark transaction as of unsupported type.
            cursor.execute('''UPDATE transactions \
                              SET supported=? \
                              WHERE tx_hash=?''',
                           (tx['tx_hash'], 'False'))
        db.commit()

    # Expire orders and give refunds.
    cursor.execute('''SELECT * FROM orders''')
    for order in cursor.fetchall():
        time_left = order['block_index'] + order['expiration'] - block_index # Inclusive/exclusive expiration? DUPE
        if time_left <= 0 and order['validity'] == 'Valid':
            cursor.execute('''UPDATE orders SET validity=? WHERE tx_hash=?''', ('Invalid: expired', order['tx_hash']))
            db, cursor = credit(db, cursor, order['source'], order['give_id'], order['give_amount'])
            print('\tExpired order:', order['tx_hash'])
        db.commit()

    # Expire deals for BTC with no BTC.
    cursor.execute('''SELECT * FROM deals''')
    for deal in cursor.fetchall():
        tx0_time_left = deal['tx0_block_index'] + deal['tx0_expiration'] - block_index # Inclusive/exclusive expiration? DUPE
        tx1_time_left = deal['tx1_block_index'] + deal['tx1_expiration'] - block_index # Inclusive/exclusive expiration? DUPE
        if (tx0_time_left <= 0 or tx1_time_left <=0) and deal['validity'] == 'Valid: waiting for bitcoins':
            cursor.execute('''UPDATE deals SET validity=? WHERE (tx0_hash=? AND tx1_hash=?)''', ('Invalid: expired while waiting for bitcoins', deal['tx0_hash'], deal['tx1_hash']))
            if not deal['forward_id']:
                db, cursor = credit(db, cursor, deal['tx1_address'],
                                    deal['backward_id'],
                                    deal['backward_amount'])
            elif not deal['backward_id']:
                db, cursor = credit(db, cursor, deal['tx0_address'],
                                    deal['forward_id'],
                                    deal['forward_amount'])
            print('\tExpired deal waiting for bitcoins:',
                  deal['tx0_hash'] + deal['tx1_hash'])    # TODO
    db.commit()

    return db, cursor


def get_tx_info (tx):
    fee = 0

    # Collect all possible source addresses; ignore coinbase transactions.
    source_list = []
    for vin in tx['vin']:                                               # Loop through input transactions.
        if 'coinbase' in vin: return None, None, None, None, None
        vin_tx = rpc('getrawtransaction', [vin['txid'], 1])['result']   # Get the full transaction data for this input transaction.
        vout = vin_tx['vout'][vin['vout']]
        fee += vout['value'] * UNIT
        source_list.append(vout['scriptPubKey']['addresses'][0])        # Assume that the output was not not multi‐sig.

    # Require that all possible source addresses be the same.
    if all(x == source_list[0] for x in source_list): source = source_list[0]
    else: source = None

    # Destination is the first output with a valid address, (if it exists).
    destination, btc_amount = None, None
    for vout in tx['vout']:
        if 'addresses' in vout['scriptPubKey']:
            address = vout['scriptPubKey']['addresses'][0]
            if rpc('validateaddress', [address])['result']['isvalid']:
                destination, btc_amount = address, vout['value'] * UNIT
                break

    for vout in tx['vout']:
        fee -= vout['value'] * UNIT

    # Loop through outputs until you come upon OP_RETURN, then get the data.
    # NOTE: This assumes only one OP_RETURN output.
    data = None
    for vout in tx['vout']:
        asm = vout['scriptPubKey']['asm'].split(' ')
        if asm[0] == 'OP_RETURN' and len(asm) == 2:
            data = binascii.unhexlify(asm[1])

    return source, destination, btc_amount, fee, data

def follow ():

    # Find and delete old versions of the database.
    os.chdir(data_dir)
    for filename in os.listdir('.'):
        filename_array = filename.split('.')
        if len(filename_array) != 3:
            continue
        if 'ledger' == filename_array[0] and 'db' == filename_array[2]:
            if filename_array[1] != str(DB_VERSION):
                os.remove(filename)
                raise DBVersionWarning('Hard‐fork! Deleting old databases. Re‐run Counterparty.')

    db = sqlite3.connect(LEDGER)
    db.row_factory = sqlite3.Row
    cursor = db.cursor()

    # Always re‐parse from beginning on start‐up.
    db, cursor = initialise(db, cursor)
    cursor.execute('''SELECT * FROM blocks ORDER BY block_index''')
    for block in cursor.fetchall():
        db, cursor = parse_block(db, cursor, block['block_index'])

    # NOTE: tx_index may be skipping some numbers.
    tx_index = 0
    while True:

        # Get index of last block.
        try:
            cursor.execute('''SELECT * FROM blocks WHERE block_index = (SELECT MAX(block_index) from blocks)''')
            block_index = cursor.fetchone()['block_index'] + 1
            assert not cursor.fetchone()
        except Exception:
            block_index = BLOCK_FIRST

        # Get index of last transaction.
        try:    # Ugly
            cursor.execute('''SELECT * FROM transactions WHERE tx_index = (SELECT MAX(tx_index) from transactions)''')
            tx_index = cursor.fetchone()['tx_index'] + 1
            assert not cursor.fetchone()
        except Exception:
            pass

        # Get block.
        block_count = rpc('getblockcount', [])['result']
        while block_index <= block_count:
            # print('Fetching block:', block_index)

            block_hash = rpc('getblockhash', [block_index])['result']
            block = rpc('getblock', [block_hash])['result']
            block_time = block['time']
            tx_hash_list = block['tx']

            # Get the transaction list for each block.
            for tx_hash in tx_hash_list:
                # Skip duplicate transaction entries.
                cursor.execute('''SELECT * FROM transactions WHERE tx_hash=?''', (tx_hash,))
                if cursor.fetchone():
                    tx_index += 1
                    continue
                # Get the important details about each transaction.
                tx = rpc('getrawtransaction', [tx_hash, 1])['result']
                source, destination, btc_amount, fee, data = get_tx_info(tx)
                if data and source:
                    cursor.execute('''INSERT INTO transactions(
                                        tx_index,
                                        tx_hash,
                                        block_index,
                                        block_time,
                                        source,
                                        destination,
                                        btc_amount,
                                        fee,
                                        data) VALUES(?,?,?,?,?,?,?,?,?)''',
                                        (tx_index,
                                         tx_hash,
                                         block_index,
                                         block_time,
                                         source,
                                         destination,
                                         btc_amount,
                                         fee,
                                         data)
                                  )
                    tx_index += 1

            # List the block after all of the transactions in it.
            cursor.execute('''INSERT INTO blocks(
                                block_index,
                                block_hash,
                                block_time) VALUES(?,?,?)''',
                                (block_index,
                                block_hash,
                                block_time)
                          )
            db.commit() # Commit only at end of block.

            # Parse transactions in this block.
            db, cursor = parse_block(db, cursor, block_index)

            # Increment block index.
            block_count = rpc('getblockcount', [])['result'] # Get block count.
            block_index +=1

        while block_index > block_count: # DUPE
            block_count = rpc('getblockcount', [])['result']
            time.sleep(20)

    cursor.close()


def history (address):
    db = sqlite3.connect(LEDGER)
    db.row_factory = sqlite3.Row
    cursor = db.cursor()

    if not rpc('validateaddress', [address])['result']['isvalid']:
        raise InvalidAddressError('Not a valid Bitcoin address:', address)

    history = {}

    # TODO: Get initial balance. (List of deposits to the unspendable address.)

    # List sends.
    cursor.execute('''SELECT * FROM sends \
                      WHERE (source=? OR destination=?) \
                      ORDER BY tx_index''',
                   (address, address))
    history['sends'] = {'incoming': [], 'outgoing': []}
    for send in cursor.fetchall():
        if send['source'] == address:
            history['sends']['incoming'].append(dict(send))
        else:
            history['sends']['outgoing'].append(dict(send))

    # List orders.
    cursor.execute('''SELECT * FROM orders \
                      WHERE (source=?)\
                      ORDER BY tx_index''',
                   (address,))
    history['orders'] = [dict(order) for order in cursor.fetchall()]

    # List deals.
    cursor.execute('''SELECT * FROM deals \
                      WHERE (tx0_address=? OR tx1_address=?) \
                      ORDER BY tx1_index, tx0_index''',
                   (address, address))
    history['deals'] = [dict(deal) for deal in cursor.fetchall()]

    # List balances in every asset with an initialised balance.
    history['balances'] = {}
    cursor.execute('''SELECT * FROM balances WHERE address=?''', (address,))
    for balance in cursor.fetchall():
        history['balances'][balance['asset_id']] = balance['amount']

    # List issuances.
    cursor.execute('''SELECT * FROM issuances \
                      WHERE (source=?)\
                      ORDER BY tx_index''',
                   (address,))
    history['issuances'] = [dict(issuance) for issuance in cursor.fetchall()]


    return history 


def orderbook ():
    db = sqlite3.connect(LEDGER)
    db.row_factory = sqlite3.Row
    cursor = db.cursor()

    block_count = rpc('getblockcount', [])['result']

    # Open orders.
    orderbook = []
    cursor.execute('''SELECT * FROM orders ORDER BY ask_price ASC, tx_index''')
    for order in cursor.fetchall():
        time_left = order['block_index'] + order['expiration'] - block_count # Inclusive/exclusive expiration? DUPE
        if order['validity'] == 'Valid' and order['give_remaining'] and ((time_left > 0 and order['give_id'] and order['get_id']) or time_left > 1): # Ignore BTC orders one block early.
            orderbook.append(dict(order))

    return orderbook


def pending():
    '''Deals awaiting Bitcoin payment from you.'''
    db = sqlite3.connect(LEDGER)
    db.row_factory = sqlite3.Row
    cursor = db.cursor()

    block_count = rpc('getblockcount', [])['result']

    pending = []
    address_list = [ element['address'] for element in rpc('listreceivedbyaddress', [0,True])['result'] ]
    cursor.execute('''SELECT * FROM deals ORDER BY tx1_index''')
    for deal in cursor.fetchall():

        # Check that neither order has expired.
        expired = False
        cursor.execute('''SELECT * FROM orders WHERE (tx_hash=? OR tx_hash=?)''', (deal['tx0_hash'], deal['tx1_hash']))
        for order in cursor.fetchall():
            time_left = order['block_index'] + order['expiration'] - block_count # Inclusive/exclusive expiration?
            if time_left <= 0: expired = True

        if deal['validity'] == 'Valid: waiting for bitcoins' and not expired:
            deal_id = deal['tx0_hash'] + deal['tx1_hash']
            if (deal['tx0_address'] in address_list and not deal['forward_id'] or
                    deal['tx1_address'] in address_list and not deal['backward_id']):
                pending.append(dict(deal))

    return pending



if __name__ == '__main__':

    # Parse command‐line arguments.
    parser = argparse.ArgumentParser(prog='counterparty', description='')
    parser.add_argument('--version', action='store_true', 
                        help='print version information')
    subparsers = parser.add_subparsers(dest='action', 
                                       help='the action to be taken')

    # TODO
    parser_send = subparsers.add_parser('send', help='requires bitcoind')
    parser_send.add_argument('source', metavar='SOURCE', type=str, help='')
    parser_send.add_argument('destination', metavar='DESTINATION', type=str, help='')
    parser_send.add_argument('amount', metavar='AMOUNT', type=str, help='')
    parser_send.add_argument('asset_name', metavar='ASSET_NAME', type=str, help='')

    # TODO
    parser_order = subparsers.add_parser('order', help='requires bitcoind')
    parser_order.add_argument('source', metavar='SOURCE', type=str, help='')
    parser_order.add_argument('get_amount', metavar='GET_AMOUNT', type=str, help='')
    parser_order.add_argument('get_name', metavar='GET_NAME', type=str, help='')
    parser_order.add_argument('give_amount', metavar='GIVE_AMOUNT', type=str, help='')
    parser_order.add_argument('give_name', metavar='GIVE_NAME', type=str, help='')
    parser_order.add_argument('price', metavar='PRICE', type=float, help='equal to GIVE/GET')
    parser_order.add_argument('expiration', metavar='EXPIRATION', type=int, help='')
    parser_order.add_argument('fee', metavar='FEE_REQUIRED or FEE_PROVIDED, as appropriate', type=float, help='')

    parser_btcpayment = subparsers.add_parser('btcpayment', help='requires bitcoind')
    parser_btcpayment.add_argument('deal_id', metavar='DEAL_ID', type=str, help='')

    parser_issuee = subparsers.add_parser('issue', help='requires bitcoind')
    parser_issuee.add_argument('source', metavar='SOURCE', type=str, help='')
    parser_issuee.add_argument('amount', metavar='AMOUNT', type=str, help='')
    parser_issuee.add_argument('asset_id', metavar='ASSET_ID', type=int, help='')

    parser_follow = subparsers.add_parser('follow', help='requires bitcoind')

    parser_history = subparsers.add_parser('history', help='')
    parser_history.add_argument('address', metavar='ADDRESS', type=str,
                                help='''get the history, balance of an
                                        address''')

    parser_orderbook = subparsers.add_parser('orderbook', help='')

    parser_pending = subparsers.add_parser('pending', help='')

    args = parser.parse_args()


    # Do something.
    if args.version:
        print('This is Version 0.01 of counterparty.')

    elif args.action == 'send':
        bitcoind_check()
        try:    # TEMP
            asset_id = ASSET_ID[args.asset_name]
        except Exception:
            asset_id = int(args.asset_name)

        if '.' in args.amount: amount = int(float(args.amount) * UNIT)
        else: amount = int(args.amount)

        json_print(send(args.source, args.destination, amount,
                   asset_id))

    elif args.action == 'order':
        source = args.source
        give_amount = int(D(args.give_amount) * UNIT)
        get_amount = int(D(args.get_amount) * UNIT)
        give_name = args.give_name
        get_name = args.get_name
        expiration = args.expiration
        fee = int(D(args.fee) * UNIT)
        price = args.price

        assert give_name != get_name            # TODO
        assert price == give_amount/get_amount  # TODO

        try:    # TEMP
            give_id = ASSET_ID[args.give_name]
        except Exception:
            give_id = int(args.give_name)
        try:    # TEMP
            get_id = ASSET_ID[args.get_name]
        except Exception:
            get_id = int(args.get_name)

        # fee argument is either fee_required or fee_provided, as necessary.
        if not give_id:
            fee_provided = fee
            assert fee_provided >= MIN_FEE
            fee_required = 0
        elif not get_id:
            fee_required = fee
            assert fee_required >= MIN_FEE
            fee_provided = MIN_FEE

        if '.' in args.give_amount:
            give_divisible = True
            give_amount = int(float(args.give_amount) * UNIT)
        else:
            give_divisible = False
            give_amount = int(args.give_amount)
        if '.' in args.get_amount:
            get_divisible = True
            get_amount = int(float(args.get_amount) * UNIT)
        else:
            get_divisible = False
            get_amount = int(args.get_amount)

        # The order of the order is reversed when it is written as a ‘buy’.
        print('Order:', source, 'wants to buy', get_amount, get_name,
              'for', give_amount, give_name, 'in', expiration, 'blocks')   # TODO (and fee_required, fee_provided)

        json_print(order(source, give_id, give_amount,
                    get_id, get_amount, expiration, fee_required, fee_provided))

    elif args.action == 'btcpayment':
        json_print(btcpayment(args.deal_id))

    elif args.action == 'issue':
        bitcoind_check()
        if '.' in args.amount:
            divisible = True
            amount = int(float(args.amount) * UNIT)
        else:
            divisible = False
            amount = int(args.amount)
        json_print(issuance(args.source, args.asset_id, amount, divisible))

    elif args.action == 'follow':
        bitcoind_check()
        follow()

    elif args.action == 'history':
        address = args.address
        json_print(history(address))

    elif args.action == 'orderbook':
        json_print(orderbook())
            
    elif args.action == 'pending':
        json_print(pending())
            
    elif args.action == 'help':
        parser.print_help()

    else:
        parser.print_help()
        sys.exit(1)


# vim: tabstop=8 expandtab shiftwidth=4 softtabstop=4
