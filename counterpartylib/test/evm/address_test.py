import pytest
import sys, os, time, tempfile
import binascii

from counterpartylib.lib import (config, util, database, script)
from counterpartylib import server
from counterpartylib.test import util_test
from counterpartylib.test.util_test import CURR_DIR
from counterpartylib.lib.evm import address, ethutils
from counterpartylib.lib.evm.address import Address


def setup_module():
    """Initialise the database with default data and wait for server to be ready."""
    server.initialise(
        database_file=tempfile.gettempdir() + '/fixtures.unittest.db',
        testnet=True,
        verbose=True,
        console_logfilter=os.environ.get('COUNTERPARTY_LOGGING', None),
        **util_test.COUNTERPARTYD_OPTIONS)
    util_test.restore_database(config.DATABASE, CURR_DIR + '/fixtures/scenarios/unittest_fixture.sql')
    db = database.get_connection(read_only=False)  # reinit the DB to deal with the restoring
    util.FIRST_MULTISIG_BLOCK_TESTNET = 1


def teardown_module(function):
    """Delete the temporary database."""
    util_test.remove_database_files(config.DATABASE)


def test_hash160():
    assert address.hash160(b"test") == b'\xce\xba\xa9\x8c\x19\x80q4CM\x10{\r>V\x92\xa5\x16\xeaf'


@pytest.fixture(scope='function')
def enable_cast_ethereum_addresses(request):
    """fixture to enable CAST_ETHEREUM_ADDRESSES and disable once done"""

    _CAST_ETHEREUM_ADDRESSES = address.CAST_ETHEREUM_ADDRESSES
    def reset_cast():
        address.CAST_ETHEREUM_ADDRESSES = _CAST_ETHEREUM_ADDRESSES
    address.CAST_ETHEREUM_ADDRESSES = True
    request.addfinalizer(reset_cast)


@pytest.mark.usefixtures('enable_cast_ethereum_addresses')
def test_min_int():
    a = Address(Address.normalizedata(b''), version=config.ADDRESSVERSION)
    a.version = b'\x01'

    assert a.int() == address.MININT

    # this is a ethereum literal from a test fixture
    assert 846782024548323446991784721256445173708587954613 < address.MININT
    a = Address.normalize(846782024548323446991784721256445173708587954613)
    assert a.base58() == "tjnUVZs4fSCixabHsYHa4Y3sLoCMbSvBgZ"


@pytest.mark.usefixtures('enable_cast_ethereum_addresses')
def test_max_int():
    a = Address(Address.normalizedata(b'\xff' * 20), version=config.ADDRESSVERSION)
    a.version = b'\xff'

    assert a.int() == address.MAXINT

    # this is a ethereum literal from a test fixture
    assert 115368164193494502992677104281492663667545801232522388744852668218526191640046 > address.MININT
    a = Address.normalize(115368164193494502992677104281492663667545801232522388744852668218526191640046)
    assert a.base58() == "toPCpBAKk7FsYMDi143PYqV1Wk6shh1sZ7"


@pytest.mark.usefixtures('enable_cast_ethereum_addresses')
def test_ruben():
    # invalid prefix bytes should be stripped off
    h = "aa800f572e5295c57f15886f9b263e2f6d2d6c7b5ec6"
    r = "800f572e5295c57f15886f9b263e2f6d2d6c7b5ec6"
    b = ethutils.decode_hex(h)
    i = ethutils.big_endian_to_int(b)

    a = Address.normalize(i)
    assert a.hexstr() == r

    # invalid suffix bytes should be stripped off
    h = "800f572e5295c57f15886f9b263e2f6d2d6c7b5ec6aa"
    r = "80572e5295c57f15886f9b263e2f6d2d6c7b5ec6aa"
    b = ethutils.decode_hex(h)
    i = ethutils.big_endian_to_int(b)

    a = Address.normalize(i)
    assert a.hexstr() == r


def test_checksum_mismatch():
    with pytest.raises(script.Base58ChecksumError):
        address.Address.frombase58('mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zd')


def test_equals():
    assert address.Address.normalize("mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc") == address.Address.normalize("mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc")
    assert address.Address.normalize("mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc") != address.Address.normalize("tXsNynQTeMkCQVBKMVnHwov1rTjpUYdVSt")
    assert address.Address.normalize("mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc") == "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc"
    assert address.Address.normalize("mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc") != "tXsNynQTeMkCQVBKMVnHwov1rTjpUYdVSt"
    assert address.Address.normalize("mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc") != "testme"
    assert address.Address.normalize("mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc") != None


def test_hash():
    a = address.Address.normalize("mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc")

    assert hash(a) == a.int() % address.HASHSIZE ** 8


def test_unique_set():
    a1 = address.Address.normalize("mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc")
    a2 = address.Address.normalize("tXsNynQTeMkCQVBKMVnHwov1rTjpUYdVSt")

    # cast list to set to make it unique
    s = set([a1, a1, a2, a2])

    assert len(s) == 2
    assert a1 in s
    assert a2 in s


def test_mk_contract_address():
    assert address.mk_contract_address(
        "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc",
        ethutils.encode_int(0),
        config.CONTRACT_ADDRESSVERSION).base58() == "tXsNynQTeMkCQVBKMVnHwov1rTjpUYdVSt"


def test_contract_address():
    a = Address.normalize('tXsNynQTeMkCQVBKMVnHwov1rTjpUYdVSt')
    assert a and isinstance(a, Address)

    assert a.hexstr() == '80119efcb773cf3768d04bdf797f7c3605808dce0a'


def test_p2sh_address():
    a = Address.normalize('2MyJHMUenMWonC35Yi6PHC7i2tkS7PuomCy')
    assert a and isinstance(a, Address)
    assert a.hexstr() == 'c44264cfd7eb65f8cbbdba98bd9815d5461fad8d7e'
    assert a.base58() == '2MyJHMUenMWonC35Yi6PHC7i2tkS7PuomCy'

    a = Address.normalize('c44264cfd7eb65f8cbbdba98bd9815d5461fad8d7e')
    assert a and isinstance(a, Address)
    assert a.base58() == '2MyJHMUenMWonC35Yi6PHC7i2tkS7PuomCy'

    a = Address.normalize(286833362487967993248380377968014724401410610138494)
    assert a and isinstance(a, Address)
    assert a.base58() == '2MyJHMUenMWonC35Yi6PHC7i2tkS7PuomCy'

    a = Address.normalize(b'\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\xc4Bd\xcf\xd7\xebe\xf8\xcb\xbd\xba\x98\xbd\x98\x15\xd5F\x1f\xad\x8d~')
    assert a and isinstance(a, Address)
    assert a.base58() == '2MyJHMUenMWonC35Yi6PHC7i2tkS7PuomCy'


def test_another_address():
    a = Address.normalize('000000000000000000000080119efcb773cf3768d04bdf797f7c3605808dce0a')
    assert a and isinstance(a, Address)

    assert a.hexstr() == '80119efcb773cf3768d04bdf797f7c3605808dce0a'


def test_address_from_base58():
    a = Address.frombase58('mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc')
    assert a and isinstance(a, Address)
    address_asserts(a)

    a = Address.frombase58(b'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc')
    assert a and isinstance(a, Address)
    address_asserts(a)


def test_address_from_hex():
    a = Address.fromhex('6f4838d8b3588c4c7ba7c1d06f866e9b3739c63037')
    assert a and isinstance(a, Address)
    address_asserts(a)

    a = Address.fromhex(b'6f4838d8b3588c4c7ba7c1d06f866e9b3739c63037')
    assert a and isinstance(a, Address)
    address_asserts(a)


def test_address_from_bytes():
    a = Address.frombytes(binascii.unhexlify('6f4838d8b3588c4c7ba7c1d06f866e9b3739c63037'))
    assert a and isinstance(a, Address)
    address_asserts(a)


def test_address_normalize_from_base58():
    a = Address.normalize('mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc')
    assert a and isinstance(a, Address)
    address_asserts(a)


def test_address_normalize_from_hexstr():
    a = Address.normalize('6f4838d8b3588c4c7ba7c1d06f866e9b3739c63037')
    assert a and isinstance(a, Address)
    address_asserts(a)


def test_address_normalize_from_hexbytes():
    a = Address.normalize(b'6f4838d8b3588c4c7ba7c1d06f866e9b3739c63037')
    assert a and isinstance(a, Address)
    address_asserts(a)


def test_address_normalize_from_bytes():
    a = Address.normalize(b'oH8\xd8\xb3X\x8cL{\xa7\xc1\xd0o\x86n\x9b79\xc607')
    assert a and isinstance(a, Address)
    address_asserts(a)


def test_address_normalize_from_bytes32():
    a = Address.normalize(b'\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00oH8\xd8\xb3X\x8cL{\xa7\xc1\xd0o\x86n\x9b79\xc607')
    assert a and isinstance(a, Address)
    address_asserts(a)


def test_address_normalize_from_int():
    a = Address.normalize(162638996798242663556760369064736334530946110206007)
    assert a and isinstance(a, Address)
    address_asserts(a)


def test_address_normalize_from_int_special():
    a = Address.normalize(1)
    assert a and isinstance(a, Address)
    a = Address.normalize(2)
    assert a and isinstance(a, Address)
    a = Address.normalize(3)
    assert a and isinstance(a, Address)
    a = Address.normalize(4)
    assert a and isinstance(a, Address)


def test_address_normalize_from_self():
    a1 = Address.normalize('mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc')
    a2 = Address.normalize(a1)
    assert id(a1) != id(a2)
    assert a2 and isinstance(a2, Address)
    address_asserts(a2)


def test_address_normalize_invalid():
    with pytest.raises(address.AddressNormalizeError):
        Address.normalize('test')

    with pytest.raises(address.AddressNormalizeError):
        Address.normalize('Qn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc')

    with pytest.raises(address.AddressNormalizeError):
        Address.normalize(["6f", "48", "38", "d8", "b3", "58", "8c", "4c", "7b", "a7", "c1", "d0", "6f", "86", "6e", "9b", "37", "39", "c6", "30", "37"])


def test_null_address():
    a = Address.nulladdress()
    assert a.version == b'\x80'
    assert a.data == b'\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00'
    assert a.base58() == 'tWGD2u9st6K9gUr68hdo53qhZZyk3JoQAF'
    assert a.bytes() == b'\x80\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00'


def test_normalize_data():
    a = Address(data=Address.normalizedata(1), version=config.CONTRACT_ADDRESSVERSION)
    assert a.version == b'\x80'
    assert a.data == b'\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x01'
    assert a.base58() == 'tWGD2u9st6K9gUr68hdo53qhZZykAQECqf'
    assert a.bytes() == b'\x80\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x01'

    a = Address(data=Address.normalizedata(b'\x00\x00\x01'), version=config.CONTRACT_ADDRESSVERSION)
    assert a.version == b'\x80'
    assert a.data == b'\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x01'
    assert a.base58() == 'tWGD2u9st6K9gUr68hdo53qhZZykAQECqf'
    assert a.bytes() == b'\x80\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x01'

    with pytest.raises(NotImplementedError):
        Address.normalizedata("01")
    with pytest.raises(NotImplementedError):
        Address.normalizedata([1])


def test_normalize_none():
    assert Address.normalize(None) is None
    assert Address.normalize(b'') is None
    assert Address.normalize('') is None


def address_asserts(a):
    assert a.version == b'\x6f'
    assert a.data == b'H8\xd8\xb3X\x8cL{\xa7\xc1\xd0o\x86n\x9b79\xc607'

    assert a.datahexbytes() == b'4838d8b3588c4c7ba7c1d06f866e9b3739c63037'
    assert a.datahexstr() == '4838d8b3588c4c7ba7c1d06f866e9b3739c63037'
    assert a.base58() == 'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc'
    assert a.hexbytes() == b'6f4838d8b3588c4c7ba7c1d06f866e9b3739c63037'
    assert a.hexstr() == '6f4838d8b3588c4c7ba7c1d06f866e9b3739c63037'
    assert a.bytes() == b'oH8\xd8\xb3X\x8cL{\xa7\xc1\xd0o\x86n\x9b79\xc607'
    assert a.bytes32() == b'\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00oH8\xd8\xb3X\x8cL{\xa7\xc1\xd0o\x86n\x9b79\xc607'
    assert a.int() == 162638996798242663556760369064736334530946110206007
    assert repr(a) == "<Address mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc {'data': b'4838d8b3588c4c7ba7c1d06f866e9b3739c63037', 'version': b'6f'}>"
    assert str(a) == 'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc'
