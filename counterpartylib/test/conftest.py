"""
Test suite configuration
"""

import json
import apsw
import time
import os
from datetime import datetime
import pytest
import bitcoin as bitcoinlib
import pycoin
from pycoin.tx import Tx
import pprint
import binascii
import logging
from Crypto.Cipher import ARC4

logger = logging.getLogger()

from counterpartylib.lib import log
log.set_logger(logger)

from counterpartylib.test import util_test
from counterpartylib.test.fixtures.vectors import UNITTEST_VECTOR
from counterpartylib.test.fixtures.params import DEFAULT_PARAMS
from counterpartylib.test.fixtures.scenarios import INTEGRATION_SCENARIOS

from counterpartylib.lib import config, util, database, api, script


# we swap out util.enabled with a custom one which has the option to mock the protocol changes
MOCK_PROTOCOL_CHANGES = {}
ALWAYS_LATEST_PROTOCOL_CHANGES = False
_enabled = util.enabled
def enabled(change_name, block_index=None):
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
    parser.addoption("--alternative", action='store_true', default=False)
    parser.addoption("--skiptestbook", default='no', help="skip test book(s) (use with one of the following values: `all`, `testnet` or `mainnet`)")
    parser.addoption("--verbosediff", action='store_true', default=False, help="print verbose diff for vectors that fail")


@pytest.fixture(scope="function")
def rawtransactions_db(request):
    """Return a database object."""
    db = apsw.Connection(':memory:')
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
            time.sleep(0.5)  # extra time window
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


class MockUTXOSet(object):
    """
    :type utxos list UTXOs list containing:
                        { 'address': 'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',
                          'amount': 1.9990914,
                          'confirmations': 74,
                          'scriptPubKey': '76a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788ac',
                          'txhex': '0100000002eff195acdf2bbd215daa8aca24eb667b563a731d34a9ab75c8d8df5df08be29b000000006c493046022100ec6fa8316a4f5cfd69816e31011022acce0933bd3b01248caa8b49e60de1b98a022100987ba974b2a4f9976a8d61d94009cb7f7986a827dc5730e999de1fb748d2046c01210282b886c087eb37dc8182f14ba6cc3e9485ed618b95804d44aecc17c300b585b0ffffffffeff195acdf2bbd215daa8aca24eb667b563a731d34a9ab75c8d8df5df08be29b010000006a47304402201f8fb2d62df22592cb8d37c68ab26563dbb8e270f7f8409ac0f6d7b24ddb5c940220314e5c767fd12b20116528c028eab2bfbad30eb963bd849993410049cf14a83d01210282b886c087eb37dc8182f14ba6cc3e9485ed618b95804d44aecc17c300b585b0ffffffff02145fea0b000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788ac0000000000000000346a32544553540000000a00000000000000010000000005f5e1000000000000000000000000000bebc2000032000000000000271000000000',
                          'txid': 'ae241be7be83ebb14902757ad94854f787d9730fc553d6f695346c9375c0d8c1',
                          'vout': 0}
    """
    utxos = []

    def __init__(self, utxos, rawtransactions_db):
        self.txouts = utxos or []
        self.spent_utxos = []
        self.rawtransactions_db = rawtransactions_db
        # logger.warn('MockUTXOSet %d' % len(utxos))

    def get_unspent_txouts(self, address, unconfirmed=False, multisig_inputs=False, unspent_tx_hash=None):
        # filter by address
        txouts = [output for output in self.txouts if output['address'] == address]

        # filter out the spend outputs
        unspent_txouts = filter(lambda txout: (txout['txid'], txout['vout']) not in self.spent_utxos, txouts)

        if unconfirmed == False:
            unspent_txouts = filter(lambda txout: txout['confirmations'] > 0, unspent_txouts)

        if multisig_inputs:
            raise NotImplementedError("%s" % multisig_inputs)

        if unspent_tx_hash:
            unspent_txouts = filter(lambda txout: txout['txid'] == unspent_tx_hash, unspent_txouts)

        return list(unspent_txouts)

    def update_utxo_set(self, txins, txouts):
        # spent the UTXOs
        for txin in txins:
            self.spent_utxos.append((txin['txid'], txin['vout']))

        for txout in txouts:
            self.txouts.append({
                'address': txout['address'],
                'amount': txout['amount'],
                'confirmations': int(txout['confirmations']),
                'scriptPubKey': txout['scriptPubKey'],
                'txhex': txout['txhex'],
                'txid': txout['txid'],
                'vout': txout['vout'],
            })

    def increment_confirmations(self):
        for utxo in self.txouts:
            utxo['confirmations'] = (utxo['confirmations'] or 0) + 1

    def add_raw_transaction(self, raw_transaction, tx_id=None, confirmations=0):
        tx = pycoin.tx.Tx.from_hex(raw_transaction)
        tx_id = tx_id or tx.id()

        txins = []
        for txin in tx.txs_in:
            txins.append({
                'txid': pycoin.serialize.b2h_rev(txin.previous_hash),
                'vout': txin.previous_index
            })

        txouts = []
        for idx, txout in enumerate(tx.txs_out):
            txouts.append({
                'address': script.scriptpubkey_to_address(bitcoinlib.core.CScript(txout.script)),
                'confirmations': int(confirmations),
                'amount': txout.coin_value / 1e8,
                'scriptPubKey': binascii.hexlify(txout.script).decode('ascii'),
                'txhex': raw_transaction,
                'txid': tx_id,
                'vout': idx
            })

        # logger.warn('add_raw_transaction %d/%d' % (len(txins), len(txouts)))
        # logger.debug(pprint.pformat(txins))
        # logger.debug(pprint.pformat(txouts))

        util_test.save_rawtransaction(self.rawtransactions_db, tx_id, raw_transaction)

        self.update_utxo_set(txins, txouts)


@pytest.fixture(scope='module', autouse=True)
def setup_logging():
    print("")  # for --verbose output this makes sure the logs start on a newline
    log.set_up(log.ROOT_LOGGER, verbose=True, console_logfilter=os.environ.get('COUNTERPARTY_LOGGING', None))


@pytest.fixture(scope='function', autouse=True)
def mock_utxos(rawtransactions_db):
    with open(util_test.CURR_DIR + '/fixtures/unspent_outputs.json', 'r') as listunspent_test_file:
        util_test.MOCK_UTXO_SET = MockUTXOSet(json.load(listunspent_test_file), rawtransactions_db)

    util_test.UNIQUE_DUMMY_TX_HASH = {}
    util_test.TX_INDEX = 1

    return util_test.MOCK_UTXO_SET


@pytest.fixture(scope='function', autouse=True)
def init_mock_functions(monkeypatch, mock_utxos, rawtransactions_db):
    """Test suit mock functions.

    Mock functions override default behaviour to allow test suit to work - for instance, date_passed is overwritten 
    so that every date will pass. Those are available to every test function in this suite."""

    util_test.rawtransactions_db = rawtransactions_db

    def get_unspent_txouts(*args, **kwargs):
        return mock_utxos.get_unspent_txouts(*args, **kwargs)

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

    # mock the arc4 with a fixed seed to keep data from changing based on inputs
    def init_arc4(seed):
        return ARC4.new(binascii.unhexlify("00" * 32))

    monkeypatch.setattr('counterpartylib.lib.transaction.arc4.init_arc4', init_arc4)
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
