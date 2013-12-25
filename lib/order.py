#! /usr/bin/python3

import struct
import sqlite3
import decimal
D = decimal.Decimal
import logging

from . import (util, config, exceptions, bitcoin, api)

FORMAT = '>QQQQHQ'
ID = 10
LENGTH = 8 + 8 + 8 + 8 + 2 + 8

def create (source, give_id, give_amount, get_id, get_amount, expiration, fee_required, fee_provided, test=False):
    db = sqlite3.connect(config.DATABASE)
    db.row_factory = sqlite3.Row
    cursor = db.cursor()
    balances = api.get_balances(address=source, asset_id=give_id)
    if give_id and (not balances or balances[0]['amount'] < give_amount):
        raise exceptions.BalanceError('Insufficient funds. (Check that the database is up‐to‐date.)')
    if give_id == get_id:
        raise exceptions.UselessError('You can’t trade an asset for itself.')
    if not get_amount or not get_amount:
        raise exceptions.UselessError('Zero give or zero get.')
    data = config.PREFIX + struct.pack(config.TXTYPE_FORMAT, ID)
    data += struct.pack(FORMAT, give_id, give_amount, get_id, get_amount,
                        expiration, fee_required)
    cursor.close()
    return bitcoin.transaction(source, None, None, int(fee_provided), data, test)

def parse (db, cursor, tx, message):
    # Ask for forgiveness…
    validity = 'Valid'

    # Unpack message.
    try:
        give_id, give_amount, get_id, get_amount, expiration, fee_required = struct.unpack(FORMAT, message)
    except Exception:   #
        give_id, give_amount, get_id, get_amount, expiration, fee_required = None, None, None, None, None, None
        validity = 'Invalid: could not unpack'

    if validity == 'Valid':
        if give_id == get_id:
            validity = 'Invalid: cannot trade an asset for itself.'
    if validity == 'Valid':
        if not get_amount or not get_amount:
            validity = 'Invalid: zero give or zero get.'

    if validity == 'Valid':
        give_amount = D(give_amount)
        get_amount = D(get_amount)
        price = get_amount / give_amount
    else:
        price = 0

    # Debit the address that makes the order. Check for sufficient funds.
    if validity == 'Valid':
        if give_id:  # No need (or way) to debit BTC.
            balances = api.get_balances(address=tx['source'], asset_id=give_id)
            if balances and balances[0]['amount'] >= give_amount:
                cursor, validity = util.debit(db, cursor, tx['source'], give_id, give_amount)
            else:
                validity = 'Invalid: insufficient funds.'

    # Add parsed transaction to message‐type–specific table.
    cursor.execute('''INSERT INTO orders(
                        tx_index,
                        tx_hash,
                        block_index,
                        source,
                        give_id,
                        give_amount,
                        give_remaining,
                        get_id,
                        get_amount,
                        price,
                        expiration,
                        fee_required,
                        fee_provided,
                        validity) VALUES(?,?,?,?,?,?,?,?,?,?,?,?,?,?)''',
                        (tx['tx_index'],
                        tx['tx_hash'],
                        tx['block_index'],
                        tx['source'],
                        give_id,
                        int(give_amount),
                        int(give_amount),
                        get_id,
                        int(get_amount),
                        float(price),
                        expiration,
                        fee_required,
                        tx['fee'],
                        validity)
                  )

    if validity == 'Valid':

        give_amount = util.devise(give_amount, give_id, 'output')
        get_amount = util.devise(get_amount, get_id, 'output')

        if not give_id:
            fee_text = 'with a provided fee of ' + str(tx['fee'] / config.UNIT) + ' BTC'
        elif not get_id:
            fee_text = 'with a required fee of ' + str(fee_required / config.UNIT) + ' BTC'
        logging.info('Order: sell {} {} for {} {} at {} {}/{} in {} blocks {} ({})'.format(give_amount, util.get_asset_name(give_id), get_amount, util.get_asset_name(get_id), price.quantize(config.FOUR).normalize(), util.get_asset_name(get_id), util.get_asset_name(give_id), expiration, fee_text, util.short(tx['tx_hash'])))
        cursor = order_match(db, cursor, tx)

    return cursor

def order_match (db, cursor, tx):

    # Get order in question.
    cursor.execute('''SELECT * FROM orders\
                      WHERE tx_index=?''', (tx['tx_index'],))
    tx1 = cursor.fetchone()
    assert not cursor.fetchone()

    cursor.execute('''SELECT * FROM orders \
                      WHERE (give_id=? AND get_id=? AND validity=?) \
                      ORDER BY price ASC, tx_index''',
                   (tx1['get_id'], tx1['give_id'], 'Valid'))
    give_remaining = tx1['give_remaining']
    for tx0 in cursor.fetchall():
        # Check whether fee conditions are satisfied.
        if not tx1['get_id'] and tx0['fee_provided'] < tx1['fee_required']: continue
        elif not tx1['give_id'] and tx1['fee_provided'] < tx0['fee_required']: continue

        # Make sure that that both orders still have funds remaining [to be sold].
        if tx0['give_remaining'] <= 0 or tx1['give_remaining'] <= 0: continue

        # If the prices agree, make the trade. The found order sets the price,
        # and they trade as much as they can.
        if tx0['price'] <= 1 / tx1['price']:
            forward_amount = round(min(D(tx0['give_remaining']), give_remaining / D(tx1['price'])))
            backward_amount = round(forward_amount * tx0['price'])

            forward_id, backward_id = tx1['get_id'], tx1['give_id']
            order_match_id = tx0['tx_hash'] + tx1['tx_hash']

            # This can’t be gotten rid of!
            forward_unit = util.devise(1, forward_id, 'output')
            backward_unit = util.devise(1, backward_id, 'output')

            logging.info('Order Match: {} {} for {} {} at {} {}/{} ({})'.format(D(forward_amount * forward_unit).quantize(config.EIGHT).normalize(), util.get_asset_name(forward_id), D(backward_amount * backward_unit).quantize(config.EIGHT).normalize(), util.get_asset_name(backward_id), D(tx0['price']).quantize(config.FOUR).normalize(), util.get_asset_name(backward_id), util.get_asset_name(forward_id), util.short(order_match_id)))

            if 0 in (tx1['give_id'], tx1['get_id']):
                validity = 'Valid: awaiting BTC payment'
            else:
                validity = 'Valid'
                # Credit.
                cursor = util.credit(db, cursor, tx1['source'], tx1['get_id'],
                                    forward_amount)
                cursor = util.credit(db, cursor, tx0['source'], tx0['get_id'],
                                    backward_amount)

            # Debit the order, even if it involves giving bitcoins, and so one
            # can’t debit the sending account.
            give_remaining -= backward_amount

            # Update give_remaining.
            cursor.execute('''UPDATE orders \
                              SET give_remaining=? \
                              WHERE tx_hash=?''',
                          (int(tx0['give_remaining'] - forward_amount),
                           tx0['tx_hash']))
            cursor.execute('''UPDATE orders \
                              SET give_remaining=? \
                              WHERE tx_hash=?''',
                          (int(give_remaining),
                           tx1['tx_hash']))

            # Record order fulfillment.
            cursor.execute('''INSERT into order_matches(
                                tx0_index,
                                tx0_hash,
                                tx0_address,
                                tx1_index,
                                tx1_hash,
                                tx1_address,
                                forward_id,
                                forward_amount,
                                backward_id,
                                backward_amount,
                                tx0_block_index,
                                tx1_block_index,
                                tx0_expiration,
                                tx1_expiration,
                                validity) VALUES(?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)''',
                                (tx0['tx_index'],
                                tx0['tx_hash'],
                                tx0['source'],
                                tx1['tx_index'],
                                tx1['tx_hash'],
                                tx1['source'],
                                forward_id,
                                int(forward_amount),
                                backward_id,
                                int(backward_amount),
                                tx0['block_index'],
                                tx1['block_index'],
                                tx0['expiration'],
                                tx1['expiration'],
                                validity)
                          )
    return cursor

def expire (db, cursor, block_index):
    # Expire orders and give refunds for the amount give_remaining.
    cursor.execute('''SELECT * FROM orders''')
    for order in cursor.fetchall():
        time_left = order['block_index'] + order['expiration'] - block_index # Inclusive/exclusive expiration? DUPE
        if time_left <= 0 and order['validity'] == 'Valid':
            cursor.execute('''UPDATE orders SET validity=? WHERE tx_hash=?''', ('Invalid: expired', order['tx_hash']))
            cursor = util.credit(db, cursor, order['source'], order['give_id'], order['give_remaining'])
            logging.info('Expired order: {}'.format(util.short(order['tx_hash'])))

    # Expire order_matches for BTC with no BTC.
    cursor.execute('''SELECT * FROM order_matches''')
    for order_match in cursor.fetchall():
        tx0_time_left = order_match['tx0_block_index'] + order_match['tx0_expiration'] - block_index # Inclusive/exclusive expiration? DUPE
        tx1_time_left = order_match['tx1_block_index'] + order_match['tx1_expiration'] - block_index # Inclusive/exclusive expiration? DUPE
        if (tx0_time_left <= 0 or tx1_time_left <=0) and order_match['validity'] == 'Valid: waiting for bitcoins':
            cursor.execute('''UPDATE order_matches SET validity=? WHERE (tx0_hash=? AND tx1_hash=?)''', ('Invalid: expired while waiting for bitcoins', order_match['tx0_hash'], order_match['tx1_hash']))
            if not order_match['forward_id']:
                cursor = util.credit(db, cursor, order_match['tx1_address'],
                                    order_match['backward_id'],
                                    order_match['backward_amount'])
            elif not order_match['backward_id']:
                cursor = util.credit(db, cursor, order_match['tx0_address'],
                                    order_match['forward_id'],
                                    order_match['forward_amount'])
            logging.info('Expired order_match waiting for bitcoins: {}'.format(util.short(order_match['tx0_hash'] + order_match['tx1_hash'])))

    return cursor

# vim: tabstop=8 expandtab shiftwidth=4 softtabstop=4
