#! /usr/bin/python3

import json, binascii, apsw
from datetime import datetime

import pytest, util_test

from fixtures.vectors import UNITTEST_VECTOR
from fixtures.params import DEFAULT_PARAMS
from fixtures.scenarios import INTEGRATION_SCENARIOS

from lib import config, bitcoin, util

import bitcoin as bitcoinlib

def pytest_collection_modifyitems(session, config, items):
    # run contracts_test.py last
    items[:] = list(reversed(items))

def pytest_generate_tests(metafunc):
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
    parser.addoption("--function", action="append", default=[], help="list of functions to test")
    parser.addoption("--scenario", action="append", default=[], help="list of scenarios to test")
    parser.addoption("--gentxhex", action='store_true', default=False, help="generate and print unsigned hex for *.compose() tests")
    parser.addoption("--savescenarios", action='store_true', default=False, help="generate sql dump and log in .new files")
    parser.addoption("--skiptestbook", default='no', help="skip test book(s) (use with one of the following values: `all`, `testnet` or `mainnet`)")

@pytest.fixture(scope="module")
def rawtransactions_db(request):
    db = apsw.Connection(util_test.CURR_DIR + '/fixtures/rawtransactions.db')
    if (request.module.__name__ == 'integration_test'):
        util_test.initialise_rawtransactions_db(db)
    return db

@pytest.fixture(autouse=True)
def init_mock_functions(monkeypatch, rawtransactions_db):

    def get_unspent_txouts(address, return_confirmed=False):
        with open(util_test.CURR_DIR + '/fixtures/unspent_outputs.json', 'r') as listunspent_test_file:
            wallet_unspent = json.load(listunspent_test_file)
            unspent_txouts = [output for output in wallet_unspent if output['address'] == address]
            if return_confirmed:
                return unspent_txouts, unspent_txouts
            else:
                return unspent_txouts

    def get_private_key(source):
        return DEFAULT_PARAMS['privkey'][source]

    def is_mine(address):
        return address in DEFAULT_PARAMS['privkey']

    def isodt(epoch_time):
        return datetime.utcfromtimestamp(epoch_time).isoformat()

    def curr_time():
        return 0

    def date_passed(date):
        return False

    def init_api_access_log():
        pass

    def multisig_pubkeyhashes_to_pubkeys(address):
        array = address.split('_')
        signatures_required = int(array[0])
        pubkeyhashes = array[1:-1]
        pubkeys = [DEFAULT_PARAMS['pubkey'][pubkeyhash] for pubkeyhash in pubkeyhashes]
        address = '_'.join([str(signatures_required)] + sorted(pubkeys) + [str(len(pubkeys))])
        return address

    def decode_raw_transaction(raw_transaction):
        if pytest.config.option.savescenarios:
            return util.rpc('decoderawtransaction', [raw_transaction])
        else:
            return util_test.decoderawtransaction(rawtransactions_db, raw_transaction)

    class RpcProxy():
        def __init__(self, service_url=None):
            pass

        def getrawtransaction(self, txid):
            tx_hex = util_test.getrawtransaction(rawtransactions_db, txid)
            ctx = bitcoinlib.core.CTransaction.deserialize(binascii.unhexlify(tx_hex))
            return ctx

    monkeypatch.setattr('lib.bitcoin.get_unspent_txouts', get_unspent_txouts)
    monkeypatch.setattr('lib.bitcoin.get_private_key', get_private_key)
    monkeypatch.setattr('lib.bitcoin.is_mine', is_mine)
    monkeypatch.setattr('lib.util.isodt', isodt)
    monkeypatch.setattr('lib.util.curr_time', curr_time)
    monkeypatch.setattr('lib.util.date_passed', date_passed)
    monkeypatch.setattr('lib.api.init_api_access_log', init_api_access_log)
    if hasattr(config, 'PREFIX'):
        monkeypatch.setattr('lib.config.PREFIX', b'TESTXXXX')
    monkeypatch.setattr('lib.bitcoin.multisig_pubkeyhashes_to_pubkeys', multisig_pubkeyhashes_to_pubkeys)
    monkeypatch.setattr('lib.bitcoin.decode_raw_transaction', decode_raw_transaction)
    monkeypatch.setattr('bitcoin.rpc.Proxy', RpcProxy)
