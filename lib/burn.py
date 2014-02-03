#! /usr/bin/python3

"""Burn BTC to earn XCP during a special period of time."""

import struct
import decimal
D = decimal.Decimal
import logging

from . import (util, config, exceptions, bitcoin, util)

ID = 60


def validate (db, source, destination, quantity, block_index=None, overburn=False):
    problems = []

    # Check destination address.
    if destination != config.UNSPENDABLE:
        problems.append('wrong destination address')

    # Try to make sure that the burned funds won't go to waste.
    if config.PREFIX != config.UNITTEST_PREFIX:    # For test suite.
        if not block_index: block_index = util.last_block(db)['block_index']
        if block_index < config.BURN_START:
            problems.append('too early')
        elif block_index > config.BURN_END:
            problems.append('too late')

    return problems

def create (db, source, quantity, overburn=False, unsigned=False):
    destination = config.UNSPENDABLE
    problems = validate(db, source, destination, quantity, None, overburn=overburn)
    if problems: raise exceptions.BurnError(problems)

    # Check that a maximum of 1 BTC total is burned per address.
    burns = util.get_burns(db, address=source, validity='Valid')
    already_burned = sum([burn['burned'] for burn in burns])
    if quantity > (1 * config.UNIT - already_burned) and not overburn:
        raise exceptions.BurnError('1 BTC may be burned per address')

    return bitcoin.transaction(source, destination, quantity, config.MIN_FEE, None, unsigned=unsigned)

def parse (db, tx, message=None):
    burn_parse_cursor = db.cursor()
    validity = 'Valid'

    if validity == 'Valid':
        problems = validate(db, tx['source'], tx['destination'], tx['btc_amount'], tx['block_index'], overburn=False)
        if problems: validity = 'Invalid: ' + ';'.join(problems)

        if tx['btc_amount'] != None:
            sent = tx['btc_amount']
        else:
            sent = 0

    if validity == 'Valid':
        # Calculate quantity of XPC earned. (Maximum 1 BTC in total, ever.)
        burns = util.get_burns(db, validity='Valid', address=tx['source'])
        already_burned = sum([burn['burned'] for burn in burns])
        ONE_BTC = 1 * config.UNIT
        max_burn = ONE_BTC - already_burned
        if sent > max_burn: burned = max_burn   # Exceeded maximum burn; earn what you can.
        else: burned = sent

        total_time = D(config.BURN_END - config.BURN_START)
        partial_time = D(config.BURN_END - tx['block_index'])
        multiplier = 1000 * (1 + D(.5) * (partial_time / total_time))
        earned = round(burned * multiplier)

        # For test suite.
        if config.PREFIX == config.UNITTEST_PREFIX:
            earned = 1500 * burned

        # Credit source address with earned XCP.
        util.credit(db, tx['block_index'], tx['source'], 'XCP', earned)

        # Log.
        logging.info('Burn: {} burned {} BTC for {} XCP ({})'.format(tx['source'], util.devise(db, burned, 'BTC', 'output'), util.devise(db, earned, 'XCP', 'output'), tx['tx_hash']))
    else:
        burned = 0
        earned = 0

    # Add parsed transaction to message-type–specific table.
    # TODO: store sent in table
    element_data = {
        'tx_index': tx['tx_index'],
        'tx_hash': tx['tx_hash'],
        'block_index': tx['block_index'],
        'address': tx['source'],
        'burned': burned,
        'earned': earned,
        'validity': validity,
    }
    burn_parse_cursor.execute(*util.get_insert_sql('burns', element_data))


    burn_parse_cursor.close()

# vim: tabstop=8 expandtab shiftwidth=4 softtabstop=4
