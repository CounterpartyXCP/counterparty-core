"""
The functions herein defined are meant to be used by the counterpartyd
internals, and so are passed all necessary database connexions.

"""


from datetime import datetime
from dateutil.tz import tzlocal

from . import config
from . import bitcoin


# Obsolete in Python 3.4.
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

def get_time_left (order):
    """order or bet"""
    # TODO: Inclusive/exclusive expiration?
    block_count = bitcoin.rpc('getblockcount', [])['result']
    return order['block_index'] + order['expiration'] - block_count
def get_deal_time_left (cursor, deal):
    cursor.execute('''SELECT * FROM orders \
                      WHERE (tx_hash=? OR tx_hash=?)''',
                   (deal['tx0_hash'], deal['tx1_hash']))
    return (cursor, min(get_time_left(order) for order in cursor.fetchall()))

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





def get_balances (cursor, address=None, asset_id=None):
    cursor.execute('''SELECT * FROM balances''')
    balances = []
    for balance in cursor.fetchall():
        if address and balance['address'] != address: continue
        if asset_id and balance['asset_id'] != asset_id: continue
        balances.append(balance)
    return cursor, balances

def get_sends (cursor, validity=None, source=None, destination=None):
    cursor.execute('''SELECT * FROM sends''')
    sends = []
    for send in cursor.fetchall():
        if validity and send['Validity'] != validity: continue
        if source and send['source'] != source: continue
        if destination and send['destination'] != destination: continue
        sends.append(send)
    return cursor, sends

def get_orders (cursor, validity=None, address=None, show_empty=True, show_expired=True):
    cursor.execute('''SELECT * FROM orders ORDER BY ask_price ASC, tx_index''')
    block_count = bitcoin.rpc('getblockcount', [])['result']
    orders = []
    for order in cursor.fetchall():
        if validity and order['Validity'] != validity: continue
        if not show_empty and not order['give_remaining']: continue
        if address and order['source'] != address: continue

        # Ignore BTC orders one block early.
        time_left = get_time_left(order)
        if not show_expired and not ((time_left > 0 and order['give_id'] and
                                    order['get_id']) or time_left > 1):
            continue

        orders.append(dict(order))
    return cursor, orders

def get_deals (cursor, validity=None, addresses=[], show_expired=True):
    cursor.execute('''SELECT * FROM deals ORDER BY tx1_index''')
    deals = []
    for deal in cursor.fetchall():
        if validity and deal['validity'] != validity: continue

        if not show_expired:
            cursor, deal_time_left = get_deal_time_left(cursor, deal)
            if deal_time_left <= 0: continue

        if addresses and not ((deal['tx0_address'] in addresses and
                               not deal['forward_id']) or
                              (deal['tx1_address'] in addresses and
                               not deal['backward_id'])):
            continue

        deals.append(dict(deal))
    return cursor, deals

"""
def get_btcpays (cursor, validity=None, address=None):
    cursor.execute('''SELECT * FROM btcpays''')
    btcpays = []
    for btcpay in cursor.fetchall():
        if validity and btcpay['Validity'] != validity: continue
        if address and btcpay['address'] != address: continue
        btcpays.append(btcpay)
    return cursor, btcpays
"""

def get_issuances (cursor, validity=None, asset_id=None, issuer=None):
    cursor.execute('''SELECT * FROM issuances \
                      ORDER BY tx_index ASC''')
    issuances = []
    for issuance in cursor.fetchall():
        if validity and issuance['Validity'] != validity: continue
        if asset_id and issuance['asset_id'] != asset_id: continue
        if issuer and issuance['issuer'] != issuer: continue
        issuances.append(issuance)
    return cursor, issuances

def get_bets (cursor, validity=None, address=None, show_empty=True, show_expired=True):
    cursor.execute('''SELECT * FROM bets ORDER BY odds DESC, tx_index''')
    block_count = bitcoin.rpc('getblockcount', [])['result']
    bets = []
    for bet in cursor.fetchall():
        if validity and bet['Validity'] != validity: continue
        if not show_empty and not bet['wager_remaining']: continue
        if address and bet['source'] != address: continue

        time_left = get_time_left(bet)
        if not show_expired and time_left < 0: continue

        bets.append(dict(bet))
    return cursor, bets

def get_contracts (cursor, validity=None, addresses=[], show_expired=True):
    cursor.execute('''SELECT * FROM contracts ORDER BY tx1_index''')
    contracts = []
    for contract in cursor.fetchall():
        if validity and contract['validity'] != validity: continue

        if not show_expired:
            cursor, contract_time_left = get_contract_time_left(cursor, contract)
            if contract_time_left <= 0: continue

        if addresses and not ((contract['tx0_address'] in addresses and
                               not contract['forward_id']) or
                              (contract['tx1_address'] in addresses and
                               not contract['backward_id'])):
            continue

        contracts.append(dict(contract))
    return cursor, contracts

def get_dividends (cursor, validity=None, address=None, asset_id=None):
    cursor.execute('''SELECT * FROM dividends''')
    dividends = []
    for dividend in cursor.fetchall():
        if validity and dividend['Validity'] != validity: continue
        if address and dividend['address'] != address: continue
        if asset_id and dividend['asset_id'] != asset_id: continue
        dividends.append(dividend)
    return cursor, dividends

def get_burns (cursor, validity=True, address=None):
    cursor.execute('''SELECT * FROM burns''')
    burns = []
    for burn in cursor.fetchall():
        if validity and burn['Validity'] != validity: continue
        if address and burn['address'] != address: continue
        burns.append(burn)
    return cursor, burns

# vim: tabstop=8 expandtab shiftwidth=4 softtabstop=4
