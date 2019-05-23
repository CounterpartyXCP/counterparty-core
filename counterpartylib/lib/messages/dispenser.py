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
logger = logging.getLogger(__name__)

from counterpartylib.lib import config
from counterpartylib.lib import exceptions
from counterpartylib.lib import util
from counterpartylib.lib import log
from counterpartylib.lib import message_type

FORMAT = '>QQQQB'
LENGTH = 33
ID = 12

STATUS_OPEN=0
STATUS_CLOSED=10
STATUS_DRAINED=20

def initialise(db):
    cursor = db.cursor()
    cursor.execute('''CREATE TABLE IF NOT EXISTS dispensers(
                      tx_index INTEGER PRIMARY KEY,
                      tx_hash TEXT UNIQUE,
                      block_index INTEGER,
                      source TEXT,
                      asset TEXT,
                      give_quantity INTEGER,
                      giverate INTEGER,
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

def validate (db, source, asset, give_quantity, giverate, satoshirate, status, block_index):
    problems = []
    order_match = None

    if giverate > give_quantity:
        problems.append('dispenser must contain enough of an asset to at least give out one swap')

    cursor = db.cursor()
    cursor.execute('''SELECT quantity FROM balances \
                      WHERE address = ? and asset = ?''', (source,asset,))
    available = cursor.fetchall()
    cursor.close()
    if len(available) == 0:
        problems.append('address doesn\'t has the asset %s' % asset)
        return None, problems
    elif len(available) > 1 and available[0]['quantity'] < give_quantity:
        problems.append('address doesn\'t has enough balance of %s' % asset)
        return None, problems
    else:
        assetid = util.generate_asset_id(asset, block_index)
        if assetid > 0:
            cursor.execute('''SELECT * FROM dispenser WHERE source = ? AND asset = ?''' % (source, asset,))
            return assetid, None
        else:
            problems.append('cannot dispense %s' % asset)
            return None, problems

def compose (db, source, asset, give_quantity, giverate, satoshirate, status):
    assetid, problems = validate(db, source, asset, give_quantity, giverate, satoshirate, status, util.CURRENT_BLOCK_INDEX)
    if problems: raise exceptions.ComposeError(problems)

    data = message_type.pack(ID)
    data += struct.pack(FORMAT, assetid, give_quantity, giverate, satoshirate, status)
    return (source, [], data)

def parse (db, tx, message):
    cursor = db.cursor()

    # Unpack message.
    try:
        if len(message) != LENGTH:
            raise exceptions.UnpackError
        assetid, give_quantity, giverate, satoshirate, dispenser_status = struct.unpack(FORMAT, message)
        asset = util.generate_asset_name(assetid)
        status = 'valid'
    except (exceptions.UnpackError, struct.error) as e:
        assetid, give_quantity, giverate, satoshirate, asset = None, None, None, None
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
                util.debit(db, tx['source'], asset, give_quantity, action='open dispenser', event=tx['tx_hash'])
                bindings = {
                    'tx_index': tx['tx_index'],
                    'tx_hash': tx['tx_hash'],
                    'block_index': tx['block_index'],
                    'source': tx['source'],
                    'asset': asset,
                    'give_quantity': give_quantity,
                    'giverate': giverate,
                    'satoshirate': satoshirate,
                    'status': dispenser_status,
                    'give_remaining': give_remaining
                }
                sql = 'insert into dispensers values(:tx_index, :tx_hash, :block_index, :source, :asset, :give_quantity, :giverate, :satoshirate, :status, :give_remaining)'
                cursor.execute(sql, bindings)
            elif len(existing) == 1 and satoshirate == 0 and giverate == 0:
                # Refill the dispenser by the given amount, rates will remain the same
                bindings = {
                    'source': tx['source'],
                    'asset': asset,
                    'give_quantity': existing[0]['give_quantity'] + give_quantity,
                    'status': dispenser_status,
                    'give_remaining': existing[0]['give_remaining'] + give_quantity,
                    'status': STATUS_OPEN,
                }
                util.debit(db, tx['source'], asset, give_quantity, action='refill dispenser', event=tx['tx_hash'])
                sql = '''UPDATE dispensers SET give_remaining=:give_remaining, give_quantity=:give_quantity
                    WHERE source=:source AND asset=:asset AND status=:status'''
                cursor.execute(sql, bindings)
            else:
                status = 'can only have one open dispenser per asset per address'
        elif dispenser_status == STATUS_CLOSE:
            cursor.execute('SELECT give_remaining FROM dispensers WHERE source=:source AND asset=:asset AND status=:status', {
                'source': tx['source'],
                'asset': asset,
                'status': STATUS_OPEN
            })
            existing = cursor.fetchall()

            if len(existing) == 1:
                util.credit(db, tx['source'], asset, existing['give_remaining'], action='close dispenser', event=tx['tx_hash'])
                bindings = {
                    'source': tx['source'],
                    'asset': asset,
                    'status': STATUS_CLOSED
                }
                sql = 'UPDATE dispensers SET give_remaining=0, status=:status WHERE source=:source AND asset=:asset'
                cursor.execute(sql, bindings)
            else:
                status = 'dispenser inexistent'
        else:
            status = 'invalid: status must be one of OPEN or CLOSE'

    cursor.close()
