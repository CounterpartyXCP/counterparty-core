#! /usr/bin/python3

import struct
import logging
import decimal
D = decimal.Decimal

from . import (config, util, exceptions, bitcoin, util)

FORMAT_1 = '>QQ?'
LENGTH_1 = 8 + 8 + 1
FORMAT_2 = '>QQ??If42p'
LENGTH_2 = 8 + 8 + 1 + 1 + 4 + 4 + 42
ID = 20


def validate (db, source, destination, asset, amount, divisible, callable_, call_date, call_price, description, block_index=None):
    problems = []

    if asset in ('BTC', 'XCP'):
        problems.append('cannot issue BTC or XCP')

    # Valid re-issuance?
    issuances = util.get_issuances(db, validity='Valid', asset=asset)
    if issuances:
        last_issuance = issuances[-1]
        if last_issuance['issuer'] != source:
            problems.append('asset exists and was not issued by this address')
        elif last_issuance['divisible'] != divisible:
            problems.append('asset exists with a different divisibility')
        elif last_issuance['callable'] != callable_ or last_issuance['call_date'] != call_date or last_issuance['call_price'] != call_price:
            problems.append('asset exists with a different callability, call date or call price')
        elif not last_issuance['amount'] and not last_issuance['transfer']:
            problems.append('asset is locked')
    elif not amount:
        problems.append('cannot lock or transfer an unissued asset')

    balances = util.get_balances(db, address=source, asset='XCP')
    if (block_index and block_index > 281236) and (not balances or balances[0]['amount'] < config.ISSUANCE_FEE):
        problems.append('insufficient funds')

    # For SQLite3
    total = sum([issuance['amount'] for issuance in issuances])
    assert isinstance(amount, int)
    if total + amount > config.MAX_INT:
        problems.append('maximum total quantity exceeded')

    if destination and amount:
        problems.append('cannot issue and transfer simultaneously')

    return problems

def create (db, source, destination, asset, amount, divisible, callable_, call_date, call_price, description, unsigned=False):
    problems = validate(db, source, destination, asset, amount, divisible, callable_, call_date, call_price, description)
    if problems: raise exceptions.IssuanceError(problems)

    asset_id = util.get_asset_id(asset)
    data = config.PREFIX + struct.pack(config.TXTYPE_FORMAT, ID)
    data += struct.pack(FORMAT_2, asset_id, amount, divisible, callable_, call_date, call_price, description.encode('utf-8'))
    if len(data) > 80:
        raise exceptions.IssuanceError('Description is greater than 52 bytes.')
    return bitcoin.transaction(source, None, None, config.MIN_FEE, data, unsigned=unsigned)

def parse (db, tx, message):
    issuance_parse_cursor = db.cursor()

    # Unpack message.
    try:
        if (tx['block_index'] > 283271 or config.TESTNET) and len(message) == LENGTH_2:
            asset_id, amount, divisible, callable_, call_date, call_price, description = struct.unpack(FORMAT_2, message)
            call_price = round(call_price, 6) # TODO: arbitrary
            try:
                description = description.decode('utf-8')
            except UnicodeDecodeError:
                description = ''
        else:
            asset_id, amount, divisible = struct.unpack(FORMAT_1, message)
            callable_, call_date, call_price, description = None, None, None, ''
        try:
            asset = util.get_asset_name(asset_id)
        except:
            validity = 'Invalid: bad asset name'
        validity = 'Valid'
    except struct.error:
        asset, amount, divisible, callable_, call_date, call_price, description = None, None, None, None, None, None, None
        validity = 'Invalid: could not unpack'

    if validity == 'Valid':
        problems = validate(db, tx['source'], tx['destination'], asset, amount, divisible, callable_, call_date, call_price, description, block_index=tx['block_index'])
        if problems: validity = 'Invalid: ' + ';'.join(problems)
        if 'maximum total quantity exceeded' in problems:
            amount = 0

    if tx['destination']:
        issuer = tx['destination']
        transfer = True
    else:
        issuer = tx['source']
        transfer = False

    fee_paid = None
    if validity == 'Valid':
        # Debit fee.
        if amount and tx['block_index'] > 281236:
            util.debit(db, tx['block_index'], tx['source'], 'XCP', config.ISSUANCE_FEE)
            fee_paid = config.ISSUANCE_FEE
        else:
            fee_paid = 0

        # Credit.
        if validity == 'Valid' and amount:
            util.credit(db, tx['block_index'], tx['source'], asset, amount, divisible=divisible)

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
        'callable': callable_,
        'call_date': call_date,
        'call_price': call_price,
        'description': description,
        'fee_paid': fee_paid,
        'validity': validity,
    }
    issuance_parse_cursor.execute(*util.get_insert_sql('issuances', element_data))


    if validity == 'Valid':
        # Log.
        if tx['destination']:
            logging.info('Issuance: {} transfered asset {} to {} ({})'.format(tx['source'], asset, tx['destination'], tx['tx_hash']))
        elif not amount:
            logging.info('Issuance: {} locked asset {} ({})'.format(tx['source'], asset, tx['tx_hash']))
        else:
            if divisible:
                divisibility = 'divisible'
                unit = config.UNIT
            else:
                divisibility = 'indivisible'
                unit = 1
            if callable_ and (tx['block_index'] > 283271 or config.TESTNET) and len(message) == LENGTH_2:
                callability = 'callable from {} for {} XCP/{}'.format(util.isodt(call_date), call_price, asset)
            else:
                callability = 'uncallable'
            logging.info('Issuance: {} created {} of {} asset {}, which is {}, with description ‘{}’ ({})'.format(tx['source'], util.devise(db, amount, None, 'output', divisible=divisible), divisibility, asset, callability, description, tx['tx_hash']))

    issuance_parse_cursor.close()

# vim: tabstop=8 expandtab shiftwidth=4 softtabstop=4
