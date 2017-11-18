"""
This module contains a variety of utility functions used in the test suite.
"""

import os
import sys
import hashlib
import time
import decimal
import logging
import locale
import re
import io
import difflib
import json
import tempfile
import pprint
import apsw
import pytest
import binascii
import appdirs
import pycoin
from pycoin.tx import Tx
import bitcoin as bitcoinlib
logger = logging.getLogger(__name__)

CURR_DIR = os.path.dirname(os.path.realpath(os.path.join(os.getcwd(), os.path.expanduser(__file__))))
sys.path.append(os.path.normpath(os.path.join(CURR_DIR, '..')))

from counterpartylib import server
from counterpartylib.lib import (config, util, blocks, check, backend, database, transaction)
from counterpartylib.lib.backend.addrindex import extract_addresses, extract_addresses_from_txlist

from counterpartylib.test.fixtures.params import DEFAULT_PARAMS as DP
from counterpartylib.test.fixtures.scenarios import UNITTEST_FIXTURE, INTEGRATION_SCENARIOS, standard_scenarios_params

D = decimal.Decimal

# Set test environment
os.environ['TZ'] = 'EST'
time.tzset()
locale.setlocale(locale.LC_ALL, 'en_US.UTF-8')

# TODO: This should grab the correct backend port and password, when used for, e.g., saverawtransactions.
COUNTERPARTYD_OPTIONS = {
    'testcoin': False,
    'rpc_port': 9999,
    'rpc_password': 'pass',
    'backend_port': 18332,
    'backend_password': 'pass',
    'backend_ssl_no_verify': True,
    'p2sh_dust_return_pubkey': '11' * 33,
    'utxo_locks_max_addresses': 0,  # Disable UTXO locking for base test suite runs
    'estimate_fee_per_kb': False
}

# used for mocking the UTXO in various places, is automatically reset every test case
MOCK_UTXO_SET = None


def init_database(sqlfile, dbfile, options=None):
    kwargs = COUNTERPARTYD_OPTIONS.copy()
    kwargs.update(options or {})

    server.initialise(
        database_file=dbfile,
        testnet=True,
        verbose=True,
        console_logfilter=os.environ.get('COUNTERPARTY_LOGGING', None),
        **kwargs)

    restore_database(config.DATABASE, sqlfile)
    db = database.get_connection(read_only=False)  # reinit the DB to deal with the restoring
    database.update_version(db)
    util.FIRST_MULTISIG_BLOCK_TESTNET = 1

    return db


def reset_current_block_index(db):
    cursor = db.cursor()
    latest_block = list(cursor.execute('''SELECT * FROM blocks ORDER BY block_index DESC LIMIT 1'''))[0]
    util.CURRENT_BLOCK_INDEX = latest_block['block_index']
    cursor.close()

    return util.CURRENT_BLOCK_INDEX


def dump_database(db):
    """Create a new database dump from db object as input."""
    # TEMPORARY
    # .dump command bugs when aspw.Shell is used with 'db' args instead 'args'
    # but this way stay 20x faster than running scenario with file db
    db_filename = tempfile.gettempdir() + '/tmpforbackup.db'
    remove_database_files(db_filename)
    filecon = apsw.Connection(db_filename)
    with filecon.backup("main", db, "main") as backup:
        backup.step()

    output = io.StringIO()
    shell = apsw.Shell(stdout=output, args=(db_filename,))
    #shell = apsw.Shell(stdout=output, db=db)
    shell.process_command(".dump")
    lines = output.getvalue().split('\n')[8:]
    new_data = '\n'.join(lines)
    #clean ; in new line
    new_data = re.sub('\)[\n\s]+;', ');', new_data)
    # apsw oddness: follwing sentence not always generated!
    new_data = new_data.replace('-- The values of various per-database settings\n', '')

    remove_database_files(db_filename)

    return new_data

def restore_database(database_filename, dump_filename):
    """Delete database dump, then opens another and loads it in-place."""
    remove_database_files(database_filename)
    db = apsw.Connection(database_filename)
    cursor = db.cursor()
    with open(dump_filename, 'r') as sql_dump:
        cursor.execute(sql_dump.read())
    cursor.close()

def remove_database_files(database_filename):
    """Delete temporary db dumps."""
    for path in [database_filename, '{}-shm'.format(database_filename), '{}-wal'.format(database_filename)]:
        if os.path.isfile(path):
            os.remove(path)


def insert_block(db, block_index, parse_block=True):
    """Add blocks to the blockchain."""
    cursor = db.cursor()
    block_hash = util.dhash_string(chr(block_index))
    block_time = block_index * 1000
    block = (block_index, block_hash, block_time, None, None, None, None)
    cursor.execute('''INSERT INTO blocks (block_index, block_hash, block_time, ledger_hash, txlist_hash, previous_block_hash, difficulty)
                      VALUES (?,?,?,?,?,?,?)''', block)
    util.CURRENT_BLOCK_INDEX = block_index  # TODO: Correct?!
    cursor.close()

    if parse_block:
        blocks.parse_block(db, block_index, block_time)

    MOCK_UTXO_SET.increment_confirmations()

    return block_index, block_hash, block_time


def create_next_block(db, block_index=None, parse_block=True):
    """Create faux data for the next block."""

    cursor = db.cursor()
    last_block_index = list(cursor.execute("SELECT block_index FROM blocks ORDER BY block_index DESC LIMIT 1"))[0]['block_index']
    if not block_index:
        block_index = last_block_index + 1

    if last_block_index >= block_index:
        raise Exception("create_next_block called with height lower than current height")

    for index in range(last_block_index + 1, block_index + 1):
        inserted_block_index, block_hash, block_time = insert_block(db, index, parse_block=parse_block)

    cursor.close()
    return inserted_block_index, block_hash, block_time


def insert_raw_transaction(raw_transaction, db):
    """Add a raw transaction to the database."""
    cursor = db.cursor()

    # one transaction per block
    block_index, block_hash, block_time = create_next_block(db, parse_block=False)

    tx_hash = dummy_tx_hash(raw_transaction)
    tx_index = block_index - config.BURN_START + 1

    source, destination, btc_amount, fee, data = blocks._get_tx_info(raw_transaction)
    transaction = (tx_index, tx_hash, block_index, block_hash, block_time, source, destination, btc_amount, fee, data, True)
    cursor.execute('''INSERT INTO transactions VALUES (?,?,?,?,?,?,?,?,?,?,?)''', transaction)
    tx = list(cursor.execute('''SELECT * FROM transactions WHERE tx_index = ?''', (tx_index,)))[0]
    cursor.close()

    MOCK_UTXO_SET.add_raw_transaction(raw_transaction, tx_id=tx_hash, confirmations=1)

    util.CURRENT_BLOCK_INDEX = block_index
    blocks.parse_block(db, block_index, block_time)
    return tx


def insert_unconfirmed_raw_transaction(raw_transaction, db):
    """Add a raw transaction to the database."""
    # one transaction per block
    cursor = db.cursor()

    tx_hash = dummy_tx_hash(raw_transaction)

    # this isn't really correct, but it will do
    tx_index = list(cursor.execute('''SELECT tx_index FROM transactions ORDER BY tx_index DESC LIMIT 1'''))
    tx_index = tx_index[0]['tx_index'] if len(tx_index) else 0
    tx_index = tx_index + 1

    source, destination, btc_amount, fee, data = blocks._get_tx_info(raw_transaction)
    tx = {
        'tx_index': tx_index,
        'tx_hash': tx_hash,
        'block_index': config.MEMPOOL_BLOCK_INDEX,
        'block_hash': config.MEMPOOL_BLOCK_HASH,
        'block_time': int(time.time()),
        'source': source,
        'destination': destination,
        'btc_amount': btc_amount,
        'fee': fee,
        'data': data,
        'supported': True
    }

    cursor.close()

    MOCK_UTXO_SET.add_raw_transaction(raw_transaction, tx_id=tx_hash, confirmations=0)

    return tx


UNIQUE_DUMMY_TX_HASH = {}
def dummy_tx_hash(raw_transaction):
    global UNIQUE_DUMMY_TX_HASH

    tx = pycoin.tx.Tx.from_hex(raw_transaction)

    # normalize inputs
    for txin in tx.txs_in:
        txin.previous_hash = b'\x00' * 32
        txin.previous_index = 0
        txin.script = b'\x00'

    # check if we have a change output
    if tx.txs_out[-1].coin_value not in [0, config.DEFAULT_REGULAR_DUST_SIZE, config.DEFAULT_MULTISIG_DUST_SIZE, config.DEFAULT_OP_RETURN_VALUE]:
        tx.txs_out[-1].coin_value = 0  # set change to 0

    tx_id = tx.id()

    # check we haven't created this before (if we do 2 exactly the sends for example)
    if tx_id in UNIQUE_DUMMY_TX_HASH:
        logger.warn('BUMP TXID %s' % tx_id)
        UNIQUE_DUMMY_TX_HASH[tx_id] += 1
        tx_id = hashlib.sha256('{}{}'.format(tx_id, UNIQUE_DUMMY_TX_HASH[tx_id]).encode('utf-8')).hexdigest()
    else:
        UNIQUE_DUMMY_TX_HASH[tx_id] = 0

    return tx_id


def insert_transaction(transaction, db):
    """Add a transaction to the database."""

    cursor = db.cursor()
    block = (transaction['block_index'], transaction['block_hash'], transaction['block_time'], None, None, None, None)
    cursor.execute('''INSERT INTO blocks (block_index, block_hash, block_time, ledger_hash, txlist_hash, previous_block_hash, difficulty)
                      VALUES (?,?,?,?,?,?,?)''', block)
    keys = ",".join(transaction.keys())
    cursor.execute('''INSERT INTO transactions ({}) VALUES (?,?,?,?,?,?,?,?,?,?,?)'''.format(keys), tuple(transaction.values()))
    cursor.close()
    util.CURRENT_BLOCK_INDEX = transaction['block_index']


def initialise_rawtransactions_db(db):
    prefill_rawtransactions_db(db)


def prefill_rawtransactions_db(db):
    """Drop old raw transaction table, create new one and populate it from unspent_outputs.json."""
    cursor = db.cursor()
    cursor.execute('DROP TABLE IF EXISTS raw_transactions')
    cursor.execute('CREATE TABLE IF NOT EXISTS raw_transactions(tx_hash TEXT UNIQUE, tx_hex TEXT, confirmations INT)')
    with open(CURR_DIR + '/fixtures/unspent_outputs.json', 'r') as listunspent_test_file:
            wallet_unspent = json.load(listunspent_test_file)
            for output in wallet_unspent:
                txid = output['txid']
                tx = backend.deserialize(output['txhex'])
                cursor.execute('INSERT INTO raw_transactions VALUES (?, ?, ?)', (txid, output['txhex'], output['confirmations']))
    cursor.close()


def save_rawtransaction(db, txid, tx_hex, confirmations=0):
    """Insert the raw transaction into the db."""
    cursor = db.cursor()
    try:
        if isinstance(txid, bytes):
            txid = binascii.hexlify(txid).decode('ascii')
        cursor.execute('''INSERT INTO raw_transactions VALUES (?, ?, ?)''', (txid, tx_hex, confirmations))
    except Exception as e: # TODO
        pass
    cursor.close()


def getrawtransaction(db, txid, verbose=False):
    """
    Return raw transactions with specific hash.

    When verbose=True we mock the bitcoind RPC response, it's incomplete atm and only mocks what we need
     if more stuff is needed, add it ..
    """
    cursor = db.cursor()

    if isinstance(txid, bytes):
        txid = binascii.hexlify(txid).decode('ascii')

    tx_hex, confirmations = list(cursor.execute('''SELECT tx_hex, confirmations FROM raw_transactions WHERE tx_hash = ?''', (txid,)))[0]
    cursor.close()

    if verbose:
        return mock_bitcoind_verbose_tx_output(tx_hex, txid, confirmations)
    else:
        return tx_hex


def mock_bitcoind_verbose_tx_output(tx, txid, confirmations):
    if isinstance(tx, bitcoinlib.core.CTransaction):
        ctx = tx
    else:
        if not isinstance(tx, bytes):
            tx = binascii.unhexlify(tx)
        ctx = bitcoinlib.core.CTransaction.deserialize(tx)

    result = {
        'version': ctx.nVersion,
        'locktime': ctx.nLockTime,
        'txid': txid,  # bitcoinlib.core.b2lx(ctx.GetHash()),
        'hex': binascii.hexlify(ctx.serialize()).decode('ascii'),
        'size': len(ctx.serialize()),
        'confirmations': confirmations,
        'vin': [],
        'vout': [],

        # not mocked yet
        'time': None,
        'blockhash': None,
        'blocktime': None,
    }

    for vin in ctx.vin:
        asm = list(map(lambda op: binascii.hexlify(op).decode('ascii') if isinstance(op, bytes) else str(op), list(vin.scriptSig)))
        rvin = {
            'txid': bitcoinlib.core.b2lx(vin.prevout.hash),
            'vout': vin.prevout.n,
            'scriptSig': {
                'hex': binascii.hexlify(vin.scriptSig).decode('ascii'),
                'asm': " ".join(asm),
            },
            'sequence': vin.nSequence
        }

        # result['vin'].append(rvin)

    for idx, vout in enumerate(ctx.vout):
        if list(vout.scriptPubKey)[-1] == bitcoinlib.core.script.OP_CHECKMULTISIG:
           pubkeys = list(vout.scriptPubKey)[1:-2]
           addresses = []
           for pubkey in pubkeys:
               addr = str(bitcoinlib.wallet.P2PKHBitcoinAddress.from_pubkey(pubkey))

               addresses.append(addr)
        else:
            try:
                addresses = [str(bitcoinlib.wallet.CBitcoinAddress.from_scriptPubKey(vout.scriptPubKey))]
            except bitcoinlib.wallet.CBitcoinAddressError:
                addresses = []

        asm = list(map(lambda op: binascii.hexlify(op).decode('ascii') if isinstance(op, bytes) else str(op), list(vout.scriptPubKey)))

        type = 'unknown'
        if vout.scriptPubKey[-1] == bitcoinlib.core.script.OP_CHECKMULTISIG:
            type = 'multisig'
        elif len(list(vout.scriptPubKey)) == 5 and \
                        vout.scriptPubKey[1] == bitcoinlib.core.script.OP_HASH160 and \
                        vout.scriptPubKey[-2] == bitcoinlib.core.script.OP_EQUALVERIFY and \
                        vout.scriptPubKey[-1] == bitcoinlib.core.script.OP_CHECKSIG:
            type = 'pubkeyhash'

        rvout = {
            'n': idx,
            'value': vout.nValue / config.UNIT,
            'scriptPubKey': {
                'type': type,
                'addresses': addresses,
                'hex': binascii.hexlify(vout.scriptPubKey).decode('ascii'),
                'asm': " ".join(asm),
            }
        }

        result['vout'].append(rvout)

    return result


def getrawtransaction_batch(db, txhash_list, verbose=False):
    result = {}
    for txhash in txhash_list:
        result[txhash] = getrawtransaction(db, txhash, verbose=verbose)

    return result


def searchrawtransactions(db, address, unconfirmed=False):
    cursor = db.cursor()

    try:
        all_tx_hashes = list(map(lambda r: r[0], cursor.execute('''SELECT tx_hash FROM raw_transactions WHERE confirmations >= ?''', (0 if unconfirmed else 1, ))))

        tx_hashes_tx = getrawtransaction_batch(db, all_tx_hashes, verbose=True)

        def _getrawtransaction_batch(txhash_list, verbose=False):
            return getrawtransaction_batch(db, txhash_list, verbose)

        tx_hashes_addresses, tx_hashes_tx = extract_addresses_from_txlist(tx_hashes_tx, _getrawtransaction_batch)

        reverse_tx_map = {}
        tx_map = {}

        # add txs to cache and reverse cache
        for tx_hash, addresses in tx_hashes_addresses.items():
            reverse_tx_map.setdefault(tx_hash, set())

            for _address in addresses:
                tx_map.setdefault(_address, set())
                tx_map[_address].add(tx_hash)
                reverse_tx_map[tx_hash].add(_address)

        tx_hashes = tx_map.get(address, set())

        if len(tx_hashes):
            return sorted(getrawtransaction_batch(db, tx_hashes, verbose=True).values(), key=lambda tx: (tx['confirmations'], tx['txid']))
        else:
            return []
    finally:
        cursor.close()


def initialise_db(db):
    """Initialise blockchain in the db and insert first block."""
    blocks.initialise(db)
    insert_block(db, config.BLOCK_FIRST - 1, parse_block=True)

def run_scenario(scenario):
    """Execute a scenario for integration test, returns a dump of the db, a json with raw transactions and the full log."""
    server.initialise(database_file=':memory:', testnet=True, **COUNTERPARTYD_OPTIONS)
    config.PREFIX = b'TESTXXXX'
    util.FIRST_MULTISIG_BLOCK_TESTNET = 1
    checkpoints = dict(check.CHECKPOINTS_TESTNET)
    check.CHECKPOINTS_TESTNET = {}

    logger = logging.getLogger()
    logger.setLevel(logging.DEBUG)
    logger_buff = io.StringIO()
    handler = logging.StreamHandler(logger_buff)
    handler.setLevel(logging.DEBUG)
    formatter = logging.Formatter('%(message)s')
    handler.setFormatter(formatter)
    logger.addHandler(handler)
    requests_log = logging.getLogger("requests")
    requests_log.setLevel(logging.WARNING)
    asyncio_log = logging.getLogger('asyncio')
    asyncio_log.setLevel(logging.ERROR)

    db = database.get_connection(read_only=False)
    initialise_db(db)

    raw_transactions = []
    for tx in scenario:
        if tx[0] != 'create_next_block':
            mock_protocol_changes = tx[3] if len(tx) == 4 else {}
            with MockProtocolChangesContext(**(mock_protocol_changes or {})):
                module = sys.modules['counterpartylib.lib.messages.{}'.format(tx[0])]
                compose = getattr(module, 'compose')
                unsigned_tx_hex = transaction.construct(db, compose(db, *tx[1]), **tx[2])
                raw_transactions.append({tx[0]: unsigned_tx_hex})
                insert_raw_transaction(unsigned_tx_hex, db)
        else:
            create_next_block(db, block_index=config.BURN_START + tx[1], parse_block=tx[2] if len(tx) == 3 else True)

    dump = dump_database(db)
    log = logger_buff.getvalue()

    db.close()
    check.CHECKPOINTS_TESTNET = checkpoints
    return dump, log, json.dumps(raw_transactions, indent=4)

def save_scenario(scenario_name):
    """Save currently run scenario's output for comparison with the expected outputs."""
    dump, log, raw_transactions = run_scenario(INTEGRATION_SCENARIOS[scenario_name][0])

    save_scenario_output(scenario_name, dump, log, raw_transactions)

def save_scenario_output(scenario_name, dump, log, raw_transactions):
    with open(CURR_DIR + '/fixtures/scenarios/' + scenario_name + '.new.sql', 'w') as f:
        f.writelines(dump)
    with open(CURR_DIR + '/fixtures/scenarios/' + scenario_name + '.new.log', 'w') as f:
        f.writelines(log)
    with open(CURR_DIR + '/fixtures/scenarios/' + scenario_name + '.new.json', 'w') as f:
        f.writelines(raw_transactions)

def load_scenario_ouput(scenario_name):
    """Read and return the current log output."""
    with open(CURR_DIR + '/fixtures/scenarios/' + scenario_name + '.sql', 'r') as f:
        dump = ("").join(f.readlines())
    with open(CURR_DIR + '/fixtures/scenarios/' + scenario_name + '.log', 'r') as f:
        log = ("").join(f.readlines())
    with open(CURR_DIR + '/fixtures/scenarios/' + scenario_name + '.json', 'r') as f:
        raw_transactions = ("").join(f.readlines())
    return dump, log, raw_transactions

def clean_scenario_dump(scenario_name, dump):
    """Replace addresses and hashes to compare a scenario with its base scenario."""
    dump = dump.replace(standard_scenarios_params[scenario_name]['address1'], 'address1')
    dump = dump.replace(standard_scenarios_params[scenario_name]['address2'], 'address2')
    dump = re.sub('[a-f0-9]{64}', 'hash', dump)
    dump = re.sub('X\'[A-F0-9]+\',1\);', '\'data\',1);', dump)
    # ignore fee values by replacing them with 10000 satoshis
    dump = re.sub(',\d+,\'data\',1\);', ',10000,\'data\',1);', dump)
    dump = re.sub(',\d+,X\'\',1\);', ',10000,\'data\',1);', dump)
    # ignore dust value by replacing them with 0 satoshis
    dump = re.sub(',7800,(\d+),\'data\',1\);', ',0,\1,\'data\',1);', dump)
    dump = re.sub(',5430,(\d+),\'data\',1\);', ',0,\1,\'data\',1);', dump)

    return dump

def check_record(record, server_db):
    """Allow direct record access to the db."""
    cursor = server_db.cursor()

    if record['table'] == 'pragma':
        field = record['field']
        sql = '''PRAGMA {}'''.format(field)
        value = cursor.execute(sql).fetchall()[0][field]
        assert value == record['value']
    else:
        sql = '''SELECT COUNT(*) AS c FROM {} '''.format(record['table'])
        sql += '''WHERE '''
        bindings = []
        conditions = []
        for field in record['values']:
            if record['values'][field] is not None:
                conditions.append('''{} = ?'''.format(field))
                bindings.append(record['values'][field])
        sql += " AND ".join(conditions)

        count = list(cursor.execute(sql, tuple(bindings)))[0]['c']
        ok = (record.get('not', False) and count == 0) or count == 1

        if not ok:
            if pytest.config.getoption('verbose') >= 2:
                print("expected values: ")
                pprint.PrettyPrinter(indent=4).pprint(record['values'])
                print("SELECT * FROM {} WHERE block_index = {}: ".format(record['table'], record['values']['block_index']))
                pprint.PrettyPrinter(indent=4).pprint(list(cursor.execute('''SELECT * FROM {} WHERE block_index = ?'''.format(record['table']), (record['values']['block_index'],))))

            raise AssertionError("check_record \n" +
                                 "table=" + record['table'] + " \n" +
                                 "conditions=" + ",".join(conditions) + " \n" +
                                 "bindings=" + ",".join(map(lambda v: str(v), bindings)))

def vector_to_args(vector, functions=[]):
    """Translate from UNITTEST_VECTOR style to function arguments."""
    args = []
    for tx_name in sorted(vector.keys()):
        for method in sorted(vector[tx_name].keys()):
            for params in vector[tx_name][method]:
                error = params.get('error', None)
                outputs = params.get('out', None)
                records = params.get('records', None)
                comment = params.get('comment', None)
                mock_protocol_changes = params.get('mock_protocol_changes', None)
                if functions == [] or (tx_name + '.' + method) in functions:
                    args.append((tx_name, method, params['in'], outputs, error, records, comment, mock_protocol_changes))
    return args

def exec_tested_method(tx_name, method, tested_method, inputs, server_db):
    """Execute tested_method within context and arguments."""
    if tx_name == 'transaction' and method == 'construct':
        return tested_method(server_db, inputs[0], **inputs[1])
    elif (tx_name == 'util' and (method in ['api','date_passed','price','generate_asset_id','generate_asset_name','dhash_string','enabled','get_url','hexlify','parse_subasset_from_asset_name','compact_subasset_longname','expand_subasset_longname',])) \
        or tx_name == 'script' \
        or (tx_name == 'blocks' and (method[:len('get_tx_info')] == 'get_tx_info')) or tx_name == 'transaction' or method == 'sortkeypicker' \
        or tx_name == 'backend' \
        or tx_name == 'message_type' \
        or tx_name == 'address':
        return tested_method(*inputs)
    else:
        if isinstance(inputs, dict):
            return tested_method(server_db, **inputs)
        else:
            return tested_method(server_db, *inputs)

def check_outputs(tx_name, method, inputs, outputs, error, records, comment, mock_protocol_changes, server_db):
    """Check actual and expected outputs of a particular function."""

    try:
        tested_module = sys.modules['counterpartylib.lib.{}'.format(tx_name)]
    except KeyError:    # TODO: hack
        tested_module = sys.modules['counterpartylib.lib.messages.{}'.format(tx_name)]
    tested_method = getattr(tested_module, method)

    with MockProtocolChangesContext(**(mock_protocol_changes or {})):
        test_outputs = None
        if error is not None:
            with pytest.raises(error[0]) as exception:
                test_outputs = exec_tested_method(tx_name, method, tested_method, inputs, server_db)
        else:
            test_outputs = exec_tested_method(tx_name, method, tested_method, inputs, server_db)
            if pytest.config.option.gentxhex and method == 'compose':
                print('')
                tx_params = {
                    'encoding': 'multisig'
                }
                if tx_name == 'order' and inputs[1] == config.BTC:
                    print('give btc')
                    tx_params['fee_provided'] = DP['fee_provided']
                unsigned_tx_hex = transaction.construct(server_db, test_outputs, **tx_params)
                print(tx_name)
                print(unsigned_tx_hex)

        if outputs is not None:
            try:
                assert outputs == test_outputs
            except AssertionError:
                if pytest.config.getoption('verbose') >= 2:
                    msg = "expected outputs don't match test_outputs:\noutputs=\n" + pprint.pformat(outputs) + "\ntest_outputs=\n" + pprint.pformat(test_outputs)
                else:
                    msg = "expected outputs don't match test_outputs: outputs=%s test_outputs=%s" % (outputs, test_outputs)
                raise Exception(msg)
        if error is not None:
            assert str(exception.value) == error[1]
        if records is not None:
            for record in records:
                check_record(record, server_db)


def compare_strings(string1, string2):
    """Compare strings diff-style."""
    diff = list(difflib.unified_diff(string1.splitlines(1), string2.splitlines(1), n=0))
    if len(diff):
        print("\nDifferences:")
        print("\n".join(diff))
    return len(diff)

def get_block_ledger(db, block_index):
    """Return the block's ledger."""
    cursor = db.cursor()
    debits = list(cursor.execute('''SELECT * FROM debits WHERE block_index = ?''', (block_index,)))
    credits = list(cursor.execute('''SELECT * FROM credits WHERE block_index = ?''', (block_index,)))
    debits = [json.dumps(m).replace('"', '\'') for m in debits]
    credits = [json.dumps(m).replace('"', '\'') for m in credits]
    ledger = json.dumps(debits + credits, indent=4)
    return ledger

def get_block_txlist(db, block_index):
    """Return block's transaction list."""
    cursor = db.cursor()
    txlist = list(cursor.execute('''SELECT * FROM transactions WHERE block_index = ?''', (block_index,)))
    txlist = [json.dumps(m).replace('"', '\'') for m in txlist]
    txlist = json.dumps(txlist, indent=4)
    return txlist

def reparse(testnet=True):
    """Reparse all transaction from the database, create a new blockchain and compare it to the old one."""
    options = dict(COUNTERPARTYD_OPTIONS)
    server.initialise(database_file=':memory:', testnet=testnet, **options)

    logger = logging.getLogger()

    if testnet:
        config.PREFIX = b'TESTXXXX'

    memory_db = database.get_connection(read_only=False)
    initialise_db(memory_db)

    data_dir = appdirs.user_data_dir(appauthor=config.XCP_NAME, appname=config.APP_NAME, roaming=True)
    prod_db_path = os.path.join(data_dir, '{}{}.db'.format(config.APP_NAME, '.testnet' if testnet else ''))
    assert os.path.exists(prod_db_path), "database path {} does not exist".format(prod_db_path)
    prod_db = apsw.Connection(prod_db_path)
    prod_db.setrowtrace(database.rowtracer)

    with memory_db.backup("main", prod_db, "main") as backup:
        backup.step()

    # Here we don’t use block.reparse() because it reparse db in transaction (`with db`).
    memory_cursor = memory_db.cursor()
    for table in blocks.TABLES + ['balances']:
        memory_cursor.execute('''DROP TABLE IF EXISTS {}'''.format(table))

    # Check that all checkpoint blocks are in the database to be tested.
    if testnet:
        CHECKPOINTS = check.CHECKPOINTS_TESTNET
    else:
        CHECKPOINTS = check.CHECKPOINTS_MAINNET
    for block_index in CHECKPOINTS.keys():
        block_exists = bool(list(memory_cursor.execute('''SELECT * FROM blocks WHERE block_index = ?''', (block_index,))))
        assert block_exists, "block #%d does not exist" % block_index

    # Clean consensus hashes if first block hash don’t match with checkpoint.
    checkpoints = check.CHECKPOINTS_TESTNET if config.TESTNET else check.CHECKPOINTS_MAINNET
    columns = [column['name'] for column in memory_cursor.execute('''PRAGMA table_info(blocks)''')]
    for field in ['ledger_hash', 'txlist_hash']:
        if field in columns:
            sql = '''SELECT {} FROM blocks  WHERE block_index = ?'''.format(field)
            first_hash = list(memory_cursor.execute(sql, (config.BLOCK_FIRST,)))[0][field]
            if first_hash != checkpoints[config.BLOCK_FIRST][field]:
                logger.info('First hash changed. Cleaning {}.'.format(field))
                memory_cursor.execute('''UPDATE blocks SET {} = NULL'''.format(field))

    blocks.initialise(memory_db)
    previous_ledger_hash = None
    previous_txlist_hash = None
    previous_messages_hash = None

    memory_cursor.execute('''SELECT * FROM blocks ORDER BY block_index''')
    for block in memory_cursor.fetchall():
        try:
            util.CURRENT_BLOCK_INDEX = block['block_index']
            previous_ledger_hash, previous_txlist_hash, previous_messages_hash, previous_found_messages_hash = blocks.parse_block(
                                                                     memory_db, block['block_index'], block['block_time'],
                                                                     previous_ledger_hash=previous_ledger_hash, ledger_hash=block['ledger_hash'],
                                                                     previous_txlist_hash=previous_txlist_hash, txlist_hash=block['txlist_hash'],
                                                                     previous_messages_hash=previous_messages_hash)
            logger.info('Block (re-parse): %s (hashes: L:%s / TX:%s / M:%s%s)' % (
                block['block_index'], previous_ledger_hash[-5:], previous_txlist_hash[-5:], previous_messages_hash[-5:],
                (' [overwrote %s]' % previous_found_messages_hash) if previous_found_messages_hash and previous_found_messages_hash != previous_messages_hash else ''))

        except check.ConsensusError as e:
            message = str(e)
            if message.find('ledger_hash') != -1:
                new_ledger = get_block_ledger(memory_db, block['block_index'])
                old_ledger = get_block_ledger(prod_db, block['block_index'])
                compare_strings(old_ledger, new_ledger)
            elif message.find('txlist_hash') != -1:
                new_txlist = get_block_txlist(memory_db, block['block_index'])
                old_txlist = get_block_txlist(prod_db, block['block_index'])
                compare_strings(old_txlist, new_txlist)
            raise(e)


class ConfigContext(object):
    def __init__(self, **kwargs):
        self.config = config
        self._extend = kwargs
        self._before = {}
        self._before_empty = []

    def __enter__(self):
        self._before = {}
        for k in self._extend:
            if k in vars(self.config):
                self._before[k] = vars(self.config)[k]
            else:
                self._before_empty.append(k)

            vars(self.config)[k] = self._extend[k]

    def __exit__(self, exc_type, exc_val, exc_tb):
        for k in self._before:
            vars(self.config)[k] = self._before[k]
        for k in self._before_empty:
            del vars(self.config)[k]


class MockProtocolChangesContext(object):
    def __init__(self, **kwargs):
        from counterpartylib.test.conftest import MOCK_PROTOCOL_CHANGES
        self.mock_protocol_changes = MOCK_PROTOCOL_CHANGES
        self._extend = kwargs
        self._before = {}
        self._before_empty = []

    def __enter__(self):
        self._before = {}
        for k in self._extend:
            if k in self.mock_protocol_changes:
                self._before[k] = self.mock_protocol_changes[k]
            else:
                self._before_empty.append(k)

            self.mock_protocol_changes[k] = self._extend[k]

    def __exit__(self, exc_type, exc_val, exc_tb):
        for k in self._before:
            self.mock_protocol_changes[k] = self._before[k]
        for k in self._before_empty:
            del self.mock_protocol_changes[k]
