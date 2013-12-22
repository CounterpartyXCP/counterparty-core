#! /usr/bin/python3

import struct
import sqlite3
import logging

from . import (config, util, exceptions, bitcoin)

FORMAT = '>QQ?'
ID = 20
LENGTH = 8 + 8

def create (source, asset_id, amount, divisible):
    db = sqlite3.connect(config.DATABASE)
    db.row_factory = sqlite3.Row
    cursor = db.cursor()

    # Handle potential re‐issuances.
    cursor, issuances = util.get_issuances(cursor, asset_id)
    if issuances:
        if issuances[0]['issuer'] != source:
            raise exceptions.IssuanceError('Asset exists and was not issued by this address.')
        if issuances[0]['divisible'] != divisible:
            raise exceptions.IssuanceError('That asset exists with a different divisibility.')

    data = config.PREFIX + struct.pack(config.TXTYPE_FORMAT, ID)
    data += struct.pack(FORMAT, asset_id, amount, divisible)
    db.close()
    return bitcoin.transaction(source, None, config.DUST_SIZE, config.MIN_FEE, data)

def parse (db, cursor, tx, message):
    # Ask for forgiveness…
    validity = 'Valid'

    # Unpack message.
    try:
        asset_id, amount, divisible = struct.unpack(FORMAT, message)
    except Exception:
        asset_id, amount, divisible = None, None, None
        validity = 'Invalid: could not unpack'

    # If re‐issuance, check for compatability in divisibility, issuer.
    cursor, issuances = util.get_issuance(cursor, asset_id)
    if issuances:
        if issuances[0]['issuer'] != tx['source']:
            validity = 'Invalid: that asset already exists and was not issued by this address'
        if validity == 'Valid' and issuance['divisible'] != divisible:
            validity = 'Invalid: asset exists with a different divisibility'

    # Credit.
    if validity == 'Valid':
        db, cursor = util.credit(db, cursor, tx['source'], asset_id, amount)
        if divisible: unit = config.UNIT
        else: unit = 1
        logging.info('(Re‐)Issuance: {} created {} of asset {} ({})'.format(tx['source'], amount / unit, asset_id, util.short(tx['tx_hash'])))

    # Add parsed transaction to message‐type–specific table.
    cursor.execute('''INSERT INTO issuances(
                        tx_index,
                        tx_hash,
                        block_index,
                        asset_id,
                        amount,
                        divisible,
                        issuer,
                        validity) VALUES(?,?,?,?,?,?,?,?)''',
                        (tx['tx_index'],
                        tx['tx_hash'],
                        tx['block_index'],
                        asset_id,
                        amount,
                        divisible,
                        tx['source'],
                        validity)
                  )

    return db, cursor

# vim: tabstop=8 expandtab shiftwidth=4 softtabstop=4
