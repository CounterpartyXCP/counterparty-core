#! /usr/bin/python3

import struct
import decimal
D = decimal.Decimal
import logging

from . import (util, config, exceptions, bitcoin, util)

FORMAT = '>QQQQHQ'
LENGTH = 8 + 8 + 8 + 8 + 2 + 8
ID = 10

def validate (db, source, give_asset, give_amount, get_asset, get_amount, expiration, fee_required):
    problems = []

    if give_asset == get_asset:
        problems.append('trading an asset for itself')
    if not give_amount or not get_amount:
        problems.append('zero give or zero get')
    if give_asset not in ('BTC', 'XCP') and not util.get_issuances(db, validity='Valid', asset=give_asset):
        problems.append('no such asset to give, {}.'.format(give_asset))
    if get_asset not in ('BTC', 'XCP') and not util.get_issuances(db, validity='Valid', asset=get_asset):
        problems.append('no such asset to get, {}.'.format(get_asset))
    if expiration > config.MAX_EXPIRATION:
        problems.append('maximum expiration time exceeded')

    # For SQLite3
    if give_amount > config.MAX_INT or get_amount > config.MAX_INT or fee_required > config.MAX_INT:
        problems.append('maximum integer size exceeded')

    return problems

def create (db, source, give_asset, give_amount, get_asset, get_amount, expiration, fee_required, fee_provided, unsigned=False):
    balances = util.get_balances(db, address=source, asset=give_asset)
    if give_asset != 'BTC' and (not balances or balances[0]['amount'] < give_amount):
        raise exceptions.OrderError('insufficient funds')

    problems = validate(db, source, give_asset, give_amount, get_asset, get_amount, expiration, fee_required)
    if problems: raise exceptions.OrderError(problems)

    give_id = util.get_asset_id(give_asset)
    get_id = util.get_asset_id(get_asset)
    data = config.PREFIX + struct.pack(config.TXTYPE_FORMAT, ID)
    data += struct.pack(FORMAT, give_id, give_amount, get_id, get_amount,
                        expiration, fee_required)
    return bitcoin.transaction(source, None, None, fee_provided, data, unsigned=unsigned)

def parse (db, tx, message):
    order_parse_cursor = db.cursor()

    # Unpack message.
    try:
        assert len(message) == LENGTH
        give_id, give_amount, get_id, get_amount, expiration, fee_required = struct.unpack(FORMAT, message)
        give_asset = util.get_asset_name(give_id)
        get_asset = util.get_asset_name(get_id)
        validity = 'Valid'
    except struct.error as e:
        give_asset, give_amount, get_asset, get_amount, expiration, fee_required = None, None, None, None, None, None
        validity = 'Invalid: could not unpack'

    price = 0
    if validity == 'Valid':
        try: price = D(get_amount) / D(give_amount)
        except: pass

        # Overorder
        order_parse_cursor.execute('''SELECT * FROM balances \
                                      WHERE (address = ? AND asset = ?)''', (tx['source'], give_asset))
        balances = order_parse_cursor.fetchall()
        if give_asset != 'BTC':
            if not balances:  give_amount = 0
            elif balances[0]['amount'] < give_amount:
                give_amount = min(balances[0]['amount'], give_amount)
                get_amount = int(price * D(give_amount))

        problems = validate(db, tx['source'], give_asset, give_amount, get_asset, get_amount, expiration, fee_required)
        if problems: validity = 'Invalid: ' + ';'.join(problems)

    if validity == 'Valid':
        if give_asset != 'BTC':  # No need (or way) to debit BTC.
            util.debit(db, tx['block_index'], tx['source'], give_asset, give_amount)

    # Add parsed transaction to message-type–specific table.
    element_data = {
        'tx_index': tx['tx_index'],
        'tx_hash': tx['tx_hash'],
        'block_index': tx['block_index'],
        'source': tx['source'],
        'give_asset': give_asset,
        'give_amount': give_amount,
        'give_remaining': give_amount,
        'get_asset': get_asset,
        'get_amount': get_amount,
        'get_remaining': get_amount,
        'expiration': expiration,
        'expire_index': tx['block_index'] + expiration,
        'fee_required': fee_required,
        'fee_provided': tx['fee'],
        'validity': validity,
    }
    order_parse_cursor.execute(*util.get_insert_sql('orders', element_data))

    # Log.
    if validity == 'Valid':
        give_amount = util.devise(db, give_amount, give_asset, 'output')
        get_amount = util.devise(db, get_amount, get_asset, 'output')

        # Consistent ordering for currency pairs. (Partial DUPE.)
        if get_asset < give_asset:
            price = util.devise(db, D(get_amount) / D(give_amount), 'price', 'output')
            price_assets = get_asset + '/' + give_asset
            action = 'sell'
        else:
            price = util.devise(db, D(give_amount) / D(get_amount), 'price', 'output')
            price_assets = give_asset + '/' + get_asset
            action = 'buy'

        logging.info('Order: {} {} {} at {} {} in {} blocks, with a provided fee of {} BTC and a required fee of {} BTC ({})'.format(action, give_amount, give_asset, price, price_assets, expiration, str(tx['fee'] / config.UNIT), str(fee_required / config.UNIT), tx['tx_hash']))
        match(db, tx)

    order_parse_cursor.close()

def match (db, tx):
    order_match_cursor = db.cursor()

    # Get order in question.
    order_match_cursor.execute('''SELECT * FROM orders\
                                  WHERE tx_index=?''', (tx['tx_index'],))
    tx1 = order_match_cursor.fetchall()[0]

    order_match_cursor.execute('''SELECT * FROM orders \
                                  WHERE (give_asset=? AND get_asset=? AND validity=?)''',
                               (tx1['get_asset'], tx1['give_asset'], 'Valid'))
    give_remaining = tx1['give_remaining']
    get_remaining = tx1['get_remaining']
    order_matches = order_match_cursor.fetchall()
    if tx['block_index'] > 284500:  # For backwards‐compatibility (no sorting before this block).
        order_matches = sorted(order_matches, key=lambda x: x['tx_index'])                              # Sort by tx index second.
        order_matches = sorted(order_matches, key=lambda x: D(x['get_amount']) / D(x['give_amount']))   # Sort by price first.
    for tx0 in order_matches:

        # Check whether fee conditions are satisfied.
        if tx1['get_asset'] == 'BTC' and tx0['fee_provided'] < tx1['fee_required']: continue
        elif tx1['give_asset'] == 'BTC' and tx1['fee_provided'] < tx0['fee_required']: continue

        # Make sure that that both orders still have funds remaining [to be sold].
        if tx0['give_remaining'] <= 0 or give_remaining <= 0: continue

        # If the prices agree, make the trade. The found order sets the price,
        # and they trade as much as they can.
        tx0_price = util.price(tx0['get_amount'], tx0['give_amount'])
        tx1_price = util.price(tx1['get_amount'], tx1['give_amount'])
        tx1_inverse_price = util.price(tx1['give_amount'], tx1['get_amount'])

        # NOTE: Old protocol.
        if tx['block_index'] < 286000: tx1_inverse_price = D(1) / tx1_price

        if tx0_price <= tx1_inverse_price:
            forward_amount = int(min(tx0['give_remaining'], D(give_remaining) / tx0_price))
            if not forward_amount: continue
            backward_amount = round(forward_amount * tx0_price)

            forward_asset, backward_asset = tx1['get_asset'], tx1['give_asset']
            order_match_id = tx0['tx_hash'] + tx1['tx_hash']

            # This can't be gotten rid of!
            forward_print = D(util.devise(db, forward_amount, forward_asset, 'output'))
            backward_print = D(util.devise(db, backward_amount, backward_asset, 'output'))

            # Consistent ordering for currency pairs. (Partial DUPE.)
            if forward_asset < backward_asset:
                price = util.devise(db, D(forward_amount) / D(backward_amount), 'price', 'output')
                price_assets = forward_asset + '/' + backward_asset
                foobar = '{} {} for {} {}'.format(forward_print, forward_asset, backward_print, backward_asset)
            else:
                price = util.devise(db, D(backward_amount) / D(forward_amount), 'price', 'output')
                price_assets = backward_asset + '/' + forward_asset
                foobar = '{} {} for {} {}'.format(backward_print, backward_asset, forward_print, forward_asset)

            logging.info('Order Match: {} at {} {} ({})'.format(foobar, price, price_assets, order_match_id))

            if 'BTC' in (tx1['give_asset'], tx1['get_asset']):
                validity = 'Valid: awaiting BTC payment'
            else:
                validity = 'Valid'
                # Credit.
                util.credit(db, tx['block_index'], tx1['source'], tx1['get_asset'],
                                    forward_amount)
                util.credit(db, tx['block_index'], tx0['source'], tx0['get_asset'],
                                    backward_amount)

            # Debit the order, even if it involves giving bitcoins, and so one
            # can't debit the sending account.
            give_remaining = give_remaining - backward_amount
            get_remaining = get_remaining - forward_amount  # This may indeed be negative!

            # Update give_remaining, get_remaining.
            order_match_cursor.execute('''UPDATE orders \
                              SET give_remaining = ?, \
                                   get_remaining = ? \
                              WHERE tx_hash = ?''',
                          (tx0['give_remaining'] - forward_amount,
                           tx0['get_remaining'] - backward_amount,
                           tx0['tx_hash']))
            order_match_cursor.execute('''UPDATE orders \
                              SET give_remaining = ?, \
                                   get_remaining = ? \
                              WHERE tx_hash = ?''',
                          (give_remaining,
                           get_remaining,
                           tx1['tx_hash']))

            # Record order match.
            element_data = {
                'id': tx0['tx_hash'] + tx['tx_hash'],
                'tx0_index': tx0['tx_index'],
                'tx0_hash': tx0['tx_hash'],
                'tx0_address': tx0['source'],
                'tx1_index': tx1['tx_index'],
                'tx1_hash': tx1['tx_hash'],
                'tx1_address': tx1['source'],
                'forward_asset': forward_asset,
                'forward_amount': forward_amount,
                'backward_asset': backward_asset,
                'backward_amount': backward_amount,
                'tx0_block_index': tx0['block_index'],
                'tx1_block_index': tx1['block_index'],
                'tx0_expiration': tx0['expiration'],
                'tx1_expiration': tx1['expiration'],
                'match_expire_index': min(tx0['expire_index'], tx1['expire_index']),
                'validity': validity,
            }

            order_match_cursor.execute(*util.get_insert_sql('order_matches', element_data))

    order_match_cursor.close()

def expire (db, block_index):
    cursor = db.cursor()

    # Expire orders and give refunds for the amount give_remaining (if non-zero; if not BTC).
    cursor.execute('''SELECT * FROM orders \
                      WHERE (validity = ? AND expire_index < ?)''', ('Valid', block_index))
    for order in cursor.fetchall():
        print(order['expire_index'], block_index)   # TODO
        cursor.execute('''UPDATE orders SET validity=? WHERE tx_index=?''', ('Invalid: expired', order['tx_index']))
        if order['give_asset'] != 'BTC':    # Can't credit BTC.
            util.credit(db, block_index, order['source'], order['give_asset'], order['give_remaining'])

        # Record offer expiration.
        element_data = {
            'order_index': order['tx_index'],
            'order_hash': order['tx_hash'],
            'block_index': block_index
        }
        cursor.execute(*util.get_insert_sql('order_expirations', element_data))

        logging.info('Expired order: {}'.format(order['tx_hash']))

    # Expire order_matches for BTC with no BTC.
    cursor.execute('''SELECT * FROM order_matches \
                      WHERE (validity = ? and match_expire_index < ?)''', ('Valid: awaiting BTC payment', block_index))
    for order_match in cursor.fetchall():
        cursor.execute('''UPDATE order_matches SET validity=? WHERE id = ?''', ('Invalid: expired awaiting BTC payment', order_match['id']))
        if order_match['forward_asset'] == 'BTC':
            util.credit(db, block_index, order_match['tx1_address'],
                        order_match['backward_asset'],
                        order_match['backward_amount'])
        elif order_match['backward_asset'] == 'BTC':
            util.credit(db, block_index, order_match['tx0_address'],
                        order_match['forward_asset'],
                        order_match['forward_amount'])

        # Record order match expiration.
        element_data = {
            'block_index': block_index,
            'order_match_id': order_match['tx0_hash'] + order_match['tx1_hash']
        }
        cursor.execute(*util.get_insert_sql('order_match_expirations', element_data))

        logging.info('Expired Order Match awaiting BTC payment: {}'.format(order_match['id']))

        # If tx0 is still good, replenish give, get remaining.
        cursor.execute('''SELECT * FROM orders \
                          WHERE tx_index = ?''',
                       (order_match['tx0_index'],))
        tx0_order = cursor.fetchall()[0]
        tx0_order_time_left = tx0_order['expire_index'] - block_index
        if tx0_order_time_left:
            cursor.execute('''UPDATE orders \
                              SET give_remaining = ?, \
                                  get_remaining = ? \
                              WHERE tx_index = ?''', (tx0_order['give_remaining'] + order_match['forward_amount'],
                                                     tx0_order['get_remaining'] + order_match['backward_amount'],
                                                     order_match['tx0_index']))
           
        # If tx1 is still good, replenish give, get remaining.
        cursor.execute('''SELECT * FROM orders \
                          WHERE tx_index = ?''',
                       (order_match['tx1_index'],))
        tx1_order = cursor.fetchall()[0]
        tx1_order_time_left = tx1_order['expire_index'] - block_index
        if tx1_order_time_left:
            cursor.execute('''UPDATE orders \
                              SET give_remaining = ?, \
                                  get_remaining = ? \
                              WHERE tx_index = ?''', (tx1_order['give_remaining'] + order_match['backward_amount'],
                                                     tx1_order['get_remaining'] + order_match['forward_amount'],
                                                     order_match['tx1_index']))

        # Sanity check: one of the two must have expired.
        assert tx0_order_time_left or tx1_order_time_left

    cursor.close()

# vim: tabstop=8 expandtab shiftwidth=4 softtabstop=4
