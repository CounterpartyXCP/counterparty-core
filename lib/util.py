import sqlite3
import time
from datetime import datetime
from dateutil.tz import tzlocal
import decimal
D = decimal.Decimal
import sys

from . import (config, exceptions, bitcoin)

b26_digits = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'

# Obsolete in Python 3.4, with enum module.
BET_TYPE_NAME = {0: 'BullCFD', 1: 'BearCFD', 2: 'Equal', 3: 'NotEqual'}
BET_TYPE_ID = {'BullCFD': 0, 'BearCFD': 1, 'Equal': 2, 'NotEqual': 3}

def bitcoind_check (db):
    # Check blocktime of last block to see if Bitcoind is running behind.
    block_count = bitcoin.rpc('getblockcount', [])
    block_hash = bitcoin.rpc('getblockhash', [block_count])
    block = bitcoin.rpc('getblock', [block_hash])
    time_behind = time.time() - block['time']   # How reliable is the block time?!
    if time_behind > 60 * 60 * 2:   # Two hours.
        raise exceptions.BitcoindError('Bitcoind is running about {} seconds behind.'.format(round(time_behind)))

def database_check (db):
    # Check Counterparty database to see if the counterpartyd server has caught up with Bitcoind.
    cursor = db.cursor()
    TRIES = 7
    for i in range(TRIES):
        try:
            cursor.execute('''SELECT * FROM blocks ORDER BY block_index ASC''')
        except sqlite3.OperationalError:
            raise exceptions.DatabaseError('Counterparty database does not exist. Run the server command to create it.')
        last_block = cursor.fetchall()[-1]
        if last_block['block_index'] == bitcoin.rpc('getblockcount', []):
            cursor.close()
            return
        time.sleep(1)
    raise exceptions.DatabaseError('Counterparty database is behind Bitcoind. Is the counterpartyd server running?')

def short (string):
    if len(string) == 64: length = 8
    elif len(string) == 128: length = 16
    short = string[:length] + '…' + string[-length:]
    return short

def isodt (epoch_time):
    return datetime.fromtimestamp(epoch_time, tzlocal()).isoformat()

def get_time_left (unmatched, block_index=None):
    """order or bet"""
    """zero time left means it expires *this* block; that is, expire when strictly less than 0"""
    if not block_index: block_index = bitcoin.rpc('getblockcount', [])
    return unmatched['block_index'] + unmatched['expiration'] - block_index
def get_order_match_time_left (matched, block_index=None):
    """order_match or bet_match"""
    if not block_index: block_index = bitcoin.rpc('getblockcount', [])
    tx0_time_left = matched['tx0_block_index'] + matched['tx0_expiration'] - block_index
    tx1_time_left = matched['tx1_block_index'] + matched['tx1_expiration'] - block_index
    return min(tx0_time_left, tx1_time_left)

def valid_asset_name (asset_name):
    if asset_name in ('BTC', 'XCP'): return True
    if len(asset_name) < 4: return False
    for c in asset_name:
        if c not in b26_digits:
            return False
    return True

def get_asset_id (asset):
    if not valid_asset_name(asset): raise exceptions.AssetError('Invalid asset name.')
    if asset == 'BTC': return 0
    elif asset == 'XCP': return 1

    # Convert the Base 26 string to an integer.
    n = 0
    s = asset
    for c in s:
        n *= 26
        if c not in b26_digits:
            raise exceptions.InvalidBase26Error('Not an uppercase ASCII character:', c)
        digit = b26_digits.index(c)
        n += digit

    # Minimum of four letters long.
    if not n > 26**3:
        raise exceptions.AssetError('Invalid asset name.')
    return n

def get_asset_name (asset_id):
    if asset_id == 0: return 'BTC'
    elif asset_id == 1: return 'XCP'

    # Minimum of four letters long.
    if not asset_id > 26**3:
        raise exceptions.AssetError('Invalid asset name.')
    # Divide that integer into Base 26 string.
    res = []
    n = asset_id
    while n > 0:
        n, r = divmod (n, 26)
        res.append(b26_digits[r])
    asset = ''.join(res[::-1])
    if not valid_asset_name(asset): raise exceptions.AssetError('Invalid asset name.')
    return asset


def debit (db, address, asset, amount):
    debit_cursor = db.cursor()
    assert asset != 'BTC' # Never BTC.
    assert type(amount) == int
    if asset == 'BTC':
        raise exceptions.BalanceError('Cannot debit bitcoins from a Counterparty address!')

    balances = get_balances(db, address=address, asset=asset)
    if not len(balances) == 1:
        old_balance = 0
    else:
        old_balance = balances[0]['amount']
        assert type(old_balance) == int

    if old_balance >= amount:
        debit_cursor.execute('''UPDATE balances \
                          SET amount=? \
                          WHERE (address=? and asset=?)''',
                       (round(old_balance - amount), address, asset)) 
        validity = 'Valid'
    else:
        validity = 'Invalid: insufficient funds'

    # Record debit.
    debit_cursor.execute('''INSERT INTO debits(
                        address,
                        asset,
                        amount) VALUES(?,?,?)''',
                        (address,
                        asset,
                        amount)
                  )
    debit_cursor.close()
    return validity

def credit (db, address, asset, amount):
    credit_cursor = db.cursor()
    assert asset != 'BTC' # Never BTC.
    assert type(amount) == int

    balances = get_balances(db, address=address, asset=asset)
    if len(balances) != 1:
        assert balances == []
        credit_cursor.execute('''INSERT INTO balances(
                            address,
                            asset,
                            amount) VALUES(?,?,?)''',
                            (address,
                            asset,
                            amount)
                      )
    else:
        old_balance = balances[0]['amount']
        assert type(old_balance) == int
        credit_cursor.execute('''UPDATE balances SET amount=? \
                          WHERE (address=? and asset=?)''',
                       (old_balance + amount, address, asset)) 

    # Record credit.
    credit_cursor.execute('''INSERT INTO credits(
                        address,
                        asset,
                        amount) VALUES(?,?,?)''',
                        (address,
                        asset,
                        amount)
                  )
    credit_cursor.close()

def devise (db, quantity, asset, dest, divisible=None):
    FOUR = D(10) ** -4
    EIGHT = D(10) ** -8

    quantity = D(quantity)

    if asset in ('leverage', 'price', 'odds', 'value'):
        if dest == 'output':
            return quantity.quantize(FOUR)
        elif dest == 'input':
            # Hackish
            if asset == 'leverage':
                return round(quantity)
            else:
                return float(quantity)

    if asset in ('fee_multiplier',):
        return D(quantity / D(1e8)).quantize(FOUR)

    if divisible == None:
        if asset in ('BTC', 'XCP'):
            divisible = True
        else:
            issuances = get_issuances(db, validity='Valid', asset=asset)
            if not issuances: raise exceptions.AssetError('No such asset: {}'.format(asset))
            divisible = issuances[0]['divisible']

    if divisible:
        if dest == 'output':
            quantity = D(quantity / config.UNIT).quantize(EIGHT)
            if quantity == quantity.to_integral():
                return str(float(quantity))  # For divisible assets, display the decimal point.
            else:
                return str(quantity.quantize(EIGHT).normalize())
        elif dest == 'input':
            quantity = D(quantity * config.UNIT).quantize(EIGHT)
            if quantity == quantity.to_integral():
                return int(quantity)
            else:
                raise exceptions.QuantityError('Divisible assets have only eight decimal places of precision.')
        else:
            return quantity.quantize(EIGHT)
    else:
        if quantity != round(quantity):
            raise exceptions.QuantityError('Fractional quantities of indivisible assets.')
        return round(quantity)

def get_debits (db, address=None, asset=None):
    """This does not include BTC."""
    cursor = db.cursor()
    cursor.execute('''SELECT * FROM debits''')
    debits = []
    for debit in cursor.fetchall():
        if address and debit['address'] != address: continue
        if asset != None and debit['asset'] != asset: continue
        debits.append(dict(debit))
    cursor.close()
    return debits

def get_credits (db, address=None, asset=None):
    """This does not include BTC."""
    cursor = db.cursor()
    cursor.execute('''SELECT * FROM credits''')
    credits = []
    for credit in cursor.fetchall():
        if address and credit['address'] != address: continue
        if asset != None and credit['asset'] != asset: continue
        credits.append(dict(credit))
    cursor.close()
    return credits

def get_balances (db, address=None, asset=None):
    """This should never be used to check Bitcoin balances."""
    cursor = db.cursor()
    cursor.execute('''SELECT * FROM balances''')
    balances = []
    for balance in cursor.fetchall():
        if address and balance['address'] != address: continue
        if asset != None and balance['asset'] != asset: continue
        if asset == 'BTC': raise Exception
        balances.append(dict(balance))
    cursor.close()
    return balances

def get_sends (db, validity=None, source=None, destination=None):
    cursor = db.cursor()
    cursor.execute('''SELECT * FROM sends ORDER BY tx_index''')
    sends = []
    for send in cursor.fetchall():
        if validity and send['Validity'] != validity: continue
        if source and send['source'] != source: continue
        if destination and send['destination'] != destination: continue
        sends.append(dict(send))
    cursor.close()
    return sends

def get_orders (db, validity=None, address=None, show_empty=True, show_expired=True):
    cursor = db.cursor()
    cursor.execute('''SELECT * FROM orders ORDER BY price ASC, tx_index''')
    block_count = bitcoin.rpc('getblockcount', [])
    orders = []
    for order in cursor.fetchall():
        if validity and order['Validity'] != validity: continue
        if not show_empty and not order['give_remaining']: continue
        if address and order['source'] != address: continue

        # Ignore BTC orders one block early. (This is why we need show_expired.)
        time_left = get_time_left(order)
        if order['give_asset'] == 'BTC': time_left -= 1
        if not show_expired and time_left < 0:
            continue

        orders.append(dict(order))
    cursor.close()
    return orders

def get_order_matches (db, validity=None, is_mine=True, address=None, tx0_hash=None, tx1_hash=None):
    cursor = db.cursor()
    cursor.execute('''SELECT * FROM order_matches ORDER BY tx1_index''')
    order_matches = []
    for order_match in cursor.fetchall():
        if validity and order_match['validity'] != validity: continue

        if is_mine and ((not bitcoin.rpc('validateaddress', [order_match['tx0_address']])['ismine'] or 
                           order_match['forward_asset'] != 'BTC') and 
                          (not bitcoin.rpc('validateaddress', [order_match['tx1_address']])['ismine'] or
                           order_match['backward_asset'] != 'BTC')):
            continue

        if address and not (order_match['tx0_address'] == address or
                            order_match['tx1_address'] == address):
            continue

        if tx0_hash and tx0_hash != order_match['tx0_hash']: continue
        if tx1_hash and tx1_hash != order_match['tx1_hash']: continue
        order_matches.append(dict(order_match))
    cursor.close()
    return order_matches

def get_btcpays (db, validity=None):
    cursor = db.cursor()
    cursor.execute('''SELECT * FROM btcpays ORDER BY tx_index''')
    btcpays = []
    for btcpay in cursor.fetchall():
        if validity and btcpay['Validity'] != validity: continue
        btcpays.append(dict(btcpay))
    cursor.close()
    return btcpays

def get_issuances (db, validity=None, asset=None, issuer=None):
    cursor = db.cursor()
    cursor.execute('''SELECT * FROM issuances \
                      ORDER BY tx_index ASC''')
    issuances = []
    for issuance in cursor.fetchall():
        if validity and issuance['Validity'] != validity: continue
        if asset != None and issuance['asset'] != asset:
            if not valid_asset_name(asset): raise exceptions.AssetError('Invalid asset name.')
            continue
        if issuer and issuance['issuer'] != issuer: continue
        issuances.append(dict(issuance))
    cursor.close()
    return issuances

def get_broadcasts (db, validity=None, source=None, order_by='tx_index ASC'):
    cursor = db.cursor()

    if order_by == 'tx_index ASC':
        cursor.execute('''SELECT * FROM broadcasts \
                          ORDER BY tx_index ASC''')
    elif order_by == 'timestamp DESC':
        cursor.execute('''SELECT * FROM broadcasts \
                          ORDER BY timestamp DESC''')
    else:
        raise Exception('Unknown scheme for ordering broadcasts.')

    broadcasts = []
    for broadcast in cursor.fetchall():
        if validity and broadcast['Validity'] != validity: continue
        if source and broadcast['source'] != source: continue
        broadcasts.append(dict(broadcast))
    cursor.close()
    return broadcasts

def get_bets (db, validity=None, address=None, show_empty=True):
    cursor = db.cursor()
    cursor.execute('''SELECT * FROM bets ORDER BY odds DESC, tx_index''')
    block_count = bitcoin.rpc('getblockcount', [])
    bets = []
    for bet in cursor.fetchall():
        if validity and bet['Validity'] != validity: continue
        if not show_empty and not bet['wager_remaining']: continue
        if address and bet['source'] != address: continue
        bets.append(dict(bet))
    cursor.close()
    return bets

def get_bet_matches (db, validity=None, address=None, tx0_hash=None, tx1_hash=None):
    cursor = db.cursor()
    cursor.execute('''SELECT * FROM bet_matches ORDER BY tx1_index''')
    bet_matches = []
    for bet_match in cursor.fetchall():
        if validity and bet_match['validity'] != validity: continue
        if address and not (bet_match['tx0_address'] == address or
                            bet_match['tx1_address'] == address):
            continue
        if tx0_hash and tx0_hash != bet_match['tx0_hash']: continue
        if tx1_hash and tx1_hash != bet_match['tx1_hash']: continue
        bet_matches.append(dict(bet_match))
    cursor.close()
    return bet_matches

def get_dividends (db, validity=None, address=None, asset=None):
    cursor = db.cursor()
    cursor.execute('''SELECT * FROM dividends ORDER BY tx_index''')
    dividends = []
    for dividend in cursor.fetchall():
        if validity and dividend['Validity'] != validity: continue
        if address and dividend['source'] != address: continue
        if asset != None and dividend['asset'] != asset: continue
        dividends.append(dict(dividend))
    cursor.close()
    return dividends

def get_burns (db, validity=True, address=None):
    cursor = db.cursor()
    cursor.execute('''SELECT * FROM burns ORDER BY tx_index''')
    burns = []
    for burn in cursor.fetchall():
        if validity and burn['Validity'] != validity: continue
        if address and burn['address'] != address: continue
        burns.append(dict(burn))
    cursor.close()
    return burns

def get_address (db, address):
    if not bitcoin.base58_decode(address, config.ADDRESSVERSION):
        raise exceptions.InvalidAddressError('Not a valid Bitcoin address:',
                                             address)
    address_dict = {}
    address_dict['balances'] = get_balances(db, address=address)
    address_dict['burns'] = get_burns(db, validity='Valid', address=address)
    address_dict['sends'] = get_sends(db, validity='Valid', source=address)
    address_dict['orders'] = get_orders(db, validity='Valid', address=address)
    address_dict['order_matches'] = get_order_matches(db, validity='Valid', address=address)
    address_dict['btcpays'] = get_btcpays(db, validity='Valid')
    address_dict['issuances'] = get_issuances(db, validity='Valid', issuer=address)
    address_dict['broadcasts'] = get_broadcasts(db, validity='Valid', source=address)
    address_dict['bets'] = get_bets(db, validity='Valid', address=address)
    address_dict['bet_matches'] = get_bet_matches(db, validity='Valid', address=address)
    address_dict['dividends'] = get_dividends(db, validity='Valid', address=address)
    return address_dict

# vim: tabstop=8 expandtab shiftwidth=4 softtabstop=4
