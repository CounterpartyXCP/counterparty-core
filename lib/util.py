import sqlite3
from . import config

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
        return config.ASSET_ID[asset_name]
    except Exception:   #
        return int(asset_name)

# TEMP
def get_asset_name (asset_id):
    """Make take name, too."""
    try:
        return config.ASSET_NAME[asset_id]
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
        
def is_locked (address):
    """ Returns None if no broadcast from address can be found. """
    # NOTE: [necessarily] locks based on tx_index and not timestamp
    db = sqlite3.connect(config.LEDGER)
    db.row_factory = sqlite3.Row
    cursor = db.cursor()
    cursor.execute('''SELECT * FROM broadcasts \
                      WHERE (source=? AND text=? AND validity=?) \
                      ORDER BY tx_index''', ('', address, 'Valid'))
    broadcast = cursor.fetchone()
    assert not cursor.fetchone()
    cursor.close()
    if broadcast: return True
    else: return False

def total_burned (address):
    db = sqlite3.connect(config.LEDGER)
    db.row_factory = sqlite3.Row
    cursor = db.cursor()

    cursor.execute('''SELECT * FROM burns WHERE (address=? AND validity=?)''', (address, 'Valid'))
    return sum([burn['quantity'] for burn in cursor.fetchall()])
        

# vim: tabstop=8 expandtab shiftwidth=4 softtabstop=4
