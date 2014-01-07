#! /usr/bin/python3

import binascii
import struct
import logging

from . import (util, config, exceptions, bitcoin, util)

FORMAT = '>32s32s'
ID = 11
LENGTH = 32 + 32

def create (db, order_match_id, test=False):
    tx0_hash, tx1_hash = order_match_id[:64], order_match_id[64:] # UTF-8 encoding means that the indices are doubled.
    tx0_hash_bytes, tx1_hash_bytes = binascii.unhexlify(bytes(tx0_hash, 'utf-8')), binascii.unhexlify(bytes(tx1_hash, 'utf-8'))
    data = config.PREFIX + struct.pack(config.TXTYPE_FORMAT, ID)
    data += struct.pack(FORMAT, tx0_hash_bytes, tx1_hash_bytes)

    order_matches = util.get_order_matches(db, validity='Valid: awaiting BTC payment', tx0_hash=tx0_hash, tx1_hash=tx1_hash)
    if len(order_matches) == 0:
        raise exceptions.InvalidOrderMatchError('Invalid Order Match ID:', order_match_id)
    elif len(order_matches) > 1:
        raise Exception
    else:
        order_match = order_matches[0]

    # Figure out to which address the BTC are being paid.
    if order_match['backward_asset'] == 'BTC':
        source = order_match['tx1_address']
        destination = order_match['tx0_address']
        btc_amount = order_match['backward_amount']
    else:
        source = order_match['tx0_address']
        destination = order_match['tx1_address']
        btc_amount = order_match['forward_amount']

    return bitcoin.transaction(source, destination, btc_amount, config.MIN_FEE, data, test)

def parse (db, tx, message):
    btcpay_parse_cursor = db.cursor()
    validity = 'Valid'

    # Unpack message.
    try:
        tx0_hash_bytes, tx1_hash_bytes = struct.unpack(FORMAT, message)
        tx0_hash, tx1_hash = binascii.hexlify(tx0_hash_bytes).decode('utf-8'), binascii.hexlify(tx1_hash_bytes).decode('utf-8')
    except Exception:
        tx0_hash, tx1_hash = None, None
        validity = 'Invalid: could not unpack'

    if validity == 'Valid':
        order_match_id = tx0_hash + tx1_hash

        # Try to match.
        btcpay_parse_cursor.execute('''SELECT * FROM order_matches WHERE (tx0_hash=? AND tx1_hash=? AND validity=?)''', (tx0_hash, tx1_hash, 'Valid: awaiting BTC payment'))
        order_match = btcpay_parse_cursor.fetchone()
        assert not btcpay_parse_cursor.fetchone()
        if not order_match:
            validity = 'Invalid: No Such Order Match ID'

    if validity == 'Valid':
        # Credit source address for the currency that he bought with the bitcoins.
        # BTC must be paid all at once and come from the 'correct' address.
        if order_match['tx0_address'] == tx['source'] and tx['btc_amount'] >= order_match['forward_amount']:
            btcpay_parse_cursor.execute('''UPDATE order_matches SET validity=? WHERE (tx0_hash=? AND tx1_hash=?)''', ('Valid', tx0_hash, tx1_hash))
            if order_match['backward_asset'] != 'BTC':
                util.credit(db, tx['source'], order_match['backward_asset'], order_match['backward_amount'])
            validity = 'Paid'
        if order_match['tx1_address'] == tx['source'] and tx['btc_amount'] >= order_match['backward_amount']:
            btcpay_parse_cursor.execute('''UPDATE order_matches SET validity=? WHERE (tx0_hash=? AND tx1_hash=?)''', ('Valid', tx0_hash, tx1_hash))
            if order_match['forward_asset'] != 'BTC':
                util.credit(db, tx['source'], order_match['forward_asset'], order_match['forward_amount'])
            validity = 'Paid'
        logging.info('BTC Payment for Order Match: {} ({})'.format(util.short(order_match_id), util.short(tx['tx_hash'])))

    # Add parsed transaction to message-type–specific table.
    btcpay_parse_cursor.execute('''INSERT INTO btcpays(
                        tx_index,
                        tx_hash,
                        block_index,
                        source,
                        order_match_id,
                        validity) VALUES(?,?,?,?,?,?)''',
                        (tx['tx_index'],
                        tx['tx_hash'],
                        tx['block_index'],
                        tx['source'],
                        order_match_id,
                        validity)
                  )

    btcpay_parse_cursor.close()

# vim: tabstop=8 expandtab shiftwidth=4 softtabstop=4
