"""
@TODO: libraries
@TODO: compile_rich
"""
import hashlib
import pprint
import copy
import pytest
import binascii
import os
import sys
import logging
import serpent
from counterpartylib.test import conftest  # this is require near the top to do setup of the test suite
from counterpartylib.test.util_test import CURR_DIR

from counterpartylib.lib import (config, database, util)
from counterpartylib.lib.evm import (blocks, processblock, ethutils, abi, address, vm, specials, opcodes)

from counterpartylib.test.evm import contracts_tester as tester
from counterpartylib.test import util_test
from counterpartylib.lib.evm.solidity import get_solidity
from counterpartylib.test.evm import pyethtestutils

solidity = get_solidity()

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

_CAST_ETHEREUM_ADDRESSES = address.CAST_ETHEREUM_ADDRESSES
def setup_module():
    """Initialise the database with unittest fixtures"""
    # global the DB/cursor for other functions to access
    global db, cursor, logger

    db = util_test.init_database(CURR_DIR + '/fixtures/scenarios/unittest_fixture.sql', 'fixtures.countracts_test.db')
    logger = logging.getLogger(__name__)
    db.setrollbackhook(lambda: logger.debug('ROLLBACK'))
    database.update_version(db)

    _CAST_ETHEREUM_ADDRESSES = address.CAST_ETHEREUM_ADDRESSES
    address.CAST_ETHEREUM_ADDRESSES = True


def teardown_module():
    """Delete the temporary database."""
    util_test.remove_database_files(config.DATABASE)
    address.CAST_ETHEREUM_ADDRESSES = _CAST_ETHEREUM_ADDRESSES


def setup_function(function):
    global db, cursor

    # start transaction so we can rollback on teardown
    cursor = db.cursor()
    cursor.execute('''BEGIN''')


def teardown_function(function):
    global db, cursor
    cursor.execute('''ROLLBACK''')


VERIFY = 2
def test_pyeth_fixtures_vm(filename, testname, testdata):
    def replace_code(testdata, old, new):
        replaced = False

        if testdata['exec']['code'] == old:
            replaced = True
            testdata['exec']['code'] = new

        for a in list(testdata.get('pre', {}).keys()):
            if testdata['pre'][a]['code'] == old:
               replaced = True
               testdata['pre'][a]['code'] = new

        for a in list(testdata.get('post', {}).keys()):
            if testdata['post'][a]['code'] == old:
               replaced = True
               testdata['post'][a]['code'] = new

        assert replaced

    def add_prefix(value, prefix=None, is_contract=True):
        if prefix is None:
            prefix = config.CONTRACT_ADDRESSVERSION if is_contract else config.ADDRESSVERSION

        if isinstance(prefix, bytes):
            prefix = ethutils.encode_hexstr(prefix)

        hexprefix = value[:2] == "0x"
        if hexprefix:
            value = value[2:]  # strip 0x
        value = prefix + value  # add prefix
        if hexprefix:
            value = "0x" + value  # add 0x back

        return value

    def add_prefix_in_code(testdata, address, badprefix=None, badsuffix=None, prefix=None, is_contract=True):
        """
        esentially does this:
        # old; PUSH21 <ADDRESS><BADBYTE> BALANCE PUSH1 0 SSTORE
        old = "0x74" "cd1722f3947def4cf144679da39c4c32bdc35681aa" "31600055"
        # old; PUSH22 <PREFIX><ADDRESS><BADBYTE> BALANCE PUSH1 0 SSTORE
        new = "0x75" "80cd1722f3947def4cf144679da39c4c32bdc35681aa" "31600055"
        replace_code(testdata, old, new)
        """

        prefixed_address = add_prefix(address, prefix, is_contract)
        old = testdata['exec']['code']

        if badprefix:
            new = old.replace("74" + badprefix + address, "75" + badprefix + prefixed_address)
        elif badsuffix:
            new = old.replace("74" + address + badsuffix, "75" + prefixed_address + badsuffix)
        else:
            new = old.replace("73" + address, "74" + prefixed_address)

        replace_code(testdata, old, new)

    def add_prefix_to_storage(testdata, address, key, prefix=None, is_contract=True):
        value = testdata['post'][address]['storage'][key]
        value = add_prefix(value, prefix, is_contract)

        testdata['post'][address]['storage'][key] = value

    def ceil_balance_in_storage(testdata, address, key):
        balance = testdata['post'][address]['storage'][key]
        balance = pyethtestutils.ceil_balance(balance)

        testdata['post'][address]['storage'][key] = pyethtestutils.encode_int_to_hex_with_prefix(balance)

    # stores CALLER, add prefix to expected result in storage
    if os.path.basename(filename) == 'vmIOandFlowOperationsTest.json' and testname == 'kv1':
        add_prefix_to_storage(testdata, '0f572e5295c57f15886f9b263e2f6d2d6c7b5ec6', '0x45', is_contract=False)

    # stores COINBASE
    elif os.path.basename(filename) == 'vmBlockInfoTest.json' and testname == 'coinbase':
        add_prefix_to_storage(testdata, '0f572e5295c57f15886f9b263e2f6d2d6c7b5ec6', '0x00', is_contract=False)

    # stores ADDRESS, add prefix to expected result in storage
    elif os.path.basename(filename) == 'vmEnvironmentalInfoTest.json' and testname == 'address1':
        add_prefix_to_storage(testdata, 'cd1722f3947def4cf144679da39c4c32bdc35681', '0x00')

    # stores ADDRESS
    elif os.path.basename(filename) == 'vmEnvironmentalInfoTest.json' and testname == 'address0':
        add_prefix_to_storage(testdata, '0f572e5295c57f15886f9b263e2f6d2d6c7b5ec6', '0x00')

    # stores BALANCE, balance needs to be ceiled
    elif os.path.basename(filename) == 'vmEnvironmentalInfoTest.json' and testname == 'balance1':
        ceil_balance_in_storage(testdata, '0f572e5295c57f15886f9b263e2f6d2d6c7b5ec6', '0x00')

    # stores CALLER
    elif os.path.basename(filename) == 'vmEnvironmentalInfoTest.json' and testname == 'caller':
        add_prefix_to_storage(testdata, '0f572e5295c57f15886f9b263e2f6d2d6c7b5ec6', '0x00', is_contract=False)

    # stores ORIGIN
    elif os.path.basename(filename) == 'vmEnvironmentalInfoTest.json' and testname == 'origin':
        add_prefix_to_storage(testdata, '0f572e5295c57f15886f9b263e2f6d2d6c7b5ec6', '0x00', is_contract=False)

    # tests invalid hardcoded address, needs prefix
    elif os.path.basename(filename) == 'vmEnvironmentalInfoTest.json' and testname == 'balanceAddressInputTooBig':
        add_prefix_in_code(testdata, "cd1722f3947def4cf144679da39c4c32bdc35681", badsuffix="aa")

    # tests invalid hardcoded address, needs prefix
    elif os.path.basename(filename) == 'vmEnvironmentalInfoTest.json' and testname == 'balanceAddressInputTooBigRightMyAddress':
        add_prefix_in_code(testdata, "0f572e5295c57f15886f9b263e2f6d2d6c7b5ec6", badsuffix="aa")

    # tests invalid hardcoded address, needs prefix
    # and ceiled balance
    elif os.path.basename(filename) == 'vmEnvironmentalInfoTest.json' and testname == 'balanceAddressInputTooBigLeftMyAddress':
        add_prefix_in_code(testdata, "0f572e5295c57f15886f9b263e2f6d2d6c7b5ec6", badprefix="aa")
        ceil_balance_in_storage(testdata, '0f572e5295c57f15886f9b263e2f6d2d6c7b5ec6', '0x00')

    # tests invalid hardcoded address, needs prefix
    elif os.path.basename(filename) == 'vmEnvironmentalInfoTest.json' and testname == 'ExtCodeSizeAddressInputTooBigRightMyAddress':
        add_prefix_in_code(testdata, "0f572e5295c57f15886f9b263e2f6d2d6c7b5ec6", badsuffix="aa")

    # tests invalid hardcoded address, needs prefix
    # if we make the code longer EXTCODESIZE returns more too
    elif os.path.basename(filename) == 'vmEnvironmentalInfoTest.json' and testname == 'ExtCodeSizeAddressInputTooBigLeftMyAddress':
        add_prefix_in_code(testdata, "0f572e5295c57f15886f9b263e2f6d2d6c7b5ec6", badprefix="aa")
        testdata['post']['0f572e5295c57f15886f9b263e2f6d2d6c7b5ec6']['storage']['0x00'] = "0x1b"

    # tests invalid hardcoded address, needs prefix
    elif os.path.basename(filename) == 'vmEnvironmentalInfoTest.json' and testname == 'extcodecopy0AddressTooBigRight':
        add_prefix_in_code(testdata, "cd1722f3947def4cf144679da39c4c32bdc35681", badsuffix="aa")

    # tests invalid hardcoded address, needs prefix
    elif os.path.basename(filename) == 'vmEnvironmentalInfoTest.json' and testname == 'extcodecopy0AddressTooBigLeft':
        add_prefix_in_code(testdata, "cd1722f3947def4cf144679da39c4c32bdc35681", badprefix="aa")

    # stores COINBASE
    elif os.path.basename(filename) == 'vmSystemOperationsTest.json' and testname == 'createNameRegistrator':
        add_prefix_to_storage(testdata, '0f572e5295c57f15886f9b263e2f6d2d6c7b5ec6', '0x00', is_contract=True)

    pyethtestutils.run_vm_test(state(), pyethtestutils.fixture_to_bytes(testdata), VERIFY)


def pytest_generate_tests(metafunc):
    if pytest.config.option.vmtests and 'all' not in pytest.config.option.vmtests:
        testsources = pytest.config.option.vmtests
    else:
        testsources = ['VMTests/*.json']

    pyethtestutils.generate_test_params(testsources, metafunc)
