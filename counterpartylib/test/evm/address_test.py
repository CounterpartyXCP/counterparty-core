#! /usr/bin/python3

import sys, os, time, tempfile
import binascii

from counterpartylib.lib import (config, util, database)
from counterpartylib import server
from counterpartylib.test import util_test
from counterpartylib.test.util_test import CURR_DIR
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


def test_contract_address():
    a = Address.normalize('tXsNynQTeMkCQVBKMVnHwov1rTjpUYdVSt')
    assert a and isinstance(a, Address)

    assert a.hexstr() == '80119efcb773cf3768d04bdf797f7c3605808dce0a'


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


def address_asserts(a):
    assert a.version == b'\x6f'
    assert a.data == b'H8\xd8\xb3X\x8cL{\xa7\xc1\xd0o\x86n\x9b79\xc607'

    assert a.base58() == 'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc'
    assert a.hexbytes() == b'6f4838d8b3588c4c7ba7c1d06f866e9b3739c63037'
    assert a.hexstr() == '6f4838d8b3588c4c7ba7c1d06f866e9b3739c63037'
    assert a.bytes() == b'oH8\xd8\xb3X\x8cL{\xa7\xc1\xd0o\x86n\x9b79\xc607'
    assert a.bytes32() == b'\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00oH8\xd8\xb3X\x8cL{\xa7\xc1\xd0o\x86n\x9b79\xc607'
