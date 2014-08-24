#! /usr/bin/python3
import sys, os
import pytest
import util_test
from util_test import CURR_DIR
from fixtures.unittest_vector import UNITTEST_VECTOR, DEFAULT_PARAMS as DP

from lib import (config, util)
import counterpartyd


def setup_module():
    counterpartyd.set_options(rpc_port=9999, database_file=CURR_DIR + '/fixtures/fixtures.unittest.db', testnet=True, testcoin=False, unittest=True, backend_rpc_ssl_verify=False)
    util_test.restore_database(config.DATABASE, CURR_DIR + '/fixtures/unittest_fixture.sql')

def teardown_module(function):
    os.remove(config.DATABASE)

@pytest.fixture
def counterpartyd_db(request):
    db = util.connect_to_db()
    cursor = db.cursor()
    cursor.execute('''BEGIN''')
    request.addfinalizer(lambda: cursor.execute('''ROLLBACK'''))
    return db

def pytest_generate_tests(metafunc):
    if metafunc.function.__name__ == 'test_vector':
        args = util_test.vector_to_args(UNITTEST_VECTOR, pytest.config.option.function)
        metafunc.parametrize('tx_name, method, inputs, outputs, error, records', args)

def test_vector(tx_name, method, inputs, outputs, error, records, counterpartyd_db):
    if method == 'parse':
        util_test.insert_transaction(inputs[0], counterpartyd_db)
    util_test.check_ouputs(tx_name, method, inputs, outputs, error, records, counterpartyd_db)


'''
# used to generate the vector
def test_tx(counterpartyd_db):
    raw_transaction = bitcoin.transaction(burn.compose(counterpartyd_db, DP['address_2'], DP['burn_quantity']), encoding='multisig')
    tx = util_test.insert_transaction(raw_transaction, counterpartyd_db)
    print(tx)
    burned = list(counterpartyd_db.cursor().execute("SELECT * FROM burns WHERE tx_hash = ?", (tx['tx_hash'], )))[0]
    print(burned)
    credit = list(counterpartyd_db.cursor().execute("SELECT * FROM credits WHERE event = ?", (tx['tx_hash'], )))[0]
    print(credit)
'''

