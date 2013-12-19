#! /usr/bin/python3

import json
import sqlite3

from . import (config, bitcoin)

def orderbook ():
    db = sqlite3.connect(config.LEDGER)
    db.row_factory = sqlite3.Row
    cursor = db.cursor()

    block_count = bitcoin.rpc('getblockcount', [])['result']

    # Open orders.
    orderbook = []
    cursor.execute('''SELECT * FROM orders ORDER BY ask_price ASC, tx_index''')
    for order in cursor.fetchall():
        time_left = order['block_index'] + order['expiration'] - block_count # Inclusive/exclusive expiration? DUPE
        if order['validity'] == 'Valid' and order['give_remaining'] and ((time_left > 0 and order['give_id'] and order['get_id']) or time_left > 1): # Ignore BTC orders one block early.
            orderbook.append(dict(order))

    return orderbook

def pending():
    """Deals awaiting Bitcoin payment from you."""
    db = sqlite3.connect(config.LEDGER)
    db.row_factory = sqlite3.Row
    cursor = db.cursor()

    block_count = bitcoin.rpc('getblockcount', [])['result']

    pending = []
    address_list = [ element['address'] for element in bitcoin.rpc('listreceivedbyaddress', [0,True])['result'] ]
    cursor.execute('''SELECT * FROM deals ORDER BY tx1_index''')
    for deal in cursor.fetchall():

        # Check that neither order has expired.
        expired = False
        cursor.execute('''SELECT * FROM orders WHERE (tx_hash=? OR tx_hash=?)''', (deal['tx0_hash'], deal['tx1_hash']))
        for order in cursor.fetchall():
            time_left = order['block_index'] + order['expiration'] - block_count # Inclusive/exclusive expiration?
            if time_left <= 0: expired = True

        if deal['validity'] == 'Valid: waiting for bitcoins' and not expired:
            deal_id = deal['tx0_hash'] + deal['tx1_hash']
            if (deal['tx0_address'] in address_list and not deal['forward_id'] or
                    deal['tx1_address'] in address_list and not deal['backward_id']):
                pending.append(dict(deal))

    return pending

def history (address):
    db = sqlite3.connect(config.LEDGER)
    db.row_factory = sqlite3.Row
    cursor = db.cursor()

    if not bitcoin.rpc('validateaddress', [address])['result']['isvalid']:
        raise exceptions.InvalidAddressError('Not a valid Bitcoin address:', address)

    history = {}

    # TODO: Get initial balance. (List of deposits to the unspendable address.)

    # List sends.
    cursor.execute('''SELECT * FROM sends \
                      WHERE (source=? OR destination=?) \
                      ORDER BY tx_index''',
                   (address, address))
    history['sends'] = {'incoming': [], 'outgoing': []}
    for send in cursor.fetchall():
        if send['source'] == address:
            history['sends']['incoming'].append(dict(send))
        else:
            history['sends']['outgoing'].append(dict(send))

    # List orders.
    cursor.execute('''SELECT * FROM orders \
                      WHERE (source=?)\
                      ORDER BY tx_index''',
                   (address,))
    history['orders'] = [dict(order) for order in cursor.fetchall()]

    # List deals.
    cursor.execute('''SELECT * FROM deals \
                      WHERE (tx0_address=? OR tx1_address=?) \
                      ORDER BY tx1_index, tx0_index''',
                   (address, address))
    history['deals'] = [dict(deal) for deal in cursor.fetchall()]

    # List balances in every asset with an initialised balance.
    history['balances'] = {}
    cursor.execute('''SELECT * FROM balances WHERE address=?''', (address,))
    for balance in cursor.fetchall():
        history['balances'][balance['asset_id']] = balance['amount']

    # List issuances.
    cursor.execute('''SELECT * FROM issuances \
                      ORDER BY tx_index''')
    history['issuances'] = [dict(asset) for asset in cursor.fetchall() if asset['issuer'] == address]


    return history 

# vim: tabstop=8 expandtab shiftwidth=4 softtabstop=4
