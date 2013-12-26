"""
The functions herein defined are meant to be used internally, and so are passed
all necessary database connexions.

"""

from datetime import datetime
from dateutil.tz import tzlocal

from . import (config, bitcoin)

# Obsolete in Python 3.4, with enum module.
ASSET_NAME = {0: 'BTC', 1: 'XCP'}
ASSET_ID = {'BTC': 0, 'XCP': 1}
BET_TYPE_NAME = {0: 'BullCFD', 1: 'BearCFD', 2: 'Equal', 3: 'NotEqual'}
BET_TYPE_ID = {'BullCFD': 0, 'BearCFD': 1, 'Equal': 2, 'NotEqual': 3}

def short (string):
    if len(string) == 64: length = 8
    elif len(string) == 128: length = 16
    short = string[:length] + '…' + string[-length:]
    return short

def isodt (epoch_time):
    return datetime.fromtimestamp(epoch_time, tzlocal()).isoformat()

def get_time_left (unmatched):
    """order or bet"""
    # TODO: Inclusive/exclusive expiration?
    block_count = bitcoin.rpc('getblockcount', [])['result']
    return unmatched['block_index'] + unmatched['expiration'] - block_count
def get_order_match_time_left (matched):
    """order_match or bet_match"""
    # TODO: Inclusive/exclusive expiration?
    block_count = bitcoin.rpc('getblockcount', [])['result']
    tx0_time_left = matched['tx0_block_index'] + matched['tx0_expiration'] - block_count
    tx1_time_left = matched['tx1_block_index'] + matched['tx1_expiration'] - block_count
    return min(tx0_time_left, tx1_time_left)

def get_asset_id (asset):
    """Always returns ID"""
    try: return ASSET_ID[asset]
    except: return int(asset)
def get_asset_name (asset_id):
    """Returns ID if no name was found"""
    try: return ASSET_NAME[asset_id]
    except Exception: return str(asset_id)

def debit (db, cursor, address, asset_id, amount):
    from lib import api #
    if not asset_id:
        raise exceptions.BalanceError('Cannot debit bitcoins from a Counterparty address!')
    try:
        old_balance = api.get_balances(address=address, asset_id=asset_id)[0]['amount']
    except IndexError:
        old_balance = 0
    finally:
        assert not cursor.fetchone()
        if old_balance >= amount:
            cursor.execute('''UPDATE balances \
                              SET amount=? \
                              WHERE (address=? and asset_id=?)''',
                           (int(old_balance - amount), address, asset_id)) 
            validity = 'Valid'
        else:
            validity = 'Invalid: insufficient funds'
    return cursor, validity

def credit (db, cursor, address, asset_id, amount):
    from lib import api #
    try:
        old_balance = api.get_balances(address=address, asset_id=asset_id)[0]['amount']
    except IndexError:
        cursor.execute('''INSERT INTO balances(
                            address,
                            asset_id,
                            amount) VALUES(?,?,?)''',
                            (address,
                            asset_id,
                            amount)
                      )
    else:
        cursor.execute('''UPDATE balances SET amount=? \
                          WHERE (address=? and asset_id=?)''',
                       (old_balance + amount, address, asset_id)) 
    return cursor

def good_feed (cursor, feed_address):
    """
    Feed is locked if *any* of its broadcasts lacks a textual message.

    Returns None if no broadcast from address can be found.

    Locks are [necessarily] based on tx_index and not timestamp.
    """
    from lib import api #
    broadcasts = api.get_broadcasts(validity='Valid', source=feed_address)
    if not len(broadcasts): return cursor, None             # Non‐existant
    for broadcast in broadcasts:
        if broadcast['text'] == '': return cursor, False    # Locked
    return cursor, True                                     # Exists and is unlocked

def devise (quantity, asset_id, dest):
    from lib import api #
    import decimal
    D = decimal.Decimal

    issuances = api.get_issuances(validity='Valid', asset_id=asset_id)
    if issuances and issuances[0]['divisible']:
        if dest == 'output':
            quantity = D(quantity) / config.UNIT
            return quantity.quantize(config.EIGHT).normalize()
        else:
            return D(quantity) * config.UNIT
    else:
        return D(quantity)

# vim: tabstop=8 expandtab shiftwidth=4 softtabstop=4
