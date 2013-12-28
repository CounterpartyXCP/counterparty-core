#! /usr/bin/python3

import sqlite3
import json

from lib import (config, exceptions, util, bitcoin)

def get_debits (address=None, asset_id=None):
    """This does not include BTC."""
    db = sqlite3.connect(config.DATABASE)
    db.row_factory = sqlite3.Row
    cursor = db.cursor()

    cursor.execute('''SELECT * FROM debits''')
    debits = []
    for debit in cursor.fetchall():
        if address and debit['address'] != address: continue
        if asset_id != None and debit['asset_id'] != asset_id: continue
        debits.append(dict(debit))
    cursor.close()
    return debits

def get_credits (address=None, asset_id=None):
    """This does not include BTC."""
    db = sqlite3.connect(config.DATABASE)
    db.row_factory = sqlite3.Row
    cursor = db.cursor()

    cursor.execute('''SELECT * FROM credits''')
    credits = []
    for credit in cursor.fetchall():
        if address and credit['address'] != address: continue
        if asset_id != None and credit['asset_id'] != asset_id: continue
        credits.append(dict(credit))
    cursor.close()
    return credits

def get_balances (address=None, asset_id=None):
    """This should never be used to check Bitcoin balances."""
    db = sqlite3.connect(config.DATABASE)
    db.row_factory = sqlite3.Row
    cursor = db.cursor()

    cursor.execute('''SELECT * FROM balances''')
    balances = []
    for balance in cursor.fetchall():
        if address and balance['address'] != address: continue
        if asset_id != None and balance['asset_id'] != asset_id: continue
        if asset_id == 0: raise Exception
        balances.append(dict(balance))
    cursor.close()
    return balances

def get_sends (validity=None, source=None, destination=None):
    db = sqlite3.connect(config.DATABASE)
    db.row_factory = sqlite3.Row
    cursor = db.cursor()

    cursor.execute('''SELECT * FROM sends ORDER BY tx_index''')
    sends = []
    for send in cursor.fetchall():
        if validity and send['Validity'] != validity: continue
        if source and send['source'] != source: continue
        if destination and send['destination'] != destination: continue
        sends.append(dict(send))
    cursor.close()
    return(sends)

def get_orders (validity=None, address=None, show_empty=True, show_expired=True):
    db = sqlite3.connect(config.DATABASE)
    db.row_factory = sqlite3.Row
    cursor = db.cursor()

    cursor.execute('''SELECT * FROM orders ORDER BY price ASC, tx_index''')
    block_count = bitcoin.rpc('getblockcount', [])['result']
    orders = []
    for order in cursor.fetchall():
        if validity and order['Validity'] != validity: continue
        if not show_empty and not order['give_remaining']: continue
        if address and order['source'] != address: continue

        # Ignore BTC orders one block early.
        time_left = util.get_time_left(order)
        if not order['give_id']: time_left -= 1
        if not show_expired and time_left < 0:
            continue

        orders.append(dict(order))
    cursor.close()
    return orders

def get_order_matches (validity=None, addresses=[], show_expired=True, tx0_hash=None, tx1_hash=None):
    db = sqlite3.connect(config.DATABASE)
    db.row_factory = sqlite3.Row
    cursor = db.cursor()

    cursor.execute('''SELECT * FROM order_matches ORDER BY tx1_index''')
    order_matches = []
    for order_match in cursor.fetchall():
        if validity and order_match['validity'] != validity: continue

        if not show_expired:
            order_match_time_left = util.get_order_match_time_left(order_match)
            if order_match_time_left < 0: continue

        if addresses and not ((order_match['tx0_address'] in addresses and
                               not order_match['forward_id']) or
                              (order_match['tx1_address'] in addresses and
                               not order_match['backward_id'])):
            continue
        if tx0_hash and tx0_hash != order_match['tx0_hash']: continue
        if tx1_hash and tx1_hash != order_match['tx1_hash']: continue
        order_matches.append(dict(order_match))
    cursor.close()
    return order_matches

def get_btcpays (validity=None):
    db = sqlite3.connect(config.DATABASE)
    db.row_factory = sqlite3.Row
    cursor = db.cursor()

    cursor.execute('''SELECT * FROM btcpays ORDER BY tx_index''')
    btcpays = []
    for btcpay in cursor.fetchall():
        if validity and btcpay['Validity'] != validity: continue
        btcpays.append(dict(btcpay))
    cursor.close()
    return btcpays

def get_issuances (validity=None, asset_id=None, issuer=None):
    db = sqlite3.connect(config.DATABASE)
    db.row_factory = sqlite3.Row
    cursor = db.cursor()

    cursor.execute('''SELECT * FROM issuances \
                      ORDER BY tx_index ASC''')
    issuances = []
    for issuance in cursor.fetchall():
        if validity and issuance['Validity'] != validity: continue
        if asset_id != None and issuance['asset_id'] != asset_id: continue
        if issuer and issuance['issuer'] != issuer: continue
        issuances.append(dict(issuance))
    cursor.close()
    return issuances

def get_broadcasts (validity=None, source=None, order_by='tx_index ASC'):
    db = sqlite3.connect(config.DATABASE)
    db.row_factory = sqlite3.Row
    cursor = db.cursor()

    if order_by not in ('tx_index ASC', 'timestamp DESC'):
        raise exceptions.PossibleInjectionAttackError('Unknown scheme for ordering broadcasts.')

    cursor.execute('''SELECT * FROM broadcasts \
                      ORDER BY ?''', (order_by,))
    broadcasts = []
    for broadcast in cursor.fetchall():
        if validity and broadcast['Validity'] != validity: continue
        if source and broadcast['source'] != source: continue
        broadcasts.append(dict(broadcast))
    cursor.close()
    return broadcasts

def get_bets (validity=None, address=None, show_empty=True, show_expired=True):
    db = sqlite3.connect(config.DATABASE)
    db.row_factory = sqlite3.Row
    cursor = db.cursor()

    cursor.execute('''SELECT * FROM bets ORDER BY odds DESC, tx_index''')
    block_count = bitcoin.rpc('getblockcount', [])['result']
    bets = []
    for bet in cursor.fetchall():
        if validity and bet['Validity'] != validity: continue
        if not show_empty and not bet['wager_remaining']: continue
        if address and bet['source'] != address: continue
        time_left = util.get_time_left(bet)
        if not show_expired and time_left < 0: continue
        bets.append(dict(bet))
    cursor.close()
    return bets

def get_bet_matches (validity=None, addresses=None, show_expired=True, tx0_hash=None, tx1_hash=None):
    db = sqlite3.connect(config.DATABASE)
    db.row_factory = sqlite3.Row
    cursor = db.cursor()

    cursor.execute('''SELECT * FROM bet_matches ORDER BY tx1_index''')
    bet_matches = []
    for bet_match in cursor.fetchall():
        if validity and bet_match['validity'] != validity: continue
        if not show_expired:
            bet_match_time_left = get_bet_match_time_left(bet_match)
            if bet_match_time_left < 0: continue
        if addresses and not (bet_match['tx0_address'] in addresses or
                              bet_match['tx1_address'] in addresses):
            continue
        if tx0_hash and tx0_hash != bet_match['tx0_hash']: continue
        if tx1_hash and tx1_hash != bet_match['tx1_hash']: continue
        bet_matches.append(dict(bet_match))
    cursor.close()
    return bet_matches

def get_dividends (validity=None, address=None, asset_id=None):
    db = sqlite3.connect(config.DATABASE)
    db.row_factory = sqlite3.Row
    cursor = db.cursor()

    cursor.execute('''SELECT * FROM dividends ORDER BY tx_index''')
    dividends = []
    for dividend in cursor.fetchall():
        if validity and dividend['Validity'] != validity: continue
        if address and dividend['source'] != address: continue
        if asset_id != None and dividend['asset_id'] != asset_id: continue
        dividends.append(dict(dividend))
    cursor.close()
    return dividends

def get_burns (validity=True, address=None):
    db = sqlite3.connect(config.DATABASE)
    db.row_factory = sqlite3.Row
    cursor = db.cursor()

    cursor.execute('''SELECT * FROM burns ORDER BY tx_index''')
    burns = []
    for burn in cursor.fetchall():
        if validity and burn['Validity'] != validity: continue
        if address and burn['address'] != address: continue
        burns.append(dict(burn))
    cursor.close()
    return burns


def get_history (address):
    if not bitcoin.base58_decode(address, bitcoin.ADDRESSVERSION):
        raise exceptions.InvalidAddressError('Not a valid Bitcoin address:',
                                             address)
    history = {}
    history['balances'] = get_balances(address=address)
    history['sends'] = get_sends(validity='Valid', source=address)
    history['orders'] = get_orders(validity='Valid', address=address)
    history['order_matches'] = get_order_matches(validity='Valid', addresses=[address])
    history['btcpays'] = get_btcpays(validity='Valid')
    history['issuances'] = get_issuances(validity='Valid', issuer=address)
    history['broadcasts'] = get_broadcasts(validity='Valid', source=address)
    history['bets'] = get_bets(validity='Valid', address=address)
    history['bet_matches'] = get_bet_matches(validity='Valid', addresses=[address])
    history['dividends'] = get_dividends(validity='Valid', address=address)
    history['burns'] = get_burns(validity='Valid', address=address)
    return history 

# vim: tabstop=8 expandtab shiftwidth=4 softtabstop=4
