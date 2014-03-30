#! /usr/bin/python3

"""Pay out dividends."""

import struct
import decimal
D = decimal.Decimal

from . import (util, config, exceptions, bitcoin, util)

FORMAT_1 = '>QQ'
LENGTH_1 = 8 + 8
FORMAT_2 = '>QQQ'
LENGTH_2 = 8 + 8 + 8
ID = 50


def validate (db, source, quantity_per_unit, asset, dividend_asset, block_index=None):
    if not block_index: block_index = util.last_block(db)['block_index']

    problems = []

    if asset in ('BTC', 'XCP'):
        problems.append('cannot pay dividends to holders of BTC or XCP')

    if quantity_per_unit <= 0: problems.append('non‐positive quantity per unit')

    # Examine asset.
    issuances = util.get_issuances(db, status='valid', asset=asset)
    if not issuances:
        problems.append('no such asset, {}.'.format(asset))
        return None, None, problems
    divisible = issuances[0]['divisible']

    # Examine dividend asset.
    if dividend_asset in ('BTC', 'XCP'):
        dividend_divisible = True
    else:
        issuances = util.get_issuances(db, status='valid', asset=dividend_asset)
        if not issuances:
            problems.append('no such dividend asset, {}.'.format(dividend_asset))
            return None, None, problems
        dividend_divisible = issuances[0]['divisible']

    outputs = []
    cursor = db.cursor()
    # Balances
    cursor.execute('''SELECT * FROM balances \
                      WHERE asset = ?''', (asset,))
    for balance in list(cursor):
        outputs.append({'address': balance['address'], 'address_quantity': balance['quantity']})
    if block_index >= 295000 or config.TESTNET:
        # Funds escrowed in orders. (Protocol change.)
        cursor.execute('''SELECT * FROM orders \
                          WHERE give_asset = ?''', (asset,))
        for order in list(cursor):
            outputs.append({'address': order['source'], 'address_quantity': order['give_quantity']})
        # Funds escrowed in pending order matches. (Protocol change.)
        cursor.execute('''SELECT * FROM order_matches \
                          WHERE (status = ? AND forward_asset = ?)''', ('pending', asset))
        for order_match in list(cursor):
            outputs.append({'address': order_match['tx0_address'], 'address_quantity': order_match['forward_quantity']})
        cursor.execute('''SELECT * FROM order_matches \
                          WHERE (status = ? AND backward_asset = ?)''', ('pending', asset))
        for order_match in list(cursor):
            outputs.append({'address': order_match['tx1_address'], 'address_quantity': order_match['backward_quantity']})
    cursor.close()

    # Calculate actual dividend quantities.
    for output in outputs:
        dividend_quantity = output['address_quantity'] * quantity_per_unit
        if divisible: dividend_quantity /= config.UNIT
        if not dividend_divisible: dividend_quantity /= config.UNIT
        if dividend_asset == 'BTC' and dividend_quantity < config.MULTISIG_DUST_SIZE:  continue    # A bit hackish.
        dividend_quantity = int(dividend_quantity)
        output['dividend_quantity'] = dividend_quantity

    dividend_total = sum([output['dividend_quantity'] for output in outputs])
    if not dividend_total: problems.append('zero dividend')

    if dividend_asset != 'BTC':
        balances = util.get_balances(db, address=source, asset=dividend_asset)
        if not balances or balances[0]['quantity'] < dividend_total:
            problems.append('insufficient funds')

    return dividend_total, outputs, problems

def compose (db, source, quantity_per_unit, asset, dividend_asset):

    dividend_total, outputs, problems = validate(db, source, quantity_per_unit, asset, dividend_asset)
    if problems: raise exceptions.DividendError(problems)
    print('Total quantity to be distributed in dividends:', util.devise(db, dividend_total, dividend_asset, 'output'), dividend_asset)

    if dividend_asset == 'BTC':
        return (source, [(output['address'], output['dividend_quantity']) for output in outputs], config.MIN_FEE, None)

    asset_id = util.get_asset_id(asset)
    dividend_asset_id = util.get_asset_id(dividend_asset)
    data = config.PREFIX + struct.pack(config.TXTYPE_FORMAT, ID)
    data += struct.pack(FORMAT_2, quantity_per_unit, asset_id, dividend_asset_id)
    return (source, [], config.MIN_FEE, data)

def parse (db, tx, message):
    dividend_parse_cursor = db.cursor()

    # Unpack message.
    try:
        if (tx['block_index'] > 288150 or config.TESTNET) and len(message) == LENGTH_2:
            quantity_per_unit, asset_id, dividend_asset_id = struct.unpack(FORMAT_2, message)
            asset = util.get_asset_name(asset_id)
            dividend_asset = util.get_asset_name(dividend_asset_id)
            status = 'valid'
        elif len(message) == LENGTH_1:
            quantity_per_unit, asset_id = struct.unpack(FORMAT_1, message)
            asset = util.get_asset_name(asset_id)
            dividend_asset = 'XCP'
            status = 'valid'
        else:
            raise Exception
    except (AssertionError, struct.error) as e:
        quantity_per_unit, asset = None, None
        status = 'invalid: could not unpack'

    if dividend_asset == 'BTC':
        status = 'invalid: cannot pay BTC dividends within protocol'

    if status == 'valid':
        # For SQLite3
        quantity_per_unit = min(quantity_per_unit, config.MAX_INT)

        dividend_total, outputs, problems = validate(db, tx['source'], quantity_per_unit, asset, dividend_asset, block_index=tx['block_index'])
        if problems: status = 'invalid: ' + '; '.join(problems)

    if status == 'valid':
        # Debit.
        util.debit(db, tx['block_index'], tx['source'], dividend_asset, dividend_total)

        # Credit.
        for output in outputs:
            util.credit(db, tx['block_index'], output['address'], dividend_asset, output['dividend_quantity'])

    # Add parsed transaction to message-type–specific table.
    bindings = {
        'tx_index': tx['tx_index'],
        'tx_hash': tx['tx_hash'],
        'block_index': tx['block_index'],
        'source': tx['source'],
        'asset': asset,
        'dividend_asset': dividend_asset,
        'quantity_per_unit': quantity_per_unit,
        'status': status,
    }
    sql='insert into dividends values(:tx_index, :tx_hash, :block_index, :source, :asset, :dividend_asset, :quantity_per_unit, :status)'
    dividend_parse_cursor.execute(sql, bindings)

    dividend_parse_cursor.close()

# vim: tabstop=8 expandtab shiftwidth=4 softtabstop=4
