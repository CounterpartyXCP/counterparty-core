import pytest
import binascii
import os
import sys
import logging
import serpent
from counterpartylib.test import conftest  # this is require near the top to do setup of the test suite
from counterpartylib.test.util_test import CURR_DIR

from counterpartylib.lib import (config, database)
from counterpartylib.lib.evm import (blocks, processblock, ethutils, abi, address)

from counterpartylib.test.evm import contracts_tester as tester
from counterpartylib.test import util_test

# globals initialized by setup_function
db, cursor, logger = None, None, None
CLEANUP_FILES = []


def setup_module():
    """Initialise the database with unittest fixtures"""
    # global the DB/cursor for other functions to access
    global db, cursor, logger

    db = util_test.init_database(CURR_DIR + '/fixtures/scenarios/unittest_fixture.sql', 'fixtures.countracts_test.db')
    logger = logging.getLogger(__name__)
    db.setrollbackhook(lambda: logger.debug('ROLLBACK'))
    database.update_version(db)


def teardown_module():
    """Delete the temporary database."""
    util_test.remove_database_files(config.DATABASE)


def setup_function(function):
    global db, cursor

    # start transaction so we can rollback on teardown
    cursor = db.cursor()
    cursor.execute('''BEGIN''')


def teardown_function(function):
    global db, cursor
    cursor.execute('''ROLLBACK''')


def test_abi_translator2():
    addrbytes32 = b'\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x80\xe3\xc0\x90l\x8a\xc6\xc7"h;\x1f\xd5?Y\xd0\xed\xcdOX('
    assert abi.decode_single(('address', '', []), addrbytes32) == "ts2T738tztDcSsYJghraUq9iqfbHdgpbW8"


def test_abi_translator():
    addrbase58 = 'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc'
    addrhexbytes = b'6f4838d8b3588c4c7ba7c1d06f866e9b3739c63037'
    addrhexstr = '6f4838d8b3588c4c7ba7c1d06f866e9b3739c63037'
    addrbytes = binascii.unhexlify(addrhexbytes)
    addrbytespadded = ((b'\x00' * 32) + addrbytes)[-32:]

    assert abi.encode_single(('address', '', []), addrbase58) == addrbytespadded
    assert abi.encode_single(('address', '', []), addrhexstr) == addrbytespadded
    assert abi.encode_single(('address', '', []), addrhexbytes) == addrbytespadded
    assert abi.encode_single(('address', '', []), addrbytes) == addrbytespadded

    assert abi.decode_single(('address', '', []), addrbytes) == addrbase58
    assert abi.decode_single(('address', '', []), addrbytespadded) == addrbase58
