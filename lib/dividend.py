#! /usr/bin/python3

"""Pay out dividends."""

import struct
import sqlite3
import colorama
colorama.init()

from . import (util, config, exceptions, bitcoin)

FORMAT = '>QQ'
ID = 50

def create (source, amount_per_share, share_id):
    # Check balance. Dividends are paid in XCP.
    db = sqlite3.connect(config.LEDGER)
    db.row_factory = sqlite3.Row
    cursor = db.cursor()

    # TODO: Check to see that share_id exists!

    cursor, total_shares = util.total_shares(cursor, share_id)
    amount = amount_per_share * total_shares
    cursor, balance = util.balance(cursor, source, 1)
    if not balance or balance < amount:
        raise exceptions.BalanceError('Insufficient funds. (Check that the database is up‐to‐date.)')

    data = config.PREFIX + struct.pack(config.TXTYPE_FORMAT, ID)
    data += struct.pack(FORMAT, amount_per_share, share_id)
    return bitcoin.transaction(source, None, config.DUST_SIZE, config.MIN_FEE, data)

def parse (db, cursor, tx, message):
    # Ask for forgiveness…
    validity = 'Valid'

    # Unpack message.
    try:
        amount_per_share, share_id = struct.unpack(FORMAT, message)
    except Exception:
        amount_per_share, share_id = None, None
        validity = 'Invalid: could not unpack'

    # Debit.
    cursor, total_shares = util.total_shares(cursor, share_id)
    amount = amount_per_share * total_shares
    if validity == 'Valid':
        db, cursor, validity = util.debit(db, cursor, tx['source'], 1, amount)

    # Credit.
    if validity == 'Valid':
        cursor, holdings = util.find_all(cursor, share_id)
        for address, address_amount in holdings:
            db, cursor = util.credit(db, cursor, address, 1, address_amount * amount_per_share)

    # Add parsed transaction to message‐type–specific table.
    cursor.execute('''INSERT INTO dividend_payments(
                        tx_index,
                        tx_hash,
                        block_index,
                        source,
                        share_id,
                        amount_per_share,
                        validity) VALUES(?,?,?,?,?,?,?)''',
                        (tx['tx_index'],
                        tx['tx_hash'],
                        tx['block_index'],
                        tx['source'],
                        share_id,
                        amount_per_share,
                        validity)
                  )
    if validity == 'Valid':
        print(colorama.Fore.RED + colorama.Style.DIM + '\tDividend Payment:', tx['source'], 'paid', amount_per_share / config.UNIT, 'per share of asset', util.get_asset_name(share_id), util.short(tx['tx_hash']))

    return db, cursor

# vim: tabstop=8 expandtab shiftwidth=4 softtabstop=4
