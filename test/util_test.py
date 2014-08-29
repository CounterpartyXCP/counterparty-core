import os, sys, hashlib, binascii, time, decimal, logging, locale, re, io
import difflib, json, inspect, tempfile, shutil
import apsw, pytest, requests
from requests.auth import HTTPBasicAuth

CURR_DIR = os.path.dirname(os.path.realpath(os.path.join(os.getcwd(), os.path.expanduser(__file__))))
sys.path.append(os.path.normpath(os.path.join(CURR_DIR, '..')))

from lib import (config, api, util, exceptions, bitcoin, blocks)
from lib import (send, order, btcpay, issuance, broadcast, bet, dividend, burn, cancel, callback, rps, rpsresolve)
import counterpartyd

from fixtures.unittest_vector import DEFAULT_PARAMS as DP

D = decimal.Decimal

# Set test environment
os.environ['TZ'] = 'EST'
time.tzset()
locale.setlocale(locale.LC_ALL, 'en_US.UTF-8')

# unit tests private keys
config.UNITTEST_PRIVKEY = {
    DP['address_1']: DP['address_1_privkey'],
    DP['address_2']: DP['address_2_privkey']
}

def dump_database(database_filename, dump_filename):
    output=io.StringIO()
    shell=apsw.Shell(stdout=output, args=(database_filename,))
    shell.process_command(".dump")
    with open(dump_filename, 'w') as f:
        lines = output.getvalue().split('\n')[8:]
        new_data = '\n'.join(lines)
        f.writelines(new_data)

def restore_database(database_filename, dump_filename):
    if os.path.isfile(database_filename):
        os.remove(database_filename)
    db = apsw.Connection(database_filename)
    cursor = db.cursor()
    with open(dump_filename, 'r') as sql_dump:
        cursor.execute(sql_dump.read())
    cursor.close()

def insert_raw_transaction(raw_transaction, db):
    cursor = db.cursor()
    tx_index = list(cursor.execute("SELECT COUNT(*) AS c FROM transactions"))[0]['c'] + 1

    tx = bitcoin.decode_raw_transaction(raw_transaction)
    tx_hash = hashlib.sha256(chr(tx_index).encode('utf-8')).hexdigest()
    block_index = config.BURN_START + tx_index
    block_hash = hashlib.sha512(chr(block_index).encode('utf-8')).hexdigest()
    block_time = block_index * 10000000
    source, destination, btc_amount, fee, data = blocks.get_tx_info(tx, block_index)

    block = (block_index, block_hash, block_time)
    cursor.execute('''INSERT INTO blocks VALUES (?,?,?)''', block)
    transaction = (tx_index, tx_hash, block_index, block_hash, block_time, source, destination, btc_amount, fee, data, True)
    cursor.execute('''INSERT INTO transactions VALUES (?,?,?,?,?,?,?,?,?,?,?)''', transaction)

    tx = list(cursor.execute('''SELECT * FROM transactions WHERE tx_index = ?''', (tx_index,)))[0]
    blocks.parse_tx(db, tx)
    return tx

def insert_transaction(transaction, db):
    cursor = db.cursor()
    block = (transaction['block_index'], transaction['block_hash'], transaction['block_time'])
    cursor.execute('''INSERT INTO blocks VALUES (?,?,?)''', block)
    keys = ",".join(transaction.keys())
    cursor.execute('''INSERT INTO transactions ({}) VALUES (?,?,?,?,?,?,?,?,?,?,?)'''.format(keys), tuple(transaction.values()))

def generate_unit_test_fixture():
    counterpartyd.set_options(rpc_port=9999, database_file=CURR_DIR+'/fixtures/fixtures.unittest.db', 
                              testnet=True, testcoin=False, unittest=True, backend_rpc_ssl_verify=False)
    
    if os.path.isfile(config.DATABASE):
        os.remove(config.DATABASE)

    db = util.connect_to_db()
    blocks.initialise(db)
    cursor = db.cursor()
    first_block = (config.BURN_START - 1, 'foobar', 1337)
    cursor.execute('''INSERT INTO blocks VALUES (?,?,?)''', first_block)

    unsigned_tx_hex = bitcoin.transaction(burn.compose(db, DP['address_1'], DP['burn_quantity']), encoding='multisig')
    insert_raw_transaction(unsigned_tx_hex, db)

    dump_database(config.DATABASE, CURR_DIR + '/fixtures/unittest_fixture.sql')
    cursor.close()
    os.remove(config.DATABASE)

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

def check_ouputs(tx_name, method, inputs, outputs, error, records, counterpartyd_db):
    tested_module = sys.modules['lib.{}'.format(tx_name)]
    tested_method = getattr(tested_module, method)
    
    test_outputs = None
    if error is not None:
        with pytest.raises(getattr(exceptions, error[0])) as exception:
            test_outputs = tested_method(counterpartyd_db, *inputs)
    else:
        test_outputs = tested_method(counterpartyd_db, *inputs)

    if outputs is not None:
        assert outputs == test_outputs
    if error is not None:
        assert str(exception.value) == error[1]
    if records is not None:
        for record in records:
            check_record(record, counterpartyd_db)


#generate_unit_test_fixture()

