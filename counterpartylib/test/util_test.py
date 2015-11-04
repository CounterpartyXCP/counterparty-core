"""
This module contains a variety of utility functions used in the test suite.
"""

import os, sys, hashlib, binascii, time, decimal, logging, locale, re, io
import difflib, json, inspect, tempfile, shutil
import apsw, pytest, requests
from requests.auth import HTTPBasicAuth

CURR_DIR = os.path.dirname(os.path.realpath(os.path.join(os.getcwd(), os.path.expanduser(__file__))))
sys.path.append(os.path.normpath(os.path.join(CURR_DIR, '..')))

import server
from counterpartylib.lib import (config, api, util, exceptions, blocks, check, backend, database, transaction, script)
from counterpartylib.lib.messages import (send, order, btcpay, issuance, broadcast, bet, dividend, burn, cancel, rps, rpsresolve)

from fixtures.params import DEFAULT_PARAMS as DP
from fixtures.scenarios import UNITTEST_FIXTURE, INTEGRATION_SCENARIOS, standard_scenarios_params

import bitcoin as bitcoinlib
import binascii

import appdirs

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
    'backend_ssl_no_verify': True
}

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
    return db

def remove_database_files(database_filename):
    """Delete temporary db dumps."""
    for path in [database_filename, '{}-shm'.format(database_filename), '{}-wal'.format(database_filename)]:
        if os.path.isfile(path):
            os.remove(path)

def insert_block(db, block_index, parse_block=False):
    """Add blocks to the blockchain."""
    cursor = db.cursor()
    block_hash = hashlib.sha512(chr(block_index).encode('utf-8')).hexdigest()
    block_time = block_index * 1000
    block = (block_index, block_hash, block_time, None, None, None, None)
    cursor.execute('''INSERT INTO blocks (block_index, block_hash, block_time, ledger_hash, txlist_hash, previous_block_hash, difficulty) 
                      VALUES (?,?,?,?,?,?,?)''', block)
    util.CURRENT_BLOCK_INDEX = block_index  # TODO: Correct?!
    cursor.close()
    if parse_block:
        blocks.parse_block(db, block_index, block_time)
    return block_index, block_hash, block_time

def create_next_block(db, block_index=None, parse_block=False):
    """Create faux data for the next block."""
    cursor = db.cursor()
    last_block_index = list(cursor.execute("SELECT block_index FROM blocks ORDER BY block_index DESC LIMIT 1"))[0]['block_index']
    if not block_index:
        block_index = last_block_index + 1
    for index in range(last_block_index + 1, block_index + 1):
        inserted_block_index, block_hash, block_time = insert_block(db, index, parse_block=parse_block)
    cursor.close()
    return inserted_block_index, block_hash, block_time

def insert_raw_transaction(raw_transaction, db, rawtransactions_db):
    """Add a raw transaction to the database."""
    # one transaction per block
    block_index, block_hash, block_time = create_next_block(db)

    cursor = db.cursor()
    tx_index = block_index - config.BURN_START + 1

    tx_hash = hashlib.sha256('{}{}'.format(tx_index,raw_transaction).encode('utf-8')).hexdigest()
    # print(tx_hash)
    # Remember to add it to the log dump
    if pytest.config.option.savescenarios:
        save_rawtransaction(rawtransactions_db, tx_hash, raw_transaction)

    source, destination, btc_amount, fee, data = blocks.get_tx_info2(raw_transaction)
    transaction = (tx_index, tx_hash, block_index, block_hash, block_time, source, destination, btc_amount, fee, data, True)
    cursor.execute('''INSERT INTO transactions VALUES (?,?,?,?,?,?,?,?,?,?,?)''', transaction)
    tx = list(cursor.execute('''SELECT * FROM transactions WHERE tx_index = ?''', (tx_index,)))[0]
    cursor.close()

    util.CURRENT_BLOCK_INDEX = block_index  # TODO: Correct?!
    blocks.parse_block(db, block_index, block_time)
    return tx

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
    """Drop old raw transaction table, create new one and populate it from unspent_outputs.json."""
    if pytest.config.option.savescenarios:
        server.initialise(database_file=':memory:', testnet=True, **COUNTERPARTYD_OPTIONS)
        cursor = db.cursor()
        cursor.execute('DROP TABLE  IF EXISTS raw_transactions')
        cursor.execute('CREATE TABLE IF NOT EXISTS raw_transactions(tx_hash TEXT UNIQUE, tx_hex TEXT)')
        with open(CURR_DIR + '/fixtures/unspent_outputs.json', 'r') as listunspent_test_file:
                wallet_unspent = json.load(listunspent_test_file)
                for output in wallet_unspent:
                    txid = binascii.hexlify(bitcoinlib.core.lx(output['txid'])).decode()
                    tx = backend.deserialize(output['txhex'])
                    cursor.execute('INSERT INTO raw_transactions VALUES (?, ?)', (txid, output['txhex']))
        cursor.close()

def save_rawtransaction(db, tx_hash, tx_hex):
    """Insert the raw transaction into the db."""
    cursor = db.cursor()
    try:
        txid = binascii.hexlify(bitcoinlib.core.lx(tx_hash)).decode()
        cursor.execute('''INSERT INTO raw_transactions VALUES (?, ?)''', (txid, tx_hex))
    except Exception as e: # TODO
        pass
    cursor.close()

def getrawtransaction(db, txid):
    """Return raw transactions with specific hash."""
    cursor = db.cursor()
    txid = binascii.hexlify(txid).decode()
    tx_hex = list(cursor.execute('''SELECT tx_hex FROM raw_transactions WHERE tx_hash = ?''', (txid,)))[0][0]
    cursor.close()
    return tx_hex

def initialise_db(db):
    """Initialise blockchain in the db and insert first block."""
    blocks.initialise(db)
    insert_block(db, config.BURN_START - 1)

def run_scenario(scenario, rawtransactions_db):
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
            module = sys.modules['counterpartylib.lib.messages.{}'.format(tx[0])]
            compose = getattr(module, 'compose')
            unsigned_tx_hex = transaction.construct(db, compose(db, *tx[1]), **tx[2])
            raw_transactions.append({tx[0]: unsigned_tx_hex})
            insert_raw_transaction(unsigned_tx_hex, db, rawtransactions_db)
        else:
            create_next_block(db, block_index=config.BURN_START + tx[1], parse_block=True)

    dump = dump_database(db)
    log = logger_buff.getvalue()

    db.close()
    check.CHECKPOINTS_TESTNET = checkpoints
    return dump, log, json.dumps(raw_transactions, indent=4)

def save_scenario(scenario_name, rawtransactions_db):
    """Save currently run scenario's output for comparison with the expected outputs."""
    dump, log, raw_transactions = run_scenario(INTEGRATION_SCENARIOS[scenario_name][0], rawtransactions_db)
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
    dump = re.sub('X\'[A-F0-9]+\',1\);', '\'data\',1)', dump)
    # ignore dust value
    dump = re.sub(',7800,10000,\'data\',1\)', ',0,10000,\'data\',1\)', dump)
    dump = re.sub(',5430,10000,\'data\',1\)', ',0,10000,\'data\',1\)', dump)
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
        sql  = '''SELECT COUNT(*) AS c FROM {} '''.format(record['table'])
        sql += '''WHERE '''
        bindings = []
        conditions = []
        for field in record['values']:
            if record['values'][field] is not None:
                conditions.append('''{} = ?'''.format(field))
                bindings.append(record['values'][field])
        sql += " AND ".join(conditions)

        count = list(cursor.execute(sql, tuple(bindings)))[0]['c']
        if count != 1:
            print(list(cursor.execute('''SELECT * FROM {} WHERE block_index = ?'''.format(record['table']), (record['values']['block_index'],))))
            assert False

def vector_to_args(vector, functions=[]):
    """Translate from UNITTEST_VECTOR style to function arguments."""
    args = []
    for tx_name in vector:
        for method in vector[tx_name]:
            for params in vector[tx_name][method]:
                error = outputs = records = None
                if 'out' in params:
                    outputs = params['out']
                if 'error' in params:
                    error = params['error']
                if 'records' in params:
                    records = params['records']
                if functions == [] or (tx_name + '.' + method) in functions:
                    args.append((tx_name, method, params['in'], outputs, error, records))
    return args

def exec_tested_method(tx_name, method, tested_method, inputs, server_db):
    """Execute tested_method within context and arguments."""
    if tx_name == 'transaction' and method == 'construct':
        return tested_method(server_db, inputs[0], **inputs[1])
    elif (tx_name == 'util' and (method == 'api' or method == 'date_passed' or method == 'price' or method == 'generate_asset_id' \
         or method == 'generate_asset_name' or method == 'dhash_string' or method == 'enabled' or method == 'get_url' or method == 'hexlify')) or tx_name == 'script' \
        or (tx_name == 'blocks' and (method == 'get_tx_info' or method == 'get_tx_info1' or method == 'get_tx_info2')) or tx_name == 'transaction' or method == 'sortkeypicker':
        return tested_method(*inputs)
    else:
        return tested_method(server_db, *inputs)

def check_outputs(tx_name, method, inputs, outputs, error, records, server_db):
    """Check actual and expected outputs of a particular function."""

    try:
        tested_module = sys.modules['counterpartylib.lib.{}'.format(tx_name)]
    except KeyError:    # TODO: hack
        tested_module = sys.modules['counterpartylib.lib.messages.{}'.format(tx_name)]
    tested_method = getattr(tested_module, method)

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
            if tx_name == 'order' and inputs[1]=='BTC':
                print('give btc')
                tx_params['fee_provided'] = DP['fee_provided']
            unsigned_tx_hex = transaction.construct(server_db, test_outputs, **tx_params)
            print(tx_name)
            print(unsigned_tx_hex)

    if outputs is not None:
        try:
            assert outputs == test_outputs
        except AssertionError:
            raise Exception("outputs don't match test_outputs: outputs=%s  ---  test_outputs=%s" % (outputs, test_outputs))
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

    if testnet:
        config.PREFIX = b'TESTXXXX'

    logger = logging.getLogger()
    console = logging.StreamHandler()
    console.setLevel(logging.INFO)
    formatter = logging.Formatter('%(message)s')
    console.setFormatter(formatter)
    logger.addHandler(console)

    memory_db = database.get_connection(read_only=False)
    initialise_db(memory_db)

    data_dir = appdirs.user_data_dir(appauthor=config.XCP_NAME, appname=config.APP_NAME, roaming=True)
    prod_db_path = os.path.join(data_dir, '{}{}.db'.format(config.APP_NAME, '.testnet' if testnet else ''))
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
        assert block_exists

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
