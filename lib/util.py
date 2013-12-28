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

def get_time_left (unmatched, block_index=None):
    """order or bet"""
    """zero time left means it expires *this* block; that is, expire when strictly less than 0"""
    if not block_index: block_index = bitcoin.rpc('getblockcount', [])['result']
    return unmatched['block_index'] + unmatched['expiration'] - block_index
def get_order_match_time_left (matched, block_index=None):
    """order_match or bet_match"""
    if not block_index: block_index = bitcoin.rpc('getblockcount', [])['result']
    tx0_time_left = matched['tx0_block_index'] + matched['tx0_expiration'] - block_index
    tx1_time_left = matched['tx1_block_index'] + matched['tx1_expiration'] - block_index
    return min(tx0_time_left, tx1_time_left)

def get_asset_id (asset):
    """Always returns ID"""
    try: return ASSET_ID[asset]
    except: return int(asset)
def get_asset_name (asset_id):
    """Returns ID if no name was found"""
    try: return ASSET_NAME[asset_id]
    except Exception: return str(asset_id)

def debit (db, address, asset_id, amount):
    debit_cursor = db.cursor()
    assert asset_id != 0 # Never BTC.
    assert type(amount) == int
    from lib import api # TODO
    if not asset_id:
        raise exceptions.BalanceError('Cannot debit bitcoins from a Counterparty address!')
    balances = api.get_balances(db, address=address, asset_id=asset_id)
    if not len(balances) == 1:
        old_balance = 0
    else:
        old_balance = balances[0]['amount']
        assert type(old_balance) == int

    if old_balance >= amount:
        debit_cursor.execute('''UPDATE balances \
                          SET amount=? \
                          WHERE (address=? and asset_id=?)''',
                       (int(old_balance - amount), address, asset_id)) 
        validity = 'Valid'
    else:
        validity = 'Invalid: insufficient funds'

    # Record debit.
    debit_cursor.execute('''INSERT INTO debits(
                        address,
                        asset_id,
                        amount) VALUES(?,?,?)''',
                        (address,
                        asset_id,
                        amount)
                  )
    debit_cursor.close()
    return validity

def credit (db, address, asset_id, amount):
    credit_cursor = db.cursor()
    assert asset_id != 0 # Never BTC.
    assert type(amount) == int
    from lib import api # TODO

    balances = api.get_balances(db, address=address, asset_id=asset_id)
    if len(balances) != 1:
        assert balances == []
        credit_cursor.execute('''INSERT INTO balances(
                            address,
                            asset_id,
                            amount) VALUES(?,?,?)''',
                            (address,
                            asset_id,
                            amount)
                      )
    else:
        old_balance = balances[0]['amount']
        assert type(old_balance) == int
        credit_cursor.execute('''UPDATE balances SET amount=? \
                          WHERE (address=? and asset_id=?)''',
                       (old_balance + amount, address, asset_id)) 

    # Record credit.
    credit_cursor.execute('''INSERT INTO credits(
                        address,
                        asset_id,
                        amount) VALUES(?,?,?)''',
                        (address,
                        asset_id,
                        amount)
                  )
    credit_cursor.close()

def good_feed (db, feed_address):
    """
    Feed is locked if *any* of its broadcasts lacks a textual message.

    Returns None if no broadcast from address can be found.

    Locks are [necessarily] based on tx_index and not timestamp.
    """
    from lib import api # TODO
    broadcasts = api.get_broadcasts(db, validity='Valid', source=feed_address, order_by='tx_index ASC')
    if not len(broadcasts): return None             # Non‐existant
    for broadcast in broadcasts:
        if broadcast['text'] == '': return False    # Locked
    return True                                     # Exists and is unlocked

def devise (db, quantity, asset_id, dest):
    from lib import api # TODO
    import decimal
    D = decimal.Decimal

    issuances = api.get_issuances(db, validity='Valid', asset_id=asset_id)
    if issuances and issuances[0]['divisible']:
        if dest == 'output':
            quantity = D(quantity) / config.UNIT
            return quantity.quantize(config.EIGHT).normalize()
        else:
            return D(quantity) * config.UNIT
    else:
        return D(quantity)

# vim: tabstop=8 expandtab shiftwidth=4 softtabstop=4
