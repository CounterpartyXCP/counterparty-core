#! /usr/bin/python3

"""
Datastreams are identified by the address that publishes them, and referenced
in transaction outputs.

In matching bets, look for *at least* counterwager_amount, or whatever.

Time_start and time_end: in case of accidental but honest delays in the feed[’s
timestamp].

For CFD leverage, 1x = 5040, 2x = 10080, etc.: 5040 is a superior highly
composite number and a colossally abundant number, and has 1-10, 12 as factors.

All wagers are in XCP.
"""

import struct
import sqlite3
import decimal
D = decimal.Decimal
# decimal.getcontext().prec = 8
import datetime

from . import (util, config, bitcoin, exceptions)

FORMAT = '>HIIQQdI'
ID = 40

def get_fee_multiplier (feed_address):
    # Get fee_multiplier from the last broadcast from the feed_address address.
    db = sqlite3.connect(config.LEDGER)
    db.row_factory = sqlite3.Row
    cursor = db.cursor()
    cursor.execute('''SELECT * FROM broadcasts \
                      WHERE source=? \
                      ORDER BY tx_index desc''', (feed_address,)
                  )
    broadcast = cursor.fetchone()
    db.close()
    return D(broadcast['fee_multiplier'] / 1e8)

def create (source, feed_address, bet_type, time_start, time_end, wager_amount,
            counterwager_amount, threshold_leverage, expiration):

    if util.is_locked(feed_address):
        raise exceptions.FeedLockedError('That feed is locked or doesn’t exist.')

    fee_multiplier = get_fee_multiplier(feed_address)
    if util.balance(source, 1) < wager_amount * (1 + fee_multiplier):
        raise exceptions.BalanceError('Insufficient funds to both make wager and pay feed fee (in XCP). (Check that the database is up‐to‐date.)')

    data = config.PREFIX + struct.pack(config.TXTYPE_FORMAT, ID)
    data += struct.pack(FORMAT, bet_type, time_start, time_end, 
                        int(wager_amount), int(counterwager_amount), threshold_leverage,
                        expiration)

    return bitcoin.transaction(source, feed_address, config.DUST_SIZE,
                               config.MIN_FEE, data)

def parse (db, cursor, tx1, message):
    # Ask for forgiveness…
    validity = 'Valid'

    # Unpack message.
    try:
        (bet_type, time_start, time_end, wager_amount,
         counterwager_amount, threshold_leverage,
         expiration) = struct.unpack(FORMAT, message)
    except Exception:   #
        (bet_type, time_start, time_end, wager_amount,
         counterwager_amount, threshold_leverage,
         expiration) = None, None, None, None, None, None, None
        validity = 'Invalid: could not unpack'

    feed_address = tx1['destination']

    if validity == 'Valid':
        # Debit amount wagered and fee.
        fee_multiplier = get_fee_multiplier(feed_address)
        db, cursor, validity = util.debit(db, cursor, tx1['source'], 1, wager_amount * (1 + fee_multiplier))

        wager_amount = int(wager_amount)
        counterwager_amount = int(counterwager_amount)
        odds = wager_amount / counterwager_amount
    else:
        odds = 0

    # Add parsed transaction to message‐type–specific table.
    cursor.execute('''INSERT INTO bets(
                        tx_index,
                        tx_hash,
                        block_index,
                        source,
                        feed_address,
                        bet_type,
                        time_start,
                        time_end,
                        wager_amount,
                        counterwager_amount,
                        wager_remaining,
                        odds,
                        threshhold_leverage,
                        expiration,
                        validity) VALUES(?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)''',
                        (tx1['tx_index'],
                        tx1['tx_hash'],
                        tx1['block_index'],
                        tx1['source'],
                        feed_address,
                        bet_type,
                        time_start,
                        time_end,
                        wager_amount,
                        counterwager_amount,
                        wager_amount,
                        odds,
                        threshold_leverage,
                        expiration,
                        validity)
                  )
    db.commit()

    if validity == 'Valid':
        print('\tBet:', 'type', bet_type, 'on', feed_address, 'between', datetime.datetime.fromtimestamp(time_start), 'and', datetime.datetime.fromtimestamp(time_end), 'for', wager_amount / config.UNIT, 'XCP', 'against', counterwager_amount / config.UNIT, 'XCP', 'in', expiration, 'blocks', '(' + tx1['tx_hash'] + ')')

        db, cursor = make_contract(db, cursor, bet_type,
                                   time_start, time_end, 
                                   wager_amount, counterwager_amount,
                                   threshold_leverage, expiration, tx1)

    return db, cursor

def make_contract (db, cursor, bet_type, time_start, time_end, 
               wager_amount, counterwager_amount, threshold_leverage,
               expiration, tx1):

    # Get counterbet_type.
    if bet_type % 2: counterbet_type = bet_type - 1
    else: counterbet_type = bet_type + 1

    feed_address = tx1['destination']
    cursor.execute('''SELECT * FROM bets\
                      WHERE (feed_address=? AND block_index>=? AND validity=? AND bet_type=?) \
                      ORDER BY odds DESC, tx_index''',
                   (feed_address, tx1['block_index'] - expiration, 'Valid', counterbet_type))

    ask_odds = wager_amount / counterwager_amount

    wager_remaining = wager_amount
    for tx0 in cursor.fetchall():
        # NOTE: tx0 is a bet; tx1 is a transaction.
        # TODO: How do I get the timestamps to agree?!?!

        # Make sure that that both bets still have funds remaining [to be wagered].
        if tx0['wager_remaining'] <= 0 or wager_remaining <= 0: continue

        # If the odds agree, make the trade. The found order sets the odds,
        # and they trade as much as they can. # TODO: Make odds match exactly?!
        odds = D(tx0['counterwager_amount']) / D(tx0['wager_amount'])
        if odds <= 1/ask_odds:  # Ugly

            # One should not bet himself.
            if tx0['source'] == tx1['source']: continue

            validity = 'Valid'

            forward_amount = round(min(D(tx0['wager_remaining']), wager_remaining / odds))
            backward_amount = round(forward_amount * odds)

            # When a match is made, pay XCP fee.
            fee = get_fee_multiplier(feed_address) * backward_amount
            db, cursor, validity = util.debit(db, cursor, tx1['source'], 1, fee)
            if validity != 'Valid': continue
            db, cursor = util.credit(db, cursor, feed_address, 1, int(fee))

            contract_id = tx0['tx_hash'] + tx1['tx_hash']   #

            print('\t\tContract:', tx0['wager_amount']/config.UNIT, 'XCP', 'against', tx0['counterwager_amount']/config.UNIT, 'XCP', '(' + contract_id + ')')   # TODO

            # Debit the order.
            wager_remaining -= backward_amount

            # Update wager_remaining.
            cursor.execute('''UPDATE bets \
                              SET wager_remaining=? \
                              WHERE tx_hash=?''',
                          (int(tx0['wager_remaining'] - forward_amount),
                           tx0['tx_hash']))
            cursor.execute('''UPDATE bets \
                              SET wager_remaining=? \
                              WHERE tx_hash=?''',
                          (int(wager_remaining),
                           tx1['tx_hash']))

            # Record order fulfillment.
            cursor.execute('''INSERT into contracts(
                                tx0_index,
                                tx0_hash,
                                tx0_address,
                                tx1_index,
                                tx1_hash,
                                tx1_address,
                                feed_address,
                                bet_type,
                                time_start,
                                time_end,
                                threshold_leverage,
                                forward_amount,
                                backward_amount,
                                tx0_block_index,
                                tx1_block_index,
                                tx0_expiration,
                                tx1_expiration,
                                validity) VALUES(?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)''',
                                (tx0['tx_index'],
                                tx0['tx_hash'],
                                tx0['source'],
                                tx1['tx_index'],
                                tx1['tx_hash'],
                                tx1['source'],
                                feed_address,
                                bet_type,
                                time_start,
                                time_end,
                                threshold_leverage,
                                int(forward_amount),
                                int(backward_amount),
                                tx0['block_index'],
                                tx1['block_index'],
                                tx0['expiration'],
                                expiration,
                                validity)
                          )
            db.commit()
    return db, cursor

# TODO: How long after time_end has been passed (in blocks?!) should the bet be expired?!
def expire (db, cursor, block_index):

    # Expire bets  and give refunds for the amount wager_remaining.
    cursor.execute('''SELECT * FROM bets''')
    for bet in cursor.fetchall():
        time_left = bet['block_index'] + bet['expiration'] - block_index # Inclusive/exclusive expiration? DUPE
        if time_left <= 0 and bet['validity'] == 'Valid':
            cursor.execute('''UPDATE bets SET validity=? WHERE tx_hash=?''', ('Invalid: expired', bet['tx_hash']))
            db, cursor = util.credit(db, cursor, bet['source'], 1, bet['wager_remaining'])
            print('\tExpired bet:', bet['tx_hash'])
        db.commit()


    return db, cursor


# vim: tabstop=8 expandtab shiftwidth=4 softtabstop=4
