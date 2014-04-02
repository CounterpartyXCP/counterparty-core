#! /usr/bin/python3

"""
offer_hash is the hash of either a bet or an order.
"""

import binascii
import struct

from . import (util, config, exceptions, bitcoin, util)
from . import (order, bet)

FORMAT = '>32s'
LENGTH = 32
ID = 70


def compose (db, offer_hash):

    # Check that offer exists.
    problems = ['no open offer with that hash']
    for offer in util.get_orders(db, status='open') + util.get_bets(db, status='open'):
        if offer_hash == offer['tx_hash']:
            source = offer['source']
            problems = None
            break
    if problems: raise exceptions.CancelError(problems)

    offer_hash_bytes = binascii.unhexlify(bytes(offer_hash, 'utf-8'))
    data = config.PREFIX + struct.pack(config.TXTYPE_FORMAT, ID)
    data += struct.pack(FORMAT, offer_hash_bytes)
    return (source, [], config.MIN_FEE, data)

def parse (db, tx, message):
    cursor = db.cursor()

    # Unpack message.
    try:
        assert len(message) == LENGTH
        offer_hash_bytes = struct.unpack(FORMAT, message)[0]
        offer_hash = binascii.hexlify(offer_hash_bytes).decode('utf-8')
        status = 'valid'
    except (AssertionError, struct.error) as e:
        offer_hash = None
        status = 'invalid: could not unpack'

    if status == 'valid':
        # Find offer.
        cursor.execute('''SELECT * FROM orders \
                          WHERE (tx_hash=? AND source=? AND status=?)''', (offer_hash, tx['source'], 'open'))
        orders = cursor.fetchall()
        cursor.execute('''SELECT * FROM bets \
                          WHERE (tx_hash=? AND source=? AND status=?)''', (offer_hash, tx['source'], 'open'))
        bets = cursor.fetchall()

        # Cancel if order.
        if orders:
            order.cancel_order(db, orders[0], 'cancelled', tx['block_index'])
        # Cancel if bet.
        elif bets:
            bet.cancel_bet(db, bets[0], 'cancelled', tx['block_index'])
        # If neither order or bet, mark as invalid.
        else:
            status = 'invalid: no open offer with that hash from that address'

    # Add parsed transaction to message-type–specific table.
    bindings = {
        'tx_index': tx['tx_index'],
        'tx_hash': tx['tx_hash'],
        'block_index': tx['block_index'],
        'source': tx['source'],
        'offer_hash': offer_hash,
        'status': status,
    }
    sql='insert into cancels values(:tx_index, :tx_hash, :block_index, :source, :offer_hash, :status)'
    cursor.execute(sql, bindings)

    cursor.close()

# vim: tabstop=8 expandtab shiftwidth=4 softtabstop=4
