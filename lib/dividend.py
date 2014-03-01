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


def validate (db, source, amount_per_unit, asset, dividend_asset):
    problems = []

    if asset in ('BTC', 'XCP'):
        problems.append('cannot send dividends to BTC or XCP')

    if not amount_per_unit:
        problems.append('zero amount per unit')

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
    balances = util.get_balances(db, asset=asset)       # + util.get_escrowed(db, asset=asset)
    for balance in balances:
        address, address_amount = balance['address'], balance['amount']
        dividend_amount = address_amount * amount_per_unit
        if divisible: dividend_amount /= config.UNIT
        if not dividend_divisible: dividend_amount /= config.UNIT
        dividend_amount = int(dividend_amount)
        outputs.append({'address': address, 'dividend_amount': dividend_amount})

    dividend_total = sum([output['dividend_amount'] for output in outputs])
    if not dividend_total: problems.append('zero dividend')

    balances = util.get_balances(db, address=source, asset=dividend_asset)
    if not balances or balances[0]['amount'] < dividend_total:
        problems.append('insufficient funds')

    return dividend_total, outputs, problems

def compose (db, source, amount_per_unit, asset, dividend_asset):

    dividend_total, outputs, problems = validate(db, source, amount_per_unit, asset, dividend_asset)
    if problems: raise exceptions.DividendError(problems)
    print('Total amount to be distributed in dividends:', util.devise(db, dividend_total, dividend_asset, 'output'), dividend_asset)

    if dividend_asset == 'BTC':
        print(outputs)
        exit(0) # TODO

    asset_id = util.get_asset_id(asset)
    dividend_asset_id = util.get_asset_id(dividend_asset)
    data = config.PREFIX + struct.pack(config.TXTYPE_FORMAT, ID)
    data += struct.pack(FORMAT_2, amount_per_unit, asset_id, dividend_asset_id)
    return (source, None, None, config.MIN_FEE, data)

def parse (db, tx, message):
    dividend_parse_cursor = db.cursor()

    # Unpack message.
    try:
        if (tx['block_index'] > 288150 or config.TESTNET) and len(message) == LENGTH_2:
            amount_per_unit, asset_id, dividend_asset_id = struct.unpack(FORMAT_2, message)
            asset = util.get_asset_name(asset_id)
            dividend_asset = util.get_asset_name(dividend_asset_id)
            status = 'valid'
        elif len(message) == LENGTH_1:
            amount_per_unit, asset_id = struct.unpack(FORMAT_1, message)
            asset = util.get_asset_name(asset_id)
            dividend_asset = 'XCP'
            status = 'valid'
        else:
            raise Exception
    except (struct.error, Exception) as e:
        amount_per_unit, asset = None, None
        status = 'invalid: could not unpack'

    if status == 'valid':
        # For SQLite3
        amount_per_unit = min(amount_per_unit, config.MAX_INT)

        dividend_total, outputs, problems = validate(db, tx['source'], amount_per_unit, asset, dividend_asset)
        if problems: status = 'invalid: ' + ';'.join(problems)

    if status == 'valid':
        # Debit.
        util.debit(db, tx['block_index'], tx['source'], dividend_asset, dividend_total)

        # Credit.
        for output in outputs:
            util.credit(db, tx['block_index'], output['address'], dividend_asset, output['dividend_amount'])

    # Add parsed transaction to message-type–specific table.
    bindings = {
        'tx_index': tx['tx_index'],
        'tx_hash': tx['tx_hash'],
        'block_index': tx['block_index'],
        'source': tx['source'],
        'asset': asset,
        'dividend_asset': dividend_asset,
        'amount_per_unit': amount_per_unit,
        'status': status,
    }
    sql='insert into dividends values(:tx_index, :tx_hash, :block_index, :source, :asset, :dividend_asset, :amount_per_unit, :status)'
    dividend_parse_cursor.execute(sql, bindings)

    dividend_parse_cursor.close()

# vim: tabstop=8 expandtab shiftwidth=4 softtabstop=4
