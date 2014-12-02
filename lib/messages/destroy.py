#! /usr/bin/python3

"""Destroy a quantity of an asset."""

import struct

from lib import (util, config)
from lib.exceptions import *

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

def pack(asset, quantity, tag):
    data = struct.pack(config.TXTYPE_FORMAT, ID)
    data += struct.pack(FORMAT, util.asset_id(asset), quantity, tag)
    return data

def unpack(message):
    try:
        asset_id, quantity, tag = struct.unpack(FORMAT, message)
        asset = util.asset_name(asset_id)

    except struct.error:
        raise UnpackError('could not unpack')

    except util.AssetNameError:
        raise UnpackError('asset id invalid')

    return asset, quantity, tag

def validate (db, source, destination, asset, quantity, block_index):

    if util.protocol_change(block_index, 335000):
        raise ValidateAssetError('destroy disabled')

    try:
        util.asset_id(asset)
    except AssetError:
        raise ValidateAssetError('asset invalid')

    try:
        util.validate_address(source, block_index)
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
        raise ValidateError('balance insufficient')

def compose (db, source, asset, quantity, tag):

    validate(db, source, None, asset, quantity, util.last_block(db)['block_index'])
    data = pack(asset, quantity)

    return (source, [], data)

def parse (db, tx, message):
    status = 'valid'

    try:
        asset, quantity = unpack(message)
        validate(db, tx['source'], tx['destination'], asset, quantity, tx['block_index'])
        util.debit(db, tx['block_index'], tx['source'], asset, quantity, 'destroy', tx['tx_hash'])

    except UnpackError as e:
        asset, quantity = None, None
        status = 'invalid: ' + ''.join(e.args)

    except ValidateError as e:
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
