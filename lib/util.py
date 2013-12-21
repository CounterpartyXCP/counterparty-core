import sqlite3
from datetime import datetime
from dateutil.tz import tzlocal

from . import config


def short (string, strip=False):
    if len(string) == 64:
        length = 8
    elif len(string) == 128:
        length = 16
    short = string[:length] + '…' + string[-length:]
    if strip:
        return short
    else:
        return '(' + short + ')'

def isodt (epoch_time):
    return datetime.fromtimestamp(epoch_time, tzlocal()).isoformat()

# Obsolete in Python 3.4.
ASSET_NAME = {0: 'BTC', 1: 'XCP'}
ASSET_ID = {'BTC': 0, 'XCP': 1}
BET_TYPE_NAME = {0: 'BullCFD', 1: 'BearCFD'}
BET_TYPE_ID = {'BullCFD': 0, 'BearCFD': 1}

def find_all (share_id):
    """
    Find every address that holds some of ASSET_ID, and return that address,
    with the amount of it that held.
    """
    db = sqlite3.connect(config.LEDGER)
    db.row_factory = sqlite3.Row
    cursor = db.cursor()
    cursor.execute('''SELECT * FROM balances WHERE (asset_id=?)''', (share_id,))
    for balance in cursor.fetchall():
        yield (balance['address'], balance['amount'])
    

# TEMP
def get_asset_id (asset_name):
    """Make take id, too."""
    try:
        return ASSET_ID[asset_name]
    except Exception:   #
        return int(asset_name)

# TEMP
def get_asset_name (asset_id):
    """Make take name, too."""
    try:
        return ASSET_NAME[asset_id]
    except Exception:   #
        return str(asset_id)

def total_shares (share_id):
    """Get total number of shares."""
    db = sqlite3.connect(config.LEDGER)
    db.row_factory = sqlite3.Row
    cursor = db.cursor()
    cursor.execute('''SELECT * FROM issuances WHERE (asset_id=? AND validity=?)''', (share_id, 'Valid'))
    total_shares = 0
    for issuance in cursor.fetchall():
        total_shares += issuance['amount']
    return total_shares

def balance (source, asset_id):
    db = sqlite3.connect(config.LEDGER)
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
        balance = 100 * config.UNIT    # *** testnet DOUBLE HACK! ***
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

def is_divisible (asset_id):
    db = sqlite3.connect(config.LEDGER)
    db.row_factory = sqlite3.Row
    cursor = db.cursor()
    cursor.execute('''SELECT * FROM issuances \
                      WHERE (asset_id=? AND validity=?)''', (asset_id, 'Valid'))
    asset = cursor.fetchone()
    cursor.close()
    return asset['divisible']
        
def good_feed (address):
    """
    Feed is locked if *any* of its broadcasts lacks a textual message.

    Returns None if no broadcast from address can be found.

    Locks are [necessarily] based on tx_index and not timestamp.
    """
    db = sqlite3.connect(config.LEDGER)
    db.row_factory = sqlite3.Row
    cursor = db.cursor()
    cursor.execute('''SELECT * FROM broadcasts \
                      WHERE (source=? AND validity=?) \
                      ORDER BY tx_index''', (address, 'Valid'))
    broadcasts = cursor.fetchall()
    if not len(broadcasts):
        cursor.close()
        return None                     # Non‐existant
    for broadcast in broadcasts:
        if broadcast['text'] == '':
            cursor.close()
            return False                # Locked
    cursor.close()
    return True                         # Good feed

def total_burned (address):
    db = sqlite3.connect(config.LEDGER)
    db.row_factory = sqlite3.Row
    cursor = db.cursor()

    cursor.execute('''SELECT * FROM burns WHERE (address=? AND validity=?)''', (address, 'Valid'))
    return sum([burn['quantity'] for burn in cursor.fetchall()])
        
def last_value (feed_address):
    db = sqlite3.connect(config.LEDGER)
    db.row_factory = sqlite3.Row
    cursor = db.cursor()
    cursor.execute('''SELECT * FROM broadcasts \
                      WHERE (source=? AND validity=?) \
                      ORDER BY tx_index DESC''', (feed_address, 'Valid'))
    broadcast = cursor.fetchone()
    cursor.close()
    return broadcast['value']

# vim: tabstop=8 expandtab shiftwidth=4 softtabstop=4
