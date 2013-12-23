#! /usr/bin/python3

"""
These functions, as opposed to those in util.py, are meant to be used by either
the counterpartyd CLI or by external programs, and not by the counterpartyd
internals. Consequently, they provide their own database connexions.

"""

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
        raise exceptions.InvalidAddressError('Not a valid Bitcoin address:',
                                             address)

    history = {}

    # List balances (in every asset with an initialised balance).
    cursor, balances = util.get_balances(cursor, address=address)
    history['balances'] = [dict(balance) for balance in balances]

    # List sends.
    cursor, sends = util.get_sends(cursor, validity='Valid', source=address)
    history['sends'] = {'incoming': [], 'outgoing': []}
    for send in sends:
        if send['source'] == address:
            history['sends']['incoming'].append(dict(send))
        else:
            history['sends']['outgoing'].append(dict(send))

    # List orders.
    cursor, orders = util.get_orders(cursor, validity='Valid', address=address)
    history['orders'] = [dict(order) for order in orders]

    # List deals.
    cursor, deals = util.get_deals(cursor, validity='Valid', addresses=[address])
    history['deals'] = [dict(deal) for deal in deals]

    # List btcpays.
    # cursor, btcpays = util.get_btcpays(cursor, validity='Valid', address=address)
    # history['btcpays'] = [dict(btcpay) for btcpay in btcpays]

    # List issuances.
    cursor, issuances = util.get_issuances(cursor, validity='Valid', issuer=address)
    history['issuances'] = [dict(issuance) for issuance in issuances]

    # List bets.
    cursor, bets = util.get_bets(cursor, validity='Valid', address=address)
    history['bets'] = [dict(bet) for bet in bets]

    # List contracts.
    cursor, contracts = util.get_contracts(cursor, validity='Valid', addresses=[address])
    history['contracts'] = [dict(contract) for contract in contracts]

    # List dividends.
    cursor, dividends = util.get_dividends(cursor, validity='Valid', issuer=address)
    history['dividends'] = [dict(dividend) for dividend in dividends]

    # List burns.
    cursor, burns = util.get_burns(cursor, validity='Valid', address=address)
    history['burns'] = [dict(burn) for burn in burns]

    return history 

# vim: tabstop=8 expandtab shiftwidth=4 softtabstop=4
