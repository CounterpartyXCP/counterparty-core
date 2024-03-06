import struct
import json
import logging
import binascii
import math
from bitcoin.core import key
from functools import reduce
from itertools import groupby

from bitstring import BitArray, BitStream, ConstBitStream, ReadError

logger = logging.getLogger(__name__)

from counterpartylib.lib import (config, util, exceptions, util, ledger, address)

## encoding functions

def _encode_constructBaseLUT(snds):
    # t is a tuple of the form (asset, addr, amnt [, memo, is_hex])
    return sorted(list(set([t[1] for t in snds]))) # Sorted to make list determinist

def _encode_constructBaseAssets(sends):
    # t is a tuple of the form (asset, addr, amnt [, memo, is_hex])
    return sorted(list(set([t[0] for t in sends]))) # Sorted to make list determinist

def _encode_constructLUT(sends):
    baseLUT = _encode_constructBaseLUT(sends)

    # What's this? It calculates the minimal number of bits needed to represent an item index inside the baseLUT
    lutNbits = math.ceil(math.log2(len(baseLUT)))

    return {
        "nbits": lutNbits,
        "addrs": baseLUT
    }

def _encode_compressLUT(lut):
    return b''.join([struct.pack('>H', len(lut['addrs']))] +
        [
            address.pack(addr)
            for addr in lut['addrs']
        ])

def _encode_memo(memo=None, is_hex=False):
    '''Tightly pack a memo as a Bit array'''

    if memo is not None:
        # signal a 1 bit for existence of the memo
        barr = BitArray('0b1')

        if is_hex:
            # signal a 1 bit for hex encoded memos
            barr.append('0b1')
            if type(memo) is str: # append the string as hex-string
                barr.append('uint:6=%i' % (len(memo) >> 1))
                memo = f'0x{memo}'
            else:
                barr.append(f'uint:6={len(memo)}')

            barr.append(memo)
        else:
            # signal a 0 bit for a string encoded memo
            barr.append('0b0')
            barr.append(f'uint:6={len(memo)}')
            barr.append(BitArray(memo.encode('utf-8')))

        return barr
    else:
        # if the memo is None, return just a 0 bit
        return BitArray('0b0')

def _safe_tuple_index(t, i):
    '''Get an element from a tuple, returning None if it's out of bounds'''

    if len(t) <= i:
        return None
    else:
        return t[i]

def _encode_constructSendList(send_asset, lut, sends):
    # t is a tuple of the form (asset, addr, amnt, memo, is_hex)
    # if there's no memo specified, memo and is_hex are None
    return [
        (lut['addrs'].index(t[1]), t[2], _safe_tuple_index(t, 3), _safe_tuple_index(t, 4))
        for t in sends
        if t[0] == send_asset
    ]

def _solve_asset(db, assetName, block_index):
    asset = ledger.resolve_subasset_longname(db, assetName)
    return ledger.get_asset_id(db, asset, block_index)

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

        addressList.append(address.unpack(addr_raw))
        p += bytesPerAddress

    lutNbits = math.ceil(math.log2(numAddresses))

    return addressList, lutNbits, data[p:]

def _decode_decodeSendList(stream, nbits, lut, block_index):
    asset_id = stream.read('uintbe:64')

    if nbits > 0:
        numRecipients = stream.read('uint:%i' % nbits)
        rangeLimit = numRecipients + 1
    else:
        numRecipients = 1
        rangeLimit = numRecipients
    sendList = []
    asset = ledger.generate_asset_name(asset_id, block_index)
    for i in range(0, rangeLimit):
        if nbits > 0:
            idx = stream.read('uint:%i' % nbits)
        else:
            idx = 0
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
