#! /usr/bin/python3

"""Based on pyethereum <https://github.com/ethereum/pyethereum>."""

from counterpartylib.lib import util
from counterpartylib.lib.messages.scriptlib import rlp

import hashlib, binascii

sha3 = lambda x: sha3_256(x).digest()

def bytearray_to_int(arr):
    o = 0
    for a in arr:
        o = o * 256 + a
    return o

def contract_sha3 (b):
    contract_id = hashlib.sha3_256(b).digest()[12:]
    contract_id = binascii.hexlify(contract_id).decode('ascii')
    return contract_id

def encode_int(v):
    # encodes an integer into serialization
    if not isinstance(v, int) or v < 0 or v >= 2 ** 256:
        raise Exception("Integer invalid or out of range")
    return rlp.int_to_big_endian(v)

def coerce_to_int(x):
    if isinstance(x, int):
        return x
    elif len(x) == 40:
        return rlp.big_endian_to_int(binascii.unhexlify(x))
    else:
        if type(x) != bytes:
            x = bytes(x, 'ascii')   # For addresses.
        return rlp.big_endian_to_int(x)

def zpad(x, l):
    return b'\x00' * max(0, l - len(x)) + x

def coerce_to_hex(x):
    if isinstance(x, int):
        return util.hexlify(zpad(rlp.int_to_big_endian(x), 20))
    elif len(x) == 40 or len(x) == 0:
        return x
    else:
        return util.hexlify(zpad(x, 20)[-20:])

def memprint(data):
    line = util.hexlify(bytes(data))
    line = ' '.join([line[i:i+2] for i in range(0, len(line), 2)])
    return line

def hexprint(x):
    assert type(x) in (bytes, list)
    if not x:
        return '<None>'
    if x != -1:
        return ('0x' + util.hexlify(bytes(x)))
    else:
        return 'OUT OF GAS'

# vim: tabstop=8 expandtab shiftwidth=4 softtabstop=4
