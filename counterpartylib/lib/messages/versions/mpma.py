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

from bitstring import BitArray, BitStream, ConstBitStream

logger = logging.getLogger(__name__)

from counterpartylib.lib import (config, util, exceptions, util, message_type, address)

ID = 3 # 0x03

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
    return sorted(list(set([addr for (asset, addr, amnt) in snds]))) # Sorted to make list determinist

def _encode_constructBaseAssets(snds):
    return sorted(list(set([asset for (asset, addr, amnt) in snds]))) # Sorted to make list determinist

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

def _encode_constructSendList(send_asset, lut, sends):
    return [
        (lut['addrs'].index(addr), amnt)
        for (asset, addr, amnt) in sends
        if asset == send_asset
    ]

def _solve_asset(db, assetName, block_index):
    asset = util.resolve_subasset_longname(db, assetName)
    return util.get_asset_id(db, asset, block_index)

def _encode_compressSendList(db, nbits, send, block_index):
    r = BitArray()
    r.append('uintbe:64=%i' % _solve_asset(db, send['assetName'], block_index))
    r.append('uint:%i=%i' % (nbits, len(send['sendList'])-1))
    for (idx, amnt) in send['sendList']:
        r.append('uint:%i=%i' % (nbits, idx))
        r.append('uintbe:64=%i' % amnt)
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

def _encode_compressSends(db, mpmaSend, block_index):
    compressedLUT = _encode_compressLUT(mpmaSend['lut'])
    isends = ''.join([
        ''.join(['0b1', _encode_compressSendList(db, mpmaSend['lut']['nbits'], sendList, block_index).bin])
        for sendList in mpmaSend['sendLists']
    ])
    bstr = ''.join([isends, '0'])
    pad = '0' * (8 - (len(bstr) - 2) % 8) # That -2 is because the prefix 0b is there
    barr = BitArray(bstr + pad)
    return b''.join([
        compressedLUT,
        barr.bytes
    ])

def _encode_mpmaSend(db, sends, block_index):
    mpma = _encode_constructSends(sends)
    send = _encode_compressSends(db, mpma, block_index)

    return send

## decoding functions

def _decode_decodeLUT(data):
    (numAddresses,) = struct.unpack('>H', data[0:2])
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

    #
    for i in range(0, numRecipients + 1):
        addr = lut[stream.read('uint:%i' % nbits)]
        amount = stream.read('uintbe:64')
        sendList.append((addr, amount))

    asset = util.generate_asset_name(asset_id, block_index)

    return asset, sendList

def _decode_decodeSends(data, nbits, lut, block_index):
    stream = ConstBitStream(data)
    sends = {}

    while stream.read('bool'):
        asset, sendList = _decode_decodeSendList(stream, nbits, lut, block_index)
        sends[asset] = sendList

    return sends

def _decode_mpmaSendDecode(data, block_index):
    lut, nbits, remain = _decode_decodeLUT(data)
    sends = _decode_decodeSends(remain, nbits, lut, block_index)

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

    return unpacked

def validate (db, source, asset_dest_quant_list, block_index):
    problems = []

    if len(asset_dest_quant_list) == 0:
        problems.append('send list cannot be empty')

    if len(asset_dest_quant_list) == 1:
        problems.append('send list cannot have only one element')

    if len(asset_dest_quant_list) > 0:
        grpd = itertools.groupby([(asset, destination) for (asset, destination, quantity) in asset_dest_quant_list])
        lengrps = [len(list(grpr)) for (group, grpr) in grpd]
        cardinality = max(lengrps)
        if cardinality > 1:
            problems.append('cannot specify more than once a destination per asset')

    cursor = db.cursor()

    for (asset, destination, quantity) in asset_dest_quant_list:
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
                if result and result['options'] & config.ADDRESS_OPTION_REQUIRE_MEMO:
                    problems.append('destination {} requires memo'.format(destination))

    cursor.close()

    return problems

def compose (db, source, asset_dest_quant_list):
    cursor = db.cursor()

    out_balances = _accumulate([(asset, quantity) for (asset, destination, quantity) in asset_dest_quant_list])
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
    data += _encode_mpmaSend(db, asset_dest_quant_list, block_index)

    return (source, [], data)

def parse (db, tx, message):
    cursor = db.cursor()

    cursor.close()

# vim: tabstop=8 expandtab shiftwidth=4 softtabstop=4
