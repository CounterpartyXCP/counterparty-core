#! /usr/bin/python3

"""Pay out dividends."""

import struct
import decimal
D = decimal.Decimal

from . import (util, config, exceptions, bitcoin, util)

FORMAT = '>QQ'
LENGTH = 8 + 8
ID = 50


def validate (db, source, amount_per_unit, asset):
    problems = []

    if asset in ('BTC', 'XCP'):
        problems.append('cannot send dividends to BTC or XCP')

    if not amount_per_unit:
        problems.append('zero amount per unit')

    issuances = util.get_issuances(db, validity='valid', asset=asset)
    if not issuances:
        problems.append('no such asset, {}.'.format(asset))
        return None, problems

    # This is different from the way callbacks are done.
    divisible = issuances[0]['divisible']
    if divisible:
        total_shares = sum([issuance['amount'] for issuance in issuances]) / config.UNIT
    else:
        total_shares = sum([issuance['amount'] for issuance in issuances])
    amount = round(amount_per_unit * total_shares)

    if not amount: problems.append('dividend too small')

    balances = util.get_balances(db, address=source, asset='XCP')
    if not balances or balances[0]['amount'] < amount:
        problems.append('insufficient funds')

    return amount, problems

def create (db, source, amount_per_unit, asset, unsigned=False):
    amount, problems = validate(db, source, amount_per_unit, asset)
    if problems: raise exceptions.DividendError(problems)
    print('Total amount to be distributed in dividends:', util.devise(db, amount, 'XCP', 'output'), 'XCP')

    asset_id = util.get_asset_id(asset)
    data = config.PREFIX + struct.pack(config.TXTYPE_FORMAT, ID)
    data += struct.pack(FORMAT, amount_per_unit, asset_id)
    return bitcoin.transaction(source, None, None, config.MIN_FEE, data, unsigned=unsigned)

def parse (db, tx, message):
    dividend_parse_cursor = db.cursor()

    # Unpack message.
    try:
        assert len(message) == LENGTH
        amount_per_unit, asset_id = struct.unpack(FORMAT, message)
        asset = util.get_asset_name(asset_id)
        validity = 'valid'
    except struct.error as e:
        amount_per_unit, asset = None, None
        validity = 'invalid: could not unpack'

    if validity == 'valid':
        # For SQLite3
        amount_per_unit = min(amount_per_unit, config.MAX_INT)

        amount, problems = validate(db, tx['source'], amount_per_unit, asset)
        if problems: validity = 'invalid: ' + ';'.join(problems)

    if validity == 'valid':
        # Debit.
        util.debit(db, tx['block_index'], tx['source'], 'XCP', amount)

        # Credit.
        issuances = util.get_issuances(db, validity='valid', asset=asset)
        divisible = issuances[0]['divisible']
        balances = util.get_balances(db, asset=asset)
        for balance in balances:
            address, address_amount = balance['address'], balance['amount']
            if divisible:   # Pay per output unit.
                address_amount = round(D(address_amount) / config.UNIT)
            amount = address_amount * amount_per_unit
            util.credit(db, tx['block_index'], address, 'XCP', amount)

    # Add parsed transaction to message-type–specific table.
    bindings = {
        'tx_index': tx['tx_index'],
        'tx_hash': tx['tx_hash'],
        'block_index': tx['block_index'],
        'source': tx['source'],
        'asset': asset,
        'amount_per_unit': amount_per_unit,
        'validity': validity,
    }
    sql='insert into dividends values(:tx_index, :tx_hash, :block_index, :source, :asset, :amount_per_unit, :validity)'
    dividend_parse_cursor.execute(sql, bindings)

    dividend_parse_cursor.close()

# vim: tabstop=8 expandtab shiftwidth=4 softtabstop=4
