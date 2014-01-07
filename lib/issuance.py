#! /usr/bin/python3

import struct
import logging
import decimal
D = decimal.Decimal

from . import (config, util, exceptions, bitcoin, util)

FORMAT = '>QQ?'
ID = 20
LENGTH = 8 + 8 + 1

def create (db, source, destination, asset, amount, divisible, test=False):

    if not util.valid_asset_name(asset):
        raise exceptions.AssetError('Bad asset name.')

    # Valid re-issuance?
    issuances = util.get_issuances(db, validity='Valid', asset=asset)
    if issuances:
        last_issuance = issuances[-1]
        if last_issuance['issuer'] != source:
            raise exceptions.IssuanceError('Asset exists and was not issued by this address.')
        elif last_issuance['divisible'] != divisible:
            raise exceptions.IssuanceError('Asset exists with a different divisibility.')
        elif not last_issuance['amount'] and not last_issuance['transfer']:
            raise exceptions.IssuanceError('Asset is locked.')
    elif not amount:
        raise exceptions.IssuanceError('Cannot lock or transfer an unissued asset.')
        
    if destination and amount:
        raise exceptions.IssuanceError('Cannot issue and transfer simultaneously.')
        
    asset_id = util.get_asset_id(asset)
    data = config.PREFIX + struct.pack(config.TXTYPE_FORMAT, ID)
    data += struct.pack(FORMAT, asset_id, amount, divisible)
    return bitcoin.transaction(source, None, None, config.MIN_FEE, data, test)

def parse (db, tx, message):
    issuance_parse_cursor = db.cursor()
    validity = 'Valid'

    # Unpack message.
    try:
        asset_id, amount, divisible = struct.unpack(FORMAT, message)
        asset = util.get_asset_name(asset_id)
    except Exception:
        asset, amount, divisible = None, None, None
        validity = 'Invalid: could not unpack'

    if validity == 'Valid' and not util.valid_asset_name(asset):
        validity = 'Invalid: bad asset name'

    # Valid re-issuance?
    if validity == 'Valid':
        issuances = util.get_issuances(db, validity='Valid', asset=asset)
        if issuances:
            last_issuance = issuances[-1]
            if last_issuance['issuer'] != tx['source']:
                validity = 'Invalid: asset already exists and was not issued by this address'
            elif last_issuance['divisible'] != divisible:
                validity = 'Invalid: asset exists with a different divisibility'
            elif not last_issuance['amount'] and not last_issuance['transfer']:
                validity = 'Invalid: asset is locked'
        elif not amount:
            validity = 'Invalid: cannot lock or transfer an unissued asset'

    if tx['destination'] and amount:
        validity = 'Invalid: cannot issue and transfer simultaneously'
        
    # Credit.
    if validity == 'Valid' and amount:
        util.credit(db, tx['source'], asset, amount)

    if tx['destination']:
        issuer = tx['destination']
        transfer = True
    else:
        issuer = tx['source']
        transfer = False

    # Add parsed transaction to message-type–specific table.
    issuance_parse_cursor.execute('''INSERT INTO issuances(
                        tx_index,
                        tx_hash,
                        block_index,
                        asset,
                        amount,
                        divisible,
                        issuer,
                        transfer,
                        validity) VALUES(?,?,?,?,?,?,?,?,?)''',
                        (tx['tx_index'],
                        tx['tx_hash'],
                        tx['block_index'],
                        asset,
                        amount,
                        divisible,
                        issuer,
                        transfer,
                        validity)
                  )

    # Log.
    if validity == 'Valid':
        if tx['destination']:
            logging.info('Issuance: {} transfered asset {} to {} ({})'.format(tx['source'], asset, tx['destination'], util.short(tx['tx_hash'])))
        elif not amount:
            logging.info('Issuance: {} locked asset {} ({})'.format(tx['source'], asset, util.short(tx['tx_hash'])))
        else:
            if divisible:
                divisibility = 'divisible'
                unit = config.UNIT
            else:
                divisibility = 'indivisible'
                unit = 1
            logging.info('Issuance: {} created {} of {} asset {} ({})'.format(tx['source'], util.devise(db, amount, None, 'output', divisible=divisible), divisibility, asset, util.short(tx['tx_hash'])))

    issuance_parse_cursor.close()

# vim: tabstop=8 expandtab shiftwidth=4 softtabstop=4
