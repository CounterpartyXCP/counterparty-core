"""
bunch of tests used to benchmark performance of the EVM
"""
import hashlib
import pprint
import pytest
import binascii
import os
import sys
import logging
import serpent
import time

from counterpartylib.test import conftest  # this is require near the top to do setup of the test suite
from counterpartylib.test.util_test import CURR_DIR
from counterpartylib.test.fixtures import params

from counterpartylib.lib import (config, database, util)
from counterpartylib.lib.evm import (blocks, processblock, ethutils, abi, address, vm, exceptions as evmexceptions)

from counterpartylib.test.evm import contracts_tester as tester
from counterpartylib.test import util_test
from counterpartylib.lib.evm.solidity import get_solidity

solidity = get_solidity()

# globals initialized by setup_function
db, cursor, logger = None, None, conftest.logger
CLEANUP_FILES = []

pytest_skip_unless_run_benchmarks = pytest.mark.skipif(not pytest.config.option.runbenchmarks, reason="avoid benchmarks unless enabled")


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
    global db, cursor

    db = util_test.init_database(CURR_DIR + '/fixtures/scenarios/unittest_fixture.sql', ':memory:')
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


@pytest_skip_unless_run_benchmarks
def test_benchmark_execution():
    code = '''
contract testme {
    uint[] data;

    function main(uint l) returns (bool) {
        for (uint i = 0; i < l; i++) {
            data.push(i);
        }

        return true;
    }
}
'''

    # disable verbose logging since it's A LOT more expensive
    #  because of all the VM OP spam
    with util_test.LoggingLevelContext(logger, logging.CRITICAL):
        s = state()
        c = s.abi_contract(code, language='solidity')

        r = {}
        for (n, m) in [
            (1, 1000), (1, 10000), (1, 35000),
            (10, 100), (10, 1000), (10, 3500),
        ]:
            b = s.block.get_balance(tester.a0)
            block_obj = s.mine()

            t = time.time()
            for i in range(n):
                c.main(m, startgas=int(config.BLOCK_GAS_LIMIT / n), block_obj=block_obj)
            tt = time.time() - t

            r[(n, m)] = (n, m, tt, b - s.block.get_balance(tester.a0))

        import pprint
        pprint.pprint(r)
