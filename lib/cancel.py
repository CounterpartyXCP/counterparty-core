#! /usr/bin/python3

"""
offer_hash is the hash of either a bet or an order.
"""

import binascii
import struct
import logging

from . import (util, config, exceptions, bitcoin, util)

FORMAT = '>32s'
LENGTH = 32
ID = 70


def validate (db, offer_hash, source=None):
    problems = []

    for offer in util.get_orders(db, validity='Valid') + util.get_bets(db, validity='Valid'):
        if offer_hash == offer['tx_hash']:
            if source == offer['source']:
                return source, offer, problems
            else:
                if bitcoin.rpc('validateaddress', [offer['source']])['ismine'] or config.PREFIX == config.UNITTEST_PREFIX:
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
    cursor = db.cursor()

    # Unpack message.
    try:
        assert len(message) == LENGTH
        offer_hash_bytes = struct.unpack(FORMAT, message)[0]
        offer_hash = binascii.hexlify(offer_hash_bytes).decode('utf-8')
        validity = 'Valid'
    except struct.error as e:
        offer_hash = None
        validity = 'Invalid: could not unpack'

    if validity == 'Valid':
        if validity == 'Valid':
            source, offer, problems = validate(db, offer_hash, source=tx['source'])
            if problems: validity = 'Invalid: ' + ';'.join(problems)

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
            if order['give_asset'] != 'BTC':
                util.credit(db, tx['block_index'], tx['source'], order['give_asset'], order['give_remaining'])
        # Cancel if bet.
        elif bets:
            bet = bets[0]
            cursor.execute('''UPDATE bets \
                                           SET validity=? \
                                           WHERE tx_hash=?''', ('Invalid: cancelled', bet['tx_hash']))
            util.credit(db, tx['block_index'], tx['source'], 'XCP', bet['wager_remaining'])
            util.credit(db, tx['block_index'], tx['source'], 'XCP', round(bet['wager_amount'] * bet['fee_multiplier'] / 1e8))
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


    cursor.close()

# vim: tabstop=8 expandtab shiftwidth=4 softtabstop=4
