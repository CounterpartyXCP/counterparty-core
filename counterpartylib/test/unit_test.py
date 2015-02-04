#! /usr/bin/python3
import sys, os, time, tempfile
import pytest
import util_test
from util_test import CURR_DIR
from fixtures.vectors import UNITTEST_VECTOR
from fixtures.params import DEFAULT_PARAMS as DP

from counterpartylib.lib import (config, util, api, database)
import server

def setup_module():
    """Initialise the database with default data and wait for server to be ready."""
    server.initialise(database_file=tempfile.gettempdir() + '/fixtures.unittest.db', testnet=True, **util_test.COUNTERPARTYD_OPTIONS)
    db = util_test.restore_database(config.DATABASE, CURR_DIR + '/fixtures/scenarios/unittest_fixture.sql')
    util.FIRST_MULTISIG_BLOCK_TESTNET = 1
    # start RPC server
    api_server = api.APIServer()
    api_server.daemon = True
    api_server.start()
    for attempt in range(5000): # wait until server is ready.
        if api_server.is_ready:
            break
        elif attempt == 4999:
            raise Exception("Timeout: RPC server not ready after 5s")
        else:
            time.sleep(0.001)

def teardown_module(function):
    """Delete the temporary database."""
    util_test.remove_database_files(config.DATABASE)

@pytest.fixture
def counterpartyd_db(request):
    """Enable database access for unit test vectors."""
    db = database.get_connection(read_only=False)
    database.update_version(db)
    cursor = db.cursor()
    cursor.execute('''BEGIN''')
    request.addfinalizer(lambda: cursor.execute('''ROLLBACK'''))
    return db

def test_vector(tx_name, method, inputs, outputs, error, records, counterpartyd_db):
    """Test the outputs of unit test vector. If testing parse, execute the transaction data on test db."""
    if method == 'parse':
        util_test.insert_transaction(inputs[0], counterpartyd_db)
        inputs += (inputs[0]['data'][4:],) # message arg
    util_test.check_outputs(tx_name, method, inputs, outputs, error, records, counterpartyd_db)

# def test_gen(counterpartyd_db, rawtransactions_db):
#     """Test cases generator.

#     This snippet generates test cases that can be used to add new tests.
#     You need to customize it to output specific transaction (tx_info) or database changes.
#     Run unit test with -s switch to see the output of print, ie. py.test test/unit_test.py -s.
#     """
#     from counterpartylib.lib import transaction
#     from counterpartylib.lib.messages import bet
#     tx_info = bet.compose(counterpartyd_db, DP['addresses'][0][0], DP['addresses'][0][0], 0, 1488000000, DP['small'] * 2, DP['small'] * 2, 0.0, 5040, DP['expiration'])
#     print('tx_info')
#     print(tx_info)
#     tx_hex = transaction.construct(counterpartyd_db, tx_info, encoding='multisig', allow_unconfirmed_inputs=True)
#     print('tx_hex')
#     print(tx_hex)
#     tx = util_test.insert_raw_transaction(tx_hex, counterpartyd_db, rawtransactions_db)
#     print('tx')
#     print(tx)
#     message = list(counterpartyd_db.cursor().execute("SELECT * FROM bets WHERE (feed_address=?)", (DP['addresses'][0][0],)))
#     print('database')
#     print(message)
