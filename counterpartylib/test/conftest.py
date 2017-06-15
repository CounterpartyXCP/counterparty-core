"""
Test suite configuration
"""

import json
import apsw
import time
from datetime import datetime
import pytest
import bitcoin as bitcoinlib
import logging

from counterpartylib.lib import log
log.set_logger(logging.getLogger())

from counterpartylib.test import util_test
from counterpartylib.test.fixtures.vectors import UNITTEST_VECTOR
from counterpartylib.test.fixtures.params import DEFAULT_PARAMS
from counterpartylib.test.fixtures.scenarios import INTEGRATION_SCENARIOS

from counterpartylib.lib import config, util, database, api


# we swap out util.enabled with a custom one which has the option to mock the protocol changes
MOCK_PROTOCOL_CHANGES = {
    'bytespersigop': False,    # default to False to avoid all old vectors breaking
    'short_tx_type_id': False, # default to False to avoid all old vectors breaking
}
MOCK_PROTOCOL_CHANGES_AT_BLOCK = {
    'subassets': {'block_index': 310495, 'enabled': True},  # override to be true only after block 310495
    'short_tx_type_id': {'block_index': 310501, 'all_tests': True, 'enabled': True},  # override to be true only after block 310500
}
ENABLE_MOCK_PROTOCOL_CHANGES_AT_BLOCK = False
ALWAYS_LATEST_PROTOCOL_CHANGES = False
_enabled = util.enabled
def enabled(change_name, block_index=None):
    # enable some protocol changes at a specific block for testing
    if shouldCheckForMockProtocolChangesAtBlock(change_name) and change_name in MOCK_PROTOCOL_CHANGES_AT_BLOCK:
        _block_index = block_index
        if _block_index is None:
            _block_index = util.CURRENT_BLOCK_INDEX
        logger = logging.getLogger(__name__)
        if _block_index >= MOCK_PROTOCOL_CHANGES_AT_BLOCK[change_name]['block_index']:
            return MOCK_PROTOCOL_CHANGES_AT_BLOCK[change_name]['enabled']

    # if explicitly set
    if change_name in MOCK_PROTOCOL_CHANGES:
        return MOCK_PROTOCOL_CHANGES[change_name]

    # used to force unit tests to always run against latest protocol changes
    if ALWAYS_LATEST_PROTOCOL_CHANGES:
        # KeyError to mimic real util.enabled
        if change_name not in util.PROTOCOL_CHANGES:
            raise KeyError(change_name)

        return True
    else:
        return _enabled(change_name, block_index)
util.enabled = enabled

# This is true if ENABLE_MOCK_PROTOCOL_CHANGES_AT_BLOCK is set
#   It is also true if 'all_tests' is set in the MOCK_PROTOCOL_CHANGES_AT_BLOCK object
def shouldCheckForMockProtocolChangesAtBlock(change_name):
    check_for_mock_protocol_changes_at_block = False
    if ENABLE_MOCK_PROTOCOL_CHANGES_AT_BLOCK:
        # always check
        check_for_mock_protocol_changes_at_block = True
    else:
        # only check if 'all_tests' is True
        if change_name in MOCK_PROTOCOL_CHANGES_AT_BLOCK \
            and 'all_tests' in MOCK_PROTOCOL_CHANGES_AT_BLOCK[change_name] \
            and MOCK_PROTOCOL_CHANGES_AT_BLOCK[change_name]['all_tests'] == True:
                check_for_mock_protocol_changes_at_block = True
    return check_for_mock_protocol_changes_at_block


RANDOM_ASSET_INT = None
_generate_random_asset = util.generate_random_asset
def generate_random_asset ():
    if RANDOM_ASSET_INT is None:
        return _generate_random_asset()
    else:
        return 'A' + str(RANDOM_ASSET_INT)
util.generate_random_asset = generate_random_asset


def pytest_generate_tests(metafunc):
    """Generate all py.test cases. Checks for different types of tests and creates proper context."""
    if metafunc.function.__name__ == 'test_vector':
        args = util_test.vector_to_args(UNITTEST_VECTOR, pytest.config.option.function)
        metafunc.parametrize('tx_name, method, inputs, outputs, error, records, comment, mock_protocol_changes', args)
    elif metafunc.function.__name__ == 'test_scenario':
        args = []
        for scenario_name in INTEGRATION_SCENARIOS:
            if pytest.config.option.scenario == [] or scenario_name in pytest.config.option.scenario:
                args.append((scenario_name, INTEGRATION_SCENARIOS[scenario_name][1], INTEGRATION_SCENARIOS[scenario_name][0]))
        metafunc.parametrize('scenario_name, base_scenario_name, transactions', args)
    elif metafunc.function.__name__ == 'test_book':
        if pytest.config.option.skiptestbook == 'all':
            args = []
        elif pytest.config.option.skiptestbook == 'testnet':
            args = [False]
        elif pytest.config.option.skiptestbook == 'mainnet':
            args = [True]
        else:
            args = [True, False]
        metafunc.parametrize('testnet', args)

def pytest_addoption(parser):
    """Add useful test suite argument options."""
    parser.addoption("--function", action="append", default=[], help="list of functions to test")
    parser.addoption("--scenario", action="append", default=[], help="list of scenarios to test")
    parser.addoption("--gentxhex", action='store_true', default=False, help="generate and print unsigned hex for *.compose() tests")
    parser.addoption("--savescenarios", action='store_true', default=False, help="generate sql dump and log in .new files")
    parser.addoption("--skiptestbook", default='no', help="skip test book(s) (use with one of the following values: `all`, `testnet` or `mainnet`)")


@pytest.fixture(scope="module")
def rawtransactions_db(request):
    """Return a database object."""
    db = apsw.Connection(util_test.CURR_DIR + '/fixtures/rawtransactions.db')
    if (request.module.__name__ == 'integration_test'):
        util_test.initialise_rawtransactions_db(db)
    return db


@pytest.fixture(scope='function')
def server_db(request, cp_server):
    """Enable database access for unit test vectors."""
    db = database.get_connection(read_only=False, integrity_check=False)
    cursor = db.cursor()
    cursor.execute('''BEGIN''')
    util_test.reset_current_block_index(db)

    request.addfinalizer(lambda: cursor.execute('''ROLLBACK'''))
    request.addfinalizer(lambda: util_test.reset_current_block_index(db))

    return db


@pytest.fixture(scope='module')
def api_server(request, cp_server):
    # start RPC server and wait for server to be ready
    api_server = api.APIServer()
    api_server.daemon = True
    api_server.start()
    for attempt in range(5000):  # wait until server is ready.
        if api_server.is_ready:
            break
        elif attempt == 4999:
            raise Exception("Timeout: RPC server not ready after 5s")
        else:
            time.sleep(0.001)  # attempt to query the current block_index if possible (scenarios start with empty DB so it's not always possible)


@pytest.fixture(scope='module')
def cp_server(request):
    dbfile = getattr(request.module, 'FIXTURE_DB')
    sqlfile = getattr(request.module, 'FIXTURE_SQL_FILE')
    options = getattr(request.module, 'FIXTURE_OPTIONS', {})

    util_test.init_database(sqlfile, dbfile, options)

    # monkeypatch this here because init_mock_functions can run before cp_server
    if hasattr(config, 'PREFIX'):
        config.PREFIX = b'TESTXXXX'

    request.addfinalizer(lambda: util_test.remove_database_files(dbfile))


@pytest.fixture(scope='function', autouse=True)
def init_mock_functions(monkeypatch, rawtransactions_db):
    """Test suit mock functions.

    Mock functions override default behaviour to allow test suit to work - for instance, date_passed is overwritten 
    so that every date will pass. Those are available to every test function in this suite."""

    util_test.rawtransactions_db = rawtransactions_db

    def get_unspent_txouts(address, unconfirmed=False, multisig_inputs=False):
        with open(util_test.CURR_DIR + '/fixtures/unspent_outputs.json', 'r') as listunspent_test_file:
            wallet_unspent = json.load(listunspent_test_file)
            unspent_txouts = [output for output in wallet_unspent if output['address'] == address]
            return unspent_txouts

    def isodt(epoch_time):
        return datetime.utcfromtimestamp(epoch_time).isoformat()

    def curr_time():
        return 0

    def date_passed(date):
        return False

    def init_api_access_log(app):
        pass

    def pubkeyhash_to_pubkey(address, provided_pubkeys=None):
        return DEFAULT_PARAMS['pubkey'][address]

    def multisig_pubkeyhashes_to_pubkeys(address, provided_pubkeys=None):
        # TODO: Should be updated?!
        array = address.split('_')
        signatures_required = int(array[0])
        pubkeyhashes = array[1:-1]
        pubkeys = [DEFAULT_PARAMS['pubkey'][pubkeyhash] for pubkeyhash in pubkeyhashes]
        address = '_'.join([str(signatures_required)] + sorted(pubkeys) + [str(len(pubkeys))])
        return address

    def get_cached_raw_transaction(tx_hash, verbose=False):
        return util_test.getrawtransaction(rawtransactions_db, bitcoinlib.core.lx(tx_hash))

    monkeypatch.setattr('counterpartylib.lib.backend.get_unspent_txouts', get_unspent_txouts)
    monkeypatch.setattr('counterpartylib.lib.log.isodt', isodt)
    monkeypatch.setattr('counterpartylib.lib.log.curr_time', curr_time)
    monkeypatch.setattr('counterpartylib.lib.util.date_passed', date_passed)
    monkeypatch.setattr('counterpartylib.lib.api.init_api_access_log', init_api_access_log)
    if hasattr(config, 'PREFIX'):
        monkeypatch.setattr('counterpartylib.lib.config.PREFIX', b'TESTXXXX')
    monkeypatch.setattr('counterpartylib.lib.backend.getrawtransaction', get_cached_raw_transaction)
    monkeypatch.setattr('counterpartylib.lib.backend.pubkeyhash_to_pubkey', pubkeyhash_to_pubkey)
    monkeypatch.setattr('counterpartylib.lib.backend.multisig_pubkeyhashes_to_pubkeys', multisig_pubkeyhashes_to_pubkeys)
