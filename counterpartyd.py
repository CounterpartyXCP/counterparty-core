#! /usr/bin/env python3
import os
import argparse
import json
import decimal
import sys
import logging
import unicodedata
import time
import dateutil.parser
import calendar
import configparser
from threading import Thread
import binascii

import requests
import appdirs
from prettytable import PrettyTable

from lib import (config, api, util, exceptions, bitcoin, blocks)
if os.name == 'nt':
    from lib import util_windows

D = decimal.Decimal
json_print = lambda x: print(json.dumps(x, sort_keys=True, indent=4))

def get_address (db, address):
    address_dict = {}
    address_dict['balances'] = util.api('get_balances', {'filters': [('address', '==', address),]})
    address_dict['debits'] = util.api('get_debits', {'filters': [('address', '==', address),]})
    address_dict['credits'] = util.api('get_credits', {'filters': [('address', '==', address),]})
    address_dict['burns'] = util.api('get_burns', {'filters': [('source', '==', address),]})
    address_dict['sends'] = util.api('get_sends', {'filters': [('source', '==', address), ('destination', '==', address)], 'filterop': 'or'})
    address_dict['orders'] = util.api('get_orders', {'filters': [('source', '==', address),]})
    address_dict['order_matches'] = util.api('get_order_matches', {'filters': [('tx0_address', '==', address), ('tx1_address', '==', address)], 'filterop': 'or'})
    address_dict['btcpays'] = util.api('get_btcpays', {'filters': [('source', '==', address), ('destination', '==', address)], 'filterop': 'or'})
    address_dict['issuances'] = util.api('get_issuances', {'filters': [('source', '==', address),]})
    address_dict['broadcasts'] = util.api('get_broadcasts', {'filters': [('source', '==', address),]})
    address_dict['bets'] = util.api('get_bets', {'filters': [('source', '==', address),]})
    address_dict['bet_matches'] = util.api('get_bet_matches', {'filters': [('tx0_address', '==', address), ('tx1_address', '==', address)], 'filterop': 'or'})
    address_dict['dividends'] = util.api('get_dividends', {'filters': [('source', '==', address),]})
    address_dict['cancels'] = util.api('get_cancels', {'filters': [('source', '==', address),]})
    address_dict['callbacks'] = util.api('get_callbacks', {'filters': [('source', '==', address),]})
    address_dict['bet_expirations'] = util.api('get_bet_expirations', {'filters': [('source', '==', address),]})
    address_dict['order_expirations'] = util.api('get_order_expirations', {'filters': [('source', '==', address),]})
    address_dict['bet_match_expirations'] = util.api('get_bet_match_expirations', {'filters': [('tx0_address', '==', address), ('tx1_address', '==', address)], 'filterop': 'or'})
    address_dict['order_match_expirations'] = util.api('get_order_match_expirations', {'filters': [('tx0_address', '==', address), ('tx1_address', '==', address)], 'filterop': 'or'})
    return address_dict


def format_order (order):
    give_quantity = util.devise(db, D(order['give_quantity']), order['give_asset'], 'output')
    get_quantity = util.devise(db, D(order['get_quantity']), order['get_asset'], 'output')
    give_remaining = util.devise(db, D(order['give_remaining']), order['give_asset'], 'output')
    get_remaining = util.devise(db, D(order['get_remaining']), order['get_asset'], 'output')
    give_asset = order['give_asset']
    get_asset = order['get_asset']

    if get_asset < give_asset:
        price = util.devise(db, D(order['get_quantity']) / D(order['give_quantity']), 'price', 'output')
        price_assets = get_asset + '/' + give_asset + ' ask'
    else:
        price = util.devise(db, D(order['give_quantity']) / D(order['get_quantity']), 'price', 'output')
        price_assets = give_asset + '/' + get_asset + ' bid'

    return [D(give_remaining), give_asset, price, price_assets, str(order['fee_required'] / config.UNIT), str(order['fee_provided'] / config.UNIT), order['expire_index'] - util.last_block(db)['block_index'], order['tx_hash']]

def format_bet (bet):
    odds = D(bet['counterwager_quantity']) / D(bet['wager_quantity'])

    if not bet['target_value']: target_value = None
    else: target_value = bet['target_value']
    if not bet['leverage']: leverage = None
    else: leverage = util.devise(db, D(bet['leverage']) / 5040, 'leverage', 'output')

    return [util.BET_TYPE_NAME[bet['bet_type']], bet['feed_address'], util.isodt(bet['deadline']), target_value, leverage, str(bet['wager_remaining'] / config.UNIT) + ' XCP', util.devise(db, odds, 'odds', 'output'), bet['expire_index'] - util.last_block(db)['block_index'], bet['tx_hash']]

def format_order_match (db, order_match):
    order_match_id = order_match['tx0_hash'] + order_match['tx1_hash']
    order_match_time_left = order_match['match_expire_index'] - util.last_block(db)['block_index']
    return [order_match_id, order_match_time_left]

def format_feed (feed):
    timestamp = util.isodt(feed['timestamp'])
    if not feed['text']:
        text = '<Locked>'
    else:
        text = feed['text']
    return [feed['source'], timestamp, text, feed['value'], D(feed['fee_fraction_int']) / D(1e8)]

def market (give_asset, get_asset):

    # Your Pending Orders Matches.
    awaiting_btcs = util.get_order_matches(db, status='pending', is_mine=True)
    table = PrettyTable(['Matched Order ID', 'Time Left'])
    for order_match in awaiting_btcs:
        order_match = format_order_match(db, order_match)
        table.add_row(order_match)
    print('Your Pending Order Matches')
    print(table)
    print('\n')

    # Open orders.
    orders = util.get_orders(db, status='open', show_expired=False)
    table = PrettyTable(['Give Quantity', 'Give Asset', 'Price', 'Price Assets', 'Required BTC Fee', 'Provided BTC Fee', 'Time Left', 'Tx Hash'])
    for order in orders:
        if give_asset and order['give_asset'] != give_asset: continue
        if get_asset and order['get_asset'] != get_asset: continue
        order = format_order(order)
        table.add_row(order)
    print('Open Orders')
    table = table.get_string(sortby='Price')
    print(table)
    print('\n')

    # Open bets.
    bets = util.get_bets(db, status='open')
    table = PrettyTable(['Bet Type', 'Feed Address', 'Deadline', 'Target Value', 'Leverage', 'Wager', 'Odds', 'Time Left', 'Tx Hash'])
    for bet in bets:
        bet = format_bet(bet)
        table.add_row(bet)
    print('Open Bets')
    print(table)
    print('\n')

    # Feeds
    broadcasts = util.get_broadcasts(db, status='valid', order_by='timestamp', order_dir='desc')
    table = PrettyTable(['Feed Address', 'Timestamp', 'Text', 'Value', 'Fee Fraction'])
    seen_addresses = []
    for broadcast in broadcasts:
        # Only show feeds with broadcasts in the last two weeks.
        last_block_time = util.last_block(db)['block_time']
        if broadcast['timestamp'] + config.TWO_WEEKS < last_block_time:
            continue
        # Always show only the latest broadcast from a feed address.
        if broadcast['source'] not in seen_addresses:
            feed = format_feed(broadcast)
            table.add_row(feed)
            seen_addresses.append(broadcast['source'])
        else:
            continue
    print('Feeds')
    print(table)


def cli(method, params, unsigned):

    # Get unsigned transaction serialisation.
    if bitcoin.is_valid(params['source']):
        if bitcoin.is_mine(params['source']):
            bitcoin.wallet_unlock()
        else:
            print('Source not in Bitcoind wallet.')
            answer = input('Public key (hexadecimal) or Private key (Wallet Import Format): ')

            # Public key or private key?
            try:
                binascii.unhexlify(answer)  # Check if hex.
                params['pubkey'] = answer   # If hex, assume public key.
                private_key_wif = None
            except binascii.Error:
                private_key_wif = answer    # Else, assume private key.
                params['pubkey'] = bitcoin.private_key_to_public_key(private_key_wif)
    else:
        raise exceptions.AddressError('Invalid address.')

    unsigned_tx_hex = util.api(method, params)
    print('Transaction (unsigned):', unsigned_tx_hex)

    # Ask to sign and broadcast.
    if not unsigned and input('Sign and broadcast? (y/N) ') == 'y':
        if bitcoin.is_mine(params['source']):
            private_key_wif = None
        elif not private_key_wif:   # If private key was not given earlier.
            private_key_wif = input('Private key (Wallet Import Format): ')

        # Sign and broadcast.
        signed_tx_hex = bitcoin.sign_tx(unsigned_tx_hex, private_key_wif=private_key_wif)
        print('Transaction (signed):', signed_tx_hex)
        print('Hash of transaction (broadcasted):', bitcoin.broadcast_tx(signed_tx_hex))


def set_options (data_dir=None,
                 bitcoind_rpc_connect=None, bitcoind_rpc_port=None,
                 bitcoind_rpc_user=None, bitcoind_rpc_password=None,
                 insight_enable=None, insight_connect=None, insight_port=None,
                 rpc_host=None, rpc_port=None, rpc_user=None, rpc_password=None,
                 log_file=None, pid_file=None, api_num_threads=None, api_request_queue_size=None,
                 database_file=None, testnet=False, testcoin=False, unittest=False, carefulness=0, force=False):

    # Unittests always run on testnet.
    if unittest and not testnet:
        raise Exception # TODO

    if force:
        config.FORCE = force
    else:
        config.FORCE = False

    # Data directory
    if not data_dir:
        config.DATA_DIR = appdirs.user_data_dir(appauthor='Counterparty', appname='counterpartyd', roaming=True)
    else:
        config.DATA_DIR = os.path.expanduser(data_dir)
    if not os.path.isdir(config.DATA_DIR): os.mkdir(config.DATA_DIR)

    # Configuration file
    configfile = configparser.ConfigParser()
    config_path = os.path.join(config.DATA_DIR, 'counterpartyd.conf')
    configfile.read(config_path)
    has_config = 'Default' in configfile
    #logging.debug("Config file: %s; Exists: %s" % (config_path, "Yes" if has_config else "No"))

    # testnet
    if testnet:
        config.TESTNET = testnet
    elif has_config and 'testnet' in configfile['Default']:
        config.TESTNET = configfile['Default'].getboolean('testnet')
    else:
        config.TESTNET = False

    # testcoin
    if testcoin:
        config.TESTCOIN = testcoin
    elif has_config and 'testcoin' in configfile['Default']:
        config.TESTCOIN = configfile['Default'].getboolean('testcoin')
    else:
        config.TESTCOIN = False

    # carefulness (check conservation of assets)
    if carefulness:
        config.CAREFULNESS = carefulness
    elif has_config and 'carefulness' in configfile['Default']:
        config.CAREFULNESS = configfile['Default'].getboolean('carefulness')
    else:
        config.CAREFULNESS = 0

    ##############
    # THINGS WE CONNECT TO

    # Bitcoind RPC host
    if bitcoind_rpc_connect:
        config.BITCOIND_RPC_CONNECT = bitcoind_rpc_connect
    elif has_config and 'bitcoind-rpc-connect' in configfile['Default'] and configfile['Default']['bitcoind-rpc-connect']:
        config.BITCOIND_RPC_CONNECT = configfile['Default']['bitcoind-rpc-connect']
    else:
        config.BITCOIND_RPC_CONNECT = 'localhost'

    # Bitcoind RPC port
    if bitcoind_rpc_port:
        config.BITCOIND_RPC_PORT = bitcoind_rpc_port
    elif has_config and 'bitcoind-rpc-port' in configfile['Default'] and configfile['Default']['bitcoind-rpc-port']:
        config.BITCOIND_RPC_PORT = configfile['Default']['bitcoind-rpc-port']
    else:
        if config.TESTNET:
            config.BITCOIND_RPC_PORT = 18332
        else:
            config.BITCOIND_RPC_PORT = 8332
    try:
        config.BITCOIND_RPC_PORT = int(config.BITCOIND_RPC_PORT)
        assert int(config.BITCOIND_RPC_PORT) > 1 and int(config.BITCOIND_RPC_PORT) < 65535
    except:
        raise Exception("Please specific a valid port number bitcoind-rpc-port configuration parameter")

    # Bitcoind RPC user
    if bitcoind_rpc_user:
        config.BITCOIND_RPC_USER = bitcoind_rpc_user
    elif has_config and 'bitcoind-rpc-user' in configfile['Default'] and configfile['Default']['bitcoind-rpc-user']:
        config.BITCOIND_RPC_USER = configfile['Default']['bitcoind-rpc-user']
    else:
        config.BITCOIND_RPC_USER = 'bitcoinrpc'

    # Bitcoind RPC password
    if bitcoind_rpc_password:
        config.BITCOIND_RPC_PASSWORD = bitcoind_rpc_password
    elif has_config and 'bitcoind-rpc-password' in configfile['Default'] and configfile['Default']['bitcoind-rpc-password']:
        config.BITCOIND_RPC_PASSWORD = configfile['Default']['bitcoind-rpc-password']
    else:
        raise exceptions.ConfigurationError('bitcoind RPC password not set. (Use configuration file or --bitcoind-rpc-password=PASSWORD)')

    config.BITCOIND_RPC = 'http://' + config.BITCOIND_RPC_USER + ':' + config.BITCOIND_RPC_PASSWORD + '@' + config.BITCOIND_RPC_CONNECT + ':' + str(config.BITCOIND_RPC_PORT)

    # insight enable
    if insight_enable:
        config.INSIGHT_ENABLE = insight_enable
    elif has_config and 'insight-enable' in configfile['Default']:
        config.INSIGHT_ENABLE = configfile['Default'].getboolean('insight-enable')
    else:
        config.INSIGHT_ENABLE = False
    
    if unittest:
        config.INSIGHT_ENABLE = True #override when running test suite
    if config.TESTNET:
        config.INSIGHT_ENABLE = True

    # insight API host
    if insight_connect:
        config.INSIGHT_CONNECT = insight_connect
    elif has_config and 'insight-connect' in configfile['Default'] and configfile['Default']['insight-connect']:
        config.INSIGHT_CONNECT = configfile['Default']['insight-connect']
    else:
        config.INSIGHT_CONNECT = 'localhost'

    # insight API port
    if insight_port:
        config.INSIGHT_PORT = insight_port
    elif has_config and 'insight-port' in configfile['Default'] and configfile['Default']['insight-port']:
        config.INSIGHT_PORT = configfile['Default']['insight-port']
    else:
        if config.TESTNET:
            config.INSIGHT_PORT = 3001
        else:
            config.INSIGHT_PORT = 3000
    try:
        config.INSIGHT_PORT = int(config.INSIGHT_PORT)
        assert int(config.INSIGHT_PORT) > 1 and int(config.INSIGHT_PORT) < 65535
    except:
        raise Exception("Please specific a valid port number insight-port configuration parameter")

    config.INSIGHT = 'http://' + config.INSIGHT_CONNECT + ':' + str(config.INSIGHT_PORT)

    ##############
    # THINGS WE SERVE

    # counterpartyd API RPC host
    if rpc_host:
        config.RPC_HOST = rpc_host
    elif has_config and 'rpc-host' in configfile['Default'] and configfile['Default']['rpc-host']:
        config.RPC_HOST = configfile['Default']['rpc-host']
    else:
        config.RPC_HOST = 'localhost'

    #  counterpartyd API RPC port
    if rpc_port:
        config.RPC_PORT = rpc_port
    elif has_config and 'rpc-port' in configfile['Default'] and configfile['Default']['rpc-port']:
        config.RPC_PORT = configfile['Default']['rpc-port']
    else:
        if config.TESTNET:
            if config.TESTCOIN:
                config.RPC_PORT = 14001
            else:
                config.RPC_PORT = 14000
        else:
            if config.TESTCOIN:
                config.RPC_PORT = 4001
            else:
                config.RPC_PORT = 4000
    try:
        config.RPC_PORT = int(config.RPC_PORT)
        assert int(config.RPC_PORT) > 1 and int(config.RPC_PORT) < 65535
    except:
        raise Exception("Please specific a valid port number rpc-port configuration parameter")

    #  counterpartyd API RPC user
    if rpc_user:
        config.RPC_USER = rpc_user
    elif has_config and 'rpc-user' in configfile['Default'] and configfile['Default']['rpc-user']:
        config.RPC_USER = configfile['Default']['rpc-user']
    else:
        config.RPC_USER = 'rpc'

    #  counterpartyd API RPC password
    if rpc_password:
        config.RPC_PASSWORD = rpc_password
    elif has_config and 'rpc-password' in configfile['Default'] and configfile['Default']['rpc-password']:
        config.RPC_PASSWORD = configfile['Default']['rpc-password']
    else:
        raise exceptions.ConfigurationError('RPC password not set. (Use configuration file or --rpc-password=PASSWORD)')

    config.RPC = 'http://' + config.RPC_USER + ':' + config.RPC_PASSWORD + '@' + config.RPC_HOST + ':' + str(config.RPC_PORT)

    ##############
    # OTHER SETTINGS

    # Log
    if log_file:
        config.LOG = log_file
    elif has_config and 'log-file' in configfile['Default']:
        config.LOG = configfile['Default']['log-file']
    else:
        string = 'counterpartyd'
        if config.TESTNET:
            string += '.testnet'
        if config.TESTCOIN:
            string += '.testcoin'
        config.LOG = os.path.join(config.DATA_DIR, string + '.log')

    # PID file
    if pid_file:
        config.PID = pid_file
    elif has_config and 'pid-file' in configfile['Default']:
        config.PID = configfile['Default']['pid-file']
    else:
        config.PID = os.path.join(config.DATA_DIR, 'counterpartyd.pid')

    if not unittest:
        if config.TESTCOIN:
            config.PREFIX = b'XX'                   # 2 bytes (possibly accidentally created)
        else:
            config.PREFIX = b'CNTRPRTY'             # 8 bytes
    else:
        config.PREFIX = config.UNITTEST_PREFIX
        
    if api_num_threads:
        config.API_NUM_THREADS = int(api_num_threads)
    elif has_config and 'api-num-threads' in configfile['Default']:
        config.API_NUM_THREADS = int(configfile['Default']['api-num-threads'])
    else:
        config.API_NUM_THREADS = 15 #(not suitable for multiuser, high-performance production)

    if api_request_queue_size:
        config.API_REQUEST_QUEUE_SIZE = int(api_request_queue_size)
    elif has_config and 'api-request-queue-size' in configfile['Default']:
        config.API_REQUEST_QUEUE_SIZE = int(configfile['Default']['api-request-queue-size'])
    else:
        config.API_REQUEST_QUEUE_SIZE = 20 #(not suitable for multiuser, high-performance production)

    # Database
    if database_file:
        config.DATABASE = database_file
    else:
        string = 'counterpartyd.' + str(config.VERSION_MAJOR)
        if config.TESTNET:
            string += '.testnet'
        if config.TESTCOIN:
            string += '.testcoin'
        config.DATABASE = os.path.join(config.DATA_DIR, string + '.db')

    # (more) Testnet
    if config.TESTNET:
        if config.TESTCOIN:
            config.ADDRESSVERSION = b'\x6f'
            config.BLOCK_FIRST = 154908
            config.BURN_START = 154908
            config.BURN_END = 4017708   # Fifty years, at ten minutes per block.
            config.UNSPENDABLE = 'mvCounterpartyXXXXXXXXXXXXXXW24Hef'
        else:
            config.ADDRESSVERSION = b'\x6f'
            config.BLOCK_FIRST = 154908
            config.BURN_START = 154908
            config.BURN_END = 4017708   # Fifty years, at ten minutes per block.
            config.UNSPENDABLE = 'mvCounterpartyXXXXXXXXXXXXXXW24Hef'
    else:
        if config.TESTCOIN:
            config.ADDRESSVERSION = b'\x00'
            config.BLOCK_FIRST = 278270
            config.BURN_START = 278310
            config.BURN_END = 2500000   # A long time.
            config.UNSPENDABLE = '1CounterpartyXXXXXXXXXXXXXXXUWLpVr'
        else:
            config.ADDRESSVERSION = b'\x00'
            config.BLOCK_FIRST = 278270
            config.BURN_START = 278310
            config.BURN_END = 283810
            config.UNSPENDABLE = '1CounterpartyXXXXXXXXXXXXXXXUWLpVr'

def balances (address):
    if not bitcoin.base58_decode(address, config.ADDRESSVERSION):
        raise exceptions.AddressError('Not a valid Bitcoin address:',
                                             address)
    address_data = get_address(db, address=address)
    balances = address_data['balances']
    table = PrettyTable(['Asset', 'Amount'])
    table.add_row(['BTC', bitcoin.get_btc_balance(address, normalize=True)])  # BTC
    for balance in balances:
        asset = balance['asset']
        quantity = util.devise(db, balance['quantity'], balance['asset'], 'output')
        table.add_row([asset, quantity])
    print('Balances')
    print(table.get_string())


if __name__ == '__main__':
    if os.name == 'nt':
        #patch up cmd.exe's "challenged" (i.e. broken/non-existent) UTF-8 logging
        util_windows.fix_win32_unicode()
    
    # Parse command-line arguments.
    parser = argparse.ArgumentParser(prog='counterpartyd', description='the reference implementation of the Counterparty protocol')
    parser.add_argument('-V', '--version', action='version', version="counterpartyd v%s" % config.VERSION_STRING)

    parser.add_argument('-v', '--verbose', dest='verbose', action='store_true', help='sets log level to DEBUG instead of WARNING')
    parser.add_argument('--force', action='store_true', help='don\'t check whether Bitcoind is caught up')
    parser.add_argument('--testnet', action='store_true', help='use Bitcoin testnet addresses and block numbers')
    parser.add_argument('--testcoin', action='store_true', help='use the test Counterparty network on every blockchain')
    parser.add_argument('--unsigned', action='store_true', help='print out unsigned hex of transaction; do not sign or broadcast')
    parser.add_argument('--carefulness', type=int, default=0, help='check conservation of assets after every CAREFULNESS transactions (potentially slow)')
    parser.add_argument('--unconfirmed', action='store_true', help='allow the spending of unconfirmed transaction outputs')

    parser.add_argument('--data-dir', help='the directory in which to keep the database, config file and log file, by default')
    parser.add_argument('--database-file', help='the location of the SQLite3 database')
    parser.add_argument('--config-file', help='the location of the configuration file')
    parser.add_argument('--log-file', help='the location of the log file')
    parser.add_argument('--pid-file', help='the location of the pid file')
    parser.add_argument('--api-num-threads', help='the number of threads created for API request processing (CherryPy WSGI, default 10)')
    parser.add_argument('--api-request-queue-size', help='the size of the API request queue (CherryPY WSGI, default 5)')

    parser.add_argument('--bitcoind-rpc-connect', help='the hostname or IP of the bitcoind JSON-RPC server')
    parser.add_argument('--bitcoind-rpc-port', type=int, help='the bitcoind JSON-RPC port to connect to')
    parser.add_argument('--bitcoind-rpc-user', help='the username used to communicate with Bitcoind over JSON-RPC')
    parser.add_argument('--bitcoind-rpc-password', help='the password used to communicate with Bitcoind over JSON-RPC')

    parser.add_argument('--insight-enable', action='store_true', default=False, help='enable the use of insight, instead of blockchain.info')
    parser.add_argument('--insight-connect', help='the insight server hostname or IP to connect to')
    parser.add_argument('--insight-port', type=int, help='the insight server port to connect to')

    parser.add_argument('--rpc-host', help='the IP of the interface to bind to for providing JSON-RPC API access (0.0.0.0 for all interfaces)')
    parser.add_argument('--rpc-port', type=int, help='port on which to provide the counterpartyd JSON-RPC API')
    parser.add_argument('--rpc-user', help='required username to use the counterpartyd JSON-RPC API (via HTTP basic auth)')
    parser.add_argument('--rpc-password', help='required password (for rpc-user) to use the counterpartyd JSON-RPC API (via HTTP basic auth)')

    subparsers = parser.add_subparsers(dest='action', help='the action to be taken')

    parser_server = subparsers.add_parser('server', help='run the server (WARNING: not thread‐safe)')

    parser_send = subparsers.add_parser('send', help='create and broadcast a *send* message')
    parser_send.add_argument('--source', required=True, help='the source address')
    parser_send.add_argument('--destination', required=True, help='the destination address')
    parser_send.add_argument('--quantity', required=True, help='the quantity of ASSET to send')
    parser_send.add_argument('--asset', required=True, help='the ASSET of which you would like to send QUANTITY')
    parser_send.add_argument('--fee', help='the exact BTC fee to be paid to miners')

    parser_order = subparsers.add_parser('order', help='create and broadcast an *order* message')
    parser_order.add_argument('--source', required=True, help='the source address')
    parser_order.add_argument('--get-quantity', required=True, help='the quantity of GET_ASSET that you would like to receive')
    parser_order.add_argument('--get-asset', required=True, help='the asset that you would like to buy')
    parser_order.add_argument('--give-quantity', required=True, help='the quantity of GIVE_ASSET that you are willing to give')
    parser_order.add_argument('--give-asset', required=True, help='the asset that you would like to sell')
    parser_order.add_argument('--expiration', type=int, required=True, help='the number of blocks for which the order should be valid')
    parser_order.add_argument('--fee-fraction-required', default=config.FEE_FRACTION_REQUIRED_DEFAULT, help='the miners’ fee required for an order to match this one, as a fraction of the BTC to be bought')
    parser_order_fees = parser_order.add_mutually_exclusive_group()
    parser_order_fees.add_argument('--fee-fraction-provided', default=config.FEE_FRACTION_PROVIDED_DEFAULT, help='the miners’ fee provided, as a fraction of the BTC to be sold')
    parser_order_fees.add_argument('--fee', help='the exact BTC fee to be paid to miners')

    parser_btcpay= subparsers.add_parser('btcpay', help='create and broadcast a *BTCpay* message, to settle an Order Match for which you owe BTC')
    parser_btcpay.add_argument('--source', required=True, help='the source address')
    parser_btcpay.add_argument('--order-match-id', required=True, help='the concatenation of the hashes of the two transactions which compose the order match')
    parser_btcpay.add_argument('--fee', help='the exact BTC fee to be paid to miners')

    parser_issuance = subparsers.add_parser('issuance', help='issue a new asset, issue more of an existing asset or transfer the ownership of an asset')
    parser_issuance.add_argument('--source', required=True, help='the source address')
    parser_issuance.add_argument('--transfer-destination', help='for transfer of ownership of asset issuance rights')
    parser_issuance.add_argument('--quantity', default=0, help='the quantity of ASSET to be issued')
    parser_issuance.add_argument('--asset', required=True, help='the name of the asset to be issued (if it’s available)')
    parser_issuance.add_argument('--divisible', action='store_true', help='whether or not the asset is divisible (must agree with previous issuances)')
    parser_issuance.add_argument('--callable', dest='callable_', action='store_true', help='whether or not the asset is callable (must agree with previous issuances)')
    parser_issuance.add_argument('--call-date', help='the date from which a callable asset may be called back (must agree with previous issuances)')
    parser_issuance.add_argument('--call-price', help='the price, in XCP per whole unit, at which a callable asset may be called back (must agree with previous issuances)')
    parser_issuance.add_argument('--description', type=str, required=True, help='a description of the asset (set to ‘LOCK’ to lock against further issuances with non‐zero quantitys)')
    parser_issuance.add_argument('--fee', help='the exact BTC fee to be paid to miners')

    parser_broadcast = subparsers.add_parser('broadcast', help='broadcast textual and numerical information to the network')
    parser_broadcast.add_argument('--source', required=True, help='the source address')
    parser_broadcast.add_argument('--text', type=str, required=True, help='the textual part of the broadcast (set to ‘LOCK’ to lock feed)')
    parser_broadcast.add_argument('--value', type=float, default=-1, help='numerical value of the broadcast')
    parser_broadcast.add_argument('--fee-fraction', default=0, help='the fraction of bets on this feed that go to its operator')
    parser_broadcast.add_argument('--fee', help='the exact BTC fee to be paid to miners')

    parser_bet = subparsers.add_parser('bet', help='offer to make a bet on the value of a feed')
    parser_bet.add_argument('--source', required=True, help='the source address')
    parser_bet.add_argument('--feed-address', required=True, help='the address which publishes the feed to bet on')
    parser_bet.add_argument('--bet-type', choices=list(util.BET_TYPE_NAME.values()), required=True, help='choices: {}'.format(list(util.BET_TYPE_NAME.values())))
    parser_bet.add_argument('--deadline', required=True, help='the date and time at which the bet should be decided/settled')
    parser_bet.add_argument('--wager', required=True, help='the quantity of XCP to wager')
    parser_bet.add_argument('--counterwager', required=True, help='the minimum quantity of XCP to be wagered by the user to bet against you, if he were to accept the whole thing')
    parser_bet.add_argument('--target-value', default=0.0, help='target value for Equal/NotEqual bet')
    parser_bet.add_argument('--leverage', type=int, default=5040, help='leverage, as a fraction of 5040')
    parser_bet.add_argument('--expiration', type=int, required=True, help='the number of blocks for which the bet should be valid')
    parser_bet.add_argument('--fee', help='the exact BTC fee to be paid to miners')

    parser_dividend = subparsers.add_parser('dividend', help='pay dividends to the holders of an asset (in proportion to their stake in it)')
    parser_dividend.add_argument('--source', required=True, help='the source address')
    parser_dividend.add_argument('--quantity-per-unit', required=True, help='the quantity of XCP to be paid per whole unit held of ASSET')
    parser_dividend.add_argument('--asset', required=True, help='the asset to which pay dividends')
    parser_dividend.add_argument('--dividend-asset', required=True, help='asset in which to pay the dividends')
    parser_dividend.add_argument('--fee', help='the exact BTC fee to be paid to miners')

    parser_burn = subparsers.add_parser('burn', help='destroy bitcoins to earn XCP, during an initial period of time')
    parser_burn.add_argument('--source', required=True, help='the source address')
    parser_burn.add_argument('--quantity', required=True, help='quantity of BTC to be destroyed')
    parser_burn.add_argument('--fee', help='the exact BTC fee to be paid to miners')

    parser_cancel= subparsers.add_parser('cancel', help='cancel an open order or bet you created')
    parser_cancel.add_argument('--source', required=True, help='the source address')
    parser_cancel.add_argument('--offer-hash', required=True, help='the transaction hash of the order or bet')
    parser_cancel.add_argument('--fee', help='the exact BTC fee to be paid to miners')

    parser_callback = subparsers.add_parser('callback', help='callback a fraction of an asset')
    parser_callback.add_argument('--source', required=True, help='the source address')
    parser_callback.add_argument('--fraction', required=True, help='the fraction of ASSET to call back')
    parser_callback.add_argument('--asset', required=True, help='the asset to callback')
    parser_callback.add_argument('--fee', help='the exact BTC fee to be paid to miners')

    parser_address = subparsers.add_parser('balances', help='display the balances of a Counterparty address')
    parser_address.add_argument('address', help='the address you are interested in')

    parser_asset = subparsers.add_parser('asset', help='display the basic properties of a Counterparty asset')
    parser_asset.add_argument('asset', help='the asset you are interested in')

    parser_wallet = subparsers.add_parser('wallet', help='list the addresses in your Bitcoind wallet along with their balances in all Counterparty assets')

    parser_pending= subparsers.add_parser('pending', help='list pending order matches awaiting BTCpayment from you')

    parser_reparse = subparsers.add_parser('reparse', help='reparse all transactions in the database (WARNING: not thread‐safe)')

    parser_rollback = subparsers.add_parser('rollback', help='rollback database (WARNING: not thread‐safe)')
    parser_rollback.add_argument('block_index', type=int, help='the index of the last known good block')

    parser_market = subparsers.add_parser('market', help='fill the screen with an always up-to-date summary of the Counterparty market')
    parser_market.add_argument('--give-asset', help='only show orders offering to sell GIVE_ASSET')
    parser_market.add_argument('--get-asset', help='only show orders offering to buy GET_ASSET')

    args = parser.parse_args()

    # Configuration
    set_options(data_dir=args.data_dir,
                bitcoind_rpc_connect=args.bitcoind_rpc_connect, bitcoind_rpc_port=args.bitcoind_rpc_port,
                bitcoind_rpc_user=args.bitcoind_rpc_user, bitcoind_rpc_password=args.bitcoind_rpc_password,
                insight_enable=args.insight_enable, insight_connect=args.insight_connect, insight_port=args.insight_port,
                rpc_host=args.rpc_host, rpc_port=args.rpc_port, rpc_user=args.rpc_user, rpc_password=args.rpc_password,
                log_file=args.log_file, pid_file=args.pid_file, api_num_threads=args.api_num_threads,
                api_request_queue_size=args.api_request_queue_size, database_file=args.database_file, testnet=args.testnet,
                testcoin=args.testcoin, unittest=False, carefulness=args.carefulness, force=args.force)

    #Create/update pid file
    pid = str(os.getpid())
    pidf = open(config.PID, 'w')
    pidf.write(pid)
    pidf.close()    

    # Database
    db = util.connect_to_db()

    # Logging (to file and console).
    logger = logging.getLogger() #get root logger
    logger.setLevel(logging.DEBUG if args.verbose else logging.INFO)
    #Console logging
    console = logging.StreamHandler()
    console.setLevel(logging.DEBUG if args.verbose else logging.INFO)
    formatter = logging.Formatter('%(message)s')
    console.setFormatter(formatter)
    logger.addHandler(console)
    #File logging (rotated)
    max_log_size = 20 * 1024 * 1024 #max log size of 20 MB before rotation (make configurable later)
    if os.name == 'nt':
        fileh = util_windows.SanitizedRotatingFileHandler(config.LOG, maxBytes=max_log_size, backupCount=5)
    else:
        fileh = logging.handlers.RotatingFileHandler(config.LOG, maxBytes=max_log_size, backupCount=5)
    fileh.setLevel(logging.DEBUG if args.verbose else logging.INFO)
    formatter = logging.Formatter('%(asctime)s %(message)s', '%Y-%m-%d-T%H:%M:%S%z')
    fileh.setFormatter(formatter)
    logger.addHandler(fileh)
    #API requests logging (don't show on console in normal operation)
    requests_log = logging.getLogger("requests")
    requests_log.setLevel(logging.DEBUG if args.verbose else logging.WARNING)
    requests_log.propagate = False
    urllib3_log = logging.getLogger('urllib3')
    urllib3_log.setLevel(logging.DEBUG if args.verbose else logging.WARNING)
    urllib3_log.propagate = False

    if args.action == None: args.action = 'server'
    
    # TODO: Keep around only as long as reparse and rollback don’t use API.
    if not config.FORCE and args.action in ('reparse', 'rollback'):
        util.version_check(db)
        bitcoin.bitcoind_check(db)

    # MESSAGE CREATION
    if args.action == 'send':
        if args.fee: args.fee = util.devise(db, args.fee, 'BTC', 'input')
        quantity = util.devise(db, args.quantity, args.asset, 'input')
        cli('create_send', {'source': args.source, 'destination': args.destination, 'asset': args.asset,
                           'quantity': quantity, 'fee': args.fee, 'allow_unconfirmed_inputs': args.unconfirmed},
            args.unsigned)

    elif args.action == 'order':
        if args.fee: args.fee = util.devise(db, args.fee, 'BTC', 'input')
        fee_required, fee_fraction_provided = D(args.fee_fraction_required), D(args.fee_fraction_provided)
        give_quantity, get_quantity = D(args.give_quantity), D(args.get_quantity)

        # Fee argument is either fee_required or fee_provided, as necessary.
        if args.give_asset == 'BTC':
            fee_required = 0
            fee_fraction_provided = util.devise(db, fee_fraction_provided, 'fraction', 'input')
            fee_provided = round(D(fee_fraction_provided) * D(give_quantity) * D(config.UNIT))
            print('Fee provided: {} BTC'.format(util.devise(db, fee_provided, 'BTC', 'output')))
        elif args.get_asset == 'BTC':
            fee_provided = 0
            fee_fraction_required = util.devise(db, args.fee_fraction_required, 'fraction', 'input')
            fee_required = round(D(fee_fraction_required) * D(get_quantity) * D(config.UNIT))
            print('Fee required: {} BTC'.format(util.devise(db, fee_required, 'BTC', 'output')))
        else:
            fee_required = 0
            fee_provided = 0

        give_quantity = util.devise(db, give_quantity, args.give_asset, 'input')
        get_quantity = util.devise(db, get_quantity, args.get_asset, 'input')

        cli('create_order', {'source': args.source, 'give_asset': args.give_asset, 'give_quantity': give_quantity,
                            'get_asset': args.get_asset, 'get_quantity': get_quantity, 'expiration': args.expiration,
                            'fee_required': fee_required, 'fee_provided': fee_provided, 'fee': args.fee, 'allow_unconfirmed_inputs': args.unconfirmed},
           args.unsigned)

    elif args.action == 'btcpay':
        if args.fee: args.fee = util.devise(db, args.fee, 'BTC', 'input')
        cli('create_btcpay', {'source': args.source, 'order_match_id': args.order_match_id, 'fee': args.fee, 'allow_unconfirmed_inputs': args.unconfirmed}, args.unsigned)

    elif args.action == 'issuance':
        if args.fee: args.fee = util.devise(db, args.fee, 'BTC', 'input')
        quantity = util.devise(db, args.quantity, None, 'input',
                               divisible=args.divisible)
        if args.callable_:
            if not args.call_date:
                parser.error('must specify call date of callable asset', )
            if not args.call_price:
                parser.error('must specify call price of callable asset')
            call_date = calendar.timegm(dateutil.parser.parse(args.call_date).utctimetuple())
            call_price = float(args.call_price)
        else:
            call_date, call_price = 0, 0

        cli('create_issuance', {'source': args.source, 'asset': args.asset, 'quantity': quantity,
                                'divisible': args.divisible, 'description': args.description,
                                'callable_': args.callable_, 'call_date': call_date, 'call_price': call_price,
                                'transfer_destination': args.transfer_destination, 'fee': args.fee, 'allow_unconfirmed_inputs': args.unconfirmed},
           args.unsigned)

    elif args.action == 'broadcast':
        if args.fee: args.fee = util.devise(db, args.fee, 'BTC', 'input')
        value = util.devise(db, args.value, 'value', 'input')
        fee_fraction = util.devise(db, args.fee_fraction, 'fraction', 'input')

        cli('create_broadcast', {'source': args.source, 'fee_fraction': fee_fraction, 'text': args.text,
                                 'timestamp': int(time.time()), 'value': value, 'fee': args.fee, 'allow_unconfirmed_inputs': args.unconfirmed},
           args.unsigned)

    elif args.action == 'bet':
        if args.fee: args.fee = util.devise(db, args.fee, 'BTC', 'input')
        deadline = calendar.timegm(dateutil.parser.parse(args.deadline).utctimetuple())
        wager = util.devise(db, args.wager, 'XCP', 'input')
        counterwager = util.devise(db, args.counterwager, 'XCP', 'input')
        target_value = util.devise(db, args.target_value, 'value', 'input')
        leverage = util.devise(db, args.leverage, 'leverage', 'input')

        cli('create_bet', {'source': args.source, 'feed_address': args.feed_address, 'bet_type': args.bet_type,
                           'deadline': deadline, 'wager': wager, 'counterwager': counterwager, 'expiration': args.expiration,
                           'target_value': target_value, 'leverage': leverage, 'fee': args.fee, 'allow_unconfirmed_inputs': args.unconfirmed},
            args.unsigned)

    elif args.action == 'dividend':
        if args.fee: args.fee = util.devise(db, args.fee, 'BTC', 'input')
        quantity_per_unit = util.devise(db, args.quantity_per_unit, 'XCP', 'input')
        cli('create_dividend', {'source': args.source, 'quantity_per_unit': quantity_per_unit, 'asset': args.asset, 'dividend_asset': args.dividend_asset, 'fee': args.fee, 'allow_unconfirmed_inputs': args.unconfirmed},
           args.unsigned)

    elif args.action == 'burn':
        if args.fee: args.fee = util.devise(db, args.fee, 'BTC', 'input')
        quantity = util.devise(db, args.quantity, 'BTC', 'input')
        cli('create_burn', {'source': args.source, 'quantity': quantity, 'fee': args.fee, 'allow_unconfirmed_inputs': args.unconfirmed}, args.unsigned)

    elif args.action == 'cancel':
        if args.fee: args.fee = util.devise(db, args.fee, 'BTC', 'input')
        cli('create_cancel', {'source': args.source, 'offer_hash': args.offer_hash, 'fee': args.fee, 'allow_unconfirmed_inputs': args.unconfirmed}, args.unsigned)

    elif args.action == 'callback':
        if args.fee: args.fee = util.devise(db, args.fee, 'BTC', 'input')
        cli('create_callback', {'source': args.source, 'fraction': util.devise(db, args.fraction,
                                'fraction', 'input'), 'asset': args.asset, 'fee': args.fee, 'allow_unconfirmed_inputs': args.unconfirmed},
           args.unsigned)


    # VIEWING (temporary)
    elif args.action == 'balances':
        try:
            bitcoin.base58_decode(args.address, config.ADDRESSVERSION)
        except Exception:
            raise exceptions.AddressError('Invalid Bitcoin address:',
                                                  args.address)
        balances(args.address)

    elif args.action == 'asset':
        results = util.api('get_asset_info', ([args.asset],))
        if results:
            results = results[0]    # HACK
        else:
            print('Asset ‘{}’ not found.'.format(args.asset))
            exit(0)
        
        asset_id = util.asset_id(args.asset)
        divisible = results['divisible']
        supply = util.devise(db, results['supply'], args.asset, dest='output')
        call_date = util.isodt(results['call_date']) if results['call_date'] else results['call_date']
        call_price = str(results['call_price']) + ' XCP' if results['call_price'] else results['call_price']

        print('Asset Name:', args.asset)
        print('Asset ID:', asset_id)
        print('Divisible:', divisible)
        print('Supply:', supply)
        print('Issuer:', results['issuer'])
        print('Callable:', results['callable'])
        print('Call Date:', call_date)
        print('Call Price:', call_price)
        print('Description:', '‘' + results['description'] + '’')

        if args.asset != 'BTC':
            print('Shareholders:')
            balances = util.get_balances(db, asset=args.asset)
            print('\taddress, quantity, escrow')
            for holder in util.holders(db, args.asset):
                quantity = holder['address_quantity']
                if not quantity: continue
                quantity = util.devise(db, quantity, args.asset, 'output')
                if holder['escrow']: escrow = holder['escrow']
                else: escrow = 'None'
                print('\t' + str(holder['address']) + ',' + str(quantity) + ',' + escrow)


    elif args.action == 'wallet':
        total_table = PrettyTable(['Asset', 'Balance'])
        totals = {}

        print()
        for bunch in bitcoin.get_wallet():
            address, btc_balance = bunch[:2]
            address_data = get_address(db, address=address)
            balances = address_data['balances']
            table = PrettyTable(['Asset', 'Balance'])
            empty = True
            if btc_balance:
                table.add_row(['BTC', btc_balance])  # BTC
                if 'BTC' in totals.keys(): totals['BTC'] += btc_balance
                else: totals['BTC'] = btc_balance
                empty = False            
            for balance in balances:
                asset = balance['asset']
                try:
                    balance = D(util.devise(db, balance['quantity'], balance['asset'], 'output'))
                except:
                    balance = None
                if balance:
                    if asset in totals.keys(): totals[asset] += balance
                    else: totals[asset] = balance
                    table.add_row([asset, balance])
                    empty = False
            if not empty:
                print(address)
                print(table.get_string())
                print()
        for asset in totals.keys():
            balance = totals[asset]
            total_table.add_row([asset, round(balance, 8)])
        print('TOTAL')
        print(total_table.get_string())
        print()

    elif args.action == 'pending':
        awaiting_btcs = util.get_order_matches(db, status='pending', is_mine=True)
        table = PrettyTable(['Matched Order ID', 'Time Left'])
        for order_match in awaiting_btcs:
            order_match = format_order_match(db, order_match)
            table.add_row(order_match)
        print(table)

    elif args.action == 'market':
        market(args.give_asset, args.get_asset)


    # PARSING
    elif args.action == 'reparse':
        blocks.reparse(db)

    elif args.action == 'rollback':
        blocks.reparse(db, block_index=args.block_index)

    elif args.action == 'server':
        api_server = api.APIServer()
        api_server.daemon = True
        api_server.start()

        # Check that Insight works if enabled.
        if config.INSIGHT_ENABLE and not config.FORCE:
            try:
                r = requests.get(config.INSIGHT + '/api/sync/')
                if r.status_code != 200:
                    raise ValueError("Bad status code returned from insight: %s" % r.status_code)
                result = r.json()
                if result['status'] == 'error':
                    raise exceptions.InsightError('Insight reports error: %s' % result['error'])
                if result['status'] == 'syncing':
                    logging.warning("WARNING: Insight is not fully synced to the blockchain: %s%% complete" % result['syncPercentage'])
            except Exception as e:
                raise exceptions.InsightError('Could not connect to Insight server: %s' % e)

        blocks.follow(db)

    else:
        parser.print_help()

# vim: tabstop=8 expandtab shiftwidth=4 softtabstop=4
