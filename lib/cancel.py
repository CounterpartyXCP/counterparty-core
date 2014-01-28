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

def validate (db, offer_hash, source=None):
    problems = []

    for offer in util.get_orders(db, validity='Valid') + util.get_bets(db, validity='Valid'):
        if offer_hash == offer['tx_hash']:
            if source == offer['source']:
                return source, offer, problems
            else:
                if bitcoin.rpc('validateaddress', [offer['source']])['ismine'] or config.PREFIX == config.TEST_PREFIX:
                    source = offer['source']
                else:
                    problems.append('offer was not made by one of your addresses')
                return source, offer, problems
                
    problems.append('no valid offer with that hash')
    return None, None, problems


def create (db, offer_hash, unsigned=False):
    source, offer, problems = validate(db, offer_hash)
    if problems: raise exceptions.CancelError(problems)

    offer_hash_bytes = binascii.unhexlify(bytes(offer_hash, 'utf-8'))
    data = config.PREFIX + struct.pack(config.TXTYPE_FORMAT, ID)
    data += struct.pack(FORMAT, offer_hash_bytes)
    return bitcoin.transaction(source, None, None, config.MIN_FEE, data, unsigned=unsigned)

def parse (db, tx, message):
    cancel_parse_cursor = db.cursor()

    # Unpack message.
    try:
        offer_hash_bytes = struct.unpack(FORMAT, message)[0]
        offer_hash = binascii.hexlify(offer_hash_bytes).decode('utf-8')
        validity = 'Valid'
    except Exception:
        offer_hash = None
        validity = 'Invalid: could not unpack'

    if validity == 'Valid':
        if validity == 'Valid':
            source, offer, problems = validate(db, offer_hash, source=tx['source'])
            if problems: validity = 'Invalid: ' + ';'.join(problems)

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
    element_data = {
        'tx_index': tx['tx_index'],
        'tx_hash': tx['tx_hash'],
        'block_index': tx['block_index'],
        'source': tx['source'],
        'offer_hash': offer_hash,
        'validity': validity,
    }
    cancel_parse_cursor.execute(*util.get_insert_sql('cancels', element_data))
    config.zeromq_publisher.push_to_subscribers('new_cancel', element_data)

    cancel_parse_cursor.close()

# vim: tabstop=8 expandtab shiftwidth=4 softtabstop=4
