#! /usr/bin/python3

import sqlite3
import json

from lib import (config, util, bitcoin)

def book ():
    db = sqlite3.connect(config.DATABASE)
    db.row_factory = sqlite3.Row
    cursor = db.cursor()

    cursor, orders = util.get_orders(cursor, show_invalid=False, show_expired=False, show_empty=False)
    cursor, bets = util.get_bets(cursor, show_invalid=False, show_expired=False, show_empty=False)
    cursor, btcpays = util.get_btcpays(cursor, show_not_mine=False, show_expired=False)

    book = {}
    book['orders'] = orders
    book['bets'] = bets
    book['btcpays'] = btcpays

    return book


def history (address):
    db = sqlite3.connect(config.DATABASE)
    db.row_factory = sqlite3.Row
    cursor = db.cursor()

    if not bitcoin.rpc('validateaddress', [address])['result']['isvalid']:
        raise exceptions.InvalidAddressError('Not a valid Bitcoin address:', address)

    history = {}

    # List burns.

    # List dividends.

    # List bets.

    # List contracts.

    # List btcpays.

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



    # List balances (in every asset with an initialised balance).
    cursor, balances = util.get_balance(cursor, address=address)
    history['balances'] = [dict(balance) for balance in balances]

    # List issuances.
    cursor, issuances = util.get_issuances(cursor, issuer=address)
    history['issuances'] = [dict(issuance) for issuance in issuances]

    return history 

# vim: tabstop=8 expandtab shiftwidth=4 softtabstop=4
