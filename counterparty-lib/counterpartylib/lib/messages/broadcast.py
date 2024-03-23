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
import json
import logging

from bitcoin.core import VarIntSerializer

from counterpartylib.lib import exceptions
from counterpartylib.lib import config
from counterpartylib.lib import util
from counterpartylib.lib import log
from counterpartylib.lib import message_type
from counterpartylib.lib import ledger
from counterpartylib.lib import database

from . import (bet)

logger = logging.getLogger(config.LOGGER_NAME)

FORMAT = '>IdI'
LENGTH = 4 + 8 + 4
ID = 30
# NOTE: Pascal strings are used for storing texts for backwards‐compatibility.

def initialise(db):
    cursor = db.cursor()

    # remove misnamed indexes
    database.drop_indexes(cursor, [
        'block_index_idx',
        'status_source_idx',
        'status_source_index_idx',
        'timestamp_idx',
    ])

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

    database.create_indexes(cursor, 'broadcasts', [
        ['block_index'],
        ['status', 'source'],
        ['status', 'source', 'tx_index'],
        ['timestamp'],
    ])

def validate (db, source, timestamp, value, fee_fraction_int, text, block_index):
    problems = []

    # For SQLite3
    if timestamp > config.MAX_INT or value > config.MAX_INT or fee_fraction_int > config.MAX_INT:
        problems.append('integer overflow')

    if ledger.enabled('max_fee_fraction'):
        if fee_fraction_int >= config.UNIT:
            problems.append('fee fraction greater than or equal to 1')
    else:
        if fee_fraction_int > 4294967295:
            problems.append('fee fraction greater than 42.94967295')

    if timestamp < 0: problems.append('negative timestamp')

    if not source:
        problems.append('null source address')
    # Check previous broadcast in this feed.
    broadcasts = ledger.get_broadcasts_by_source(db, source, 'valid')
    if broadcasts:
        last_broadcast = broadcasts[-1]
        if last_broadcast['locked']:
            problems.append('locked feed')
        elif timestamp <= last_broadcast['timestamp']:
            problems.append('feed timestamps not monotonically increasing')

    if not (block_index >= 317500 or config.TESTNET or config.REGTEST):  # Protocol change.
        if len(text) > 52:
            problems.append('text too long')

    if ledger.enabled('options_require_memo') and text and text.lower().startswith('options'):
        try:
            # Check for options and if they are valid.
            options = util.parse_options_from_string(text)
            if options is not False:
                util.validate_address_options(options)
        except exceptions.OptionsError as e:
            problems.append(str(e))

    return problems

def compose (db, source, timestamp, value, fee_fraction, text):

    # Store the fee fraction as an integer.
    fee_fraction_int = int(fee_fraction * 1e8)

    problems = validate(db, source, timestamp, value, fee_fraction_int, text, ledger.CURRENT_BLOCK_INDEX)
    if problems: raise exceptions.ComposeError(problems)

    data = message_type.pack(ID)

    # always use custom length byte instead of problematic usage of 52p format and make sure to encode('utf-8') for length
    if ledger.enabled('broadcast_pack_text'):
        data += struct.pack(FORMAT, timestamp, value, fee_fraction_int)
        data += VarIntSerializer.serialize(len(text.encode('utf-8')))
        data += text.encode('utf-8')
    else:
        if len(text) <= 52:
            curr_format = FORMAT + f'{len(text) + 1}p'
        else:
            curr_format = FORMAT + f'{len(text)}s'

        data += struct.pack(curr_format, timestamp, value, fee_fraction_int, text.encode('utf-8'))
    return (source, [], data)

def parse (db, tx, message):
    cursor = db.cursor()

    # Unpack message.
    try:
        if ledger.enabled('broadcast_pack_text', tx['block_index']):
            timestamp, value, fee_fraction_int, rawtext = struct.unpack(FORMAT + f'{len(message) - LENGTH}s', message)
            textlen = VarIntSerializer.deserialize(rawtext)
            if textlen == 0:
                text = b''
            else:
                text = rawtext[-textlen:]

            assert len(text) == textlen
        else:
            if len(message) - LENGTH <= 52:
                curr_format = FORMAT + f'{len(message) - LENGTH}p'
            else:
                curr_format = FORMAT + f'{len(message) - LENGTH}s'

            timestamp, value, fee_fraction_int, text = struct.unpack(curr_format, message)

        try:
            text = text.decode('utf-8')
        except UnicodeDecodeError:
            text = ''
        status = 'valid'
    except (struct.error) as e:
        timestamp, value, fee_fraction_int, text = 0, None, 0, None
        status = 'invalid: could not unpack'
    except AssertionError:
        timestamp, value, fee_fraction_int, text = 0, None, 0, None
        status = "invalid: could not unpack text"
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
    if "integer overflow" not in status:
        ledger.insert_record(db, 'broadcasts', bindings)
    else:
        logger.debug(f"Not storing [broadcast] tx [{tx['tx_hash']}]: {status}")
        logger.debug(f"Bindings: {json.dumps(bindings)}")

    # stop processing if broadcast is invalid for any reason
    if ledger.enabled('broadcast_invalid_check') and status != 'valid':
        return

    # Options? Should not fail to parse due to above checks.
    if ledger.enabled('options_require_memo') and text and text.lower().startswith('options'):
        options = util.parse_options_from_string(text)
        if options is not False:
            op_bindings = {
                        'block_index': tx['block_index'],
                        'address': tx['source'],
                        'options': options
                       }
            sql = 'insert or replace into addresses(address, options, block_index) values(:address, :options, :block_index)'
            cursor = db.cursor()
            cursor.execute(sql, op_bindings)

    # Negative values (default to ignore).
    if value is None or value < 0:
        # Cancel Open Bets?
        if value == -2:
            for i in ledger.get_open_bet_by_feed(db, tx['source']):
                bet.cancel_bet(db, i, 'dropped', tx['block_index'], tx['tx_index'])
        # Cancel Pending Bet Matches?
        if value == -3:
            for bet_match in ledger.get_pending_bet_matches(db, tx['source']):
                bet.cancel_bet_match(db, bet_match, 'dropped', tx['block_index'], tx['tx_index'])
        cursor.close()
        return

    # stop processing if broadcast is invalid for any reason
    # @TODO: remove this check once broadcast_invalid_check has been activated
    if ledger.enabled('max_fee_fraction') and status != 'valid':
        return

    # Handle bet matches that use this feed.
    bet_matches = ledger.get_pending_bet_matches(db,
                                                 tx['source'],
                                                 order_by='tx1_index ASC, tx0_index ASC')
    for bet_match in bet_matches:
        broadcast_bet_match_cursor = db.cursor()
        bet_match_id = util.make_id(bet_match['tx0_hash'], bet_match['tx1_hash'])
        bet_match_status = None

        # Calculate total funds held in escrow and total fee to be paid if
        # the bet match is settled. Escrow less fee is amount to be paid back
        # to betters.
        total_escrow = bet_match['forward_quantity'] + bet_match['backward_quantity']

        if ledger.enabled('inmutable_fee_fraction'):
            fee_fraction = bet_match['fee_fraction_int'] / config.UNIT
        else:
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
                    ledger.credit(db, bull_address, config.XCP, bull_credit, tx['tx_index'], action=f'bet {bet_match_status}', event=tx['tx_hash'])
                elif bull_credit <= 0:
                    bull_credit = 0
                    bear_credit = escrow_less_fee
                    bet_match_status = 'settled: liquidated for bear'
                    ledger.credit(db, bear_address, config.XCP, bear_credit, tx['tx_index'], action=f'bet {bet_match_status}', event=tx['tx_hash'])

                # Pay fee to feed.
                ledger.credit(db, bet_match['feed_address'], config.XCP, fee, tx['tx_index'], action='feed fee', event=tx['tx_hash'])

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
                ledger.insert_record(db, 'bet_match_resolutions', bindings)

            # Settle (if not liquidated).
            elif timestamp >= bet_match['deadline']:
                bet_match_status = 'settled'

                ledger.credit(db, bull_address, config.XCP, bull_credit, tx['tx_index'], action=f'bet {bet_match_status}', event=tx['tx_hash'])
                ledger.credit(db, bear_address, config.XCP, bear_credit, tx['tx_index'], action=f'bet {bet_match_status}', event=tx['tx_hash'])

                # Pay fee to feed.
                ledger.credit(db, bet_match['feed_address'], config.XCP, fee, tx['tx_index'], action='feed fee', event=tx['tx_hash'])

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
                ledger.insert_record(db, 'bet_match_resolutions', bindings)

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
                ledger.credit(db, equal_address, config.XCP, escrow_less_fee, tx['tx_index'], action=f'bet {bet_match_status}', event=tx['tx_hash'])
            else:
                winner = 'NotEqual'
                bet_match_status = 'settled: for notequal'
                ledger.credit(db, notequal_address, config.XCP, escrow_less_fee, tx['tx_index'], action=f'bet {bet_match_status}', event=tx['tx_hash'])

            # Pay fee to feed.
            ledger.credit(db, bet_match['feed_address'], config.XCP, fee, tx['tx_index'], action='feed fee', event=tx['tx_hash'])

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
            ledger.insert_record(db, 'bet_match_resolutions', bindings)

        # Update the bet match’s status.
        if bet_match_status:
            bet_match_id = util.make_id(bet_match['tx0_hash'], bet_match['tx1_hash'])
            ledger.update_bet_match_status(db, bet_match_id, bet_match_status)

            log.message(db, tx['block_index'], 'update', 'bet_matches', {
                'status': bet_match_status,
                'bet_match_id': bet_match_id
            })

        broadcast_bet_match_cursor.close()

    cursor.close()
