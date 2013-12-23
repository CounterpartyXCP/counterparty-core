"""
The functions herein defined are meant to be used internally, and so are passed
all necessary database connexions.

"""
# TODO: move debit, credit and balance into api.py?!
    # TODO: combine get_balances() and balance()?!

from datetime import datetime
from dateutil.tz import tzlocal

from . import (config, bitcoin)

# Obsolete in Python 3.4, with enum module.
ASSET_NAME = {0: 'BTC', 1: 'XCP'}
ASSET_ID = {'BTC': 0, 'XCP': 1}
BET_TYPE_NAME = {0: 'BullCFD', 1: 'BearCFD'}
BET_TYPE_ID = {'BullCFD': 0, 'BearCFD': 1}

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

def balance (cursor, source, asset_id):
    if not asset_id == 0: # If not BTC…
        cursor.execute('''SELECT * FROM balances \
                          WHERE (address=? and asset_id=?)''',
                       (source, asset_id))
        row = cursor.fetchone()
        assert not cursor.fetchone()
        if not row:
            balance = None
        else:
            balance = row['amount']
    else:   # HACK (fragile)
        import subprocess
        # balance = int(subprocess.check_output(['curl','-s', 'http://blockchain.info/q/addressbalance/' + source]))    # mainnet
        balance = 100 * config.UNIT    # *** testnet DOUBLE HACK! ***
    return cursor, balance

def debit (db, cursor, address, asset_id, amount):
    if not asset_id:
        raise exceptions.BalanceError('Cannot debit bitcoins from a Counterparty address!')

    cursor.execute('''SELECT * FROM balances WHERE (address=? and asset_id=?)''',
                   (address, asset_id))
    try:
        old_balance = cursor.fetchone()['amount']
    except TypeError:
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
    db.commit()
    return db, cursor, validity

def credit (db, cursor, address, asset_id, amount):
    cursor, old_balance = balance(cursor, address, asset_id)
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
        cursor.execute('''UPDATE balances SET amount=? \
                          WHERE (address=? and asset_id=?)''',
                       (old_balance + amount, address, asset_id)) 
    db.commit()
    return db, cursor

def good_feed (cursor, address):
    """
    Feed is locked if *any* of its broadcasts lacks a textual message.

    Returns None if no broadcast from address can be found.

    Locks are [necessarily] based on tx_index and not timestamp.
    """
    cursor.execute('''SELECT * FROM broadcasts \
                      WHERE (source=? AND validity=?) \
                      ORDER BY tx_index''', (address, 'Valid'))
    broadcasts = cursor.fetchall()
    if not len(broadcasts): return cursor, None             # Non‐existant
    for broadcast in broadcasts:
        if broadcast['text'] == '': return cursor, False    # Locked
    return cursor, True                                     # Exists and is unlocked

def last_value_of_feed (cursor, feed_address):
    cursor.execute('''SELECT * FROM broadcasts \
                      WHERE (source=? AND validity=?) \
                      ORDER BY tx_index DESC''', (feed_address, 'Valid'))
    return cursor, cursor.fetchone()['value']

# vim: tabstop=8 expandtab shiftwidth=4 softtabstop=4
