#! /usr/bin/python3

"""Create and parse 'send'-type messages."""

import struct

from . import (util, config, exceptions, bitcoin, util)

FORMAT = '>QQ'
LENGTH = 8 + 8
ID = 0


def validate (db, source, destination, amount, asset):
    problems = []

    if asset == 'BTC': problems.append('cannot send bitcoins')  # Only for parsing.
    if not amount: problems.append('zero quantity')

    return problems

def create (db, source, destination, amount, asset, unsigned=False):
    # Just send BTC.
    if asset == 'BTC':
        return bitcoin.transaction(source, destination, amount, config.MIN_FEE, None, unsigned=unsigned)

    balances = util.get_balances(db, address=source, asset=asset)
    if not balances or balances[0]['amount'] < amount:
        raise exceptions.SendError('insufficient funds')

    problems = validate(db, source, destination, amount, asset)
    if problems: raise exceptions.SendError(problems)

    asset_id = util.get_asset_id(asset)
    data = config.PREFIX + struct.pack(config.TXTYPE_FORMAT, ID)
    data += struct.pack(FORMAT, asset_id, amount)
    return bitcoin.transaction(source, destination, config.DUST_SIZE, config.MIN_FEE, data, unsigned=unsigned)

def parse (db, tx, message):
    cursor = db.cursor()

    # Unpack message.
    try:
        assert len(message) == LENGTH
        asset_id, amount = struct.unpack(FORMAT, message)
        asset = util.get_asset_name(asset_id)
        validity = 'valid'
    except struct.error as e:
        asset, amount = None, None
        validity = 'invalid: Could not unpack.'

    if validity == 'valid':
        # Oversend
        cursor.execute('''SELECT * FROM balances \
                                     WHERE (address = ? AND asset = ?)''', (tx['source'], asset))
        balances = cursor.fetchall()
        if not balances:  amount = 0
        elif balances[0]['amount'] < amount:
            amount = min(balances[0]['amount'], amount)
        # For SQLite3
        amount = min(amount, config.MAX_INT)
        problems = validate(db, tx['source'], tx['destination'], amount, asset)
        if problems: validity = 'invalid: ' + ';'.join(problems)

    if validity == 'valid':
        util.debit(db, tx['block_index'], tx['source'], asset, amount, event=tx['tx_hash'])
        util.credit(db, tx['block_index'], tx['destination'], asset, amount, event=tx['tx_hash'])

    # Add parsed transaction to message-type–specific table.
    bindings = {
        'tx_index': tx['tx_index'],
        'tx_hash': tx['tx_hash'],
        'block_index': tx['block_index'],
        'source': tx['source'],
        'destination': tx['destination'],
        'asset': asset,
        'amount': amount,
        'validity': validity,
    }
    sql='insert into sends values(:tx_index, :tx_hash, :block_index, :source, :destination, :asset, :amount, :validity)'
    cursor.execute(sql, bindings)


    cursor.close()

# vim: tabstop=8 expandtab shiftwidth=4 softtabstop=4
