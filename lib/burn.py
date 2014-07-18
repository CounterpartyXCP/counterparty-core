#! /usr/bin/python3

"""Burn an asset. Burn {} to earn {} during a special period of time.""".format(config.BTC, config.XCP)

import struct
import decimal
D = decimal.Decimal
from fractions import Fraction

from . import (util, config, exceptions, bitcoin, util)

FORMAT = '>QQ8p'
LENGTH = 8 + 8 + 8
ID = 60


def validate (db, source, asset, quantity, block_index):
    problems = []

    if not isinstance(quantity, int):
        problems.append('quantity must be in satoshis')
        return problems
    if quantity < 0: problems.append('negative quantity')

    # Bitcoin?
    if asset == config.BTC:
        # Try to make sure that the burned funds won't go to waste.
        if block_index < config.BURN_START - 1:
            problems.append('too early to burn {}'.format(config.BTC))
        elif block_index > config.BURN_END:
            problems.append('too late to burn {}'.format(config.BTC))

    # For SQLite3
    quantity = min(quantity, config.MAX_INT)

    return quantity, problems

def compose (db, source, asset, quantity, tag, overburn=False):
    cursor = db.cursor()
    if not tag: tag = ''

    quantity, problems = validate(db, source, asset, quantity, util.last_block(db)['block_index'])
    if problems: raise exceptions.BurnError(problems)

    if asset == config.BTC: 
        # Check that a maximum of 1 BTC total is burned per address.
        burns = list(cursor.execute('''SELECT * FROM burns WHERE (status = ? AND source = ? AND asset = ?)''', ('valid', source, config.BTC)))
        already_burned = sum([burn['burned'] for burn in burns])
        if quantity > (1 * config.UNIT - already_burned) and not overburn:  # Overburn is for test suite.
            raise exceptions.BurnError('1 {} may be burned per address'.format(config.BTC))
        cursor.close()
        return (source, [(config.UNSPENDABLE, quantity)], None)

    else:
        # Only for outgoing (incoming will overburn).
        balances = list(cursor.execute('''SELECT * FROM balances WHERE (address = ? AND asset = ?)''', (source, asset)))
        if not balances or balances[0]['quantity'] < quantity:
            raise exceptions.SendError('insufficient funds')

        asset_id = util.asset_id(asset)
        data = config.PREFIX + struct.pack(config.TXTYPE_FORMAT, ID)
        data += struct.pack(FORMAT, asset_id, quantity, tag)
        cursor.close()
        return (source, [], data)


def parse (db, tx, message=None):
    cursor = db.cursor()

    # Bitcoin?
    if tx['destination'] == config.UNSPENDABLE:
        if tx['btc_amount'] == None:
            quantity = 0
        else:
            quantity = tx['btc_amount']
        asset = config.BTC
        status = 'valid'
    else:
        # Unpack message.
        try:
            assert len(message) == LENGTH
            asset_id, quantity, tag = struct.unpack(FORMAT, message)
            asset = util.asset_name(asset_id)
            status = 'valid'
        except (AssertionError, struct.error) as e:
            asset, quantity, tag = None, None, None
            status = 'invalid: could not unpack'

    if status == 'valid':
        quantity, problems = validate(db, tx['source'], asset, quantity, tx['block_index'])
        if problems: status = 'invalid: ' + '; '.join(problems)

    # TODO: from here…
    # Bitcoin?
    if asset == config.BTC:
        if status == 'valid':
            # Calculate quantity of XCP earned. (Maximum 1 BTC in total, ever.)
            cursor = db.cursor()
            cursor.execute('''SELECT * FROM burns WHERE (status = ? AND source = ?)''', ('valid', tx['source']))
            burns = cursor.fetchall()
            already_burned = sum([burn['burned'] for burn in burns])
            ONE = 1 * config.UNIT
            max_burn = ONE - already_burned
            if sent > max_burn: burned = max_burn   # Exceeded maximum burn; earn what you can.
            else: burned = sent

            total_time = config.BURN_END - config.BURN_START
            partial_time = config.BURN_END - tx['block_index']
            multiplier = 1000 * (1 + (.5 * Fraction(partial_time, total_time)))
            earned = round(burned * multiplier)

            # Credit source address with earned XCP.
            util.credit(db, tx['block_index'], tx['source'], config.XCP, earned, event=tx['tx_hash'])
        else:
            burned = 0
            earned = 0
    else:
        # Overburn
        cursor.execute('''SELECT * FROM balances \
                          WHERE (address = ? AND asset = ?)''', (tx['source'], asset))
        balances = cursor.fetchall()
        if not balances:
            status = 'invalid: insufficient funds'
        elif balances[0]['quantity'] < quantity:
            quantity = min(balances[0]['quantity'], quantity)

        # Debit address.
        util.debit(db, tx['block_index'], tx['source'], asset, burned, event=tx['tx_hash'])

        sent = 0
        burned = quantity
        earned = 0

    # Add parsed transaction to message-type–specific table.
    bindings = {
        'tx_index': tx['tx_index'],
        'tx_hash': tx['tx_hash'],
        'block_index': tx['block_index'],
        'source': tx['source'],
        'asset': asset,
        'sent': sent,
        'burned': burned,
        'earned': earned,
        'tag': tag,
        'status': status,
    }
    sql='insert into burns values(:tx_index, :tx_hash, :block_index, :source, :asset, :sent, :burned, :earned, :tag, :status)'
    cursor.execute(sql, bindings)

    cursor.close()

# vim: tabstop=8 expandtab shiftwidth=4 softtabstop=4
