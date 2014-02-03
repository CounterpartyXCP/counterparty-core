#! /usr/bin/python3

"""Pay out dividends."""

import struct
import logging
import decimal
D = decimal.Decimal

from . import (util, config, exceptions, bitcoin, util)

FORMAT = '>QQ'
LENGTH = 8 + 8
ID = 50


def validate (db, source, amount_per_share, asset):
    problems = []

    if asset in ('BTC', 'XCP'):
        problems.append('cannot send dividends to BTC or XCP')

    if not amount_per_share:
        problems.append('zero amount per share')

    issuances = util.get_issuances(db, validity='Valid', asset=asset)
    if not issuances:
        problems.append('no such asset, {}.'.format(asset))
        return None, problems

    # This is different from the way callbacks are done.
    divisible = issuances[0]['divisible']
    if divisible:
        total_shares = sum([issuance['amount'] for issuance in issuances]) / config.UNIT
    else:
        total_shares = sum([issuance['amount'] for issuance in issuances])
    amount = round(amount_per_share * total_shares)

    if not amount: problems.append('dividend too small')

    balances = util.get_balances(db, address=source, asset='XCP')
    if not balances or balances[0]['amount'] < amount:
        problems.append('insufficient funds')

    return amount, problems

def create (db, source, amount_per_share, asset, unsigned=False):
    amount, problems = validate(db, source, amount_per_share, asset)
    if problems: raise exceptions.DividendError(problems)
    print('Total amount to be distributed in dividends:', util.devise(db, amount, 'XCP', 'output'), 'XCP')

    asset_id = util.get_asset_id(asset)
    data = config.PREFIX + struct.pack(config.TXTYPE_FORMAT, ID)
    data += struct.pack(FORMAT, amount_per_share, asset_id)
    return bitcoin.transaction(source, None, None, config.MIN_FEE, data, unsigned=unsigned)

def parse (db, tx, message):
    dividend_parse_cursor = db.cursor()

    # Unpack message.
    try:
        assert len(message) == LENGTH
        amount_per_share, asset_id = struct.unpack(FORMAT, message)
        asset = util.get_asset_name(asset_id)
        validity = 'Valid'
    except struct.error as e:
        amount_per_share, asset = None, None
        validity = 'Invalid: could not unpack'

    if validity == 'Valid':
        # For SQLite3
        amount_per_share = min(amount_per_share, config.MAX_INT)

        amount, problems = validate(db, tx['source'], amount_per_share, asset)
        if problems: validity = 'Invalid: ' + ';'.join(problems)

    if validity == 'Valid':
        # Debit.
        util.debit(db, tx['block_index'], tx['source'], 'XCP', amount)

        # Credit.
        issuances = util.get_issuances(db, validity='Valid', asset=asset)
        divisible = issuances[0]['divisible']
        balances = util.get_balances(db, asset=asset)
        for balance in balances:
            address, address_amount = balance['address'], balance['amount']
            if divisible:   # Pay per output unit.
                address_amount = round(D(address_amount) / config.UNIT)
            amount = address_amount * amount_per_share
            util.credit(db, tx['block_index'], address, 'XCP', amount)

    # Add parsed transaction to message-type–specific table.
    element_data = {
        'tx_index': tx['tx_index'],
        'tx_hash': tx['tx_hash'],
        'block_index': tx['block_index'],
        'source': tx['source'],
        'asset': asset,
        'amount_per_share': amount_per_share,
        'validity': validity,
    }
    dividend_parse_cursor.execute(*util.get_insert_sql('dividends', element_data))


    if validity == 'Valid':
        logging.info('Dividend: {} paid {} per share of asset {} ({})'.format(tx['source'], util.devise(db, amount_per_share, 'XCP', 'output'), asset, tx['tx_hash']))

    dividend_parse_cursor.close()

# vim: tabstop=8 expandtab shiftwidth=4 softtabstop=4
