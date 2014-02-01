#! /usr/bin/python3

"""Create and parse 'send'-type messages."""

import struct
import logging

from . import (util, config, exceptions, bitcoin, util)

FORMAT = '>QQ'
LENGTH = 8 + 8
ID = 0


def validate (db, source, destination, amount, asset):
    problems = []

    if asset == 'BTC': problems.append('cannot send bitcoins')
    if not util.valid_asset_name(asset): problems.append('bad asset ID')
    if not amount: problems.append('zero quantity')

    balances = util.get_balances(db, address=source, asset=asset)
    if not balances or balances[0]['amount'] < amount:
        problems.append('insufficient funds')

    return problems

def create (db, source, destination, amount, asset, unsigned=False):
    problems = validate(db, source, destination, amount, asset)
    if problems: raise exceptions.SendError(problems)

    asset_id = util.get_asset_id(asset)
    data = config.PREFIX + struct.pack(config.TXTYPE_FORMAT, ID)
    data += struct.pack(FORMAT, asset_id, amount)
    return bitcoin.transaction(source, destination, config.DUST_SIZE, config.MIN_FEE, data, unsigned=unsigned)

def parse (db, tx, message):
    send_parse_cursor = db.cursor()

    # Unpack message.
    try:
        assert len(message) == LENGTH
        asset_id, amount = struct.unpack(FORMAT, message)
        asset = util.get_asset_name(asset_id)
        validity = 'Valid'
    except struct.error as e:
        asset, amount = None, None
        validity = 'Invalid: Could not unpack.'

    if validity == 'Valid':
        # For SQLite3
        amount = min(amount, config.MAX_INT)

        problems = validate(db, tx['source'], tx['destination'], amount, asset)
        if problems: validity = 'Invalid: ' + ';'.join(problems)

    if validity == 'Valid':
        util.debit(db, tx['block_index'], tx['source'], asset, amount)
        util.credit(db, tx['block_index'], tx['destination'], asset, amount)
        logging.info('Send: {} of asset {} from {} to {} ({})'.format(util.devise(db, amount, asset, 'output'), asset, tx['source'], tx['destination'], util.short(tx['tx_hash'])))

    # Add parsed transaction to message-type–specific table.
    element_data = {
        'tx_index': tx['tx_index'],
        'tx_hash': tx['tx_hash'],
        'block_index': tx['block_index'],
        'source': tx['source'],
        'destination': tx['destination'],
        'asset': asset,
        'amount': amount,
        'validity': validity,
    }
    send_parse_cursor.execute(*util.get_insert_sql('sends', element_data))
    config.zeromq_publisher.push_to_subscribers('new_send', element_data)

    send_parse_cursor.close()

# vim: tabstop=8 expandtab shiftwidth=4 softtabstop=4
