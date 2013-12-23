#! /usr/bin/python3

import binascii
import struct
import sqlite3
import logging

from . import (util, config, exceptions, bitcoin)

FORMAT = '>32s32s'
ID = 11
LENGTH = 32 + 32

def create (deal_id):
    db = sqlite3.connect(config.DATABASE)
    db.row_factory = sqlite3.Row
    cursor = db.cursor()

    tx0_hash, tx1_hash = deal_id[:64], deal_id[64:] # UTF‐8 encoding means that the indices are doubled.
    tx0_hash_bytes, tx1_hash_bytes = binascii.unhexlify(tx0_hash), binascii.unhexlify(tx1_hash)
    data = config.PREFIX + struct.pack(config.TXTYPE_FORMAT, ID)
    data += struct.pack(FORMAT, tx0_hash_bytes, tx1_hash_bytes)

    cursor.execute('''SELECT * FROM deals \
                      WHERE (tx0_hash=? AND tx1_hash=?)''',
                   (tx0_hash, tx1_hash))
    deal = cursor.fetchone()
    assert not cursor.fetchone()
    if not deal: raise exceptions.InvalidDealError('Invalid Deal ID:', deal_id)

    if not deal['backward_id']:
        source = deal['tx1_address']
        destination = deal['tx0_address']
        btc_amount = deal['backward_amount']
    else:
        source = deal['tx0_address']
        destination = deal['tx1_address']
        btc_amount = deal['forward_amount']

    return bitcoin.transaction(source, destination, btc_amount, config.MIN_FEE, data)

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

    cursor.execute('''SELECT * FROM deals WHERE (tx0_hash=? AND tx1_hash=?)''', (tx0_hash, tx1_hash))
    deal = cursor.fetchone()
    assert not cursor.fetchone()
    if not deal: return db, cursor
    # Credit source address for the currency that he bought with the bitcoins.
    # BTC must be paid all at once and come from the ‘correct’ address.
    if deal['tx0_address'] == tx['source'] and tx['btc_amount'] >= deal['forward_amount']:
        cursor.execute('''UPDATE deals SET validity=? WHERE (tx0_hash=? AND tx1_hash=?)''', ('Valid', tx0_hash, tx1_hash))
        db.commit()
        if deal['backward_id']:    # Gratuitous
            db, cursor = util.credit(db, cursor, tx['source'], deal['backward_id'], deal['backward_amount'])
    if deal['tx1_address'] == tx['source'] and tx['btc_amount'] >= deal['backward_amount']:
        cursor.execute('''UPDATE deals SET validity=? WHERE (tx0_hash=? AND tx1_hash=?)''', ('Valid', tx0_hash, tx1_hash))
        if deal['forward_id']:     # Gratuitous
            db, cursor = util.credit(db, cursor, tx['source'], deal['forward_id'], deal['forward_amount'])

    deal_id = tx0_hash + tx1_hash
    logging.info('BTC payment for deal: {} ({})'.format(util.short(deal_id), util.short(tx['tx_hash'])))

    return db, cursor

# vim: tabstop=8 expandtab shiftwidth=4 softtabstop=4
