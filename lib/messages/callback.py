#! /usr/bin/python3

"""Callback a callable asset."""

import struct
import decimal
D = decimal.Decimal
import logging

from lib import (config, exceptions, bitcoin, util)
from . import order

FORMAT = '>dQ'
LENGTH = 8 + 8
ID = 21

def initialise (db):
    cursor = db.cursor()
    cursor.execute('''CREATE TABLE IF NOT EXISTS callbacks(
                      tx_index INTEGER PRIMARY KEY,
                      tx_hash TEXT UNIQUE,
                      block_index INTEGER,
                      source TEXT,
                      fraction TEXT,
                      asset TEXT,
                      status TEXT,
                      FOREIGN KEY (tx_index, tx_hash, block_index) REFERENCES transactions(tx_index, tx_hash, block_index))
                   ''')
    cursor.execute('''CREATE INDEX IF NOT EXISTS
                      block_index_idx ON callbacks (block_index)
                   ''')
    cursor.execute('''CREATE INDEX IF NOT EXISTS
                      source_idx ON callbacks (source)
                   ''')
    cursor.execute('''CREATE INDEX IF NOT EXISTS
                      asset_idx ON callbacks (asset)
                   ''')

def validate (db, source, fraction, asset, block_time, block_index, parse):
    cursor = db.cursor()
    problems = []

    # TODO
    if not config.TESTNET:
        problems.append('callbacks are currently disabled on mainnet')
        return None, None, None, problems
    # TODO

    if fraction > 1:
        problems.append('fraction greater than one')
    elif fraction <= 0:
        problems.append('non‐positive fraction')

    issuances = list(cursor.execute('''SELECT * FROM issuances WHERE (status = ? AND asset = ?)''', ('valid', asset)))
    if not issuances:
        problems.append('no such asset, {}.'.format(asset))
        return None, None, None, problems
    else:
        last_issuance = issuances[-1]

        if last_issuance['issuer'] != source:
            problems.append('not asset owner')
            return None, None, None, problems

        if not last_issuance['callable']:
            problems.append('uncallable asset')
            return None, None, None, problems
        elif last_issuance['call_date'] > block_time: problems.append('before call date')

        call_price = round(last_issuance['call_price'], 6)  # TODO: arbitrary
        divisible = last_issuance['divisible']

    if not divisible:   # Pay per output unit.
        call_price *= config.UNIT

    # If parsing, unescrow all funds of asset. (Order of operations is
    # important here.)
    if parse:

        # Cancel pending order matches involving asset.
        cursor.execute('''SELECT * from order_matches \
                          WHERE status = ? AND (forward_asset = ? OR backward_asset = ?)''', ('pending', asset, asset))
        for order_match in list(cursor):
            order.cancel_order_match(db, order_match, 'cancelled', block_index)

        # Cancel open orders involving asset.
        cursor.execute('''SELECT * from orders \
                          WHERE status = ? AND (give_asset = ? OR get_asset = ?)''', ('open', asset, asset))
        for order_element in list(cursor):
            order.cancel_order(db, order_element, 'cancelled', block_index)

    # Calculate callback quantities.
    holders = util.holders(db, asset)
    outputs = []
    for holder in holders:

        # If composing (and not parsing), predict funds to be returned from
        # escrow (instead of cancelling open offers, etc.), by *not* skipping
        # listing escrowed funds here.
        if parse and holder['escrow']:
            continue

        address = holder['address']
        address_quantity = holder['address_quantity']
        if address == source or address_quantity == 0: continue

        callback_quantity = int(address_quantity * fraction)   # Round down.
        fraction_actual = callback_quantity / address_quantity

        outputs.append({'address': address, 'address_quantity': address_quantity, 'callback_quantity': callback_quantity, 'fraction_actual': fraction_actual})

    callback_total = sum([output['callback_quantity'] for output in outputs])
    if not callback_total: problems.append('nothing called back')

    balances = list(cursor.execute('''SELECT * FROM balances WHERE (address = ? AND asset = ?)''', (source, config.XCP)))
    if not balances or balances[0]['quantity'] < (call_price * callback_total):
        problems.append('insufficient funds')

    cursor.close()
    return call_price, callback_total, outputs, problems

def compose (db, source, fraction, asset):
    call_price, callback_total, outputs, problems = validate(db, source, fraction, asset, util.last_block(db)['block_time'], util.last_block(db)['block_index'], parse=False)
    if problems: raise exceptions.ComposeError(problems)
    logging.info('Total quantity to be called back: {} {}'.format(util.value_out(db, callback_total, asset), asset))

    asset_id = util.get_asset_id(asset, util.last_block(db)['block_index'])
    data = struct.pack(config.TXTYPE_FORMAT, ID)
    data += struct.pack(FORMAT, fraction, asset_id)
    return (source, [], data)

def parse (db, tx, message):
    callback_parse_cursor = db.cursor()

    # Unpack message.
    try:
        if len(message) != LENGTH:
            raise exceptions.UnpackError
        fraction, asset_id = struct.unpack(FORMAT, message)
        asset = util.get_asset_name(asset_id, tx['block_index'])
        status = 'valid'
    except (exceptions.UnpackError, exceptions.AssetNameError, struct.error) as e:
        fraction, asset = None, None
        status = 'invalid: could not unpack'

    if status == 'valid':
        call_price, callback_total, outputs, problems = validate(db, tx['source'], fraction, asset, tx['block_time'], tx['block_index'], parse=True)
        if problems: status = 'invalid: ' + '; '.join(problems)

    if status == 'valid':
        # Issuer.
        assert call_price * callback_total == int(call_price * callback_total)
        util.debit(db, tx['block_index'], tx['source'], config.XCP, int(call_price * callback_total), action='callback', event=tx['tx_hash'])
        util.credit(db, tx['block_index'], tx['source'], asset, callback_total, action='callback', event=tx['tx_hash'])

        # Holders.
        for output in outputs:
            assert call_price * output['callback_quantity'] == int(call_price * output['callback_quantity'])
            util.debit(db, tx['block_index'], output['address'], asset, output['callback_quantity'], action='callback', event=tx['tx_hash'])
            util.credit(db, tx['block_index'], output['address'], config.XCP, int(call_price * output['callback_quantity']), action='callback', event=tx['tx_hash'])

    # Add parsed transaction to message-type–specific table.
    bindings = {
        'tx_index': tx['tx_index'],
        'tx_hash': tx['tx_hash'],
        'block_index': tx['block_index'],
        'source': tx['source'],
        'fraction': fraction,
        'asset': asset,
        'status': status,
    }
    sql='insert into callbacks values(:tx_index, :tx_hash, :block_index, :source, :fraction, :asset, :status)'
    callback_parse_cursor.execute(sql, bindings)

    callback_parse_cursor.close()

# vim: tabstop=8 expandtab shiftwidth=4 softtabstop=4
