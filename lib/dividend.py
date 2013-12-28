#! /usr/bin/python3

"""Pay out dividends."""

import struct
import logging

from . import (util, config, exceptions, bitcoin, util)

FORMAT = '>QQ'
ID = 50
LENGTH = 8 + 8

def create (db, source, amount_per_share, asset_id, test=False):
    issuances = util.get_issuances(db, validity='Valid', asset_id=asset_id)
    total_shares = sum([issuance['amount'] for issuance in issuances])
    amount = amount_per_share * total_shares
    balances = util.get_balances(db, address=source, asset_id=1)
    print(balances[0]['amount'], amount)
    if not balances or balances[0]['amount'] < amount:
        raise exceptions.BalanceError('Insufficient funds. (Check that the database is up‐to‐date.)')
    if not issuances:
        raise exceptions.DividendError('No such asset: {}.'.format(asset_id))
    # elif issuances[0]['divisible'] == True:
    #     raise exceptions.DividendError('Dividend‐yielding assets must be indivisible.')
    if not amount_per_share:
        raise exceptions.UselessError('Zero amount per share.')
    print('Total amount to be distributed in dividends:', amount / config.UNIT)
    data = config.PREFIX + struct.pack(config.TXTYPE_FORMAT, ID)
    data += struct.pack(FORMAT, amount_per_share, asset_id)
    return bitcoin.transaction(source, None, None, config.MIN_FEE, data, test)

def parse (db, tx, message):
    dividend_parse_cursor = db.cursor()
    # Ask for forgiveness…
    validity = 'Valid'

    # Unpack message.
    try:
        amount_per_share, asset_id = struct.unpack(FORMAT, message)
    except Exception:
        amount_per_share, asset_id = None, None
        validity = 'Invalid: could not unpack'

    if validity == 'Valid':
        if not amount_per_share:
            validity = 'Invalid: zero amount per share.'

    if validity:
        if asset_id in (0, 1):
            validity = 'Invalid: cannot send dividends to BTC or XCP'
        elif not asset_id > 49**3:
            validity = 'Invalid: bad Asset ID'

    # Debit.
    issuances = util.get_issuances(db, validity='Valid', asset_id=asset_id)
    total_shares = sum([issuance['amount'] for issuance in issuances])
    amount = amount_per_share * total_shares
    if validity == 'Valid':
        validity = util.debit(db, tx['source'], 1, amount)

    # Credit.
    if validity == 'Valid':
        balances = util.get_balances(db, asset_id=asset_id)
        for balance in balances:
            address, address_amount = balance['address'], balance['amount']
            util.credit(db, address, 1, address_amount * amount_per_share)

    # Add parsed transaction to message‐type–specific table.
    dividend_parse_cursor.execute('''INSERT INTO dividends(
                        tx_index,
                        tx_hash,
                        block_index,
                        source,
                        asset_id,
                        amount_per_share,
                        validity) VALUES(?,?,?,?,?,?,?)''',
                        (tx['tx_index'],
                        tx['tx_hash'],
                        tx['block_index'],
                        tx['source'],
                        asset_id,
                        amount_per_share,
                        validity)
                  )
    if validity == 'Valid':
        logging.info('Dividend: {} paid {} per share of asset {} ({})'.format(tx['source'], amount_per_share / config.UNIT, util.get_asset_name(asset_id), util.short(tx['tx_hash'])))

    dividend_parse_cursor.close()

# vim: tabstop=8 expandtab shiftwidth=4 softtabstop=4
