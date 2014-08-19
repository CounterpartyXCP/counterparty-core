#! /usr/bin/python3

import binascii
import struct

from . import (util, config, exceptions, bitcoin, util)

FORMAT = '>32s32s'
LENGTH = 32 + 32
ID = 11


def validate (db, source, order_match_id, block_index):
    problems = []
    order_match = None

    cursor = db.cursor()
    cursor.execute('''SELECT * FROM order_matches \
                      WHERE id = ?''', (order_match_id,))
    order_matches = cursor.fetchall()
    cursor.close()
    if len(order_matches) == 0:
        problems.append('no such order match')
        return None, None, None, None, order_match, problems
    elif len(order_matches) > 1:
        assert False
    else:
        order_match = order_matches[0]

        if order_match['status'] == 'expired':
            problems.append('order match expired')
        elif order_match['status'] == 'completed':
            problems.append('order match completed')
        elif order_match['status'].startswith('invalid'):
            problems.append('order match invalid')
        elif order_match['status'] != 'pending':
            raise exceptions.OrderError('unrecognised order match status')

    # Figure out to which address the BTC are being paid.
    # Check that source address is correct.
    if order_match['backward_asset'] == config.BTC:
        if source != order_match['tx1_address'] and not (block_index >= 313900 or config.TESTNET):  # Protocol change.
            problems.append('incorrect source address')
        destination = order_match['tx0_address']
        btc_quantity = order_match['backward_quantity']
        escrowed_asset  = order_match['forward_asset']
        escrowed_quantity = order_match['forward_quantity']
    elif order_match['forward_asset'] == config.BTC:
        if source != order_match['tx0_address'] and not (block_index >= 313900 or config.TESTNET):  # Protocol change.
            problems.append('incorrect source address')
        destination = order_match['tx1_address']
        btc_quantity = order_match['forward_quantity']
        escrowed_asset  = order_match['backward_asset']
        escrowed_quantity = order_match['backward_quantity']
    else:
        assert False

    return destination, btc_quantity, escrowed_asset, escrowed_quantity, order_match, problems

def compose (db, source, order_match_id):
    tx0_hash, tx1_hash = order_match_id[:64], order_match_id[64:] # UTF-8 encoding means that the indices are doubled.

    destination, btc_quantity, escrowed_asset, escrowed_quantity, order_match, problems = validate(db, source, order_match_id, util.last_block(db)['block_index'])
    if problems: raise exceptions.BTCPayError(problems)

    # Warn if down to the wire.
    time_left = order_match['match_expire_index'] - util.last_block(db)['block_index']
    if time_left < 4:
        print('WARNING: Only {} blocks until that order match expires. The payment might not make into the blockchain in time.'.format(time_left))
    if 10 - time_left < 4:
        print('WARNING: Order match has only {} confirmation(s).'.format(10 - time_left))

    tx0_hash_bytes, tx1_hash_bytes = binascii.unhexlify(bytes(tx0_hash, 'utf-8')), binascii.unhexlify(bytes(tx1_hash, 'utf-8'))
    data = config.PREFIX + struct.pack(config.TXTYPE_FORMAT, ID)
    data += struct.pack(FORMAT, tx0_hash_bytes, tx1_hash_bytes)
    return (source, [(destination, btc_quantity)], data)

def parse (db, tx, message):
    cursor = db.cursor()

    # Unpack message.
    try:
        assert len(message) == LENGTH
        tx0_hash_bytes, tx1_hash_bytes = struct.unpack(FORMAT, message)
        tx0_hash, tx1_hash = binascii.hexlify(tx0_hash_bytes).decode('utf-8'), binascii.hexlify(tx1_hash_bytes).decode('utf-8')
        order_match_id = tx0_hash + tx1_hash
        status = 'valid'
    except (AssertionError, struct.error) as e:
        tx0_hash, tx1_hash, order_match_id = None, None, None
        status = 'invalid: could not unpack'

    if status == 'valid':
        destination, btc_quantity, escrowed_asset, escrowed_quantity, order_match, problems = validate(db, tx['source'], order_match_id, tx['block_index'])
        if problems:
            order_match = None
            status = 'invalid: ' + '; '.join(problems)

    if status == 'valid':
        # BTC must be paid all at once.
        if tx['btc_amount'] >= btc_quantity:

            # Credit source address for the currency that he bought with the bitcoins.
            util.credit(db, tx['block_index'], tx['source'], escrowed_asset, escrowed_quantity)
            status = 'valid'

            # Update order match.
            bindings = {
                'status': 'completed',
                'order_match_id': order_match_id
            }
            sql='update order_matches set status = :status where id = :order_match_id'
            cursor.execute(sql, bindings)
            util.message(db, tx['block_index'], 'update', 'order_matches', bindings)

    # Add parsed transaction to message-type–specific table.
    bindings = {
        'tx_index': tx['tx_index'],
        'tx_hash': tx['tx_hash'],
        'block_index': tx['block_index'],
        'source': tx['source'],
        'destination': tx['destination'],
        'btc_amount': tx['btc_amount'],
        'order_match_id': order_match_id,
        'status': status,
    }
    sql='insert into btcpays values(:tx_index, :tx_hash, :block_index, :source, :destination, :btc_amount, :order_match_id, :status)'
    cursor.execute(sql, bindings)


    cursor.close()

# vim: tabstop=8 expandtab shiftwidth=4 softtabstop=4
