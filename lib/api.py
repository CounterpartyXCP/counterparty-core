#! /usr/bin/python3

import sqlite3
import json

from lib import (config, util, bitcoin)

db = sqlite3.connect(config.DATABASE)
db.row_factory = sqlite3.Row
cursor = db.cursor()

def get_balances (address=None, asset_id=None):
    cursor.execute('''SELECT * FROM balances''')
    for balance in cursor.fetchall():
        if address and balance['address'] != address: continue
        if asset_id and balance['asset_id'] != asset_id: continue
        yield dict(balance)

def get_sends (validity=None, source=None, destination=None):
    cursor.execute('''SELECT * FROM sends''')
    for send in cursor.fetchall():
        if validity and send['Validity'] != validity: continue
        if source and send['source'] != source: continue
        if destination and send['destination'] != destination: continue
        yield dict(send)

def get_orders (validity=None, address=None, show_empty=True, show_expired=True):
    cursor.execute('''SELECT * FROM orders ORDER BY price ASC, tx_index''')
    block_count = bitcoin.rpc('getblockcount', [])['result']
    for order in cursor.fetchall():
        if validity and order['Validity'] != validity: continue
        if not show_empty and not order['give_remaining']: continue
        if address and order['source'] != address: continue

        # Ignore BTC orders one block early.
        time_left = util.get_time_left(order)
        if not show_expired and not ((time_left > 0 and order['give_id'] and
                                    order['get_id']) or time_left > 1):
            continue

        yield dict(order)

def get_matched_orders (validity=None, addresses=[], show_expired=True):
    cursor.execute('''SELECT * FROM matched_orders ORDER BY tx1_index''')
    for matched_order in cursor.fetchall():
        if validity and matched_order['validity'] != validity: continue

        if not show_expired:
            matched_order_time_left = util.get_matched_order_time_left(matched_order)
            if matched_order_time_left <= 0: continue

        if addresses and not ((matched_order['tx0_address'] in addresses and
                               not matched_order['forward_id']) or
                              (matched_order['tx1_address'] in addresses and
                               not matched_order['backward_id'])):
            continue

        yield dict(matched_order)

def get_btcpays (validity=None):
    cursor.execute('''SELECT * FROM btcpays''')
    for btcpay in cursor.fetchall():
        if validity and btcpay['Validity'] != validity: continue
        yield dict(btcpay)

def get_issuances (validity=None, asset_id=None, issuer=None):
    cursor.execute('''SELECT * FROM issuances \
                      ORDER BY tx_index ASC''')
    for issuance in cursor.fetchall():
        if validity and issuance['Validity'] != validity: continue
        if asset_id and issuance['asset_id'] != asset_id: continue
        if issuer and issuance['issuer'] != issuer: continue
        yield dict(issuance)

def get_bets (validity=None, address=None, show_empty=True, show_expired=True):
    cursor.execute('''SELECT * FROM bets ORDER BY odds DESC, tx_index''')
    block_count = bitcoin.rpc('getblockcount', [])['result']
    for bet in cursor.fetchall():
        if validity and bet['Validity'] != validity: continue
        if not show_empty and not bet['wager_remaining']: continue
        if address and bet['source'] != address: continue
        time_left = util.get_time_left(bet)
        if not show_expired and time_left < 0: continue
        yield dict(bet)

def get_matched_bets (validity=None, addresses=None, show_expired=True):
    cursor.execute('''SELECT * FROM matched_bets ORDER BY tx1_index''')
    for matched_bet in cursor.fetchall():
        if validity and matched_bet['validity'] != validity: continue
        if not show_expired:
            matched_bet_time_left = get_matched_bet_time_left(matched_bet)
            if matched_bet_time_left <= 0: continue
        if addresses and not (matched_bet['tx0_address'] in addresses or
                              matched_bet['tx1_address'] in addresses):
            continue
        yield dict(matched_bet)

def get_dividends (validity=None, address=None, asset_id=None):
    cursor.execute('''SELECT * FROM dividends''')
    for dividend in cursor.fetchall():
        if validity and dividend['Validity'] != validity: continue
        if address and dividend['source'] != address: continue
        if asset_id and dividend['asset_id'] != asset_id: continue
        yield dict(dividend)

def get_burns (validity=True, address=None):
    cursor.execute('''SELECT * FROM burns''')
    for burn in cursor.fetchall():
        if validity and burn['Validity'] != validity: continue
        if address and burn['address'] != address: continue
        yield dict(burn)


def history (address):
    if not bitcoin.rpc('validateaddress', [address])['result']['isvalid']:
        raise exceptions.InvalidAddressError('Not a valid Bitcoin address:',
                                             address)
    history = {}
    history['balances'] = [balance for balance in get_balances(address=address)]
    history['sends'] = [send for send in get_sends(validity='Valid', source=address)]
    history['orders'] = [order for order in get_orders(validity='Valid', address=address)]
    history['matched_orders'] = [matched_order for matched_order in get_matched_orders(validity='Valid', addresses=[address])]
    history['btcpays'] = [btcpay for btcpay in get_btcpays(validity='Valid')]
    history['issuances'] = [issuance for issuance in get_issuances(validity='Valid', issuer=address)]
    history['bets'] = [bet for bet in get_bets(validity='Valid', address=address)]
    history['matched_bets'] = [matched_bet for matched_bet in get_matched_bets(validity='Valid', addresses=[address])]
    history['dividends'] = [dividend for dividend in get_dividends(validity='Valid', address=address)]
    history['burns'] = [burn for burn in get_burns(validity='Valid', address=address)]
    return history 

# vim: tabstop=8 expandtab shiftwidth=4 softtabstop=4
