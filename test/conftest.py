#! /usr/bin/python3

import json, binascii
from datetime import datetime

import pytest, util_test
from fixtures.fixtures import UNITTEST_VECTOR, INTEGRATION_SCENARIOS, DEFAULT_PARAMS
from lib import config

import bitcoin as bitcoinlib

def pytest_generate_tests(metafunc):
    if metafunc.function.__name__ == 'test_vector':
        args = util_test.vector_to_args(UNITTEST_VECTOR, pytest.config.option.function)
        metafunc.parametrize('tx_name, method, inputs, outputs, error, records', args)
    elif metafunc.function.__name__ == 'test_scenario':
        args = []
        for scenario_name in INTEGRATION_SCENARIOS:
            if pytest.config.option.scenario == [] or scenario_name in pytest.config.option.scenario:
                args.append((scenario_name, INTEGRATION_SCENARIOS[scenario_name]))
        metafunc.parametrize('scenario_name, transactions', args)

def pytest_addoption(parser):
    parser.addoption("--function", action="append", default=[], help="list of functions to test")
    parser.addoption("--scenario", action="append", default=[], help="list of scenarios to test")
    parser.addoption("--gentxhex", action='store_true', default=False, help="generate and print unsigned hex for *.compose() tests")


@pytest.fixture(autouse=True)
def init_mock_functions(monkeypatch):

    def get_unspent_txouts(address):
        with open(util_test.CURR_DIR + '/fixtures/listunspent.test.json', 'r') as listunspent_test_file:
            wallet_unspent = json.load(listunspent_test_file)
            unspent_txouts = [output for output in wallet_unspent if output['address'] == address]
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

    class RpcProxy():
        def getrawtransaction(self, txid):
            tx_hex = util_test.get_getrawtransaction_data(config.TEMP_DB, txid)
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


    monkeypatch.setattr('bitcoin.rpc.Proxy', RpcProxy)
