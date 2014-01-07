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
    if not bitcoin.rpc('validateaddress', [source])['ismine']:
        raise exceptions.CancelError('That offer was not made by one of your addresses.')

    offer_hash_bytes = binascii.unhexlify(bytes(offer_hash, 'utf-8'))
    data = config.PREFIX + struct.pack(config.TXTYPE_FORMAT, ID)
    data += struct.pack(FORMAT, offer_hash_bytes)
    return bitcoin.transaction(source, None, None, config.MIN_FEE, data, test)

def parse (db, tx, message):
    cancel_parse_cursor = db.cursor()
    validity = 'Valid'

    # Unpack message.
    try:
        offer_hash_bytes = struct.unpack(FORMAT, message)[0]
        offer_hash = binascii.hexlify(offer_hash_bytes).decode('utf-8')
    except Exception:
        offer_hash = None
        validity = 'Invalid: could not unpack'


    if validity == 'Valid':
        # Find the offer.
        cancel_parse_cursor.execute('''SELECT * FROM (orders JOIN bets) \
                                       WHERE ((orders.tx_hash=? AND orders.source=? AND orders.validity=?) OR (bets.tx_hash=? AND bets.source=? AND bets.validity=?))''', (offer_hash, tx['source'], 'Valid', offer_hash, tx['source'], 'Valid'))
        offer = cancel_parse_cursor.fetchone()
        # assert not cancel_parse_cursor.fetchone() # TODO: Why am I getting multiple matches here?!
        if not offer:
            validity = 'Invalid: no valid offer with that hash from that address'

    if validity == 'Valid':
        # Cancel the offer. (This in very inelegant.)
        cancel_parse_cursor.execute('''UPDATE orders \
                                       SET validity=? \
                                       WHERE (tx_hash=? AND source=? AND validity=?)''', ('Invalid: cancelled', offer_hash, tx['source'], 'Valid'))
        cancel_parse_cursor.execute('''UPDATE bets \
                                       SET validity=? \
                                       WHERE (tx_hash=? AND source=? AND validity=?)''', ('Invalid: cancelled', offer_hash, tx['source'], 'Valid'))

        logging.info('Cancel: {} ({})'.format(util.short(offer_hash), util.short(tx['tx_hash'])))

    # Add parsed transaction to message-type–specific table.
    cancel_parse_cursor.execute('''INSERT INTO cancels(
                        tx_index,
                        tx_hash,
                        block_index,
                        source,
                        offer_hash,
                        validity) VALUES(?,?,?,?,?,?)''',
                        (tx['tx_index'],
                        tx['tx_hash'],
                        tx['block_index'],
                        tx['source'],
                        offer_hash,
                        validity)
                  )

    cancel_parse_cursor.close()

# vim: tabstop=8 expandtab shiftwidth=4 softtabstop=4
