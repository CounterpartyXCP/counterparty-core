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

CURR_DIR = os.path.dirname(os.path.realpath(os.path.join(os.getcwd(), os.path.expanduser(__file__))))
sys.path.append(os.path.normpath(os.path.join(CURR_DIR, '..')))

from lib import (config, api, util, exceptions, bitcoin, blocks)
from lib import (send, order, btcpay, issuance, broadcast, bet, dividend, burn, cancel, callback)
import counterpartyd

# config.BLOCK_FIRST = 0
# config.BURN_START = 0
# config.BURN_END = 9999999
counterpartyd.set_options(database_file=CURR_DIR+'/counterpartyd.unittest.db', testnet=True, testcoin=False, unittest=True)

# Connect to database.
try: os.remove(config.DATABASE)
except: pass
db = util.connect_to_db()
cursor = db.cursor()

# Each tx has a block_index equal to its tx_index
tx_index = 0

source_default = 'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc'
destination_default = 'n3BrDB6zDiEPWEE6wLxywFb4Yp9ZY5fHM7'
quantity = config.UNIT
small = round(quantity / 2)
expiration = 10
fee_required = 900000
fee_provided = 1000000
fee_multiplier_default = .05



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



def setup_function(function):
    global db
    global cursor
    cursor.execute('''BEGIN''')

def teardown_function(function):
    cursor.execute('''END''')

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

'''
# Fake RPC responses
try: os.remove(CURR_DIR + '/rpc.new')
except: pass
'''

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
    unsigned_tx_hex = bitcoin.transaction(send.compose(db, source_default, destination_default, 'XCP', small), encoding='multisig')

    parse_hex(unsigned_tx_hex)

    output_new[inspect.stack()[0][3]] = unsigned_tx_hex

def test_order_buy_xcp ():
    unsigned_tx_hex = bitcoin.transaction(order.compose(db, source_default, 'BTC', small, 'XCP', small * 2, expiration, 0, fee_provided), encoding='multisig')

    parse_hex(unsigned_tx_hex)

    output_new[inspect.stack()[0][3]] = unsigned_tx_hex

def test_order_sell_xcp ():
    unsigned_tx_hex = bitcoin.transaction(order.compose(db, source_default, 'XCP', round(small * 2.1), 'BTC', small, expiration, fee_required, config.MIN_FEE), encoding='multisig')

    parse_hex(unsigned_tx_hex)

    output_new[inspect.stack()[0][3]] = unsigned_tx_hex

def test_btcpay ():
    order_match_id = 'dbc1b4c900ffe48d575b5da5c638040125f65db0fe3e24494b76ea986457d986084fed08b978af4d7d196a7446a86b58009e636b611db16211b65a9aadff29c5'
    unsigned_tx_hex = bitcoin.transaction(btcpay.compose(db, order_match_id), encoding='multisig')

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

def test_dividend_divisible ():
    unsigned_tx_hex = bitcoin.transaction(dividend.compose(db, source_default, 6, 'BBBB', 'XCP'), encoding='multisig')

    parse_hex(unsigned_tx_hex)

    output_new[inspect.stack()[0][3]] = unsigned_tx_hex

def test_dividend_indivisible ():
    unsigned_tx_hex = bitcoin.transaction(dividend.compose(db, source_default, 8, 'BBBC', 'XCP'), encoding='multisig')

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
    unsigned_tx_hex = bitcoin.transaction(order.compose(db, source_default, 'BBBB', small, 'XCP', small, expiration, 0, config.MIN_FEE), encoding='multisig')

    parse_hex(unsigned_tx_hex)

    output_new[inspect.stack()[0][3]] = unsigned_tx_hex

def test_cancel ():
    unsigned_tx_hex = bitcoin.transaction(cancel.compose(db, 'ab897fbdedfa502b2d839b6a56100887dccdc507555c282e59589e06300a62e2'), encoding='multisig')

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

def test_json_rpc():

    api_server = api.APIServer()
    api_server.daemon = True
    api_server.start()

    url = 'http://localhost:' + str(config.RPC_PORT) + '/rpc/'
    headers = {'content-type': 'application/json'}
    auth = HTTPBasicAuth(config.RPC_USER, config.RPC_PASSWORD)

    payloads = []
    payloads.append({
        "method": "get_balances",
        "params": {"filters": {'field': 'address', 'op': '==', 'value': 'mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns'}},
        "jsonrpc": "2.0",
        "id": 0,
    })
    payloads.append({
        "method": "create_send",
        "params": {'source': 'mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns', 'destination': destination_default, 'asset': 'XCP', 'quantity': 1, 'encoding': 'pubkeyhash'},
        "jsonrpc": "2.0",
        "id": 0,
    })

    for payload in payloads:
        for attempt in range(100):  # Try until server is ready.
            try:
                response = requests.post(url, data=json.dumps(payload), headers=headers, auth=auth).json()
                print('\npayload', payload)
                print('response', response, '\n')
                if not response['result']:
                    raise Exception('testnet server not running')
                    assert False
                assert response['jsonrpc'] == '2.0'
                assert response['id'] == 0
                output_new['rpc.' + payload['method']] = response['result']
                break
            except requests.exceptions.ConnectionError:
                time.sleep(.05)
        if attempt == 99: exit(1)   # Fail

def test_get_address():
    get_address = util.get_address(db, source_default)
    for field in get_address:
        output_new['get_address_' + field] = get_address[field]

def test_stop():
    logging.info('STOP TEST')


def test_db():
    GOOD = CURR_DIR + '/db.dump'
    NEW = CURR_DIR + '/db.new.dump'

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

    import subprocess
    assert not subprocess.call(['diff', GOOD, NEW])

def test_output():
    with open(CURR_DIR + '/output.new.json', 'w') as output_new_file:
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
    with open(CURR_DIR + '/log', 'r') as f:
        old_log = f.readlines()
    with open(CURR_DIR + '/log.new', 'r') as f:
        new_log = f.readlines()

    log_diff = list(difflib.unified_diff(old_log, new_log, n=0))
    print(log_diff)
    assert not len(log_diff)

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


"""
follow()

reorg()

asset lock
asset transfer
expire order matches
expire bet matches
cancelling bets, orders

bet_match
order_match
rpc
bitcoind_check
serialize
get_inputs
transaction
"""


"""
Too small:
util.isodt()
util.devise()
bet.get_fee_multiplier()
"""



