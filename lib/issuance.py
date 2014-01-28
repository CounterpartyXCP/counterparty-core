#! /usr/bin/python3

import struct
import logging
import decimal
D = decimal.Decimal

from . import (config, util, exceptions, bitcoin, util)

FORMAT = '>QQ?'
ID = 20
LENGTH = 8 + 8 + 1

def validate (db, source, destination, asset, amount, divisible, block_index=None):
    problems = []

    if not util.valid_asset_name(asset):
        problems.append('bad asset name')
    if asset in ('BTC', 'XCP'):
        problems.append('cannot issue BTC or XCP')

    balances = util.get_balances(db, address=source, asset='XCP')
    if (block_index and block_index > 281236) and (not balances or balances[0]['amount'] < config.ISSUANCE_FEE):
        problems.append('insufficient funds')

    # Valid re-issuance?
    issuances = util.get_issuances(db, validity='Valid', asset=asset)
    if issuances:
        last_issuance = issuances[-1]
        if last_issuance['issuer'] != source:
            problems.append('asset exists and was not issued by this address')
        elif last_issuance['divisible'] != divisible:
            problems.append('asset exists with a different divisibility')
        elif not last_issuance['amount'] and not last_issuance['transfer']:
            problems.append('asset is locked')
    elif not amount:
        problems.append('cannot lock or transfer an unissued asset')

    # For SQLite3
    total = sum([issuance['amount'] for issuance in issuances])
    assert isinstance(amount, int)
    if total + amount > config.MAX_INT:
        problems.append('maximum total quantity exceeded')

    if destination and amount:
        problems.append('cannot issue and transfer simultaneously')
 
    return problems

def create (db, source, destination, asset, amount, divisible, unsigned=False):
    problems = validate(db, source, destination, asset, amount, divisible)
    if problems: raise exceptions.IssuanceError(problems)

    asset_id = util.get_asset_id(asset)
    data = config.PREFIX + struct.pack(config.TXTYPE_FORMAT, ID)
    data += struct.pack(FORMAT, asset_id, amount, divisible)
    return bitcoin.transaction(source, None, None, config.MIN_FEE, data, unsigned=unsigned)

def parse (db, tx, message):
    issuance_parse_cursor = db.cursor()

    # Unpack message.
    try:
        asset_id, amount, divisible = struct.unpack(FORMAT, message)
        asset = util.get_asset_name(asset_id)
        validity = 'Valid'
    except Exception:
        asset, amount, divisible = None, None, None
        validity = 'Invalid: could not unpack'

    if validity == 'Valid':
        problems = validate(db, tx['source'], tx['destination'], asset, amount, divisible, block_index=tx['block_index'])
        if problems: validity = 'Invalid: ' + ';'.join(problems)
        if 'maximum total quantity exceeded' in problems:
            amount = 0

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
        
    if validity == 'Valid':
        # Debit fee.
        # TODO: Add amount destroyed to table.
        if amount and tx['block_index'] > 281236:
            util.debit(db, tx['block_index'], tx['source'], 'XCP', config.ISSUANCE_FEE)

        # Credit.
        if validity == 'Valid' and amount:
            util.credit(db, tx['block_index'], tx['source'], asset, amount)

        # Log.
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
