import time
from datetime import datetime
from dateutil.tz import tzlocal
import decimal
D = decimal.Decimal
import sys
import logging
from operator import itemgetter

from . import (config, exceptions, bitcoin)

b26_digits = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'

# Obsolete in Python 3.4, with enum module.
BET_TYPE_NAME = {0: 'BullCFD', 1: 'BearCFD', 2: 'Equal', 3: 'NotEqual'}
BET_TYPE_ID = {'BullCFD': 0, 'BearCFD': 1, 'Equal': 2, 'NotEqual': 3}

def rowtracer(cursor, sql):
    dictionary = {}
    description = cursor.getdescription()
    for i in range(len(description)):
        dictionary[description[i][0]] = sql[i]
    return dictionary

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
        except Exception:   # TODO
            raise exceptions.DatabaseError('Counterparty database does not exist. Run the server command to create it.')
        last_block = cursor.fetchall()[-1]
        if last_block['block_index'] == bitcoin.rpc('getblockcount', []):
            cursor.close()
            return
        time.sleep(1)
    raise exceptions.DatabaseError('Counterparty database is behind Bitcoind. Is the counterpartyd server running?')

def do_order_by(results, order_by, order_dir):
    if not len(results) or not order_by: #empty results, or not ordering
        return results
    assert isinstance(results, list) and isinstance(results[0], dict)

    if order_by not in results[0]:
        raise KeyError("Specified order_by property '%s' does not exist in returned data" % order_by)
    if order_dir not in ('asc', 'desc'):
        raise Exception("Invalid order_dir: '%s'. Must be 'asc' or 'desc'" % order_dir)
    return sorted(results, key=itemgetter(order_by), reverse=order_dir=='desc')

def get_limit_to_blocks(start_block, end_block, col_names=['block_index',]):
    if    (start_block is not None and not isinstance(start_block, int)) \
       or (end_block is not None and not isinstance(end_block, int)):
        raise ValueError("start_block and end_block must be either an integer, or None")
    assert isinstance(col_names, list) and len(col_names) in [1, 2]
    
    if start_block is None and end_block is None:
        return ''
    elif len(col_names) == 1:
        col_name = col_names[0]
        if start_block and end_block:
            block_limit_clause = " WHERE %s >= %s AND %s <= %s" % (col_name, start_block, col_name, end_block)
        elif start_block:
            block_limit_clause = " WHERE %s >= %s" % (col_name, start_block)
        elif end_block:
            block_limit_clause = " WHERE %s <= %s" % (col_name, end_block)
    else: #length of 2
        if start_block and end_block:
            block_limit_clause = " WHERE (%s >= %s OR %s >= %s) AND (%s <= %s OR %s <= %s)" % (
                col_name[0], start_block, col_name[1], start_block,
                col_name[0], end_block, col_name[1], end_block)
        elif start_block:
            block_limit_clause = " WHERE %s >= %s OR %s >= %s" % (
                col_name[0], start_block, col_name[1], start_block)
        elif end_block:
            block_limit_clause = " WHERE %s >= %s OR %s >= %s" % (
                col_name[0], end_block, col_name[1], end_block)
    return block_limit_clause

def short (string):
    if len(string) == 64: length = 8
    elif len(string) == 128: length = 16
    short = string[:length] + '...' + string[-length:]
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
        balance = round(old_balance - amount)
        balance = min(balance, config.MAX_INT)
        debit_cursor.execute('''UPDATE balances \
                          SET amount=? \
                          WHERE (address=? and asset=?)''',
                       (balance, address, asset)) 
        validity = 'Valid'
    else:
        validity = 'Invalid: insufficient funds'

    # Record debit.
    logging.debug('Debit: {} of {} from {}'.format(devise(db, amount, asset, 'output'), asset, address))
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
        balance = round(old_balance + amount)
        balance = min(balance, config.MAX_INT)
        credit_cursor.execute('''UPDATE balances SET amount=? \
                          WHERE (address=? and asset=?)''',
                       (balance, address, asset)) 

    # Record credit.
    logging.debug('Credit: {} of {} to {}'.format(devise(db, amount, asset, 'output'), asset, address))
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

def get_debits (db, address=None, asset=None, order_by=None, order_dir='asc'):
    """This does not include BTC."""
    cursor = db.cursor()
    cursor.execute('''SELECT * FROM debits''')
    debits = []
    for debit in cursor.fetchall():
        if address and debit['address'] != address: continue
        if asset != None and debit['asset'] != asset: continue
        debits.append(dict(debit))
    cursor.close()
    return do_order_by(debits, order_by, order_dir)

def get_credits (db, address=None, asset=None, order_by=None, order_dir='asc'):
    """This does not include BTC."""
    cursor = db.cursor()
    cursor.execute('''SELECT * FROM credits''')
    credits = []
    for credit in cursor.fetchall():
        if address and credit['address'] != address: continue
        if asset != None and credit['asset'] != asset: continue
        credits.append(dict(credit))
    cursor.close()
    return do_order_by(credits, order_by, order_dir)

def get_balances (db, address=None, asset=None, order_by=None, order_dir='asc'):
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
    return do_order_by(balances, order_by, order_dir)

def get_sends (db, validity=None, source=None, destination=None, order_by='tx_index', order_dir='asc', start_block=None, end_block=None):
    cursor = db.cursor()
    cursor.execute('''SELECT * FROM sends%s'''
        % get_limit_to_blocks(start_block, end_block))
    sends = []
    for send in cursor.fetchall():
        if validity and send['validity'] != validity: continue
        if source and send['source'] != source: continue
        if destination and send['destination'] != destination: continue
        sends.append(dict(send))
    cursor.close()
    return do_order_by(sends, order_by, order_dir)

def get_orders (db, validity=None, address=None, show_empty=True, show_expired=True, order_by='price', order_dir='asc', start_block=None, end_block=None):
    cursor = db.cursor()
    cursor.execute('''SELECT * FROM orders%s'''
        % get_limit_to_blocks(start_block, end_block))
    block_count = bitcoin.rpc('getblockcount', [])
    orders = []
    for order in cursor.fetchall():
        if validity and order['validity'] != validity: continue
        if not show_empty and not order['give_remaining']: continue
        if address and order['source'] != address: continue

        # Ignore BTC orders one block early. (This is why we need show_expired.)
        time_left = get_time_left(order)
        if order['give_asset'] == 'BTC': time_left -= 1
        if not show_expired and time_left < 0:
            continue

        orders.append(dict(order))
    cursor.close()
    return do_order_by(orders, order_by, order_dir)

def get_order_matches (db, validity=None, is_mine=False, address=None, tx0_hash=None, tx1_hash=None, order_by='tx1_index', order_dir='asc', start_block=None, end_block=None):
    cursor = db.cursor()
    cursor.execute('''SELECT * FROM order_matches%s'''
        % get_limit_to_blocks(start_block, end_block,
            col_names=['tx0_block_index', 'tx1_block_index']))
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
    return do_order_by(order_matches, order_by, order_dir)

def get_btcpays (db, validity=None, order_by='tx_index', order_dir='asc', start_block=None, end_block=None):
    cursor = db.cursor()
    cursor.execute('''SELECT * FROM btcpays%s'''
        % get_limit_to_blocks(start_block, end_block))
    btcpays = []
    for btcpay in cursor.fetchall():
        if validity and btcpay['validity'] != validity: continue
        btcpays.append(dict(btcpay))
    cursor.close()
    return do_order_by(btcpays, order_by, order_dir)

def get_issuances (db, validity=None, asset=None, issuer=None, order_by='tx_index', order_dir='asc', start_block=None, end_block=None):
    cursor = db.cursor()
    cursor.execute('''SELECT * FROM issuances%s'''
         % get_limit_to_blocks(start_block, end_block))
    issuances = []
    for issuance in cursor.fetchall():
        if validity and issuance['validity'] != validity: continue
        if asset != None and issuance['asset'] != asset:
            if not valid_asset_name(asset): raise exceptions.AssetError('Invalid asset name.')
            continue
        if issuer and issuance['issuer'] != issuer: continue
        issuances.append(dict(issuance))
    cursor.close()
    return do_order_by(issuances, order_by, order_dir)

def get_broadcasts (db, validity=None, source=None, order_by='tx_index', order_dir='asc', start_block=None, end_block=None):
    cursor = db.cursor()
    cursor.execute('''SELECT * FROM broadcasts%s'''
         % get_limit_to_blocks(start_block, end_block))
    broadcasts = []
    for broadcast in cursor.fetchall():
        if validity and broadcast['validity'] != validity: continue
        if source and broadcast['source'] != source: continue
        broadcasts.append(dict(broadcast))
    cursor.close()
    return do_order_by(broadcasts, order_by, order_dir)

def get_bets (db, validity=None, address=None, show_empty=True, order_by='odds', order_dir='desc', start_block=None, end_block=None):
    cursor = db.cursor()
    cursor.execute('''SELECT * FROM bets%s'''
        % get_limit_to_blocks(start_block, end_block))
    block_count = bitcoin.rpc('getblockcount', [])
    bets = []
    for bet in cursor.fetchall():
        if validity and bet['validity'] != validity: continue
        if not show_empty and not bet['wager_remaining']: continue
        if address and bet['source'] != address: continue
        bets.append(dict(bet))
    cursor.close()
    return do_order_by(bets, order_by, order_dir)

def get_bet_matches (db, validity=None, address=None, tx0_hash=None, tx1_hash=None, order_by='tx1_index', order_dir='asc', start_block=None, end_block=None):
    cursor = db.cursor()
    cursor.execute('''SELECT * FROM bet_matches%s'''
         % get_limit_to_blocks(start_block, end_block,
             col_names=['tx0_block_index', 'tx1_block_index']))
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
    return do_order_by(bet_matches, order_by, order_dir)

def get_dividends (db, validity=None, address=None, asset=None, order_by='tx_index', order_dir='asc', start_block=None, end_block=None):
    cursor = db.cursor()
    cursor.execute('''SELECT * FROM dividends%s'''
         % get_limit_to_blocks(start_block, end_block))
    dividends = []
    for dividend in cursor.fetchall():
        if validity and dividend['validity'] != validity: continue
        if address and dividend['source'] != address: continue
        if asset != None and dividend['asset'] != asset: continue
        dividends.append(dict(dividend))
    cursor.close()
    return do_order_by(dividends, order_by, order_dir)

def get_burns (db, validity=True, address=None, order_by='tx_index', order_dir='asc', start_block=None, end_block=None):
    cursor = db.cursor()
    cursor.execute('''SELECT * FROM burns%s'''
         % get_limit_to_blocks(start_block, end_block))
    burns = []
    for burn in cursor.fetchall():
        if validity and burn['validity'] != validity: continue
        if address and burn['address'] != address: continue
        burns.append(dict(burn))
    cursor.close()
    return do_order_by(burns, order_by, order_dir)

def get_cancels (db, validity=True, source=None, order_by=None, order_dir=None, start_block=None, end_block=None):
    cursor = db.cursor()
    cursor.execute('''SELECT * FROM cancels%s'''
         % get_limit_to_blocks(start_block, end_block))
    cancels = []
    for cancel in cursor.fetchall():
        if validity and cancel['validity'] != validity: continue
        if source and cancel['source'] != source: continue
        cancels.append(dict(cancel))
    cursor.close()
    return do_order_by(cancels, order_by, order_dir)

def get_address (db, address):
    if not bitcoin.base58_decode(address, config.ADDRESSVERSION):
        raise exceptions.InvalidAddressError('Not a valid Bitcoin address:',
                                             address)
    address_dict = {}
    address_dict['balances'] = get_balances(db, address=address)
    address_dict['burns'] = get_burns(db, validity='Valid', address=address, order_by='block_index', order_dir='asc')
    address_dict['sends'] = get_sends(db, validity='Valid', source=address, order_by='block_index', order_dir='asc')
    address_dict['orders'] = get_orders(db, validity='Valid', address=address, order_by='block_index', order_dir='asc')
    address_dict['order_matches'] = get_order_matches(db, validity='Valid', address=address, order_by='tx0_block_index', order_dir='asc')
    address_dict['btcpays'] = get_btcpays(db, validity='Valid', order_by='block_index', order_dir='asc')
    address_dict['issuances'] = get_issuances(db, validity='Valid', issuer=address, order_by='block_index', order_dir='asc')
    address_dict['broadcasts'] = get_broadcasts(db, validity='Valid', source=address, order_by='block_index', order_dir='asc')
    address_dict['bets'] = get_bets(db, validity='Valid', address=address, order_by='block_index', order_dir='asc')
    address_dict['bet_matches'] = get_bet_matches(db, validity='Valid', address=address, order_by='tx0_block_index', order_dir='asc')
    address_dict['dividends'] = get_dividends(db, validity='Valid', address=address, order_by='block_index', order_dir='asc')
    return address_dict

# vim: tabstop=8 expandtab shiftwidth=4 softtabstop=4
