#! /usr/bin/python3

import os
import hashlib
import binascii
import time
import sqlite3
import appdirs
import logging
import decimal
D = decimal.Decimal
import difflib
import json
import inspect
from threading import Thread
import requests

import os
import sys
CURR_DIR = os.path.dirname(os.path.realpath(os.path.join(os.getcwd(), os.path.expanduser(__file__))))
sys.path.append(os.path.normpath(os.path.join(CURR_DIR, '..')))
from lib import (config, api, util, exceptions, bitcoin, blocks)
from lib import (send, order, btcpay, issuance, broadcast, bet, dividend, burn, cancel, util)

# JSON-RPC Options
CONFIGFILE = os.path.expanduser('~') + '/.bitcoin/bitcoin.conf'
config.PREFIX = b'TEST'
config.RPCCONNECT = 'localhost'
config.RPCPORT = '18332' # Only run tests on testnet.
try:
    with open(CONFIGFILE, 'r') as configfile:
        for line in configfile.readlines():
            if line.startswith('#'):
                continue
            array = line.replace('\n', '').split('=')
            if len(array) != 2:
                continue
            key, value = array[:2]
            if key == 'rpcuser': config.RPCUSER = value
            elif key == 'rpcpassword': config.RPCPASSWORD = value
            elif key == 'rpcconnect': config.RPCCONNECT = value
            elif key == 'rpcport': config.RPCCONNECT = value
except Exception:
    raise exceptions.BitcoinConfError('Put a (valid) copy of your \
bitcoin.conf in ~/.bitcoin/bitcoin.conf')
    sys.exit(1)
config.RPC = 'http://'+config.RPCUSER+':'+config.RPCPASSWORD+'@'+config.RPCCONNECT+':'+config.RPCPORT

config.DATABASE = CURR_DIR + '/counterparty.test.db'
try: os.remove(config.DATABASE)
except: pass
db = sqlite3.connect(config.DATABASE)
db.isolation_level = None
db.row_factory = sqlite3.Row

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
fee_multiplier_default = round(D(.05) * D(1e8))

# Each tx has a block_index equal to its tx_index

print('Run `test.py` with `py.test test.py`.')




def check_balance():
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

def parse_tx (tx_index, data, parse_func):
    parse_tx_cursor = db.cursor()
    parse_tx_cursor.execute('''SELECT * FROM transactions \
                      WHERE tx_index=?''', (tx_index,))
    tx = parse_tx_cursor.fetchone()
    if data:
        message = data[len(config.PREFIX) + 4:]
    else:
        message = None

    parse_func(db, tx, message)
    parse_tx_cursor.close()
    db.commit()

    # After parsing every transaction, check that the credits, debits sum properly.
    check_balance()

def tx_insert (source, destination, btc_amount, fee, data):
    
    tx_insert_cursor = db.cursor()
    tx_hash = hashlib.sha256(chr(tx_index).encode('utf-8')).hexdigest()
    global tx_index
    tx_insert_cursor.execute('''INSERT INTO transactions(
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
    tx_insert_cursor.close()
    tx_index += 1

def get_tx_data (tx_hex):
    """Accepts unsigned transactions."""
    tx = bitcoin.rpc('decoderawtransaction', [tx_hex])

    # Get destination output and data output.
    destination, btc_amount, data = None, None, None
    for vout in tx['vout']:

        # Destination is the first output before the data.
        if not destination and not btc_amount and not data:
            if 'addresses' in vout['scriptPubKey']:
                address = vout['scriptPubKey']['addresses'][0]
                if bitcoin.base58_decode(address, config.ADDRESSVERSION):  # If address is valid…
                    destination, btc_amount = address, round(D(vout['value']) * config.UNIT)

        # Assume only one OP_RETURN output.
        if not data:
            asm = vout['scriptPubKey']['asm'].split(' ')
            if asm[0] == 'OP_RETURN' and len(asm) == 2:
                data = binascii.unhexlify(bytes(asm[1], 'utf-8'))

    return destination, btc_amount, data





def setup_function(function):
    global db

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

# TODO: replace inspect.stack()[0][3] with inspect.currentframe().f_code.co_name?

def test_start ():
    logging.info('START TEST')

def test_initialise ():
    blocks.initialise(db)

def test_burn ():
    unsigned_tx_hex = burn.create(db, source_default, int(.62 * quantity), test=True)

    destination, btc_amount, data = get_tx_data(unsigned_tx_hex)
    tx_insert(source_default, destination, btc_amount, config.MIN_FEE, data)

    parse_tx(tx_index - 1, data, burn.parse)

    output_new[inspect.stack()[0][3]] = unsigned_tx_hex

def test_send ():
    unsigned_tx_hex = send.create(db, source_default, destination_default, small, 'XCP', test=True)

    destination, btc_amount, data = get_tx_data(unsigned_tx_hex)
    tx_insert(source_default, destination, btc_amount, config.MIN_FEE, data)

    parse_tx(tx_index - 1, data, send.parse)

    output_new[inspect.stack()[0][3]] = unsigned_tx_hex

def test_order_buy_xcp ():
    unsigned_tx_hex = order.create(db, source_default, 'BTC', small, 'XCP', small * 2, expiration, 0, fee_provided, test=True)

    destination, btc_amount, data = get_tx_data(unsigned_tx_hex)
    tx_insert(source_default, destination, btc_amount, fee_provided, data)

    parse_tx(tx_index - 1, data, order.parse)

    output_new[inspect.stack()[0][3]] = unsigned_tx_hex

def test_order_sell_xcp ():
    unsigned_tx_hex = order.create(db, source_default, 'XCP', round(small * 2.1), 'BTC', small, expiration, fee_required, 0, test=True)

    destination, btc_amount, data = get_tx_data(unsigned_tx_hex)
    tx_insert(source_default, destination, btc_amount, config.MIN_FEE, data)

    parse_tx(tx_index - 1, data, order.parse)

    output_new[inspect.stack()[0][3]] = unsigned_tx_hex

def test_btcpay ():
    order_match_id = 'dbc1b4c900ffe48d575b5da5c638040125f65db0fe3e24494b76ea986457d986084fed08b978af4d7d196a7446a86b58009e636b611db16211b65a9aadff29c5'
    unsigned_tx_hex = btcpay.create(db, order_match_id, test=True)

    destination, btc_amount, data = get_tx_data(unsigned_tx_hex)
    tx_insert(source_default, destination, btc_amount, config.MIN_FEE, data)
    parse_tx(tx_index - 1, data, btcpay.parse)

    output_new[inspect.stack()[0][3]] = unsigned_tx_hex

def test_issuance_divisible ():
    unsigned_tx_hex = issuance.create(db, source_default, None, 'BBBB', quantity * 10, True, test=True)

    destination, btc_amount, data = get_tx_data(unsigned_tx_hex)
    tx_insert(source_default, destination, btc_amount, config.MIN_FEE, data)

    parse_tx(tx_index - 1, data, issuance.parse)

    output_new[inspect.stack()[0][3]] = unsigned_tx_hex

def test_issuance_indivisible ():
    unsigned_tx_hex = issuance.create(db, source_default, None, 'BBBC', round(quantity / 1000), False, test=True)

    destination, btc_amount, data = get_tx_data(unsigned_tx_hex)
    tx_insert(source_default, destination, btc_amount, config.MIN_FEE, data)
    parse_tx(tx_index - 1, data, issuance.parse)

    output_new[inspect.stack()[0][3]] = unsigned_tx_hex

def test_dividend_divisible ():
    unsigned_tx_hex = dividend.create(db, source_default, 6, 'BBBB', test=True)

    destination, btc_amount, data = get_tx_data(unsigned_tx_hex)
    tx_insert(source_default, destination, btc_amount, config.MIN_FEE, data)
    parse_tx(tx_index - 1, data, dividend.parse)

    output_new[inspect.stack()[0][3]] = unsigned_tx_hex

def test_dividend_indivisible ():
    unsigned_tx_hex = dividend.create(db, source_default, 8, 'BBBC', test=True)

    destination, btc_amount, data = get_tx_data(unsigned_tx_hex)
    tx_insert(source_default, destination, btc_amount, config.MIN_FEE, data)
    parse_tx(tx_index - 1, data, dividend.parse)

    output_new[inspect.stack()[0][3]] = unsigned_tx_hex

def test_broadcast_initial ():
    unsigned_tx_hex = broadcast.create(db, source_default, 1388000000, 100, fee_multiplier_default, 'Unit Test', test=True)

    destination, btc_amount, data = get_tx_data(unsigned_tx_hex)
    tx_insert(source_default, destination, btc_amount, config.MIN_FEE, data)
    parse_tx(tx_index - 1, data, broadcast.parse)

    output_new[inspect.stack()[0][3]] = unsigned_tx_hex

def test_bet_bullcfd_to_be_liquidated ():
    unsigned_tx_hex = bet.create(db, source_default, source_default, 0, 1388000100, small, round(small / 2), 0.0, 15120, expiration, test=True)

    destination, btc_amount, data = get_tx_data(unsigned_tx_hex)
    tx_insert(source_default, destination, btc_amount, config.MIN_FEE, data)
    parse_tx(tx_index - 1, data, bet.parse)

    output_new[inspect.stack()[0][3]] = unsigned_tx_hex

def test_bet_bearcfd_to_be_liquidated ():
    unsigned_tx_hex = bet.create(db, source_default, source_default, 1, 1388000100, round(small / 2), round(small * .83), 0.0, 15120, expiration, test=True)

    destination, btc_amount, data = get_tx_data(unsigned_tx_hex)
    tx_insert(source_default, destination, btc_amount, config.MIN_FEE, data)
    parse_tx(tx_index - 1, data, bet.parse)

    output_new[inspect.stack()[0][3]] = unsigned_tx_hex

def test_bet_bullcfd_to_be_settled ():
    unsigned_tx_hex = bet.create(db, source_default, source_default, 0, 1388000100, small * 3, small * 7, 0.0, 5040, expiration, test=True)

    destination, btc_amount, data = get_tx_data(unsigned_tx_hex)
    tx_insert(source_default, destination, btc_amount, config.MIN_FEE, data)
    parse_tx(tx_index - 1, data, bet.parse)

    output_new[inspect.stack()[0][3]] = unsigned_tx_hex

def test_bet_bearcfd_to_be_settled ():
    unsigned_tx_hex = bet.create(db, source_default, source_default, 1, 1388000100, small * 7, small * 3, 0.0, 5040, expiration, test=True)

    destination, btc_amount, data = get_tx_data(unsigned_tx_hex)
    tx_insert(source_default, destination, btc_amount, config.MIN_FEE, data)
    parse_tx(tx_index - 1, data, bet.parse)

    output_new[inspect.stack()[0][3]] = unsigned_tx_hex

def test_bet_equal ():
    unsigned_tx_hex = bet.create(db, source_default, source_default, 2, 1388000200, small * 15, small * 13, 1, 5040, expiration, test=True)

    destination, btc_amount, data = get_tx_data(unsigned_tx_hex)
    tx_insert(source_default, destination, btc_amount, config.MIN_FEE, data)
    parse_tx(tx_index - 1, data, bet.parse)

    output_new[inspect.stack()[0][3]] = unsigned_tx_hex

def test_bet_notequal ():
    unsigned_tx_hex = bet.create(db, source_default, source_default, 3, 1388000200, small * 13, small * 15, 1, 5040, expiration, test=True)

    destination, btc_amount, data = get_tx_data(unsigned_tx_hex)
    tx_insert(source_default, destination, btc_amount, config.MIN_FEE, data)
    parse_tx(tx_index - 1, data, bet.parse)

    output_new[inspect.stack()[0][3]] = unsigned_tx_hex

def test_broadcast_liquidate ():
    unsigned_tx_hex = broadcast.create(db, source_default, 1388000050, round(100 - (.05 / 3) - .00001, 5), fee_multiplier_default, 'Unit Test', test=True)

    destination, btc_amount, data = get_tx_data(unsigned_tx_hex)
    tx_insert(source_default, destination, btc_amount, config.MIN_FEE, data)
    parse_tx(tx_index - 1, data, broadcast.parse)

    output_new[inspect.stack()[0][3]] = unsigned_tx_hex

def test_broadcast_settle ():
    unsigned_tx_hex = broadcast.create(db, source_default, 1388000101, 100.343, fee_multiplier_default, 'Unit Test', test=True)

    destination, btc_amount, data = get_tx_data(unsigned_tx_hex)
    tx_insert(source_default, destination, btc_amount, config.MIN_FEE, data)
    parse_tx(tx_index - 1, data, broadcast.parse)

    output_new[inspect.stack()[0][3]] = unsigned_tx_hex

def test_broadcast_equal ():
    unsigned_tx_hex = broadcast.create(db, source_default, 1388000201, 2, fee_multiplier_default, 'Unit Test', test=True)

    destination, btc_amount, data = get_tx_data(unsigned_tx_hex)
    tx_insert(source_default, destination, btc_amount, config.MIN_FEE, data)
    parse_tx(tx_index - 1, data, broadcast.parse)

    output_new[inspect.stack()[0][3]] = unsigned_tx_hex

def test_order_to_be_cancelled ():
    unsigned_tx_hex = order.create(db, source_default, 'BBBB', small, 'XCP', small, expiration, 0, 0, test=True)

    destination, btc_amount, data = get_tx_data(unsigned_tx_hex)
    tx_insert(source_default, destination, btc_amount, fee_provided, data)

    parse_tx(tx_index - 1, data, order.parse)

    output_new[inspect.stack()[0][3]] = unsigned_tx_hex

def test_cancel ():
    unsigned_tx_hex = cancel.create(db, 'ab897fbdedfa502b2d839b6a56100887dccdc507555c282e59589e06300a62e2', test=True)

    destination, btc_amount, data = get_tx_data(unsigned_tx_hex)
    tx_insert(source_default, destination, btc_amount, fee_provided, data)

    parse_tx(tx_index - 1, data, cancel.parse)

    output_new[inspect.stack()[0][3]] = unsigned_tx_hex

def test_overburn ():
    unsigned_tx_hex = burn.create(db, source_default, (1 * config.UNIT), test=True, overburn=True)  # Try to burn a whole 'nother BTC.

    destination, btc_amount, data = get_tx_data(unsigned_tx_hex)
    tx_insert(source_default, destination, btc_amount, config.MIN_FEE, data)

    parse_tx(tx_index - 1, data, burn.parse)

    output_new[inspect.stack()[0][3]] = unsigned_tx_hex

def test_get_address():
    get_address = util.get_address(db, source_default)
    for field in get_address:
        output_new['get_address_' + field] = get_address[field]

def test_json_rpc():
    thread=api.reqthread()
    thread.daemon = True
    thread.start()
    time.sleep(.1)

    url = "http://localhost:9999/jsonrpc"
    headers = {'content-type': 'application/json'}

    payloads = []
    payloads.append({
        "method": "get_balances",
        "params": {"address": source_default, "asset": None},
        "jsonrpc": "2.0",
        "id": 0,
    })

    for payload in payloads:
        response = requests.post(
            url, data=json.dumps(payload), headers=headers).json()
        print(response['result'])   # TODO
        try:
            output_new['rpc.' + payload['method']] = response['result']
        except:
            output_new['rpc.' + payload['method']] = response['error']
        assert response['jsonrpc'] == '2.0'
        assert response['id'] == 0

def test_stop():
    db.commit()
    logging.info('STOP TEST')


def test_db():
    with open(CURR_DIR + '/db.dump', 'r') as f:
        good_data = f.readlines()

    # Hack
    with open(CURR_DIR + '/db.new.dump', 'w') as f:
        f.write('\n'.join(list(db.iterdump())) + '\n')
    with open(CURR_DIR + '/db.new.dump', 'r') as f:
        new_data = f.readlines()

    db_diff = list(difflib.unified_diff(good_data, new_data, n=0))
    assert not len(db_diff)

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



