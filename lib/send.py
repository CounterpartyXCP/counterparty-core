#! /usr/bin/python3

"""Create and parse 'send'-type messages."""

import struct
import logging

from . import (util, config, exceptions, bitcoin, util)

FORMAT = '>QQ'
ID = 0
LENGTH = 8 + 8

def create (db, source, destination, amount, asset, test=False):
    if asset == 'BTC': raise exceptions.BalanceError('Cannot send bitcoins.')
    if not amount: raise exceptions.UselessError('Zero quantity.')

    balances = util.get_balances(db, address=source, asset=asset)
    if not balances or balances[0]['amount'] < amount:
        raise exceptions.BalanceError('Insufficient funds. (Check that the database is up-to-date.)')

    asset_id = util.get_asset_id(asset)
    data = config.PREFIX + struct.pack(config.TXTYPE_FORMAT, ID)
    data += struct.pack(FORMAT, asset_id, amount)
    return bitcoin.transaction(source, destination, config.DUST_SIZE, config.MIN_FEE, data, test)

def parse (db, tx, message):
    send_parse_cursor = db.cursor()

    # Ask for forgiveness…
    validity = 'Valid'

    # Unpack message.
    try:
        asset_id, amount = struct.unpack(FORMAT, message)
        asset = util.get_asset_name(asset_id)
    except Exception:
        asset, amount = None, None
        validity = 'Invalid: could not unpack'

    # Check that it is not BTC that someone was trying to send.
    if validity == 'Valid':
        if asset == 'BTC':
            validity = 'Invalid: cannot send bitcoins'
        elif not util.valid_asset_name(asset):
            validity = 'Invalid: bad Asset ID'

    # Debit.
    if validity == 'Valid':
        if not amount:
            validity = 'Invalid: zero quantity.'
        validity = util.debit(db, tx['source'], asset, amount)

    # Credit.
    if validity == 'Valid':
        util.credit(db, tx['destination'], asset, amount)

    # Add parsed transaction to message-type–specific table.
    send_parse_cursor.execute('''INSERT INTO sends(
                        tx_index,
                        tx_hash,
                        block_index,
                        source,
                        destination,
                        asset,
                        amount,
                        validity) VALUES(?,?,?,?,?,?,?,?)''',
                        (tx['tx_index'],
                        tx['tx_hash'],
                        tx['block_index'],
                        tx['source'],
                        tx['destination'],
                        asset,
                        amount,
                        validity)
                  )
    if validity == 'Valid':
        amount = util.devise(db, amount, asset, 'output')
        logging.info('Send: {} of asset {} from {} to {} ({})'.format(amount, asset, tx['source'], tx['destination'], util.short(tx['tx_hash'])))

    send_parse_cursor.close()

# vim: tabstop=8 expandtab shiftwidth=4 softtabstop=4
