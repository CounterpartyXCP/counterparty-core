#! /usr/bin/python3

import struct
import sqlite3
import decimal
D = decimal.Decimal
import logging

from . import (util, config, exceptions, bitcoin)

FORMAT = '>QQQQHQ'
ID = 10
LENGTH = 8 + 8 + 8 + 8 + 2 + 8

def create (source, give_id, give_amount, get_id, get_amount, expiration, fee_required, fee_provided):
    db = sqlite3.connect(config.DATABASE)
    db.row_factory = sqlite3.Row
    cursor = db.cursor()
    cursor, balance = util.balance(cursor, source, give_id) 
    if not balance or balance < give_amount:
        raise exceptions.BalanceError('Insufficient funds. (Check that the database is up‐to‐date.)')
    if give_id == get_id:
        raise exceptions.UselessError('You can’t trade an asset for itself.')
    data = config.PREFIX + struct.pack(config.TXTYPE_FORMAT, ID)
    data += struct.pack(FORMAT, give_id, give_amount, get_id, get_amount,
                        expiration, fee_required)
    return bitcoin.transaction(source, None, config.DUST_SIZE, int(fee_provided), data)

def parse (db, cursor, tx, message):
    # Ask for forgiveness…
    validity = 'Valid'

    # Unpack message.
    try:
        give_id, give_amount, get_id, get_amount, expiration, fee_required = struct.unpack(FORMAT, message)
    except Exception:   #
        give_id, give_amount, get_id, get_amount, expiration, fee_required = None, None, None, None, None, None
        validity = 'Invalid: could not unpack'

    if give_id == get_id:
        validity = 'Invalid: cannot trade an asset for itself.'

    if validity == 'Valid':
        give_amount = D(give_amount)
        get_amount = D(get_amount)
        price = get_amount / give_amount

    # Debit the address that makes the order. Check for sufficient funds.
    if validity == 'Valid':
        cursor, balance = util.balance(cursor, tx['source'], give_id)
        if balance >= give_amount:
            if give_id:  # No need (or way) to debit BTC.
                db, cursor, validity = util.debit(db, cursor, tx['source'], give_id, give_amount)
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
    db.commit()

    if validity == 'Valid':

        cursor, issuances = util.get_issuances(cursor, give_id)
        if issuances and issuances[0]['divisible']: give_unit = config.UNIT
        else: give_unit = 1
        cursor, issuances = util.get_issuances(cursor, get_id)
        if issuances and issuances[0]['divisible']: get_unit = config.UNIT
        else: get_unit = 1

        if not give_id:
            fee_text = 'with a provided fee of ' + str(tx['fee'] / config.UNIT) + ' BTC'
        elif not get_id:
            fee_text = 'with a required fee of ' + str(fee_required / config.UNIT) + ' BTC'
        logging.info('Order: sell {} {} for {} {} at {} {}/{} in {} blocks {} ({})'.format(give_amount/give_unit, util.get_asset_name(give_id), get_amount/get_unit, util.get_asset_name(get_id), price.quantize(config.FOUR).normalize(), util.get_asset_name(get_id), util.get_asset_name(give_id), expiration, fee_text, util.short(tx['tx_hash'])))

        db, cursor = matched_order(db, cursor, tx)

    return db, cursor

def matched_order (db, cursor, tx):  # TODO: Simplify bets in this way, too.
    # TODO: ask_odds, only pass tx, expiration_date vs. expiration

    # Get order in question.
    cursor.execute('''SELECT * FROM orders\
                      WHERE tx_index=?''', (tx['tx_index'],))
    tx1 = cursor.fetchone()
    assert not cursor.fetchone()

    cursor.execute('''SELECT * FROM orders \
                      WHERE (give_id=? AND get_id=? AND validity=?) \
                      ORDER BY price ASC, tx_index''',
                   (tx1['get_id'], tx1['give_id'], 'Valid'))
    give_remaining = tx1['give_amount']
    for tx0 in cursor.fetchall():

        # Check whether fee conditions are satisfied.
        if not tx1['get_id'] and tx0['fee_provided'] < tx0['fee_required']: continue
        elif not tx1['give_id'] and tx1['fee_provided'] < tx0['fee_required']: continue

        # Make sure that that both orders still have funds remaining [to be sold].
        if tx0['give_remaining'] <= 0 or tx1['give_remaining'] <= 0: continue

        # If the prices agree, make the trade. The found order sets the price,
        # and they trade as much as they can.
        price = D(tx0['get_amount']) / D(tx0['give_amount'])
        if price <= 1 / tx1['price']:
            forward_amount = round(min(D(tx0['give_remaining']), give_remaining / price))
            backward_amount = round(forward_amount * price)

            forward_id, backward_id = tx1['get_id'], tx1['give_id']
            matched_order_id = tx0['tx_hash'] + tx1['tx_hash']

            cursor, issuances = util.get_issuances(cursor, forward_id)
            if issuances and issuances[0]['divisible']: forward_unit = config.UNIT
            else: forward_unit = 1
            cursor, issuances = util.get_issuances(cursor, backward_id)
            if issuances and issuances[0]['divisible']: backward_unit = config.UNIT
            else: backward_unit = 1

            logging.info('matched_order: {} {} for {} {} at {} {}/{} ({})'.format(forward_amount/forward_unit, util.get_asset_name(forward_id), backward_amount/backward_unit, util.get_asset_name(backward_id), price.quantize(config.FOUR).normalize(), util.get_asset_name(backward_id), util.get_asset_name(forward_id), util.short(matched_order_id)))

            if 0 in (tx1['give_id'], tx1['get_id']):
                validity = 'Valid: awaiting BTC payment'
            else:
                validity = 'Valid'
                # Credit.
                db, cursor = util.credit(db, cursor, tx1['source'], tx1['get_id'],
                                    forward_amount)
                db, cursor = util.credit(db, cursor, tx0['source'], tx0['get_id'],
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
            cursor.execute('''INSERT into matched_orders(
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
                                expiration_date,
                                validity) VALUES(?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)''',
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
                                min(tx0['block_index'] + tx0['expiration'], tx1['block_index'] + tx1['expiration']),
                                validity)
                          )
            db.commit()
    return db, cursor

def expire (db, cursor, block_index):
    # Expire orders and give refunds for the amount give_remaining.
    cursor.execute('''SELECT * FROM orders''')
    for order in cursor.fetchall():
        time_left = order['block_index'] + order['expiration'] - block_index # Inclusive/exclusive expiration? DUPE
        if time_left <= 0 and order['validity'] == 'Valid':
            cursor.execute('''UPDATE orders SET validity=? WHERE tx_hash=?''', ('Invalid: expired', order['tx_hash']))
            db, cursor = util.credit(db, cursor, order['source'], order['give_id'], order['give_remaining'])
            logging.info('Expired order: {}'.format(util.short(order['tx_hash'])))
        db.commit()

    # Expire matched_orders for BTC with no BTC.
    cursor.execute('''SELECT * FROM matched_orders''')
    for matched_order in cursor.fetchall():
        tx0_time_left = matched_order['tx0_block_index'] + matched_order['tx0_expiration'] - block_index # Inclusive/exclusive expiration? DUPE
        tx1_time_left = matched_order['tx1_block_index'] + matched_order['tx1_expiration'] - block_index # Inclusive/exclusive expiration? DUPE
        if (tx0_time_left <= 0 or tx1_time_left <=0) and matched_order['validity'] == 'Valid: waiting for bitcoins':
            cursor.execute('''UPDATE matched_orders SET validity=? WHERE (tx0_hash=? AND tx1_hash=?)''', ('Invalid: expired while waiting for bitcoins', matched_order['tx0_hash'], matched_order['tx1_hash']))
            if not matched_order['forward_id']:
                db, cursor = util.credit(db, cursor, matched_order['tx1_address'],
                                    matched_order['backward_id'],
                                    matched_order['backward_amount'])
            elif not matched_order['backward_id']:
                db, cursor = util.credit(db, cursor, matched_order['tx0_address'],
                                    matched_order['forward_id'],
                                    matched_order['forward_amount'])
            logging.info('Expired matched_order waiting for bitcoins: {}'.format(util.short(matched_order['tx0_hash'] + matched_order['tx1_hash'])))
    db.commit()

    return db, cursor

# vim: tabstop=8 expandtab shiftwidth=4 softtabstop=4
