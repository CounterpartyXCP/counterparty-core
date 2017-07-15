#! /usr/bin/python3

import struct
import json
import logging
logger = logging.getLogger(__name__)

from counterpartylib.lib import (config, util, exceptions, util, message_type, address)

FORMAT = '>QQ21s'
LENGTH = 8 + 8 + 21
MAX_MEMO_LENGTH = 34
ID = 2 # 0x02

def initialise (db):
    cursor = db.cursor()

    # Adds a memo to sends
    #   SQLite can’t do `ALTER TABLE IF COLUMN NOT EXISTS`.
    columns = [column['name'] for column in cursor.execute('''PRAGMA table_info(sends)''')]
    if 'memo' not in columns:
        cursor.execute('''ALTER TABLE sends ADD COLUMN memo BLOB''')

    cursor.execute('''CREATE INDEX IF NOT EXISTS
                      memo_idx ON sends (memo)
                   ''')

def unpack(db, message, block_index):
    try:
        # account for memo bytes
        memo_bytes_length = len(message) - LENGTH
        if memo_bytes_length < 0:
            raise exceptions.UnpackError('invalid message length')
        if memo_bytes_length > MAX_MEMO_LENGTH:
            raise exceptions.UnpackError('memo too long')

        struct_format = FORMAT + ('{}s'.format(memo_bytes_length))
        asset_id, quantity, short_address_bytes, memo_bytes = struct.unpack(struct_format, message)
        if len(memo_bytes) == 0:
            memo_bytes = None
        
        # unpack address
        try:
          full_address = address.unpack(short_address_bytes)
        except:
          raise exceptions.UnpackError('address invalid')

        # asset id to name
        asset = util.generate_asset_name(asset_id, block_index)
        if asset == config.BTC:
          raise exceptions.AssetNameError('{} not allowed'.format(config.BTC))

    except (struct.error) as e:
        logger.warning("enhanced send unpack error: {}".format(e))
        raise exceptions.UnpackError('could not unpack')

    except (exceptions.AssetNameError, exceptions.AssetIDError) as e:
        logger.warning("enhanced send invalid asset id: {}".format(e))
        raise exceptions.UnpackError('asset id invalid')

    unpacked = {
      'asset': asset,
      'quantity': quantity,
      'address': full_address,
      'memo': memo_bytes,
    }
    return unpacked

def validate (db, source, destination, asset, quantity, memo_bytes, block_index):
    problems = []

    if asset == config.BTC: problems.append('cannot send {}'.format(config.BTC))

    if not isinstance(quantity, int):
        problems.append('quantity must be in satoshis')
        return problems

    if quantity < 0:
        problems.append('negative quantity')

    # if quantity == 0:
    #     problems.append('zero quantity')

    # For SQLite3
    if quantity > config.MAX_INT:
        problems.append('integer overflow')

    # destination is always required
    if not destination:
        problems.append('destination is required')

    # check memo
    if memo_bytes is not None and len(memo_bytes) > MAX_MEMO_LENGTH:
      problems.append('memo is too long')

    return problems

def compose (db, source, destination, asset, quantity, memo, memo_is_hex):
    cursor = db.cursor()

    # Just send BTC?
    if asset == config.BTC:
        return (source, [(destination, quantity)], None)

    # resolve subassets
    asset = util.resolve_subasset_longname(db, asset)

    #quantity must be in int satoshi (not float, string, etc)
    if not isinstance(quantity, int):
        raise exceptions.ComposeError('quantity must be an int (in satoshi)')

    # Only for outgoing (incoming will overburn).
    balances = list(cursor.execute('''SELECT * FROM balances WHERE (address = ? AND asset = ?)''', (source, asset)))
    if not balances or balances[0]['quantity'] < quantity:
        raise exceptions.ComposeError('insufficient funds')

    # convert memo to memo_bytes based on memo_is_hex setting
    if memo is None:
        memo_bytes = b''
    elif memo_is_hex:
        memo_bytes = bytes.fromhex(memo)
    else:
        memo = memo.encode('utf-8')
        memo_bytes = struct.pack(">{}s".format(len(memo)), memo)

    block_index = util.CURRENT_BLOCK_INDEX

    problems = validate(db, source, destination, asset, quantity, memo_bytes, block_index)
    if problems: raise exceptions.ComposeError(problems)

    asset_id = util.get_asset_id(db, asset, block_index)

    short_address_bytes = address.pack(destination)

    data = message_type.pack(ID)
    data += struct.pack(FORMAT, asset_id, quantity, short_address_bytes)
    data += memo_bytes

    cursor.close()
    return (source, [(destination, None)], data)

def parse (db, tx, message):
    # unimplemented
    pass

# vim: tabstop=8 expandtab shiftwidth=4 softtabstop=4
