import hashlib
import pprint
import logging

import binascii

from counterpartylib.lib import script, util, exceptions
from counterpartylib.lib.evm import ethutils, specials
from counterpartylib.lib import config

logger = logging.getLogger(__name__)

VERSION_BYTE_LENGTH = 1
DATA_LENGTH = 20
CHECKSUM_LENGTH = 4


class AddressNormalizeError(Exception):
    pass


class Address(object):
    CLSNAME = 'Address'

    def __init__(self, data, version):
        self.data = data
        self.version = version

        assert self.version in [config.ADDRESSVERSION, config.CONTRACT_ADDRESSVERSION]

    def bytes(self):
        return self.version + self.data

    def bytes32(self):
        return ((b'\x00' * 32) + self.version + self.data)[-32:]

    def base58(self):
        return script.base58_check_encode(self.data, self.version)

    def hexbytes(self):
        return binascii.hexlify(self.bytes())

    def hexstr(self):
        return self.hexbytes().decode('ascii')

    def int(self):
        i = ethutils.decode_hex(self.hexbytes())

        return ethutils.big_endian_to_int(i)

    def __eq__(self, other):
        try:
            other = Address.normalize(other)
            if not other:
                return False
        except Exception as e:
            return False

        return self.bytes32() == other.bytes32()

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
            addr = ethutils.int_to_big_endian(addr)

            # print(list(map(lambda s: (s, len(s)), specials.specials.keys())))
            # print(((b'\x00' * 32) + addr)[-20:])
            # print(((b'\x00' * 32) + addr)[-20:] in specials.specials)

            # check if zero-padded address is a special contract
            addrpaddded = ((b'\x00' * DATA_LENGTH) + addr)[-DATA_LENGTH:]
            if addrpaddded in specials.specials:
                return cls(addrpaddded, config.CONTRACT_ADDRESSVERSION)

            version, data = addr[0:1], addr[1:]

            return cls(data, version)

        raise AddressNormalizeError("Cound not normalize Address: %s(%d)" % (addr, len(addr)))

    @classmethod
    def fromhex(cls, addr):
        assert isinstance(addr, (bytes, str))

        if isinstance(addr, bytes):
            addr = addr.decode('utf-8')

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
            addr = addr.decode('utf-8')

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
