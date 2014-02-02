#! /usr/bin/python3

import struct
import decimal
D = decimal.Decimal
import logging
import heapq

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

def parse (db, tx, message, order_heap, order_match_heap):
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
        balances = util.get_balances(db, address=tx['source'], asset=give_asset)
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
        'fee_required': fee_required,
        'fee_provided': tx['fee'],
        'validity': validity,
    }
    order_parse_cursor.execute(*util.get_insert_sql('orders', element_data))
    if validity == 'Valid':
        heapq.heappush(order_heap, (tx['block_index'] + expiration, tx['tx_index']))

    # Log.
    if validity == 'Valid':
        give_amount = util.devise(db, give_amount, give_asset, 'output')
        get_amount = util.devise(db, get_amount, get_asset, 'output')

        if give_asset == 'BTC':
            fee_text = 'with a provided fee of ' + str(tx['fee'] / config.UNIT) + ' BTC '
        elif get_asset == 'BTC':
            fee_text = 'with a required fee of ' + str(fee_required / config.UNIT) + ' BTC '
        else:
            fee_text = ''
        logging.info('Order: sell {} {} for {} {} at {} {}/{} in {} blocks {}({})'.format(give_amount, give_asset, get_amount, get_asset, util.devise(db, price, 'price', dest='output'), get_asset, give_asset, expiration, fee_text, util.short(tx['tx_hash'])))
        match(db, tx, order_heap, order_match_heap)

    order_parse_cursor.close()

def match (db, tx, order_heap, order_match_heap):
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
    sorted(order_matches, key=lambda x: x['tx_index'])                              # Sort by tx index second.
    sorted(order_matches, key=lambda x: D(x['get_amount']) / D(x['give_amount']))   # Sort by price first.
    for tx0 in order_matches:

        # Check whether fee conditions are satisfied.
        if tx1['get_asset'] == 'BTC' and tx0['fee_provided'] < tx1['fee_required']: continue
        elif tx1['give_asset'] == 'BTC' and tx1['fee_provided'] < tx0['fee_required']: continue

        # Make sure that that both orders still have funds remaining [to be sold].
        if tx0['give_remaining'] <= 0 or give_remaining <= 0: continue

        # If the prices agree, make the trade. The found order sets the price,
        # and they trade as much as they can.
        tx0_price = D(tx0['get_amount']) / D(tx0['give_amount'])
        tx1_price = D(tx1['get_amount']) / D(tx1['give_amount'])
        if tx0_price <= D(1) / tx1_price:
            forward_amount = int(min(tx0['give_remaining'], D(give_remaining) / tx0_price))
            if not forward_amount: continue
            backward_amount = round(forward_amount * tx0_price)

            forward_asset, backward_asset = tx1['get_asset'], tx1['give_asset']
            order_match_id = tx0['tx_hash'] + tx1['tx_hash']

            # This can't be gotten rid of!
            forward_print = D(util.devise(db, forward_amount, forward_asset, 'output'))
            backward_print = D(util.devise(db, backward_amount, backward_asset, 'output'))

            logging.info('Order Match: {} {} for {} {} at {} {}/{} ({})'.format(forward_print, forward_asset, backward_print, backward_asset, util.devise(db, tx0_price, 'price', 'output'), backward_asset, forward_asset, util.short(order_match_id)))

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
                'validity': validity,
            }

            order_match_cursor.execute(*util.get_insert_sql('order_matches', element_data))
            if validity == 'Valid: awaiting BTC payment':
                heapq.heappush(order_match_heap, (min(tx0['block_index'] + tx0['expiration'], tx0['block_index'] + tx0['expiration']), tx0['tx_index'], tx1['tx_index']))

    order_match_cursor.close()

def expire (db, block_index, order_heap, order_match_heap):
    # Expire orders and give refunds for the amount give_remaining (if non-zero; if not BTC).
    while True:
        try: expire_block_index, tx_index = order_heap[0]
        except IndexError: break

        if expire_block_index >= block_index:
            break
        else:
            heapq.heappop(order_heap)
            order_expire_cursor = db.cursor()

            order_expire_cursor.execute('''SELECT * FROM orders WHERE tx_index=?''', (tx_index,))
            order = order_expire_cursor.fetchall()[0]
            if order['validity'] == 'Valid':
                if order['give_asset'] != 'BTC':    # Can't credit BTC.
                    util.credit(db, block_index, order['source'], order['give_asset'], order['give_remaining'])
                order_expire_cursor.execute('''UPDATE orders SET validity=? WHERE (validity = ? AND tx_index=?)''', ('Invalid: expired', 'Valid', tx_index))

                logging.info('Expired order: {}'.format(util.short(order['tx_hash'])))
            order_expire_cursor.close()

    # Expire order_matches for BTC with no BTC.
    cursor = db.cursor()
    while True:
        try: expire_block_index, tx0_index, tx1_index = order_match_heap[0]
        except IndexError: break

        if expire_block_index >= block_index:
            break
        else:
            heapq.heappop(order_match_heap)
            cursor.execute('''SELECT * FROM order_matches WHERE (tx0_index=? AND tx1_index=?)''', (tx0_index, tx1_index))
            order_match = cursor.fetchall()[0]

            if order_match['validity'] == 'Valid: awaiting BTC payment':
                cursor.execute('''UPDATE order_matches SET validity=? WHERE (tx0_hash=? AND tx1_hash=?)''', ('Invalid: expired awaiting BTC payment', order_match['tx0_hash'], order_match['tx1_hash']))
                if order_match['forward_asset'] == 'BTC':
                    util.credit(db, block_index, order_match['tx1_address'],
                                        order_match['backward_asset'],
                                        order_match['backward_amount'])
                elif order_match['backward_asset'] == 'BTC':
                    util.credit(db, block_index, order_match['tx0_address'],
                                        order_match['forward_asset'],
                                        order_match['forward_amount'])
                logging.info('Expired Order Match awaiting BTC payment: {}'.format(util.short(order_match['tx0_hash'] + order_match['tx1_hash'])))

    cursor.close()

# vim: tabstop=8 expandtab shiftwidth=4 softtabstop=4
