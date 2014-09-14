import os, sys, hashlib, binascii, time, decimal, logging, locale, re, io
import difflib, json, inspect, tempfile, shutil
import apsw, pytest, requests
from requests.auth import HTTPBasicAuth

CURR_DIR = os.path.dirname(os.path.realpath(os.path.join(os.getcwd(), os.path.expanduser(__file__))))
sys.path.append(os.path.normpath(os.path.join(CURR_DIR, '..')))

from lib import (config, api, util, exceptions, bitcoin, blocks)
from lib import (send, order, btcpay, issuance, broadcast, bet, dividend, burn, cancel, callback, rps, rpsresolve)
import counterpartyd

from fixtures.fixtures import DEFAULT_PARAMS as DP
from fixtures.fixtures import UNITEST_FIXTURE, INTEGRATION_SCENARIOS

D = decimal.Decimal

# Set test environment
os.environ['TZ'] = 'EST'
time.tzset()
locale.setlocale(locale.LC_ALL, 'en_US.UTF-8')

# unit tests private keys
config.UNITTEST_PRIVKEY = {
    DP['address_1']: DP['address_1_privkey'],
    DP['address_2']: DP['address_2_privkey'],
    DP['address_3']: DP['address_3_privkey']
}

def dump_database(db):
    # TEMPORARY
    # .dump command bugs when aspw.Shell is used with 'db' args instead 'args'
    # but this way keep 20x faster than to run scenario with file db
    db_filename = CURR_DIR + '/fixtures/tmpforbackup.db'
    if os.path.isfile(db_filename):
        os.remove(db_filename)
    filecon=apsw.Connection(db_filename)
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

    os.remove(db_filename)

    return new_data

def restore_database(database_filename, dump_filename):
    if os.path.isfile(database_filename):
        os.remove(database_filename)
    db = apsw.Connection(database_filename)
    cursor = db.cursor()
    with open(dump_filename, 'r') as sql_dump:
        cursor.execute(sql_dump.read())
    cursor.close()

def insert_block(db, block_index, parse_block=False):
    cursor = db.cursor()
    block_hash = hashlib.sha512(chr(block_index).encode('utf-8')).hexdigest()
    block_time = block_index * 10000000
    block = (block_index, block_hash, block_time, None)
    cursor.execute('''INSERT INTO blocks VALUES (?,?,?,?)''', block)
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

def insert_raw_transaction(raw_transaction, db):
    # one transaction per block
    block_index, block_hash, block_time = create_next_block(db)

    cursor = db.cursor()
    tx_index = block_index - config.BURN_START + 1
    tx = util.aio_run_synch(bitcoin.decode_raw_transaction(raw_transaction))
    tx_hash = hashlib.sha256(chr(tx_index).encode('utf-8')).hexdigest()
    source, destination, btc_amount, fee, data = util.aio_run_synch(blocks.get_tx_info(tx, block_index))
    transaction = (tx_index, tx_hash, block_index, block_hash, block_time, source, destination, btc_amount, fee, data, True)
    cursor.execute('''INSERT INTO transactions VALUES (?,?,?,?,?,?,?,?,?,?,?)''', transaction)
    tx = list(cursor.execute('''SELECT * FROM transactions WHERE tx_index = ?''', (tx_index,)))[0]
    cursor.close()

    blocks.parse_block(db, block_index, block_time)
    return tx

def insert_transaction(transaction, db):
    cursor = db.cursor()
    block = (transaction['block_index'], transaction['block_hash'], transaction['block_time'], None)
    cursor.execute('''INSERT INTO blocks VALUES (?,?,?,?)''', block)
    keys = ",".join(transaction.keys())
    cursor.execute('''INSERT INTO transactions ({}) VALUES (?,?,?,?,?,?,?,?,?,?,?)'''.format(keys), tuple(transaction.values()))
    cursor.close()

def initialise_db(db):
    blocks.initialise(db)
    cursor = db.cursor()
    first_block = (config.BURN_START - 1, 'foobar', 1337, util.double_hash_string(config.MOVEMENTS_HASH_SEED))
    cursor.execute('''INSERT INTO blocks VALUES (?,?,?,?)''', first_block)
    cursor.close()

def run_scenario(scenario):
    counterpartyd.set_options(rpc_port=9999, database_file=':memory:',
                              testnet=True, testcoin=False, unittest=True, backend_rpc_ssl_verify=False)

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
    for transaction in scenario:
        if transaction[0] != 'create_next_block':
            module = sys.modules['lib.{}'.format(transaction[0])]
            compose = getattr(module, 'compose')
            unsigned_tx_hex = util.aio_run_synch(bitcoin.transaction(compose(db, *transaction[1]), **transaction[2]))
            insert_raw_transaction(unsigned_tx_hex, db)
        else:
            create_next_block(db, block_index=config.BURN_START + transaction[1], parse_block=True)

    dump = dump_database(db)
    log = logger_buff.getvalue()

    db.close()
    return dump, log

def save_scenario(scenario_name):
    dump, log = run_scenario(INTEGRATION_SCENARIOS[scenario_name])
    with open(CURR_DIR + '/fixtures/' + scenario_name + '.new.sql', 'w') as f:
        f.writelines(dump)
    with open(CURR_DIR + '/fixtures/' + scenario_name + '.new.log', 'w') as f:
        f.writelines(log)

def load_scenario_ouput(scenario_name):
    with open(CURR_DIR + '/fixtures/' + scenario_name + '.sql', 'r') as f:
        dump = ("").join(f.readlines())
    with open(CURR_DIR + '/fixtures/' + scenario_name + '.log', 'r') as f:
        log = ("").join(f.readlines())
    return dump, log

def check_record(record, counterpartyd_db):
    sql  = '''SELECT COUNT(*) AS c FROM {} '''.format(record['table'])
    sql += '''WHERE '''
    bindings = []
    conditions = []
    for field in record['values']:
        if record['values'][field] is not None:
            conditions.append('''{} = ?'''.format(field))
            bindings.append(record['values'][field])
    sql += " AND ".join(conditions)

    cursor = counterpartyd_db.cursor()
    count = list(cursor.execute(sql, tuple(bindings)))[0]['c']
    assert count == 1

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
        return util.aio_run_synch(tested_method(inputs[0], **inputs[1]))
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
            unsigned_tx_hex = util.aio_run_synch(bitcoin.transaction(test_outputs, **tx_params))
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
        print("".join(diff))
    assert not len(diff)

if __name__ == '__main__':
    save_scenario('unittest_fixture')
    save_scenario('scenario_1')

