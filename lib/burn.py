#! /usr/bin/python3

"""Burn BTC to earn XCP during a special period of time."""

import struct
import decimal
D = decimal.Decimal
import logging

from . import (util, config, exceptions, bitcoin, util)

FORMAT = '>11s'
ID = 60
LENGTH = 11

def create (db, source, quantity, test=False, overburn=False):
    # Try to make sure that the burned funds won't go to waste.
    block_count = bitcoin.rpc('getblockcount', [])
    if block_count < config.BURN_START:
        raise exceptions.UselessError('The proof-of-burn period has not yet begun.')
    elif block_count > config.BURN_END:
        raise exceptions.UselessError('The proof-of-burn period has already ended.')

    # Check that a maximum of 1 BTC total is burned per address.
    burns = util.get_burns(db, address=source, validity='Valid')
    already_burned = sum([burn['burned'] for burn in burns])
    if quantity > (1 * config.UNIT - already_burned) and not overburn:
        raise exceptions.UselessError('A maximum of 1 BTC may be burned per address.')
        
    return bitcoin.transaction(source, config.UNSPENDABLE, quantity, config.MIN_FEE, None, test)

def parse (db, tx, message=None):
    burn_parse_cursor = db.cursor()
    validity = 'Valid'

    # Check destination address.
    if validity == 'Valid' and tx['destination'] != config.UNSPENDABLE:
        validity = 'Invalid: wrong destination address'

    if validity == 'Valid' and tx['btc_amount'] != None:
        sent = tx['btc_amount']
    else:
        sent = 0

    # Check that the burn was done at the right time.
    if tx['block_index'] < config.BURN_START: 
        validity = 'Invalid: too early'
    elif tx['block_index'] > config.BURN_END:
        validity = 'Invalid: too late'

    # Calculate quantity of XPC earned. (Maximum 1 BTC in total, ever.)
    if validity == 'Valid':
        burns = util.get_burns(db, validity='Valid', address=tx['source'])
        already_burned = sum([burn['burned'] for burn in burns])
        ONE_BTC = 1 * config.UNIT
        max_burn = ONE_BTC - already_burned
        if sent > max_burn: burned = max_burn   # TODO: exceeded maximum burn; earn what you can.
        else: burned = sent

        total_time = D(config.BURN_END - config.BURN_START)
        partial_time = D(config.BURN_END - tx['block_index'])
        multiplier = 1000 * (1 + D(.5) * (partial_time / total_time))
        earned = round(burned * multiplier)

    # Credit source address with earned XCP.
    if validity == 'Valid':
        util.credit(db, tx['source'], 'XCP', earned)

    # Add parsed transaction to message-type–specific table.
    # TODO: store sent in table
    burn_parse_cursor.execute('''INSERT INTO burns(
                        tx_index,
                        tx_hash,
                        block_index,
                        address,
                        burned,
                        earned,
                        validity) VALUES(?,?,?,?,?,?,?)''',
                        (tx['tx_index'],
                        tx['tx_hash'],
                        tx['block_index'],
                        tx['source'],
                        burned,
                        earned,
                        validity)
                  )
    
    if validity == 'Valid':
        logging.info('Burn: {} burned {} BTC for {} XCP ({})'.format(tx['source'], util.devise(db, burned, 'BTC', 'output'), util.devise(db, earned, 'XCP', 'output'), util.short(tx['tx_hash'])))

    burn_parse_cursor.close()

# vim: tabstop=8 expandtab shiftwidth=4 softtabstop=4
