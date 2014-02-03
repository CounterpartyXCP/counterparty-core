#! /usr/bin/python3

"""
offer_hash is the hash of either a bet or an order.
"""

import binascii
import struct
import logging

from . import (util, config, exceptions, bitcoin, util)

FORMAT = '>32s'
ID = 70
LENGTH = 32

def create (db, offer_hash, test=False):
    offer = None
    for offer in util.get_orders(db, validity='Valid') + util.get_bets(db, validity='Valid'):
        if offer_hash == offer['tx_hash']:
            break
    if not offer:
        raise exceptions.Useless('No valid offer with that hash.')

    source = offer['source']
    if not bitcoin.rpc('validateaddress', [source])['ismine'] and not test:
        raise exceptions.CancelError('That offer was not made by one of your addresses.')

    offer_hash_bytes = binascii.unhexlify(bytes(offer_hash, 'utf-8'))
    data = config.PREFIX + struct.pack(config.TXTYPE_FORMAT, ID)
    data += struct.pack(FORMAT, offer_hash_bytes)
    return bitcoin.transaction(source, None, None, config.MIN_FEE, data, test)

def parse (db, tx, message):
    cursor = db.cursor()
    validity = 'Valid'

    # Unpack message.
    try:
        offer_hash_bytes = struct.unpack(FORMAT, message)[0]
        offer_hash = binascii.hexlify(offer_hash_bytes).decode('utf-8')
    except Exception:
        offer_hash = None
        validity = 'Invalid: could not unpack'

    if validity == 'Valid':
        # Find offer.
        cursor.execute('''SELECT * FROM orders \
                          WHERE (tx_hash=? AND source=? AND validity=?)''', (offer_hash, tx['source'], 'Valid'))
        orders = cursor.fetchall()
        cursor.execute('''SELECT * FROM bets \
                          WHERE (tx_hash=? AND source=? AND validity=?)''', (offer_hash, tx['source'], 'Valid'))
        bets = cursor.fetchall()

        # Cancel if order.
        if orders:
            order = orders[0]
            cursor.execute('''UPDATE orders \
                                           SET validity=? \
                                           WHERE tx_hash=?''', ('Invalid: cancelled', order['tx_hash']))
            util.credit(db, tx['source'], order['give_asset'], order['give_remaining'])
        # Cancel if bet.
        elif bets:
            bet = bets[0]
            cursor.execute('''UPDATE bets \
                                           SET validity=? \
                                           WHERE tx_hash=?''', ('Invalid: cancelled', bet['tx_hash']))
            util.credit(db, tx['source'], 'XCP', bet['wager_remaining'])
            util.credit(db, tx['source'], 'XCP', bet['fee'])
        # If neither order or bet, mark as invalid.
        else:
            validity = 'Invalid: no valid offer with that hash from that address'

    if validity == 'Valid':
        logging.info('Cancel: {} ({})'.format(offer_hash, tx['tx_hash']))

    # Add parsed transaction to message-type–specific table.
    element_data = {
        'tx_index': tx['tx_index'],
        'tx_hash': tx['tx_hash'],
        'block_index': tx['block_index'],
        'source': tx['source'],
        'offer_hash': offer_hash,
        'validity': validity,
    }
    cursor.execute(*util.get_insert_sql('cancels', element_data))
    config.zeromq_publisher.push_to_subscribers('new_cancel', element_data)
    cursor.close()

# vim: tabstop=8 expandtab shiftwidth=4 softtabstop=4
