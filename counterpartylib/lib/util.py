import time
import decimal
import sys
import json
import logging
logger = logging.getLogger(__name__)
import apsw
import inspect
import requests
from datetime import datetime
from dateutil.tz import tzlocal
from operator import itemgetter
import fractions
import warnings
import binascii
import hashlib
import sha3
import bitcoin as bitcoinlib
import os
import collections
import threading

from counterpartylib.lib import exceptions
from counterpartylib.lib.exceptions import DecodeError
from counterpartylib.lib import config

D = decimal.Decimal
b26_digits = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'

# Obsolete in Python 3.4, with enum module.
BET_TYPE_NAME = {0: 'BullCFD', 1: 'BearCFD', 2: 'Equal', 3: 'NotEqual'}
BET_TYPE_ID = {'BullCFD': 0, 'BearCFD': 1, 'Equal': 2, 'NotEqual': 3}

dhash = lambda x: hashlib.sha256(hashlib.sha256(x).digest()).digest()

json_print = lambda x: print(json.dumps(x, sort_keys=True, indent=4))

BLOCK_LEDGER = []

CURR_DIR = os.path.dirname(os.path.realpath(__file__))
with open(CURR_DIR + '/../protocol_changes.json') as f:
    PROTOCOL_CHANGES = json.load(f)

class RPCError (Exception): pass

# TODO: Move to `util_test.py`.
# TODO: This doesn’t timeout properly. (If server hangs, then unhangs, no result.)
def api(method, params):
    """Poll API via JSON-RPC."""
    headers = {'content-type': 'application/json'}
    payload = {
        "method": method,
        "params": params,
        "jsonrpc": "2.0",
        "id": 0,
    }
    response = requests.post(config.RPC, data=json.dumps(payload), headers=headers)
    if response == None:
        raise RPCError('Cannot communicate with {} server.'.format(config.XCP_NAME))
    elif response.status_code != 200:
        if response.status_code == 500:
            raise RPCError('Malformed API call.')
        else:
            raise RPCError(str(response.status_code) + ' ' + response.reason)

    response_json = response.json()
    if 'error' not in response_json.keys() or response_json['error'] == None:
        try:
            return response_json['result']
        except KeyError:
            raise RPCError(response_json)
    else:
        raise RPCError('{}'.format(response_json['error']))

def chunkify(l, n):
    n = max(1, n)
    return [l[i:i + n] for i in range(0, len(l), n)]

def date_passed(date):
    """Check if the date has already passed."""
    return date <= int(time.time())

def price (numerator, denominator):
    """Return price as Fraction or Decimal."""
    if CURRENT_BLOCK_INDEX >= 294500 or config.TESTNET: # Protocol change.
        return fractions.Fraction(numerator, denominator)
    else:
        numerator = D(numerator)
        denominator = D(denominator)
        return D(numerator / denominator)

def last_message(db):
    """Return latest message from the db."""
    cursor = db.cursor()
    messages = list(cursor.execute('''SELECT * FROM messages WHERE message_index = (SELECT MAX(message_index) from messages)'''))
    if messages:
        assert len(messages) == 1
        last_message = messages[0]
    else:
        raise exceptions.DatabaseError('No messages found.')
    cursor.close()
    return last_message

def generate_asset_id(asset_name, block_index):
    """Create asset_id from asset_name."""
    if asset_name == config.BTC: return 0
    elif asset_name == config.XCP: return 1

    if len(asset_name) < 4:
        raise exceptions.AssetNameError('too short')

    # Numeric asset names.
    if enabled('numeric_asset_names'):  # Protocol change.
        if asset_name[0] == 'A':
            # Must be numeric.
            try:
                asset_id = int(asset_name[1:])
            except ValueError:
                raise exceptions.AssetNameError('non‐numeric asset name starts with ‘A’')

            # Number must be in range.
            if not (26**12 + 1 <= asset_id <= 2**64 - 1):
                raise exceptions.AssetNameError('numeric asset name not in range')

            return asset_id
        elif len(asset_name) >= 13:
            raise exceptions.AssetNameError('long asset names must be numeric')

    if asset_name[0] == 'A': raise exceptions.AssetNameError('non‐numeric asset name starts with ‘A’')

    # Convert the Base 26 string to an integer.
    n = 0
    for c in asset_name:
        n *= 26
        if c not in b26_digits:
            raise exceptions.AssetNameError('invalid character:', c)
        digit = b26_digits.index(c)
        n += digit
    asset_id = n

    if asset_id < 26**3:
        raise exceptions.AssetNameError('too short')

    return asset_id

def generate_asset_name (asset_id, block_index):
    """Create asset_name from asset_id."""
    if asset_id == 0: return config.BTC
    elif asset_id == 1: return config.XCP

    if asset_id < 26**3:
        raise exceptions.AssetIDError('too low')

    if enabled('numeric_asset_names'):  # Protocol change.
        if asset_id <= 2**64 - 1:
            if 26**12 + 1 <= asset_id:
                asset_name = 'A' + str(asset_id)
                return asset_name
        else:
            raise exceptions.AssetIDError('too high')

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


def get_asset_id (db, asset_name, block_index):
    """Return asset_id from asset_name."""
    if not enabled('hotfix_numeric_assets'):
        return generate_asset_id(asset_name, block_index)
    cursor = db.cursor()
    cursor.execute('''SELECT * FROM assets WHERE asset_name = ?''', (asset_name,))
    assets = list(cursor)
    if len(assets) == 1:
        return int(assets[0]['asset_id'])
    else:
        raise exceptions.AssetError('No such asset: {}'.format(asset_name))

def get_asset_name (db, asset_id, block_index):
    """Return asset_name from asset_id."""
    if not enabled('hotfix_numeric_assets'):
        return generate_asset_name(asset_id, block_index)
    cursor = db.cursor()
    cursor.execute('''SELECT * FROM assets WHERE asset_id = ?''', (str(asset_id),))
    assets = list(cursor)
    if len(assets) == 1:
        return assets[0]['asset_name']
    elif not assets:
        return 0    # Strange, I know…


class DebitError (Exception): pass
def debit (db, address, asset, quantity, action=None, event=None):
    """Debit given address by quantity of asset."""
    block_index = CURRENT_BLOCK_INDEX

    if type(quantity) != int:
        raise DebitError('Quantity must be an integer.')
    if quantity < 0:
        raise DebitError('Negative quantity.')
    if asset == config.BTC:
        raise DebitError('Cannot debit bitcoins.')

    debit_cursor = db.cursor()

    # Contracts can only hold XCP balances.
    if enabled('contracts_only_xcp_balances'): # Protocol change.
        if len(address) == 40:
            assert asset == config.XCP

    if asset == config.BTC:
        raise exceptions.BalanceError('Cannot debit bitcoins from a {} address!'.format(config.XCP_NAME))

    debit_cursor.execute('''SELECT * FROM balances \
                            WHERE (address = ? AND asset = ?)''', (address, asset))
    balances = debit_cursor.fetchall()
    if not len(balances) == 1: old_balance = 0
    else: old_balance = balances[0]['quantity']

    if old_balance < quantity:
        raise DebitError('Insufficient funds.')

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

    BLOCK_LEDGER.append('{}{}{}{}'.format(block_index, address, asset, quantity))

class CreditError (Exception): pass
def credit (db, address, asset, quantity, action=None, event=None):
    """Credit given address by quantity of asset."""
    block_index = CURRENT_BLOCK_INDEX

    if type(quantity) != int:
        raise CreditError('Quantity must be an integer.')
    if quantity < 0:
        raise CreditError('Negative quantity.')
    if asset == config.BTC:
        raise CreditError('Cannot debit bitcoins.')

    credit_cursor = db.cursor()

    # Contracts can only hold XCP balances.
    if enabled('contracts_only_xcp_balances'): # Protocol change.
        if len(address) == 40:
            assert asset == config.XCP

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

    BLOCK_LEDGER.append('{}{}{}{}'.format(block_index, address, asset, quantity))

class QuantityError(Exception): pass

def is_divisible(db, asset):
    """Check if the asset is divisible."""
    if asset in (config.BTC, config.XCP):
        return True
    else:
        cursor = db.cursor()
        cursor.execute('''SELECT * FROM issuances \
                          WHERE (status = ? AND asset = ?)''', ('valid', asset))
        issuances = cursor.fetchall()
        if not issuances: raise exceptions.AssetError('No such asset: {}'.format(asset))
        return issuances[0]['divisible']

def value_input(quantity, asset, divisible):
    if asset == 'leverage':
        return round(quantity)

    if asset in ('value', 'fraction', 'price', 'odds'):
        return float(quantity)  # TODO: Float?!

    if divisible:
        quantity = D(quantity) * config.UNIT
        if quantity == quantity.to_integral():
            return int(quantity)
        else:
            raise QuantityError('Divisible assets have only eight decimal places of precision.')
    else:
        quantity = D(quantity)
        if quantity != round(quantity):
            raise QuantityError('Fractional quantities of indivisible assets.')
        return round(quantity)

def value_in(db, quantity, asset, divisible=None):
    if asset not in ['leverage', 'value', 'fraction', 'price', 'odds'] and divisible == None:
        divisible = is_divisible(db, asset)
    return value_input(quantity, asset, divisible)

def value_output(quantity, asset, divisible):

    def norm(num, places):
        """Round only if necessary."""
        num = round(num, places)
        fmt = '{:.' + str(places) + 'f}'
        num = fmt.format(num)
        return num.rstrip('0')+'0' if num.rstrip('0')[-1] == '.' else num.rstrip('0')

    if asset == 'fraction':
        return str(norm(D(quantity) * D(100), 6)) + '%'

    if asset in ('leverage', 'value', 'price', 'odds'):
        return norm(quantity, 6)

    if divisible:
        quantity = D(quantity) / D(config.UNIT)
        if quantity == quantity.to_integral():
            return str(quantity) + '.0'  # For divisible assets, display the decimal point.
        else:
            return norm(quantity, 8)
    else:
        quantity = D(quantity)
        if quantity != round(quantity):
            raise QuantityError('Fractional quantities of indivisible assets.')
        return round(quantity)

def value_out(db, quantity, asset, divisible=None):
    if asset not in ['leverage', 'value', 'fraction', 'price', 'odds'] and divisible == None:
        divisible = is_divisible(db, asset)
    return value_output(quantity, asset, divisible)

### SUPPLIES ###

def holders(db, asset):
    """Return holders of the asset."""
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

        cursor.execute('''SELECT * FROM executions WHERE status IN (?,?)''', ('valid','out of gas'))
        for execution in list(cursor):
            holders.append({'address': execution['source'], 'address_quantity': execution['gas_cost'], 'escrow': None})

        # XCP escrowed for not finished executions
        cursor.execute('''SELECT * FROM executions WHERE status = ?''', ('out of gas',))
        for execution in list(cursor):
            holders.append({'address': execution['source'], 'address_quantity': execution['gas_remained'], 'escrow': execution['contract_id']})

    cursor.close()
    return holders

def xcp_created (db):
    """Return number of XCP created thus far."""
    cursor = db.cursor()
    cursor.execute('''SELECT SUM(earned) AS total FROM burns \
                      WHERE (status = ?)''', ('valid',))
    total = list(cursor)[0]['total'] or 0
    cursor.close()
    return total

def xcp_destroyed (db):
    """Return number of XCP destroyed thus far."""
    cursor = db.cursor()
    # Destructions
    cursor.execute('''SELECT SUM(quantity) AS total FROM destructions \
                      WHERE (status = ? AND asset = ?)''', ('valid', config.XCP))
    destroyed_total = list(cursor)[0]['total'] or 0
    # Subtract issuance fees.
    cursor.execute('''SELECT SUM(fee_paid) AS total FROM issuances\
                      WHERE status = ?''', ('valid',))
    issuance_fee_total = list(cursor)[0]['total'] or 0
    # Subtract dividend fees.
    cursor.execute('''SELECT SUM(fee_paid) AS total FROM dividends\
                      WHERE status = ?''', ('valid',))
    dividend_fee_total = list(cursor)[0]['total'] or 0
    cursor.close()
    return destroyed_total + issuance_fee_total + dividend_fee_total

def xcp_supply (db):
    """Return the XCP supply."""
    return xcp_created(db) - xcp_destroyed(db)

def creations (db):
    """Return creations."""
    cursor = db.cursor()
    creations = {config.XCP: xcp_created(db)}
    cursor.execute('''SELECT asset, SUM(quantity) AS created FROM issuances \
                      WHERE status = ? GROUP BY asset''', ('valid',))

    for issuance in cursor:
        asset = issuance['asset']
        created = issuance['created']
        creations[asset] = created            

    cursor.close()
    return creations

def destructions (db):
    """Return destructions."""
    cursor = db.cursor()
    destructions = {config.XCP: xcp_destroyed(db)}
    cursor.execute('''SELECT asset, SUM(quantity) AS destroyed FROM destructions \
                      WHERE (status = ? AND asset != ?) GROUP BY asset''', ('valid', config.XCP))

    for destruction in cursor:
        asset = destruction['asset']
        destroyed = destruction['destroyed']
        destructions[asset] = destroyed

    cursor.close()
    return destructions

def asset_supply (db, asset):
    """Return asset supply."""
    supply = creations(db)[asset]
    destroyed = destructions(db)
    if asset in destroyed:
        supply -= destroyed[asset]
    return supply

def supplies (db):
    """Return supplies."""
    d1 = creations(db)
    d2 = destructions(db)
    return {key: d1[key] - d2.get(key, 0) for key in d1.keys()}

def held (db): #TODO: Rename ?
    sql = '''SELECT asset, SUM(total) AS total FROM (
                SELECT asset, SUM(quantity) AS total FROM balances GROUP BY asset 
                UNION ALL
                SELECT give_asset AS asset, SUM(give_remaining) AS total FROM orders WHERE status = 'open' GROUP BY asset
                UNION ALL
                SELECT forward_asset AS asset, SUM(forward_quantity) AS total FROM order_matches WHERE status = 'pending' GROUP BY asset
                UNION ALL
                SELECT backward_asset AS asset, SUM(backward_quantity) AS total FROM order_matches WHERE status = 'pending' GROUP BY asset
                UNION ALL
                SELECT 'XCP' AS asset, SUM(wager_remaining) AS total FROM bets WHERE status = 'open'
                UNION ALL
                SELECT 'XCP' AS asset, SUM(forward_quantity) AS total FROM bet_matches WHERE status = 'pending'
                UNION ALL
                SELECT 'XCP' AS asset, SUM(backward_quantity) AS total FROM bet_matches WHERE status = 'pending'
                UNION ALL
                SELECT 'XCP' AS asset, SUM(wager) AS total FROM rps WHERE status = 'open'
                UNION ALL
                SELECT 'XCP' AS asset, SUM(wager * 2) AS total FROM rps_matches WHERE status IN ('pending', 'pending and resolved', 'resolved and pending')
                UNION ALL
                SELECT 'XCP' AS asset, SUM(gas_cost) AS total FROM executions WHERE status IN ('valid', 'out of gas')
                UNION ALL
                SELECT 'XCP' AS asset, SUM(gas_remained) AS total FROM executions WHERE status  = 'out of gas'
            ) GROUP BY asset;'''

    cursor = db.cursor()
    cursor.execute(sql)
    held = {}
    for row in cursor:
        asset = row['asset']
        total = row['total']
        held[asset] = total

    return held

### SUPPLIES ###


class GetURLError (Exception): pass
def get_url(url, abort_on_error=False, is_json=True, fetch_timeout=5):
    """Fetch URL using requests.get."""
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

def get_balance (db, address, asset):
    """Get balance of contract or address."""
    cursor = db.cursor()
    balances = list(cursor.execute('''SELECT * FROM balances WHERE (address = ? AND asset = ?)''', (address, asset)))
    cursor.close()
    if not balances: return 0
    else: return balances[0]['quantity']

# Why on Earth does `binascii.hexlify()` return bytes?!
def hexlify(x):
    """Return the hexadecimal representation of the binary data. Decode from ASCII to UTF-8."""
    return binascii.hexlify(x).decode('ascii')
def unhexlify(hex_string):
    return binascii.unhexlify(bytes(hex_string, 'utf-8'))

### Protocol Changes ###
def enabled(change_name, block_index=None):
    """Return True if protocol change is enabled."""
    enable_block_index = PROTOCOL_CHANGES[change_name]['block_index']

    if not block_index:
        block_index = CURRENT_BLOCK_INDEX

    if config.TESTNET: 
        return True     # Protocol changes are always retroactive on testnet.
    else:
        if block_index >= enable_block_index:
            return True
        else:
            return False
    assert False

def transfer(db, source, destination, asset, quantity, action, event):
    """Transfer quantity of asset from source to destination."""
    debit(db, source, asset, quantity, action=action, event=event)
    credit(db, destination, asset, quantity, action=action, event=event)

ID_SEPARATOR = '_'
def make_id(hash_1, hash_2):
    return hash_1 + ID_SEPARATOR + hash_2
def parse_id(match_id):
    assert match_id[64] == ID_SEPARATOR
    return match_id[:64], match_id[65:] # UTF-8 encoding means that the indices are doubled.

class DictCache: 
    """Threadsafe FIFO dict cache"""
    def __init__(self, size=100):  
        if int(size) < 1 :  
            raise AttributeError('size < 1 or not a number')  
        self.size = size  
        self.dict = collections.OrderedDict()  
        self.lock = threading.Lock()  
  
    def __getitem__(self,key):  
        with self.lock:  
            return self.dict[key]  
  
    def __setitem__(self,key,value):  
        with self.lock:  
            while len(self.dict) >= self.size:  
                self.dict.popitem(last=False)  
            self.dict[key] = value  
  
    def __delitem__(self,key):  
        with self.lock:  
            del self.dict[key]

    def __len__(self):
        with self.lock:
            return len(self.dict)
            
    def __contains__(self, key):
        with self.lock: 
            return key in self.dict
    
    def refresh(self, key):
        with self.lock:
            self.dict.move_to_end(key, last=True)

# vim: tabstop=8 expandtab shiftwidth=4 softtabstop=4
