#! /usr/bin/python3

"""Create and parse ‘send’‐type messages."""

import struct
import sqlite3
import colorama
colorama.init()

from . import (util, config, exceptions, bitcoin)

FORMAT = '>QQ'
ID = 0

def create (source, destination, amount, asset_id):
    db = sqlite3.connect(config.LEDGER)
    db.row_factory = sqlite3.Row
    cursor = db.cursor()
    cursor, balance = util.balance(cursor, source, asset_id)
    if not balance or balance < amount:
        raise exceptions.BalanceError('Insufficient funds. (Check that the database is up‐to‐date.)')
    data = config.PREFIX + struct.pack(config.TXTYPE_FORMAT, ID)
    data += struct.pack(FORMAT, asset_id, amount)
    return bitcoin.transaction(source, destination, config.DUST_SIZE, config.MIN_FEE, data)

def parse (db, cursor, tx, message):
    # Ask for forgiveness…
    validity = 'Valid'

    # Unpack message.
    try:
        asset_id, amount = struct.unpack(FORMAT, message)
    except Exception:
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
        if divisible: amount /= config.UNIT
        print(colorama.Fore.GREEN + '\tSend:', amount, util.get_asset_name(asset_id), 'from', tx['source'], 'to', tx['destination'], util.short(tx['tx_hash']))

    return db, cursor

# vim: tabstop=8 expandtab shiftwidth=4 softtabstop=4
