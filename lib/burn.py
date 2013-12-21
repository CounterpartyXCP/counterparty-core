#! /usr/bin/python3

"""Burn BTC (in miners’ fees) to earn XCP during a special period of time."""

import struct
import sqlite3
import decimal
D = decimal.Decimal
import colorama
colorama.init()

from . import (util, config, exceptions, bitcoin)

FORMAT = '>11s'
ID = 60

def create (source, quantity):
    db = sqlite3.connect(config.LEDGER)
    db.row_factory = sqlite3.Row
    cursor = db.cursor()

    # Make sure that the burned funds won’t go to waste.
    block_count = bitcoin.rpc('getblockcount', [])['result']
    if block_count < config.BURN_START:
        raise exceptions.UselessError('The proof‐of‐burn period has not yet begun.')
    elif block_count > config.BURN_END:
        raise exceptions.UselessError('The proof‐of‐burn period has already ended.')

    # Check that a maximum of 1 BTC total is burned per address.
    cursor, total_burned = util.total_burned(cursor, source)
    if quantity > (1 * config.UNIT - total_burned):
        raise exceptions.UselessError('A maximum of 1 BTC may be burned per address.')
        
    data = config.PREFIX + struct.pack(config.TXTYPE_FORMAT, ID)
    data += struct.pack(FORMAT, 'ProofOfBurn'.encode('utf-8'))
    return bitcoin.transaction(source, None, config.DUST_SIZE, int(quantity), data)

def parse (db, cursor, tx, message):
    # Ask for forgiveness…
    validity = 'Valid'

    # Unpack message.
    try:
        hidden_message = struct.unpack(FORMAT, message)
    except Exception:   #
        validity = 'Invalid: could not unpack'

    if not hidden_message[0].decode('utf-8') == 'ProofOfBurn':
        validity = 'Invalid: secret message not found'

    burned = int(tx['fee'])

    # Check that a maximum of 1 BTC total is burned per address.
    cursor, total_burned = util.total_burned(cursor, tx['source'])
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
    multiplier = 100 * (1 + (partial_time / total_time))
    earned = burned * int(multiplier)
 
    # Credit source address with earned XCP.
    if validity == 'Valid':
        db, cursor = util.credit(db, cursor, tx['source'], 1, earned)

    # Add parsed transaction to message‐type–specific table.
    cursor.execute('''INSERT INTO burns(
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
        print(colorama.Style.BRIGHT + '\tBurn:', burned / config.UNIT, 'BTC burned;', earned / config.UNIT, 'XCP earned', util.short(tx['tx_hash']) + colorama.Style.RESET_ALL)

    return db, cursor

# vim: tabstop=8 expandtab shiftwidth=4 softtabstop=4
