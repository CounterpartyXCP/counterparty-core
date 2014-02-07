#! /usr/bin/env python3


import os
import argparse
import json

import decimal
D = decimal.Decimal

import sys
import logging
import requests
from prettytable import PrettyTable
import unicodedata

import time
import dateutil.parser
import datetime
import calendar
from threading import Thread

import appdirs
import logging
import configparser

# Units
from lib import (config, api, util, exceptions, bitcoin, blocks)
from lib import (send, order, btcpay, issuance, broadcast, bet, dividend, burn, cancel, callback)
if os.name == 'nt':
    from lib import util_windows

json_print = lambda x: print(json.dumps(x, sort_keys=True, indent=4))

def set_options (data_dir=None, bitcoind_rpc_connect=None, bitcoind_rpc_port=None,
                 bitcoind_rpc_user=None, bitcoind_rpc_password=None, rpc_host=None, rpc_port=None,
                 rpc_user=None, rpc_password=None, log_file=None, database_file=None, testnet=False, testcoin=False, unittest=False):

    # Unittests always run on testnet.
    if unittest and not testnet:
        raise Exception # TODO

    # Data directory
    if not data_dir:
        config.DATA_DIR = appdirs.user_data_dir(appauthor='Counterparty', appname='counterpartyd', roaming=True)
    else:
        config.DATA_DIR = data_dir
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
            config.BITCOIND_RPC_PORT = '18332'
        else:
            config.BITCOIND_RPC_PORT = '8332'
    try:
        int(config.BITCOIND_RPC_PORT)
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

    # RPC host
    if rpc_host:
        config.RPC_HOST = rpc_host
    elif has_config and 'rpc-host' in configfile['Default'] and configfile['Default']['rpc-host']:
        config.RPC_HOST = configfile['Default']['rpc-host']
    else:
        config.RPC_HOST = 'localhost'

    # RPC port
    if rpc_port:
        config.RPC_PORT = rpc_port
    elif has_config and 'rpc-port' in configfile['Default'] and configfile['Default']['rpc-port']:
        config.RPC_PORT = configfile['Default']['rpc-port']
    else:
        if config.TESTNET:
            config.RPC_PORT = '14000'
        else:
            config.RPC_PORT = '4000'
    try:
        int(config.RPC_PORT)
        assert int(config.RPC_PORT) > 1 and int(config.RPC_PORT) < 65535
    except:
        raise Exception("Please specific a valid port number rpc-port configuration parameter")

    # RPC user
    if rpc_user:
        config.RPC_USER = rpc_user
    elif has_config and 'rpc-user' in configfile['Default'] and configfile['Default']['rpc-user']:
        config.RPC_USER = configfile['Default']['rpc-user']
    else:
        config.RPC_USER = 'rpc'

    # RPC password
    if rpc_password:
        config.RPC_PASSWORD = rpc_password
    elif has_config and 'rpc-password' in configfile['Default'] and configfile['Default']['rpc-password']:
        config.RPC_PASSWORD = configfile['Default']['rpc-password']
    else:
        raise exceptions.ConfigurationError('RPC password not set. (Use configuration file or --rpc-password=PASSWORD)')

    # Log
    if log_file:
        config.LOG = log_file
    elif has_config and 'logfile' in configfile['Default']:
        config.LOG = configfile['Default']['logfile']
    else:
        if config.TESTNET:
            config.LOG = os.path.join(config.DATA_DIR, 'counterpartyd.testnet.log')
        else:
            config.LOG = os.path.join(config.DATA_DIR, 'counterpartyd.log')

    if not unittest:
        if config.TESTCOIN:
            config.PREFIX = b'XX'                   # 2 bytes (possibly accidentally created)
        else:
            config.PREFIX = b'CNTRPRTY'             # 8 bytes
    else:
        config.PREFIX = config.UNITTEST_PREFIX

    # Database
    if config.TESTNET:
        config.DB_VERSION_MAJOR = str(config.DB_VERSION_MAJOR) + '.testnet'
    if database_file:
        config.DATABASE = database_file
    else:
        config.DB_VERSION_MAJOR
        config.DATABASE = os.path.join(config.DATA_DIR, 'counterpartyd.' + str(config.DB_VERSION_MAJOR) + '.db')

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

def market (give_asset, get_asset):
    # Open orders.
    orders = util.get_orders(db, validity='Valid', show_expired=False, show_empty=False)
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
    bets = util.get_bets(db, validity='Valid', show_empty=False)
    table = PrettyTable(['Bet Type', 'Feed Address', 'Deadline', 'Target Value', 'Leverage', 'Wager', 'Odds', 'Time Left', 'Tx Hash'])
    for bet in bets:
        bet = format_bet(bet)
        table.add_row(bet)
    print('Open Bets')
    print(table)
    print('\n')

    # Matched orders awaiting BTC payments from you.
    awaiting_btcs = util.get_order_matches(db, validity='Valid: awaiting BTC payment', is_mine=True)
    table = PrettyTable(['Matched Order ID', 'Time Left'])
    for order_match in awaiting_btcs:
        order_match = format_order_match(db, order_match)
        table.add_row(order_match)
    print('Order Matches Awaiting BTC Payment from You')
    print(table)
    print('\n')

    # Feeds
    broadcasts = util.get_broadcasts(db, validity='Valid', order_by='timestamp', order_dir='desc')
    table = PrettyTable(['Feed Address', 'Timestamp', 'Text', 'Value', 'Fee Multiplier'])
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


def balances (address):
    def get_btc_balance(address):
        r = requests.get("https://blockchain.info/q/addressbalance/" + address)
        # ^any other services that provide this?? (blockexplorer.com doesn't...)
        try:
            assert r.status_code == 200
            return int(r.text) / float(config.UNIT)
        except:
            return "???"

    address_data = util.get_address(db, address=address)

    # Balances.
    balances = address_data['balances']
    table = PrettyTable(['Asset', 'Amount'])
    table.add_row(['BTC', get_btc_balance(address)])  # BTC
    for balance in balances:
        asset = balance['asset']
        amount = util.devise(db, balance['amount'], balance['asset'], 'output')
        table.add_row([asset, amount])
    print('Balances')
    print(table.get_string())

def format_order (order):
    give_amount = util.devise(db, D(order['give_amount']), order['give_asset'], 'output')
    get_amount = util.devise(db, D(order['get_amount']), order['get_asset'], 'output')
    give_remaining = util.devise(db, D(order['give_remaining']), order['give_asset'], 'output')
    get_remaining = util.devise(db, D(order['get_remaining']), order['get_asset'], 'output')
    give_asset = order['give_asset']
    get_asset = order['get_asset']

    if get_asset < give_asset:
        price = util.devise(db, D(order['get_amount']) / D(order['give_amount']), 'price', 'output')
        price_assets = get_asset + '/' + give_asset + ' ask'
    else:
        price = util.devise(db, D(order['give_amount']) / D(order['get_amount']), 'price', 'output')
        price_assets = give_asset + '/' + get_asset + ' bid'

    return [D(give_remaining), give_asset, price, price_assets, str(order['fee_required'] / config.UNIT), str(order['fee_provided'] / config.UNIT), order['expire_index'] - util.last_block(db)['block_index'], order['tx_hash']]

def format_bet (bet):
    odds = D(bet['counterwager_amount']) / D(bet['wager_amount'])

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
    return [feed['source'], timestamp, text, feed['value'], D(feed['fee_multiplier']) / D(1e8)]


if __name__ == '__main__':
    if os.name == 'nt':
        #patch up cmd.exe's "challenged" (i.e. broken/non-existent) UTF-8 logging
        util_windows.fix_win32_unicode()
    
    # Parse command-line arguments.
    parser = argparse.ArgumentParser(prog='counterpartyd', description='the reference implementation of the Counterparty protocol')
    parser.add_argument('-V', '--version', action='version', version="counterpartyd v%s" % config.VERSION)

    parser.add_argument('-v', '--verbose', dest='verbose', action='store_true', help='sets log level to DEBUG instead of WARNING')
    parser.add_argument('--force', action='store_true', help='don\'t check whether Bitcoind is caught up')
    parser.add_argument('--testnet', action='store_true', help='use Bitcoin testnet addresses and block numbers')
    parser.add_argument('--testcoin', action='store_true', help='use the test Counterparty network on every blockchain')
    parser.add_argument('--unsigned', action='store_true', default=False, help='print out unsigned hex of transaction; do not sign or broadcast')

    parser.add_argument('--data-dir', help='the directory in which to keep the database, config file and log file, by default')
    parser.add_argument('--database-file', help='the location of the SQLite3 database')
    parser.add_argument('--config-file', help='the location of the configuration file')
    parser.add_argument('--log-file', help='the location of the log file')

    parser.add_argument('--bitcoind-rpc-connect', help='the hostname of the Bitcoind JSON-RPC server')
    parser.add_argument('--bitcoind-rpc-port', type=int, help='the port used to communicate with Bitcoind over JSON-RPC')
    parser.add_argument('--bitcoind-rpc-user', help='the username used to communicate with Bitcoind over JSON-RPC')
    parser.add_argument('--bitcoind-rpc-password', help='the password used to communicate with Bitcoind over JSON-RPC')

    parser.add_argument('--rpc-host', help='the host to provide the counterpartyd JSON-RPC API')
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

    parser_order = subparsers.add_parser('order', help='create and broadcast an *order* message')
    parser_order.add_argument('--source', required=True, help='the source address')
    parser_order.add_argument('--get-quantity', required=True, help='the quantity of GET_ASSET that you would like to receive')
    parser_order.add_argument('--get-asset', required=True, help='the asset that you would like to buy')
    parser_order.add_argument('--give-quantity', required=True, help='the quantity of GIVE_ASSET that you are willing to give')
    parser_order.add_argument('--give-asset', required=True, help='the asset that you would like to sell')
    parser_order.add_argument('--expiration', type=int, required=True, help='the number of blocks for which the order should be valid')
    parser_order.add_argument('--fee_required', default=0, help='the miners\' fee required to be paid by orders for them to match this one; in BTC; required iff buying BTC (may be zero, though)')
    parser_order.add_argument('--fee_provided', default=(config.MIN_FEE / config.UNIT), help='the miners\' fee provided; in BTC; required iff selling BTC (should not be lower than is required for acceptance in a block)')

    parser_btcpay= subparsers.add_parser('btcpay', help='create and broadcast a *BTCpay* message, to settle an Order Match for which you owe BTC')
    parser_btcpay.add_argument('--order-match-id', required=True, help='the concatenation of the hashes of the two transactions which compose the order match')

    parser_issuance = subparsers.add_parser('issuance', help='issue a new asset, issue more of an existing asset or transfer the ownership of an asset')
    parser_issuance.add_argument('--source', required=True, help='the source address')
    parser_issuance.add_argument('--transfer-destination', help='for transfer of ownership of asset issuance rights')
    parser_issuance.add_argument('--quantity', required=True, help='the quantity of ASSET to be issued')
    parser_issuance.add_argument('--asset', required=True, help='the name of the asset to be issued (if it\'s available)')
    parser_issuance.add_argument('--divisible', action='store_true', help='whether or not the asset is divisible (must agree with previous issuances)')
    parser_issuance.add_argument('--callable', dest='callable_', action='store_true', help='whether or not the asset is callable (must agree with previous issuances)')
    parser_issuance.add_argument('--call-date', help='the date from which a callable asset may be called back (must agree with previous issuances)')
    parser_issuance.add_argument('--call-price', help='the price at which a callable asset may be called back (must agree with previous issuances)')
    parser_issuance.add_argument('--description', type=str, required=True, help='a description of the asset')

    parser_broadcast = subparsers.add_parser('broadcast', help='broadcast textual and numerical information to the network')
    parser_broadcast.add_argument('--source', required=True, help='the source address')
    parser_broadcast.add_argument('--text', type=str, required=True, help='the textual part of the broadcast')
    parser_broadcast.add_argument('--value', type=float, default=0, help='numerical value of the broadcast')
    parser_broadcast.add_argument('--fee-multiplier', required=True, help='how much of every bet on this feed should go to its operator; a fraction of 1, (i.e. .05 is five percent)')

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

    parser_dividend = subparsers.add_parser('dividend', help='pay dividends to the holders of an asset (in proportion to their stake in it)')
    parser_dividend.add_argument('--source', required=True, help='the source address')
    parser_dividend.add_argument('--quantity-per-share', required=True, help='the quantity of XCP to be paid per unit (satoshi) held of ASSET')
    parser_dividend.add_argument('--asset', required=True, help='the asset to which pay dividends')

    parser_burn = subparsers.add_parser('burn', help='destroy bitcoins to earn XCP, during an initial period of time')
    parser_burn.add_argument('--source', required=True, help='the source address')
    parser_burn.add_argument('--quantity', required=True, help='quantity of BTC to be destroyed')

    parser_cancel= subparsers.add_parser('cancel', help='cancel an open order or bet you created')
    parser_cancel.add_argument('--offer-hash', required=True, help='the transaction hash of the order or bet')

    parser_callback = subparsers.add_parser('callback', help='callback a fraction of an asset')
    parser_callback.add_argument('--source', required=True, help='the source address')
    parser_callback.add_argument('--fraction-per-share', required=True, help='the fraction of ASSET to call back')
    parser_callback.add_argument('--asset', required=True, help='the asset to callback')

    parser_address = subparsers.add_parser('balances', help='display the balances of a Counterparty address')
    parser_address.add_argument('address', help='the address you are interested in')

    parser_asset = subparsers.add_parser('asset', help='display the basic properties of a Counterparty asset')
    parser_asset.add_argument('asset', help='the asset you are interested in')

    parser_wallet = subparsers.add_parser('wallet', help='list the addresses in your Bitcoind wallet along with their balances in all Counterparty assets')

    parser_market = subparsers.add_parser('market', help='fill the screen with an always up-to-date summary of the Counterparty market')
    parser_market.add_argument('--give-asset', help='only show orders offering to sell GIVE_ASSET')
    parser_market.add_argument('--get-asset', help='only show orders offering to buy GET_ASSET')

    parser_reparse = subparsers.add_parser('reparse', help='reparse all transactions in the database (WARNING: not thread‐safe)')

    parser_rollback = subparsers.add_parser('rollback', help='rollback database (WARNING: not thread‐safe)')
    parser_rollback.add_argument('block_index', type=int, help='the index of the last known good block')

    """
    parser_checksum = subparsers.add_parser('checksum', help='create an asset name from a base string')
    parser_checksum.add_argument('string', help='base string of the desired asset name')
    """

    args = parser.parse_args()

    # Configuration
    set_options(data_dir=args.data_dir, bitcoind_rpc_connect=args.bitcoind_rpc_connect, bitcoind_rpc_port=args.bitcoind_rpc_port,
                 bitcoind_rpc_user=args.bitcoind_rpc_user, bitcoind_rpc_password=args.bitcoind_rpc_password, rpc_host=args.rpc_host, rpc_port=args.rpc_port,
                 rpc_user=args.rpc_user, rpc_password=args.rpc_password, log_file=args.log_file, database_file=args.database_file, testnet=args.testnet, testcoin=args.testcoin, unittest=False)

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
    max_log_size = 2 * 1024 * 1024 #max log size of 2 MB before rotation (make configurable later)
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

    if args.action == None: args.action = 'server'

    # Check that bitcoind is running, communicable, and caught up with the blockchain.
    # Check that the database has caught up with bitcoind.
    if not args.force:
        util.bitcoind_check(db)
        if args.action not in ('server', 'reparse', 'rollback'):
            util.database_check(db)

    # Do something.
    if args.action == 'send':
        quantity = util.devise(db, args.quantity, args.asset, 'input')
        unsigned_tx_hex = send.create(db, args.source, args.destination,
                                      quantity, args.asset, unsigned=args.unsigned)
        print(unsigned_tx_hex) if args.unsigned else json_print(bitcoin.transmit(unsigned_tx_hex))

    elif args.action == 'order':
        # Fee argument is either fee_required or fee_provided, as necessary.
        if args.give_asset == 'BTC':
            if args.fee_required != 0:
                raise exceptions.FeeError('When selling BTC, do not specify a fee required.')
            fee_required = args.fee_required
            fee_provided = util.devise(db, args.fee_provided, 'BTC', 'input')
        elif args.get_asset == 'BTC':
            fee_required = util.devise(db, args.fee_required, 'BTC', 'input')
            if args.fee_provided != config.MIN_FEE / config.UNIT:
                raise exceptions.FeeError('When buying BTC, do not specify a fee provided.')
            fee_provided = util.devise(db, args.fee_provided, 'BTC', 'input')
        else:
            fee_provided = util.devise(db, args.fee_provided, 'XCP', 'input')
            if fee_provided != config.MIN_FEE or args.fee_required != 0:
                raise exceptions.InputError('No fee should be required or provided (explicitly) if not buying or selling BTC.')
            fee_required = 0
            fee_provided = config.MIN_FEE

        give_quantity = util.devise(db, args.give_quantity, args.give_asset, 'input')
        get_quantity = util.devise(db, args.get_quantity, args.get_asset, 'input')
        unsigned_tx_hex = order.create(db, args.source, args.give_asset, give_quantity,
                                args.get_asset, get_quantity,
                                args.expiration, fee_required, fee_provided, unsigned=args.unsigned)
        print(unsigned_tx_hex) if args.unsigned else json_print(bitcoin.transmit(unsigned_tx_hex))

    elif args.action == 'btcpay':
        unsigned_tx_hex = btcpay.create(db, args.order_match_id, unsigned=args.unsigned)
        print(unsigned_tx_hex) if args.unsigned else json_print(bitcoin.transmit(unsigned_tx_hex))

    elif args.action == 'issuance':
        quantity = util.devise(db, args.quantity, None, 'input',
                               divisible=args.divisible)
        if args.callable_:
            if not args.call_date:
                parser.error('must specify call date of callable asset', )
            if not args.call_price:
                parser.error('must specify call price of callable asset')
            call_date = round(datetime.timestamp(dateutil.parser.parse(args.call_date)))
            call_price = float(args.call_price)
        else:
            call_date, call_price = 0, 0

        unsigned_tx_hex = issuance.create(db, args.source,
                                          args.transfer_destination,
                                          args.asset, quantity, args.divisible, args.callable_, call_date, call_price, args.description, unsigned=args.unsigned)
        print(unsigned_tx_hex) if args.unsigned else json_print(bitcoin.transmit(unsigned_tx_hex))

    elif args.action == 'broadcast':
        value = util.devise(db, args.value, 'value', 'input')
        unsigned_tx_hex = broadcast.create(db, args.source, int(time.time()),
                                           value, args.fee_multiplier,
                                           args.text, unsigned=args.unsigned)
        print(unsigned_tx_hex) if args.unsigned else json_print(bitcoin.transmit(unsigned_tx_hex))

    elif args.action == 'bet':
        deadline = calendar.timegm(dateutil.parser.parse(args.deadline).utctimetuple())
        wager = util.devise(db, args.wager, 'XCP', 'input')
        counterwager = util.devise(db, args.counterwager, 'XCP', 'input')
        target_value = util.devise(db, args.target_value, 'value', 'input')
        leverage = util.devise(db, args.leverage, 'leverage', 'input')

        unsigned_tx_hex = bet.create(db, args.source, args.feed_address,
                                     util.BET_TYPE_ID[args.bet_type], deadline,
                                     wager, counterwager, target_value,
                                     leverage, args.expiration, unsigned=args.unsigned)
        print(unsigned_tx_hex) if args.unsigned else json_print(bitcoin.transmit(unsigned_tx_hex))

    elif args.action == 'dividend':
        quantity_per_share = util.devise(db, args.quantity_per_share, 'XCP', 'input')
        unsigned_tx_hex = dividend.create(db, args.source, quantity_per_share,
                                   args.asset, unsigned=args.unsigned)
        print(unsigned_tx_hex) if args.unsigned else json_print(bitcoin.transmit(unsigned_tx_hex))

    elif args.action == 'burn':
        quantity = util.devise(db, args.quantity, 'BTC', 'input')
        unsigned_tx_hex = burn.create(db, args.source, quantity, unsigned=args.unsigned)
        print(unsigned_tx_hex) if args.unsigned else json_print(bitcoin.transmit(unsigned_tx_hex))

    elif args.action == 'cancel':
        unsigned_tx_hex = cancel.create(db, args.offer_hash, unsigned=args.unsigned)
        print(unsigned_tx_hex) if args.unsigned else json_print(bitcoin.transmit(unsigned_tx_hex))

    elif args.action == 'callback':
        unsigned_tx_hex = callback.create(db, args.source, float(args.fraction_per_share),
                                   args.asset, unsigned=args.unsigned)
        print(unsigned_tx_hex) if args.unsigned else json_print(bitcoin.transmit(unsigned_tx_hex))

    elif args.action == 'balances':
        try:
            bitcoin.base58_decode(args.address, config.ADDRESSVERSION)
        except Exception:
            raise exceptions.InvalidAddressError('Invalid Bitcoin address:',
                                                  args.address)
        balances(args.address)

    elif args.action == 'asset':
        # TODO: Use API
        if args.asset == 'XCP':
            total = util.devise(db, util.xcp_supply(db), args.asset, 'output')
            divisible = True
            issuer = None
            callable_ = None
            call_date = None
            call_price = None
            description = None
        elif args.asset == 'BTC':
            total = None
            divisible = True
            issuer = None
            callable_ = None
            call_date = None
            call_price = None
            description = None
        else:
            issuances = util.get_issuances(db, validity='Valid', asset=args.asset)
            total = sum([issuance['amount'] for issuance in issuances])
            total = util.devise(db, total, args.asset, 'output')
            divisible = bool(issuances[-1]['divisible'])
            issuer = issuances[-1]['issuer'] # Issuer of last issuance.
            callable_ = None
            call_date = issuances[-1]['call_date']
            call_price = issuances[-1]['call_price']
            description = issuances[-1]['description']

        asset_id = util.get_asset_id(args.asset)
        print('Asset Name:', args.asset)
        print('Asset ID:', asset_id)
        print('Total Issued:', total)
        print('Divisible:', divisible)
        print('Issuer:', issuer)
        print('Callable:', callable_)
        print('Call Date:', util.isodt(call_date) if call_date else call_date)
        print('Call Price:', str(call_price) + ' XCP' if call_price else call_price)
        print('Description:', description)

    elif args.action == 'wallet':
        total_table = PrettyTable(['Asset', 'Balance'])
        totals = {}

        print()
        # TODO: This should be burns minus issuance fees (so it won’t depend on escrowed funds).
        for group in bitcoin.rpc('listaddressgroupings', []):
            for bunch in group:
                address, btc_balance = bunch[:2]
                get_address = util.get_address(db, address=address)
                balances = get_address['balances']
                table = PrettyTable(['Asset', 'Balance'])
                empty = True
                if btc_balance:
                    table.add_row(['BTC', btc_balance])  # BTC
                    if 'BTC' in totals.keys(): totals['BTC'] += btc_balance
                    else: totals['BTC'] = btc_balance
                    empty = False
                for balance in balances:
                    asset = balance['asset']
                    balance = D(util.devise(db, balance['amount'], balance['asset'], 'output'))
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

    elif args.action == 'market':
        market(args.give_asset, args.get_asset)

    elif args.action == 'reparse':
        blocks.reparse(db)

    elif args.action == 'rollback':
        blocks.reparse(db, block_index=args.block_index)

    # elif args.action == 'checksum':
        # print('Asset name:', args.string + checksum.compute(args.string))

    elif args.action == 'server':
        api_server = api.APIServer()
        api_server.daemon = True
        api_server.start()
        blocks.follow(db)

    elif args.action == 'help':
        parser.print_help()

    else:
        parser.print_help()

# vim: tabstop=8 expandtab shiftwidth=4 softtabstop=4
