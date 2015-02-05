#! /usr/bin/python3

import struct
import decimal
D = decimal.Decimal
from fractions import Fraction

from counterpartylib.lib import (config, exceptions, util)

"""Burn {} to earn {} during a special period of time.""".format(config.BTC, config.XCP)

ID = 60

def initialise (db):
    cursor = db.cursor()
    cursor.execute('''CREATE TABLE IF NOT EXISTS burns(
                      tx_index INTEGER PRIMARY KEY,
                      tx_hash TEXT UNIQUE,
                      block_index INTEGER,
                      source TEXT,
                      burned INTEGER,
                      earned INTEGER,
                      status TEXT,
                      FOREIGN KEY (tx_index, tx_hash, block_index) REFERENCES transactions(tx_index, tx_hash, block_index))
                   ''')
    cursor.execute('''CREATE INDEX IF NOT EXISTS
                      status_idx ON burns (status)
                   ''')
    cursor.execute('''CREATE INDEX IF NOT EXISTS
                      address_idx ON burns (source)
                   ''')

def validate (db, source, destination, quantity, block_index, overburn=False):
    problems = []

    # Check destination address.
    if destination != config.UNSPENDABLE:
        problems.append('wrong destination address')

    if not isinstance(quantity, int):
        problems.append('quantity must be in satoshis')
        return problems

    if quantity < 0: problems.append('negative quantity')

    # Try to make sure that the burned funds won't go to waste.
    if block_index < config.BURN_START - 1:
        problems.append('too early')
    elif block_index > config.BURN_END:
        problems.append('too late')

    return problems

def compose (db, source, quantity, overburn=False):
    cursor = db.cursor()
    destination = config.UNSPENDABLE
    problems = validate(db, source, destination, quantity, util.CURRENT_BLOCK_INDEX, overburn=overburn)
    if problems: raise exceptions.ComposeError(problems)

    # Check that a maximum of 1 BTC total is burned per address.
    burns = list(cursor.execute('''SELECT * FROM burns WHERE (status = ? AND source = ?)''', ('valid', source)))
    already_burned = sum([burn['burned'] for burn in burns])
    if quantity > (1 * config.UNIT - already_burned) and not overburn:
        raise exceptions.ComposeError('1 {} may be burned per address'.format(config.BTC))

    cursor.close()
    return (source, [(destination, quantity)], None)

def parse (db, tx, MAINNET_BURNS, message=None):
    burn_parse_cursor = db.cursor()

    if config.TESTNET:
        status = 'valid'

        if status == 'valid':
            problems = validate(db, tx['source'], tx['destination'], tx['btc_amount'], tx['block_index'], overburn=False)
            if problems: status = 'invalid: ' + '; '.join(problems)

            if tx['btc_amount'] != None:
                sent = tx['btc_amount']
            else:
                sent = 0

        if status == 'valid':
            # Calculate quantity of XCP earned. (Maximum 1 BTC in total, ever.)
            cursor = db.cursor()
            cursor.execute('''SELECT * FROM burns WHERE (status = ? AND source = ?)''', ('valid', tx['source']))
            burns = cursor.fetchall()
            already_burned = sum([burn['burned'] for burn in burns])
            ONE = 1 * config.UNIT
            max_burn = ONE - already_burned
            if sent > max_burn: burned = max_burn   # Exceeded maximum burn; earn what you can.
            else: burned = sent

            total_time = config.BURN_END - config.BURN_START
            partial_time = config.BURN_END - tx['block_index']
            multiplier = (1000 + (500 * Fraction(partial_time, total_time)))
            earned = round(burned * multiplier)

            # Credit source address with earned XCP.
            util.credit(db, tx['source'], config.XCP, earned, action='burn', event=tx['tx_hash'])
        else:
            burned = 0
            earned = 0

        tx_index = tx['tx_index']
        tx_hash = tx['tx_hash']
        block_index = tx['block_index']
        source = tx['source']

    else:
        # Mainnet burns are hard‐coded.

        try:
            line = MAINNET_BURNS[tx['tx_hash']]
        except KeyError:
            return

        util.credit(db, line['source'], config.XCP, int(line['earned']), action='burn', event=line['tx_hash'])

        tx_index = tx['tx_index']
        tx_hash = line['tx_hash']
        block_index = line['block_index']
        source = line['source']
        burned = line['burned']
        earned = line['earned']
        status = 'valid'

    # Add parsed transaction to message-type–specific table.
    # TODO: store sent in table
    bindings = {
        'tx_index': tx_index,
        'tx_hash': tx_hash,
        'block_index': block_index,
        'source': source,
        'burned': burned,
        'earned': earned,
        'status': status,
    }
    sql='insert into burns values(:tx_index, :tx_hash, :block_index, :source, :burned, :earned, :status)'
    burn_parse_cursor.execute(sql, bindings)

    burn_parse_cursor.close()

# vim: tabstop=8 expandtab shiftwidth=4 softtabstop=4
