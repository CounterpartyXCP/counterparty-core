#! /usr/bin/python3

"""Create and parse ‘send’‐type messages."""

import struct
import logging

from . import (util, config, exceptions, bitcoin, util)

FORMAT = '>QQ'
ID = 0
LENGTH = 8 + 8

def create (db, source, destination, amount, asset_id, test=False):

    # Check that it is not BTC that someone was trying to send.
    if not asset_id: raise exceptions.BalanceError('Cannot send bitcoins.')

    balances = util.get_balances(db, address=source, asset_id=asset_id)
    if not balances or balances[0]['amount'] < amount:
        raise exceptions.BalanceError('Insufficient funds. (Check that the database is up‐to‐date.)')
    if not amount:
        raise exceptions.UselessError('Zero quantity.')

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
    except Exception:
        asset_id, amount = None, None
        validity = 'Invalid: could not unpack'


    # Check that it is not BTC that someone was trying to send.
    if not asset_id:
        validity = 'Invalid: cannot send bitcoins'

    # Debit.
    if validity == 'Valid':
        if not amount:
            validity = 'Invalid: zero quantity.'
        validity = util.debit(db, tx['source'], asset_id, amount)

    # Credit.
    if validity == 'Valid':
        util.credit(db, tx['destination'], asset_id, amount)

    # Add parsed transaction to message‐type–specific table.
    send_parse_cursor.execute('''INSERT INTO sends(
                        tx_index,
                        tx_hash,
                        block_index,
                        source,
                        destination,
                        asset_id,
                        amount,
                        validity) VALUES(?,?,?,?,?,?,?,?)''',
                        (tx['tx_index'],
                        tx['tx_hash'],
                        tx['block_index'],
                        tx['source'],
                        tx['destination'],
                        asset_id,
                        amount,
                        validity)
                  )
    if validity == 'Valid':
        amount = util.devise(db, amount, asset_id, 'output')
        logging.info('Send: {} of asset {} from {} to {} ({})'.format(amount, util.get_asset_name(asset_id), tx['source'], tx['destination'], util.short(tx['tx_hash'])))

    send_parse_cursor.close()

# vim: tabstop=8 expandtab shiftwidth=4 softtabstop=4
