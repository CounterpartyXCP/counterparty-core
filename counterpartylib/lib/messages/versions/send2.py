#! /usr/bin/python3

"""Create and parse ‘send’-type messages."""

import struct

from counterpartylib.lib import util
from counterpartylib.lib import config
from counterpartylib.lib.script import AddressError
from counterpartylib.lib.exceptions import ValidateError
from counterpartylib.lib.exceptions import UnpackError
from counterpartylib.lib.exceptions import AssetError
from counterpartylib.lib.exceptions import AssetNameError
from counterpartylib.lib.exceptions import BalanceError

FORMAT = '>QQ'
LENGTH = 8 + 8
ID = 1

def pack(asset, quantity):
    data = struct.pack(config.TXTYPE_FORMAT, ID)
    data += struct.pack(FORMAT, util.asset_id(asset), quantity)
    return data

def unpack(db, message, block_index):
    try:
        asset_id, quantity = struct.unpack(FORMAT, message)
        asset = util.get_asset_name(db, asset_id, block_index)

    except struct.error:
        raise UnpackError('could not unpack')

    except AssetNameError:
        raise UnpackError('asset id invalid')

    unpacked = {
                'asset': asset,
                'quantity': quantity
               }
    return unpacked

def validate(db, source, destination, asset, quantity, block_index):

    try:
        util.get_asset_id(db, asset, block_index)
    except AssetError:
        raise ValidateError('asset invalid')

    try:
        script.validate(source)
    except AddressError:
        raise ValidateError('source address invalid')

    try:
        script.validate(destination)
    except AddressError:
        raise ValidateError('destination address invalid')

    if asset == config.BTC:
        raise ValidateError('cannot send {}'.format(config.BTC))

    if type(quantity) != int:
        raise ValidateError('quantity not integer')

    if quantity > config.MAX_INT:
        raise ValidateError('quantity too large')

    if quantity <= 0:
        raise ValidateError('quantity non‐positive')

    if util.get_balance(db, source, asset) < quantity:
        raise BalanceError('balance insufficient')

def compose(db, source, destination, asset, quantity):

    if asset == config.BTC:
        return (source, [(destination, quantity)], None)

    validate(db, source, destination, asset, quantity, util.CURRENT_BLOCK_INDEX)
    data = pack(asset, quantity)

    return (source, [(destination, None)], data)

def parse(db, tx, message):
    status = 'valid'

    try:
        unpacked = unpack(message)
        asset, quantity = unpacked['asset'], unpacked['quantity']
        validate(db, tx['source'], tx['destination'], asset, quantity, tx['block_index'])
        util.transfer(db, tx['source'], tx['destination'], asset, quantity, 'send', tx['tx_hash'])

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
                    'destination': tx['destination'],
                    'asset': asset,
                    'quantity': quantity,
                    'status': status,
                   }
        sql = 'insert into sends values(:tx_index, :tx_hash, :block_index, :source, :destination, :asset, :quantity, :status)'
        cursor = db.cursor()
        cursor.execute(sql, bindings)

# vim: tabstop=8 expandtab shiftwidth=4 softtabstop=4
