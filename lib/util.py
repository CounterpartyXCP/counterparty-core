import time
import decimal
import sys
import json
import logging
import operator
import apsw
import collections
import inspect
import requests
from datetime import datetime
from dateutil.tz import tzlocal
from operator import itemgetter
import fractions

from . import (config, exceptions)

D = decimal.Decimal
b26_digits = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'

# Obsolete in Python 3.4, with enum module.
BET_TYPE_NAME = {0: 'BullCFD', 1: 'BearCFD', 2: 'Equal', 3: 'NotEqual'}
BET_TYPE_ID = {'BullCFD': 0, 'BearCFD': 1, 'Equal': 2, 'NotEqual': 3}


def api (method, params):
    headers = {'content-type': 'application/json'}
    payload = {
        "method": method,
        "params": params,
        "jsonrpc": "2.0",
        "id": 0,
    }
    response = requests.post(config.RPC, data=json.dumps(payload), headers=headers)
    if response == None:
        raise exceptions.RPCError('Cannot communicate with counterpartyd server.')
    elif response.status_code != 200:
        if response.status_code == 500:
            raise exceptions.RPCError('Malformed API call.')
        else:
            raise exceptions.RPCError(str(response.status_code) + ' ' + response.reason)

    response_json = response.json()
    if 'error' not in response_json.keys() or response_json['error'] == None:
        return response_json['result']
    else:
        raise exceptions.RPCError('{}'.format(response_json['error']))

def price (numerator, denominator, block_index):
    if block_index >= 294500 or config.TESTNET: # Protocol change.
        return fractions.Fraction(numerator, denominator)
    else:
        numerator = D(numerator)
        denominator = D(denominator)
        return D(numerator / denominator)

def log (db, command, category, bindings):

    # Slow?!
    def output (quantity, asset):
        try:
            if asset not in ('fraction', 'leverage'):
                return str(devise(db, quantity, asset, 'output')) + ' ' + asset
            else:
                return str(devise(db, quantity, asset, 'output'))
        except exceptions.AssetError:
            return '<AssetError>'
        except decimal.DivisionByZero:
            return '<DivisionByZero>'

    if command == 'update':
        if category == 'order':
            logging.debug('Database: set status of order {} to {}.'.format(bindings['tx_hash'], bindings['status']))
        elif category == 'bet':
            logging.debug('Database: set status of bet {} to {}.'.format(bindings['tx_hash'], bindings['status']))
        elif category == 'order_matches':
            logging.debug('Database: set status of order_match {} to {}.'.format(bindings['order_match_id'], bindings['status']))
        elif category == 'bet_matches':
            logging.debug('Database: set status of bet_match {} to {}.'.format(bindings['bet_match_id'], bindings['status']))
        # TODO: elif category == 'balances':
            # logging.debug('Database: set balance of {} in {} to {}.'.format(bindings['address'], bindings['asset'], output(bindings['quantity'], bindings['asset']).split(' ')[0]))

    elif command == 'insert':

        if category == 'credits':
            logging.debug('Credit: {} to {} #{}# <{}>'.format(output(bindings['quantity'], bindings['asset']), bindings['address'], bindings['action'], bindings['event']))

        elif category == 'debits':
            logging.debug('Debit: {} from {} #{}# <{}>'.format(output(bindings['quantity'], bindings['asset']), bindings['address'], bindings['action'], bindings['event']))

        elif category == 'sends':
            logging.info('Send: {} from {} to {} ({}) [{}]'.format(output(bindings['quantity'], bindings['asset']), bindings['source'], bindings['destination'], bindings['tx_hash'], bindings['status']))

        elif category == 'orders':
            logging.info('Order: give {} for {} in {} blocks, with a provided fee of {} BTC and a required fee of {} BTC ({}) [{}]'.format(output(bindings['give_quantity'], bindings['give_asset']), output(bindings['get_quantity'], bindings['get_asset']), bindings['expiration'], bindings['fee_provided'] / config.UNIT, bindings['fee_required'] / config.UNIT, bindings['tx_hash'], bindings['status']))

        elif category == 'order_matches':
            logging.info('Order Match: {} for {} ({}) [{}]'.format(output(bindings['forward_quantity'], bindings['forward_asset']), output(bindings['backward_quantity'], bindings['backward_asset']), bindings['id'], bindings['status']))

        elif category == 'btcpays':
            logging.info('BTC Payment: {} paid {} to {} for order match {} ({}) [{}]'.format(bindings['source'], output(bindings['btc_amount'], 'BTC'), bindings['destination'], bindings['order_match_id'], bindings['tx_hash'], bindings['status']))

        elif category == 'issuances':
            if bindings['transfer']:
                logging.info('Issuance: {} transfered asset {} to {} ({}) [{}]'.format(bindings['source'], bindings['asset'], bindings['issuer'], bindings['tx_hash'], bindings['status']))
            elif bindings['locked']:
                logging.info('Issuance: {} locked asset {} ({}) [{}]'.format(bindings['issuer'], bindings['asset'], bindings['tx_hash'], bindings['status']))
            else:
                if bindings['divisible']:
                    divisibility = 'divisible'
                    unit = config.UNIT
                else:
                    divisibility = 'indivisible'
                    unit = 1
                if bindings['callable'] and (bindings['block_index'] > 283271 or config.TESTNET):   # Protocol change.
                    callability = 'callable from {} for {} XCP/{}'.format(isodt(bindings['call_date']), bindings['call_price'], bindings['asset'])
                else:
                    callability = 'uncallable'
                try:
                    quantity = devise(db, bindings['quantity'], None, dest='output', divisible=bindings['divisible'])
                except:
                    quantity = '?'
                logging.info('Issuance: {} created {} of asset {}, which is {} and {}, with description ‘{}’ ({}) [{}]'.format(bindings['issuer'], quantity, bindings['asset'], divisibility, callability, bindings['description'], bindings['tx_hash'], bindings['status']))

        elif category == 'broadcasts':
            if bindings['locked']:
                logging.info('Broadcast: {} locked his feed ({}) [{}]'.format(bindings['source'], bindings['tx_hash'], bindings['status']))
            else:
                if not bindings['value']: infix = '‘{}’'.format(bindings['text'])
                else: infix = '‘{}’ = {}'.format(bindings['text'], bindings['value'])
                suffix = ' from ' + bindings['source'] + ' at ' + isodt(bindings['timestamp']) + ' with a fee of {}%'.format(output(D(bindings['fee_fraction_int'] / 1e8) * D(100), 'fraction')) + ' (' + bindings['tx_hash'] + ')' + ' [{}]'.format(bindings['status'])
                logging.info('Broadcast: {}'.format(infix + suffix))

        elif category == 'bets':
            # Last text
            broadcasts = get_broadcasts(db, status='valid', source=bindings['feed_address'], order_by='tx_index', order_dir='asc')
            try:
                last_broadcast = broadcasts[-1]
                text = last_broadcast['text']
            except IndexError:
                text = '<Text>'

            # Suffix
            end = 'in {} blocks, for a fee of {} ({}) [{}]'.format(bindings['expiration'], output(bindings['fee_paid'], 'XCP'), bindings['tx_hash'], bindings['status'])

            if 'CFD' not in BET_TYPE_NAME[bindings['bet_type']]:
                log_message = 'Bet: {} against {}, by {}, on {} that ‘{}’ will {} {} at {}, {}'.format(output(bindings['wager_quantity'], 'XCP'), output(bindings['counterwager_quantity'], 'XCP'), bindings['source'], bindings['feed_address'], text, BET_TYPE_NAME[bindings['bet_type']], str(output(bindings['target_value'], 'value').split(' ')[0]), isodt(bindings['deadline']), end)
            else:
                log_message = 'Bet: {}, by {}, on {} for {} against {}, leveraged {}x, {}'.format(BET_TYPE_NAME[bindings['bet_type']], bindings['source'], bindings['feed_address'],output(bindings['wager_quantity'], 'XCP'), output(bindings['counterwager_quantity'], 'XCP'), output(bindings['leverage']/ 5040, 'leverage'), end)

            logging.info(log_message)

        elif category == 'bet_matches':
            placeholder = ''
            if bindings['target_value'] >= 0:    # Only non‐negative values are valid.
                placeholder = ' that ' + str(output(bindings['target_value'], 'value'))
            if bindings['leverage']:
                placeholder += ', leveraged {}x'.format(output(bindings['leverage'] / 5040, 'leverage'))
            logging.info('Bet Match: {} for {} against {} for {} on {} at {}{} ({}) [{}]'.format(BET_TYPE_NAME[bindings['tx0_bet_type']], output(bindings['forward_quantity'], 'XCP'), BET_TYPE_NAME[bindings['tx1_bet_type']], output(bindings['backward_quantity'], 'XCP'), bindings['feed_address'], isodt(bindings['deadline']), placeholder, bindings['id'], bindings['status']))

        elif category == 'dividends':
            logging.info('Dividend: {} paid {} per unit of {} ({}) [{}]'.format(bindings['source'], output(bindings['quantity_per_unit'], bindings['dividend_asset']), bindings['asset'], bindings['tx_hash'], bindings['status']))

        elif category == 'burns':
            logging.info('Burn: {} burned {} for {} ({}) [{}]'.format(bindings['source'], output(bindings['burned'], 'BTC'), output(bindings['earned'], 'XCP'), bindings['tx_hash'], bindings['status']))

        elif category == 'cancels':
            logging.info('Cancel: {} ({}) [{}]'.format(bindings['offer_hash'], bindings['tx_hash'], bindings['status']))

        elif category == 'callbacks':
            logging.info('Callback: {} called back {}% of {} ({}) [{}]'.format(bindings['source'], float(D(bindings['fraction']) * D(100)), bindings['asset'], bindings['tx_hash'], bindings['status']))

        elif category == 'order_expirations':
            logging.info('Expired order: {}'.format(bindings['order_hash']))

        elif category == 'order_match_expirations':
            logging.info('Expired Order Match awaiting payment: {}'.format(bindings['order_match_id']))

        elif category == 'bet_expirations':
            logging.info('Expired bet: {}'.format(bindings['bet_hash']))

        elif category == 'bet_match_expirations':
            logging.info('Expired Bet Match: {}'.format(bindings['bet_match_id']))

def message (db, block_index, command, category, bindings):
    cursor = db.cursor()

    # Get last message index.
    messages = list(cursor.execute('''SELECT * FROM messages
                                      WHERE message_index = (SELECT MAX(message_index) from messages)'''))
    if messages:
        assert len(messages) == 1
        message_index = messages[0]['message_index'] + 1
    else:
        message_index = 0

    bindings_string = json.dumps(collections.OrderedDict(sorted(bindings.items())))
    cursor.execute('insert into messages values(:message_index, :block_index, :command, :category, :bindings)',
                   (message_index, block_index, command, category, bindings_string))

    cursor.close()

       
def rowtracer(cursor, sql):
    """Converts fetched SQL data into dict-style"""
    dictionary = {}
    for index, (name, type_) in enumerate(cursor.getdescription()):
        dictionary[name] = sql[index]
    return dictionary

def exectracer(cursor, sql, bindings):
    # This means that all changes to database must use a very simple syntax.
        # TODO: Need sanity checks here.
    sql = sql.lower()

    # Parse SQL.
    array = sql.split('(')[0].split(' ')
    if 'insert' in sql:
        command, category = array[0], array[2]
    elif 'update' in sql:
        command, category = array[0], array[1]
    else:
        return True

    db = cursor.getconnection()
    dictionary = {'command': command, 'category': category, 'bindings': bindings}

    # Skip blocks, transactions.
    if 'blocks' in sql or 'transactions' in sql: return True

    # Record alteration in database.
    if category not in ('balances', 'messages'):
        if not (command in ('update') and category in ('orders', 'bets', 'order_matches', 'bet_matches')):    # List message manually.
            try:
                block_index = bindings['block_index']
            except KeyError:
                block_index = bindings['tx1_block_index']
            message(db, block_index, command, category, bindings)

    # Log.
    log(db, command, category, bindings)

    return True

def connect_to_db(flags=None):
    """Connects to the SQLite database, returning a db Connection object"""

    if flags == None:
        db = apsw.Connection(config.DATABASE)
    elif flags == 'SQLITE_OPEN_READONLY':
        db = apsw.Connection(config.DATABASE, flags=0x00000001)
    else:
        raise Exception # TODO

    cursor = db.cursor()

    # For speed.
    cursor.execute('''PRAGMA count_changes = OFF''')

    # For integrity, security.
    cursor.execute('''PRAGMA foreign_keys = ON''')
    cursor.execute('''PRAGMA defer_foreign_keys = ON''')

    # So that writers don’t block readers.
    cursor.execute('''PRAGMA journal_mode = WAL''')

    rows = list(cursor.execute('''PRAGMA foreign_key_check'''))
    if rows: raise exceptions.DatabaseError('Foreign key check failed.')

    # Integrity check
    integral = False
    for i in range(10): # DUPE
        try:
            cursor.execute('''PRAGMA integrity_check''')
            rows = cursor.fetchall()
            if not (len(rows) == 1 and rows[0][0] == 'ok'):
                raise exceptions.DatabaseError('Integrity check failed.')
            integral = True
            break
        except Exception:
            time.sleep(1)
            continue
    if not integral:
        raise exceptions.DatabaseError('Could not perform integrity check.')

    cursor.close()

    db.setrowtrace(rowtracer)
    db.setexectrace(exectracer)

    return db

def versions_check (db):
    try:
        host = 'https://raw2.github.com/PhantomPhreak/counterpartyd/master/versions.json'
        response = requests.get(host, headers={'cache-control': 'no-cache'})
        versions = json.loads(response.text)
    except Exception as e:
        raise exceptions.DatabaseVersionError('Unable to check client, database versions. How’s your Internet access?')
 
    # Check client version (for important UI changes).
    if config.CLIENT_VERSION_MAJOR < versions['minimum_client_version_major']:
        if config.CLIENT_VERSION_MiNOR < versions['minimum_client_version_minor']:
            raise exceptions.ClientVersionError('Please upgrade counterpartyd to the latest version and restart the server.')

    # Check the database version when past the block at which the protocol change
    # comes into effect.
    try:
        block_index = last_block(db)['block_index']
    except (exceptions.DatabaseError, apsw.SQLError):
        logging.debug('Status: Version checks passed.') # DUPE
        return
    for protocol_change in versions['protocol_changes']:
        if block_index >= protocol_change['block_index']:
            if config.DB_VERSION_MAJOR < protocol_change['minimum_database_version_major']:
                if config.DB_VERSION_MINOR < protocol_change['minimum_database_version_minor']:
                    raise exceptions.DatabaseVersionError('Please upgrade counterpartyd to the latest version and restart the server.')

    logging.debug('Status: Version checks passed.')
    return

def database_check (db, blockcount):
    """Checks Counterparty database to see if the counterpartyd server has caught up with Bitcoind."""
    cursor = db.cursor()
    TRIES = 14
    for i in range(TRIES):
        block_index = last_block(db)['block_index']
        if block_index == blockcount:
            cursor.close()
            return
        print('Database not up‐to‐date. Sleeping for one second. (Try {}/{})'.format(i+1, TRIES), file=sys.stderr)
        time.sleep(1)
    raise exceptions.DatabaseError('Counterparty database is behind Bitcoind. Is the counterpartyd server running?')


def isodt (epoch_time):
    return datetime.fromtimestamp(epoch_time, tzlocal()).isoformat()

def sortkeypicker(keynames):
    """http://stackoverflow.com/a/1143719"""
    negate = set()
    for i, k in enumerate(keynames):
        if k[:1] == '-':
            keynames[i] = k[1:]
            negate.add(k[1:])
    def getit(adict):
       composite = [adict[k] for k in keynames]
       for i, (k, v) in enumerate(zip(keynames, composite)):
           if k in negate:
               composite[i] = -v
       return composite
    return getit

def last_block (db):
    cursor = db.cursor()
    blocks = list(cursor.execute('''SELECT * FROM blocks WHERE block_index = (SELECT MAX(block_index) from blocks)'''))
    if blocks:
        assert len(blocks) == 1
        last_block = blocks[0]
    else:
        raise exceptions.DatabaseError('No blocks found.')
    cursor.close()
    return last_block

def last_message (db):
    cursor = db.cursor()
    messages = list(cursor.execute('''SELECT * FROM messages WHERE message_index = (SELECT MAX(message_index) from messages)'''))
    if messages:
        assert len(messages) == 1
        last_message = messages[0]
    else:
        raise exceptions.DatabaseError('No messages found.')
    cursor.close()
    return last_message

def get_asset_id (asset):
    # Special cases.
    if asset == 'BTC': return 0
    elif asset == 'XCP': return 1

    if asset[0] == 'A': raise exceptions.AssetNameError('starts with ‘A’')

    # Checksum
    """
    if not checksum.verify(asset):
        raise exceptions.AssetNameError('invalid checksum')
    else:
        asset = asset[:-1]  # Strip checksum character.
    """

    # Convert the Base 26 string to an integer.
    n = 0
    for c in asset:
        n *= 26
        if c not in b26_digits:
            raise exceptions.AssetNameError('invalid character:', c)
        digit = b26_digits.index(c)
        n += digit

    if n < 26**3:
        raise exceptions.AssetNameError('too short')

    return n

def get_asset_name (asset_id):
    if asset_id == 0: return 'BTC'
    elif asset_id == 1: return 'XCP'

    if asset_id < 26**3:
        raise exceptions.AssetIDError('too low')

    # Divide that integer into Base 26 string.
    res = []
    n = asset_id
    while n > 0:
        n, r = divmod (n, 26)
        res.append(b26_digits[r])
    asset_name = ''.join(res[::-1])

    """
    return asset_name + checksum.compute(asset_name)
    """
    return asset_name


def debit (db, block_index, address, asset, quantity, action=None, event=None):
    debit_cursor = db.cursor()
    assert asset != 'BTC' # Never BTC.
    assert type(quantity) == int
    assert quantity >= 0

    if asset == 'BTC':
        raise exceptions.BalanceError('Cannot debit bitcoins from a Counterparty address!')

    debit_cursor.execute('''SELECT * FROM balances \
                            WHERE (address = ? AND asset = ?)''', (address, asset))
    balances = debit_cursor.fetchall()
    if not len(balances) == 1: old_balance = 0
    else: old_balance = balances[0]['quantity']

    if old_balance < quantity:
        raise exceptions.BalanceError('Insufficient funds.')

    balance = round(old_balance - quantity)
    balance = min(balance, config.MAX_INT)
    assert balance >= 0

    bindings = {
        'quantity': balance,
        'address': address,
        'asset': asset
    }
    sql='update balances set quantity = :quantity where (address = :address and asset = :asset)'
    debit_cursor.execute(sql, bindings)

    # Record debit.
    bindings = {
        'block_index': block_index,
        'address': address,
        'asset': asset,
        'quantity': quantity,
        'action': action,
        'event': event
    }
    sql='insert into debits values(:block_index, :address, :asset, :quantity, :action, :event)'
    debit_cursor.execute(sql, bindings)

    debit_cursor.close()

def credit (db, block_index, address, asset, quantity, action=None, event=None):
    credit_cursor = db.cursor()
    assert asset != 'BTC' # Never BTC.
    assert type(quantity) == int
    assert quantity >= 0

    credit_cursor.execute('''SELECT * FROM balances \
                             WHERE (address = ? AND asset = ?)''', (address, asset))
    balances = credit_cursor.fetchall()
    if len(balances) == 0:
        assert balances == []

        #update balances table with new balance
        bindings = {
            'address': address,
            'asset': asset,
            'quantity': quantity,
        }
        sql='insert into balances values(:address, :asset, :quantity)'
        credit_cursor.execute(sql, bindings)
    elif len(balances) > 1:
        raise Exception
    else:
        old_balance = balances[0]['quantity']
        assert type(old_balance) == int
        balance = round(old_balance + quantity)
        balance = min(balance, config.MAX_INT)

        bindings = {
            'quantity': balance,
            'address': address,
            'asset': asset
        }
        sql='update balances set quantity = :quantity where (address = :address and asset = :asset)'
        credit_cursor.execute(sql, bindings)

    # Record credit.
    bindings = {
        'block_index': block_index,
        'address': address,
        'asset': asset,
        'quantity': quantity,
        'action': action,
        'event': event
    }
    sql='insert into credits values(:block_index, :address, :asset, :quantity, :action, :event)'
    credit_cursor.execute(sql, bindings)
    credit_cursor.close()

def devise (db, quantity, asset, dest, divisible=None):

    # For output only.
    def norm(num, places):
        # Round only if necessary.
        num = round(num, places)

        fmt = '{:.' + str(places) + 'f}'
        num = fmt.format(num)
        return num.rstrip('0')+'0' if num.rstrip('0')[-1] == '.' else num.rstrip('0')

    # TODO: remove price, odds
    if asset in ('leverage', 'value', 'fraction', 'price', 'odds'):
        if dest == 'output':
            return norm(quantity, 6)
        elif dest == 'input':
            # Hackish
            if asset == 'leverage':
                return round(quantity)
            else:
                return float(quantity)  # TODO: Float?!

    if asset in ('fraction',):
        return norm(fraction(quantity, 1e8), 6)

    if divisible == None:
        if asset in ('BTC', 'XCP'):
            divisible = True
        else:
            cursor = db.cursor()
            cursor.execute('''SELECT * FROM issuances \
                              WHERE (status = ? AND asset = ?)''', ('valid', asset))
            issuances = cursor.fetchall()
            cursor.close()
            if not issuances: raise exceptions.AssetError('No such asset: {}'.format(asset))
            divisible = issuances[0]['divisible']

    if divisible:
        if dest == 'output':
            quantity = D(quantity) / D(config.UNIT)
            if quantity == quantity.to_integral():
                return str(quantity) + '.0'  # For divisible assets, display the decimal point.
            else:
                return norm(quantity, 8)
        elif dest == 'input':
            quantity = D(quantity) * config.UNIT
            if quantity == quantity.to_integral():
                return int(quantity)
            else:
                raise exceptions.QuantityError('Divisible assets have only eight decimal places of precision.')
        else:
            return quantity
    else:
        quantity = D(quantity)
        if quantity != round(quantity):
            raise exceptions.QuantityError('Fractional quantities of indivisible assets.')
        return round(quantity)







DO_FILTER_OPERATORS = {
    '==': operator.eq,
    '!=': operator.ne,
    '<': operator.lt,
    '>': operator.gt,
    '<=': operator.le,
    '>=': operator.ge,
}

def do_filter(results, filters, filterop):
    """Filters results based on a filter data structure (as used by the API)"""
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
        if results[0][filter['field']] != None and filter['value'] != None and type(filter['value']) != type(results[0][filter['field']]):
            # field is None when it does not matter.
            raise Exception("Value specified for filter field '%s' does not match the data type of that field (value: %s, field: %s) and neither is None" % (
                filter['field'], type(filter['value']), type(results[0][filter['field']])))
    #filter data
    if filterop == 'and':
        for filter in filters:
            results = [e for e in results if DO_FILTER_OPERATORS[filter['op']](e[filter['field']], filter['value'])]
        return results
    else: #or
        combined_results = []
        for filter in filters:
            if filter['field'] == 'status': continue #don't filter status as an OR requirement
            combined_results += [e for e in results if DO_FILTER_OPERATORS[filter['op']](e[filter['field']], filter['value'])]
        
        status_filter = next((f for f in filters if f['field'] == 'status'), None)
        if status_filter: #filter out invalid results as an AND requirement
            combined_results = [e for e in combined_results if DO_FILTER_OPERATORS[status_filter['op']](
                e[status_filter['field']], status_filter['value'])]
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
                col_names[0], start_block, col_names[1], start_block,
                col_names[0], end_block, col_names[1], end_block)
        elif start_block:
            block_limit_clause = " WHERE %s >= %s OR %s >= %s" % (
                col_names[0], start_block, col_names[1], start_block)
        elif end_block:
            block_limit_clause = " WHERE %s >= %s OR %s >= %s" % (
                col_names[0], end_block, col_names[1], end_block)
    return block_limit_clause


def get_holders(db, asset):
    holders = []
    cursor = db.cursor()
    # Balances
    cursor.execute('''SELECT * FROM balances \
                      WHERE asset = ?''', (asset,))
    for balance in list(cursor):
        holders.append({'address': balance['address'], 'address_quantity': balance['quantity'], 'escrow': None})
    # Funds escrowed in orders. (Protocol change.)
    cursor.execute('''SELECT * FROM orders \
                      WHERE give_asset = ? AND status = ?''', (asset, 'open'))
    for order in list(cursor):
        holders.append({'address': order['source'], 'address_quantity': order['give_remaining'], 'escrow': order['tx_hash']})
    # Funds escrowed in pending order matches. (Protocol change.)
    cursor.execute('''SELECT * FROM order_matches \
                      WHERE (forward_asset = ? AND status = ?)''', (asset, 'pending'))
    for order_match in list(cursor):
        holders.append({'address': order_match['tx0_address'], 'address_quantity': order_match['forward_quantity'], 'escrow': order_match['id']})
    cursor.execute('''SELECT * FROM order_matches \
                      WHERE (backward_asset = ? AND status = ?)''', (asset, 'pending'))
    for order_match in list(cursor):
        holders.append({'address': order_match['tx1_address'], 'address_quantity': order_match['backward_quantity'], 'escrow': order_match['id']})

    # Bets (and bet matches) only escrow XCP.
    if asset == 'XCP':
        cursor.execute('''SELECT * FROM bets \
                          WHERE status = ?''', ('open',))
        for bet in list(cursor):
            holders.append({'address': bet['source'], 'address_quantity': bet['wager_remaining'], 'escrow': bet['tx_hash']})
            holders.append({'address': bet['source'], 'address_quantity': bet['fee_paid'], 'escrow': bet['tx_hash']})
        cursor.execute('''SELECT * FROM bet_matches \
                          WHERE status = ?''', ('pending',))
        for bet_match in list(cursor):
            holders.append({'address': bet_match['tx0_address'], 'address_quantity': bet_match['forward_quantity'], 'escrow': bet_match['id']})
            holders.append({'address': bet_match['tx0_address'], 'address_quantity': bet_match['forward_fee'], 'escrow': bet_match['id']})
            holders.append({'address': bet_match['tx1_address'], 'address_quantity': bet_match['backward_quantity'], 'escrow': bet_match['id']})
            holders.append({'address': bet_match['tx1_address'], 'address_quantity': bet_match['backward_fee'], 'escrow': bet_match['id']})

    cursor.close()
    return holders

def xcp_supply (db):
    cursor = db.cursor()

    # Add burns.
    cursor.execute('''SELECT * FROM burns \
                      WHERE status = ?''', ('valid',))
    burn_total = sum([burn['earned'] for burn in cursor.fetchall()])

    # Subtract issuance fees.
    cursor.execute('''SELECT * FROM issuances\
                      WHERE status = ?''', ('valid',))
    fee_total = sum([issuance['fee_paid'] for issuance in cursor.fetchall()])

    cursor.close()
    return burn_total - fee_total

def get_supplies (db):
    cursor = db.cursor()
    supplies = {'XCP': xcp_supply(db)}
    cursor.execute('''SELECT * from issuances \
                      WHERE status = ?''', ('valid',))
    for issuance in list(cursor):
        asset = issuance['asset']
        quantity = issuance['quantity']
        if asset in supplies.keys():
            supplies[asset] += quantity
        else:
            supplies[asset] = quantity

    cursor.close()
    return supplies 

def get_debits (db, address=None, asset=None, filters=None, order_by=None, order_dir='asc', start_block=None, end_block=None, filterop='and'):
    """This does not include BTC."""
    if filters is None: filters = list()
    if filters and not isinstance(filters, list): filters = [filters,]
    if address: filters.append({'field': 'address', 'op': '==', 'value': address})
    if asset: filters.append({'field': 'asset', 'op': '==', 'value': asset})
    cursor = db.cursor()
    cursor.execute('''SELECT * FROM debits%s'''
        % get_limit_to_blocks(start_block, end_block))
    results = do_filter(cursor.fetchall(), filters, filterop)
    cursor.close()
    return do_order_by(results, order_by, order_dir)

def get_credits (db, address=None, asset=None, filters=None, order_by=None, order_dir='asc', start_block=None, end_block=None, filterop='and'):
    """This does not include BTC."""
    if filters is None: filters = list()
    if filters and not isinstance(filters, list): filters = [filters,]
    if address: filters.append({'field': 'address', 'op': '==', 'value': address})
    if asset: filters.append({'field': 'asset', 'op': '==', 'value': asset})
    cursor = db.cursor()
    cursor.execute('''SELECT * FROM credits%s'''
        % get_limit_to_blocks(start_block, end_block))
    results = do_filter(cursor.fetchall(), filters, filterop)
    cursor.close()
    return do_order_by(results, order_by, order_dir)

def get_balances (db, address=None, asset=None, filters=None, order_by=None, order_dir='asc', filterop='and'):
    """This should never be used to check Bitcoin balances."""
    if filters is None: filters = list()
    if filters and not isinstance(filters, list): filters = [filters,]
    if address:
        from . import bitcoin   # HACK
        if not bitcoin.base58_decode(address, config.ADDRESSVERSION):
            raise exceptions.AddressError('Not a valid Bitcoin address:',
                                                 address)
        filters.append({'field': 'address', 'op': '==', 'value': address})
    if asset: filters.append({'field': 'asset', 'op': '==', 'value': asset})
    cursor = db.cursor()
    cursor.execute('''SELECT * FROM balances''')
    results = do_filter(cursor.fetchall(), filters, filterop)
    cursor.close()
    return do_order_by(results, order_by, order_dir)

def get_sends (db, status=None, source=None, destination=None, filters=None, order_by='tx_index', order_dir='asc', start_block=None, end_block=None, filterop='and'):
    if filters is None: filters = list()
    if filters and not isinstance(filters, list): filters = [filters,]
    if status: filters.append({'field': 'status', 'op': '==', 'value': status})
    if source: filters.append({'field': 'source', 'op': '==', 'value': source})
    if destination: filters.append({'field': 'destination', 'op': '==', 'value': destination})
    cursor = db.cursor()
    cursor.execute('''SELECT * FROM sends%s'''
        % get_limit_to_blocks(start_block, end_block))
    results = do_filter(cursor.fetchall(), filters, filterop)
    cursor.close()
    return do_order_by(results, order_by, order_dir)

def get_orders (db, status=None, source=None, show_expired=True, filters=None, order_by=None, order_dir='asc', start_block=None, end_block=None, filterop='and'):
    def filter_expired(e, cur_block_index):
        #Ignore BTC orders one block early. (This is why we need show_expired.)
        #function returns True if the element is NOT expired
        time_left = e['expire_index'] - cur_block_index
        if e['give_asset'] == 'BTC': time_left -= 1
        return False if time_left < 0 else True

    if filters is None: filters = list()
    if filters and not isinstance(filters, list): filters = [filters,]
    if status: filters.append({'field': 'status', 'op': '==', 'value': status})
    if source: filters.append({'field': 'source', 'op': '==', 'value': source})
    cur_block_index = last_block(db)['block_index']
    cursor = db.cursor()
    cursor.execute('''SELECT * FROM orders%s'''
        % get_limit_to_blocks(start_block, end_block))
    results = do_filter(cursor.fetchall(), filters, filterop)
    cursor.close()
    if not show_expired: results = [e for e in results if filter_expired(e, cur_block_index)]
    return do_order_by(results, order_by, order_dir)

def get_order_matches (db, status=None, post_filter_status=None, is_mine=False, address=None, tx0_hash=None, tx1_hash=None, filters=None, order_by='tx1_index', order_dir='asc', start_block=None, end_block=None, filterop='and'):
    from . import bitcoin   # HACK
    def filter_is_mine(e):
        if (    (not bitcoin.is_mine(e['tx0_address']) or
                 e['forward_asset'] != 'BTC')
            and (not bitcoin.is_mine(e['tx1_address']) or
                 e['backward_asset'] != 'BTC')):
            return False #is not mine
        return True #is mine
    if filters is None: filters = list()
    if filters and not isinstance(filters, list): filters = [filters,]
    if status: filters.append({'field': 'status', 'op': '==', 'value': status})
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
    if post_filter_status: results = [e for e in results if e['status'] == post_filter_status]
    return do_order_by(results, order_by, order_dir)

def get_btcpays (db, status=None, filters=None, order_by='tx_index', order_dir='asc', start_block=None, end_block=None, filterop='and'):
    if filters is None: filters = list()
    if filters and not isinstance(filters, list): filters = [filters,]
    if status: filters.append({'field': 'status', 'op': '==', 'value': status})
    cursor = db.cursor()
    cursor.execute('''SELECT * FROM btcpays%s'''
        % get_limit_to_blocks(start_block, end_block))
    results = do_filter(cursor.fetchall(), filters, filterop)
    cursor.close()
    return do_order_by(results, order_by, order_dir)

def get_issuances (db, status=None, asset=None, issuer=None, filters=None, order_by='tx_index', order_dir='asc', start_block=None, end_block=None, filterop='and'):
    if filters is None: filters = list()
    if filters and not isinstance(filters, list): filters = [filters,]
    if status: filters.append({'field': 'status', 'op': '==', 'value': status})
    if asset: filters.append({'field': 'asset', 'op': '==', 'value': asset})
    if issuer: filters.append({'field': 'issuer', 'op': '==', 'value': issuer})
    # TODO: callable, call_date (range?), call_price (range?)
    # TODO: description search
    cursor = db.cursor()
    cursor.execute('''SELECT * FROM issuances%s'''
         % get_limit_to_blocks(start_block, end_block))
    results = do_filter(cursor.fetchall(), filters, filterop)
    cursor.close()
    return do_order_by(results, order_by, order_dir)

def get_broadcasts (db, status=None, source=None, filters=None, order_by='tx_index', order_dir='asc', start_block=None, end_block=None, filterop='and'):
    if filters is None: filters = list()
    if filters and not isinstance(filters, list): filters = [filters,]
    if status: filters.append({'field': 'status', 'op': '==', 'value': status})
    if source: filters.append({'field': 'source', 'op': '==', 'value': source})
    cursor = db.cursor()
    cursor.execute('''SELECT * FROM broadcasts%s'''
         % get_limit_to_blocks(start_block, end_block))
    results = do_filter(cursor.fetchall(), filters, filterop)
    cursor.close()
    return do_order_by(results, order_by, order_dir)

def get_bets (db, status=None, source=None, filters=None, order_by=None, order_dir='desc', start_block=None, end_block=None, filterop='and'):
    if filters is None: filters = list()
    if filters and not isinstance(filters, list): filters = [filters,]
    if status: filters.append({'field': 'status', 'op': '==', 'value': status})
    if source: filters.append({'field': 'source', 'op': '==', 'value': source})
    cursor = db.cursor()
    cursor.execute('''SELECT * FROM bets%s'''
        % get_limit_to_blocks(start_block, end_block))
    results = do_filter(cursor.fetchall(), filters, filterop)
    cursor.close()
    return do_order_by(results, order_by, order_dir)

def get_bet_matches (db, status=None, address=None, tx0_hash=None, tx1_hash=None, filters=None, order_by='tx1_index', order_dir='asc', start_block=None, end_block=None, filterop='and'):
    if filters is None: filters = list()
    if filters and not isinstance(filters, list): filters = [filters,]
    if status: filters.append({'field': 'status', 'op': '==', 'value': status})
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

def get_dividends (db, status=None, source=None, asset=None, filters=None, order_by='tx_index', order_dir='asc', start_block=None, end_block=None, filterop='and'):
    if filters is None: filters = list()
    if filters and not isinstance(filters, list): filters = [filters,]
    if status: filters.append({'field': 'status', 'op': '==', 'value': status})
    if source: filters.append({'field': 'source', 'op': '==', 'value': source})
    if asset: filters.append({'field': 'asset', 'op': '==', 'value': asset})
    cursor = db.cursor()
    cursor.execute('''SELECT * FROM dividends%s'''
         % get_limit_to_blocks(start_block, end_block))
    results = do_filter(cursor.fetchall(), filters, filterop)
    cursor.close()
    return do_order_by(results, order_by, order_dir)

def get_burns (db, status=None, source=None, filters=None, order_by='tx_index', order_dir='asc', start_block=None, end_block=None, filterop='and'):
    if filters is None: filters = list()
    if filters and not isinstance(filters, list): filters = [filters,]
    if status: filters.append({'field': 'status', 'op': '==', 'value': status})
    if source: filters.append({'field': 'source', 'op': '==', 'value': source})
    cursor = db.cursor()
    cursor.execute('''SELECT * FROM burns%s'''
         % get_limit_to_blocks(start_block, end_block))
    results = do_filter(cursor.fetchall(), filters, filterop)
    cursor.close()
    return do_order_by(results, order_by, order_dir)

def get_cancels (db, status=None, source=None, filters=None, order_by=None, order_dir=None, start_block=None, end_block=None, filterop='and'):
    if filters is None: filters = list()
    if filters and not isinstance(filters, list): filters = [filters,]
    if status: filters.append({'field': 'status', 'op': '==', 'value': status})
    if source: filters.append({'field': 'source', 'op': '==', 'value': source})
    cursor = db.cursor()
    cursor.execute('''SELECT * FROM cancels%s'''
         % get_limit_to_blocks(start_block, end_block))
    results = do_filter(cursor.fetchall(), filters, filterop)
    cursor.close()
    return do_order_by(results, order_by, order_dir)

def get_callbacks (db, status=None, source=None, filters=None, order_by=None, order_dir=None, start_block=None, end_block=None, filterop='and'):
    if filters is None: filters = list()
    if filters and not isinstance(filters, list): filters = [filters,]
    if status: filters.append({'field': 'status', 'op': '==', 'value': status})
    if source: filters.append({'field': 'source', 'op': '==', 'value': source})
    cursor = db.cursor()
    cursor.execute('''SELECT * FROM callbacks%s'''
         % get_limit_to_blocks(start_block, end_block))
    results = do_filter(cursor.fetchall(), filters, filterop)
    cursor.close()
    return do_order_by(results, order_by, order_dir)

def get_bet_expirations (db, source=None, filters=None, order_by=None, order_dir=None, start_block=None, end_block=None, filterop='and'):
    if filters is None: filters = list()
    if filters and not isinstance(filters, list): filters = [filters,]
    if source: filters.append({'field': 'source', 'op': '==', 'value': source})
    cursor = db.cursor()
    cursor.execute('''SELECT * FROM bet_expirations%s'''
         % get_limit_to_blocks(start_block, end_block))
    results = do_filter(cursor.fetchall(), filters, filterop)
    cursor.close()
    return do_order_by(results, order_by, order_dir)

def get_order_expirations (db, source=None, filters=None, order_by=None, order_dir=None, start_block=None, end_block=None, filterop='and'):
    if filters is None: filters = list()
    if filters and not isinstance(filters, list): filters = [filters,]
    if source: filters.append({'field': 'source', 'op': '==', 'value': source})
    cursor = db.cursor()
    cursor.execute('''SELECT * FROM order_expirations%s'''
         % get_limit_to_blocks(start_block, end_block))
    results = do_filter(cursor.fetchall(), filters, filterop)
    cursor.close()
    return do_order_by(results, order_by, order_dir)

def get_bet_match_expirations (db, address=None, filters=None, order_by=None, order_dir=None, start_block=None, end_block=None, filterop='and'):
    if filters is None: filters = list()
    if filters and not isinstance(filters, list): filters = [filters,]
    cursor = db.cursor()
    cursor.execute('''SELECT * FROM bet_match_expirations%s'''
         % get_limit_to_blocks(start_block, end_block))
    results = do_filter(cursor.fetchall(), filters, filterop)
    cursor.close()
    if address: results = [e for e in results if e['tx0_address'] == address or e['tx1_address'] == address]
    return do_order_by(results, order_by, order_dir)

def get_order_match_expirations (db, address=None, filters=None, order_by=None, order_dir=None, start_block=None, end_block=None, filterop='and'):
    if filters is None: filters = list()
    if filters and not isinstance(filters, list): filters = [filters,]
    cursor = db.cursor()
    cursor.execute('''SELECT * FROM order_match_expirations%s'''
         % get_limit_to_blocks(start_block, end_block))
    results = do_filter(cursor.fetchall(), filters, filterop)
    cursor.close()
    if address: results = [e for e in results if e['tx0_address'] == address or e['tx1_address'] == address]
    return do_order_by(results, order_by, order_dir)

def get_address (db, address, start_block=None, end_block=None):
    address_dict = {}
    address_dict['balances'] = get_balances(db, address=address)
    
    address_dict['debits'] = get_debits(db, address=address, order_by='block_index',
        order_dir='asc', start_block=start_block, end_block=end_block)

    address_dict['credits'] = get_credits(db, address=address, order_by='block_index',
        order_dir='asc', start_block=start_block, end_block=end_block)

    address_dict['burns'] = get_burns(db, source=address, order_by='block_index',
        order_dir='asc', start_block=start_block, end_block=end_block)
    
    address_dict['sends'] = get_sends(db, source=address, destination=address, order_by='block_index',
        order_dir='asc', start_block=start_block, end_block=end_block, filterop='or')
    #^ with filterop == 'or', we get all sends where this address was the source OR destination 
    
    address_dict['orders'] = get_orders(db, source=address, order_by='block_index',
        order_dir='asc', start_block=start_block, end_block=end_block)
    
    address_dict['order_matches'] = get_order_matches(db, address=address,
        order_by='tx0_block_index', order_dir='asc', start_block=start_block, end_block=end_block)
    
    address_dict['btcpays'] = get_btcpays(db,
        filters=[{'field': 'source', 'op': '==', 'value': address}, {'field': 'destination', 'op': '==', 'value': address}],
        filterop='or', order_by='block_index',
        order_dir='asc', start_block=start_block, end_block=end_block)
    
    address_dict['issuances'] = get_issuances(db, issuer=address,
        order_by='block_index', order_dir='asc', start_block=start_block, end_block=end_block)
    
    address_dict['broadcasts'] = get_broadcasts(db, source=address,
        order_by='block_index', order_dir='asc', start_block=start_block, end_block=end_block)
    
    address_dict['bets'] = get_bets(db, source=address, order_by='block_index',
        order_dir='asc', start_block=start_block, end_block=end_block)
    
    address_dict['bet_matches'] = get_bet_matches(db, address=address,
        order_by='tx0_block_index', order_dir='asc', start_block=start_block, end_block=end_block)
    
    address_dict['dividends'] = get_dividends(db, source=address, order_by='block_index',
        order_dir='asc', start_block=start_block, end_block=end_block)

    address_dict['cancels'] = get_cancels(db, source=address, order_by='block_index',
        order_dir='asc', start_block=start_block, end_block=end_block)

    address_dict['callbacks'] = get_callbacks(db, source=address, order_by='block_index',
        order_dir='asc', start_block=start_block, end_block=end_block)

    address_dict['bet_expirations'] = get_bet_expirations(db, source=address, order_by='block_index',
        order_dir='asc', start_block=start_block, end_block=end_block)

    address_dict['order_expirations'] = get_order_expirations(db, source=address, order_by='block_index',
        order_dir='asc', start_block=start_block, end_block=end_block)

    address_dict['bet_match_expirations'] = get_bet_match_expirations(db, address=address, order_by='block_index',
        order_dir='asc', start_block=start_block, end_block=end_block)

    address_dict['order_match_expirations'] = get_order_match_expirations(db, address=address, order_by='block_index',
        order_dir='asc', start_block=start_block, end_block=end_block)

    return address_dict
    
# vim: tabstop=8 expandtab shiftwidth=4 softtabstop=4
