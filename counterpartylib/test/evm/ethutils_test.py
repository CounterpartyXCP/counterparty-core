import pprint

import pytest
import binascii
import os
import sys
import logging
import serpent
from counterpartylib.test import conftest  # this is require near the top to do setup of the test suite
from counterpartylib.test.util_test import CURR_DIR

from counterpartylib.lib import (config, database)
from counterpartylib.lib.evm import (blocks, processblock, ethutils, abi, address, vm, exceptions as ethexceptions)

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

    # cleanup files marked for cleanup
    for file in CLEANUP_FILES:
        if os.path.isfile(file):
            os.remove(file)


def test_big_endian_to_int():
    assert ethutils.big_endian_to_int(binascii.unhexlify(b'084fed08b978af4d7d196a7446a86b58009e636b611db16211b65a9aadff29c5')) == 0x084fed08b978af4d7d196a7446a86b58009e636b611db16211b65a9aadff29c5
