#! /usr/bin/python3

import struct
import sqlite3
import logging

from . import (config, util, exceptions, bitcoin, api)

FORMAT = '>QQ?'
ID = 20
LENGTH = 8 + 8 + 1

def create (source, asset_id, amount, divisible):
    db = sqlite3.connect(config.DATABASE)
    db.row_factory = sqlite3.Row
    cursor = db.cursor()

    # Handle potential re‐issuances.
    issuances = api.get_issuances(validity='Valid', asset_id=asset_id)
    if issuances:
        if issuances[0]['issuer'] != source:
            raise exceptions.IssuanceError('Asset exists and was not issuanced by this address.')
        if issuances[0]['divisible'] != divisible:
            raise exceptions.IssuanceError('That asset exists with a different divisibility.')

    if not amount:
        raise exceptions.UselessError('Zero amount.')

    data = config.PREFIX + struct.pack(config.TXTYPE_FORMAT, ID)
    data += struct.pack(FORMAT, asset_id, amount, divisible)
    db.close()
    return bitcoin.transaction(source, None, None, config.MIN_FEE, data)

def parse (db, cursor, tx, message):
    # Ask for forgiveness…
    validity = 'Valid'

    # Unpack message.
    try:
        asset_id, amount, divisible = struct.unpack(FORMAT, message)
    except Exception:
        asset_id, amount, divisible = None, None, None
        validity = 'Invalid: could not unpack'

    if validity == 'Valid':
        if not amount:
            validity = 'Invalid: zero amount.'

    # If re‐issuance, check for compatability in divisibility, issuer.
    issuances = api.get_issuances(validity='Valid', asset_id=asset_id)
    if issuances:
        if issuances[0]['issuer'] != tx['source']:
            validity = 'Invalid: that asset already exists and was not issuanced by this address'
        if validity == 'Valid' and issuance['divisible'] != divisible:
            validity = 'Invalid: asset exists with a different divisibility'

    # Credit.
    if validity == 'Valid':
        cursor = util.credit(db, cursor, tx['source'], asset_id, amount)
        if divisible: divisibility = 'divisible'
        else: divisibility = 'indivisible'
        logging.info('(Re‐)Issuance: {} created {} of {} asset {} ({})'.format(tx['source'], util.devise(amount, asset_id, 'output'), divisibility, asset_id, util.short(tx['tx_hash'])))

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

    return cursor

# vim: tabstop=8 expandtab shiftwidth=4 softtabstop=4
