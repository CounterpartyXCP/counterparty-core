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
        asset_id, quantity, short_address_bytes = struct.unpack(FORMAT, message[:LENGTH])
        
        # unpack address
        try:
          full_address = address.unpack(short_address_bytes)
        except:
          raise exceptions.UnpackError('address invalid')

        # unpack memo
        memo = message[37:]
        if len(memo) > MAX_MEMO_LENGTH:
          raise exceptions.UnpackError('memo too long')
        if len(memo) == 0:
          memo = None

        # asset id to name
        asset = util.generate_asset_name(asset_id, block_index)

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
      'memo': memo,
    }
    return unpacked

def validate (db, source, destination, asset, quantity, block_index):
    # unimplemented
    pass

def compose (db, source, destination, asset, quantity):
    # unimplemented
    pass

def parse (db, tx, message):
    # unimplemented
    pass

# vim: tabstop=8 expandtab shiftwidth=4 softtabstop=4
