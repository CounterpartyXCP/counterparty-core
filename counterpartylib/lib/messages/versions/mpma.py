#! /usr/bin/python3

import struct
import json
import logging
import binascii
import math
from bitcoin.core import key
from functools import reduce
from itertools import groupby

logger = logging.getLogger(__name__)

from bitstring import ReadError
from counterpartylib.lib import (config, util, exceptions, util, message_type, address)

from .mpma_util.internals import (_decode_mpmaSendDecode, _encode_mpmaSend)

ID = 3 # 0x03 is this specific message type

## expected functions for message version
def unpack(db, message, block_index):
    try:
        unpacked = _decode_mpmaSendDecode(message, block_index)
    except (struct.error) as e:
        raise exceptions.UnpackError('could not unpack')
    except (exceptions.AssetNameError, exceptions.AssetIDError) as e:
        raise exceptions.UnpackError('invalid asset in mpma send')
    except (ReadError) as e:
        raise exceptions.UnpackError('truncated data')

    return unpacked

def validate (db, source, asset_dest_quant_list, block_index):
    problems = []

    if len(asset_dest_quant_list) == 0:
        problems.append('send list cannot be empty')

    if len(asset_dest_quant_list) == 1:
        problems.append('send list cannot have only one element')

    if len(asset_dest_quant_list) > 0:
        # Need to manually unpack the tuple to avoid errors on scenarios where no memo is specified
        grpd = groupby([(t[0], t[1]) for t in asset_dest_quant_list])
        lengrps = [len(list(grpr)) for (group, grpr) in grpd]
        cardinality = max(lengrps)
        if cardinality > 1:
            problems.append('cannot specify more than once a destination per asset')

    cursor = db.cursor()
    for t in asset_dest_quant_list:
        # Need to manually unpack the tuple to avoid errors on scenarios where no memo is specified
        asset = t[0]
        destination = t[1]
        quantity = t[2]

        sendMemo = None
        if len(t) > 3:
            sendMemo = t[3]

        if asset == config.BTC: problems.append('cannot send {} to {}'.format(config.BTC, destination))

        if not isinstance(quantity, int):
            problems.append('quantities must be an int (in satoshis) for {} to {}'.format(asset, destination))

        if quantity < 0:
            problems.append('negative quantity for {} to {}'.format(asset, destination))

        if quantity == 0:
            problems.append('zero quantity for {} to {}'.format(asset, destination))

        # For SQLite3
        if quantity > config.MAX_INT:
            problems.append('integer overflow for {} to {}'.format(asset, destination))

        # destination is always required
        if not destination:
            problems.append('destination is required for {}'.format(asset))

        if util.enabled('options_require_memo'):
            results = cursor.execute('SELECT options FROM addresses WHERE address=?', (destination,))
            if results:
                result = results.fetchone()
                if result and result['options'] & config.ADDRESS_OPTION_REQUIRE_MEMO and (sendMemo is None):
                    problems.append('destination {} requires memo'.format(destination))

    cursor.close()

    return problems

def compose (db, source, asset_dest_quant_list, memo, memo_is_hex):
    cursor = db.cursor()

    out_balances = util.accumulate([(t[0], t[2]) for t in asset_dest_quant_list])
    for (asset, quantity) in out_balances:
        if not isinstance(quantity, int):
            raise exceptions.ComposeError('quantities must be an int (in satoshis) for {}'.format(asset))

        balances = list(cursor.execute('''SELECT * FROM balances WHERE (address = ? AND asset = ?)''', (source, asset)))
        if not balances or balances[0]['quantity'] < quantity:
            raise exceptions.ComposeError('insufficient funds for {}'.format(asset))

    block_index = util.CURRENT_BLOCK_INDEX

    cursor.close()

    problems = validate(db, source, asset_dest_quant_list, block_index)
    if problems: raise exceptions.ComposeError(problems)

    data = message_type.pack(ID)
    data += _encode_mpmaSend(db, asset_dest_quant_list, block_index, memo=memo, memo_is_hex=memo_is_hex)

    return (source, [], data)

def parse (db, tx, message):
    try:
        unpacked = unpack(db, message, tx['block_index'])
        status = 'valid'
    except (struct.error) as e:
        status = 'invalid: truncated message'
    except (exceptions.AssetNameError, exceptions.AssetIDError) as e:
        status = 'invalid: invalid asset name/id'
    except (Exception) as e:
        status = 'invalid: couldn\'t unpack; %s' % e

    cursor = db.cursor()

    plain_sends = []
    all_debits = []
    all_credits = []
    if status == 'valid':
        for asset_id in unpacked:
            try:
                asset = util.get_asset_name(db, asset_id, tx['block_index'])
            except (exceptions.AssetNameError) as e:
                status = 'invalid: asset %s invalid at block index %i' % (asset_id, tx['block_index'])
                break

            cursor.execute('''SELECT * FROM balances \
                              WHERE (address = ? AND asset = ?)''', (tx['source'], asset_id))

            balances = cursor.fetchall()
            if not balances:
                status = 'invalid: insufficient funds for asset %s, address %s has no balance' % (asset_id, tx['source'])
                break

            credits = unpacked[asset_id]

            total_sent = reduce(lambda p, t: p + t[1], credits, 0)

            if balances[0]['quantity'] < total_sent:
                status = 'invalid: insufficient funds for asset %s, needs %i' % (asset_id, total_sent)
                break

            if status == 'valid':
                plain_sends += map(lambda t: util.py34TupleAppend(asset_id, t), credits)
                all_credits += map(lambda t: {"asset": asset_id, "destination": t[0], "quantity": t[1]}, credits)
                all_debits.append({"asset": asset_id, "quantity": total_sent})

    if status == 'valid':
        problems = validate(db, tx['source'], plain_sends, tx['block_index'])

        if problems: status = 'invalid:' + '; '.join(problems)

    if status == 'valid':
        for op in all_credits:
            util.credit(db, op['destination'], op['asset'], op['quantity'], action='send', event=tx['tx_hash'])

        for op in all_debits:
            util.debit(db, tx['source'], op['asset'], op['quantity'], action='send', event=tx['tx_hash'])

        # Enumeration of the plain sends needs to be deterministic, so we sort them by asset and then by address
        plain_sends = sorted(plain_sends, key=lambda x: ''.join([x[0], x[1]]))
        for i, op in enumerate(plain_sends):
            if len(op) > 3:
                memo_bytes = op[3]
            else:
                memo_bytes = None

            bindings = {
                'tx_index': tx['tx_index'],
                'tx_hash': tx['tx_hash'],
                'block_index': tx['block_index'],
                'source': tx['source'],
                'asset': op[0],
                'destination': op[1],
                'quantity': op[2],
                'status': status,
                'memo': memo_bytes,
                'msg_index': i
            }

            sql = 'insert into sends (tx_index, tx_hash, block_index, source, destination, asset, quantity, status, memo, msg_index) values(:tx_index, :tx_hash, :block_index, :source, :destination, :asset, :quantity, :status, :memo, :msg_index)'
            cursor.execute(sql, bindings)

    if status != 'valid':
        logger.warn("Not storing [mpma] tx [%s]: %s" % (tx['tx_hash'], status))

    cursor.close()

# vim: tabstop=8 expandtab shiftwidth=4 softtabstop=4
