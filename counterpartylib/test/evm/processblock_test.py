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
from counterpartylib.lib.evm import (blocks, processblock, ethutils, transactions, opcodes, abi, address, vm, exceptions as ethexceptions)

from counterpartylib.test.evm import contracts_tester as tester
from counterpartylib.test import util_test
from counterpartylib.lib.evm.solidity import get_solidity

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


def test_nonce():
    code = """
contract testme {

}
"""

    evmcode = solidity.compile(code)

    s = state()
    assert s.block.get_nonce(tester.a0) == 1

    address1 = s.evm(evmcode, tester.a0, 0)
    assert s.block.get_nonce(tester.a0) == 2

    address2 = s.evm(evmcode, tester.a0, 0)
    assert s.block.get_nonce(tester.a0) == 3

    address3 = s.evm(evmcode, tester.a0, 0)
    assert s.block.get_nonce(tester.a0) == 4

    address4 = s.evm(evmcode, tester.a0, 0)
    assert s.block.get_nonce(tester.a0) == 5

    assert address1 != address2
    assert address1 != address3
    assert address1 != address4
    assert address2 != address3
    assert address2 != address4
    assert address3 != address4


def test_intrinsic_gas_check():
    global db

    code = """
contract testme {

}
"""

    evmcode = solidity.compile(code)
    intrinsic_gas = transactions.Transaction.intrinsic_gas_used_for_data(evmcode) + opcodes.CREATE[3]

    s = state()

    # gas lower than intrinsic_gas
    with pytest.raises(ethexceptions.InsufficientStartGas):
        s.evm(evmcode, tester.a0, 0, startgas=intrinsic_gas - 1)


def test_snapshot():
    global db, cursor

    code = """
contract testme {

}
"""

    contracts_before = list(cursor.execute('''SELECT * FROM contracts'''))

    evmcode = solidity.compile(code)
    s = state()

    sender = address.Address.normalize(tester.a0)
    to = address.Address.normalize('')

    tx, tx_obj, block_obj = s.mock_tx(sender, to, 0, evmcode)

    ext = processblock.VMExt(db, block_obj, tx_obj)

    suicides = list(ext._block.suicides)
    logs = list(ext._block.logs)
    refunds = ext._block.refunds
    gas_used = ext._block.gas_used

    snapshot = ext._block.snapshot()

    # create contract
    processblock.apply_transaction(db, block_obj, tx_obj)

    # modify VMExt instance with random data
    ext._block.suicides.append(1)
    ext._block.logs.append(1)
    ext._block.refunds += 1
    ext._block.gas_used += 1

    # check for changes
    assert list(ext._block.suicides) != suicides
    assert list(ext._block.logs) != logs
    assert ext._block.refunds != refunds
    assert ext._block.gas_used != gas_used
    assert list(cursor.execute('''SELECT * FROM contracts''')) != contracts_before

    ext._block.revert(snapshot)

    assert list(ext._block.suicides) == suicides
    assert list(ext._block.logs) == logs
    assert ext._block.refunds == refunds
    assert ext._block.gas_used == gas_used
    assert list(cursor.execute('''SELECT * FROM contracts''')) == contracts_before


def test_creation_rollback():
    global db, cursor

    code = """
contract testme {
    uint d = 0;
    uint dd = 0;

    function testme() {
        d = 111;

        // make sure it goes OOG here
        for (uint i = 0; i < 100000; i++) {
            dd = i;
        }
    }

}
"""

    contracts_before = list(cursor.execute('''SELECT * FROM contracts'''))
    storage_before = list(cursor.execute('''SELECT * FROM storage'''))
    nonce_before = list(cursor.execute('''SELECT * FROM nonces WHERE address = ?''', (tester.a0, )))

    evmcode = solidity.compile(code)

    s = state()

    # not enough to execute the full constructor, but enough to do a bit of it
    startgas = 314159

    sender = address.Address.normalize(tester.a0)
    to = address.Address.normalize('')

    tx, tx_obj, block_obj = s.mock_tx(sender, to, 0, evmcode, startgas=startgas)

    success, output, gas_remained = processblock.apply_transaction(db, block_obj, tx_obj)

    # check that it failed
    assert success == False
    assert output == b''
    assert gas_remained == 0

    pprint.pprint(list(cursor.execute('''SELECT * FROM storage''')))

    # check that no data was left behind
    assert list(cursor.execute('''SELECT * FROM contracts''')) == contracts_before
    assert list(cursor.execute('''SELECT * FROM storage''')) == storage_before

    # check that nonce was still bumped @TODO: are we sure about this?
    assert list(cursor.execute('''SELECT * FROM nonces WHERE address = ?''', (tester.a0, )))[0]['nonce'] == nonce_before[0]['nonce'] + 1
