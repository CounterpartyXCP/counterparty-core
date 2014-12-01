#! /usr/bin/python3

"""Based on pyethereum <https://github.com/ethereum/pyethereum>."""

import math
import binascii

'''
First byte of an encoded item

    x: single byte, itself
    |
    |
0x7f == 127

0x80 == 128
    |
    x: [0, 55] byte long string, x-0x80 == length
    |
0xb7 == 183

0xb8 == 184
    |
    x: [56, ] long string, x-0xf7 == length of the length
    |
0xbf == 191

0xc0 == 192
    |
    x: [0, 55] byte long list, x-0xc0 == length
    |
0xf7 == 247

0xf8 == 248
    |
    x: [56, ] long list, x-0xf7 == length of the length
    |
0xff == 255
'''

def decode_datalist(arr):
    if isinstance(arr, list):
        arr = ''.join(map(chr, arr))
    o = []
    for i in range(0, len(arr), 32):
        o.append(big_endian_to_int(arr[i:i + 32]))
    return o


def int_to_big_endian(integer):
    '''convert a integer to big endian binary string'''
    # 0 is a special case, treated same as ''
    if integer == 0:
        return b''
    """
    NOTE
    s = '%x' % integer
    if len(s) & 1:
        s = '0' + s
    return binascii.unhexlify(s).decode('ascii')
    """
    byte_length = math.ceil(integer.bit_length() / 8)
    return (integer).to_bytes(byte_length, byteorder='big')


def big_endian_to_int(string):
    '''convert a big endian binary string to integer'''
    # '' is a special case, treated same as 0
    string = string or b'\x00'
    s = binascii.hexlify(string)
    return int(s, 16)


def encode(input):
    if isinstance(input,bytes):
        if len(input) == 1 and ord(input) < 128: return input
        else: return encode_length(len(input),128) + input
    elif isinstance(input,list):
        output = b''
        for item in input:
            output += encode(item)
        return encode_length(len(output),192) + output

def encode_length(L,offset):
    if L < 56:
        return (L + offset).to_bytes(1, byteorder='big')
    elif L < 256**8:
        BL = to_binary(L)
        return (len(BL) + offset + 55).to_bytes(1, byteorder='big') + BL
    else:
        raise Exception("input too long")

def to_binary(x):
    return b'' if x == 0 else to_binary(x // 256) + (x % 256).to_bytes(1, byteorder='big')
