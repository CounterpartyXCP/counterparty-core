#! /usr/bin/python3

import struct
import logging
import decimal
D = decimal.Decimal

from . import (config, util, exceptions, bitcoin, util)

FORMAT = '>QQ?'
ID = 20
LENGTH = 8 + 8 + 1

def create (db, source, destination, asset, amount, divisible, test=False, unsigned=False):
    if not util.valid_asset_name(asset):
        raise exceptions.AssetError('Bad asset name.')
    if asset in ('BTC', 'XCP'):
            raise exceptions.IssuanceError('Cannot issue BTC or XCP.')

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

    # For SQLite3
    total = sum([issuance['amount'] for issuance in issuances])
    assert isinstance(amount, int)
    if total + amount > config.MAX_INT:
        raise exceptions.IssuanceError('Maximum total quantity exceeded.')

    if destination and amount:
        raise exceptions.IssuanceError('Cannot issue and transfer simultaneously.')
        
    asset_id = util.get_asset_id(asset)
    data = config.PREFIX + struct.pack(config.TXTYPE_FORMAT, ID)
    data += struct.pack(FORMAT, asset_id, amount, divisible)
    return bitcoin.transaction(source, None, None, config.MIN_FEE, data, test=test, unsigned=unsigned)

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

    # For SQLite3
    total = sum([issuance['amount'] for issuance in issuances])
    if total + amount > config.MAX_INT:
        amount = 0
        if validity == 'Valid':
            validity = 'Invalid: exceeded maximum total quantity'

    if validity == 'Valid' and asset in ('BTC', 'XCP'):
        validity = 'Invalid: cannot issue BTC or XCP'

    if validity == 'Valid' and (tx['destination'] and amount):
        validity = 'Invalid: cannot issue and transfer simultaneously'

    if tx['destination']:
        issuer = tx['destination']
        transfer = True
    else:
        issuer = tx['source']
        transfer = False

    # Add parsed transaction to message-type–specific table.
    element_data = {
        'tx_index': tx['tx_index'],
        'tx_hash': tx['tx_hash'],
        'block_index': tx['block_index'],
        'asset': asset,
        'amount': amount,
        'divisible': divisible,
        'issuer': issuer,
        'transfer': transfer,
        'validity': validity,
    }
    issuance_parse_cursor.execute(*util.get_insert_sql('issuances', element_data))
    config.zeromq_publisher.push_to_subscribers('new_issuance', element_data)
        
    # Debit fee.
    # TODO: Add amount destroyed to table.
    if validity == 'Valid' and amount and tx['block_index'] > 281236:
        validity = util.debit(db, tx['source'], 'XCP', 5)

    # Credit.
    if validity == 'Valid' and amount:
        util.credit(db, tx['source'], asset, amount)

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
