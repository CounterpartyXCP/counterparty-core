"""
@TODO: libraries
@TODO: compile_rich
"""
import hashlib
import pprint

import pytest
import binascii
import os
import sys
import logging
import serpent
from counterpartylib.test import conftest  # this is require near the top to do setup of the test suite
from counterpartylib.test.util_test import CURR_DIR

from counterpartylib.lib import (config, database, util)
from counterpartylib.lib.evm import (blocks, processblock, ethutils, abi, address, vm)

from counterpartylib.test.evm import contracts_tester as tester
from counterpartylib.test import util_test
from counterpartylib.lib.evm import solidity

_solidity = solidity.get_solidity()

# globals initialized by setup_function
db, cursor, logger = None, None, None
CLEANUP_FILES = []


def state():
    """"create a tester.state with latest block"""
    global db

    cursor = db.cursor()
    cursor.execute('''SELECT * FROM blocks ORDER BY block_index DESC LIMIT 1''')
    latest_block = list(cursor.fetchall())[0]
    cursor.close()

    return tester.state(db, latest_block['block_hash'])


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


def open_cleanonteardown(filename, *args, **kwargs):
    CLEANUP_FILES.append(filename)

    return open(filename, *args, **kwargs)


def test_contract_names():
    # test simple extracting names
    code = '''
contract test1 {}
contract test2 {}
'''
    assert solidity.solc_wrapper.contract_names(code) == [('contract', 'test1'), ('contract', 'test2')]

    # test with odd comment
    code = '''
contract test1
// odd comment here
/* more odd comments */
{}
'''
    assert solidity.solc_wrapper.contract_names(code) == [('contract', 'test1')]

    # test with contract in comment
    code = '''
contract test1 {}
//contract test2 {}
/*contract test3 {}*/
/*
contract test4 {}
*/
'''
    assert solidity.solc_wrapper.contract_names(code) == [('contract', 'test1')]

    # test with a var named 'subcontract'
    code = '''
contract test1 {
    _subcontract = new subcontract();
}
'''
    assert solidity.solc_wrapper.contract_names(code) == [('contract', 'test1')]

    # test with a contract named subcontract
    code = '''
contract subcontract {}
'''
    assert solidity.solc_wrapper.contract_names(code) == [('contract', 'subcontract')]

    # test with a library
    code = '''
contract test1 {}
library test2 {}
'''
    assert solidity.solc_wrapper.contract_names(code) == [('contract', 'test1'), ('library', 'test2')]


def test_compile_error():
    code = '''
notacontract test {

}
'''

    s = state()
    with pytest.raises(solidity.CompileError):
        s.abi_contract(code, language='solidity')
