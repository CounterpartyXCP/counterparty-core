#! /usr/bin/python3

"""Create and parse 'send'-type messages."""

import struct

from . import (util, config, exceptions, bitcoin, util)

FORMAT = '>QQ'
LENGTH = 8 + 8
ID = 0


def validate (db, source, destination, asset, quantity):
    problems = []

    if asset == config.BTC: problems.append('cannot send bitcoins')  # Only for parsing.

    if not isinstance(quantity, int):
        problems.append('quantity must be in satoshis')
        return problems

    if quantity < 0: problems.append('negative quantity')

    return problems

def compose (db, source, destination, asset, quantity):
    cursor = db.cursor()

    # Just send BTC?
    if asset == config.BTC:
        return (source, [(destination, quantity)], None)

    #quantity must be in int satoshi (not float, string, etc)
    if not isinstance(quantity, int):
        raise exceptions.SendError('quantity must be an int (in satoshi)')

    # Only for outgoing (incoming will overburn).
    balances = list(cursor.execute('''SELECT * FROM balances WHERE (address = ? AND asset = ?)''', (source, asset)))
    if not balances or balances[0]['quantity'] < quantity:
        raise exceptions.SendError('insufficient funds')

    problems = validate(db, source, destination, asset, quantity)
    if problems: raise exceptions.SendError(problems)

    asset_id = util.asset_id(asset)
    data = config.PREFIX + struct.pack(config.TXTYPE_FORMAT, ID)
    data += struct.pack(FORMAT, asset_id, quantity)

    cursor.close()
    return (source, [(destination, None)], data)

def parse (db, tx, message):
    cursor = db.cursor()

    # Unpack message.
    try:
        assert len(message) == LENGTH
        asset_id, quantity = struct.unpack(FORMAT, message)
        asset = util.asset_name(asset_id)
        status = 'valid'
    except (AssertionError, struct.error) as e:
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

    if status == 'valid':
        # For SQLite3
        quantity = min(quantity, config.MAX_INT)
        problems = validate(db, tx['source'], tx['destination'], asset, quantity)
        if problems: status = 'invalid: ' + '; '.join(problems)

    if status == 'valid':
        util.debit(db, tx['block_index'], tx['source'], asset, quantity, event=tx['tx_hash'])
        util.credit(db, tx['block_index'], tx['destination'], asset, quantity, event=tx['tx_hash'])

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
