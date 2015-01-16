#! /usr/bin/python3

"""
Broadcast a message, with or without a price.

Multiple messages per block are allowed. Bets are be made on the 'timestamp'
field, and not the block index.

An address is a feed of broadcasts. Feeds may be locked with a broadcast whose
text field is identical to ‘lock’ (case insensitive). Bets on a feed reference
the address that is the source of the feed in an output which includes the
(latest) required fee.

Broadcasts without a price may not be used for betting. Broadcasts about events
with a small number of possible outcomes (e.g. sports games), should be
written, for example, such that a price of 1 XCP means one outcome, 2 XCP means
another, etc., which schema should be described in the 'text' field.

fee_fraction: .05 XCP means 5%. It may be greater than 1, however; but
because it is stored as a four‐byte integer, it may not be greater than about
42.
"""

import struct
import decimal
D = decimal.Decimal
from fractions import Fraction
import logging
logger = logging.getLogger(__name__)

from counterpartylib.lib import exceptions
from counterpartylib.lib import config
from counterpartylib.lib import util
from counterpartylib.lib import log
from . import (bet)

FORMAT = '>IdI'
LENGTH = 4 + 8 + 4
ID = 30
# NOTE: Pascal strings are used for storing texts for backwards‐compatibility.

def initialise(db):
    cursor = db.cursor()
    cursor.execute('''CREATE TABLE IF NOT EXISTS broadcasts(
                      tx_index INTEGER PRIMARY KEY,
                      tx_hash TEXT UNIQUE,
                      block_index INTEGER,
                      source TEXT,
                      timestamp INTEGER,
                      value REAL,
                      fee_fraction_int INTEGER,
                      text TEXT,
                      locked BOOL,
                      status TEXT,
                      FOREIGN KEY (tx_index, tx_hash, block_index) REFERENCES transactions(tx_index, tx_hash, block_index))
                   ''')
    cursor.execute('''CREATE INDEX IF NOT EXISTS
                      block_index_idx ON broadcasts (block_index)
                   ''')
    cursor.execute('''CREATE INDEX IF NOT EXISTS
                      status_source_idx ON broadcasts (status, source)
                   ''')
    cursor.execute('''CREATE INDEX IF NOT EXISTS
                      status_source_index_idx ON broadcasts (status, source, tx_index)
                   ''')
    cursor.execute('''CREATE INDEX IF NOT EXISTS
                      timestamp_idx ON broadcasts (timestamp)
                   ''')

def validate (db, source, timestamp, value, fee_fraction_int, text, block_index):
    problems = []

    if fee_fraction_int > 4294967295:
        problems.append('fee fraction greater than 42.94967295')

    if timestamp < 0: problems.append('negative timestamp')

    if not source:
        problems.append('null source address')
    # Check previous broadcast in this feed.
    cursor = db.cursor()
    broadcasts = list(cursor.execute('''SELECT * FROM broadcasts WHERE (status = ? AND source = ?) ORDER BY tx_index ASC''', ('valid', source)))
    cursor.close()
    if broadcasts:
        last_broadcast = broadcasts[-1]
        if last_broadcast['locked']:
            problems.append('locked feed')
        elif timestamp <= last_broadcast['timestamp']:
            problems.append('feed timestamps not monotonically increasing')

    if not (block_index >= 317500 or config.TESTNET):  # Protocol change.
        if len(text) > 52:
            problems.append('text too long')

    return problems

def compose (db, source, timestamp, value, fee_fraction, text):

    # Store the fee fraction as an integer.
    fee_fraction_int = int(fee_fraction * 1e8)

    problems = validate(db, source, timestamp, value, fee_fraction_int, text, util.CURRENT_BLOCK_INDEX)
    if problems: raise exceptions.ComposeError(problems)

    data = struct.pack(config.TXTYPE_FORMAT, ID)
    if len(text) <= 52:
        curr_format = FORMAT + '{}p'.format(len(text) + 1)
    else:
        curr_format = FORMAT + '{}s'.format(len(text))
    data += struct.pack(curr_format, timestamp, value, fee_fraction_int,
                        text.encode('utf-8'))
    return (source, [], data)

def parse (db, tx, message):
    cursor = db.cursor()

    # Unpack message.
    try:
        if len(message) - LENGTH <= 52:
            curr_format = FORMAT + '{}p'.format(len(message) - LENGTH)
        else:
            curr_format = FORMAT + '{}s'.format(len(message) - LENGTH)
        timestamp, value, fee_fraction_int, text = struct.unpack(curr_format, message)

        try:
            text = text.decode('utf-8')
        except UnicodeDecodeError:
            text = ''
        status = 'valid'
    except (struct.error) as e:
        timestamp, value, fee_fraction_int, text = 0, None, 0, None
        status = 'invalid: could not unpack'

    if status == 'valid':
        # For SQLite3
        timestamp = min(timestamp, config.MAX_INT)
        value = min(value, config.MAX_INT)

        problems = validate(db, tx['source'], timestamp, value, fee_fraction_int, text, tx['block_index'])
        if problems: status = 'invalid: ' + '; '.join(problems)

    # Lock?
    lock = False
    if text and text.lower() == 'lock':
        lock = True
        timestamp, value, fee_fraction_int, text = 0, None, None, None
    else:
        lock = False

    # Add parsed transaction to message-type–specific table.
    bindings = {
        'tx_index': tx['tx_index'],
        'tx_hash': tx['tx_hash'],
        'block_index': tx['block_index'],
        'source': tx['source'],
        'timestamp': timestamp,
        'value': value,
        'fee_fraction_int': fee_fraction_int,
        'text': text,
        'locked': lock,
        'status': status,
    }
    sql='insert into broadcasts values(:tx_index, :tx_hash, :block_index, :source, :timestamp, :value, :fee_fraction_int, :text, :locked, :status)'
    cursor.execute(sql, bindings)

    # Negative values (default to ignore).
    if value == None or value < 0:
        # Cancel Open Bets?
        if value == -2:
            cursor.execute('''SELECT * FROM bets \
                              WHERE (status = ? AND feed_address = ?)''',
                           ('open', tx['source']))
            for i in list(cursor):
                bet.cancel_bet(db, i, 'dropped', tx['block_index'])
        # Cancel Pending Bet Matches?
        if value == -3:
            cursor.execute('''SELECT * FROM bet_matches \
                              WHERE (status = ? AND feed_address = ?)''',
                           ('pending', tx['source']))
            for bet_match in list(cursor):
                bet.cancel_bet_match(db, bet_match, 'dropped', tx['block_index'])
        cursor.close()
        return

    # Handle bet matches that use this feed.
    cursor.execute('''SELECT * FROM bet_matches \
                      WHERE (status=? AND feed_address=?)
                      ORDER BY tx1_index ASC, tx0_index ASC''',
                   ('pending', tx['source']))
    for bet_match in cursor.fetchall():
        broadcast_bet_match_cursor = db.cursor()
        bet_match_id = util.make_id(bet_match['tx0_hash'], bet_match['tx1_hash'])
        bet_match_status = None

        # Calculate total funds held in escrow and total fee to be paid if
        # the bet match is settled. Escrow less fee is amount to be paid back
        # to betters.
        total_escrow = bet_match['forward_quantity'] + bet_match['backward_quantity']
        fee_fraction = fee_fraction_int / config.UNIT
        fee = int(fee_fraction * total_escrow)              # Truncate.
        escrow_less_fee = total_escrow - fee

        # Get known bet match type IDs.
        cfd_type_id = util.BET_TYPE_ID['BullCFD'] + util.BET_TYPE_ID['BearCFD']
        equal_type_id = util.BET_TYPE_ID['Equal'] + util.BET_TYPE_ID['NotEqual']

        # Get the bet match type ID of this bet match.
        bet_match_type_id = bet_match['tx0_bet_type'] + bet_match['tx1_bet_type']

        # Contract for difference, with determinate settlement date.
        if bet_match_type_id == cfd_type_id:

            # Recognise tx0, tx1 as the bull, bear (in the right direction).
            if bet_match['tx0_bet_type'] < bet_match['tx1_bet_type']:
                bull_address = bet_match['tx0_address']
                bear_address = bet_match['tx1_address']
                bull_escrow = bet_match['forward_quantity']
                bear_escrow = bet_match['backward_quantity']
            else:
                bull_address = bet_match['tx1_address']
                bear_address = bet_match['tx0_address']
                bull_escrow = bet_match['backward_quantity']
                bear_escrow = bet_match['forward_quantity']

            leverage = Fraction(bet_match['leverage'], 5040)
            initial_value = bet_match['initial_value']

            bear_credit = bear_escrow - (value - initial_value) * leverage * config.UNIT
            bull_credit = escrow_less_fee - bear_credit
            bear_credit = round(bear_credit)
            bull_credit = round(bull_credit)

            # Liquidate, as necessary.
            if bull_credit >= escrow_less_fee or bull_credit <= 0:
                if bull_credit >= escrow_less_fee:
                    bull_credit = escrow_less_fee
                    bear_credit = 0
                    bet_match_status = 'settled: liquidated for bull'
                    util.credit(db, bull_address, config.XCP, bull_credit, action='bet {}'.format(bet_match_status), event=tx['tx_hash'])
                elif bull_credit <= 0:
                    bull_credit = 0
                    bear_credit = escrow_less_fee
                    bet_match_status = 'settled: liquidated for bear'
                    util.credit(db, bear_address, config.XCP, bear_credit, action='bet {}'.format(bet_match_status), event=tx['tx_hash'])

                # Pay fee to feed.
                util.credit(db, bet_match['feed_address'], config.XCP, fee, action='feed fee', event=tx['tx_hash'])

                # For logging purposes.
                bindings = {
                    'bet_match_id': bet_match_id,
                    'bet_match_type_id': bet_match_type_id,
                    'block_index': tx['block_index'],
                    'settled': False,
                    'bull_credit': bull_credit,
                    'bear_credit': bear_credit,
                    'winner': None,
                    'escrow_less_fee': None,
                    'fee': fee
                }
                sql='insert into bet_match_resolutions values(:bet_match_id, :bet_match_type_id, :block_index, :settled, :bull_credit, :bear_credit, :winner, :escrow_less_fee, :fee)'
                cursor.execute(sql, bindings)

            # Settle (if not liquidated).
            elif timestamp >= bet_match['deadline']:
                bet_match_status = 'settled'

                util.credit(db, bull_address, config.XCP, bull_credit, action='bet {}'.format(bet_match_status), event=tx['tx_hash'])
                util.credit(db, bear_address, config.XCP, bear_credit, action='bet {}'.format(bet_match_status), event=tx['tx_hash'])

                # Pay fee to feed.
                util.credit(db, bet_match['feed_address'], config.XCP, fee, action='feed fee', event=tx['tx_hash'])

                # For logging purposes.
                bindings = {
                    'bet_match_id': bet_match_id,
                    'bet_match_type_id': bet_match_type_id,
                    'block_index': tx['block_index'],
                    'settled': True,
                    'bull_credit': bull_credit,
                    'bear_credit': bear_credit,
                    'winner': None,
                    'escrow_less_fee': None,
                    'fee': fee
                }
                sql='insert into bet_match_resolutions values(:bet_match_id, :bet_match_type_id, :block_index, :settled, :bull_credit, :bear_credit, :winner, :escrow_less_fee, :fee)'
                cursor.execute(sql, bindings)

        # Equal[/NotEqual] bet.
        elif bet_match_type_id == equal_type_id and timestamp >= bet_match['deadline']:

            # Recognise tx0, tx1 as the bull, bear (in the right direction).
            if bet_match['tx0_bet_type'] < bet_match['tx1_bet_type']:
                equal_address = bet_match['tx0_address']
                notequal_address = bet_match['tx1_address']
            else:
                equal_address = bet_match['tx1_address']
                notequal_address = bet_match['tx0_address']

            # Decide who won, and credit appropriately.
            if value == bet_match['target_value']:
                winner = 'Equal'
                bet_match_status = 'settled: for equal'
                util.credit(db, equal_address, config.XCP, escrow_less_fee, action='bet {}'.format(bet_match_status), event=tx['tx_hash'])
            else:
                winner = 'NotEqual'
                bet_match_status = 'settled: for notequal'
                util.credit(db, notequal_address, config.XCP, escrow_less_fee, action='bet {}'.format(bet_match_status), event=tx['tx_hash'])

            # Pay fee to feed.
            util.credit(db, bet_match['feed_address'], config.XCP, fee, action='feed fee', event=tx['tx_hash'])

            # For logging purposes.
            bindings = {
                'bet_match_id': bet_match_id,
                'bet_match_type_id': bet_match_type_id,
                'block_index': tx['block_index'],
                'settled': None,
                'bull_credit': None,
                'bear_credit': None,
                'winner': winner,
                'escrow_less_fee': escrow_less_fee,
                'fee': fee
            }
            sql='insert into bet_match_resolutions values(:bet_match_id, :bet_match_type_id, :block_index, :settled, :bull_credit, :bear_credit, :winner, :escrow_less_fee, :fee)'
            cursor.execute(sql, bindings)

        # Update the bet match’s status.
        if bet_match_status:
            bindings = {
                'status': bet_match_status,
                'bet_match_id': util.make_id(bet_match['tx0_hash'], bet_match['tx1_hash'])
            }
            sql='update bet_matches set status = :status where id = :bet_match_id'
            cursor.execute(sql, bindings)
            log.message(db, tx['block_index'], 'update', 'bet_matches', bindings)

        broadcast_bet_match_cursor.close()

    cursor.close()

# vim: tabstop=8 expandtab shiftwidth=4 softtabstop=4
