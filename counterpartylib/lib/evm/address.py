import hashlib
import pprint
import logging
import sys

import binascii

from counterpartylib.lib import script, util, exceptions
from counterpartylib.lib.evm import ethutils, specials
from counterpartylib.lib import config

logger = logging.getLogger(__name__)

VERSION_BYTE_LENGTH = 1
DATA_LENGTH = 20
CHECKSUM_LENGTH = 4

# .int() for data=b'\x00'*20, version=b'\x01' -> b'\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00'
#  ethereum addresses will be < this
MININT = 1461501637330902918203684832716283019655932542976
assert MININT == 2 ** 160

# .int() for data=b'\xff'*20, version=b'\xff' -> b'\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff'
#  ethereum addresses will be > this
MAXINT = 374144419156711147060143317175368453031918731001855
assert MAXINT == 2 ** 168 - 1
CAST_ETHEREUM_ADDRESSES = False

# hashsize in bytes
HASHSIZE = int(sys.hash_info.width / 8)


class AddressNormalizeError(Exception):
    pass


def unique_address_list(l):
    keys = {}
    result = []
    for a in l:
        assert isinstance(a, Address)
        key = a.bytes32()

        if key not in keys:
            result.append(a)

    return result


def valid_version_bytes():
    return [config.ADDRESSVERSION, config.CONTRACT_ADDRESSVERSION]


class Address(object):
    CLSNAME = 'Address'

    def __init__(self, data, version):
        self.data = data
        self.version = version

        assert self.version in valid_version_bytes()

    def bytes(self):
        return self.version + self.data

    def bytes32(self):
        return ((b'\x00' * 32) + self.version + self.data)[-32:]

    def base58(self):
        return script.base58_check_encode(self.data, self.version)

    def hexbytes(self):
        return binascii.hexlify(self.bytes())

    def datahexbytes(self):
        return binascii.hexlify(self.data)

    def datahexstr(self):
        return self.datahexbytes().decode('ascii')

    def hexstr(self):
        return self.hexbytes().decode('ascii')

    def int(self):
        i = ethutils.decode_hex(self.hexbytes())

        return ethutils.big_endian_to_int(i)

    def __hash__(self):
        return self.int() % HASHSIZE ** 8

    def __eq__(self, other):
        try:
            other = Address.normalize(other)
            if not other:
                return False
        except Exception as e:
            return False

        return hash(self) == hash(other)

    def __repr__(self):
        return '<%s %s %s>' % (
            self.CLSNAME,
            self.base58(),
            pprint.pformat({
                'version': binascii.hexlify(self.version),
                'data': binascii.hexlify(self.data)
            })
        )

    def __str__(self):
        return self.base58()

    @classmethod
    def nulladdress(cls):
        return cls(b'\x00' * DATA_LENGTH, config.CONTRACT_ADDRESSVERSION)

    @classmethod
    def normalizedata(cls, data):
        if isinstance(data, str):
            raise NotImplementedError

        elif isinstance(data, int):
            data = ethutils.int_to_big_endian(data)

        elif not isinstance(data, bytes):
            raise NotImplementedError

        # add padding
        data = ((b'\x00' * DATA_LENGTH) + data)[-DATA_LENGTH:]

        return data

    @classmethod
    def normalize(cls, addr):
        if addr is None or addr == '' or addr == b'':
            return None

        if isinstance(addr, Address):
            return cls(addr.data, addr.version)

        elif isinstance(addr, (str, bytes)):
            try:
                return cls.frombytes(addr)
            except: pass

            try:
                return cls.fromhex(addr)
            except: pass

            try:
                return cls.frombase58(addr)
            except:
                pass

        elif isinstance(addr, int):
            addrb = ethutils.int_to_big_endian(addr)

            # check if zero-padded address is a special contract
            addrpaddded = ((b'\x00' * DATA_LENGTH) + addrb)[-DATA_LENGTH:]
            if addrpaddded in specials.specials:
                return cls(addrpaddded, config.CONTRACT_ADDRESSVERSION)

            # if below the MININT it's a literal ethereum address, cast it
            #  this is only for compatibility with pyeth test fixtures
            if addr <= MININT:
                if CAST_ETHEREUM_ADDRESSES:
                    return cls(data=cls.normalizedata(addr), version=config.CONTRACT_ADDRESSVERSION)
                else:
                    raise AddressNormalizeError("Can't normalize int(%d), is below MININT" % (addr, ))

            # if above the MAXINT it's a literal ethereum address, cast it
            #  this is only for compatibility with pyeth test fixtures
            if addr >= MAXINT:
                if CAST_ETHEREUM_ADDRESSES:
                    # strip off prefix bytes that aren't valid version bytes
                    while len(addrb) and addrb[0:1] not in valid_version_bytes():
                        addrb = addrb[1:]

                    if not len(addrb):
                        return cls.normalize(addr % 2 ** 160)

                    # split the version byte off
                    version = addrb[0:1]
                    addrb = addrb[1:]

                    # strip off an remaining trailing bytes
                    addrb = addrb[-DATA_LENGTH:]

                    return cls(data=addrb, version=version)
                else:
                    raise AddressNormalizeError("Can't normalize int(%d), is above MAXINT" % (addr, ))

            version, data = addrb[0:1], addrb[1:]

            return cls(data, version)

        raise AddressNormalizeError("Cound not normalize Address: %s(%d)" % (addr, len(addr)))

    @classmethod
    def fromhex(cls, addr):
        assert isinstance(addr, (bytes, str))

        if isinstance(addr, bytes):
            addr = addr.decode('ascii')

        assert len(addr) == (VERSION_BYTE_LENGTH + DATA_LENGTH) * 2 or len(addr) == 32 * 2

        return cls.frombytes(binascii.unhexlify(addr))

    @classmethod
    def frombytes(cls, addr):
        assert isinstance(addr, bytes)

        if len(addr) == 32:
            addr = addr[-(VERSION_BYTE_LENGTH + DATA_LENGTH):]

        assert len(addr) == VERSION_BYTE_LENGTH + DATA_LENGTH

        addrbyte, data = addr[0:1], addr[1:]
        return cls(data, addrbyte)

    @classmethod
    def frombase58(cls, addr):
        assert isinstance(addr, (bytes, str))

        if isinstance(addr, bytes):
            addr = addr.decode('ascii')

        addrbyte, data, chk0 = script.base58_check_decode_parts(addr)

        assert len(addrbyte) == VERSION_BYTE_LENGTH
        assert len(data) == DATA_LENGTH
        assert len(chk0) == CHECKSUM_LENGTH

        chk1 = util.dhash(addrbyte + data)[:4]
        if chk0 != chk1:
            raise script.Base58ChecksumError('Checksum mismatch: 0x{} ≠ 0x{}'.format(util.hexlify(chk0), util.hexlify(chk1)))

        return cls(data, addrbyte)


def hash160(msg):
    """RIPEME160(SHA256(msg)) -> bytes"""
    h = hashlib.new('ripemd160')
    h.update(hashlib.sha256(msg).digest())
    return h.digest()


def mk_contract_address(addr, nonce, version):
    addr = Address.normalize(addr)
    data = hash160(addr.data + nonce)

    return Address(data, version)
