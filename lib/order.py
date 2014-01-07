#! /usr/bin/python3

import struct
import decimal
D = decimal.Decimal
import logging

from . import (util, config, exceptions, bitcoin, util)

FORMAT = '>QQQQHQ'
ID = 10
LENGTH = 8 + 8 + 8 + 8 + 2 + 8

def create (db, source, give_asset, give_amount, get_asset, get_amount, expiration, fee_required, fee_provided, test=False):

    balances = util.get_balances(db, address=source, asset=give_asset)
    if give_asset != 'BTC' and (not balances or balances[0]['amount'] < give_amount):
        raise exceptions.BalanceError('Insufficient funds. (Check that the database is up-to-date.)')
    if give_asset == get_asset:
        raise exceptions.UselessError('You can\'t trade an asset for itself.')
    if not give_amount or not get_amount:
        raise exceptions.UselessError('Zero give or zero get.')
    if get_asset not in ('BTC', 'XCP') and not util.get_issuances(db, validity='Valid', asset=get_asset):
        raise exceptions.DividendError('No such asset to get: {}.'.format(get_asset))

    give_id = util.get_asset_id(give_asset)
    get_id = util.get_asset_id(get_asset)
    data = config.PREFIX + struct.pack(config.TXTYPE_FORMAT, ID)
    data += struct.pack(FORMAT, give_id, give_amount, get_id, get_amount,
                        expiration, fee_required)
    return bitcoin.transaction(source, None, None, fee_provided, data, test)

def parse (db, tx, message):
    order_parse_cursor = db.cursor()

    # Ask for forgiveness…
    validity = 'Valid'

    # Unpack message.
    try:
        give_id, give_amount, get_id, get_amount, expiration, fee_required = struct.unpack(FORMAT, message)
        give_asset = util.get_asset_name(give_id)
        get_asset = util.get_asset_name(get_id)
    except Exception:   #
        give_asset, give_amount, get_asset, get_amount, expiration, fee_required = None, None, None, None, None, None
        validity = 'Invalid: could not unpack'

    if validity == 'Valid':
        if give_asset == get_asset:
            validity = 'Invalid: cannot trade an asset for itself.'
    if validity == 'Valid':
        if not give_amount or not get_amount:
            validity = 'Invalid: zero give or zero get.'

    elif get_asset not in ('BTC', 'XCP') and not util.get_issuances(db, validity='Valid', asset=get_asset):
        validity = 'Invalid: bad get asset'

    if validity == 'Valid':
        give_amount = give_amount
        get_amount = get_amount
        price = D(get_amount) / D(give_amount)
    else:
        price = 0

    # Debit the address that makes the order. Check for sufficient funds.
    if validity == 'Valid':
        if give_asset != 'BTC':  # No need (or way) to debit BTC.
            balances = util.get_balances(db, address=tx['source'], asset=give_asset)
            if balances and balances[0]['amount'] >= give_amount:
                validity = util.debit(db, tx['source'], give_asset, give_amount)
            else:
                validity = 'Invalid: insufficient funds.'

    # Add parsed transaction to message-type–specific table.
    order_parse_cursor.execute('''INSERT INTO orders(
                        tx_index,
                        tx_hash,
                        block_index,
                        source,
                        give_asset,
                        give_amount,
                        give_remaining,
                        get_asset,
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
                        give_asset,
                        give_amount,
                        give_amount,
                        get_asset,
                        get_amount,
                        float(price),
                        expiration,
                        fee_required,
                        tx['fee'],
                        validity)
                  )

    if validity == 'Valid':

        give_amount = util.devise(db, give_amount, give_asset, 'output')
        get_amount = util.devise(db, get_amount, get_asset, 'output')

        if give_asset == 'BTC':
            fee_text = 'with a provided fee of ' + str(tx['fee'] / config.UNIT) + ' BTC '
        elif get_asset == 'BTC':
            fee_text = 'with a required fee of ' + str(fee_required / config.UNIT) + ' BTC '
        else:
            fee_text = ''
        display_price = util.devise(db, D(get_amount) / D(give_amount), 'price', dest='output')
        logging.info('Order: sell {} {} for {} {} at {} {}/{} in {} blocks {}({})'.format(give_amount, give_asset, get_amount, get_asset, display_price, get_asset, give_asset, expiration, fee_text, util.short(tx['tx_hash'])))
        match(db, tx)

    order_parse_cursor.close()

def match (db, tx):

    order_match_cursor = db.cursor()

    # Get order in question.
    order_match_cursor.execute('''SELECT * FROM orders\
                      WHERE tx_index=?''', (tx['tx_index'],))
    tx1 = order_match_cursor.fetchone()

    order_match_cursor.execute('''SELECT * FROM orders \
                      WHERE (give_asset=? AND get_asset=? AND validity=?) \
                      ORDER BY price ASC, tx_index''',
                   (tx1['get_asset'], tx1['give_asset'], 'Valid'))
    give_remaining = tx1['give_remaining']
    order_matches = order_match_cursor.fetchall()
    for tx0 in order_matches:

        # Check whether fee conditions are satisfied.
        if tx1['get_asset'] == 'BTC' and tx0['fee_provided'] < tx1['fee_required']: continue
        elif tx1['give_asset'] == 'BTC' and tx1['fee_provided'] < tx0['fee_required']: continue

        # Make sure that that both orders still have funds remaining [to be sold].
        if tx0['give_remaining'] <= 0 or give_remaining <= 0: continue

        # If the prices agree, make the trade. The found order sets the price,
        # and they trade as much as they can.
        if tx0['price'] <= 1 / tx1['price']:
            forward_amount = round(min(D(tx0['give_remaining']), give_remaining / D(tx0['price'])))
            backward_amount = round(forward_amount * tx0['price'])

            forward_asset, backward_asset = tx1['get_asset'], tx1['give_asset']
            order_match_id = tx0['tx_hash'] + tx1['tx_hash']

            # This can't be gotten rid of!
            forward_print = D(util.devise(db, forward_amount, forward_asset, 'output'))
            backward_print = D(util.devise(db, backward_amount, backward_asset, 'output'))

            logging.info('Order Match: {} {} for {} {} at {} {}/{} ({})'.format(forward_print, forward_asset, backward_print, backward_asset, util.devise(db, tx0['price'], 'price', 'output'), backward_asset, forward_asset, util.short(order_match_id)))

            if 'BTC' in (tx1['give_asset'], tx1['get_asset']):
                validity = 'Valid: awaiting BTC payment'
            else:
                validity = 'Valid'
                # Credit.
                util.credit(db, tx1['source'], tx1['get_asset'],
                                    forward_amount)
                util.credit(db, tx0['source'], tx0['get_asset'],
                                    backward_amount)

            # Debit the order, even if it involves giving bitcoins, and so one
            # can't debit the sending account.
            give_remaining = round(give_remaining - backward_amount)

            # Update give_remaining.
            order_match_cursor.execute('''UPDATE orders \
                              SET give_remaining=? \
                              WHERE tx_hash=?''',
                          (tx0['give_remaining'] - forward_amount,
                           tx0['tx_hash']))
            order_match_cursor.execute('''UPDATE orders \
                              SET give_remaining=? \
                              WHERE tx_hash=?''',
                          (give_remaining,
                           tx1['tx_hash']))

            # Record order match.
            order_match_cursor.execute('''INSERT into order_matches(
                                tx0_index,
                                tx0_hash,
                                tx0_address,
                                tx1_index,
                                tx1_hash,
                                tx1_address,
                                forward_asset,
                                forward_amount,
                                backward_asset,
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
                                forward_asset,
                                forward_amount,
                                backward_asset,
                                backward_amount,
                                tx0['block_index'],
                                tx1['block_index'],
                                tx0['expiration'],
                                tx1['expiration'],
                                validity)
                          )
    order_match_cursor.close()

def expire (db, block_index):
    order_expire_cursor = db.cursor()
    # Expire orders and give refunds for the amount give_remaining (if non-zero; if not BTC).
    order_expire_cursor.execute('''SELECT * FROM orders''')
    for order in order_expire_cursor.fetchall():
        if order['Validity'] == 'Valid' and util.get_time_left(order, block_index=block_index) < 0:
            order_expire_cursor.execute('''UPDATE orders SET validity=? WHERE tx_hash=?''', ('Invalid: expired', order['tx_hash']))
            if order['give_asset'] != 'BTC':    # Can't credit BTC.
                util.credit(db, order['source'], order['give_asset'], order['give_remaining'])
            logging.info('Expired order: {}'.format(util.short(order['tx_hash'])))

    # Expire order_matches for BTC with no BTC.
    order_expire_cursor.execute('''SELECT * FROM order_matches''')
    order_matches = order_expire_cursor.fetchall()
    for order_match in order_matches:
        if order_match['validity'] == 'Valid: awaiting BTC payment' and util.get_order_match_time_left(order_match, block_index=block_index) < 0:
            order_expire_cursor.execute('''UPDATE order_matches SET validity=? WHERE (tx0_hash=? AND tx1_hash=?)''', ('Invalid: expired awaiting BTC payment', order_match['tx0_hash'], order_match['tx1_hash']))
            if order_match['forward_asset'] == 'BTC':
                util.credit(db, order_match['tx1_address'],
                                    order_match['backward_asset'],
                                    order_match['backward_amount'])
            elif order_match['backward_asset'] == 'BTC':
                util.credit(db, order_match['tx0_address'],
                                    order_match['forward_asset'],
                                    order_match['forward_amount'])
            logging.info('Expired Order Match awaiting BTC payment: {}'.format(util.short(order_match['tx0_hash'] + order_match['tx1_hash'])))

    order_expire_cursor.close()

# vim: tabstop=8 expandtab shiftwidth=4 softtabstop=4
