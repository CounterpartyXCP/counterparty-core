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

def create (db, source, quantity, test=False):
    # Try to make sure that the burned funds won’t go to waste.
    block_count = bitcoin.rpc('getblockcount', [])['result']
    if block_count < config.BURN_START:
        raise exceptions.UselessError('The proof‐of‐burn period has not yet begun.')
    elif block_count > config.BURN_END:
        raise exceptions.UselessError('The proof‐of‐burn period has already ended.')

    # Check that a maximum of 1 BTC total is burned per address.
    burns = util.get_burns(db, address=source, validity='Valid')
    total_burned = sum([burn['burned'] for burn in burns])
    if quantity > (1 * config.UNIT - total_burned):
        raise exceptions.UselessError('A maximum of 1 BTC may be burned per address.')
        
    data = config.PREFIX + struct.pack(config.TXTYPE_FORMAT, ID)
    data += struct.pack(FORMAT, 'ProofOfBurn'.encode('utf-8'))
    return bitcoin.transaction(source, config.UNSPENDABLE, quantity, config.MIN_FEE, data, test)

def parse (db, tx, message):
    burn_parse_cursor = db.cursor()
    validity = 'Valid'

    # Unpack message.
    try:
        hidden_message = struct.unpack(FORMAT, message)
    except Exception:
        validity = 'Invalid: could not unpack'

    # Check for burn notice (heh).
    if validity == 'Valid' and hidden_message[0].decode('utf-8') != 'ProofOfBurn':
        validity = 'Invalid: secret message not found'

    # Check destination address.
    if validity == 'Valid' and tx['destination'] != config.UNSPENDABLE:
        validity = 'Invalid: wrong destination address'

    if validity == 'Valid' and tx['btc_amount'] != None:
        burned = tx['btc_amount']
    else:
        burned = 0

    # Check that a maximum of 1 BTC total is burned per address.
    burns = util.get_burns(db, validity='Valid', address=tx['source'])
    total_burned = sum([burn['burned'] for burn in burns])
    if burned > (1 * config.UNIT - total_burned):
        validity = 'Invalid: exceeded maximum burn'

    # Check that the burn was done at the right time.
    if tx['block_index'] < config.BURN_START: 
        validity = 'Invalid: too early'
    elif tx['block_index'] > config.BURN_END:
        validity = 'Invalid: too late'

    # Calculate quantity of XPC earned.
    total_time = D(config.BURN_END - config.BURN_START)
    partial_time = D(config.BURN_END - tx['block_index'])
    multiplier = 1000 * (1 + D(.5) * (partial_time / total_time))
    earned = round(burned * multiplier)
 
    # Credit source address with earned XCP.
    if validity == 'Valid':
        util.credit(db, tx['source'], 'XCP', earned)

    # Add parsed transaction to message‐type–specific table.
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
