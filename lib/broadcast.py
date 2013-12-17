#! /usr/bin/python3

"""
Broadcast a message, with or without a price.

Multiple messages per block are allowed. Bets are be made on the ‘timestamp’
field, and not the block index.

An address is a feed of broadcasts. Feeds (addresses) may be locked with a
broadcast containing a blank ‘text’ field. Bets on a feed reference the address
that is the source of the feed in an output which includes the (latest)
required fee.

Broadcasts without a price may not be used for betting. Broadcasts about events
with a small number of possible outcomes (e.g. sports games), should be
written, for example, such that a price of 1 XCP means one outcome, 2 XCP means
another, etc., which schema should be described in the ‘text’ field.
"""

import struct
import sqlite3
import datetime

from . import (util, config, bitcoin)

FORMAT = '>IQQQ48p' # timestamp, price_id, price_amount, fee (XCP), text
ID = 30

def create (source, timestamp, price_id, price_amount, fee_required, text):
    data = config.PREFIX + struct.pack(config.TXTYPE_FORMAT, ID) + struct.pack(FORMAT, timestamp, price_id, price_amount, fee_required, text.encode('utf-8'))
    return bitcoin.transaction(source, None, config.DUST_SIZE, config.MIN_FEE, data)

def parse (db, cursor, tx, message):
    # Ask for forgiveness…
    validity = 'Valid'

    # Unpack message.
    try:
        timestamp, price_id, price_amount, fee_required, text = struct.unpack(FORMAT, message)
        text = text.decode('utf-8')
    except Exception:
        asset_id, amount = None, None
        validity = 'Invalid: could not unpack'

    # Check that the publishing address is not locked.
    if util.is_locked(tx['source']):
        validity = 'Invalid: address is locked'

    # Add parsed transaction to message‐type–specific table.
    cursor.execute('''INSERT INTO broadcasts(
                        tx_index,
                        tx_hash,
                        block_index,
                        source,
                        timestamp,
                        price_id,
                        price_amount,
                        fee_required,
                        text,
                        validity) VALUES(?,?,?,?,?,?,?,?,?,?)''',
                        (tx['tx_index'],
                        tx['tx_hash'],
                        tx['block_index'],
                        tx['source'],
                        timestamp,
                        price_id,
                        price_amount,
                        fee_required,
                        text,
                        validity)
                  )
    if validity == 'Valid':
        if util.is_divisible(price_id):
            price_amount /= config.UNIT

        try:    # TEMP
            price_name = config.ASSET_NAME[price_id]
        except Exception as e:
            raise e
            price_name = price_id

        suffix = 'from ' + tx['source'] + ' at ' + datetime.datetime.fromtimestamp(timestamp).isoformat() + ' (' + tx['tx_hash'] + ') '

        if not price_amount:
            price_amount, price_name = '', ''
            print('\tBroadcast:', '‘' + text + '’', suffix)
        else:
            print('\tBroadcast:', '‘' + text + ' =', price_amount, price_name + '’', suffix)

              
    return db, cursor

# vim: tabstop=8 expandtab shiftwidth=4 softtabstop=4
