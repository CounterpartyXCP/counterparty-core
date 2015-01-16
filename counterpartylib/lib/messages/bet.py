#! /usr/bin/python3

"""
Datastreams are identified by the address that publishes them, and referenced
in transaction outputs.

For CFD leverage, 1x = 5040, 2x = 10080, etc.: 5040 is a superior highly
composite number and a colossally abundant number, and has 1-10, 12 as factors.

All wagers are in XCP.

Expiring a bet match doesn’t re‐open the constituent bets. (So all bets may be ‘filled’.)
"""

import struct
import decimal
D = decimal.Decimal
import time
import logging
logger = logging.getLogger(__name__)

from counterpartylib.lib import config
from counterpartylib.lib import exceptions
from counterpartylib.lib import util
from counterpartylib.lib import log

FORMAT = '>HIQQdII'
LENGTH = 2 + 4 + 8 + 8 + 8 + 4 + 4
ID = 40

def initialise (db):
    cursor = db.cursor()

    # Bets.
    cursor.execute('''CREATE TABLE IF NOT EXISTS bets(
                      tx_index INTEGER UNIQUE,
                      tx_hash TEXT UNIQUE,
                      block_index INTEGER,
                      source TEXT,
                      feed_address TEXT,
                      bet_type INTEGER,
                      deadline INTEGER,
                      wager_quantity INTEGER,
                      wager_remaining INTEGER,
                      counterwager_quantity INTEGER,
                      counterwager_remaining INTEGER,
                      target_value REAL,
                      leverage INTEGER,
                      expiration INTEGER,
                      expire_index INTEGER,
                      fee_fraction_int INTEGER,
                      status TEXT,
                      FOREIGN KEY (tx_index, tx_hash, block_index) REFERENCES transactions(tx_index, tx_hash, block_index),
                      PRIMARY KEY (tx_index, tx_hash))
                  ''')
    cursor.execute('''CREATE INDEX IF NOT EXISTS
                      block_index_idx ON bets (block_index)
                   ''')
    cursor.execute('''CREATE INDEX IF NOT EXISTS
                      index_hash_idx ON bets (tx_index, tx_hash)
                   ''')
    cursor.execute('''CREATE INDEX IF NOT EXISTS
                      expire_idx ON bets (status, expire_index)
                   ''')
    cursor.execute('''CREATE INDEX IF NOT EXISTS
                      feed_valid_bettype_idx ON bets (feed_address, status, bet_type)
                   ''')
    cursor.execute('''CREATE INDEX IF NOT EXISTS
                      source_idx ON bets (source)
                   ''')
    cursor.execute('''CREATE INDEX IF NOT EXISTS
                      status_idx ON bets (status)
                   ''')

    # Bet Matches
    cursor.execute('''CREATE TABLE IF NOT EXISTS bet_matches(
                      id TEXT PRIMARY KEY,
                      tx0_index INTEGER,
                      tx0_hash TEXT,
                      tx0_address TEXT,
                      tx1_index INTEGER,
                      tx1_hash TEXT,
                      tx1_address TEXT,
                      tx0_bet_type INTEGER,
                      tx1_bet_type INTEGER,
                      feed_address TEXT,
                      initial_value INTEGER,
                      deadline INTEGER,
                      target_value REAL,
                      leverage INTEGER,
                      forward_quantity INTEGER,
                      backward_quantity INTEGER,
                      tx0_block_index INTEGER,
                      tx1_block_index INTEGER,
                      block_index INTEGER,
                      tx0_expiration INTEGER,
                      tx1_expiration INTEGER,
                      match_expire_index INTEGER,
                      fee_fraction_int INTEGER,
                      status TEXT,
                      FOREIGN KEY (tx0_index, tx0_hash, tx0_block_index) REFERENCES transactions(tx_index, tx_hash, block_index),
                      FOREIGN KEY (tx1_index, tx1_hash, tx1_block_index) REFERENCES transactions(tx_index, tx_hash, block_index))
                   ''')
    cursor.execute('''CREATE INDEX IF NOT EXISTS
                      match_expire_idx ON bet_matches (status, match_expire_index)
                   ''')
    cursor.execute('''CREATE INDEX IF NOT EXISTS
                      valid_feed_idx ON bet_matches (feed_address, status)
                   ''')
    cursor.execute('''CREATE INDEX IF NOT EXISTS
                      id_idx ON bet_matches (id)
                   ''')
    cursor.execute('''CREATE INDEX IF NOT EXISTS
                      tx0_address_idx ON bet_matches (tx0_address)
                   ''')
    cursor.execute('''CREATE INDEX IF NOT EXISTS
                      tx1_address_idx ON bet_matches (tx1_address)
                   ''')
    cursor.execute('''CREATE INDEX IF NOT EXISTS
                      status_idx ON bet_matches (status)
                   ''')

    # Bet Expirations
    cursor.execute('''CREATE TABLE IF NOT EXISTS bet_expirations(
                      bet_index INTEGER PRIMARY KEY,
                      bet_hash TEXT UNIQUE,
                      source TEXT,
                      block_index INTEGER,
                      FOREIGN KEY (block_index) REFERENCES blocks(block_index),
                      FOREIGN KEY (bet_index, bet_hash) REFERENCES bets(tx_index, tx_hash))
                   ''')
    cursor.execute('''CREATE INDEX IF NOT EXISTS
                      block_index_idx ON bet_expirations (block_index)
                   ''')
    cursor.execute('''CREATE INDEX IF NOT EXISTS
                      source_idx ON bet_expirations (source)
                   ''')

    # Bet Match Expirations
    cursor.execute('''CREATE TABLE IF NOT EXISTS bet_match_expirations(
                      bet_match_id TEXT PRIMARY KEY,
                      tx0_address TEXT,
                      tx1_address TEXT,
                      block_index INTEGER,
                      FOREIGN KEY (bet_match_id) REFERENCES bet_matches(id),
                      FOREIGN KEY (block_index) REFERENCES blocks(block_index))
                   ''')
    cursor.execute('''CREATE INDEX IF NOT EXISTS
                      block_index_idx ON bet_match_expirations (block_index)
                   ''')
    cursor.execute('''CREATE INDEX IF NOT EXISTS
                      tx0_address_idx ON bet_match_expirations (tx0_address)
                   ''')
    cursor.execute('''CREATE INDEX IF NOT EXISTS
                      tx1_address_idx ON bet_match_expirations (tx1_address)
                   ''')

    # Bet Match Resolutions
    cursor.execute('''CREATE TABLE IF NOT EXISTS bet_match_resolutions(
                      bet_match_id TEXT PRIMARY KEY,
                      bet_match_type_id INTEGER,
                      block_index INTEGER,
                      winner TEXT,
                      settled BOOL,
                      bull_credit INTEGER,
                      bear_credit INTEGER,
                      escrow_less_fee INTEGER,
                      fee INTEGER,
                      FOREIGN KEY (bet_match_id) REFERENCES bet_matches(id),
                      FOREIGN KEY (block_index) REFERENCES blocks(block_index))
                   ''')

def cancel_bet (db, bet, status, block_index):
    cursor = db.cursor()

    # Update status of bet.
    bindings = {
        'status': status,
        'tx_hash': bet['tx_hash']
    }
    sql='update bets set status = :status where tx_hash = :tx_hash'
    cursor.execute(sql, bindings)
    log.message(db, block_index, 'update', 'bets', bindings)

    util.credit(db, bet['source'], config.XCP, bet['wager_remaining'], action='recredit wager remaining', event=bet['tx_hash'])

    cursor = db.cursor()

def cancel_bet_match (db, bet_match, status, block_index):
    # Does not re‐open, re‐fill, etc. constituent bets.

    cursor = db.cursor()

    # Recredit tx0 address.
    util.credit(db, bet_match['tx0_address'], config.XCP,
                bet_match['forward_quantity'], action='recredit forward quantity', event=bet_match['id'])

    # Recredit tx1 address.
    util.credit(db, bet_match['tx1_address'], config.XCP,
                bet_match['backward_quantity'], action='recredit backward quantity', event=bet_match['id'])

    # Update status of bet match.
    bindings = {
        'status': status,
        'bet_match_id': bet_match['id']
    }
    sql='update bet_matches set status = :status where id = :bet_match_id'
    cursor.execute(sql, bindings)
    log.message(db, block_index, 'update', 'bet_matches', bindings)

    cursor.close()


def get_fee_fraction (db, feed_address):
    '''Get fee fraction from last broadcast from the feed_address address.
    '''
    cursor = db.cursor()
    broadcasts = list(cursor.execute('''SELECT * FROM broadcasts WHERE (status = ? AND source = ?) ORDER BY tx_index ASC''', ('valid', feed_address)))
    cursor.close()
    if broadcasts:
        last_broadcast = broadcasts[-1]
        fee_fraction_int = last_broadcast['fee_fraction_int']
        if fee_fraction_int: return fee_fraction_int / 1e8
        else: return 0
    else:
        return 0

def validate (db, source, feed_address, bet_type, deadline, wager_quantity,
              counterwager_quantity, target_value, leverage, expiration, block_index):
    problems = []

    if leverage is None: leverage = 5040

    # Look at feed to be bet on.
    cursor = db.cursor()
    broadcasts = list(cursor.execute('''SELECT * FROM broadcasts WHERE (status = ? AND source = ?) ORDER BY tx_index ASC''', ('valid', feed_address)))
    cursor.close()
    if not broadcasts:
        problems.append('feed doesn’t exist')
    elif not broadcasts[-1]['text']:
        problems.append('feed is locked')
    elif broadcasts[-1]['timestamp'] >= deadline:
        problems.append('deadline in that feed’s past')

    if not bet_type in (0, 1, 2, 3):
        problems.append('unknown bet type')

    # Valid leverage level?
    if leverage != 5040 and bet_type in (2,3):   # Equal, NotEqual
        problems.append('leverage used with Equal or NotEqual')
    if leverage < 5040 and not bet_type in (0,1):   # BullCFD, BearCFD (fractional leverage makes sense precisely with CFDs)
        problems.append('leverage level too low')

    if bet_type in (0,1):   # BullCFD, BearCFD
        if block_index >= 312350:   # Protocol change.
            problems.append('CFDs temporarily disabled')

    if not isinstance(wager_quantity, int):
        problems.append('wager_quantity must be in satoshis')
        return problems, leverage
    if not isinstance(counterwager_quantity, int):
        problems.append('counterwager_quantity must be in satoshis')
        return problems, leverage
    if not isinstance(expiration, int):
        problems.append('expiration must be expressed as an integer block delta')
        return problems, leverage

    if wager_quantity <= 0: problems.append('non‐positive wager')
    if counterwager_quantity <= 0: problems.append('non‐positive counterwager')
    if deadline < 0: problems.append('negative deadline')
    if expiration < 0: problems.append('negative expiration')
    if expiration == 0 and not (block_index >= 317500 or config.TESTNET):   # Protocol change.
        problems.append('zero expiration')

    if target_value:
        if bet_type in (0,1):   # BullCFD, BearCFD
            problems.append('CFDs have no target value')
        if target_value < 0:
            problems.append('negative target value')

    if expiration > config.MAX_EXPIRATION:
        problems.append('expiration overflow')

    # For SQLite3
    if wager_quantity > config.MAX_INT or counterwager_quantity > config.MAX_INT or bet_type > config.MAX_INT or deadline > config.MAX_INT or leverage > config.MAX_INT:
        problems.append('integer overflow')

    return problems, leverage

def compose (db, source, feed_address, bet_type, deadline, wager_quantity,
            counterwager_quantity, target_value, leverage, expiration):

    if util.get_balance(db, source, config.XCP) < wager_quantity:
        raise exceptions.ComposeError('insufficient funds')

    problems, leverage = validate(db, source, feed_address, bet_type, deadline, wager_quantity,
                        counterwager_quantity, target_value, leverage, expiration, util.CURRENT_BLOCK_INDEX)
    if util.date_passed(deadline):
        problems.append('deadline passed')
    if problems: raise exceptions.ComposeError(problems)

    data = struct.pack(config.TXTYPE_FORMAT, ID)
    data += struct.pack(FORMAT, bet_type, deadline,
                        wager_quantity, counterwager_quantity, target_value,
                        leverage, expiration)
    return (source, [(feed_address, None)], data)

def parse (db, tx, message):
    bet_parse_cursor = db.cursor()

    # Unpack message.
    try:
        if len(message) != LENGTH:
            raise exceptions.UnpackError
        (bet_type, deadline, wager_quantity,
         counterwager_quantity, target_value, leverage,
         expiration) = struct.unpack(FORMAT, message)
        status = 'open'
    except (exceptions.UnpackError, struct.error):
        (bet_type, deadline, wager_quantity,
         counterwager_quantity, target_value, leverage,
         expiration, fee_fraction_int) = 0, 0, 0, 0, 0, 0, 0, 0
        status = 'invalid: could not unpack'

    odds, fee_fraction = 0, 0
    feed_address = tx['destination']
    if status == 'open':
        try:
            odds = util.price(wager_quantity, counterwager_quantity)
        except ZeroDivisionError:
            odds = 0

        fee_fraction = get_fee_fraction(db, feed_address)

        # Overbet
        bet_parse_cursor.execute('''SELECT * FROM balances \
                                    WHERE (address = ? AND asset = ?)''', (tx['source'], config.XCP))
        balances = list(bet_parse_cursor)
        if not balances:
            wager_quantity = 0
        else:
            balance = balances[0]['quantity']
            if balance < wager_quantity:
                wager_quantity = balance
                counterwager_quantity = int(util.price(wager_quantity, odds))

        problems, leverage = validate(db, tx['source'], feed_address, bet_type, deadline, wager_quantity,
                            counterwager_quantity, target_value, leverage, expiration, tx['block_index'])
        if problems: status = 'invalid: ' + '; '.join(problems)

    # Debit quantity wagered. (Escrow.)
    if status == 'open':
        util.debit(db, tx['source'], config.XCP, wager_quantity, action='bet', event=tx['tx_hash'])

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
    if status == 'open' and tx['block_index'] != config.MEMPOOL_BLOCK_INDEX:
        match(db, tx)

    bet_parse_cursor.close()

def match (db, tx):

    cursor = db.cursor()

    # Get bet in question.
    bets = list(cursor.execute('''SELECT * FROM bets\
                                  WHERE (tx_index = ? AND status = ?)''', (tx['tx_index'], 'open')))
    if not bets:
        cursor.close()
        return
    else:
        assert len(bets) == 1
    tx1 = bets[0]

    # Get counterbet_type.
    if tx1['bet_type'] % 2: counterbet_type = tx1['bet_type'] - 1
    else: counterbet_type = tx1['bet_type'] + 1

    feed_address = tx1['feed_address']

    cursor.execute('''SELECT * FROM bets\
                             WHERE (feed_address=? AND status=? AND bet_type=?)''',
                             (tx1['feed_address'], 'open', counterbet_type))
    tx1_wager_remaining = tx1['wager_remaining']
    tx1_counterwager_remaining = tx1['counterwager_remaining']
    bet_matches = cursor.fetchall()
    if tx['block_index'] > 284500 or config.TESTNET:  # Protocol change.
        sorted(bet_matches, key=lambda x: x['tx_index'])                                        # Sort by tx index second.
        sorted(bet_matches, key=lambda x: util.price(x['wager_quantity'], x['counterwager_quantity']))   # Sort by price first.

    tx1_status = tx1['status']
    for tx0 in bet_matches:
        if tx1_status != 'open': break

        logger.debug('Considering: ' + tx0['tx_hash'])
        tx0_wager_remaining = tx0['wager_remaining']
        tx0_counterwager_remaining = tx0['counterwager_remaining']

        # Bet types must be opposite.
        if counterbet_type != tx0['bet_type']:
            logger.debug('Skipping: bet types disagree.')
            continue

        # Leverages must agree exactly
        if tx0['leverage'] != tx1['leverage']:
            logger.debug('Skipping: leverages disagree.')
            continue

        # Target values must agree exactly.
        if tx0['target_value'] != tx1['target_value']:
            logger.debug('Skipping: target values disagree.')
            continue

        # Fee fractions must agree exactly.
        if tx0['fee_fraction_int'] != tx1['fee_fraction_int']:
            logger.debug('Skipping: fee fractions disagree.')
            continue

        # Deadlines must agree exactly.
        if tx0['deadline'] != tx1['deadline']:
            logger.debug('Skipping: deadlines disagree.')
            continue

        # If the odds agree, make the trade. The found order sets the odds,
        # and they trade as much as they can.
        tx0_odds = util.price(tx0['wager_quantity'], tx0['counterwager_quantity'])
        tx0_inverse_odds = util.price(tx0['counterwager_quantity'], tx0['wager_quantity'])
        tx1_odds = util.price(tx1['wager_quantity'], tx1['counterwager_quantity'])

        if tx['block_index'] < 286000: tx0_inverse_odds = util.price(1, tx0_odds) # Protocol change.

        logger.debug('Tx0 Inverse Odds: {}; Tx1 Odds: {}'.format(float(tx0_inverse_odds), float(tx1_odds)))
        if tx0_inverse_odds > tx1_odds:
            logger.debug('Skipping: price mismatch.')
        else:
            logger.debug('Potential forward quantities: {}, {}'.format(tx0_wager_remaining, int(util.price(tx1_wager_remaining, tx1_odds))))
            forward_quantity = int(min(tx0_wager_remaining, int(util.price(tx1_wager_remaining, tx1_odds))))
            logger.debug('Forward Quantity: {}'.format(forward_quantity))
            backward_quantity = round(forward_quantity / tx0_odds)
            logger.debug('Backward Quantity: {}'.format(backward_quantity))

            if not forward_quantity:
                logger.debug('Skipping: zero forward quantity.')
                continue
            if tx1['block_index'] >= 286500 or config.TESTNET:    # Protocol change.
                if not backward_quantity:
                    logger.debug('Skipping: zero backward quantity.')
                    continue

            bet_match_id = util.make_id(tx0['tx_hash'], tx1['tx_hash'])

            # Debit the order.
            # Counterwager remainings may be negative.
            tx0_wager_remaining = tx0_wager_remaining - forward_quantity
            tx0_counterwager_remaining = tx0_counterwager_remaining - backward_quantity
            tx1_wager_remaining = tx1_wager_remaining - backward_quantity
            tx1_counterwager_remaining = tx1_counterwager_remaining - forward_quantity

            # tx0
            tx0_status = 'open'
            if tx0_wager_remaining <= 0 or tx0_counterwager_remaining <= 0:
                # Fill order, and recredit give_remaining.
                tx0_status = 'filled'
                util.credit(db, tx0['source'], config.XCP, tx0_wager_remaining, event=tx1['tx_hash'], action='filled')
            bindings = {
                'wager_remaining': tx0_wager_remaining,
                'counterwager_remaining': tx0_counterwager_remaining,
                'status': tx0_status,
                'tx_hash': tx0['tx_hash']
            }
            sql='update bets set wager_remaining = :wager_remaining, counterwager_remaining = :counterwager_remaining, status = :status where tx_hash = :tx_hash'
            cursor.execute(sql, bindings)
            log.message(db, tx['block_index'], 'update', 'bets', bindings)

            if tx1['block_index'] >= 292000 or config.TESTNET:  # Protocol change
                if tx1_wager_remaining <= 0 or tx1_counterwager_remaining <= 0:
                    # Fill order, and recredit give_remaining.
                    tx1_status = 'filled'
                    util.credit(db, tx1['source'], config.XCP, tx1_wager_remaining, event=tx1['tx_hash'], action='filled')
            # tx1
            bindings = {
                'wager_remaining': tx1_wager_remaining,
                'counterwager_remaining': tx1_counterwager_remaining,
                'status': tx1_status,
                'tx_hash': tx1['tx_hash']
            }
            sql='update bets set wager_remaining = :wager_remaining, counterwager_remaining = :counterwager_remaining, status = :status where tx_hash = :tx_hash'
            cursor.execute(sql, bindings)
            log.message(db, tx['block_index'], 'update', 'bets', bindings)

            # Get last value of feed.
            broadcasts = list(cursor.execute('''SELECT * FROM broadcasts WHERE (status = ? AND source = ?) ORDER BY tx_index ASC''', ('valid', feed_address)))
            initial_value = broadcasts[-1]['value']

            # Record bet fulfillment.
            bindings = {
                'id': util.make_id(tx0['tx_hash'], tx['tx_hash']),
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
                'block_index': max(tx0['block_index'], tx1['block_index']),
                'tx0_expiration': tx0['expiration'],
                'tx1_expiration': tx1['expiration'],
                'match_expire_index': min(tx0['expire_index'], tx1['expire_index']),
                'fee_fraction_int': tx1['fee_fraction_int'],
                'status': 'pending',
            }
            sql='insert into bet_matches values(:id, :tx0_index, :tx0_hash, :tx0_address, :tx1_index, :tx1_hash, :tx1_address, :tx0_bet_type, :tx1_bet_type, :feed_address, :initial_value, :deadline, :target_value, :leverage, :forward_quantity, :backward_quantity, :tx0_block_index, :tx1_block_index, :block_index, :tx0_expiration, :tx1_expiration, :match_expire_index, :fee_fraction_int, :status)'
            cursor.execute(sql, bindings)

    cursor.close()
    return

def expire (db, block_index, block_time):
    cursor = db.cursor()

    # Expire bets and give refunds for the quantity wager_remaining.
    cursor.execute('''SELECT * FROM bets \
                      WHERE (status = ? AND expire_index < ?)''', ('open', block_index))
    for bet in cursor.fetchall():
        cancel_bet(db, bet, 'expired', block_index)

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
        cancel_bet_match(db, bet_match, 'expired', block_index)

        # Record bet match expiration.
        bindings = {
            'bet_match_id': bet_match['id'],
            'tx0_address': bet_match['tx0_address'],
            'tx1_address': bet_match['tx1_address'],
            'block_index': block_index
        }
        sql='insert into bet_match_expirations values(:bet_match_id, :tx0_address, :tx1_address, :block_index)'
        cursor.execute(sql, bindings)

    cursor.close()

# vim: tabstop=8 expandtab shiftwidth=4 softtabstop=4
