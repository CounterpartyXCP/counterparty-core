#! /usr/bin/python3

"""
offer_hash is the hash of either a bet or an order.
"""

import binascii
import struct

from counterpartylib.lib import (config, exceptions, util)
from . import (order, bet, rps)

FORMAT = '>32s'
LENGTH = 32
ID = 70

def initialise (db):
    cursor = db.cursor()
    cursor.execute('''CREATE TABLE IF NOT EXISTS cancels(
                      tx_index INTEGER PRIMARY KEY,
                      tx_hash TEXT UNIQUE,
                      block_index INTEGER,
                      source TEXT,
                      offer_hash TEXT,
                      status TEXT,
                      FOREIGN KEY (tx_index, tx_hash, block_index) REFERENCES transactions(tx_index, tx_hash, block_index))
                   ''')
                      # Offer hash is not a foreign key. (And it cannot be, because of some invalid cancels.)
    cursor.execute('''CREATE INDEX IF NOT EXISTS
                      cancels_block_index_idx ON cancels (block_index)
                   ''')
    cursor.execute('''CREATE INDEX IF NOT EXISTS
                      source_idx ON cancels (source)
                   ''')

def validate (db, source, offer_hash):
    problems = []

    # TODO: make query only if necessary
    cursor = db.cursor()
    cursor.execute('''SELECT * from orders WHERE tx_hash = ?''', (offer_hash,))
    orders = list(cursor)
    cursor.execute('''SELECT * from bets WHERE tx_hash = ?''', (offer_hash,))
    bets = list(cursor)
    cursor.execute('''SELECT * from rps WHERE tx_hash = ?''', (offer_hash,))
    rps = list(cursor)
    cursor.close()

    offer_type = None
    if orders: offer_type = 'order'
    elif bets: offer_type = 'bet'
    elif rps: offer_type = 'rps'
    else: problems = ['no open offer with that hash']

    offer = None
    if offer_type:
        offers = orders + bets + rps
        offer = offers[0]
        if offer['source'] != source:
            problems.append('incorrect source address')
        if offer['status'] != 'open':
            problems.append('offer not open')

    return offer, offer_type, problems

def compose (db, source, offer_hash):

    # Check that offer exists.
    offer, offer_type, problems = validate(db, source, offer_hash)
    if problems: raise exceptions.ComposeError(problems)

    offer_hash_bytes = binascii.unhexlify(bytes(offer_hash, 'utf-8'))
    data = struct.pack(config.TXTYPE_FORMAT, ID)
    data += struct.pack(FORMAT, offer_hash_bytes)
    return (source, [], data)

def parse (db, tx, message):
    cursor = db.cursor()

    # Unpack message.
    try:
        if len(message) != LENGTH:
            raise exceptions.UnpackError
        offer_hash_bytes = struct.unpack(FORMAT, message)[0]
        offer_hash = binascii.hexlify(offer_hash_bytes).decode('utf-8')
        status = 'valid'
    except (exceptions.UnpackError, struct.error) as e:
        offer_hash = None
        status = 'invalid: could not unpack'

    if status == 'valid':
        offer, offer_type, problems = validate(db, tx['source'], offer_hash)
        if problems:
            status = 'invalid: ' + '; '.join(problems)

    if status == 'valid':
        # Cancel if order.
        if offer_type == 'order':
            order.cancel_order(db, offer, 'cancelled', tx['block_index'])
        # Cancel if bet.
        elif offer_type == 'bet':
            bet.cancel_bet(db, offer, 'cancelled', tx['block_index'])
        # Cancel if rps.
        elif offer_type == 'rps':
            rps.cancel_rps(db, offer, 'cancelled', tx['block_index'])
        # If neither order or bet, mark as invalid.
        else:
            assert False

    # Add parsed transaction to message-type–specific table.
    bindings = {
        'tx_index': tx['tx_index'],
        'tx_hash': tx['tx_hash'],
        'block_index': tx['block_index'],
        'source': tx['source'],
        'offer_hash': offer_hash,
        'status': status,
    }
    sql='INSERT INTO cancels VALUES (:tx_index, :tx_hash, :block_index, :source, :offer_hash, :status)'
    cursor.execute(sql, bindings)

    cursor.close()

# vim: tabstop=8 expandtab shiftwidth=4 softtabstop=4
