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
import logging

from . import (util, config, bitcoin, exceptions, util)

FORMAT = '>HIQQdII'
ID = 40
LENGTH = 2 + 4 + 8 + 8 + 8 + 4 + 4

def get_fee_multiplier (db, feed_address):
    # Get fee_multiplier from the last broadcast from the feed_address address.
    broadcasts = util.get_broadcasts(db, source=feed_address)
    last_broadcast = broadcasts[-1]
    return last_broadcast['fee_multiplier']

def create (db, source, feed_address, bet_type, deadline, wager_amount,
            counterwager_amount, target_value, leverage, expiration, test=False):

    # Look at feed to be bet on.
    broadcasts = util.get_broadcasts(db, validity='Valid', source=feed_address)
    if not broadcasts:
        raise exceptions.FeedError('That feed doesn\'t exist.')
    elif not broadcasts[-1]['text']:
        raise exceptions.FeedError('That feed is locked.')
    elif broadcasts[-1]['timestamp'] >= deadline:
        raise exceptions.FeedError('Deadline is in that feed\'s past.')

    # Check for sufficient funds.
    fee_multiplier = get_fee_multiplier(db, feed_address)
    balances = util.get_balances(db, address=source, asset='XCP')
    if not balances or balances[0]['amount'] < wager_amount * (1 + fee_multiplier / 1e8):
        raise exceptions.BalanceError('Insufficient funds to both make wager and pay feed fee (in XCP). (Check that the database is up-to-date.)')

    # Valid leverage level?
    if leverage != 5040 and bet_type in (2,3):   # Equal, NotEqual
        raise exceptions.UselessError('Leverage cannot be used with bet types Equal and NotEqual.')
    if leverage < 5040:
        raise exceptions.UselessError('Leverage level too low (less than 5040, which is 1:1).')

    if not wager_amount or not counterwager_amount:
        raise exceptions.UselessError('Zero wager or counterwager')

    if target_value and bet_type in (0,1):   # BullCFD, BearCFD
        raise exceptions.UselessError('CFDs have no target value.')

    data = config.PREFIX + struct.pack(config.TXTYPE_FORMAT, ID)
    data += struct.pack(FORMAT, bet_type, deadline, 
                        wager_amount, counterwager_amount, target_value,
                        leverage, expiration)
    return bitcoin.transaction(source, feed_address, config.DUST_SIZE,
                               config.MIN_FEE, data, test)

def parse (db, tx, message):
    bet_parse_cursor = db.cursor()
    validity = 'Valid'

    # Unpack message.
    try:
        (bet_type, deadline, wager_amount,
         counterwager_amount, target_value, leverage,
         expiration) = struct.unpack(FORMAT, message)
    except Exception:
        (bet_type, deadline, wager_amount,
         counterwager_amount, target_value, leverage,
         expiration) = None, None, None, None, None, None, None
        validity = 'Invalid: could not unpack'

    # Look at feed to be bet on.
    feed_address = tx['destination']
    if validity == 'Valid':
        broadcasts = util.get_broadcasts(db, validity='Valid', source=feed_address)
        if not broadcasts:
            validity = 'Invalid: no such feed'
        elif not broadcasts[-1]['text']:
            validity = 'Invalid: locked feed'
        elif broadcasts[-1]['timestamp'] >= deadline:
            validity = 'Invalid: deadline is in that feed\'s past'

    # Leverage < 5040 is allowed.

    if validity == 'Valid':
        if not wager_amount or not counterwager_amount:
            validity = 'Invalid: zero wager or zero counterwager.'

    if validity == 'Valid' and leverage != 5040 and bet_type in (2,3):   # Equal, NotEqual
        validity  = 'Invalid: leverage used with an inappropriate bet type.'

    # Debit amount wagered and fee.
    if validity == 'Valid':
        fee_multiplier = get_fee_multiplier(db, feed_address)
        fee = round(wager_amount * fee_multiplier / 1e8)
        validity = util.debit(db, tx['source'], 'XCP', wager_amount)
        validity = util.debit(db, tx['source'], 'XCP', fee)

        wager_amount = round(wager_amount)
        counterwager_amount = round(counterwager_amount)
        odds = wager_amount / counterwager_amount
    else:
        odds = 0

    # Add parsed transaction to message-type–specific table.
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
                        fee_multiplier,
                        validity) VALUES(?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)''',
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
                        fee_multiplier,
                        validity)
                  )

    # Log.
    if validity == 'Valid':
        placeholder = ''
        if target_value:    # 0.0 is not a valid target value.
            placeholder = ' that ' + str(util.devise(db, target_value, 'value', 'output'))
        if leverage:
            placeholder += ', leveraged {}x'.format(util.devise(db, leverage / 5040, 'leverage', 'output'))
        logging.info('Bet: {} on {} at {} for {} XCP against {} XCP in {} blocks{} for a fee of {} XCP ({})'.format(util.BET_TYPE_NAME[bet_type], feed_address, util.isodt(deadline), wager_amount / config.UNIT, counterwager_amount / config.UNIT, expiration, placeholder, util.devise(db, fee, 'XCP', 'output'), util.short(tx['tx_hash'])))
        match(db, tx)

    bet_parse_cursor.close()

def match (db, tx):
    bet_match_cursor = db.cursor()

    # Get bet in question.
    bet_match_cursor.execute('''SELECT * FROM bets\
                      WHERE tx_index=?''', (tx['tx_index'],))
    tx1 = bet_match_cursor.fetchone()

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

        # Bet types must be opposite.
        if not counterbet_type == tx0['bet_type']: continue
        if tx0['leverage'] == tx1['leverage']:
            leverage = tx0['leverage']
        else:
            continue

        # Target values must agree exactly.
        if tx0['target_value'] == tx1['target_value']:
            target_value = tx0['target_value']
        else:
            continue

        # Fee multipliers must agree exactly.
        if tx0['fee_multiplier'] != tx1['fee_multiplier']:
            continue
        else:
            fee_multiplier = tx0['fee_multiplier']

        # Deadlines must agree exactly.
        if tx0['deadline'] != tx1['deadline']:
            continue

        # Make sure that that both bets still have funds remaining [to be wagered].
        if tx0['wager_remaining'] <= 0 or wager_remaining <= 0: continue

        # If the odds agree, make the trade. The found order sets the odds,
        # and they trade as much as they can.
        if 1 / tx0['odds'] <= tx1['odds']:
            forward_amount = round(max(D(tx0['wager_remaining']), wager_remaining / D(tx1['odds'])))
            backward_amount = round(forward_amount / D(tx0['odds']))

            bet_match_id = tx0['tx_hash'] + tx1['tx_hash']

            # Log.
            placeholder = ''
            if target_value:    # 0 is not a valid target value.
                placeholder = ' that ' + str(util.devise(db, target_value, 'value', 'output'))
            if leverage:
                placeholder += ', leveraged {}x'.format(util.devise(db, leverage / 5040, 'leverage', 'output'))
            logging.info('Bet Match: {} for {} XCP against {} for {} XCP on {} at {}{} ({})'.format(util.BET_TYPE_NAME[tx0['bet_type']], util.devise(db, forward_amount, 'XCP', 'output'), util.BET_TYPE_NAME[tx1['bet_type']], util.devise(db, backward_amount, 'XCP', 'output'), tx1['feed_address'], util.isodt(tx1['deadline']), placeholder, util.short(bet_match_id)))

            # Debit the order.
            wager_remaining = round(wager_remaining - backward_amount)

            # Update wager_remaining.
            bet_match_cursor.execute('''UPDATE bets \
                              set wager_remaining=? \
                              where tx_hash=?''',
                          (tx0['wager_remaining'] - forward_amount,
                           tx0['tx_hash']))
            bet_match_cursor.execute('''UPDATE bets \
                              SET wager_remaining=? \
                              WHERE tx_hash=?''',
                          (wager_remaining,
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
                                fee_multiplier,
                                validity) VALUES(?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)''',
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
                                forward_amount,
                                backward_amount,
                                tx0['block_index'],
                                tx1['block_index'],
                                tx0['expiration'],
                                tx1['expiration'],
                                fee_multiplier,
                                'Valid')
                          )

    bet_match_cursor.close()

def expire (db, block_index):
    # Expire bets and give refunds for the amount wager_remaining.
    bet_expire_cursor = db.cursor()
    bet_expire_cursor.execute('''SELECT * FROM bets''')
    for bet in bet_expire_cursor.fetchall():
        if bet['validity'] == 'Valid' and util.get_time_left(bet, block_index=block_index) < 0:
            bet_expire_cursor.execute('''UPDATE bets SET validity=? WHERE tx_hash=?''', ('Invalid: expired', bet['tx_hash']))
            util.credit(db, bet['source'], 'XCP', round(bet['wager_remaining'] * (1 + bet['fee_multiplier'] / 1e8)))
            logging.info('Expired bet: {}'.format(util.short(bet['tx_hash'])))
    bet_expire_cursor.close()

    # Expire bet matches whose deadline was passed 2016 blocks ago.
    bet_expire_match_cursor = db.cursor()
    bet_expire_match_cursor.execute('''SELECT * FROM blocks \
                                  WHERE block_index<=?''', (block_index - 2016,)
                              )
    bet_matches = util.get_bet_matches(db, validity='Valid')
    for old_block in bet_expire_match_cursor.fetchall():
        for bet_match in bet_matches:
            if bet_match['deadline'] < old_block['block_time']:
                bet_expire_match_cursor.execute('''UPDATE bet_matches \
                                              SET validity=? \
                                              WHERE (tx0_hash=? AND tx1_hash=?)''', ('Invalid: expired awaiting broadcast', bet_match['tx0_hash'], bet_match['tx1_hash'])
                                             )
                util.credit(db, bet_match['tx0_address'], 'XCP',
                            round(bet_match['forward_amount'] * (1 + bet_match['fee_multiplier'] / 1e8)))
                util.credit(db, bet_match['tx1_address'], 'XCP',
                            round(bet_match['backward_amount'] * (1 + bet_match['fee_multiplier'] / 1e8)))
                logging.info('Expired Bet Match: {}'.format(util.short(bet_match['tx0_hash'] + bet_match['tx1_hash'])))

    bet_expire_match_cursor.close()

# vim: tabstop=8 expandtab shiftwidth=4 softtabstop=4
