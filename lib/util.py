import time
import decimal
import sys
import json
import logging
import apsw
import collections
import inspect
import requests
from datetime import datetime
from dateutil.tz import tzlocal
from operator import itemgetter
import fractions
import warnings
import binascii
import hashlib

from . import (config, exceptions)

D = decimal.Decimal
b26_digits = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'

json_print = lambda x: print(json.dumps(x, sort_keys=True, indent=4))

# Obsolete in Python 3.4, with enum module.
BET_TYPE_NAME = {0: 'BullCFD', 1: 'BearCFD', 2: 'Equal', 3: 'NotEqual'}
BET_TYPE_ID = {'BullCFD': 0, 'BearCFD': 1, 'Equal': 2, 'NotEqual': 3}

# TODO: This doesn’t timeout properly. (If server hangs, then unhangs, no result.)
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
        raise exceptions.RPCError('Cannot communicate with {} server.'.format(config.XCP_CLIENT))
    elif response.status_code != 200:
        if response.status_code == 500:
            raise exceptions.RPCError('Malformed API call.')
        else:
            raise exceptions.RPCError(str(response.status_code) + ' ' + response.reason)

    response_json = response.json()
    if 'error' not in response_json.keys() or response_json['error'] == None:
        try:
            return response_json['result']
        except KeyError:
            raise exceptions.RPCError(response_json)
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
    cursor = db.cursor()

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
            logging.info('Order: {} ordered {} for {} in {} blocks, with a provided fee of {} {} and a required fee of {} {} ({}) [{}]'.format(bindings['source'], output(bindings['give_quantity'], bindings['give_asset']), output(bindings['get_quantity'], bindings['get_asset']), bindings['expiration'], bindings['fee_provided'] / config.UNIT, config.BTC, bindings['fee_required'] / config.UNIT, config.BTC, bindings['tx_hash'], bindings['status']))

        elif category == 'order_matches':
            logging.info('Order Match: {} for {} ({}) [{}]'.format(output(bindings['forward_quantity'], bindings['forward_asset']), output(bindings['backward_quantity'], bindings['backward_asset']), bindings['id'], bindings['status']))

        elif category == 'btcpays':
            logging.info('{} Payment: {} paid {} to {} for order match {} ({}) [{}]'.format(config.BTC, bindings['source'], output(bindings['btc_amount'], config.BTC), bindings['destination'], bindings['order_match_id'], bindings['tx_hash'], bindings['status']))

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
                except Exception as e:
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
            broadcasts = list(cursor.execute('''SELECT * FROM broadcasts WHERE (status = ? AND source = ?) ORDER BY tx_index ASC''', ('valid', bindings['feed_address'])))
            try:
                last_broadcast = broadcasts[-1]
                text = last_broadcast['text']
            except IndexError:
                text = '<Text>'

            # Suffix
            end = 'in {} blocks ({}) [{}]'.format(bindings['expiration'], bindings['tx_hash'], bindings['status'])

            if 'CFD' not in BET_TYPE_NAME[bindings['bet_type']]:
                log_message = 'Bet: {} against {}, by {}, on {} that ‘{}’ will {} {} at {}, {}'.format(output(bindings['wager_quantity'], config.XCP), output(bindings['counterwager_quantity'], config.XCP), bindings['source'], bindings['feed_address'], text, BET_TYPE_NAME[bindings['bet_type']], str(output(bindings['target_value'], 'value').split(' ')[0]), isodt(bindings['deadline']), end)
            else:
                log_message = 'Bet: {}, by {}, on {} for {} against {}, leveraged {}x, {}'.format(BET_TYPE_NAME[bindings['bet_type']], bindings['source'], bindings['feed_address'],output(bindings['wager_quantity'], config.XCP), output(bindings['counterwager_quantity'], config.XCP), output(bindings['leverage']/ 5040, 'leverage'), end)

            logging.info(log_message)

        elif category == 'bet_matches':
            placeholder = ''
            if bindings['target_value'] >= 0:    # Only non‐negative values are valid.
                placeholder = ' that ' + str(output(bindings['target_value'], 'value'))
            if bindings['leverage']:
                placeholder += ', leveraged {}x'.format(output(bindings['leverage'] / 5040, 'leverage'))
            logging.info('Bet Match: {} for {} against {} for {} on {} at {}{} ({}) [{}]'.format(BET_TYPE_NAME[bindings['tx0_bet_type']], output(bindings['forward_quantity'], config.XCP), BET_TYPE_NAME[bindings['tx1_bet_type']], output(bindings['backward_quantity'], config.XCP), bindings['feed_address'], isodt(bindings['deadline']), placeholder, bindings['id'], bindings['status']))

        elif category == 'dividends':
            logging.info('Dividend: {} paid {} per unit of {} ({}) [{}]'.format(bindings['source'], output(bindings['quantity_per_unit'], bindings['dividend_asset']), bindings['asset'], bindings['tx_hash'], bindings['status']))

        elif category == 'burns':
            logging.info('Burn: {} burned {} for {} ({}) [{}]'.format(bindings['source'], output(bindings['burned'], config.BTC), output(bindings['earned'], config.XCP), bindings['tx_hash'], bindings['status']))

        elif category == 'cancels':
            logging.info('Cancel: {} ({}) [{}]'.format(bindings['offer_hash'], bindings['tx_hash'], bindings['status']))

        elif category == 'callbacks':
            logging.info('Callback: {} called back {}% of {} ({}) [{}]'.format(bindings['source'], float(D(bindings['fraction']) * D(100)), bindings['asset'], bindings['tx_hash'], bindings['status']))

        elif category == 'rps':
            log_message = 'RPS: {} opens game with {} possible moves and a wager of {}'.format(bindings['source'], bindings['possible_moves'], output(bindings['wager'], 'XCP'))
            logging.info(log_message)

        elif category == 'rps_matches':
            log_message = 'RPS Match: {} is playing a {}-moves game with {} with a wager of {} ({}) [{}]'.format(bindings['tx0_address'], bindings['possible_moves'], bindings['tx1_address'], output(bindings['wager'], 'XCP'), bindings['id'], bindings['status'])
            logging.info(log_message)

        elif category == 'rpsresolves':
            
            if bindings['status'] == 'valid':
                rps_matches = list(cursor.execute('''SELECT * FROM rps_matches WHERE id = ?''', (bindings['rps_match_id'],)))
                assert len(rps_matches) == 1
                rps_match = rps_matches[0]
                log_message = 'RPS Resolved: {} is playing {} on a {}-moves game with {} with a wager of {} ({}) [{}]'.format(rps_match['tx0_address'], bindings['move'], rps_match['possible_moves'], rps_match['tx1_address'], output(rps_match['wager'], 'XCP'), rps_match['id'], rps_match['status'])
            else:
                log_message = 'RPS Resolved: {} [{}]'.format(bindings['tx_hash'], bindings['status'])
            logging.info(log_message)

        elif category == 'order_expirations':
            logging.info('Expired order: {}'.format(bindings['order_hash']))

        elif category == 'order_match_expirations':
            logging.info('Expired Order Match awaiting payment: {}'.format(bindings['order_match_id']))

        elif category == 'bet_expirations':
            logging.info('Expired bet: {}'.format(bindings['bet_hash']))

        elif category == 'bet_match_expirations':
            logging.info('Expired Bet Match: {}'.format(bindings['bet_match_id']))

        elif category == 'bet_match_resolutions':
            # DUPE
            cfd_type_id = BET_TYPE_ID['BullCFD'] + BET_TYPE_ID['BearCFD']
            equal_type_id = BET_TYPE_ID['Equal'] + BET_TYPE_ID['NotEqual']

            if bindings['bet_match_type_id'] == cfd_type_id:
                if bindings['settled']:
                    logging.info('Bet Match Settled: {} credited to the bull, {} credited to the bear, and {} credited to the feed address ({})'.format(output(bindings['bull_credit'], config.XCP), output(bindings['bear_credit'], config.XCP), output(bindings['fee'], config.XCP), bindings['bet_match_id']))
                else:
                    logging.info('Bet Match Force‐Liquidated: {} credited to the bull, {} credited to the bear, and {} credited to the feed address ({})'.format(output(bindings['bull_credit'], config.XCP), output(bindings['bear_credit'], config.XCP), output(bindings['fee'], config.XCP), bindings['bet_match_id']))

            elif bindings['bet_match_type_id'] == equal_type_id:
                logging.info('Bet Match Settled: {} won the pot of {}; {} credited to the feed address ({})'.format(bindings['winner'], output(bindings['escrow_less_fee'], config.XCP), output(bindings['fee'], config.XCP), bindings['bet_match_id']))

        elif category == 'rps_expirations':
            logging.info('Expired RPS: {}'.format(bindings['rps_hash']))

        elif category == 'rps_match_expirations':
            logging.info('Expired RPS Match: {}'.format(bindings['rps_match_id']))

        elif category == 'contracts':
            logging.info('New Contract: {} ({})'.format(binascii.hexlify(bindings['code']).decode('ascii'), bindings['tx_hash']))

        elif category == 'executions':
            logging.info('Execution: {} ({}) [{}]'.format(bindings['contract_id'], bindings['tx_hash'], bindings['status']))

    cursor.close()


def message (db, block_index, command, category, bindings, tx_hash=None):
    cursor = db.cursor()

    # Get last message index.
    messages = list(cursor.execute('''SELECT * FROM messages
                                      WHERE message_index = (SELECT MAX(message_index) from messages)'''))
    if messages:
        assert len(messages) == 1
        message_index = messages[0]['message_index'] + 1
    else:
        message_index = 0

    # Not to be misleading…
    if block_index == config.MEMPOOL_BLOCK_INDEX:
        try:
            del bindings['status']
            del bindings['block_index']
            del bindings['tx_index']
        except KeyError:
            pass

    # Handle binary data.
    items = []
    for item in sorted(bindings.items()):
        if type(item[1]) == bytes:
            items.append((item[0], binascii.hexlify(item[1]).decode('ascii')))
        else:
            items.append(item)

    bindings_string = json.dumps(collections.OrderedDict(items))
    cursor.execute('insert into messages values(:message_index, :block_index, :command, :category, :bindings, :timestamp)',
                   (message_index, block_index, command, category, bindings_string, curr_time()))

    # Log only real transactions.
    if block_index != config.MEMPOOL_BLOCK_INDEX:
        log(db, command, category, bindings)

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
    if category not in ('balances', 'messages', 'mempool'):
        if not (command in ('update') and category in ('orders', 'bets', 'rps', 'order_matches', 'bet_matches', 'rps_matches')):    # List message manually.
            message(db, bindings['block_index'], command, category, bindings)

    return True

def connect_to_db(flags=None):
    """Connects to the SQLite database, returning a db Connection object"""
    logging.debug('Status: Creating connection to `{}`.'.format(config.DATABASE.split('/').pop()))

    if flags == None:
        db = apsw.Connection(config.DATABASE)
    elif flags == 'SQLITE_OPEN_READONLY':
        db = apsw.Connection(config.DATABASE, flags=0x00000001)
    else:
        raise exceptions.DatabaseError

    cursor = db.cursor()

    # For speed.
    cursor.execute('''PRAGMA count_changes = OFF''')

    # For integrity, security.
    cursor.execute('''PRAGMA foreign_keys = ON''')
    cursor.execute('''PRAGMA defer_foreign_keys = ON''')

    # So that writers don’t block readers.
    if flags != 'SQLITE_OPEN_READONLY':
        cursor.execute('''PRAGMA journal_mode = WAL''')

    # Make case sensitive the LIKE operator.
    # For insensitive queries use 'UPPER(fieldname) LIKE value.upper()''
    cursor.execute('''PRAGMA case_sensitive_like = ON''')

    rows = list(cursor.execute('''PRAGMA foreign_key_check'''))
    if rows: raise exceptions.DatabaseError('Foreign key check failed.')

    # Integrity check
    integral = False
    for i in range(10): # DUPE
        try:
            logging.debug('Status: Checking database integrity.')
            cursor.execute('''PRAGMA integrity_check''')
            rows = cursor.fetchall()
            if not (len(rows) == 1 and rows[0][0] == 'ok'):
                raise exceptions.DatabaseError('Integrity check failed.')
            integral = True
            break
        except exceptions.DatabaseIntegrityError:
            time.sleep(1)
            continue
    if not integral:
        raise exceptions.DatabaseError('Could not perform integrity check.')

    cursor.close()

    db.setrowtrace(rowtracer)
    db.setexectrace(exectracer)

    return db

def version_check (db):
    try:
        host = 'https://raw2.github.com/CounterpartyXCP/counterpartyd/master/version.json'
        response = requests.get(host, headers={'cache-control': 'no-cache'})
        versions = json.loads(response.text)
    except Exception as e:
        raise exceptions.VersionError('Unable to check version. How’s your Internet access?')

    # Check client version.
    passed = True
    if config.VERSION_MAJOR < versions['minimum_version_major']:
        passed = False
    elif config.VERSION_MAJOR == versions['minimum_version_major']:
        if config.VERSION_MINOR < versions['minimum_version_minor']:
            passed = False
        elif config.VERSION_MINOR == versions['minimum_version_minor']:
            if config.VERSION_REVISION < versions['minimum_version_revision']:
                passed = False

    if not passed:
        explanation = 'Your version of counterpartyd is v{}, but, as of block {}, the minimum version is v{}.{}.{}. Reason: ‘{}’. Please upgrade to the latest version and restart the server.'.format(
            config.VERSION_STRING, versions['block_index'], versions['minimum_version_major'], versions['minimum_version_minor'],
            versions['minimum_version_revision'], versions['reason'])
        if last_block(db)['block_index'] >= versions['block_index']:
            raise exceptions.VersionUpdateRequiredError(explanation)
        else:
            warnings.warn(explanation)

    logging.debug('Status: Version check passed.')
    return

def database_check (db, blockcount):
    """Checks {} database to see if the {} server has caught up with Bitcoind.""".format(config.XCP_NAME, config.XCP_CLIENT)
    if last_block(db)['block_index'] + 1 < blockcount:
        raise exceptions.DatabaseError('{} database is behind Bitcoind. Is the {} server running?'.format(config.XCP_NAME, config.XCP_CLIENT))
    return

def isodt (epoch_time):
    return datetime.fromtimestamp(epoch_time, tzlocal()).isoformat()

def curr_time():
    return int(time.time())

def date_passed(date):
    return date <= time.time()

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

def asset_id (asset):
    # Special cases.
    if asset == config.BTC: return 0
    elif asset == config.XCP: return 1

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

def asset_name (asset_id):
    if asset_id == 0: return config.BTC
    elif asset_id == 1: return config.XCP

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
    assert asset != config.BTC # Never BTC.
    assert type(quantity) == int
    assert quantity >= 0

    if asset == config.BTC:
        raise exceptions.BalanceError('Cannot debit bitcoins from a {} address!'.format(config.XCP_NAME))

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
    assert asset != config.BTC # Never BTC.
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
        assert False
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
        if asset in (config.BTC, config.XCP):
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

def holders(db, asset):
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

    # Bets and RPS (and bet/rps matches) only escrow XCP.
    if asset == config.XCP:
        cursor.execute('''SELECT * FROM bets \
                          WHERE status = ?''', ('open',))
        for bet in list(cursor):
            holders.append({'address': bet['source'], 'address_quantity': bet['wager_remaining'], 'escrow': bet['tx_hash']})
        cursor.execute('''SELECT * FROM bet_matches \
                          WHERE status = ?''', ('pending',))
        for bet_match in list(cursor):
            holders.append({'address': bet_match['tx0_address'], 'address_quantity': bet_match['forward_quantity'], 'escrow': bet_match['id']})
            holders.append({'address': bet_match['tx1_address'], 'address_quantity': bet_match['backward_quantity'], 'escrow': bet_match['id']})

        cursor.execute('''SELECT * FROM rps \
                          WHERE status = ?''', ('open',))
        for rps in list(cursor):
            holders.append({'address': rps['source'], 'address_quantity': rps['wager'], 'escrow': rps['tx_hash']})
        cursor.execute('''SELECT * FROM rps_matches \
                          WHERE status IN (?, ?, ?)''', ('pending', 'pending and resolved', 'resolved and pending'))
        for rps_match in list(cursor):
            holders.append({'address': rps_match['tx0_address'], 'address_quantity': rps_match['wager'], 'escrow': rps_match['id']})
            holders.append({'address': rps_match['tx1_address'], 'address_quantity': rps_match['wager'], 'escrow': rps_match['id']})

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

def supplies (db):
    cursor = db.cursor()
    supplies = {config.XCP: xcp_supply(db)}
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

def get_url(url, abort_on_error=False, is_json=True, fetch_timeout=5):
    try:
        r = requests.get(url, timeout=fetch_timeout)
    except Exception as e:
        raise GetURLError("Got get_url request error: %s" % e)
    else:
        if r.status_code != 200 and abort_on_error:
            raise GetURLError("Bad status code returned: '%s'. result body: '%s'." % (r.status_code, r.text))
        result = json.loads(r.text) if is_json else r.text
    return result

def dhash_string(text):
    return binascii.hexlify(hashlib.sha256(hashlib.sha256(bytes(text, 'utf-8')).digest()).digest()).decode()

# vim: tabstop=8 expandtab shiftwidth=4 softtabstop=4
