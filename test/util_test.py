import os, sys, hashlib, binascii, time, decimal, logging, locale, re, io
import difflib, json, inspect, tempfile, shutil
import apsw, pytest, requests
from requests.auth import HTTPBasicAuth

CURR_DIR = os.path.dirname(os.path.realpath(os.path.join(os.getcwd(), os.path.expanduser(__file__))))
sys.path.append(os.path.normpath(os.path.join(CURR_DIR, '..')))

from lib import (config, api, util, exceptions, bitcoin, blocks)
from lib import (send, order, btcpay, issuance, broadcast, bet, dividend, burn, cancel, callback, rps, rpsresolve)
from lib.exceptions import ConsensusError
import counterpartyd

from fixtures.params import DEFAULT_PARAMS as DP
from fixtures.scenarios import UNITEST_FIXTURE, INTEGRATION_SCENARIOS, standard_scenarios_params

import bitcoin as bitcoinlib
import binascii

D = decimal.Decimal

# Set test environment
os.environ['TZ'] = 'EST'
time.tzset()
locale.setlocale(locale.LC_ALL, 'en_US.UTF-8')

COUNTERPARTYD_OPTIONS = {
    'testcoin': False, 
    'backend_rpc_ssl_verify': False, 
    'data_dir': tempfile.gettempdir(), 
    'rpc_port': 9999, 
    'rpc_password': 'pass', 
    'backend_rpc_port': 8888, 
    'backend_rpc_password': 'pass'
}

def dump_database(db):
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
    remove_database_files(database_filename)
    db = apsw.Connection(database_filename)
    cursor = db.cursor()
    with open(dump_filename, 'r') as sql_dump:
        cursor.execute(sql_dump.read())
    cursor.close()

def remove_database_files(database_filename):
    for path in [database_filename, '{}-shm'.format(database_filename), '{}-wal'.format(database_filename)]:
        if os.path.isfile(path):
            os.remove(path)

def insert_block(db, block_index, parse_block=False):
    cursor = db.cursor()
    block_hash = hashlib.sha512(chr(block_index).encode('utf-8')).hexdigest()
    block_time = block_index * 10000000
    block = (block_index, block_hash, block_time, None, None)
    cursor.execute('''INSERT INTO blocks VALUES (?,?,?,?,?)''', block)
    cursor.close()
    if parse_block:
        blocks.parse_block(db, block_index, block_time)
    return block_index, block_hash, block_time

def create_next_block(db, block_index=None, parse_block=False):
    cursor = db.cursor()  
    last_block_index = list(cursor.execute("SELECT block_index FROM blocks ORDER BY block_index DESC LIMIT 1"))[0]['block_index']
    if not block_index:
        block_index = last_block_index + 1
    for index in range(last_block_index + 1, block_index + 1):
        inserted_block_index, block_hash, block_time = insert_block(db, index, parse_block=parse_block)
    cursor.close()
    return inserted_block_index, block_hash, block_time

def insert_raw_transaction(raw_transaction, db, rawtransactions_db):
    # one transaction per block
    block_index, block_hash, block_time = create_next_block(db)

    cursor = db.cursor()
    tx_index = block_index - config.BURN_START + 1
    tx = bitcoin.decode_raw_transaction(raw_transaction)
    
    tx_hash = hashlib.sha256('{}{}'.format(tx_index,raw_transaction).encode('utf-8')).hexdigest()
    #print(tx_hash)
    tx['txid'] = tx_hash
    if pytest.config.option.saverawtransactions:
        save_rawtransaction(rawtransactions_db, tx_hash, raw_transaction, json.dumps(tx))

    source, destination, btc_amount, fee, data = blocks.get_tx_info2(tx, block_index)
    transaction = (tx_index, tx_hash, block_index, block_hash, block_time, source, destination, btc_amount, fee, data, True)
    cursor.execute('''INSERT INTO transactions VALUES (?,?,?,?,?,?,?,?,?,?,?)''', transaction)
    tx = list(cursor.execute('''SELECT * FROM transactions WHERE tx_index = ?''', (tx_index,)))[0]
    cursor.close()

    blocks.parse_block(db, block_index, block_time)
    return tx

def insert_transaction(transaction, db):
    cursor = db.cursor()
    block = (transaction['block_index'], transaction['block_hash'], transaction['block_time'], None, None)
    cursor.execute('''INSERT INTO blocks VALUES (?,?,?,?,?)''', block)
    keys = ",".join(transaction.keys())
    cursor.execute('''INSERT INTO transactions ({}) VALUES (?,?,?,?,?,?,?,?,?,?,?)'''.format(keys), tuple(transaction.values()))
    cursor.close()

# table uses for getrawtransaction mock.
# we use the same database (in memory) for speed
def initialise_rawtransactions_db(db):
    if pytest.config.option.initrawtransactions:
        counterpartyd.set_options(testnet=True, **COUNTERPARTYD_OPTIONS)
        cursor = db.cursor()
        cursor.execute('DROP TABLE  IF EXISTS raw_transactions')
        cursor.execute('CREATE TABLE IF NOT EXISTS raw_transactions(tx_hash TEXT UNIQUE, tx_hex TEXT, tx_json TEXT)')
        with open(CURR_DIR + '/fixtures/unspent_outputs.json', 'r') as listunspent_test_file:
                wallet_unspent = json.load(listunspent_test_file)
                for output in wallet_unspent:
                    txid = binascii.hexlify(bitcoinlib.core.lx(output['txid'])).decode()
                    tx = bitcoin.decode_raw_transaction(output['txhex'])
                    cursor.execute('INSERT INTO raw_transactions VALUES (?, ?, ?)', (txid, output['txhex'], json.dumps(tx)))
        cursor.close()

def save_rawtransaction(db, tx_hash, tx_hex, tx_json):
    cursor = db.cursor()
    try:
        txid = binascii.hexlify(bitcoinlib.core.lx(tx_hash)).decode()
        cursor.execute('''INSERT INTO raw_transactions VALUES (?, ?, ?)''', (txid, tx_hex, tx_json))
    except Exception as e:
        pass
    cursor.close()

def getrawtransaction(db, txid):
    cursor = db.cursor()
    txid = binascii.hexlify(txid).decode()
    tx_hex = list(cursor.execute('''SELECT tx_hex FROM raw_transactions WHERE tx_hash = ?''', (txid,)))[0][0]
    cursor.close()
    return tx_hex

def decoderawtransaction(db, tx_hex):
    cursor = db.cursor()
    tx_json = list(cursor.execute('''SELECT tx_json FROM raw_transactions WHERE tx_hex = ?''', (tx_hex,)))[0][0]
    cursor.close()
    return json.loads(tx_json)

def initialise_db(db):
    blocks.initialise(db)
    insert_block(db, config.BURN_START - 1)

def run_scenario(scenario, rawtransactions_db):
    counterpartyd.set_options(database_file=':memory:', testnet=True, **COUNTERPARTYD_OPTIONS)
    config.PREFIX = b'TESTXXXX'
    config.FIRST_MULTISIG_BLOCK_TESTNET = 1
    config.CHECKPOINTS_TESTNET = {}
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

    db = util.connect_to_db()
    initialise_db(db)

    raw_transactions = []
    for transaction in scenario:
        if transaction[0] != 'create_next_block':
            module = sys.modules['lib.{}'.format(transaction[0])]
            compose = getattr(module, 'compose')
            unsigned_tx_hex = bitcoin.transaction(db, compose(db, *transaction[1]), **transaction[2])
            raw_transactions.append({transaction[0]: unsigned_tx_hex})
            insert_raw_transaction(unsigned_tx_hex, db, rawtransactions_db)
        else:
            create_next_block(db, block_index=config.BURN_START + transaction[1], parse_block=True)

    dump = dump_database(db)
    log = logger_buff.getvalue()

    db.close()
    return dump, log, json.dumps(raw_transactions, indent=4)

def save_scenario(scenario_name, rawtransactions_db):
    dump, log, raw_transactions = run_scenario(INTEGRATION_SCENARIOS[scenario_name][0], rawtransactions_db)
    with open(CURR_DIR + '/fixtures/scenarios/' + scenario_name + '.new.sql', 'w') as f:
        f.writelines(dump)
    with open(CURR_DIR + '/fixtures/scenarios/' + scenario_name + '.new.log', 'w') as f:
        f.writelines(log)
    with open(CURR_DIR + '/fixtures/scenarios/' + scenario_name + '.new.json', 'w') as f:
        f.writelines(raw_transactions)

def load_scenario_ouput(scenario_name):
    with open(CURR_DIR + '/fixtures/scenarios/' + scenario_name + '.sql', 'r') as f:
        dump = ("").join(f.readlines())
    with open(CURR_DIR + '/fixtures/scenarios/' + scenario_name + '.log', 'r') as f:
        log = ("").join(f.readlines())
    with open(CURR_DIR + '/fixtures/scenarios/' + scenario_name + '.json', 'r') as f:
        raw_transactions = ("").join(f.readlines())
    return dump, log, raw_transactions

def clean_scenario_dump(scenario_name, dump):
    dump = dump.replace(standard_scenarios_params[scenario_name]['address1'], 'address1')
    dump = dump.replace(standard_scenarios_params[scenario_name]['address2'], 'address2')
    dump = re.sub('[a-f0-9]{64}', 'hash', dump)
    dump = re.sub('X\'[A-F0-9]+\',1\);', '\'data\',1)', dump)
    return dump

def check_record(record, counterpartyd_db):
    cursor = counterpartyd_db.cursor()

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

def exec_tested_method(tx_name, method, tested_method, inputs, counterpartyd_db):
    if tx_name == 'bitcoin' and method == 'transaction':
        return tested_method(counterpartyd_db, inputs[0], **inputs[1])
    elif tx_name == 'util' and method == 'api':
        return tested_method(*inputs)
    elif tx_name == 'bitcoin' and method == 'base58_check_decode':
        return binascii.hexlify(tested_method(*inputs)).decode('utf-8')
    else:
        return tested_method(counterpartyd_db, *inputs)

def check_ouputs(tx_name, method, inputs, outputs, error, records, counterpartyd_db):
    tested_module = sys.modules['lib.{}'.format(tx_name)]
    tested_method = getattr(tested_module, method)
    
    test_outputs = None
    if error is not None:
        with pytest.raises(getattr(exceptions, error[0])) as exception:
            test_outputs = exec_tested_method(tx_name, method, tested_method, inputs, counterpartyd_db)
    else:
        test_outputs = exec_tested_method(tx_name, method, tested_method, inputs, counterpartyd_db)
        if pytest.config.option.gentxhex and method == 'compose':
            print('')
            tx_params = {
                'encoding': 'multisig'
            }
            if tx_name == 'order' and inputs[1]=='BTC':
                print('give btc')
                tx_params['fee_provided'] = DP['fee_provided']
            unsigned_tx_hex = bitcoin.transaction(counterpartyd_db, test_outputs, **tx_params)
            print(tx_name)
            print(unsigned_tx_hex)

    if outputs is not None:
        assert outputs == test_outputs
    if error is not None:
        assert str(exception.value) == error[1]
    if records is not None:
        for record in records:
            check_record(record, counterpartyd_db)

def compare_strings(string1, string2):
    diff = list(difflib.unified_diff(string1.splitlines(1), string2.splitlines(1), n=0))
    if len(diff):
        print("\nDifferences:")
        print("\n".join(diff))
    return len(diff)

def get_block_ledger(db, block_index):
    cursor = db.cursor()
    debits = list(cursor.execute('''SELECT * FROM debits WHERE block_index = ?''', (block_index,)))
    credits = list(cursor.execute('''SELECT * FROM credits WHERE block_index = ?''', (block_index,)))
    debits = [json.dumps(m).replace('"', '\'') for m in debits]
    credits = [json.dumps(m).replace('"', '\'') for m in credits]
    ledger = json.dumps(debits + credits, indent=4)
    return ledger

def get_block_txlist(db, block_index):
    cursor = db.cursor()
    txlist = list(cursor.execute('''SELECT * FROM transactions WHERE block_index = ?''', (block_index,)))
    txlist = [json.dumps(m).replace('"', '\'') for m in txlist]
    txlist = json.dumps(txlist, indent=4)
    return txlist

def reparse(testnet=True):
    options = dict(COUNTERPARTYD_OPTIONS)
    options.pop('data_dir')
    counterpartyd.set_options(database_file=':memory:', testnet=testnet, **options)
    
    if testnet:
        config.PREFIX = b'TESTXXXX'

    logger = logging.getLogger()
    console = logging.StreamHandler()
    console.setLevel(logging.INFO)
    formatter = logging.Formatter('%(message)s')
    console.setFormatter(formatter)
    logger.addHandler(console)

    memory_db = util.connect_to_db()
    initialise_db(memory_db)
    
    prod_db_path = os.path.join(config.DATA_DIR, '{}.{}{}.db'.format(config.XCP_CLIENT, str(config.VERSION_MAJOR), '.testnet' if testnet else ''))
    prod_db = apsw.Connection(prod_db_path)
    prod_db.setrowtrace(util.rowtracer)

    with memory_db.backup("main", prod_db, "main") as backup:
        backup.step()

    # here we don't use block.reparse() because it reparse db in transaction (`with db`)
    memory_cursor = memory_db.cursor()
    for table in blocks.TABLES + ['balances']:
        memory_cursor.execute('''DROP TABLE IF EXISTS {}'''.format(table))
    blocks.initialise(memory_db)
    previous_ledger_hash = None
    previous_txlist_hash = None
    memory_cursor.execute('''SELECT * FROM blocks ORDER BY block_index''')
    for block in memory_cursor.fetchall():
        try:
            logger.info('Block (re‐parse): {}'.format(str(block['block_index'])))
            previous_ledger_hash, previous_txlist_hash = blocks.parse_block(memory_db, block['block_index'], block['block_time'], 
                                                                                    previous_ledger_hash, block['ledger_hash'],
                                                                                    previous_txlist_hash, block['txlist_hash'])
        except ConsensusError as e:
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
