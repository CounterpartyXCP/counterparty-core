#! /usr/bin/python3

"""Callback a callable asset."""

import struct
import decimal
D = decimal.Decimal

from . import (util, config, exceptions, bitcoin, util)
from . import order

FORMAT = '>dQ'
LENGTH = 8 + 8
ID = 21


def validate (db, source, fraction, asset, block_time, block_index, parse):
    cursor = db.cursor()
    problems = []

    # TODO
    if not config.TESTNET:
        problems.append('callbacks are currently disabled on mainnet')
        return None, None, None, problems
    # TODO

    if fraction > 1:
        problems.append('fraction greater than one')
    elif fraction <= 0:
        problems.append('non‐positive fraction')

    issuances = list(cursor.execute('''SELECT * FROM issuances WHERE (status = ? AND asset = ?)''', ('valid', asset)))
    if not issuances:
        problems.append('no such asset, {}.'.format(asset))
        return None, None, None, problems
    else:
        last_issuance = issuances[-1]

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

    # If parsing, unescrow all funds of asset. (Order of operations is
    # important here.)
    if parse:

        # Cancel pending order matches involving asset.
        cursor.execute('''SELECT * from order_matches \
                          WHERE status = ? AND (forward_asset = ? OR backward_asset = ?)''', ('pending', asset, asset))
        for order_match in list(cursor):
            order.cancel_order_match(db, order_match, 'cancelled', block_index)

        # Cancel open orders involving asset.
        cursor.execute('''SELECT * from orders \
                          WHERE status = ? AND (give_asset = ? OR get_asset = ?)''', ('open', asset, asset))
        for order_element in list(cursor):
            order.cancel_order(db, order_element, 'cancelled', block_index)

    # Calculate callback quantities.
    holders = util.holders(db, asset)
    outputs = []
    for holder in holders:

        # If composing (and not parsing), predict funds to be returned from
        # escrow (instead of cancelling open offers, etc.), by *not* skipping
        # listing escrowed funds here.
        if parse and holder['escrow']:
            continue

        address = holder['address']
        address_quantity = holder['address_quantity']
        if address == source or address_quantity == 0: continue

        callback_quantity = int(address_quantity * fraction)   # Round down.
        fraction_actual = callback_quantity / address_quantity

        outputs.append({'address': address, 'address_quantity': address_quantity, 'callback_quantity': callback_quantity, 'fraction_actual': fraction_actual})

    callback_total = sum([output['callback_quantity'] for output in outputs])
    if not callback_total: problems.append('nothing called back')

    balances = list(cursor.execute('''SELECT * FROM balances WHERE (address = ? AND asset = ?)''', (source, config.XCP)))
    if not balances or balances[0]['quantity'] < (call_price * callback_total):
        problems.append('insufficient funds')

    cursor.close()
    return call_price, callback_total, outputs, problems

def compose (db, source, fraction, asset):
    call_price, callback_total, outputs, problems = validate(db, source, fraction, asset, util.last_block(db)['block_time'], util.last_block(db)['block_index'], parse=False)
    if problems: raise exceptions.CallbackError(problems)
    print('Total quantity to be called back:', util.devise(db, callback_total, asset, 'output'), asset)

    asset_id = util.asset_id(asset)
    data = config.PREFIX + struct.pack(config.TXTYPE_FORMAT, ID)
    data += struct.pack(FORMAT, fraction, asset_id)
    return (source, [], data)

def parse (db, tx, message):
    callback_parse_cursor = db.cursor()

    # Unpack message.
    try:
        assert len(message) == LENGTH
        fraction, asset_id = struct.unpack(FORMAT, message)
        asset = util.asset_name(asset_id)
        status = 'valid'
    except (AssertionError, struct.error) as e:
        fraction, asset = None, None
        status = 'invalid: could not unpack'

    if status == 'valid':
        call_price, callback_total, outputs, problems = validate(db, tx['source'], fraction, asset, tx['block_time'], tx['block_index'], parse=True)
        if problems: status = 'invalid: ' + '; '.join(problems)

    if status == 'valid':
        # Issuer.
        assert call_price * callback_total == int(call_price * callback_total)
        util.debit(db, tx['block_index'], tx['source'], config.XCP, int(call_price * callback_total))
        util.credit(db, tx['block_index'], tx['source'], asset, callback_total)

        # Holders.
        for output in outputs:
            assert call_price * output['callback_quantity'] == int(call_price * output['callback_quantity'])
            util.debit(db, tx['block_index'], output['address'], asset, output['callback_quantity'])
            util.credit(db, tx['block_index'], output['address'], config.XCP, int(call_price * output['callback_quantity']))

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
