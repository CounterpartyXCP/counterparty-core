#! /usr/bin/python3

import struct
import sqlite3

from . import (config, util, bitcoin)

FORMAT = '>QQ?'         # asset_id, amount, divisible
ID = 20

def issuance (source, asset_id, amount, divisible):
    db = sqlite3.connect(config.LEDGER)
    db.row_factory = sqlite3.Row
    cursor = db.cursor()
    # Avoid duplicates.
    cursor.execute('''SELECT * FROM assets WHERE (asset_id=? AND validity=?)''', (asset_id, 'Valid'))
    if cursor.fetchone():
        raise exceptions.IssuanceError('Asset ID already claimed.')
    data = config.PREFIX + struct.pack(config.TXTYPE_FORMAT, ID) + struct.pack(FORMAT, asset_id, amount, divisible)
    db.close()
    return bitcoin.transaction(source, None, config.DUST_SIZE, config.MIN_FEE, data)

def parse_issuance (db, cursor, tx, message):
    # Ask for forgiveness…
    validity = 'Valid'

    # Unpack message.
    try:
        asset_id, amount, divisible = struct.unpack(FORMAT, message)
    except Exception:
        asset_id, amount, divisible = None, None, None
        validity = 'Invalid: could not unpack'

    # Avoid duplicates.
    cursor.execute('''SELECT * FROM assets WHERE (asset_id=? AND validity=?)''', (asset_id, 'Valid'))
    if cursor.fetchone():
        validity = 'Invalid: duplicate Asset ID'

    # Credit.
    if validity == 'Valid':
        db, cursor = util.credit(db, cursor, tx['source'], asset_id, amount)
        if divisible: unit = config.UNIT
        else: unit = 1
        print('\tIssuance:', tx['source'], 'created', amount/unit, 'of asset', asset_id, '(' + tx['tx_hash'] + ')')

    # Add parsed transaction to message‐type–specific table.
    cursor.execute('''INSERT INTO assets(
                        asset_id,
                        amount,
                        divisible,
                        tx_index,
                        tx_hash,
                        block_index,
                        issuer,
                        validity) VALUES(?,?,?,?,?,?,?,?)''',
                        (asset_id,
                        amount,
                        divisible,
                        tx['tx_index'],
                        tx['tx_hash'],
                        tx['block_index'],
                        tx['source'],
                        validity)
                  )

    return db, cursor

# vim: tabstop=8 expandtab shiftwidth=4 softtabstop=4
