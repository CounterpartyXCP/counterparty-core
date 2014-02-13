#! /usr/bin/python3

import binascii
import struct

from . import (util, config, exceptions, bitcoin, util)

FORMAT = '>32s32s'
LENGTH = 32 + 32
ID = 11


def validate (db, order_match_id):
    problems = []
    order_match = None

    cursor = db.cursor()
    cursor.execute('''SELECT * FROM order_matches \
                      WHERE id = ?''', (order_match_id,))
    order_matches = cursor.fetchall()
    cursor.close()
    if len(order_matches) == 0:
        problems.append('no such order match')
    elif len(order_matches) > 1:
        assert False
    else:
        order_match = order_matches[0]
        if order_match['validity'] != 'pending':
            if order_match['validity'] == 'invalid: expired awaiting payment':
                problems.append('expired order match')
            else:
                problems.append('invalid order match')

    return order_match, problems

def create (db, order_match_id, unsigned=False):
    tx0_hash, tx1_hash = order_match_id[:64], order_match_id[64:] # UTF-8 encoding means that the indices are doubled.

    # Try to match.
    order_match, problems = validate(db, order_match_id)
    if problems: raise exceptions.BTCPayError(problems)

    # Figure out to which address the BTC are being paid.
    if order_match['backward_asset'] == 'BTC':
        source = order_match['tx1_address']
        destination = order_match['tx0_address']
        btc_amount = order_match['backward_amount']
    else:
        source = order_match['tx0_address']
        destination = order_match['tx1_address']
        btc_amount = order_match['forward_amount']

    # Warn if down to the wire.
    if not config.PREFIX == config.UNITTEST_PREFIX:
        time_left = order_match['match_expire_index'] - util.last_block(db)['block_index']
        if time_left < 4:
            print('WARNING: Only {} blocks until that order match expires. The payment might not make into the blockchain in time.'.format(time_left))

    tx0_hash_bytes, tx1_hash_bytes = binascii.unhexlify(bytes(tx0_hash, 'utf-8')), binascii.unhexlify(bytes(tx1_hash, 'utf-8'))
    data = config.PREFIX + struct.pack(config.TXTYPE_FORMAT, ID)
    data += struct.pack(FORMAT, tx0_hash_bytes, tx1_hash_bytes)
    return bitcoin.transaction(source, destination, btc_amount, config.MIN_FEE, data, unsigned=unsigned)

def parse (db, tx, message):
    cursor = db.cursor()

    # Unpack message.
    try:
        assert len(message) == LENGTH
        tx0_hash_bytes, tx1_hash_bytes = struct.unpack(FORMAT, message)
        tx0_hash, tx1_hash = binascii.hexlify(tx0_hash_bytes).decode('utf-8'), binascii.hexlify(tx1_hash_bytes).decode('utf-8')
        order_match_id = tx0_hash + tx1_hash
        validity = 'valid'
    except struct.error as e:
        tx0_hash, tx1_hash = None, None
        validity = 'invalid: could not unpack'

    if validity == 'valid':
        # Try to match.
        order_match, problems = validate(db, order_match_id)
        if problems:
            order_match = None
            validity = 'invalid: ' + ';'.join(problems)

    if validity == 'valid':
        update = False
        # Credit source address for the currency that he bought with the bitcoins.
        # BTC must be paid all at once and come from the 'correct' address.
        if order_match['tx0_address'] == tx['source'] and tx['btc_amount'] >= order_match['forward_amount']:
            update = True
            if order_match['backward_asset'] != 'BTC':
                util.credit(db, tx['block_index'], tx['source'], order_match['backward_asset'], order_match['backward_amount'])
            validity = 'valid'
        if order_match['tx1_address'] == tx['source'] and tx['btc_amount'] >= order_match['backward_amount']:
            update = True
            if order_match['forward_asset'] != 'BTC':
                util.credit(db, tx['block_index'], tx['source'], order_match['forward_asset'], order_match['forward_amount'])
            validity = 'valid'

        if update:
            # Update order match.
            bindings = {
                'validity': 'valid',
                'order_match_id': order_match_id
            }
            sql='update order_matches set validity = :validity where id = :order_match_id'
            cursor.execute(sql, bindings)


    # Add parsed transaction to message-type–specific table.
    bindings = {
        'tx_index': tx['tx_index'],
        'tx_hash': tx['tx_hash'],
        'block_index': tx['block_index'],
        'source': tx['source'],
        'destination': tx['destination'],
        'btc_amount': tx['btc_amount'],
        'order_match_id': order_match_id,
        'validity': validity,
    }
    sql='insert into btcpays values(:tx_index, :tx_hash, :block_index, :source, :destination, :btc_amount, :order_match_id, :validity)'
    cursor.execute(sql, bindings)


    cursor.close()

# vim: tabstop=8 expandtab shiftwidth=4 softtabstop=4
