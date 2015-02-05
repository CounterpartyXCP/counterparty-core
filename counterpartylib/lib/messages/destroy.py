#! /usr/bin/python3

"""Destroy a quantity of an asset."""

import struct

from counterpartylib.lib import util
from counterpartylib.lib import config
from counterpartylib.lib import script
from counterpartylib.lib.script import AddressError
from counterpartylib.lib.exceptions import *

FORMAT = '>QQ8s'
LENGTH = 8 + 8 + 8
ID = 110

def initialise(db):
    cursor = db.cursor()
    cursor.execute('''CREATE TABLE IF NOT EXISTS destructions(
                      tx_index INTEGER PRIMARY KEY,
                      tx_hash TEXT UNIQUE,
                      block_index INTEGER,
                      source TEXT,
                      asset INTEGER,
                      quantity INTEGER,
                      tag TEXT,
                      status TEXT,
                      FOREIGN KEY (tx_index, tx_hash, block_index) REFERENCES transactions(tx_index, tx_hash, block_index))
                   ''')
    cursor.execute('''CREATE INDEX IF NOT EXISTS
                      status_idx ON destructions (status)
                   ''')
    cursor.execute('''CREATE INDEX IF NOT EXISTS
                      address_idx ON destructions (source)
                   ''')

def pack(db, asset, quantity, tag):
    data = struct.pack(config.TXTYPE_FORMAT, ID)
    data += struct.pack(FORMAT, util.get_asset_id(db, asset, util.CURRENT_BLOCK_INDEX), quantity, tag)
    return data

def unpack(db, message):
    try:
        asset_id, quantity, tag = struct.unpack(FORMAT, message)
        asset = util.get_asset_name(db, asset_id, util.CURRENT_BLOCK_INDEX)

    except struct.error:
        raise UnpackError('could not unpack')

    except util.AssetNameError:
        raise UnpackError('asset id invalid')

    return asset, quantity, tag

def validate (db, source, destination, asset, quantity):

    try:
        util.get_asset_id(db, asset, util.CURRENT_BLOCK_INDEX)
    except AssetError:
        raise ValidateError('asset invalid')

    try:
        script.validate(source)
    except AddressError:
        raise ValidateError('source address invalid')

    if destination:
        raise ValidateError('destination exists')

    if asset == config.BTC:
        raise ValidateError('cannot destroy {}'.format(config.BTC))

    if type(quantity) != int:
        raise ValidateError('quantity not integer')

    if quantity > config.MAX_INT:
        raise ValidateError('quantity too large')

    if quantity < 0:
        raise ValidateError('quantity negative')

    if util.get_balance(db, source, asset) < quantity:
        raise BalanceError('balance insufficient')

    if not config.TESTNET:
        raise ValidateError('disabled on mainnet')

def compose (db, source, asset, quantity, tag):

    validate(db, source, None, asset, quantity)
    data = pack(db, asset, quantity, tag)

    return (source, [], data)

def parse (db, tx, message):
    status = 'valid'

    try:
        asset, quantity = unpack(message, tx['block_index'])
        validate(db, tx['source'], tx['destination'], asset, quantity)
        util.debit(db, tx['source'], asset, quantity, 'destroy', tx['tx_hash'])

    except UnpackError as e:
        asset, quantity = None, None
        status = 'invalid: ' + ''.join(e.args)

    except (ValidateError, BalanceError) as e:
        status = 'invalid: ' + ''.join(e.args)

    finally:
        bindings = {
                    'tx_index': tx['tx_index'],
                    'tx_hash': tx['tx_hash'],
                    'block_index': tx['block_index'],
                    'source': tx['source'],
                    'asset': asset,
                    'quantity': quantity,
                    'tag': tag,
                    'status': status,
                   }
        sql='insert into destructions values(:tx_index, :tx_hash, :block_index, :source, :asset, :quantity, :tag, :status)'
        cursor = db.cursor()
        cursor.execute(sql, bindings)

# vim: tabstop=8 expandtab shiftwidth=4 softtabstop=4
