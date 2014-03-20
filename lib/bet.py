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

from . import (util, config, bitcoin, exceptions, util)

FORMAT = '>HIQQdII'
LENGTH = 2 + 4 + 8 + 8 + 8 + 4 + 4
ID = 40


def get_fee_fraction (db, feed_address):
    '''Get fee fraction from the last broadcast from the feed_address address.
    '''
    broadcasts = util.get_broadcasts(db, source=feed_address)
    if broadcasts:
        last_broadcast = broadcasts[-1]
        fee_fraction_int = last_broadcast['fee_fraction_int']
        if fee_fraction_int: return fee_fraction_int / 1e8
        else: return 0
    else:
        return 0

def validate (db, source, feed_address, bet_type, deadline, wager_quantity,
              counterwager_quantity, target_value, leverage, expiration):
    problems = []

    # Look at feed to be bet on.
    broadcasts = util.get_broadcasts(db, status='valid', source=feed_address)
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

    if not isinstance(wager_quantity, int):
        problems.append('wager_quantity must be in satoshis')
        return problems
    if not isinstance(counterwager_quantity, int):
        problems.append('counterwager_quantity must be in satoshis')
        return problems
    if not isinstance(expiration, int):
        problems.append('expiration must be expressed as an integer block delta')
        return problems

    if wager_quantity <= 0: problems.append('non‐positive wager')
    if counterwager_quantity <= 0: problems.append('non‐positive counterwager')
    if target_value < 0: problems.append('negative target value')
    if deadline < 0: problems.append('negative deadline')
    if expiration <= 0: problems.append('non‐positive expiration')

    if target_value and bet_type in (0,1):   # BullCFD, BearCFD
        problems.append('CFDs have no target value')

    if expiration > config.MAX_EXPIRATION:
        problems.append('maximum expiration time exceeded')

    # For SQLite3
    if wager_quantity > config.MAX_INT or counterwager_quantity > config.MAX_INT or bet_type > config.MAX_INT or deadline > config.MAX_INT or leverage > config.MAX_INT:
        problems.append('maximum integer size exceeded')

    return problems

def compose (db, source, feed_address, bet_type, deadline, wager_quantity,
            counterwager_quantity, target_value, leverage, expiration):

    # Check for sufficient funds.
    fee_fraction = get_fee_fraction(db, feed_address)
    balances = util.get_balances(db, address=source, asset='XCP')
    if not balances or balances[0]['quantity']/(1 + fee_fraction) < wager_quantity :
        raise exceptions.BetError('insufficient funds to both make wager and pay feed fee (in XCP)')

    problems = validate(db, source, feed_address, bet_type, deadline, wager_quantity,
                        counterwager_quantity, target_value, leverage, expiration)
    if problems: raise exceptions.BetError(problems)

    data = config.PREFIX + struct.pack(config.TXTYPE_FORMAT, ID)
    data += struct.pack(FORMAT, bet_type, deadline,
                        wager_quantity, counterwager_quantity, target_value,
                        leverage, expiration)
    return (source, [(feed_address, None)], config.MIN_FEE,
                               data)

def parse (db, tx, message):
    bet_parse_cursor = db.cursor()

    # Unpack message.
    try:
        assert len(message) == LENGTH
        (bet_type, deadline, wager_quantity,
         counterwager_quantity, target_value, leverage,
         expiration) = struct.unpack(FORMAT, message)
        status = 'valid'
    except struct.error as e:
        (bet_type, deadline, wager_quantity,
         counterwager_quantity, target_value, leverage,
         expiration) = None, None, None, None, None, None, None
        status = 'invalid: could not unpack'

    fee_fraction = 0
    odds = 0
    if status == 'valid':
        feed_address = tx['destination']
        fee_fraction = get_fee_fraction(db, feed_address)

        try: odds = D(wager_quantity) / D(counterwager_quantity)
        except: pass

        problems = validate(db, tx['source'], feed_address, bet_type, deadline, wager_quantity,
                            counterwager_quantity, target_value, leverage, expiration)
        if problems: status = 'invalid: ' + ';'.join(problems)

    if status == 'valid':
        # Overbet
        balances = util.get_balances(db, address=tx['source'], asset='XCP')
        if not balances: wager_quantity = 0
        elif balances[0]['quantity']/(1 + fee_fraction) < wager_quantity:
            wager_quantity = min(round(balances[0]['quantity']/(1 + fee_fraction)), wager_quantity)
            counterwager_quantity = int(D(wager_quantity) / odds)

    # Debit quantity wagered and fee.
    if status == 'valid':
        fee = round(wager_quantity * fee_fraction)    # round?!
        util.debit(db, tx['block_index'], tx['source'], 'XCP', wager_quantity)
        util.debit(db, tx['block_index'], tx['source'], 'XCP', fee)

    # Add parsed transaction to message-type–specific table.
    bindings = {
        'tx_index': tx['tx_index'],
        'tx_hash': tx['tx_hash'],
        'block_index': tx['block_index'],
        'source': tx['source'],
        'feed_address': feed_address,
        'bet_type': bet_type,
        'deadline': deadline,
        'wager_quantity': wager_quantity,
        'wager_remaining': wager_quantity,
        'counterwager_quantity': counterwager_quantity,
        'counterwager_remaining': counterwager_quantity,
        'target_value': target_value,
        'leverage': leverage,
        'expiration': expiration,
        'expire_index': tx['block_index'] + expiration,
        'fee_fraction_int': fee_fraction * 1e8,
        'status': status,
    }
    sql='insert into bets values(:tx_index, :tx_hash, :block_index, :source, :feed_address, :bet_type, :deadline, :wager_quantity, :wager_remaining, :counterwager_quantity, :counterwager_remaining, :target_value, :leverage, :expiration, :expire_index, :fee_fraction_int, :status)'
    bet_parse_cursor.execute(sql, bindings)

    # Match.
    match(db, tx)

    bet_parse_cursor.close()

def match (db, tx):
    cursor = db.cursor()

    # Get bet in question.
    bets = list(cursor.execute('''SELECT * FROM bets\
                                WHERE tx_index=?''', (tx['tx_index'],)))
    assert len(bets) == 1
    tx1 = bets[0]

    # Get counterbet_type.
    if tx1['bet_type'] % 2: counterbet_type = tx1['bet_type'] - 1
    else: counterbet_type = tx1['bet_type'] + 1

    feed_address = tx1['feed_address']

    cursor.execute('''SELECT * FROM bets\
                             WHERE (feed_address=? AND status=? AND bet_type=?)''',
                             (tx1['feed_address'], 'valid', counterbet_type))
    tx1_wager_remaining = tx1['wager_remaining']
    tx1_counterwager_remaining = tx1['counterwager_remaining']
    bet_matches = cursor.fetchall()
    if tx['block_index'] > 284500 or config.TESTNET:  # Protocol change.
        sorted(bet_matches, key=lambda x: x['tx_index'])                                        # Sort by tx index second.
        sorted(bet_matches, key=lambda x: D(x['wager_quantity']) / D(x['counterwager_quantity']))   # Sort by price first.
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

        # Fee fractions must agree exactly.
        if tx0['fee_fraction_int'] != tx1['fee_fraction_int']:
            continue
        else:
            fee_fraction_int = tx0['fee_fraction_int']

        # Deadlines must agree exactly.
        if tx0['deadline'] != tx1['deadline']:
            continue

        # Make sure that that both bets still have funds remaining [to be wagered].
        if tx0['wager_remaining'] <= 0 or tx1_wager_remaining <= 0: continue
        if tx1['block_index'] >= 292000 or config.TESTNET:  # Protocol change
            if tx0['counterwager_remaining'] <= 0 or tx1_counterwager_remaining <= 0: continue

        # If the odds agree, make the trade. The found order sets the odds,
        # and they trade as much as they can.
        tx0_odds = util.price(tx0['wager_quantity'], tx0['counterwager_quantity'])
        tx0_inverse_odds = util.price(tx0['counterwager_quantity'], tx0['wager_quantity'])
        tx1_odds = util.price(tx1['wager_quantity'], tx1['counterwager_quantity'])

        if tx['block_index'] < 286000: tx0_inverse_odds = D(1) / tx0_odds # Protocol change.

        if tx0_inverse_odds <= tx1_odds:
            forward_quantity = int(min(D(tx0['wager_remaining']), D(tx1_wager_remaining) / tx1_odds))
            backward_quantity = round(D(forward_quantity) / tx0_odds)

            if not forward_quantity: continue
            if tx1['block_index'] >= 286500 or config.TESTNET:    # Protocol change.
                if not backward_quantity: continue

            bet_match_id = tx0['tx_hash'] + tx1['tx_hash']

            # Debit the order.
            # Counterwager remainings may be negative.
            tx0_wager_remaining = tx0['wager_remaining'] - forward_quantity
            tx0_counterwager_remaining = tx0['counterwager_remaining'] - backward_quantity
            tx1_wager_remaining = tx1_wager_remaining - backward_quantity
            tx1_counterwager_remaining = tx1_counterwager_remaining - forward_quantity

            # tx0
            bindings = {
                'wager_remaining': tx0_wager_remaining,
                'counterwager_remaining': tx0_counterwager_remaining,
                'tx_index': tx0['tx_index']
            }
            sql='update bets set wager_remaining = :wager_remaining, counterwager_remaining = :counterwager_remaining where tx_index = :tx_index'
            cursor.execute(sql, bindings)
            util.message(db, tx1['block_index'], 'update', 'bets', bindings)

            # tx1
            bindings = {
                'wager_remaining': tx1_wager_remaining,
                'counterwager_remaining': tx1_counterwager_remaining,
                'tx_index': tx1['tx_index']
            }
            sql='update bets set wager_remaining = :wager_remaining, counterwager_remaining = :counterwager_remaining where tx_index = :tx_index'
            cursor.execute(sql, bindings)
            util.message(db, tx1['block_index'], 'update', 'bets', bindings)

            # Get last value of feed.
            initial_value = util.get_broadcasts(db, status='valid', source=tx1['feed_address'])[-1]['value']

            # Record bet fulfillment.
            bindings = {
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
                'forward_quantity': forward_quantity,
                'backward_quantity': backward_quantity,
                'tx0_block_index': tx0['block_index'],
                'tx1_block_index': tx1['block_index'],
                'tx0_expiration': tx0['expiration'],
                'tx1_expiration': tx1['expiration'],
                'match_expire_index': min(tx0['expire_index'], tx1['expire_index']),
                'fee_fraction_int': fee_fraction_int,
                'status': 'pending',
            }
            sql='insert into bet_matches values(:id, :tx0_index, :tx0_hash, :tx0_address, :tx1_index, :tx1_hash, :tx1_address, :tx0_bet_type, :tx1_bet_type, :feed_address, :initial_value, :deadline, :target_value, :leverage, :forward_quantity, :backward_quantity, :tx0_block_index, :tx1_block_index, :tx0_expiration, :tx1_expiration, :match_expire_index, :fee_fraction_int, :status)'
            cursor.execute(sql, bindings)

    cursor.close()

def expire (db, block_index, block_time):
    cursor = db.cursor()

    # Expire bets and give refunds for the quantity wager_remaining.
    cursor.execute('''SELECT * FROM bets \
                      WHERE (status = ? AND expire_index < ?)''', ('valid', block_index))
    for bet in cursor.fetchall():

        # Update status of bet.
        bindings = {
            'status': 'expired',
            'tx_index': bet['tx_index']
        }
        sql='update bets set status = :status where tx_index = :tx_index'
        cursor.execute(sql, bindings)
        util.message(db, block_index, 'update', 'bets', bindings)

        util.credit(db, block_index, bet['source'], 'XCP', round(bet['wager_remaining'] * (1 + bet['fee_fraction_int'] / 1e8)))

        # Record bet expiration.
        bindings = {
            'bet_index': bet['tx_index'],
            'bet_hash': bet['tx_hash'],
            'source': bet['source'],
            'block_index': block_index
        }
        sql='insert into bet_expirations values(:bet_index, :bet_hash, :source, :block_index)'
        cursor.execute(sql, bindings)

    # Expire bet matches whose deadline is more than two weeks before the current block time.
    cursor.execute('''SELECT * FROM bet_matches \
                      WHERE (status = ? AND deadline < ?)''', ('pending', block_time - config.TWO_WEEKS))
    for bet_match in cursor.fetchall():
        util.credit(db, block_index, bet_match['tx0_address'], 'XCP',
                    round(bet_match['forward_quantity'] * (1 + bet_match['fee_fraction_int'] / 1e8)))
        util.credit(db, block_index, bet_match['tx1_address'], 'XCP',
                    round(bet_match['backward_quantity'] * (1 + bet_match['fee_fraction_int'] / 1e8)))

        # Update status of bet match.
        bindings = {
            'status': 'expired',
            'bet_match_id': bet_match['id']
        }
        sql='update bet_matches set status = :status where id = :bet_match_id'
        cursor.execute(sql, bindings)
        util.message(db, block_index, 'update', 'bet_matches', bindings)

        # Record bet match expiration.
        bindings = {
            'block_index': block_index,
            'tx0_address': bet_match['tx0_address'],
            'tx1_address': bet_match['tx1_address'],
            'bet_match_id': bet_match['tx0_hash'] + bet_match['tx1_hash']
        }
        sql='insert into bet_match_expirations values(:block_index, :tx0_address, :tx1_address, :bet_match_id)'
        cursor.execute(sql, bindings)

    cursor.close()

# vim: tabstop=8 expandtab shiftwidth=4 softtabstop=4
