#! /usr/bin/python3
#
# What is a dispenser?
#
# A dispenser is a type of order where the holder address gives out a given amount
# of units of an asset for a given amount of BTC satoshis received.
# It's a very simple but powerful semantic to allow swaps to operate on-chain.
#

import binascii
import json
import pprint
import struct
import logging
from math import floor
logger = logging.getLogger(__name__)

from counterpartylib.lib import config
from counterpartylib.lib import exceptions
from counterpartylib.lib import util
from counterpartylib.lib import log
from counterpartylib.lib import message_type

FORMAT = '>QQQQB'
LENGTH = 33
ID = 12
DISPENSE_ID = 13

STATUS_OPEN=0
STATUS_CLOSED=10

def initialise(db):
    cursor = db.cursor()
    cursor.execute('''CREATE TABLE IF NOT EXISTS dispensers(
                      tx_index INTEGER PRIMARY KEY,
                      tx_hash TEXT UNIQUE,
                      block_index INTEGER,
                      source TEXT,
                      asset TEXT,
                      give_quantity INTEGER,
                      escrow_quantity INTEGER,
                      satoshirate INTEGER,
                      status INTEGER,
                      give_remaining INTEGER,
                      FOREIGN KEY (tx_index, tx_hash, block_index) REFERENCES transactions(tx_index, tx_hash, block_index))
                   ''')
                      # Disallows invalids: FOREIGN KEY (order_match_id) REFERENCES order_matches(id))
    cursor.execute('''CREATE INDEX IF NOT EXISTS
                      source_idx ON dispensers (source)
                   ''')
    cursor.execute('''CREATE INDEX IF NOT EXISTS
                      asset_idx ON dispensers (asset)
                   ''')

def validate (db, source, asset, give_quantity, escrow_quantity, mainchainrate, status, block_index):
    problems = []
    order_match = None
    asset_id = None

    if asset == config.BTC:
        problems.append('cannot dispense %s' % config.BTC)
        return None, problems

    if escrow_quantity < give_quantity:
        problems.append('escrow_quantity must be greater or equal than give_quantity')

    if not(status == STATUS_OPEN or status == STATUS_CLOSED):
        problems.append('invalid status %i' % status)

    cursor = db.cursor()
    cursor.execute('''SELECT quantity FROM balances \
                      WHERE address = ? and asset = ?''', (source,asset,))
    available = cursor.fetchall()

    if len(available) == 0:
        problems.append('address doesn\'t has the asset %s' % asset)
    elif len(available) >= 1 and available[0]['quantity'] < escrow_quantity:
        problems.append('address doesn\'t has enough balance of %s (%i < %i)' % (asset, available[0]['quantity'], escrow_quantity))
    else:
        cursor.execute('''SELECT * FROM dispensers WHERE source = ? AND asset = ? AND status=?''', (source, asset, STATUS_OPEN))
        open_dispensers = cursor.fetchall()
        if status == STATUS_OPEN:
            if len(open_dispensers) > 0 and open_dispensers[0]['satoshirate'] != mainchainrate:
                problems.append('address has a dispenser already opened for asset %s with a different mainchainrate' % asset)

            if len(open_dispensers) > 0 and open_dispensers[0]['give_quantity'] != give_quantity:
                problems.append('address has a dispenser already opened for asset %s with a different give_quantity' % asset)
        elif status == STATUS_CLOSED:
            if len(open_dispensers) == 0:
                problems.append('address doesnt has an open dispenser for asset %s' % asset)

        if len(problems) == 0:
            asset_id = util.generate_asset_id(asset, block_index)
            if asset_id == 0:
                problems.append('cannot dispense %s' % asset) # How can we test this on a test vector?

    cursor.close()
    if len(problems) > 0:
        return None, problems
    else:
        return asset_id, None

def compose (db, source, asset, give_quantity, escrow_quantity, mainchainrate, status):
    assetid, problems = validate(db, source, asset, give_quantity, escrow_quantity, mainchainrate, status, util.CURRENT_BLOCK_INDEX)
    if problems: raise exceptions.ComposeError(problems)

    data = message_type.pack(ID)
    data += struct.pack(FORMAT, assetid, give_quantity, escrow_quantity, mainchainrate, status)
    return (source, [], data)

def parse (db, tx, message):
    cursor = db.cursor()

    # Unpack message.
    try:
        if len(message) != LENGTH:
            raise exceptions.UnpackError
        assetid, give_quantity, escrow_quantity, mainchainrate, dispenser_status = struct.unpack(FORMAT, message)
        asset = util.generate_asset_name(assetid, util.CURRENT_BLOCK_INDEX)
        status = 'valid'
    except (exceptions.UnpackError, struct.error) as e:
        assetid, give_quantity, mainchainrate, asset = None, None, None, None
        status = 'invalid: could not unpack'

    if status == 'valid':
        if dispenser_status == STATUS_OPEN:
            cursor.execute('SELECT * FROM dispensers WHERE source=:source AND asset=:asset AND status=:status', {
                'source': tx['source'],
                'asset': asset,
                'status': STATUS_OPEN
            })
            existing = cursor.fetchall()

            if len(existing) == 0:
                # Create the new dispenser
                util.debit(db, tx['source'], asset, escrow_quantity, action='open dispenser', event=tx['tx_hash'])
                bindings = {
                    'tx_index': tx['tx_index'],
                    'tx_hash': tx['tx_hash'],
                    'block_index': tx['block_index'],
                    'source': tx['source'],
                    'asset': asset,
                    'give_quantity': give_quantity,
                    'escrow_quantity': escrow_quantity,
                    'satoshirate': mainchainrate,
                    'status': dispenser_status,
                    'give_remaining': escrow_quantity
                }
                sql = 'insert into dispensers values(:tx_index, :tx_hash, :block_index, :source, :asset, :give_quantity, :escrow_quantity, :satoshirate, :status, :give_remaining)'
                cursor.execute(sql, bindings)
            elif len(existing) == 1 and existing[0]['satoshirate'] == mainchainrate and existing[0]['give_quantity'] == give_quantity:
                # Refill the dispenser by the given amount
                bindings = {
                    'source': tx['source'],
                    'asset': asset,
                    'status': dispenser_status,
                    'give_remaining': existing[0]['give_remaining'] + escrow_quantity,
                    'status': STATUS_OPEN,
                    'block_index': tx['block_index']
                }
                util.debit(db, tx['source'], asset, escrow_quantity, action='refill dispenser', event=tx['tx_hash'])
                sql = 'UPDATE dispensers SET give_remaining=:give_remaining \
                    WHERE source=:source AND asset=:asset AND status=:status'
                cursor.execute(sql, bindings)
            else:
                status = 'can only have one open dispenser per asset per address'
        elif dispenser_status == STATUS_CLOSED:
            cursor.execute('SELECT give_remaining FROM dispensers WHERE source=:source AND asset=:asset AND status=:status', {
                'source': tx['source'],
                'asset': asset,
                'status': STATUS_OPEN
            })
            existing = cursor.fetchall()

            if len(existing) == 1:
                util.credit(db, tx['source'], asset, existing[0]['give_remaining'], action='close dispenser', event=tx['tx_hash'])
                bindings = {
                    'source': tx['source'],
                    'asset': asset,
                    'status': STATUS_CLOSED,
                    'block_index': tx['block_index']
                }
                sql = 'UPDATE dispensers SET give_remaining=0, status=:status WHERE source=:source AND asset=:asset'
                cursor.execute(sql, bindings)
            else:
                status = 'dispenser inexistent'
        else:
            status = 'invalid: status must be one of OPEN or CLOSE'

    cursor.close()

def is_dispensable(db, address, amount):
    cursor = db.cursor()
    cursor.execute('SELECT count(*) as cnt FROM dispensers WHERE source=:source AND status=:status AND satoshirate<=:amount', {
        'source': address,
        'amount': amount,
        'status': STATUS_OPEN
    })
    dispensers = cursor.fetchall()
    cursor.close()
    return len(dispensers) > 0 and dispensers[0]['cnt'] > 0

def dispense(db, tx):
    cursor = db.cursor()
    cursor.execute('SELECT * FROM dispensers WHERE source=:source AND status=:status', {
        'source': tx['destination'],
        'status': STATUS_OPEN
    })
    dispensers = cursor.fetchall()

    for dispenser in dispensers:
        must_give = int(floor(tx['btc_amount'] / dispenser['satoshirate']))
        remaining = int(floor(dispenser['give_remaining'] / dispenser['give_quantity']))
        actually_given = min(must_give, remaining) * dispenser['give_quantity']
        give_remaining = dispenser['give_remaining'] - actually_given

        assert give_remaining >= 0

        util.credit(db, tx['source'], dispenser['asset'], actually_given, action='dispense', event=tx['tx_hash'])

        dispenser['give_remaining'] = give_remaining
        if give_remaining < dispenser['give_quantity']:
            # close the dispenser
            dispenser['give_remaining'] = 0
            if give_remaining > 0:
                # return the remaining to the owner
                util.credit(db, dispenser['source'], dispenser['asset'], give_remaining, action='dispenser close', event=tx['tx_hash'])
            dispenser['status'] = STATUS_CLOSED

        cursor.execute('UPDATE DISPENSERS SET give_remaining=:give_remaining, status=:status \
                WHERE source=:source AND asset=:asset AND satoshirate=:satoshirate AND give_quantity=:give_quantity', dispenser)

    cursor.close()
