#! /usr/bin/python3

# Filled orders may not be re‐opened, so only orders not involving BTC (and so
# which cannot have expired order matches) may be filled.

import struct
import decimal
D = decimal.Decimal
import logging

from . import (util, config, exceptions, bitcoin, util)

FORMAT = '>QQQQHQ'
LENGTH = 8 + 8 + 8 + 8 + 2 + 8
ID = 10

def cancel_order (db, order, status, block_index):
    cursor = db.cursor()

    # Update status of order.
    bindings = {
        'status': status,
        'tx_hash': order['tx_hash']
    }
    sql='update orders set status = :status where tx_hash = :tx_hash'
    cursor.execute(sql, bindings)
    util.message(db, block_index, 'update', 'orders', bindings)

    if order['give_asset'] != 'BTC':    # Can’t credit BTC.
        util.credit(db, block_index, order['source'], order['give_asset'], order['give_remaining'], event=order['tx_hash'])

    cursor.close()

def cancel_order_match (db, order_match, status, block_index):
    '''
    May only be cancelled by callbacks.'''

    cursor = db.cursor()

    # Update status of order match.
    bindings = {
        'status': status,
        'order_match_id': order_match['id']
    }
    sql='update order_matches set status = :status where id = :order_match_id'
    cursor.execute(sql, bindings)
    util.message(db, block_index, 'update', 'order_matches', bindings)

    order_match_id = order_match['tx0_hash'] + order_match['tx1_hash']

    # If tx0 is dead, credit address directly; if not, replenish give remaining, get remaining, and fee required remaining.
    orders = list(cursor.execute('''SELECT * FROM orders \
                                    WHERE tx_index = ?''',
                                 (order_match['tx0_index'],)))
    assert len(orders) == 1
    tx0_order = orders[0]
    if tx0_order['status'] in ('expired', 'cancelled'):
        tx0_order_status = tx0_order['status']
        if order_match['forward_asset'] != 'BTC':
            util.credit(db, block_index, order_match['tx0_address'],
                        order_match['forward_asset'],
                        order_match['forward_quantity'], event=order_match['id'])
    else:
        tx0_give_remaining = tx0_order['give_remaining'] + order_match['forward_quantity']
        tx0_get_remaining = tx0_order['get_remaining'] + order_match['backward_quantity']
        if tx0_order['get_asset'] == 'BTC' and (block_index >= 297000 or config.TESTNET):    # Protocol change.
            tx0_fee_required_remaining = tx0_order['fee_required_remaining'] + order_match['fee_paid']
        else:
            tx0_fee_required_remaining = tx0_order['fee_required_remaining']
        tx0_order_status = tx0_order['status']
        bindings = {
            'give_remaining': tx0_give_remaining,
            'get_remaining': tx0_get_remaining,
            'status': tx0_order_status,
            'fee_required_remaining': tx0_fee_required_remaining,
            'tx_hash': order_match['tx0_hash']
        }
        sql='update orders set give_remaining = :give_remaining, get_remaining = :get_remaining, fee_required_remaining = :fee_required_remaining where tx_hash = :tx_hash'
        cursor.execute(sql, bindings)
        util.message(db, block_index, 'update', 'orders', bindings)

    # If tx1 is dead, credit address directly; if not, replenish give remaining, get remaining, and fee required remaining.
    orders = list(cursor.execute('''SELECT * FROM orders \
                                    WHERE tx_index = ?''',
                                 (order_match['tx1_index'],)))
    assert len(orders) == 1
    tx1_order = orders[0]
    if tx1_order['status'] in ('expired', 'cancelled'):
        tx1_order_status = tx1_order['status']
        if order_match['backward_asset'] != 'BTC':
            util.credit(db, block_index, order_match['tx1_address'],
                        order_match['backward_asset'],
                        order_match['backward_quantity'], event=order_match['id'])
    else:
        tx1_give_remaining = tx1_order['give_remaining'] + order_match['backward_quantity']
        tx1_get_remaining = tx1_order['get_remaining'] + order_match['forward_quantity']
        if tx1_order['get_asset'] == 'BTC' and (block_index >= 297000 or config.TESTNET):    # Protocol change.
            tx1_fee_required_remaining = tx1_order['fee_required_remaining'] + order_match['fee_paid']
        else:
            tx1_fee_required_remaining = tx1_order['fee_required_remaining']
        tx1_order_status = tx1_order['status']
        bindings = {
            'give_remaining': tx1_give_remaining,
            'get_remaining': tx1_get_remaining,
            'status': tx1_order_status,
            'fee_required_remaining': tx1_fee_required_remaining,
            'tx_hash': order_match['tx1_hash']
        }
        sql='update orders set give_remaining = :give_remaining, get_remaining = :get_remaining, fee_required_remaining = :fee_required_remaining where tx_hash = :tx_hash'
        cursor.execute(sql, bindings)
        util.message(db, block_index, 'update', 'orders', bindings)

    if block_index < 286500:    # Protocol change.
        # Sanity check: one of the two must have expired.
        tx0_order_time_left = tx0_order['expire_index'] - block_index
        tx1_order_time_left = tx1_order['expire_index'] - block_index
        assert tx0_order_time_left or tx1_order_time_left

    cursor.close()


def validate (db, source, give_asset, give_quantity, get_asset, get_quantity, expiration, fee_required):
    problems = []
    cursor = db.cursor()

    if give_asset == get_asset:
        problems.append('trading an asset for itself')

    if not isinstance(give_quantity, int):
        problems.append('give_quantity must be in satoshis')
        return problems
    if not isinstance(get_quantity, int):
        problems.append('get_quantity must be in satoshis')
        return problems
    if not isinstance(fee_required, int):
        problems.append('fee_required must be in satoshis')
        return problems
    if not isinstance(expiration, int):
        problems.append('expiration must be expressed as an integer block delta')
        return problems

    if give_quantity <= 0: problems.append('non‐positive give quantity')
    if get_quantity <= 0: problems.append('non‐positive get quantity')
    if fee_required < 0: problems.append('negative fee_required')
    if expiration <= 0: problems.append('non‐positive expiration')

    if not give_quantity or not get_quantity:
        problems.append('zero give or zero get')
    cursor.execute('select * from issuances where (status = ? and asset = ?)', ('valid', give_asset))
    if give_asset not in ('BTC', 'XCP') and not cursor.fetchall():
        problems.append('no such asset to give ({})'.format(give_asset))
    cursor.execute('select * from issuances where (status = ? and asset = ?)', ('valid', get_asset))
    if get_asset not in ('BTC', 'XCP') and not cursor.fetchall():
        problems.append('no such asset to get ({})'.format(get_asset))
    if expiration > config.MAX_EXPIRATION:
        problems.append('expiration overflow')

    # For SQLite3
    if give_quantity > config.MAX_INT or get_quantity > config.MAX_INT or fee_required > config.MAX_INT:
        problems.append('integer overflow')

    cursor.close()
    return problems

def compose (db, source, give_asset, give_quantity, get_asset, get_quantity, expiration, fee_required):
    cursor = db.cursor()
    balances = list(cursor.execute('''SELECT * FROM balances WHERE (address = ? AND asset = ?)''', (source, give_asset)))
    if give_asset != 'BTC' and (not balances or balances[0]['quantity'] < give_quantity):
        raise exceptions.OrderError('insufficient funds')

    problems = validate(db, source, give_asset, give_quantity, get_asset, get_quantity, expiration, fee_required)
    if problems: raise exceptions.OrderError(problems)

    give_id = util.asset_id(give_asset)
    get_id = util.asset_id(get_asset)
    data = config.PREFIX + struct.pack(config.TXTYPE_FORMAT, ID)
    data += struct.pack(FORMAT, give_id, give_quantity, get_id, get_quantity,
                        expiration, fee_required)
    cursor.close()
    return (source, [], data)

def parse (db, tx, message):
    order_parse_cursor = db.cursor()

    # Unpack message.
    try:
        assert len(message) == LENGTH
        give_id, give_quantity, get_id, get_quantity, expiration, fee_required = struct.unpack(FORMAT, message)
        give_asset = util.asset_name(give_id)
        get_asset = util.asset_name(get_id)
        status = 'open'
    except (AssertionError, struct.error) as e:
        give_asset, give_quantity, get_asset, get_quantity, expiration, fee_required = 0, 0, 0, 0, 0, 0
        status = 'invalid: could not unpack'

    price = 0
    if status == 'open':
        try: price = util.price(get_quantity, give_quantity, tx['block_index'])
        except Exception as e: pass

        # Overorder
        order_parse_cursor.execute('''SELECT * FROM balances \
                                      WHERE (address = ? AND asset = ?)''', (tx['source'], give_asset))
        balances = list(order_parse_cursor)
        if give_asset != 'BTC':
            if not balances:
                give_quantity = 0
            else:
                balance = balances[0]['quantity']
                if balance < give_quantity:
                    give_quantity = balance
                    get_quantity = int(price * give_quantity)

        problems = validate(db, tx['source'], give_asset, give_quantity, get_asset, get_quantity, expiration, fee_required)
        if problems: status = 'invalid: ' + '; '.join(problems)

    # Debit give quantity. (Escrow.)
    if status == 'open':
        if give_asset != 'BTC':  # No need (or way) to debit BTC.
            util.debit(db, tx['block_index'], tx['source'], give_asset, give_quantity, event=tx['tx_hash'])

    # Add parsed transaction to message-type–specific table.
    bindings = {
        'tx_index': tx['tx_index'],
        'tx_hash': tx['tx_hash'],
        'block_index': tx['block_index'],
        'source': tx['source'],
        'give_asset': give_asset,
        'give_quantity': give_quantity,
        'give_remaining': give_quantity,
        'get_asset': get_asset,
        'get_quantity': get_quantity,
        'get_remaining': get_quantity,
        'expiration': expiration,
        'expire_index': tx['block_index'] + expiration,
        'fee_required': fee_required,
        'fee_required_remaining': fee_required,
        'fee_provided': tx['fee'],
        'fee_provided_remaining': tx['fee'],
        'status': status,
    }
    sql='insert into orders values(:tx_index, :tx_hash, :block_index, :source, :give_asset, :give_quantity, :give_remaining, :get_asset, :get_quantity, :get_remaining, :expiration, :expire_index, :fee_required, :fee_required_remaining, :fee_provided, :fee_provided_remaining, :status)'
    order_parse_cursor.execute(sql, bindings)

    # Match.
    if status == 'open':
        match(db, tx)

    order_parse_cursor.close()

def match (db, tx):
    cursor = db.cursor()

    # Get order in question.
    orders = list(cursor.execute('''SELECT * FROM orders\
                                    WHERE tx_index=?''', (tx['tx_index'],)))
    assert len(orders) == 1
    tx1 = orders[0]

    cursor.execute('''SELECT * FROM orders \
                      WHERE (give_asset=? AND get_asset=? AND status=?)''',
                   (tx1['get_asset'], tx1['give_asset'], 'open'))

    tx1_give_remaining = tx1['give_remaining']
    tx1_get_remaining = tx1['get_remaining']

    order_matches = cursor.fetchall()
    if tx['block_index'] > 284500 or config.TESTNET:  # Protocol change.
        order_matches = sorted(order_matches, key=lambda x: x['tx_index'])                              # Sort by tx index second.
        order_matches = sorted(order_matches, key=lambda x: util.price(x['get_quantity'], x['give_quantity'], tx1['block_index']))   # Sort by price first.

    # Get fee remaining.
    tx1_fee_required_remaining = tx1['fee_required_remaining']
    tx1_fee_provided_remaining = tx1['fee_provided_remaining']

    tx1_status = 'open'
    for tx0 in order_matches:
        if tx1_status != 'open': break

        logging.debug('Considering: ' + tx0['tx_hash'])
        tx0_give_remaining = tx0['give_remaining']
        tx0_get_remaining = tx0['get_remaining']

        # Get fee provided remaining.
        tx0_fee_required_remaining = tx0['fee_required_remaining']
        tx0_fee_provided_remaining = tx0['fee_provided_remaining']

        # Make sure that that both orders still have funds remaining (if order involves BTC, and so cannot be ‘filled’).
        if tx0['give_asset'] == 'BTC' or tx0['get_asset'] == 'BTC': # Gratuitous
            if tx0_give_remaining <= 0 or tx1_give_remaining <= 0:
                logging.debug('Negative give remaining.')
                continue
            if tx1['block_index'] >= 292000 or config.TESTNET:  # Protocol change
                if tx0_get_remaining <= 0 or tx1_get_remaining <= 0:
                    logging.debug('Negative get remaining.')
                    continue

            if tx1['block_index'] >= 294000 or config.TESTNET:  # Protocol change.
                if tx0['fee_required_remaining'] < 0:
                    logging.debug('Negative tx0 fee required remaining.')
                    continue
                if tx0['fee_provided_remaining'] < 0:
                    logging.debug('Negative tx0 fee provided remaining.')
                    continue
                if tx1_fee_provided_remaining < 0:
                    logging.debug('Negative tx1 fee provided remaining.')
                    continue
                if tx1_fee_required_remaining < 0:
                    logging.debug('Negative tx1 fee required remaining.')
                    continue

        # If the prices agree, make the trade. The found order sets the price,
        # and they trade as much as they can.
        tx0_price = util.price(tx0['get_quantity'], tx0['give_quantity'], tx1['block_index'])
        tx1_price = util.price(tx1['get_quantity'], tx1['give_quantity'], tx1['block_index'])
        tx1_inverse_price = util.price(tx1['give_quantity'], tx1['get_quantity'], tx1['block_index'])

        # Protocol change.
        if tx['block_index'] < 286000: tx1_inverse_price = util.price(1, tx1_price, tx1['block_index'])

        logging.debug('Tx0 Price: {}; Tx1 Inverse Price: {}'.format(float(tx0_price), float(tx1_inverse_price)))
        if tx0_price <= tx1_inverse_price:
            logging.debug('Potential forward quantities: {}, {}'.format(tx0_give_remaining, int(util.price(tx1_give_remaining, tx0_price, tx1['block_index']))))
            forward_quantity = int(min(tx0_give_remaining, int(util.price(tx1_give_remaining, tx0_price, tx1['block_index']))))
            logging.debug('Forward Quantity: {}'.format(forward_quantity))
            backward_quantity = round(forward_quantity * tx0_price)

            if not forward_quantity:
                logging.debug('Zero forward quantity.')
                continue
            if tx1['block_index'] >= 286500 or config.TESTNET:    # Protocol change.
                if not backward_quantity:
                    logging.debug('Zero backward quantity.')
                    continue
            logging.debug('Backward Quantity: {}'.format(backward_quantity))

            # Check and update fee remainings.
            fee = 0
            if tx1['block_index'] >= 286500 or config.TESTNET: # Protocol change. Deduct fee_required from fee_provided_remaining, etc., if possible (else don’t match).
                if tx1['get_asset'] == 'BTC':
                    fee = int(tx1['fee_required_remaining'] * util.price(forward_quantity, tx1_get_remaining, tx1['block_index']))
                    if tx0_fee_provided_remaining < fee:
                        logging.debug('Tx0 fee provided remaining: {}; Fee: {}'.format(tx0_fee_provided_remaining, fee))
                        continue
                    else:
                        tx0_fee_provided_remaining -= fee
                        if tx1['block_index'] >= 287800 or config.TESTNET:  # Protocol change.
                            tx1_fee_required_remaining -= fee
                elif tx1['give_asset'] == 'BTC':
                    fee = int(tx0['fee_required_remaining'] * util.price(backward_quantity, tx0_get_remaining, tx1['block_index']))
                    if tx1_fee_provided_remaining < fee:
                        logging.debug('Tx1 fee provided remaining: {}; Fee: {}'.format(tx1_fee_provided_remaining, fee))
                        continue
                    else:
                        tx1_fee_provided_remaining -= fee 
                        if tx1['block_index'] >= 287800 or config.TESTNET:  # Protocol change.
                            tx0_fee_required_remaining -= fee
            else:   # Don’t deduct.
                if tx1['get_asset'] == 'BTC':
                    if tx0_fee_provided_remaining < tx1['fee_required']: continue
                elif tx1['give_asset'] == 'BTC':
                    if tx1_fee_provided_remaining < tx0['fee_required']: continue

            forward_asset, backward_asset = tx1['get_asset'], tx1['give_asset']
            order_match_id = tx0['tx_hash'] + tx1['tx_hash']

            if 'BTC' in (tx1['give_asset'], tx1['get_asset']):
                status = 'pending'
            else:
                status = 'completed'
                # Credit.
                util.credit(db, tx['block_index'], tx1['source'], tx1['get_asset'],
                                    forward_quantity, event=order_match_id)
                util.credit(db, tx['block_index'], tx0['source'], tx0['get_asset'],
                                    backward_quantity, event=order_match_id)

            # Debit the order, even if it involves giving bitcoins, and so one
            # can't debit the sending account.
            # Get remainings may be negative.
            tx0_give_remaining -= forward_quantity
            tx0_get_remaining -= backward_quantity
            tx1_give_remaining -= backward_quantity
            tx1_get_remaining -= forward_quantity

            # Update give_remaining, get_remaining.
            # tx0
            tx0_status = 'open'
            if tx0_give_remaining <= 0 or (tx0_get_remaining <= 0 and (tx1['block_index'] >= 292000 or config.TESTNET)):    # Protocol change
                if tx0['give_asset'] != 'BTC' and tx0['get_asset'] != 'BTC':
                    # Fill order, and recredit give_remaining.
                    tx0_status = 'filled'
                    util.credit(db, tx1['block_index'], tx0['source'], tx0['give_asset'], tx0_give_remaining, event=tx1['tx_hash'], action='filled')
            bindings = {
                'give_remaining': tx0_give_remaining,
                'get_remaining': tx0_get_remaining,
                'fee_required_remaining': tx0_fee_required_remaining,
                'fee_provided_remaining': tx0_fee_provided_remaining,
                'status': tx0_status,
                'tx_hash': tx0['tx_hash']
            }
            sql='update orders set give_remaining = :give_remaining, get_remaining = :get_remaining, fee_required_remaining = :fee_required_remaining, fee_provided_remaining = :fee_provided_remaining, status = :status where tx_hash = :tx_hash'
            cursor.execute(sql, bindings)
            util.message(db, tx1['block_index'], 'update', 'orders', bindings)
            # tx1
            if tx1_give_remaining <= 0 or (tx1_get_remaining <= 0 and (tx1['block_index'] >= 292000 or config.TESTNET)):    # Protocol change
                if tx1['give_asset'] != 'BTC' and tx1['get_asset'] != 'BTC':
                    # Fill order, and recredit give_remaining.
                    tx1_status = 'filled'
                    util.credit(db, tx1['block_index'], tx1['source'], tx1['give_asset'], tx1_give_remaining, event=tx0['tx_hash'], action='filled')
            bindings = {
                'give_remaining': tx1_give_remaining,
                'get_remaining': tx1_get_remaining,
                'fee_required_remaining': tx1_fee_required_remaining,
                'fee_provided_remaining': tx1_fee_provided_remaining,
                'status': tx1_status,
                'tx_hash': tx1['tx_hash']
            }
            sql='update orders set give_remaining = :give_remaining, get_remaining = :get_remaining, fee_required_remaining = :fee_required_remaining, fee_provided_remaining = :fee_provided_remaining, status = :status where tx_hash = :tx_hash'
            cursor.execute(sql, bindings)
            util.message(db, tx1['block_index'], 'update', 'orders', bindings)

            # Calculate when the match will expire.
            if tx1['block_index'] >= 286500 or config.TESTNET:    # Protocol change.
                match_expire_index = tx1['block_index'] + 10
            else:
                match_expire_index = min(tx0['expire_index'], tx1['expire_index'])

            # Record order match.
            bindings = {
                'id': tx0['tx_hash'] + tx['tx_hash'],
                'tx0_index': tx0['tx_index'],
                'tx0_hash': tx0['tx_hash'],
                'tx0_address': tx0['source'],
                'tx1_index': tx1['tx_index'],
                'tx1_hash': tx1['tx_hash'],
                'tx1_address': tx1['source'],
                'forward_asset': forward_asset,
                'forward_quantity': forward_quantity,
                'backward_asset': backward_asset,
                'backward_quantity': backward_quantity,
                'tx0_block_index': tx0['block_index'],
                'tx1_block_index': tx1['block_index'],
                'tx0_expiration': tx0['expiration'],
                'tx1_expiration': tx1['expiration'],
                'match_expire_index': match_expire_index,
                'fee_paid': fee,
                'status': status,
            }
            sql='insert into order_matches values(:id, :tx0_index, :tx0_hash, :tx0_address, :tx1_index, :tx1_hash, :tx1_address, :forward_asset, :forward_quantity, :backward_asset, :backward_quantity, :tx0_block_index, :tx1_block_index, :tx0_expiration, :tx1_expiration, :match_expire_index, :fee_paid, :status)'
            cursor.execute(sql, bindings)

            if tx1_status == 'filled':
                break

    cursor.close()

def expire (db, block_index):
    cursor = db.cursor()

    # Expire orders and give refunds for the quantity give_remaining (if non-zero; if not BTC).
    cursor.execute('''SELECT * FROM orders \
                      WHERE (status = ? AND expire_index < ?)''', ('open', block_index))
    for order in cursor.fetchall():
        cancel_order(db, order, 'expired', block_index)

        # Record offer expiration.
        bindings = {
            'order_index': order['tx_index'],
            'order_hash': order['tx_hash'],
            'source': order['source'],
            'block_index': block_index
        }
        sql='insert into order_expirations values(:order_index, :order_hash, :source, :block_index)'
        cursor.execute(sql, bindings)


    # Expire order_matches for BTC with no BTC.
    cursor.execute('''SELECT * FROM order_matches \
                      WHERE (status = ? and match_expire_index < ?)''', ('pending', block_index))
    for order_match in cursor.fetchall():
        cancel_order_match(db, order_match, 'expired', block_index)

        # Record order match expiration.
        bindings = {
            'order_match_id': order_match['id'],
            'tx0_address': order_match['tx0_address'],
            'tx1_address': order_match['tx1_address'],
            'block_index': block_index
        }
        sql='insert into order_match_expirations values(:order_match_id, :tx0_address, :tx1_address, :block_index)'
        cursor.execute(sql, bindings)

    cursor.close()

# vim: tabstop=8 expandtab shiftwidth=4 softtabstop=4
