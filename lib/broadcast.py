#! /usr/bin/python3

"""
Broadcast a message, with or without a price.

Multiple messages per block are allowed. Bets are be made on the ‘timestamp’
field, and not the block index.

An address is a feed of broadcasts. Feeds (addresses) may be locked with a
broadcast containing a blank ‘text’ field. Bets on a feed reference the address
that is the source of the feed in an output which includes the (latest)
required fee.

Broadcasts without a price may not be used for betting. Broadcasts about events
with a small number of possible outcomes (e.g. sports games), should be
written, for example, such that a price of 1 XCP means one outcome, 2 XCP means
another, etc., which schema should be described in the ‘text’ field.

fee_multipilier: .05 XCP means 5%. It may be greater than 1, however; but
because it is stored as a four‐byte integer, it may not be greater than about
42.
"""

import struct
import sqlite3
import decimal
D = decimal.Decimal
import logging

from . import (util, config, bitcoin)

FORMAT = '>IdI40p' # How many characters *can* the text be?! (That is, how long is PREFIX?!)
ID = 30
LENGTH = 4 + 8 + 4 + 40

def create (source, timestamp, value, fee_multiplier, text, test=False):
    data = config.PREFIX + struct.pack(config.TXTYPE_FORMAT, ID)
    data += struct.pack(FORMAT, timestamp, value, fee_multiplier,
                        text.encode('utf-8'))
    return bitcoin.transaction(source, None, None, config.MIN_FEE, data, test)

def parse (db, cursor, tx, message):
    # Ask for forgiveness…
    validity = 'Valid'

    # Unpack message.
    try:
        timestamp, value, fee_multiplier, text = struct.unpack(FORMAT, message)
        text = text.decode('utf-8')
    except Exception:
        timestamp, value, fee_multiplier, text = None, None, None, None
        validity = 'Invalid: could not unpack'

    # Check that the publishing address is not locked.
    cursor, good_feed = util.good_feed(cursor, tx['source'])
    if good_feed != None and not good_feed:
        validity = 'Invalid: locked feed'

    # Add parsed transaction to message‐type–specific table.
    cursor.execute('''INSERT INTO broadcasts(
                        tx_index,
                        tx_hash,
                        block_index,
                        source,
                        timestamp,
                        value,
                        fee_multiplier,
                        text,
                        validity) VALUES(?,?,?,?,?,?,?,?,?)''',
                        (tx['tx_index'],
                        tx['tx_hash'],
                        tx['block_index'],
                        tx['source'],
                        timestamp,
                        value,
                        fee_multiplier,
                        text,
                        validity)
                  )
    if validity == 'Valid':
        if not value: infix = '‘' + text + '’'
        else: infix = '‘' + text + ' = ' + str(value) + '’'
        suffix = ' from ' + tx['source'] + ' at ' + util.isodt(timestamp) + ' (' + util.short(tx['tx_hash']) + ')'
        logging.info('Broadcast: {}'.format(infix + suffix))


    # Handle bet_matches that use this feed.
    cursor.execute('''SELECT * FROM bet_matches \
                      WHERE (validity=? AND feed_address=?)''', ('Valid', tx['source']))
    for bet_match in cursor.fetchall():
        bet_match_id = bet_match['tx0_hash'] + bet_match['tx1_hash']

        # Contract for difference, with determinate settlement date.
        cfd_id_sum = util.BET_TYPE_ID['BullCFD'] + util.BET_TYPE_ID['BearCFD']
        if bet_match['tx0_bet_type'] + bet_match['tx1_bet_type'] == cfd_id_sum:
            leverage = D(bet_match['leverage']) / 5040
            initial_value = bet_match['initial_value']

            if bet_match['tx0_bet_type'] == 0 and bet_match['tx1_bet_type'] == 1:
                bull_address = bet_match['tx0_address']
                bear_address = bet_match['tx1_address']
                bull_escrow = bet_match['forward_amount']
                bear_escrow = bet_match['backward_amount']
            else:
                bull_address = bet_match['tx1_address']
                bear_address = bet_match['tx0_address']
                bull_escrow = bet_match['backward_amount']
                bear_escrow = bet_match['forward_amount']
                
            total_escrow = bull_escrow + bear_escrow
            bear_credit = bear_escrow - D(value - initial_value) * leverage * config.UNIT
            bull_credit = total_escrow - bear_credit

            # Liquidate, as necessary.
            if bull_credit >= total_escrow:
                cursor = util.credit(db, cursor, bull_address, 1, total_escrow)
                validity = 'Force‐Liquidated'
                logging.info('Contract Force‐Liquidated: {} XCP credited to the bull, and 0 XCP credited to the bear ({})'.format(total_escrow / config.UNIT, util.short(bet_match_id)))
            elif bull_credit <= 0:
                cursor = util.credit(db, cursor, bear_address, 1, total_escrow)
                validity = 'Force‐Liquidated'
                logging.info('Contract Force‐Liquidated: 0 XCP credited to the bull, and {} XCP credited to the bear ({})'.format(total_escrow / config.UNIT, util.short(bet_match_id)))

            # Settle.
            if timestamp > bet_match['deadline'] and validity != 'Liquidated':
                cursor = util.credit(db, cursor, bull_address, 1, bull_credit)
                cursor = util.credit(db, cursor, bear_address, 1, bear_credit)
                validity = 'Settled'
                logging.info('Contract Settled: {} XCP credited to the bull, and {} XCP credited to the bear ({})'.format(bull_credit / config.UNIT, bear_credit / config.UNIT, util.short(bet_match_id)))

            cursor.execute('''UPDATE bet_matches \
                              SET validity=? \
                              WHERE (tx0_hash=? and tx1_hash=?)''',
                          (validity, bet_match['tx0_hash'], bet_match['tx1_hash']))

    return cursor

# vim: tabstop=8 expandtab shiftwidth=4 softtabstop=4
