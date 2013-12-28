#! /usr/bin/python3

import struct
import logging
import decimal
D = decimal.Decimal

from . import (config, util, exceptions, bitcoin, util)

FORMAT = '>QQ?'
ID = 20
LENGTH = 8 + 8 + 1

def create (db, source, asset_id, amount, divisible, test=False):
    # Handle potential re‐issuances.
    issuances = util.get_issuances(db, validity='Valid', asset_id=asset_id)
    if issuances:
        if issuances[0]['issuer'] != source:
            raise exceptions.IssuanceError('Asset exists and was not issuanced by this address.')
        if issuances[0]['divisible'] != divisible:
            raise exceptions.IssuanceError('That asset exists with a different divisibility.')

    if not asset_id > 49**3:
        raise execeptions.AssetError('Asset ID must be greater than 49^3.')

    if not amount:
        raise exceptions.UselessError('Zero amount.')

    data = config.PREFIX + struct.pack(config.TXTYPE_FORMAT, ID)
    data += struct.pack(FORMAT, asset_id, amount, divisible)
    return bitcoin.transaction(source, None, None, config.MIN_FEE, data, test)

def parse (db, tx, message):
    issuance_parse_cursor = db.cursor()

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

    if validity and not asset_id > 49**3:
        validity = 'Invalid: bad Asset ID'

    # If re‐issuance, check for compatability in divisibility, issuer.
    issuances = util.get_issuances(db, validity='Valid', asset_id=asset_id)
    if issuances:
        if issuances[0]['issuer'] != tx['source']:
            validity = 'Invalid: that asset already exists and was not issuanced by this address'
        if validity == 'Valid' and issuance['divisible'] != divisible:
            validity = 'Invalid: asset exists with a different divisibility'

    # Credit.
    if validity == 'Valid':
        util.credit(db, tx['source'], asset_id, amount)
        if divisible:
            divisibility = 'divisible'
            unit = config.UNIT
        else:
            divisibility = 'indivisible'
            unit = 1
        logging.info('(Re‐)Issuance: {} created {} of {} asset {} ({})'.format(tx['source'], D(amount / unit).quantize(config.EIGHT).normalize(), divisibility, util.get_asset_name(asset_id), util.short(tx['tx_hash'])))

    # Add parsed transaction to message‐type–specific table.
    issuance_parse_cursor.execute('''INSERT INTO issuances(
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

    issuance_parse_cursor.close()

# vim: tabstop=8 expandtab shiftwidth=4 softtabstop=4
