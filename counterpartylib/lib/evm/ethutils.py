try:
    from Crypto.Hash import keccak

    sha3_256 = lambda x: keccak.new(digest_bits=256, data=x).digest()
except:
    import sha3 as _sha3

    sha3_256 = lambda x: _sha3.sha3_256(x).digest()

import sys
import rlp
from rlp.sedes import big_endian_int, BigEndianInt, Binary
from rlp.utils import decode_hex, encode_hex, ascii_chr, str_to_bytes
import random
import math
import binascii
import yaml

from counterpartylib.lib import util, script

big_endian_to_int = lambda x: big_endian_int.deserialize(str_to_bytes(x).lstrip(b'\x00'))
int_to_big_endian = lambda x: big_endian_int.serialize(x)

TT256 = 2 ** 256
TT256M1 = 2 ** 256 - 1
TT255 = 2 ** 255


is_numeric = lambda x: isinstance(x, int)
# @TODO: is_string checks for bytes :/
is_string = lambda x: isinstance(x, bytes)


def json_decode(data):
    """
    load JSON using `yaml.safe_load` (which supports) JSON for better unicode support
    """
    return yaml.safe_load(data)


def to_string(value):
    if isinstance(value, bytes):
        return value
    if isinstance(value, str):
        return bytes(value, 'utf-8')
    if isinstance(value, int):
        return bytes(str(value), 'utf-8')


def int_to_bytes(value):
    if isinstance(value, bytes):
        return value
    return int_to_big_endian(value)


def to_string_for_regexp(value):
    return str(to_string(value), 'utf-8')


unicode = str
isnumeric = is_numeric


def safe_ord(value):
    if isinstance(value, int):
        return value
    else:
        return ord(value)


# decorator


def debug(label):
    def deb(f):
        def inner(*args, **kwargs):
            i = random.randrange(1000000)
            print(label, i, 'start', args)
            x = f(*args, **kwargs)
            print(label, i, 'end', x)
            return x

        return inner

    return deb


def bytearray_to_int(arr):
    o = 0
    for a in arr:
        o = (o << 8) + a
    return o


def sha3(seed):
    return sha3_256(to_string(seed))


def zpad(x, l):
    return b'\x00' * max(0, l - len(x)) + x


def int_to_addr(x):
    o = [''] * 20
    for i in range(20):
        o[19 - i] = ascii_chr(x & 0xff)
        x >>= 8
    return b''.join(o)


def coerce_addr_to_hex(x):
    if is_numeric(x):
        return encode_hex(zpad(big_endian_int.serialize(x), 20))
    elif len(x) == 40 or len(x) == 0:
        return x
    else:
        return encode_hex(zpad(x, 20)[-20:])


def coerce_to_int(x):
    if is_numeric(x):
        return x
    elif len(x) == 40:
        return big_endian_to_int(decode_hex(x))
    else:
        return big_endian_to_int(x)


def ceil32(x):
    return x if x % 32 == 0 else x + 32 - (x % 32)


def to_signed(i):
    return i if i < TT255 else i - TT256


def encode_int(v):
    '''encodes an integer into serialization'''
    if not is_numeric(v) or v < 0 or v >= TT256:
        raise Exception("Integer invalid or out of range: %r" % v)
    return int_to_big_endian(v)


class Denoms():
    def __init__(self):
        self.wei = 1
        self.babbage = 10 ** 3
        self.lovelace = 10 ** 6
        self.shannon = 10 ** 9
        self.szabo = 10 ** 12
        self.finney = 10 ** 15
        self.ether = 10 ** 18
        self.turing = 2 ** 256


denoms = Denoms()

address = Binary.fixed_length(20, allow_empty=True)
int20 = BigEndianInt(20)
int32 = BigEndianInt(32)
int256 = BigEndianInt(256)
hash32 = Binary.fixed_length(32)
trie_root = Binary.fixed_length(32, allow_empty=True)


def hexprint(x):
    assert type(x) in (bytes, list)
    if not x:
        return '<None>'
    if x != -1:
        return ('0x' + util.hexlify(bytes(x)))
    else:
        return 'OUT OF GAS'


def parse_int_or_hex(s):
    if is_numeric(s):
        return s
    elif s[:2] in (b'0x', '0x'):
        s = to_string(s)
        tail = (b'0' if len(s) % 2 else b'') + s[2:]
        return big_endian_to_int(decode_hex(tail))
    else:
        return int(s)


def encode_int_to_hex(s):
    return encode_hex(int_to_big_endian(s))


def encode_int_to_hexstr(s):
    return encode_int_to_hex(s).decode('ascii')


def encode_hexstr(s):
    return encode_hex(s).decode('ascii')
