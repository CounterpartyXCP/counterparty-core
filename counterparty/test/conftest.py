#! /usr/bin/python3

"""
Test suite configuration
"""

import os
import sys

current_dir = os.path.dirname(os.path.realpath(os.path.join(os.getcwd(), os.path.expanduser(__file__))))
base_dir = os.path.normpath(os.path.join(current_dir, '../../'))
sys.path.insert(0, base_dir)

import json, binascii, apsw
from datetime import datetime

import pytest, util_test

from fixtures.vectors import UNITTEST_VECTOR
from fixtures.params import DEFAULT_PARAMS
from fixtures.scenarios import INTEGRATION_SCENARIOS

from counterparty.lib import config, util, backend, transaction

import bitcoin as bitcoinlib
import bitcoin.rpc as bitcoinlib_rpc

def pytest_collection_modifyitems(session, config, items):
    """Run contracts_test.py last."""
    items[:] = list(reversed(items))

def pytest_generate_tests(metafunc):
    """Generate all py.test cases. Checks for different types of tests and creates proper context."""
    if metafunc.function.__name__ == 'test_vector':
        args = util_test.vector_to_args(UNITTEST_VECTOR, pytest.config.option.function)
        metafunc.parametrize('tx_name, method, inputs, outputs, error, records', args)
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

@pytest.fixture(autouse=True)
def init_mock_functions(monkeypatch, rawtransactions_db):
    """Test suit mock functions.

    Mock functions override default behaviour to allow test suit to work - for instance, date_passed is overwritten 
    so that every date will pass. Those are available to every test function in this suite."""

    util_test.rawtransactions_db = rawtransactions_db

    def get_unspent_txouts(address, return_confirmed=False):
        with open(util_test.CURR_DIR + '/fixtures/unspent_outputs.json', 'r') as listunspent_test_file:
            wallet_unspent = json.load(listunspent_test_file)
            unspent_txouts = [output for output in wallet_unspent if output['address'] == address]
            if return_confirmed:
                return unspent_txouts, unspent_txouts
            else:
                return unspent_txouts

    def isodt(epoch_time):
        return datetime.utcfromtimestamp(epoch_time).isoformat()

    def curr_time():
        return 0

    def date_passed(date):
        return False

    def init_api_access_log():
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

    util.CURRENT_BLOCK_INDEX = DEFAULT_PARAMS['default_block'] - 1

    monkeypatch.setattr('counterparty.lib.backend.get_unspent_txouts', get_unspent_txouts)
    monkeypatch.setattr('counterparty.lib.log.isodt', isodt)
    monkeypatch.setattr('counterparty.lib.log.curr_time', curr_time)
    monkeypatch.setattr('counterparty.lib.util.date_passed', date_passed)
    monkeypatch.setattr('counterparty.lib.api.init_api_access_log', init_api_access_log)
    if hasattr(config, 'PREFIX'):
        monkeypatch.setattr('counterparty.lib.config.PREFIX', b'TESTXXXX')
    monkeypatch.setattr('counterparty.lib.backend.getrawtransaction', get_cached_raw_transaction)
    monkeypatch.setattr('counterparty.lib.backend.pubkeyhash_to_pubkey', pubkeyhash_to_pubkey)
    monkeypatch.setattr('counterparty.lib.backend.multisig_pubkeyhashes_to_pubkeys', multisig_pubkeyhashes_to_pubkeys)
