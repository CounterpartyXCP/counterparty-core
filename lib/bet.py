#! /usr/bin/python3

"""
Datastreams are identified by the address that publishes them, and referenced
in transaction outputs.

For CFD leverage, 1x = 5040, 2x = 10080, etc.: 5040 is a superior highly
composite number and a colossally abundant number, and has 1-10, 12 as factors.

All wagers are in XCP.
"""

import struct
import decimal
D = decimal.Decimal
# decimal.getcontext().prec = 8
import logging

from . import (util, config, bitcoin, exceptions, util)

FORMAT = '>HIQQdII'
ID = 40
LENGTH = 2 + 4 + 8 + 8 + 8 + 4 + 4

def get_fee_multiplier (db, feed_address):
    # Get fee_multiplier from the last broadcast from the feed_address address.
    broadcasts = util.get_broadcasts(db, source=feed_address)
    last_broadcast = broadcasts[-1]
    return D(last_broadcast['fee_multiplier'] / 1e8)

def create (db, source, feed_address, bet_type, deadline, wager_amount,
            counterwager_amount, target_value, leverage, expiration, test=False):
    good_feed = util.good_feed(db, feed_address)
    if good_feed == None:
        raise exceptions.FeedError('That feed doesn’t exist.')
    elif not good_feed:
        raise exceptions.FeedError('That feed is locked.')

    if not wager_amount or not counterwager_amount:
        raise exceptions.UselessError('Zero wager or counterwager')

    fee_multiplier = get_fee_multiplier(db, feed_address)
    balances = util.get_balances(db, address=source, asset_id=1)
    if not balances or balances[0]['amount'] < wager_amount * (1 + fee_multiplier):
        raise exceptions.BalanceError('Insufficient funds to both make wager and pay feed fee (in XCP). (Check that the database is up‐to‐date.)')

    # Store a null target_value as a zero float.
    if not target_value: target_value = 0.0

    if leverage and bet_type in (2,3):   # Equal, NotEqual
        raise exceptions.UselessError('Leverage cannot be used with bet types Equal and NotEqual.')

    data = config.PREFIX + struct.pack(config.TXTYPE_FORMAT, ID)
    data += struct.pack(FORMAT, bet_type, deadline, 
                        int(wager_amount), int(counterwager_amount), target_value, int(leverage),
                        expiration)

    return bitcoin.transaction(source, feed_address, config.DUST_SIZE,
                               config.MIN_FEE, data, test)

def parse (db, tx, message):
    bet_parse_cursor = db.cursor()

    # Ask for forgiveness…
    validity = 'Valid'

    # Unpack message.
    try:
        (bet_type, deadline, wager_amount,
         counterwager_amount, target_value, leverage,
         expiration) = struct.unpack(FORMAT, message)
    except Exception:   #
        (bet_type, deadline, wager_amount,
         counterwager_amount, target_value, leverage,
         expiration) = None, None, None, None, None, None, None
        validity = 'Invalid: could not unpack'

    feed_address = tx['destination']
    if validity == 'Valid':
        good_feed = util.good_feed(db, feed_address)
        if good_feed == None:
            validity = 'Invalid: no such feed'
        elif not good_feed:
            validity = 'Invalid: locked feed'

    if validity == 'Valid':
        if not wager_amount or not counterwager_amount:
            validity = 'Invalid: zero wager or zero counterwager.'

    if validity == 'Valid' and leverage and bet_type in (2,3):   # Equal, NotEqual
        validity  = 'Invalid: leverage used with an inappropriate bet type.'

    if validity == 'Valid':
        # Debit amount wagered and fee.
        fee_multiplier = get_fee_multiplier(db, feed_address)
        validity = util.debit(db, tx['source'], 1, round(wager_amount * (1 + fee_multiplier)))

        wager_amount = int(wager_amount)
        counterwager_amount = int(counterwager_amount)
        odds = wager_amount / counterwager_amount
    else:
        odds = 0

    # Add parsed transaction to message‐type–specific table.
    bet_parse_cursor.execute('''INSERT INTO bets(
                        tx_index,
                        tx_hash,
                        block_index,
                        source,
                        feed_address,
                        bet_type,
                        deadline,
                        wager_amount,
                        counterwager_amount,
                        wager_remaining,
                        odds,
                        target_value,
                        leverage,
                        expiration,
                        validity) VALUES(?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)''',
                        (tx['tx_index'],
                        tx['tx_hash'],
                        tx['block_index'],
                        tx['source'],
                        feed_address,
                        bet_type,
                        deadline,
                        wager_amount,
                        counterwager_amount,
                        wager_amount,
                        odds,
                        target_value,
                        leverage,
                        expiration,
                        validity)
                  )

    if validity == 'Valid':
        placeholder = ''
        if target_value:    # 0 is not a valid target value.
            placeholder = ' that ' + str(D(target_value).quantize(config.FOUR).normalize())
        if leverage:
            placeholder += ', leveraged {}x'.format(str(D(leverage / 5040).quantize(config.FOUR).normalize()))
        logging.info('Bet: {} on {} at {} for {} XCP against {} XCP in {} blocks{} ({})'.format(util.BET_TYPE_NAME[bet_type], feed_address, util.isodt(deadline), wager_amount / config.UNIT, counterwager_amount / config.UNIT, expiration, placeholder, util.short(tx['tx_hash'])))
        match(db, tx)

    bet_parse_cursor.close()

def match (db, tx):
    bet_match_cursor = db.cursor()

    # Get bet in question.
    bet_match_cursor.execute('''SELECT * FROM bets\
                      WHERE tx_index=?''', (tx['tx_index'],))
    tx1 = bet_match_cursor.fetchone()
    assert not bet_match_cursor.fetchone()

    # Get counterbet_type.
    if tx1['bet_type'] % 2: counterbet_type = tx1['bet_type'] - 1
    else: counterbet_type = tx1['bet_type'] + 1

    feed_address = tx1['feed_address']
    bet_match_cursor.execute('''SELECT * FROM bets\
                      WHERE (feed_address=? AND block_index>=? AND validity=? AND bet_type=?) \
                      ORDER BY odds DESC, tx_index''',
                   (tx1['feed_address'], tx1['block_index'] - tx1['expiration'], 'Valid', counterbet_type))
    wager_remaining = D(tx1['wager_remaining'])
    bet_matches = bet_match_cursor.fetchall()
    for tx0 in bet_matches:
        if not counterbet_type == tx0['bet_type']: continue
        if tx0['leverage'] == tx1['leverage']:
            leverage = tx0['leverage']
        else:
            continue
        if tx0['target_value'] == tx1['target_value']:
            target_value = tx0['target_value']
        else:
            continue

        # Make sure that that both bets still have funds remaining [to be wagered].
        if tx0['wager_remaining'] <= 0 or wager_remaining <= 0: continue

        # If the odds agree, make the trade. The found order sets the odds,
        # and they trade as much as they can.
        if tx0['odds'] <= 1 / tx1['odds']:
            forward_amount = round(min(D(tx0['wager_remaining']), wager_remaining / D(tx1['odds'])))
            backward_amount = round(forward_amount / D(tx0['odds']))

            # When a match is made, pay XCP fee.
            fee = get_fee_multiplier(db, tx1['feed_address']) * backward_amount
            validity = util.debit(db, tx1['source'], 1, round(fee))
            if validity != 'Valid': continue
            util.credit(db, tx1['feed_address'], 1, int(fee))

            bet_match_id = tx0['tx_hash'] + tx1['tx_hash']

            placeholder = ''
            if target_value:    # 0 is not a valid target value.
                placeholder = ' that ' + str(D(target_value).quantize(config.FOUR).normalize())
            if leverage:
                placeholder += ', leveraged {}x'.format(str(D(leverage / 5040).quantize(config.FOUR).normalize()))
            logging.info('Bet Match: {} for {} XCP against {} for {} XCP on {} at {}{} ({})'.format(util.BET_TYPE_NAME[tx0['bet_type']], forward_amount / config.UNIT, util.BET_TYPE_NAME[tx1['bet_type']], backward_amount / config.UNIT, tx1['feed_address'], util.isodt(tx1['deadline']), placeholder, util.short(bet_match_id)))

            # Debit the order.
            wager_remaining -= backward_amount

            # Update wager_remaining.
            bet_match_cursor.execute('''UPDATE bets \
                              SET wager_remaining=? \
                              WHERE tx_hash=?''',
                          (int(tx0['wager_remaining'] - forward_amount),
                           tx0['tx_hash']))
            bet_match_cursor.execute('''UPDATE bets \
                              SET wager_remaining=? \
                              WHERE tx_hash=?''',
                          (int(wager_remaining),
                           tx1['tx_hash']))

            # Get last value of feed.
            initial_value = util.get_broadcasts(db, validity='Valid', source=tx1['feed_address'])[-1]['value']

            # Record order fulfillment.
            bet_match_cursor.execute('''INSERT into bet_matches(
                                tx0_index,
                                tx0_hash,
                                tx0_address,
                                tx1_index,
                                tx1_hash,
                                tx1_address,
                                tx0_bet_type,
                                tx1_bet_type,
                                feed_address,
                                initial_value,
                                deadline,
                                target_value,
                                leverage,
                                forward_amount,
                                backward_amount,
                                tx0_block_index,
                                tx1_block_index,
                                tx0_expiration,
                                tx1_expiration,
                                validity) VALUES(?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)''',
                                (tx0['tx_index'],
                                tx0['tx_hash'],
                                tx0['source'],
                                tx1['tx_index'],
                                tx1['tx_hash'],
                                tx1['source'],
                                tx0['bet_type'],
                                tx1['bet_type'],
                                tx1['feed_address'],
                                initial_value,
                                tx1['deadline'],
                                tx1['target_value'],
                                tx1['leverage'],
                                int(forward_amount),
                                int(backward_amount),
                                tx0['block_index'],
                                tx1['block_index'],
                                tx0['expiration'],
                                tx1['expiration'],
                                validity)
                          )

    bet_match_cursor.close()

# TODO: How long after deadline has been passed (in blocks?!) should the bet be expired?!
def expire (db, block_index):

    bet_expire_cursor = db.cursor()

    # Expire bets  and give refunds for the amount wager_remaining.
    bet_expire_cursor.execute('''SELECT * FROM bets''')
    bets = bet_expire_cursor.fetchall()
    for bet in bets:
        if util.get_time_left(bet) < 0 and bet['validity'] == 'Valid':
            bet_expire_cursor.execute('''UPDATE bets SET validity=? WHERE tx_hash=?''', ('Invalid: expired', bet['tx_hash']))
            util.credit(db, bet['source'], 1, bet['wager_remaining'])
            logging.info('Expired bet: {}'.format(bet['tx_hash']))

    bet_expire_cursor.close()


# vim: tabstop=8 expandtab shiftwidth=4 softtabstop=4
