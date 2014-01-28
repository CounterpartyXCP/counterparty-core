#! /usr/bin/python3

import os
import sys
import hashlib
import binascii
import time
import apsw
import appdirs
import logging
import decimal
D = decimal.Decimal
import difflib
import json
import inspect
from threading import Thread
import requests
from requests.auth import HTTPBasicAuth

CURR_DIR = os.path.dirname(os.path.realpath(os.path.join(os.getcwd(), os.path.expanduser(__file__))))
sys.path.append(os.path.normpath(os.path.join(CURR_DIR, '..')))

from lib import (config, api, zeromq, util, exceptions, bitcoin, blocks)
from lib import (send, order, btcpay, issuance, broadcast, bet, dividend, burn, cancel, util)

# JSON-RPC Options
CONFIGFILE = os.path.expanduser('~') + '/.bitcoin/bitcoin.conf'
config.PREFIX = config.UNITTEST_PREFIX
config.BITCOIND_RPC_CONNECT = 'localhost'
config.BITCOIND_RPC_PORT = '18332' # Only run tests on testnet.
try:
    with open(CONFIGFILE, 'r') as configfile:
        for line in configfile.readlines():
            if line.startswith('#'):
                continue
            array = line.replace('\n', '').split('=')
            if len(array) != 2:
                continue
            key, value = array[:2]
            if key == 'rpcuser': config.BITCOIND_RPC_USER = value
            elif key == 'rpcpassword': config.BITCOIND_RPC_PASSWORD = value
            elif key == 'rpcconnect': config.BITCOIND_RPC_CONNECT = value
            elif key == 'rpcport': config.BITCOIND_RPC_PORT = value
except Exception:
    raise Exception('Put a (valid) copy of your \
bitcoin.conf in ~/.bitcoin/bitcoin.conf')
    sys.exit(1)
config.BITCOIND_RPC = 'http://'+config.BITCOIND_RPC_USER+':'+config.BITCOIND_RPC_PASSWORD+'@'+config.BITCOIND_RPC_CONNECT+':'+config.BITCOIND_RPC_PORT

config.RPC_HOST = 'localhost'
config.RPC_PORT = 9999
config.RPC_USER = 'rpcuser'
config.RPC_PASSWORD = 'rpcpass'

config.DATABASE = CURR_DIR + '/counterparty.test.db'
try: os.remove(config.DATABASE)
except: pass

#Connect to test DB
db = apsw.Connection(config.DATABASE)
db.setrowtrace(util.rowtracer)
cursor = db.cursor()

#Set up zeromq publisher
config.zeromq_publisher = zeromq.ZeroMQPublisher()
config.zeromq_publisher.daemon = True
config.zeromq_publisher.start()

tx_index = 0

config.BLOCK_FIRST = 0
config.BURN_START = 0
config.BURN_END = 9999999
config.ADDRESSVERSION = b'\x6F' # testnet
config.UNSPENDABLE = 'mvCounterpartyXXXXXXXXXXXXXXW24Hef'

source_default = 'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc'
destination_default = 'n3BrDB6zDiEPWEE6wLxywFb4Yp9ZY5fHM7'
quantity = config.UNIT
small = round(quantity / 2)
expiration = 10
fee_required = 900000
fee_provided = 1000000
fee_multiplier_default = .05


# Each tx has a block_index equal to its tx_index

print('Run `test.py` with `py.test test.py`.')



def parse_hex (unsigned_tx_hex):
    
    tx = bitcoin.rpc('decoderawtransaction', [unsigned_tx_hex])
    source, destination, btc_amount, fee, data = blocks.get_tx_info(tx)

    parse_hex_cursor = db.cursor()
    tx_hash = hashlib.sha256(chr(tx_index).encode('utf-8')).hexdigest()
    global tx_index
    parse_hex_cursor.execute('''INSERT INTO transactions(
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
                         tx_index,
                         tx_index,
                         source,
                         destination,
                         btc_amount,
                         fee,
                         data)
                  )
    parse_hex_cursor.execute('''SELECT * FROM transactions \
                                WHERE tx_index=?''', (tx_index,))                         
    tx = parse_hex_cursor.fetchall()[0]                  
    blocks.parse_tx(db, tx)

    # After parsing every transaction, check that the credits, debits sum properly.
    balances = util.get_balances(db)
    for balance in balances:
        amount = 0
        debits = util.get_debits(db, address=balance['address'], asset=balance['asset'])
        for debit in debits:
            amount -= debit['amount']
        credits = util.get_credits(db, address=balance['address'], asset=balance['asset'])
        for credit in credits:
            amount += credit['amount']
        assert amount == balance['amount']

    tx_index += 1
    parse_hex_cursor.close()



def setup_function(function):
    global db
    global cursor
    cursor.execute('''BEGIN''')

def teardown_function(function):
    cursor.execute('''END''')

# Logs.
try: os.remove(CURR_DIR + '/log.new')
except: pass
logging.basicConfig(filename=CURR_DIR + '/log.new', level=logging.INFO, format='%(message)s')
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

def test_burn ():
    unsigned_tx_hex = burn.create(db, source_default, int(.62 * quantity))

    parse_hex(unsigned_tx_hex)

    output_new[inspect.stack()[0][3]] = unsigned_tx_hex

def test_send ():
    unsigned_tx_hex = send.create(db, source_default, destination_default, small, 'XCP')

    parse_hex(unsigned_tx_hex)

    output_new[inspect.stack()[0][3]] = unsigned_tx_hex

def test_order_buy_xcp ():
    unsigned_tx_hex = order.create(db, source_default, 'BTC', small, 'XCP', small * 2, expiration, 0, fee_provided)

    parse_hex(unsigned_tx_hex)

    output_new[inspect.stack()[0][3]] = unsigned_tx_hex

def test_order_sell_xcp ():
    unsigned_tx_hex = order.create(db, source_default, 'XCP', round(small * 2.1), 'BTC', small, expiration, fee_required, config.MIN_FEE)

    parse_hex(unsigned_tx_hex)

    output_new[inspect.stack()[0][3]] = unsigned_tx_hex

def test_btcpay ():
    order_match_id = 'dbc1b4c900ffe48d575b5da5c638040125f65db0fe3e24494b76ea986457d986084fed08b978af4d7d196a7446a86b58009e636b611db16211b65a9aadff29c5'
    unsigned_tx_hex = btcpay.create(db, order_match_id)

    parse_hex(unsigned_tx_hex)

    output_new[inspect.stack()[0][3]] = unsigned_tx_hex

def test_issuance_divisible ():
    unsigned_tx_hex = issuance.create(db, source_default, None, 'BBBB', quantity * 10, True)

    parse_hex(unsigned_tx_hex)

    output_new[inspect.stack()[0][3]] = unsigned_tx_hex

def test_issuance_indivisible ():
    unsigned_tx_hex = issuance.create(db, source_default, None, 'BBBC', round(quantity / 1000), False)

    parse_hex(unsigned_tx_hex)

    output_new[inspect.stack()[0][3]] = unsigned_tx_hex

def test_dividend_divisible ():
    unsigned_tx_hex = dividend.create(db, source_default, 6, 'BBBB')

    parse_hex(unsigned_tx_hex)

    output_new[inspect.stack()[0][3]] = unsigned_tx_hex

def test_dividend_indivisible ():
    unsigned_tx_hex = dividend.create(db, source_default, 8, 'BBBC')

    parse_hex(unsigned_tx_hex)

    output_new[inspect.stack()[0][3]] = unsigned_tx_hex

def test_broadcast_initial ():
    unsigned_tx_hex = broadcast.create(db, source_default, 1388000000, 100, fee_multiplier_default, 'Unit Test')

    parse_hex(unsigned_tx_hex)

    output_new[inspect.stack()[0][3]] = unsigned_tx_hex

def test_bet_bullcfd_to_be_liquidated ():
    unsigned_tx_hex = bet.create(db, source_default, source_default, 0, 1388000100, small, round(small / 2), 0.0, 15120, expiration)

    parse_hex(unsigned_tx_hex)

    output_new[inspect.stack()[0][3]] = unsigned_tx_hex

def test_bet_bearcfd_to_be_liquidated ():
    unsigned_tx_hex = bet.create(db, source_default, source_default, 1, 1388000100, round(small / 2), round(small * .83), 0.0, 15120, expiration)

    parse_hex(unsigned_tx_hex)

    output_new[inspect.stack()[0][3]] = unsigned_tx_hex

def test_bet_bullcfd_to_be_settled ():
    unsigned_tx_hex = bet.create(db, source_default, source_default, 0, 1388000100, small * 3, small * 7, 0.0, 5040, expiration)

    parse_hex(unsigned_tx_hex)

    output_new[inspect.stack()[0][3]] = unsigned_tx_hex

def test_bet_bearcfd_to_be_settled ():
    unsigned_tx_hex = bet.create(db, source_default, source_default, 1, 1388000100, small * 7, small * 3, 0.0, 5040, expiration)

    parse_hex(unsigned_tx_hex)

    output_new[inspect.stack()[0][3]] = unsigned_tx_hex

def test_bet_equal ():
    unsigned_tx_hex = bet.create(db, source_default, source_default, 2, 1388000200, small * 15, small * 13, 1, 5040, expiration)

    parse_hex(unsigned_tx_hex)

    output_new[inspect.stack()[0][3]] = unsigned_tx_hex

def test_bet_notequal ():
    unsigned_tx_hex = bet.create(db, source_default, source_default, 3, 1388000200, small * 13, small * 15, 1, 5040, expiration)

    parse_hex(unsigned_tx_hex)

    output_new[inspect.stack()[0][3]] = unsigned_tx_hex

def test_broadcast_liquidate ():
    unsigned_tx_hex = broadcast.create(db, source_default, 1388000050, round(100 - (.415/3) - .00001, 5), fee_multiplier_default, 'Unit Test')

    parse_hex(unsigned_tx_hex)

    output_new[inspect.stack()[0][3]] = unsigned_tx_hex

def test_broadcast_settle ():
    unsigned_tx_hex = broadcast.create(db, source_default, 1388000101, 100.343, fee_multiplier_default, 'Unit Test')

    parse_hex(unsigned_tx_hex)

    output_new[inspect.stack()[0][3]] = unsigned_tx_hex

def test_broadcast_equal ():
    unsigned_tx_hex = broadcast.create(db, source_default, 1388000201, 2, fee_multiplier_default, 'Unit Test')

    parse_hex(unsigned_tx_hex)

    output_new[inspect.stack()[0][3]] = unsigned_tx_hex

def test_order_to_be_cancelled ():
    unsigned_tx_hex = order.create(db, source_default, 'BBBB', small, 'XCP', small, expiration, 0, config.MIN_FEE)

    parse_hex(unsigned_tx_hex)

    output_new[inspect.stack()[0][3]] = unsigned_tx_hex

def test_cancel ():
    unsigned_tx_hex = cancel.create(db, 'ab897fbdedfa502b2d839b6a56100887dccdc507555c282e59589e06300a62e2')

    parse_hex(unsigned_tx_hex)

    output_new[inspect.stack()[0][3]] = unsigned_tx_hex

def test_overburn ():
    unsigned_tx_hex = burn.create(db, source_default, (1 * config.UNIT), overburn=True)  # Try to burn a whole 'nother BTC.

    parse_hex(unsigned_tx_hex)

    output_new[inspect.stack()[0][3]] = unsigned_tx_hex

def test_get_address():
    get_address = util.get_address(db, source_default)
    for field in get_address:
        output_new['get_address_' + field] = get_address[field]

def test_json_rpc():
    thread = api.APIServer()
    thread.daemon = True
    thread.start()
    time.sleep(.1)

    url = 'http://localhost:' + str(config.RPC_PORT) + '/jsonrpc/'
    headers = {'content-type': 'application/json'}
    auth = HTTPBasicAuth(config.RPC_USER, config.RPC_PASSWORD)

    payloads = []
    payloads.append({
        "method": "get_balances",
        "params": {"filters": {'field': 'address', 'op': '==', 'value': source_default}},
        "jsonrpc": "2.0",
        "id": 0,
    })

    for payload in payloads:
        response = requests.post(
            url, data=json.dumps(payload), headers=headers, auth=auth).json()
        response = json.loads(response) # Wierd
        try:
            output_new['rpc.' + payload['method']] = response['result']
        except:
            output_new['rpc.' + payload['method']] = response['error']
        assert response['jsonrpc'] == '2.0'
        assert response['id'] == 0

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
        except Exception:
            print('Key:', key)
            print('Old output:')
            print(output[key])
            print('New output:')
            print(output_new[key])
            raise Exception

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

get_time_left
get_order_match_time_left
get_asset
get_asset_name

debit
credit

bet_match
order_match
get_tx_info
rpc
bitcoind_check
serialize
get_inputs
transaction
"""


"""
Too small:
util.short()
util.isodt()
util.devise()
bet.get_fee_multiplier()
"""



