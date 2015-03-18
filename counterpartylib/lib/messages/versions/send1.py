#! /usr/bin/python3

"""Create and parse 'send'-type messages."""

import struct

from ... import (config, exceptions, util)

FORMAT = '>QQ'
LENGTH = 8 + 8
ID = 0

def unpack(db, message, block_index):
    # Only used for `unpack` API call at the moment.
    try:
        asset_id, quantity = struct.unpack(FORMAT, message)
        asset = util.get_asset_name(db, asset_id, block_index)

    except struct.error:
        raise UnpackError('could not unpack')

    except AssetNameError:
        raise UnpackError('asset id invalid')

    unpacked = {
                'asset': asset,
                'quantity': quantity
               }
    return unpacked

def validate (db, source, destination, asset, quantity, block_index):
    problems = []

    if asset == config.BTC: problems.append('cannot send bitcoins')  # Only for parsing.

    if not isinstance(quantity, int):
        problems.append('quantity must be in satoshis')
        return problems

    if quantity < 0: problems.append('negative quantity')

    if util.enabled('send_destination_required'):  # Protocol change.
        if not destination:
            status = problems.append('destination is required')

    return problems

def compose (db, source, destination, asset, quantity):
    cursor = db.cursor()

    # Just send BTC?
    if asset == config.BTC:
        return (source, [(destination, quantity)], None)

    #quantity must be in int satoshi (not float, string, etc)
    if not isinstance(quantity, int):
        raise exceptions.ComposeError('quantity must be an int (in satoshi)')

    # Only for outgoing (incoming will overburn).
    balances = list(cursor.execute('''SELECT * FROM balances WHERE (address = ? AND asset = ?)''', (source, asset)))
    if not balances or balances[0]['quantity'] < quantity:
        raise exceptions.ComposeError('insufficient funds')

    block_index = util.CURRENT_BLOCK_INDEX

    problems = validate(db, source, destination, asset, quantity, block_index)
    if problems: raise exceptions.ComposeError(problems)

    asset_id = util.get_asset_id(db, asset, block_index)
    data = struct.pack(config.TXTYPE_FORMAT, ID)
    data += struct.pack(FORMAT, asset_id, quantity)

    cursor.close()
    return (source, [(destination, None)], data)

def parse (db, tx, message):
    cursor = db.cursor()

    # Unpack message.
    try:
        if len(message) != LENGTH:
            raise exceptions.UnpackError
        asset_id, quantity = struct.unpack(FORMAT, message)
        asset = util.get_asset_name(db, asset_id, tx['block_index'])
        status = 'valid'
    except (exceptions.UnpackError, exceptions.AssetNameError, struct.error) as e:
        asset, quantity = None, None
        status = 'invalid: could not unpack'

    if status == 'valid':
        # Oversend
        cursor.execute('''SELECT * FROM balances \
                                     WHERE (address = ? AND asset = ?)''', (tx['source'], asset))
        balances = cursor.fetchall()
        if not balances:
            status = 'invalid: insufficient funds'
        elif balances[0]['quantity'] < quantity:
            quantity = min(balances[0]['quantity'], quantity)

    # For SQLite3
    if quantity:
        quantity = min(quantity, config.MAX_INT)

    if status == 'valid':
        problems = validate(db, tx['source'], tx['destination'], asset, quantity, tx['block_index'])
        if problems: status = 'invalid: ' + '; '.join(problems)

    if status == 'valid':
        util.debit(db, tx['source'], asset, quantity, action='send', event=tx['tx_hash'])
        util.credit(db, tx['destination'], asset, quantity, action='send', event=tx['tx_hash'])

    # Add parsed transaction to message-type–specific table.
    bindings = {
        'tx_index': tx['tx_index'],
        'tx_hash': tx['tx_hash'],
        'block_index': tx['block_index'],
        'source': tx['source'],
        'destination': tx['destination'],
        'asset': asset,
        'quantity': quantity,
        'status': status,
    }
    sql='insert into sends values(:tx_index, :tx_hash, :block_index, :source, :destination, :asset, :quantity, :status)'
    cursor.execute(sql, bindings)


    cursor.close()

# vim: tabstop=8 expandtab shiftwidth=4 softtabstop=4
