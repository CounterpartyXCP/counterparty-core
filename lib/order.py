#! /usr/bin/python3

import struct
import sqlite3
import decimal
D = decimal.Decimal
# decimal.getcontext().prec = 8
import colorama
colorama.init()

from . import (util, config, exceptions, bitcoin)

FORMAT = '>QQQQHQ'
ID = 10

def create (source, give_id, give_amount, get_id, get_amount, expiration, fee_required, fee_provided):
    db = sqlite3.connect(config.LEDGER)
    db.row_factory = sqlite3.Row
    cursor = db.cursor()
    cursor, balance = util.balance(cursor, source, give_id) 
    if not balance or balance < give_amount:
        raise exceptions.BalanceError('Insufficient funds. (Check that the database is up‐to‐date.)')
    data = config.PREFIX + struct.pack(config.TXTYPE_FORMAT, ID)
    data += struct.pack(FORMAT, give_id, give_amount, get_id, get_amount,
                        expiration, fee_required)
    return bitcoin.transaction(source, None, config.DUST_SIZE, int(fee_provided), data)

def parse (db, cursor, tx, message):
    # Ask for forgiveness…
    validity = 'Valid'

    fee_provided = int(tx['fee'])

    # Unpack message.
    try:
        give_id, give_amount, get_id, get_amount, expiration, fee_required = struct.unpack(FORMAT, message)
        assert give_id != get_id    # TODO
    except Exception:   #
        give_id, give_amount, get_id, get_amount, expiration, fee_required = None, None, None, None, None, None
        validity = 'Invalid: could not unpack'

    if validity == 'Valid':
        give_amount = D(give_amount)
        get_amount = D(get_amount)
        ask_price = get_amount / give_amount

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
                        ask_price,
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
                        float(ask_price),
                        expiration,
                        fee_required,
                        fee_provided,
                        validity)
                  )
    db.commit()

    if validity == 'Valid':

        cursor, divisible = util.is_divisible(cursor, give_id)
        if divisible: give_unit = config.UNIT
        else: give_unit = 1
        cursor, divisible = util.is_divisible(cursor, get_id)
        if divisible: get_unit = config.UNIT
        else: get_unit = 1

        if not give_id:
            fee_text = 'with a provided fee of ' + str(fee_provided / config.UNIT) + ' BTC'
        elif not get_id:
            fee_text = 'with a required fee of ' + str(fee_required / config.UNIT) + ' BTC'
        print(colorama.Fore.CYAN + '\tOrder: sell', give_amount/give_unit, util.get_asset_name(give_id), 'for', get_amount/get_unit, util.get_asset_name(get_id), 'at', ask_price.quantize(config.FOUR).normalize(), util.get_asset_name(get_id) + '/' + util.get_asset_name(give_id), 'in', expiration, 'blocks', fee_text, util.short(tx['tx_hash']) + colorama.Style.RESET_ALL) # TODO (and fee_required, fee_provided)

        db, cursor = deal(db, cursor, give_id, give_amount, get_id, get_amount, ask_price, expiration, fee_required, tx)

    return db, cursor

def deal (db, cursor, give_id, give_amount, get_id, get_amount,
        ask_price, expiration, fee_required, tx):

    # Get order in question.
    cursor.execute('''SELECT * FROM orders\
                      WHERE tx_index=?''', (tx['tx_index'],))
    tx1 = cursor.fetchone()
    assert not cursor.fetchone()

    cursor.execute('''SELECT * FROM orders \
                      WHERE (give_id=? AND get_id=? AND validity=?) \
                      ORDER BY ask_price ASC, tx_index''',
                   (get_id, give_id, 'Valid'))
    give_remaining = give_amount
    for tx0 in cursor.fetchall():

        # Check whether fee conditions are satisfied.
        if not get_id and tx0['fee_provided'] < tx0['fee_required']: continue
        elif not give_id and tx1['fee_provided'] < tx0['fee_required']: continue

        # Make sure that that both orders still have funds remaining [to be sold].
        if tx0['give_remaining'] <= 0 or give_remaining <= 0: continue

        # If the prices agree, make the trade. The found order sets the price,
        # and they trade as much as they can.
        price = D(tx0['get_amount']) / D(tx0['give_amount'])
        if price <= 1/ask_price:  # Ugly
            forward_amount = round(min(D(tx0['give_remaining']), give_remaining / price))
            backward_amount = round(forward_amount * price)

            forward_id, backward_id = get_id, give_id
            deal_id = tx0['tx_hash'] + tx1['tx_hash']

            cursor, divisible = util.is_divisible(cursor, forward_id)
            if divisible: forward_unit = config.UNIT
            else: forward_unit = 1
            cursor, divisible = util.is_divisible(cursor, backward_id)
            if divisible: backward_unit = config.UNIT
            else: backward_unit = 1

            print(colorama.Fore.MAGENTA + '\t\tDeal:', forward_amount/forward_unit, util.get_asset_name(forward_id), 'for', backward_amount/backward_unit, util.get_asset_name(backward_id), 'at', price.quantize(config.FOUR).normalize(), util.get_asset_name(backward_id) + '/' + util.get_asset_name(forward_id), util.short(deal_id))

            if 0 in (give_id, get_id):
                validity = 'Valid: waiting for bitcoins'
            else:
                validity = 'Valid'
                # Credit.
                db, cursor = util.credit(db, cursor, tx1['source'], get_id,
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
            cursor.execute('''INSERT into deals(
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
                                expiration,
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
            print(colorama.Fore.YELLOW + colorama.Style.DIM + '\tExpired order:', util.short(order['tx_hash'], strip=True) + colorama.Style.RESET_ALL)
        db.commit()

    # Expire deals for BTC with no BTC.
    cursor.execute('''SELECT * FROM deals''')
    for deal in cursor.fetchall():
        tx0_time_left = deal['tx0_block_index'] + deal['tx0_expiration'] - block_index # Inclusive/exclusive expiration? DUPE
        tx1_time_left = deal['tx1_block_index'] + deal['tx1_expiration'] - block_index # Inclusive/exclusive expiration? DUPE
        if (tx0_time_left <= 0 or tx1_time_left <=0) and deal['validity'] == 'Valid: waiting for bitcoins':
            cursor.execute('''UPDATE deals SET validity=? WHERE (tx0_hash=? AND tx1_hash=?)''', ('Invalid: expired while waiting for bitcoins', deal['tx0_hash'], deal['tx1_hash']))
            if not deal['forward_id']:
                db, cursor = util.credit(db, cursor, deal['tx1_address'],
                                    deal['backward_id'],
                                    deal['backward_amount'])
            elif not deal['backward_id']:
                db, cursor = util.credit(db, cursor, deal['tx0_address'],
                                    deal['forward_id'],
                                    deal['forward_amount'])
            print(colorama.Fore.GREEN + colorama.Style.DIM + '\tExpired deal waiting for bitcoins:',
                  util.short(deal['tx0_hash'] + deal['tx1_hash'], strip=True) + colorama.Style.RESET_ALL)
    db.commit()

    return db, cursor

# vim: tabstop=8 expandtab shiftwidth=4 softtabstop=4
