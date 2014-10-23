#! /usr/bin/python3

"""Create and parse ‘send’-type messages."""

import struct

from . import (util, config, bitcoin, util)
from exceptions import *

FORMAT = '>QQ'
LENGTH = 8 + 8
ID = 1

def validate (db, source, destination, asset, quantity):

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

    validate(db, source, destination, asset, quantity)

    data = struct.pack(config.TXTYPE_FORMAT, ID)
    data += struct.pack(FORMAT, util.asset_id(asset), quantity)

    return (source, [(destination, None)], data)

def parse (db, tx, message):
    status = 'valid'

    try:
        asset_id, quantity = struct.unpack(FORMAT, message)
        asset = util.asset_name(asset_id)

        validate(db, tx['source'], tx['destination'], asset, quantity)
        util.transfer(db, tx['block_index'], tx['destination'], asset, quantity, action='send', event=tx['tx_hash'])

    except (AssetNameError, struct.error):
        asset, quantity = None, None
        status = 'invalid: could not unpack'

    except ValidateError as e:
        status = 'invalid: ' + e.args)

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
