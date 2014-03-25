#! /usr/bin/python3

"""Callback a callable asset."""

import struct
import decimal
D = decimal.Decimal

from . import (util, config, exceptions, bitcoin, util)

FORMAT = '>dQ'
LENGTH = 8 + 8
ID = 21


def validate (db, source, fraction, asset, block_time):
    problems = []

    if fraction > 1:
        problems.append('fraction greater than one')
    elif fraction <= 0:
        problems.append('non‐positive fraction')

    issuances = util.get_issuances(db, status='valid', asset=asset)
    if not issuances:
        problems.append('no such asset, {}.'.format(asset))
        return None, None, None, problems
    else:
        last_issuance = issuances[-1]
        if block_time == None:  # For composition only.
            block_time = util.last_block(db)['block_time']

        if last_issuance['issuer'] != source:
            problems.append('not asset owner')
            return None, None, None, problems

        if not last_issuance['callable']:
            problems.append('uncallable asset')
            return None, None, None, problems
        elif last_issuance['call_date'] > block_time: problems.append('before call date')

        call_price = round(last_issuance['call_price'], 6)  # TODO: arbitrary
        divisible = last_issuance['divisible']

    if not divisible:   # Pay per output unit.
        call_price *= config.UNIT

    outputs = []
    balances = util.get_balances(db, asset=asset)
    for balance in balances:
        address, address_quantity = balance['address'], balance['quantity']
        if address == source or address_quantity == 0: continue
        callback_quantity = int(address_quantity * fraction)   # Round down.
        fraction_actual = callback_quantity / address_quantity
        outputs.append({'address': address, 'callback_quantity': callback_quantity, 'fraction_actual': fraction_actual})

    callback_total = sum([output['callback_quantity'] for output in outputs])
    if not callback_total: problems.append('nothing called back')

    balances = util.get_balances(db, address=source, asset='XCP')
    if not balances or balances[0]['quantity'] < (call_price * callback_total):
        problems.append('insufficient funds')

    return call_price, callback_total, outputs, problems

def compose (db, source, fraction, asset):
    call_price, callback_total, outputs, problems = validate(db, source, fraction, asset, None)
    if problems: raise exceptions.CallbackError(problems)
    print('Total quantity to be called back:', util.devise(db, callback_total, asset, 'output'), asset)

    asset_id = util.get_asset_id(asset)
    data = config.PREFIX + struct.pack(config.TXTYPE_FORMAT, ID)
    data += struct.pack(FORMAT, fraction, asset_id)
    return (source, [], config.MIN_FEE, data)

def parse (db, tx, message):
    callback_parse_cursor = db.cursor()

    # Unpack message.
    try:
        assert len(message) == LENGTH
        fraction, asset_id = struct.unpack(FORMAT, message)
        asset = util.get_asset_name(asset_id)
        status = 'valid'
    except (AssertionError, struct.error) as e:
        fraction, asset = None, None
        status = 'invalid: could not unpack'

    if status == 'valid':
        call_price, callback_total, outputs, problems = validate(db, tx['source'], fraction, asset, tx['block_time'])
        if problems: status = 'invalid: ' + ';'.join(problems)

    if status == 'valid':
        # Issuer.
        assert call_price * callback_total == int(call_price * callback_total)
        util.debit(db, tx['block_index'], tx['source'], 'XCP', int(call_price * callback_total))
        util.credit(db, tx['block_index'], tx['source'], asset, callback_total)

        # Holders.
        for output in outputs:
            assert call_price * output['callback_quantity'] == int(call_price * output['callback_quantity'])
            util.debit(db, tx['block_index'], output['address'], asset, output['callback_quantity'])
            util.credit(db, tx['block_index'], output['address'], 'XCP', int(call_price * output['callback_quantity']))

    # Add parsed transaction to message-type–specific table.
    bindings = {
        'tx_index': tx['tx_index'],
        'tx_hash': tx['tx_hash'],
        'block_index': tx['block_index'],
        'source': tx['source'],
        'fraction': fraction,
        'asset': asset,
        'status': status,
    }
    sql='insert into callbacks values(:tx_index, :tx_hash, :block_index, :source, :fraction, :asset, :status)'
    callback_parse_cursor.execute(sql, bindings)

    callback_parse_cursor.close()

# vim: tabstop=8 expandtab shiftwidth=4 softtabstop=4
