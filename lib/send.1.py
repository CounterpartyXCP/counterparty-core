#! /usr/bin/python3

"""Create and parse ‘send’-type messages."""

import struct

from . import (util, config)
from exceptions import *

FORMAT = '>QQ'
LENGTH = 8 + 8
ID = 1

def unpack(message):
    try:
        asset_id, quantity = struct.unpack(FORMAT, message)
        asset = util.asset_name(asset_id)

    except struct.error:
        raise UnpackError('could not unpack')

    except AssetNameError:
        raise UnpackError('asset id invalid')

    return asset, quantity

def validate (db, source, destination, asset, quantity, block_index):

    try:
        util.asset_id(asset)
    except AssetError:
        raise ValidateAssetError('asset invalid')

    try:
        util.validate_address(source, block_index):
    except AddressError:
        raise ValidateError('source address invalid')

    try:
        util.validate_address(destination, block_index):
    except AddressError:
        raise ValidateError('destination address invalid')

    if asset == config.BTC:
        raise ValidateError('cannot send {}'.format(config.BTC))

    if type(quantity) != int:
        raise ValidateError('quantity not integer')

    if quantity > config.MAX_INT:
        raise ValidateError('quantity too large')

    if quantity < 0:
        raise ValidateError('quantity negative')

    if util.get_balance(db, source, asset) < quantity:
        raise ValidateError('balance insufficient')

def compose (db, source, destination, asset, quantity):

    if asset == config.BTC:
        return (source, [(destination, quantity)], None)

    validate(db, source, destination, asset, quantity, util.last_block['block_index'])

    data = struct.pack(config.TXTYPE_FORMAT, ID)
    data += struct.pack(FORMAT, util.asset_id(asset), quantity)

    return (source, [(destination, None)], data)

def parse (db, tx, message):
    status = 'valid'

    try:
        asset, quantity = unpack(message)
        validate(db, tx['source'], tx['destination'], asset, quantity, tx['block_index'])
        util.transfer(db, tx['block_index'], tx['source'], tx['destination'], asset, quantity, 'send', tx['tx_hash'])

    except UnpackError as e:
        asset, quantity = None, None
        status = 'invalid: ' + e.args

    except ValidateError as e:
        status = 'invalid: ' + e.args

    finally:
        bindings = {
                    'tx_index': tx['tx_index'],
                    'tx_hash': tx['tx_hash'],
                    'block_index': tx['block_index'],
                    'source': tx['source'],
                    'destination': tx['destination'],
                    'asset': asset,
                    'quantity': quantity,
                    'status': status,
                   }
        util.insert(db, 'sends', bindings)

# vim: tabstop=8 expandtab shiftwidth=4 softtabstop=4
