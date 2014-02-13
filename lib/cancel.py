#! /usr/bin/python3

"""
offer_hash is the hash of either a bet or an order.
"""

import binascii
import struct

from . import (util, config, exceptions, bitcoin, util)

FORMAT = '>32s'
LENGTH = 32
ID = 70


def validate (db, offer_hash, source=None):
    problems = []

    for offer in util.get_orders(db, validity='valid') + util.get_bets(db, validity='valid'):
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
        validity = 'valid'
    except struct.error as e:
        offer_hash = None
        validity = 'invalid: could not unpack'

    if validity == 'valid':
        if validity == 'valid':
            source, offer, problems = validate(db, offer_hash, source=tx['source'])
            if problems: validity = 'invalid: ' + ';'.join(problems)

    if validity == 'valid':
        # Find offer.
        cursor.execute('''SELECT * FROM orders \
                          WHERE (tx_hash=? AND source=? AND validity=?)''', (offer_hash, tx['source'], 'valid'))
        orders = cursor.fetchall()
        cursor.execute('''SELECT * FROM bets \
                          WHERE (tx_hash=? AND source=? AND validity=?)''', (offer_hash, tx['source'], 'valid'))
        bets = cursor.fetchall()

        # Cancel if order.
        if orders:
            order = orders[0]

            # Update validity of order.
            bindings = {
                'validity': 'cancelled',
                'tx_hash': order['tx_hash']
            }
            sql='update orders set validity = :validity where tx_hash = :tx_hash'
            cursor.execute(sql, bindings)

            if order['give_asset'] != 'BTC':
                util.credit(db, tx['block_index'], tx['source'], order['give_asset'], order['give_remaining'])
        # Cancel if bet.
        elif bets:
            bet = bets[0]

            # Update validity of bet.
            bindings = {
                'validity': 'cancelled',
                'tx_hash': bet['tx_hash']
            }
            sql='update bets set validity = :validity where tx_hash = :tx_hash'
            cursor.execute(sql, bindings)

            util.credit(db, tx['block_index'], tx['source'], 'XCP', bet['wager_remaining'])
            util.credit(db, tx['block_index'], tx['source'], 'XCP', round(bet['wager_amount'] * bet['fee_multiplier'] / 1e8))
        # If neither order or bet, mark as invalid.
        else:
            validity = 'invalid: no valid offer with that hash from that address'

    # Add parsed transaction to message-type–specific table.
    bindings = {
        'tx_index': tx['tx_index'],
        'tx_hash': tx['tx_hash'],
        'block_index': tx['block_index'],
        'source': tx['source'],
        'offer_hash': offer_hash,
        'validity': validity,
    }
    sql='insert into cancels values(:tx_index, :tx_hash, :block_index, :source, :offer_hash, :validity)'
    cursor.execute(sql, bindings)


    cursor.close()

# vim: tabstop=8 expandtab shiftwidth=4 softtabstop=4
