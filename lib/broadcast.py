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

from . import (util, config, bitcoin)

FORMAT = '>IdI40p' # How many characters *can* the text be?! (That is, how long is PREFIX?!)
ID = 30

def create (source, timestamp, value, fee_multiplier, text):
    data = config.PREFIX + struct.pack(config.TXTYPE_FORMAT, ID)
    data += struct.pack(FORMAT, timestamp, value, fee_multiplier,
                        text.encode('utf-8'))
    return bitcoin.transaction(source, None, config.DUST_SIZE, config.MIN_FEE,
                               data)

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
    good_feed = util.good_feed(tx['source'])
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
        suffix = 'from ' + tx['source'] + ' at ' + util.isodt(timestamp) + ' (' + tx['tx_hash'] + ') '
        print('\tBroadcast:', infix, suffix)


    # Handle contracts that use this feed.
    cursor.execute('''SELECT * FROM contracts \
                      WHERE (validity=? AND feed_address=?)''', ('Valid', tx['source']))
    for contract in cursor.fetchall():
        contract_id = contract['tx0_hash'] + contract['tx1_hash']

        # Contract for difference, with determinate settlement date.
        cfd_id_sum = util.BET_TYPE_ID['BullCFD'] + util.BET_TYPE_ID['BearCFD']
        if contract['tx0_bet_type'] + contract['tx1_bet_type'] == cfd_id_sum:
            leverage = D(contract['leverage']) / 5040
            initial_value = contract['initial_value']

            if contract['tx0_bet_type'] == 0 and contract['tx1_bet_type'] == 1:
                bull_address = contract['tx0_address']
                bear_address = contract['tx1_address']
                bull_escrow = contract['forward_amount']
                bear_escrow = contract['backward_amount']
            else:
                bull_address = contract['tx1_address']
                bear_address = contract['tx0_address']
                bull_escrow = contract['backward_amount']
                bear_escrow = contract['forward_amount']
                
            total_escrow = bull_escrow + bear_escrow
            bear_credit = bear_escrow - D(value - initial_value) * leverage * config.UNIT
            bull_credit = total_escrow - bear_credit

            # Liquidate, as necessary.
            print(value, initial_value, leverage, bull_credit / config.UNIT, total_escrow / config.UNIT)
            if bull_credit >= total_escrow:
                db, cursor = util.credit(db, cursor, bull_address, 1, total_escrow)
                validity = 'Force‐Liquidated'
                print('\tContract Force‐Liquidated:', total_escrow / config.UNIT, 'XCP credited to the bull, and 0 XCP credited to the bear', '(' + contract_id + ')')
            elif bull_credit <= 0:
                db, cursor = util.credit(db, cursor, bear_address, 1, total_escrow)
                validity = 'Force‐Liquidated'
                print('\tContract Force‐Liquidated:', '0 XCP credited to the bull, and', total_escrow / config.UNIT, 'XCP credited to the bear', '(' + contract_id + ')')

            # Settle.
            if timestamp > contract['deadline'] and validity != 'Liquidated':
                db, cursor = util.credit(db, cursor, bull_address, 1, bull_credit)
                db, cursor = util.credit(db, cursor, bear_address, 1, bear_credit)
                validity = 'Settled'
                print('\tContract Settled:', bull_credit / config.UNIT, 'XCP credited to the bull, and', bear_credit / config.UNIT, 'XCP credited to the bear', '(' + contract_id + ')')

            cursor.execute('''UPDATE contracts \
                              SET validity=? \
                              WHERE (tx0_hash=? and tx1_hash=?)''',
                          (validity, contract['tx0_hash'], contract['tx1_hash']))

    db.commit()

    return db, cursor

# vim: tabstop=8 expandtab shiftwidth=4 softtabstop=4
