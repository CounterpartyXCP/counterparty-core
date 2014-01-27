import time
from datetime import datetime
from dateutil.tz import tzlocal
import decimal
D = decimal.Decimal
import sys
import logging
import operator
from operator import itemgetter

from . import (config, exceptions, bitcoin)

b26_digits = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'

# Obsolete in Python 3.4, with enum module.
BET_TYPE_NAME = {0: 'BullCFD', 1: 'BearCFD', 2: 'Equal', 3: 'NotEqual'}
BET_TYPE_ID = {'BullCFD': 0, 'BearCFD': 1, 'Equal': 2, 'NotEqual': 3}
DO_FILTER_OPERATORS = {
    '==': operator.eq,
    '!=': operator.ne,
    '<': operator.lt,
    '>': operator.gt,
    '<=': operator.le,
    '>=': operator.ge,
}

def rowtracer(cursor, sql):
    dictionary = {}
    description = cursor.getdescription()
    for i in range(len(description)):
        dictionary[description[i][0]] = sql[i]
    return dictionary

def get_insert_sql(table_name, element_data):
    """Takes a mapping of element data and a table name, and produces an INSERT statement suitable for a sqlite3 cursor.execute() operation"""
    #NOTE: keys() and values() return in the same order if dict is not modified: http://docs.python.org/2/library/stdtypes.html#dict.items
    k, v = (element_data.keys(), element_data.values())
    return [ "INSERT INTO %s(%s) VALUES(%s)" % (
        table_name, ','.join(k), ','.join(['?' for i in range(len(v))])), v ]

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

def do_filter(results, filters, filterop):
    """Filter results based on a filter data structure (as used by the API)"""
    if not len(results) or not filters: #empty results, or not filtering
        return results
    if isinstance(filters, dict): #single filter entry, convert to a one entry list
        filters = [filters,] 
    #validate filter(s)
    required_fields = ['field', 'op', 'value']
    for filter in filters:
        for field in required_fields: #should have all fields
            if field not in filter:
                raise Exception("A specified filter is missing the '%s' field" % field)
        if filterop not in ('and', 'or'):
            raise Exception("Invalid filterop setting. Must be either 'and' or 'or'.")
        if filter['op'] not in DO_FILTER_OPERATORS.keys():
            raise Exception("A specified filter op is invalid or not recognized: '%s'" % filter['op'])
        if filter['field'] == 'block_index':
            raise Exception("For performance reasons, please use the start_block and end_block API arguments to do block_index filtering")
        if filter['field'] not in results[0]:
            raise Exception("A specified filter field is invalid or not recognized for the given object type: '%s'" % filter['field'])
        if type(filter['value']) not in (str, int, float, bool):
            raise Exception("Value specified for filter field '%s' is not one of the supported value types (str, int, float, bool)" % (
                filter['field']))
        if type(filter['value']) != type(results[0][filter['field']]):
            raise Exception("Value specified for filter field '%s' does not match the data type of that field (value: %s, field: %s)" % (
                filter['field'], type(filter['value']), type(results[0][filter['field']])))
    #filter data
    if filterop == 'and':
        for filter in filters:
            results = [e for e in results if DO_FILTER_OPERATORS[filter['op']](e[filter['field']], filter['value'])]
        return results
    else: #or
        combined_results = []
        for filter in filters:
            combined_results += [e for e in results if DO_FILTER_OPERATORS[filter['op']](e[filter['field']], filter['value'])]
        return combined_results

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

    if old_balance < amount:
        raise exceptions.BalanceError('Insufficient funds.')

    balance = round(old_balance - amount)
    balance = min(balance, config.MAX_INT)
    debit_cursor.execute('''UPDATE balances \
                      SET amount=? \
                      WHERE (address=? and asset=?)''',
                   (balance, address, asset)) 

    # Record debit *only if valid*.
    logging.debug('Debit: {} of {} from {}'.format(devise(db, amount, asset, 'output'), asset, address))
    element_data = {
        'address': address,
        'asset': asset,
        'amount': amount,
    }
    debit_cursor.execute(*get_insert_sql('debits', element_data))
    config.zeromq_publisher.push_to_subscribers('debit', {
        'address': address, 'asset': asset, 'amount': amount, 'balance': balance })
    debit_cursor.close()

def credit (db, address, asset, amount):
    credit_cursor = db.cursor()
    assert asset != 'BTC' # Never BTC.
    assert type(amount) == int

    balances = get_balances(db, address=address, asset=asset)
    if len(balances) != 1:
        assert balances == []
        
        #update balances table with new balance
        element_data = {
            'address': address,
            'asset': asset,
            'amount': amount,
        }
        credit_cursor.execute(*get_insert_sql('balances', element_data))
        config.zeromq_publisher.push_to_subscribers('credit', {
            'address': address, 'asset': asset, 'amount': amount, 'balance': amount })
    else:
        old_balance = balances[0]['amount']
        assert type(old_balance) == int
        balance = round(old_balance + amount)
        balance = min(balance, config.MAX_INT)
        credit_cursor.execute('''UPDATE balances SET amount=? \
                          WHERE (address=? and asset=?)''',
                       (balance, address, asset)) 
        config.zeromq_publisher.push_to_subscribers('credit', {
            'address': address, 'asset': asset, 'amount': amount, 'balance': balance })

    # Record credit.
    logging.debug('Credit: {} of {} to {}'.format(devise(db, amount, asset, 'output'), asset, address))
    element_data = { 
        'address': address,
        'asset': asset,
        'amount': amount
    }
    credit_cursor.execute(*get_insert_sql('credits', element_data))
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

def get_debits (db, address=None, asset=None, filters=None, order_by=None, order_dir='asc', filterop='and'):
    """This does not include BTC."""
    if filters is None: filters = list()
    if filters and not isinstance(filters, list): filters = [filters,] 
    if address: filters.append({'field': 'address', 'op': '==', 'value': address})
    if asset: filters.append({'field': 'asset', 'op': '==', 'value': asset})
    cursor = db.cursor()
    cursor.execute('''SELECT * FROM debits''')
    results = do_filter(cursor.fetchall(), filters, filterop)
    cursor.close()
    return do_order_by(results, order_by, order_dir)

def get_credits (db, address=None, asset=None, filters=None, order_by=None, order_dir='asc', filterop='and'):
    """This does not include BTC."""
    if filters is None: filters = list()
    if filters and not isinstance(filters, list): filters = [filters,] 
    if address: filters.append({'field': 'address', 'op': '==', 'value': address})
    if asset: filters.append({'field': 'asset', 'op': '==', 'value': asset})
    cursor = db.cursor()
    cursor.execute('''SELECT * FROM credits''')
    results = do_filter(cursor.fetchall(), filters, filterop)
    cursor.close()
    return do_order_by(results, order_by, order_dir)

def get_balances (db, address=None, asset=None, filters=None, order_by=None, order_dir='asc', filterop='and'):
    """This should never be used to check Bitcoin balances."""
    if filters is None: filters = list()
    if filters and not isinstance(filters, list): filters = [filters,] 
    if address: filters.append({'field': 'address', 'op': '==', 'value': address})
    if asset: filters.append({'field': 'asset', 'op': '==', 'value': asset})
    cursor = db.cursor()
    cursor.execute('''SELECT * FROM balances''')
    results = do_filter(cursor.fetchall(), filters, filterop)
    cursor.close()
    return do_order_by(results, order_by, order_dir)

def get_sends (db, validity=None, source=None, destination=None, filters=None, order_by='tx_index', order_dir='asc', start_block=None, end_block=None, filterop='and'):
    if filters is None: filters = list()
    if filters and not isinstance(filters, list): filters = [filters,] 
    if validity: filters.append({'field': 'validity', 'op': '==', 'value': validity})
    if source: filters.append({'field': 'source', 'op': '==', 'value': source})
    if destination: filters.append({'field': 'destination', 'op': '==', 'value': destination})
    cursor = db.cursor()
    cursor.execute('''SELECT * FROM sends%s'''
        % get_limit_to_blocks(start_block, end_block))
    results = do_filter(cursor.fetchall(), filters, filterop)
    cursor.close()
    return do_order_by(results, order_by, order_dir)

def get_orders (db, validity=None, source=None, show_empty=True, show_expired=True, filters=None, order_by='price', order_dir='asc', start_block=None, end_block=None, filterop='and'):
    def filter_expired(e):
        #Ignore BTC orders one block early. (This is why we need show_expired.)
        #function returns True if the element is NOT expired
        time_left = get_time_left(e)
        if e['give_asset'] == 'BTC': time_left -= 1
        return False if time_left < 0 else True

    if filters is None: filters = list()
    if filters and not isinstance(filters, list): filters = [filters,] 
    if validity: filters.append({'field': 'validity', 'op': '==', 'value': validity})
    if source: filters.append({'field': 'source', 'op': '==', 'value': source})
    if not show_empty: filters.append({'field': 'give_remaining', 'op': '!=', 'value': 0})
    cursor = db.cursor()
    cursor.execute('''SELECT * FROM orders%s'''
        % get_limit_to_blocks(start_block, end_block))
    results = do_filter(cursor.fetchall(), filters, filterop)
    cursor.close()
    if not show_expired: results = [e for e in results if filter_expired(e)]
    return do_order_by(results, order_by, order_dir)

def get_order_matches (db, validity=None, is_mine=False, address=None, tx0_hash=None, tx1_hash=None, filters=None, order_by='tx1_index', order_dir='asc', start_block=None, end_block=None, filterop='and'):
    def filter_is_mine(e):
        if (    (not bitcoin.rpc('validateaddress', [e['tx0_address']])['ismine'] or 
                 e['forward_asset'] != 'BTC')
            and (not bitcoin.rpc('validateaddress', [e['tx1_address']])['ismine'] or
                 e['backward_asset'] != 'BTC')):
            return False #is not mine
        return True #is mine
    if filters is None: filters = list()
    if filters and not isinstance(filters, list): filters = [filters,] 
    if validity: filters.append({'field': 'validity', 'op': '==', 'value': validity})
    if tx0_hash: filters.append({'field': 'tx0_hash', 'op': '==', 'value': tx0_hash})
    if tx1_hash: filters.append({'field': 'tx1_hash', 'op': '==', 'value': tx1_hash})
    cursor = db.cursor()
    cursor.execute('''SELECT * FROM order_matches%s'''
        % get_limit_to_blocks(start_block, end_block,
            col_names=['tx0_block_index', 'tx1_block_index']))
    results = do_filter(cursor.fetchall(), filters, filterop)
    cursor.close()
    if is_mine: results = [e for e in results if filter_is_mine(e)]
    if address: results = [e for e in results if e['tx0_address'] == address or e['tx1_address'] == address]
    return do_order_by(results, order_by, order_dir)

def get_btcpays (db, validity=None, filters=None, order_by='tx_index', order_dir='asc', start_block=None, end_block=None, filterop='and'):
    if filters is None: filters = list()
    if filters and not isinstance(filters, list): filters = [filters,] 
    if validity: filters.append({'field': 'validity', 'op': '==', 'value': validity})
    cursor = db.cursor()
    cursor.execute('''SELECT * FROM btcpays%s'''
        % get_limit_to_blocks(start_block, end_block))
    results = do_filter(cursor.fetchall(), filters, filterop)
    cursor.close()
    return do_order_by(results, order_by, order_dir)

def get_issuances (db, validity=None, asset=None, issuer=None, filters=None, order_by='tx_index', order_dir='asc', start_block=None, end_block=None, filterop='and'):
    if filters is None: filters = list()
    if filters and not isinstance(filters, list): filters = [filters,] 
    if validity: filters.append({'field': 'validity', 'op': '==', 'value': validity})
    if asset: filters.append({'field': 'asset', 'op': '==', 'value': asset})
    if issuer: filters.append({'field': 'issuer', 'op': '==', 'value': issuer})
    cursor = db.cursor()
    cursor.execute('''SELECT * FROM issuances%s'''
         % get_limit_to_blocks(start_block, end_block))
    results = do_filter(cursor.fetchall(), filters, filterop)
    cursor.close()
    return do_order_by(results, order_by, order_dir)

def get_broadcasts (db, validity=None, source=None, filters=None, order_by='tx_index', order_dir='asc', start_block=None, end_block=None, filterop='and'):
    if filters is None: filters = list()
    if filters and not isinstance(filters, list): filters = [filters,] 
    if validity: filters.append({'field': 'validity', 'op': '==', 'value': validity})
    if source: filters.append({'field': 'source', 'op': '==', 'value': source})
    cursor = db.cursor()
    cursor.execute('''SELECT * FROM broadcasts%s'''
         % get_limit_to_blocks(start_block, end_block))
    results = do_filter(cursor.fetchall(), filters, filterop)
    cursor.close()
    return do_order_by(results, order_by, order_dir)

def get_bets (db, validity=None, source=None, show_empty=True, filters=None, order_by='odds', order_dir='desc', start_block=None, end_block=None, filterop='and'):
    if filters is None: filters = list()
    if filters and not isinstance(filters, list): filters = [filters,] 
    if validity: filters.append({'field': 'validity', 'op': '==', 'value': validity})
    if source: filters.append({'field': 'source', 'op': '==', 'value': source})
    if not show_empty: filters.append({'field': 'wager_remaining', 'op': '==', 'value': 0})
    cursor = db.cursor()
    cursor.execute('''SELECT * FROM bets%s'''
        % get_limit_to_blocks(start_block, end_block))
    results = do_filter(cursor.fetchall(), filters, filterop)
    cursor.close()
    return do_order_by(results, order_by, order_dir)

def get_bet_matches (db, validity=None, address=None, tx0_hash=None, tx1_hash=None, filters=None, order_by='tx1_index', order_dir='asc', start_block=None, end_block=None, filterop='and'):
    if filters is None: filters = list()
    if filters and not isinstance(filters, list): filters = [filters,] 
    if validity: filters.append({'field': 'validity', 'op': '==', 'value': validity})
    if tx0_hash: filters.append({'field': 'tx0_hash', 'op': '==', 'value': tx0_hash})
    if tx1_hash: filters.append({'field': 'tx1_hash', 'op': '==', 'value': tx1_hash})
    cursor = db.cursor()
    cursor.execute('''SELECT * FROM bet_matches%s'''
         % get_limit_to_blocks(start_block, end_block,
             col_names=['tx0_block_index', 'tx1_block_index']))
    results = do_filter(cursor.fetchall(), filters, filterop)
    cursor.close()
    if address: results = [e for e in results if e['tx0_address'] == address or e['tx1_address'] == address]
    return do_order_by(results, order_by, order_dir)

def get_dividends (db, validity=None, source=None, asset=None, filters=None, order_by='tx_index', order_dir='asc', start_block=None, end_block=None, filterop='and'):
    if filters is None: filters = list()
    if filters and not isinstance(filters, list): filters = [filters,] 
    if validity: filters.append({'field': 'validity', 'op': '==', 'value': validity})
    if source: filters.append({'field': 'source', 'op': '==', 'value': source})
    if asset: filters.append({'field': 'asset', 'op': '==', 'value': asset})
    cursor = db.cursor()
    cursor.execute('''SELECT * FROM dividends%s'''
         % get_limit_to_blocks(start_block, end_block))
    results = do_filter(cursor.fetchall(), filters, filterop)
    cursor.close()
    return do_order_by(results, order_by, order_dir)

def get_burns (db, validity=True, address=None, filters=None, order_by='tx_index', order_dir='asc', start_block=None, end_block=None, filterop='and'):
    if filters is None: filters = list()
    if filters and not isinstance(filters, list): filters = [filters,] 
    if validity: filters.append({'field': 'validity', 'op': '==', 'value': validity})
    if address: filters.append({'field': 'address', 'op': '==', 'value': address})
    cursor = db.cursor()
    cursor.execute('''SELECT * FROM burns%s'''
         % get_limit_to_blocks(start_block, end_block))
    results = do_filter(cursor.fetchall(), filters, filterop)
    cursor.close()
    return do_order_by(results, order_by, order_dir)

def get_cancels (db, validity=True, source=None, filters=None, order_by=None, order_dir=None, start_block=None, end_block=None, filterop='and'):
    if filters is None: filters = list()
    if filters and not isinstance(filters, list): filters = [filters,] 
    if validity: filters.append({'field': 'validity', 'op': '==', 'value': validity})
    if source: filters.append({'field': 'source', 'op': '==', 'value': source})
    cursor = db.cursor()
    cursor.execute('''SELECT * FROM cancels%s'''
         % get_limit_to_blocks(start_block, end_block))
    results = do_filter(cursor.fetchall(), filters, filterop)
    cursor.close()
    return do_order_by(results, order_by, order_dir)

def get_address (db, address):
    if not bitcoin.base58_decode(address, config.ADDRESSVERSION):
        raise exceptions.InvalidAddressError('Not a valid Bitcoin address:',
                                             address)
    address_dict = {}
    address_dict['balances'] = get_balances(db, address=address)
    address_dict['burns'] = get_burns(db, validity='Valid', address=address, order_by='block_index', order_dir='asc')
    address_dict['sends'] = get_sends(db, validity='Valid', source=address, order_by='block_index', order_dir='asc')
    address_dict['orders'] = get_orders(db, validity='Valid', source=address, order_by='block_index', order_dir='asc')
    address_dict['order_matches'] = get_order_matches(db, validity='Valid', address=address, order_by='tx0_block_index', order_dir='asc')
    address_dict['btcpays'] = get_btcpays(db, validity='Valid', order_by='block_index', order_dir='asc')
    address_dict['issuances'] = get_issuances(db, validity='Valid', issuer=address, order_by='block_index', order_dir='asc')
    address_dict['broadcasts'] = get_broadcasts(db, validity='Valid', source=address, order_by='block_index', order_dir='asc')
    address_dict['bets'] = get_bets(db, validity='Valid', source=address, order_by='block_index', order_dir='asc')
    address_dict['bet_matches'] = get_bet_matches(db, validity='Valid', address=address, order_by='tx0_block_index', order_dir='asc')
    address_dict['dividends'] = get_dividends(db, validity='Valid', source=address, order_by='block_index', order_dir='asc')
    return address_dict

# vim: tabstop=8 expandtab shiftwidth=4 softtabstop=4
