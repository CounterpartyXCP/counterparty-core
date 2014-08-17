#! /usr/bin/python3

import os
import sys
import hashlib
import binascii
import time
import apsw
import decimal
D = decimal.Decimal
import difflib
import json
import inspect
import requests
from requests.auth import HTTPBasicAuth
import logging
import tempfile
import shutil
import locale
import re

# Set test environment
os.environ['TZ'] = 'EST'
time.tzset()
locale.setlocale(locale.LC_ALL, 'en_US.UTF-8')

CURR_DIR = os.path.dirname(os.path.realpath(os.path.join(os.getcwd(), os.path.expanduser(__file__))))
sys.path.append(os.path.normpath(os.path.join(CURR_DIR, '..')))

from lib import (config, api, util, exceptions, bitcoin, blocks)
from lib import (send, order, btcpay, issuance, broadcast, bet, dividend, burn, cancel, callback, rps, rpsresolve)
import counterpartyd

# config.BLOCK_FIRST = 0
# config.BURN_START = 0
# config.BURN_END = 9999999
counterpartyd.set_options(rpc_port=9999, database_file=CURR_DIR+'/counterpartyd.unittest.db', testnet=True, testcoin=False, unittest=True, backend_rpc_ssl_verify=False)

# unit tests private keys
config.UNITTEST_PRIVKEY = {
    'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc': 'cPdUqd5EbBWsjcG9xiL1hz8bEyGFiz4SW99maU9JgpL9TEcxUf3j',
    'mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns': 'cQ897jnCVRrawNbw8hgmjMiRNHejwzg4KbzdMCzc91iaTif8ReqX'
}

# Logs.
try: os.remove(CURR_DIR + '/log.new')
except: pass
logging.basicConfig(filename=CURR_DIR + '/log.new', level=logging.DEBUG, format='%(message)s')
requests_log = logging.getLogger("requests")
requests_log.setLevel(logging.WARNING)

# Output.
output_new = {}
with open(CURR_DIR + '/output.json', 'r') as output_file:
    output = json.load(output_file)

# Connect to database.
try: os.remove(config.DATABASE)
except: pass
db = util.connect_to_db()
cursor = db.cursor()

# Each tx has a block_index equal to its tx_index
tx_index = 0

source_default = 'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc' 
destination_default = 'mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns'
quantity = config.UNIT
small = round(quantity / 2)
expiration = 10
fee_required = 900000
fee_provided = 1000000
fee_multiplier_default = .05
move_random_hash_default = '6a886d74c2d4b1d7a35fd9159333ef64ba45a04d7aeeeb4538f958603c16fc5d'
rps_random_default = '7a4488d61ed8f2e9fa2874113fccb8b1'

def parse_hex (unsigned_tx_hex):

    tx = bitcoin.decode_raw_transaction(unsigned_tx_hex)

    cursor = db.cursor()
    tx_hash = hashlib.sha256(chr(tx_index).encode('utf-8')).hexdigest()
    global tx_index
    block_index = config.BURN_START + tx_index
    block_hash = hashlib.sha512(chr(block_index).encode('utf-8')).hexdigest()
    block_time = block_index * 10000000

    source, destination, btc_amount, fee, data = blocks.get_tx_info(tx, block_index)

    cursor.execute('''INSERT INTO blocks(
                        block_index,
                        block_hash,
                        block_time) VALUES(?,?,?)''',
                        (block_index,
                        block_hash,
                        block_time)
                  )

    cursor.execute('''INSERT INTO transactions(
                        tx_index,
                        tx_hash,
                        block_index,
                        block_time,
                        source,
                        destination,
                        btc_amount,
                        fee,
                        data) VALUES(?,?,?,?,?,?,?,?,?)''',
                        (tx_index,
                         tx_hash,
                         block_index,
                         tx_index,
                         source,
                         destination,
                         btc_amount,
                         fee,
                         data)
                  )

    txes = list(cursor.execute('''SELECT * FROM transactions \
                                  WHERE tx_index=?''', (tx_index,)))
    assert len(txes) == 1
    tx = txes[0]
    blocks.parse_tx(db, tx)

    # After parsing every transaction, check that the credits, debits sum properly.
    cursor.execute('''SELECT * FROM balances''')
    for balance in cursor.fetchall():
        quantity = 0
        cursor.execute('''SELECT * FROM debits \
                          WHERE (address = ? AND asset = ?)''', (balance['address'], balance['asset']))
        for debit in cursor.fetchall():
            quantity -= debit['quantity']
        cursor.execute('''SELECT * FROM credits \
                          WHERE (address = ? AND asset = ?)''', (balance['address'], balance['asset']))
        for credit in cursor.fetchall():
            quantity += credit['quantity']
        assert quantity == balance['quantity']

    tx_index += 1
    cursor.close()
    return tx

def block_progress(block_count):
    global tx_index
    for b in range(block_count):
        block_index = config.BURN_START + tx_index
        block_hash = hashlib.sha512(chr(block_index).encode('utf-8')).hexdigest()
        block_time = block_index * 10000000

        cursor.execute('''INSERT INTO blocks(
                        block_index,
                        block_hash,
                        block_time) VALUES(?,?,?)''',
                        (block_index,
                        block_hash,
                        block_time)
                      )

        order.expire(db, block_index)
        bet.expire(db, block_index, block_time)
        rps.expire(db, block_index)

        tx_index += 1

def check_movment(db, movment_type, block_index, address, asset, quantity, event):
    sql = '''SELECT * FROM {}s WHERE block_index = ? AND address = ? AND  asset = ? AND quantity = ? AND event = ?'''
    sql = sql.format(movment_type)
    bindings = (block_index, address, asset, quantity, event)
    movments = list(cursor.execute(sql, bindings))
    assert len(movments) == 1

# https://github.com/CounterpartyXCP/counterpartyd/blob/develop/test/db.dump#L23
# some sqlite version generates spaces and line breaks too.
def clean_sqlite_dump(dump):
    dump = "\n".join(dump)
    dump = re.sub('\)[\n\s]+;', ');', dump)
    return dump.split("\n")

def compare(filename):
    old = CURR_DIR + '/' + filename
    new = old + '.new'

    with open(old, 'r') as f:
        old_lines = f.readlines()
    with open(new, 'r') as f:
        new_lines = f.readlines()

    if (filename == 'db.dump'):
        old_lines = clean_sqlite_dump(old_lines)
        new_lines = clean_sqlite_dump(new_lines)

    diff = list(difflib.unified_diff(old_lines, new_lines, n=0))
    if len(diff):
        print(diff)
    assert not len(diff)

def summarise (ebit):
    return (ebit['block_index'], ebit['address'], ebit['asset'], ebit['quantity'])


def setup_function(function):
    global db
    global cursor
    cursor.execute('''BEGIN''')

def teardown_function(function):
    cursor.execute('''END''')


# TODO: replace inspect.stack()[0][3] with inspect.currentframe().f_code.co_name?

def test_start ():
    logging.info('START TEST')

def test_initialise ():
    blocks.initialise(db)

    # First block (for burn.create sanity check).
    cursor = db.cursor()
    cursor.execute('''INSERT INTO blocks(
                        block_index,
                        block_hash,
                        block_time) VALUES(?,?,?)''',
                        (config.BURN_START - 1,
                        'foobar',
                        1337)
                  )
    cursor.close()

def test_burn ():
    unsigned_tx_hex = bitcoin.transaction(burn.compose(db, source_default, int(.62 * quantity)), encoding='multisig')

    parse_hex(unsigned_tx_hex)

    output_new[inspect.stack()[0][3]] = unsigned_tx_hex

def test_send ():
    unsigned_tx_hex = bitcoin.transaction(send.compose(db, source_default, destination_default, config.XCP, small), encoding='multisig')

    parse_hex(unsigned_tx_hex)

    output_new[inspect.stack()[0][3]] = unsigned_tx_hex

def test_order_buy_xcp ():
    unsigned_tx_hex = bitcoin.transaction(order.compose(db, source_default, config.BTC, small, config.XCP, small * 2, expiration, 0), encoding='multisig', fee_provided=fee_provided)

    parse_hex(unsigned_tx_hex)

    output_new[inspect.stack()[0][3]] = unsigned_tx_hex

def test_order_sell_xcp ():
    unsigned_tx_hex = bitcoin.transaction(order.compose(db, source_default, config.XCP, round(small * 2.1), config.BTC, small, expiration, fee_required), encoding='multisig')

    parse_hex(unsigned_tx_hex)

    output_new[inspect.stack()[0][3]] = unsigned_tx_hex

def test_btcpay ():
    order_match_id = 'dbc1b4c900ffe48d575b5da5c638040125f65db0fe3e24494b76ea986457d986084fed08b978af4d7d196a7446a86b58009e636b611db16211b65a9aadff29c5'
    unsigned_tx_hex = bitcoin.transaction(btcpay.compose(db, source_default, order_match_id), encoding='multisig')

    parse_hex(unsigned_tx_hex)

    output_new[inspect.stack()[0][3]] = unsigned_tx_hex

def test_issuance_divisible ():
    unsigned_tx_hex = bitcoin.transaction(issuance.compose(db, source_default, None, 'BBBB', quantity * 10, True, False, 0, 0.0, ''), encoding='multisig')

    parse_hex(unsigned_tx_hex)

    output_new[inspect.stack()[0][3]] = unsigned_tx_hex

def test_issuance_indivisible_callable ():
    unsigned_tx_hex = bitcoin.transaction(issuance.compose(db, source_default, None, 'BBBC', round(quantity / 1000), False, True, 17, 0.015, 'foobar'), encoding='multisig')

    parse_hex(unsigned_tx_hex)

    output_new[inspect.stack()[0][3]] = unsigned_tx_hex

def test_send_divisible ():
    unsigned_tx_hex = bitcoin.transaction(send.compose(db, source_default, destination_default, 'BBBB', round(quantity / 25)), encoding='multisig')

    parse_hex(unsigned_tx_hex)

    output_new[inspect.stack()[0][3]] = unsigned_tx_hex

def test_send_indivisible ():
    unsigned_tx_hex = bitcoin.transaction(send.compose(db, source_default, destination_default, 'BBBC', round(quantity / 190000)), encoding='multisig')

    parse_hex(unsigned_tx_hex)

    output_new[inspect.stack()[0][3]] = unsigned_tx_hex

def test_dividend_divisible ():
    unsigned_tx_hex = bitcoin.transaction(dividend.compose(db, source_default, 600, 'BBBB', config.XCP), encoding='multisig')

    parse_hex(unsigned_tx_hex)

    output_new[inspect.stack()[0][3]] = unsigned_tx_hex

def test_dividend_indivisible ():
    unsigned_tx_hex = bitcoin.transaction(dividend.compose(db, source_default, 800, 'BBBC', config.XCP), encoding='multisig')

    parse_hex(unsigned_tx_hex)

    output_new[inspect.stack()[0][3]] = unsigned_tx_hex

def test_broadcast_initial ():
    unsigned_tx_hex = bitcoin.transaction(broadcast.compose(db, source_default, 1388000000, 100, fee_multiplier_default, 'Unit Test'), encoding='multisig')

    parse_hex(unsigned_tx_hex)

    output_new[inspect.stack()[0][3]] = unsigned_tx_hex

def test_bet_bullcfd_to_be_liquidated ():
    unsigned_tx_hex = bitcoin.transaction(bet.compose(db, source_default, source_default, 0, 1388000100, small, round(small / 2), 0.0, 15120, expiration), encoding='multisig')

    parse_hex(unsigned_tx_hex)

    output_new[inspect.stack()[0][3]] = unsigned_tx_hex

def test_bet_bearcfd_to_be_liquidated ():
    unsigned_tx_hex = bitcoin.transaction(bet.compose(db, source_default, source_default, 1, 1388000100, round(small / 2), round(small * .83), 0.0, 15120, expiration), encoding='multisig')

    parse_hex(unsigned_tx_hex)

    output_new[inspect.stack()[0][3]] = unsigned_tx_hex

def test_bet_bullcfd_to_be_settled ():
    unsigned_tx_hex = bitcoin.transaction(bet.compose(db, source_default, source_default, 0, 1388000100, small * 3, small * 7, 0.0, 5040, expiration), encoding='multisig')

    parse_hex(unsigned_tx_hex)

    output_new[inspect.stack()[0][3]] = unsigned_tx_hex

def test_bet_bearcfd_to_be_settled ():
    unsigned_tx_hex = bitcoin.transaction(bet.compose(db, source_default, source_default, 1, 1388000100, small * 7, small * 3, 0.0, 5040, expiration), encoding='multisig')

    parse_hex(unsigned_tx_hex)

    output_new[inspect.stack()[0][3]] = unsigned_tx_hex

def test_bet_equal ():
    unsigned_tx_hex = bitcoin.transaction(bet.compose(db, source_default, source_default, 2, 1388000200, small * 15, small * 13, 1, 5040, expiration), encoding='multisig')

    parse_hex(unsigned_tx_hex)

    output_new[inspect.stack()[0][3]] = unsigned_tx_hex

def test_bet_notequal ():
    unsigned_tx_hex = bitcoin.transaction(bet.compose(db, source_default, source_default, 3, 1388000200, small * 13, small * 15, 1, 5040, expiration), encoding='multisig')

    parse_hex(unsigned_tx_hex)

    output_new[inspect.stack()[0][3]] = unsigned_tx_hex

def test_broadcast_liquidate ():
    unsigned_tx_hex = bitcoin.transaction(broadcast.compose(db, source_default, 1388000050, round(100 - (.415/3) - .00001, 5), fee_multiplier_default, 'Unit Test'), encoding='multisig')

    parse_hex(unsigned_tx_hex)

    output_new[inspect.stack()[0][3]] = unsigned_tx_hex

def test_broadcast_settle ():
    unsigned_tx_hex = bitcoin.transaction(broadcast.compose(db, source_default, 1388000101, 100.343, fee_multiplier_default, 'Unit Test'), encoding='multisig')

    parse_hex(unsigned_tx_hex)

    output_new[inspect.stack()[0][3]] = unsigned_tx_hex

def test_broadcast_equal ():
    unsigned_tx_hex = bitcoin.transaction(broadcast.compose(db, source_default, 1388000201, 2, fee_multiplier_default, 'Unit Test'), encoding='multisig')

    parse_hex(unsigned_tx_hex)

    output_new[inspect.stack()[0][3]] = unsigned_tx_hex

def test_order_to_be_cancelled ():
    unsigned_tx_hex = bitcoin.transaction(order.compose(db, source_default, 'BBBB', small, config.XCP, small, expiration, 0), encoding='multisig')

    parse_hex(unsigned_tx_hex)

    output_new[inspect.stack()[0][3]] = unsigned_tx_hex

def test_cancel ():
    unsigned_tx_hex = bitcoin.transaction(cancel.compose(db, source_default, '2f0fd1e89b8de1d57292742ec380ea47066e307ad645f5bc3adad8a06ff58608'), encoding='multisig')

    parse_hex(unsigned_tx_hex)

    output_new[inspect.stack()[0][3]] = unsigned_tx_hex

def test_overburn ():
    unsigned_tx_hex = bitcoin.transaction(burn.compose(db, source_default, (1 * config.UNIT), overburn=True), encoding='multisig')  # Try to burn a whole 'nother BTC.

    parse_hex(unsigned_tx_hex)

    output_new[inspect.stack()[0][3]] = unsigned_tx_hex

def test_send_callable ():
    unsigned_tx_hex = bitcoin.transaction(send.compose(db, source_default, destination_default, 'BBBC', 10000), encoding='multisig')

    parse_hex(unsigned_tx_hex)

    output_new[inspect.stack()[0][3]] = unsigned_tx_hex

def test_callback ():
    unsigned_tx_hex = bitcoin.transaction(callback.compose(db, source_default, .3, 'BBBC'), encoding='multisig')

    parse_hex(unsigned_tx_hex)

    output_new[inspect.stack()[0][3]] = unsigned_tx_hex

def test_rps ():
    unsigned_tx_hex = bitcoin.transaction(rps.compose(db, source_default, 5, 11021663, move_random_hash_default, 100), encoding='multisig')
    
    parse_hex(unsigned_tx_hex)

    output_new[inspect.stack()[0][3]] = unsigned_tx_hex

def test_counter_rps ():
    unsigned_tx_hex = bitcoin.transaction(rps.compose(db, destination_default, 5, 11021663, '6e8bf66cbd6636aca1802459b730a99548624e48e243b840e0b34a12bede17ec', 100), encoding='multisig')

    parse_hex(unsigned_tx_hex)

    output_new[inspect.stack()[0][3]] = unsigned_tx_hex

def test_rpsresolve ():
    rps_match_id = '58f7b0780592032e4d8602a3e8690fb2c701b2e1dd546e703445aabd6469734d77adfc95029e73b173f60e556f915b0cd8850848111358b1c370fb7c154e61fd'
    unsigned_tx_hex = bitcoin.transaction(rpsresolve.compose(db, source_default, 3, rps_random_default, rps_match_id), encoding='multisig')

    parse_hex(unsigned_tx_hex)

    output_new[inspect.stack()[0][3]] = unsigned_tx_hex

def test_counter_rpsresolve ():
    rps_match_id = '58f7b0780592032e4d8602a3e8690fb2c701b2e1dd546e703445aabd6469734d77adfc95029e73b173f60e556f915b0cd8850848111358b1c370fb7c154e61fd'
    unsigned_tx_hex = bitcoin.transaction(rpsresolve.compose(db, destination_default, 5, 'fa765e80203cba24a298e4458f63ff6b', rps_match_id), encoding='multisig')
    
    parse_hex(unsigned_tx_hex)

    output_new[inspect.stack()[0][3]] = unsigned_tx_hex

def test_rps_expiration ():
    unsigned_tx_hex = bitcoin.transaction(rps.compose(db, source_default, 5, 11021663, move_random_hash_default, 10), encoding='multisig')
    tx_rps = parse_hex(unsigned_tx_hex)
    check_movment(db, 'debit', tx_rps['block_index'], source_default, 'XCP', 11021663, tx_rps['tx_hash'])

    block_progress(15)
    expiration_block = tx_rps['block_index']+11

    # re-credit expired rps
    check_movment(db, 'credit', expiration_block, source_default, 'XCP', 11021663, tx_rps['tx_hash'])

def test_pending_rps_match_expiration ():
    unsigned_tx_hex = bitcoin.transaction(rps.compose(db, source_default, 5, 11021664, move_random_hash_default, 10), encoding='multisig')
    rps1 = parse_hex(unsigned_tx_hex)
    check_movment(db, 'debit', rps1['block_index'], source_default, 'XCP', 11021664, rps1['tx_hash'])

    unsigned_tx_hex = bitcoin.transaction(rps.compose(db, destination_default, 5, 11021664, move_random_hash_default, 10), encoding='multisig')
    rps2 = parse_hex(unsigned_tx_hex)
    check_movment(db, 'debit', rps2['block_index'], destination_default, 'XCP', 11021664, rps2['tx_hash'])

    block_progress(25)
    expiration_block = rps2['block_index']+21

    # re-credit expired rps
    check_movment(db, 'credit', expiration_block, source_default, 'XCP', 11021664, rps1['tx_hash'] + rps2['tx_hash'])
    check_movment(db, 'credit', expiration_block, destination_default, 'XCP', 11021664, rps1['tx_hash'] + rps2['tx_hash'])

def test_pending_and_resolved_rps_match_expiration ():
    unsigned_tx_hex = bitcoin.transaction(rps.compose(db, source_default, 5, 11021665, move_random_hash_default, 10), encoding='multisig')
    rps1 = parse_hex(unsigned_tx_hex)
    check_movment(db, 'debit', rps1['block_index'], source_default, 'XCP', 11021665, rps1['tx_hash'])

    unsigned_tx_hex = bitcoin.transaction(rps.compose(db, destination_default, 5, 11021665, move_random_hash_default, 10), encoding='multisig')
    rps2 = parse_hex(unsigned_tx_hex)
    check_movment(db, 'debit', rps2['block_index'], destination_default, 'XCP', 11021665, rps2['tx_hash'])

    rps_match_id = rps1['tx_hash'] + rps2['tx_hash']
    unsigned_tx_hex = bitcoin.transaction(rpsresolve.compose(db, source_default, 3, rps_random_default, rps_match_id), encoding='multisig')
    rps_match = parse_hex(unsigned_tx_hex)

    block_progress(25)
    expiration_block = rps_match['block_index']+20
    
    # resolved game wins
    check_movment(db, 'credit', expiration_block, source_default, 'XCP', 2 * 11021665, rps_match_id)


def test_json_rpc():

    # TODO: Broken
    api_server = api.APIServer()
    api_server.daemon = True
    api_server.start()
    url = 'http://' + str(config.RPC_USER) + ':' + config.RPC_PASSWORD + '@localhost:' + str(config.RPC_PORT)

    # TEMP: Use external server.
    url = 'http://' + str(config.RPC_USER) + ':' + config.RPC_PASSWORD + '@localhost:' + '14000'

    headers = {'content-type': 'application/json'}
    payloads = []
#     payloads.append({
#         "method": "get_balances",
#         "params": {"filters": {'field': 'address', 'op': '==', 'value': 'mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns'}},
#         "jsonrpc": "2.0",
#         "id": 0,
#     })
    payloads.append({
        "method": "create_send",
        "params": {'source': 'mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns', 'destination': destination_default, 'asset': config.XCP, 'quantity': 1, 'encoding': 'pubkeyhash', 'pubkey': '0319f6e07b0b8d756156394b9dcf3b011fe9ac19f2700bd6b69a6a1783dbb8b977'},
        "jsonrpc": "2.0",
        "id": 0,
    })

    for payload in payloads:
        for attempt in range(100):  # Try until server is ready.
            try:
                response = requests.post(url, data=json.dumps(payload), headers=headers, verify=False).json()
                print(response)
                # print('\npayload', payload)
                # print('response', response, '\n')
                if not response['result']:
                    raise Exception('null result')
                    assert False
                assert response['jsonrpc'] == '2.0'
                assert response['id'] == 0
                output_new['rpc.' + payload['method']] = response['result']
                break
            except KeyError as e:
                print(response, file=sys.stderr)
                exit(1)
            except requests.exceptions.ConnectionError:
                time.sleep(.05)
        if attempt == 99: exit(1)   # Fail

def test_stop():
    logging.info('STOP TEST')


def test_db():
    GOOD = CURR_DIR + '/db.dump'
    NEW = CURR_DIR + '/db.dump.new'

    with open(GOOD, 'r') as f:
        good_data = f.readlines()

    import io
    output=io.StringIO()
    shell=apsw.Shell(stdout=output, args=(config.DATABASE,))
    shell.process_command(".dump")
    with open(NEW, 'w') as f:
        lines = output.getvalue().split('\n')[8:]
        new_data = '\n'.join(lines)
        f.writelines(new_data)

    compare('db.dump')

def test_output():
    with open(CURR_DIR + '/output.json.new', 'w') as output_new_file:
        json.dump(output_new, output_new_file, sort_keys=True, indent=4)

    for key in output_new.keys():
        try:
            assert output[key] == output_new[key]
        except Exception as e:
            print('Key:', key)
            print('Old output:')
            print(output[key])
            print('New output:')
            print(output_new[key])
            raise e

def test_log():
    compare('log')

def test_base58_decode():
    """
    mainnet addresses here

    The leading zeros are not included in the pubkeyhash: see
    <http://www.bitcoinsecurity.org/wp-content/uploads/2012/07/tx_binary_map.png>.
    """
    address = '16UwLL9Risc3QfPqBUvKofHmBQ7wMtjvM'
    pubkeyhash = bitcoin.base58_decode(address, b'\x00')
    assert binascii.hexlify(pubkeyhash).decode('utf-8') == '010966776006953D5567439E5E39F86A0D273BEE'.lower()
    assert len(pubkeyhash) == 20

def do_book(testnet):
    # Filenames.
    if testnet:
        filename = 'book.testnet'
    else:
        filename = 'book.mainnet'
    old = CURR_DIR + '/' + filename
    new = old + '.new'

    # Get last block_index of old book.
    with open(old, 'r') as f:
        block_index = int(f.readlines()[-1][7:13])

    # Use temporary DB.
    counterpartyd.set_options(testnet=testnet)
    default_db = config.DATABASE
    temp_db = tempfile.gettempdir() + '/' + os.path.basename(config.DATABASE)
    shutil.copyfile(default_db, temp_db)
    counterpartyd.set_options(database_file=temp_db, testnet=testnet)
    db = util.connect_to_db()
    cursor = db.cursor()

    # TODO: USE API
    import subprocess
    if testnet:
        subprocess.check_call(['./counterpartyd.py', '--database-file=' + temp_db, '--testnet', 'reparse'])
    else:
        subprocess.check_call(['./counterpartyd.py', '--database-file=' + temp_db, 'reparse'])

    # Get new book.
    with open(new, 'w') as f:
        # Credits.
        cursor.execute('select * from credits where block_index <= ? order by block_index, address, asset', (block_index,))
        for credit in list(cursor):
            f.write('credit ' + str(summarise(credit)) + '\n')
        # Debits.
        cursor.execute('select * from debits where block_index <= ? order by block_index, address, asset', (block_index,))
        for debit in cursor.fetchall():
            f.write('debit ' + str(summarise(debit)) + '\n')

    # Compare books.
    compare(filename)

    # Clean up.
    cursor.close()
    os.remove(temp_db)

def test_book_testnet():
    do_book(True)

def test_book_mainnet():
    do_book(False)
