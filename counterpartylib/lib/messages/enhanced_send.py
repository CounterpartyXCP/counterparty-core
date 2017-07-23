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
    # return an empty array as the second argument because we don't need to send BTC dust to the recipient
    return (source, [], data)

def parse (db, tx, message):
    cursor = db.cursor()

    # Unpack message.
    try:
        unpacked = unpack(db, message, tx['block_index'])
        asset       = unpacked['asset']
        quantity    = unpacked['quantity']
        destination = unpacked['address']
        memo_bytes  = unpacked['memo']

        status = 'valid'

    except (exceptions.UnpackError, exceptions.AssetNameError, struct.error) as e:
        asset, quantity, destination, memo_bytes = None, None, None, None
        status = 'invalid: could not unpack ({})'.format(e)
    except:
        asset, quantity, destination, memo_bytes = None, None, None, None
        status = 'invalid: could not unpack'

    if status == 'valid':
        # Oversend
        cursor.execute('''SELECT * FROM balances \
                                     WHERE (address = ? AND asset = ?)''', (tx['source'], asset))
        balances = cursor.fetchall()
        if not balances:
            status = 'invalid: insufficient funds'
        elif balances[0]['quantity'] < quantity:
            quantity = min(balances[0]['quantity'], quantity)

    # For SQLite3
    if quantity:
        quantity = min(quantity, config.MAX_INT)

    if status == 'valid':
        problems = validate(db, tx['source'], destination, asset, quantity, memo_bytes, tx['block_index'])
        if problems: status = 'invalid: ' + '; '.join(problems)

    if status == 'valid':
        util.debit(db, tx['source'], asset, quantity, action='send', event=tx['tx_hash'])
        util.credit(db, destination, asset, quantity, action='send', event=tx['tx_hash'])

    # log invalid transactions
    if status != 'valid':
        if quantity is None:
            logger.warn("Invalid send from %s with status %s. (%s)" % (tx['source'], status, tx['tx_hash']))
        else:
            logger.warn("Invalid send of %s %s from %s to %s. status is %s. (%s)" % (quantity, asset, tx['source'], destination, status, tx['tx_hash']))


    # Add parsed transaction to message-type–specific table.
    bindings = {
        'tx_index': tx['tx_index'],
        'tx_hash': tx['tx_hash'],
        'block_index': tx['block_index'],
        'source': tx['source'],
        'destination': destination,
        'asset': asset,
        'quantity': quantity,
        'status': status,
        'memo': memo_bytes,
    }
    if "integer overflow" not in status and "quantity must be in satoshis" not in status:
        sql = 'insert into sends values(:tx_index, :tx_hash, :block_index, :source, :destination, :asset, :quantity, :status, :memo)'
        cursor.execute(sql, bindings)
    else:
        logger.warn("Not storing [send] tx [%s]: %s" % (tx['tx_hash'], status))
        logger.debug("Bindings: %s" % (json.dumps(bindings), ))


    cursor.close()

# vim: tabstop=8 expandtab shiftwidth=4 softtabstop=4
