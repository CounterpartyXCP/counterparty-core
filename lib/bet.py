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
LENGTH = 2 + 4 + 8 + 8 + 8 + 4 + 4
ID = 40


def get_fee_multiplier (db, feed_address):
    '''Get fee_multiplier from the last broadcast from the feed_address address.
    '''
    broadcasts = util.get_broadcasts(db, source=feed_address)
    if broadcasts:
        last_broadcast = broadcasts[-1]
        fee_multiplier = last_broadcast['fee_multiplier']
        if fee_multiplier: return fee_multiplier
        else: return 0
    else:
        return 0

def validate (db, source, feed_address, bet_type, deadline, wager_amount,
              counterwager_amount, target_value, leverage, expiration):
    problems = []

    # Look at feed to be bet on.
    broadcasts = util.get_broadcasts(db, validity='Valid', source=feed_address)
    if not broadcasts:
        problems.append('feed doesn’t exist')
    elif not broadcasts[-1]['text']:
        problems.append('feed is locked')
    elif broadcasts[-1]['timestamp'] >= deadline:
        problems.append('deadline in that feed’s past')

    # Valid leverage level?
    if leverage != 5040 and bet_type in (2,3):   # Equal, NotEqual
        problems.append('leverage cannot be used with bet types Equal and NotEqual')
    if leverage < 5040:
        problems.append('leverage level too low (less than 5040, which is 1:1)')

    if not wager_amount or not counterwager_amount:
        problems.append('zero wager or counterwager')

    if target_value and bet_type in (0,1):   # BullCFD, BearCFD
        problems.append('CFDs have no target value')

    if expiration > config.MAX_EXPIRATION:
        problems.append('maximum expiration time exceeded')

    # For SQLite3
    if wager_amount > config.MAX_INT or counterwager_amount > config.MAX_INT or bet_type > config.MAX_INT or deadline > config.MAX_INT or leverage > config.MAX_INT:
        problems.append('maximum integer size exceeded')

    return problems

def create (db, source, feed_address, bet_type, deadline, wager_amount,
            counterwager_amount, target_value, leverage, expiration, unsigned=False):

    # Check for sufficient funds.
    fee_multiplier = get_fee_multiplier(db, feed_address)
    balances = util.get_balances(db, address=source, asset='XCP')
    if not balances or balances[0]['amount']/(1 + fee_multiplier / 1e8) < wager_amount :
        raise exceptions.BetError('insufficient funds to both make wager and pay feed fee (in XCP)')

    problems = validate(db, source, feed_address, bet_type, deadline, wager_amount,
                        counterwager_amount, target_value, leverage, expiration)
    if problems: raise exceptions.BetError(problems)

    data = config.PREFIX + struct.pack(config.TXTYPE_FORMAT, ID)
    data += struct.pack(FORMAT, bet_type, deadline,
                        wager_amount, counterwager_amount, target_value,
                        leverage, expiration)
    return bitcoin.transaction(source, feed_address, config.DUST_SIZE,
                               config.MIN_FEE, data, unsigned=unsigned)

def parse (db, tx, message):
    bet_parse_cursor = db.cursor()

    # Unpack message.
    try:
        assert len(message) == LENGTH
        (bet_type, deadline, wager_amount,
         counterwager_amount, target_value, leverage,
         expiration) = struct.unpack(FORMAT, message)
        validity = 'Valid'
    except struct.error as e:
        (bet_type, deadline, wager_amount,
         counterwager_amount, target_value, leverage,
         expiration) = None, None, None, None, None, None, None
        validity = 'Invalid: could not unpack'

    fee_multiplier = 0
    odds = 0
    if validity == 'Valid':
        try: odds = D(wager_amount) / D(counterwager_amount)
        except: pass

        # Overbet
        balances = util.get_balances(db, address=tx['source'], asset='XCP')
        if not balances: wager_amount = 0
        elif balances[0]['amount']/(1 + fee_multiplier / 1e8) < wager_amount:
            wager_amount = min(round(balances[0]['amount']/(1 + fee_multiplier / 1e8)), wager_amount)
            counterwager_amount = int(D(wager_amount) / odds)

        feed_address = tx['destination']
        problems = validate(db, tx['source'], feed_address, bet_type, deadline, wager_amount,
                            counterwager_amount, target_value, leverage, expiration)
        if problems: validity = 'Invalid: ' + ';'.join(problems)

    # Debit amount wagered and fee.
    if validity == 'Valid':
        fee_multiplier = get_fee_multiplier(db, feed_address)
        fee = round(wager_amount * fee_multiplier / 1e8)    # round?!
        util.debit(db, tx['block_index'], tx['source'], 'XCP', wager_amount)
        util.debit(db, tx['block_index'], tx['source'], 'XCP', fee)

    # Add parsed transaction to message-type–specific table.
    element_data = {
        'tx_index': tx['tx_index'],
        'tx_hash': tx['tx_hash'],
        'block_index': tx['block_index'],
        'source': tx['source'],
        'feed_address': feed_address,
        'bet_type': bet_type,
        'deadline': deadline,
        'wager_amount': wager_amount,
        'wager_remaining': wager_amount,
        'counterwager_amount': counterwager_amount,
        'counterwager_remaining': counterwager_amount,
        'target_value': target_value,
        'leverage': leverage,
        'expiration': expiration,
        'expire_index': tx['block_index'] + expiration,
        'fee_multiplier': fee_multiplier,
        'validity': validity,
    }
    bet_parse_cursor.execute(*util.get_insert_sql('bets', element_data))

    # Log.
    if validity == 'Valid':
        placeholder = ''
        if target_value:    # 0.0 is not a valid target value.
            placeholder = ' that ' + str(util.devise(db, target_value, 'value', 'output'))
        if leverage:
            placeholder += ', leveraged {}x'.format(util.devise(db, leverage / 5040, 'leverage', 'output'))
        logging.info('Bet: {} on {} at {} for {} XCP against {} XCP at {} odds in {} blocks{} for a fee of {} XCP ({})'.format(util.BET_TYPE_NAME[bet_type], feed_address, util.isodt(deadline), wager_amount / config.UNIT, counterwager_amount / config.UNIT, util.devise(db, odds, 'odds', dest='output'), expiration, placeholder, util.devise(db, fee, 'XCP', 'output'), tx['tx_hash']))
        match(db, tx)

    bet_parse_cursor.close()

def match (db, tx):
    bet_match_cursor = db.cursor()

    # Get bet in question.
    bet_match_cursor.execute('''SELECT * FROM bets\
                                WHERE tx_index=?''', (tx['tx_index'],))
    tx1 = bet_match_cursor.fetchall()[0]

    # Get counterbet_type.
    if tx1['bet_type'] % 2: counterbet_type = tx1['bet_type'] - 1
    else: counterbet_type = tx1['bet_type'] + 1

    feed_address = tx1['feed_address']

    bet_match_cursor.execute('''SELECT * FROM bets\
                             WHERE (feed_address=? AND validity=? AND bet_type=?)''',
                             (tx1['feed_address'], 'Valid', counterbet_type))
    wager_remaining = tx1['wager_remaining']
    counterwager_remaining = tx1['counterwager_remaining']
    bet_matches = bet_match_cursor.fetchall()
    if tx['block_index'] > 284500:  # For backwards‐compatibility (no sorting before this block).
        sorted(bet_matches, key=lambda x: x['tx_index'])                                        # Sort by tx index second.
        sorted(bet_matches, key=lambda x: D(x['wager_amount']) / D(x['counterwager_amount']))   # Sort by price first.
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
        tx0_odds = util.price(tx0['wager_amount'], tx0['counterwager_amount'])
        tx0_inverse_odds = util.price(tx0['counterwager_amount'], tx0['wager_amount'])
        tx1_odds = util.price(tx1['wager_amount'], tx1['counterwager_amount'])

        # NOTE: Old protocol.
        if tx['block_index'] < 286000: tx0_inverse_odds = D(1) / tx0_odds

        if tx0_inverse_odds <= tx1_odds:
            forward_amount = int(min(D(tx0['wager_remaining']), D(wager_remaining) / tx1_odds))
            if not forward_amount: continue
            backward_amount = round(D(forward_amount) / tx0_odds)
            bet_match_id = tx0['tx_hash'] + tx1['tx_hash']

            # Log.
            placeholder = ''
            if target_value:    # 0 is not a valid target value.
                placeholder = ' that ' + str(util.devise(db, target_value, 'value', 'output'))
            if leverage:
                placeholder += ', leveraged {}x'.format(util.devise(db, leverage / 5040, 'leverage', 'output'))
            logging.info('Bet Match: {} for {} XCP against {} for {} XCP on {} at {}{} ({})'.format(util.BET_TYPE_NAME[tx0['bet_type']], util.devise(db, forward_amount, 'XCP', 'output'), util.BET_TYPE_NAME[tx1['bet_type']], util.devise(db, backward_amount, 'XCP', 'output'), tx1['feed_address'], util.isodt(tx1['deadline']), placeholder, bet_match_id))

            # Debit the order.
            wager_remaining = wager_remaining - backward_amount
            counterwager_remaining = counterwager_remaining - forward_amount  # This may indeed be negative!

            # Update wager_remaining.
            bet_match_cursor.execute('''UPDATE bets \
                                        SET wager_remaining = ?, \
                                            counterwager_remaining = ? \
                                        WHERE tx_hash = ?''',
                                     (tx0['wager_remaining'] - forward_amount,
                                      tx0['counterwager_remaining'] - backward_amount,
                                      tx0['tx_hash']))
            bet_match_cursor.execute('''UPDATE bets \
                              SET wager_remaining = ?, \
                                  counterwager_remaining = ? \
                              WHERE tx_hash = ?''',
                          (wager_remaining,
                           counterwager_remaining,
                           tx1['tx_hash']))

            # Get last value of feed.
            initial_value = util.get_broadcasts(db, validity='Valid', source=tx1['feed_address'])[-1]['value']

            # Record bet fulfillment.
            element_data = {
                'id': tx0['tx_hash'] + tx['tx_hash'],
                'tx0_index': tx0['tx_index'],
                'tx0_hash': tx0['tx_hash'],
                'tx0_address': tx0['source'],
                'tx1_index': tx1['tx_index'],
                'tx1_hash': tx1['tx_hash'],
                'tx1_address': tx1['source'],
                'tx0_bet_type': tx0['bet_type'],
                'tx1_bet_type': tx1['bet_type'],
                'feed_address': tx1['feed_address'],
                'initial_value': initial_value,
                'deadline': tx1['deadline'],
                'target_value': tx1['target_value'],
                'leverage': tx1['leverage'],
                'forward_amount': forward_amount,
                'backward_amount': backward_amount,
                'tx0_block_index': tx0['block_index'],
                'tx1_block_index': tx1['block_index'],
                'tx0_expiration': tx0['expiration'],
                'tx1_expiration': tx1['expiration'],
                'fee_multiplier': fee_multiplier,
                'match_expire_index': min(tx0['expire_index'], tx1['expire_index']),
                'validity': 'Valid',
            }
            bet_match_cursor.execute(*util.get_insert_sql('bet_matches', element_data))

    bet_match_cursor.close()

def expire (db, block_index, block_time):
    cursor = db.cursor()

    # Expire bets and give refunds for the amount wager_remaining.
    cursor.execute('''SELECT * FROM bets \
                      WHERE (validity = ? AND expire_index < ?)''', ('Valid', block_index))
    for bet in cursor.fetchall():
        cursor.execute('''UPDATE bets SET validity=? WHERE tx_index=?''', ('Invalid: expired', bet['tx_index']))
        util.credit(db, block_index, bet['source'], 'XCP', round(bet['wager_remaining'] * (1 + bet['fee_multiplier'] / 1e8)))

        # Record bet expiration.
        element_data = {
            'bet_index': bet['tx_index'],
            'bet_hash': bet['tx_hash'],
            'block_index': block_index
        }
        cursor.execute(*util.get_insert_sql('bet_expirations', element_data))

        logging.info('Expired bet: {}'.format(bet['tx_hash']))

    # Expire bet matches whose deadline is more than two weeks before the current block time.
    cursor.execute('''SELECT * FROM bet_matches \
                      WHERE (validity = ? AND deadline < ?)''', ('Valid', block_time - config.TWO_WEEKS))
    for bet_match in cursor.fetchall():
        util.credit(db, block_index, bet_match['tx0_address'], 'XCP',
                    round(bet_match['forward_amount'] * (1 + bet_match['fee_multiplier'] / 1e8)))
        util.credit(db, block_index, bet_match['tx1_address'], 'XCP',
                    round(bet_match['backward_amount'] * (1 + bet_match['fee_multiplier'] / 1e8)))
        cursor.execute('''UPDATE bet_matches \
                          SET validity=? \
                          WHERE id = ?''', ('Invalid: expired awaiting broadcast', bet_match['id'])
                      )

        # Record bet match expiration.
        element_data = {
            'block_index': block_index,
            'bet_match_id': bet_match['tx0_hash'] + bet_match['tx1_hash']
        }
        cursor.execute(*util.get_insert_sql('bet_match_expirations', element_data))

        logging.info('Expired Bet Match: {}'.format(bet_match['tx0_hash'] + bet_match['tx1_hash']))

    cursor.close()

# vim: tabstop=8 expandtab shiftwidth=4 softtabstop=4
