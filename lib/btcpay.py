#! /usr/bin/python3

import binascii
import struct
import sqlite3
import logging

from . import (util, config, exceptions, bitcoin)

FORMAT = '>32s32s'
ID = 11
LENGTH = 32 + 32

def create (order_match_id, test=False):
    db = sqlite3.connect(config.DATABASE)
    db.row_factory = sqlite3.Row
    cursor = db.cursor()

    tx0_hash, tx1_hash = order_match_id[:64], order_match_id[64:] # UTF‐8 encoding means that the indices are doubled.
    tx0_hash_bytes, tx1_hash_bytes = binascii.unhexlify(tx0_hash), binascii.unhexlify(tx1_hash)
    data = config.PREFIX + struct.pack(config.TXTYPE_FORMAT, ID)
    data += struct.pack(FORMAT, tx0_hash_bytes, tx1_hash_bytes)

    cursor.execute('''SELECT * FROM order_matches \
                      WHERE (tx0_hash=? AND tx1_hash=?)''',
                   (tx0_hash, tx1_hash))
    order_match = cursor.fetchone()
    assert not cursor.fetchone()
    if not order_match: raise exceptions.InvalidDealError('Invalid Deal ID:', order_match_id)

    if not order_match['backward_id']:
        source = order_match['tx1_address']
        destination = order_match['tx0_address']
        btc_amount = order_match['backward_amount']
    else:
        source = order_match['tx0_address']
        destination = order_match['tx1_address']
        btc_amount = order_match['forward_amount']

    return bitcoin.transaction(source, destination, btc_amount, config.MIN_FEE, data, test)

def parse (db, cursor, tx, message):
    # Ask for forgiveness…
    validity = 'Valid'

    # Unpack message.
    try:
        tx0_hash_bytes, tx1_hash_bytes = struct.unpack(FORMAT, message)
        tx0_hash, tx1_hash = binascii.hexlify(tx0_hash_bytes).decode('utf-8'), binascii.hexlify(tx1_hash_bytes).decode('utf-8')
    except Exception:
        tx0_hash, tx1_hash = None, None
        validity = 'Invalid: could not unpack'

    cursor.execute('''SELECT * FROM order_matches WHERE (tx0_hash=? AND tx1_hash=?)''', (tx0_hash, tx1_hash))
    order_match = cursor.fetchone()
    assert not cursor.fetchone()
    if not order_match: return cursor
    # Credit source address for the currency that he bought with the bitcoins.
    # BTC must be paid all at once and come from the ‘correct’ address.
    if order_match['tx0_address'] == tx['source'] and tx['btc_amount'] >= order_match['forward_amount']:
        cursor.execute('''UPDATE order_matches SET validity=? WHERE (tx0_hash=? AND tx1_hash=?)''', ('Valid', tx0_hash, tx1_hash))
        if order_match['backward_id']:    # Gratuitous
            cursor = util.credit(db, cursor, tx['source'], order_match['backward_id'], order_match['backward_amount'])
    if order_match['tx1_address'] == tx['source'] and tx['btc_amount'] >= order_match['backward_amount']:
        cursor.execute('''UPDATE order_matches SET validity=? WHERE (tx0_hash=? AND tx1_hash=?)''', ('Valid', tx0_hash, tx1_hash))
        if order_match['forward_id']:     # Gratuitous
            cursor = util.credit(db, cursor, tx['source'], order_match['forward_id'], order_match['forward_amount'])

    order_match_id = tx0_hash + tx1_hash

    # Add parsed transaction to message‐type–specific table.
    cursor.execute('''INSERT INTO btcpays(
                        tx_index,
                        tx_hash,
                        block_index,
                        source,
                        amount,
                        order_match_id,
                        validity) VALUES(?,?,?,?,?,?,?)''',
                        (tx['tx_index'],
                        tx['tx_hash'],
                        tx['block_index'],
                        tx['source'],
                        tx['btc_amount'],
                        order_match_id,
                        validity)
                  )
    logging.info('BTC Payment for Order Match: {} ({})'.format(util.short(order_match_id), util.short(tx['tx_hash'])))
    return cursor

# vim: tabstop=8 expandtab shiftwidth=4 softtabstop=4
