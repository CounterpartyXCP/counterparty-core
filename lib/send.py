#! /usr/bin/python3

"""Create and parse ‘send’‐type messages."""

import struct
import sqlite3
from . import (util, config, bitcoin)

FORMAT = '>QQ'             # asset_id, amount
ID = 0

def send (source, destination, amount, asset_id):
    balance = util.balance(source, asset_id)
    if balance and balance < amount:
        raise BalanceError('Insufficient funds. (Check that the database is up‐to‐date.)')
    data = config.PREFIX + struct.pack(config.TXTYPE_FORMAT, ID) + struct.pack(FORMAT, asset_id, amount)
    return bitcoin.transaction(source, destination, config.DUST_SIZE, config.MIN_FEE, data)

def parse_send (db, cursor, tx, message):
    # Ask for forgiveness…
    validity = 'Valid'

    # Unpack message.
    try:
        asset_id, amount = struct.unpack(FORMAT, message)
    except Exception as e:
        raise e
        asset_id, amount = None, None
        validity = 'Invalid: could not unpack'

    # Debit.
    if validity == 'Valid':
        db, cursor, validity = util.debit(db, cursor, tx['source'], asset_id, amount)

    # Credit.
    if validity == 'Valid':
        db, cursor = util.credit(db, cursor, tx['destination'], asset_id, amount)

    # Add parsed transaction to message‐type–specific table.
    cursor.execute('''INSERT INTO sends(
                        tx_index,
                        tx_hash,
                        block_index,
                        source,
                        destination,
                        asset_id,
                        amount,
                        validity) VALUES(?,?,?,?,?,?,?,?)''',
                        (tx['tx_index'],
                        tx['tx_hash'],
                        tx['block_index'],
                        tx['source'],
                        tx['destination'],
                        asset_id,
                        amount,
                        validity)
                  )
    if validity == 'Valid':
        cursor, divisible = util.is_divisible(cursor, asset_id)
        if divisible:
            unit = config.UNIT
        else:
            unit = 1
        try:    # TEMP
            asset_name = ASSET_NAME[asset_id]
        except Exception:
            asset_name = asset_id
        print('\tSend:', amount/unit, asset_name, 'from', tx['source'], 'to', tx['destination'], '(' + tx['tx_hash'] + ')')

    return db, cursor

# vim: tabstop=8 expandtab shiftwidth=4 softtabstop=4
