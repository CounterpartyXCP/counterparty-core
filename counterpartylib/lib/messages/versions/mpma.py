#! /usr/bin/python3

import struct
import json
import logging
import binascii
import math
import itertools
import operator
from bitcoin import base58
from bitcoin.core import key
from functools import reduce

from bitstring import BitArray, BitStream, ConstBitStream, ReadError

logger = logging.getLogger(__name__)

from counterpartylib.lib import (config, util, exceptions, util, message_type, address)

ID = 3 # 0x03 is this specific message type

## address manipulation functions

def _addrToBytes(addr):
    return base58.decode(addr)[:-4]

def _addressFrom21Bytes(b):
    sha256_1 = key.hashlib.new('sha256')
    sha256_1.update(b)

    sha256_2 = key.hashlib.new('sha256')
    sha256_2.update(sha256_1.digest())

    chk = sha256_2.digest()[:4]

    return base58.encode(b''.join([b, chk]))

## encoding functions

def _encode_constructBaseLUT(snds):
    # t is a tuple of the form (asset, addr, amnt, memo, is_hex)
    return sorted(list(set([t[1] for t in snds]))) # Sorted to make list determinist

def _encode_constructBaseAssets(snds):
    # t is a tuple of the form (asset, addr, amnt [, memo, is_hex])
    return sorted(list(set([t[0] for t in snds]))) # Sorted to make list determinist

def _encode_constructLUT(snds):
    baseLUT = _encode_constructBaseLUT(snds)
    lutNbits = math.ceil(math.log2(len(baseLUT)))
    return {
        "nbits": lutNbits,
        "addrs": baseLUT
    }

def _encode_compressLUT(lut):
    return b''.join([struct.pack('>H', len(lut['addrs']))] +
        [
            _addrToBytes(addr)
            for addr in lut['addrs']
        ])

def _encode_memo(memo=None, is_hex=False):
    if memo is not None:
        barr = BitArray('0b1')

        if is_hex:
            barr.append('0b1')
            if type(memo) is str: # append the string as hex-string
                barr.append('uint:6=%i' % (len(memo) >> 1))
                memo = '0x%s' % memo
            else:
                barr.append('uint:6=%i' % len(memo))

            barr.append(memo)
        else:
            barr.append('0b0')
            barr.append('uint:6=%i' % len(memo))
            barr.append(BitArray(memo.encode('utf-8')))

        return barr
    else:
        return BitArray('0b0')

def _safe_tuple_index(t, i):
    if len(t) <= i:
        return None
    else:
        return t[i]

def _encode_constructSendList(send_asset, lut, sends):
    # t is a tuple of the form (asset, addr, amnt, memo, is_hex)
    return [
        (lut['addrs'].index(t[1]), t[2], _safe_tuple_index(t, 3), _safe_tuple_index(t, 4))
        for t in sends
        if t[0] == send_asset
    ]

def _solve_asset(db, assetName, block_index):
    asset = util.resolve_subasset_longname(db, assetName)
    return util.get_asset_id(db, asset, block_index)

def _encode_compressSendList(db, nbits, send, block_index):
    r = BitArray()
    r.append('uintbe:64=%i' % _solve_asset(db, send['assetName'], block_index))
    r.append('uint:%i=%i' % (nbits, len(send['sendList'])-1))
    for sendItem in send['sendList']:
        idx = sendItem[0]
        amnt = sendItem[1]
        r.append('uint:%i=%i' % (nbits, idx))
        r.append('uintbe:64=%i' % amnt)

        try:
            memoStr = _encode_memo(memo=sendItem[2], is_hex=sendItem[3])
        except:
            memoStr = BitArray('0b0')

        r.append(memoStr)
    return r

def _encode_constructSends(sends):
    lut = _encode_constructLUT(sends)
    assets = _encode_constructBaseAssets(sends)

    sendLists = [
        {
            "assetName": asset,
            "sendList": _encode_constructSendList(asset, lut, sends)
        }
        for asset in assets
    ]

    return {
        "lut": lut,
        "sendLists": sendLists
    }

def _encode_compressSends(db, mpmaSend, block_index, memo=None, memo_is_hex=False):
    compressedLUT = _encode_compressLUT(mpmaSend['lut'])
    memo_arr = _encode_memo(memo, memo_is_hex).bin

    isends = '0b' + memo_arr + ''.join([
        ''.join(['1', _encode_compressSendList(db, mpmaSend['lut']['nbits'], sendList, block_index).bin])
        for sendList in mpmaSend['sendLists']
    ])
    bstr = ''.join([isends, '0'])
    pad = '0' * ((8 - (len(bstr) - 2)) % 8) # That -2 is because the prefix 0b is there
    barr = BitArray(bstr + pad)
    return b''.join([
        compressedLUT,
        barr.bytes
    ])

def _encode_mpmaSend(db, sends, block_index, memo=None, memo_is_hex=False):
    mpma = _encode_constructSends(sends)
    send = _encode_compressSends(db, mpma, block_index, memo=memo, memo_is_hex=memo_is_hex)

    return send

## decoding functions

def _decode_decodeLUT(data):
    (numAddresses,) = struct.unpack('>H', data[0:2])
    if numAddresses == 0:
        raise exceptions.DecodeError('address list can\'t be empty')
    p = 2
    addressList = []
    bytesPerAddress = 21

    for i in range(0, numAddresses):
        addr_raw = data[p:p+bytesPerAddress]

        addressList.append(_addressFrom21Bytes(addr_raw))
        p += bytesPerAddress

    lutNbits = math.ceil(math.log2(numAddresses))

    return addressList, lutNbits, data[p:]

def _decode_decodeSendList(stream, nbits, lut, block_index):
    asset_id = stream.read('uintbe:64')
    numRecipients = stream.read('uint:%i' % nbits)
    sendList = []
    asset = util.generate_asset_name(asset_id, block_index)
    for i in range(0, numRecipients + 1):
        idx = stream.read('uint:%i' % nbits)
        addr = lut[idx]
        amount = stream.read('uintbe:64')

        memo, is_hex = _decode_memo(stream)
        if memo is not None:
            sendList.append((addr, amount, memo, is_hex))
        else:
            sendList.append((addr, amount))


    return asset, sendList

def _decode_decodeSends(stream, nbits, lut, block_index):
    #stream = ConstBitStream(data)
    sends = {}

    while stream.read('bool'):
        asset, sendList = _decode_decodeSendList(stream, nbits, lut, block_index)
        sends[asset] = sendList

    return sends

def _decode_memo(stream):
    if stream.read('bool'):
        is_hex = stream.read('bool')
        mlen = stream.read('uint:6')
        data = stream.read('bytes:%i' % mlen)

        if not(is_hex):
            # is an utf8 string
            data = data.decode('utf-8')

        return data, is_hex
    else:
        return None, None

def _decode_mpmaSendDecode(data, block_index):
    lut, nbits, remain = _decode_decodeLUT(data)
    stream = ConstBitStream(remain)
    memo, is_hex = _decode_memo(stream)
    sends = _decode_decodeSends(stream, nbits, lut, block_index)
    if memo is not None:
        for asset in sends:
            sendList = sends[asset]
            for idx, send in enumerate(sendList):
                if len(send) == 2:
                    sendList[idx] = (send[0], send[1], memo, is_hex)

    return sends

## misc funcs

def _accumulate(l):
    it = itertools.groupby(l, operator.itemgetter(0))
    for key, subiter in it:
       yield key, sum(item[1] for item in subiter)

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
        grpd = itertools.groupby([(t[0], t[1]) for t in asset_dest_quant_list])
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

    out_balances = _accumulate([(t[0], t[2]) for t in asset_dest_quant_list])
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
                plain_sends += map(lambda t: (asset, t[0], t[1]), credits)
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

        for i, op in enumerate(plain_sends):
            bindings = {
                'tx_index': tx['tx_index'] + i,
                'tx_hash': tx['tx_hash'],
                'block_index': tx['block_index'],
                'source': tx['source'],
                'asset': op[0],
                'destination': op[1],
                'quantity': op[2],
                'status': status,
                'msg_index': i
            }

            sql = 'insert into sends values(:tx_index, :tx_hash, :block_index, :source, :destination, :asset, :quantity, :status, :msg_index)'
            print(bindings)
            cursor.execute(sql, bindings)

    if status != 'valid':
        logger.warn("Not storing [mpma] tx [%s]: %s" % (tx['tx_hash'], status))

    cursor.close()

# vim: tabstop=8 expandtab shiftwidth=4 softtabstop=4
