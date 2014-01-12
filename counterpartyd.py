#! /usr/bin/env python3


import os
import argparse
import json

import decimal
D = decimal.Decimal

import sqlite3
import logging
import appdirs
import configparser
from prettytable import PrettyTable

import time
import dateutil.parser
from datetime import datetime
from threading import Thread

from lib import (config, api, util, exceptions, bitcoin, blocks)
from lib import (send, order, btcpay, issuance, broadcast, bet, dividend, burn, cancel, util)

json_print = lambda x: print(json.dumps(x, sort_keys=True, indent=4))

def market (give_asset, get_asset):
    os.system('cls' if os.name=='nt' else 'clear')

    # Open orders.
    orders = util.get_orders(db, validity='Valid', show_expired=False, show_empty=False)
    table = PrettyTable(['Give Quantity', 'Give Asset', 'Get Quantity', 'Get Asset', 'Price', 'Price Assets', 'Fee', 'Time Left', 'Tx Hash'])
    for order in orders:
        if give_asset and order['give_asset'] != give_asset:
            continue
        if get_asset and order['get_asset'] != get_asset:
            continue
        order = format_order(order)
        table.add_row(order)
    print('Open Orders')
    print(str(table.get_string(sortby='Price')))
    print('\n')

    # Open bets.
    bets = util.get_bets(db, validity='Valid', show_empty=False)
    table = PrettyTable(['Bet Type', 'Feed Address', 'Deadline', 'Target Value', 'Leverage', 'Wager', 'Counterwager', 'Odds', 'Time Left', 'Tx Hash'])
    for bet in bets:
        bet = format_bet(bet)
        table.add_row(bet)
    print('Open Bets')
    print(str(table))
    print('\n')

    # Matched orders awaiting BTC payments from you.
    awaiting_btcs = util.get_order_matches(db, validity='Valid: awaiting BTC payment', is_mine=True)
    table = PrettyTable(['Matched Order ID', 'Time Left'])
    for order_match in awaiting_btcs:
        order_match = format_order_match(order_match)
        table.add_row(order_match)
    print('Order Matches Awaiting BTC Payment')
    print(str(table))
    print('\n')

    # Feeds
    broadcasts = util.get_broadcasts(db, validity='Valid', order_by='timestamp DESC')
    table = PrettyTable(['Feed Address', 'Timestamp', 'Text', 'Value', 'Fee Multiplier'])
    seen_addresses = []
    for broadcast in broadcasts:
        # Always show only the latest broadcast from a feed address.
        if broadcast['source'] not in seen_addresses:
            feed = format_feed(broadcast)
            table.add_row(feed)
            seen_addresses.append(broadcast['source'])
        else:
            continue
    print('Feeds')
    print(str(table))

    time.sleep(30)


def address (address):
    address = util.get_address(db, address=address)

    # Balances.
    balances = address['balances']
    table = PrettyTable(['Asset', 'Amount'])
    table.add_row(['BTC', '???'])  # BTC
    for balance in balances:
        asset = balance['asset']
        amount = util.devise(db, balance['amount'], balance['asset'], 'output')
        table.add_row([asset, amount])
    print('Balances')
    print(str(table))
    print('\n')

    # Burns.
    burns = address['burns']
    table = PrettyTable(['Block Index', 'Burned', 'Earned', 'Tx Hash'])
    for burn in burns:
        burned = util.devise(db, burn['burned'], 'BTC', 'output')
        earned = util.devise(db, burn['earned'], 'BTC', 'output')
        table.add_row([burn['block_index'], burned + ' BTC', earned + ' XCP', util.short(burn['tx_hash'])])
    print('Burns')
    print(str(table))
    print('\n')

    # Sends.
    sends = address['sends']
    table = PrettyTable(['Amount', 'Asset', 'Source', 'Destination', 'Tx Hash'])
    for send in sends:
        amount = util.devise(db, send['amount'], send['asset'], 'output')
        asset = send['asset']
        table.add_row([amount, asset, send['source'], send['destination'], util.short(send['tx_hash'])])
    print('Sends')
    print(str(table))
    print('\n')

    """
    # Orders.
    orders = address['orders']
    json_print(orders)
    table = PrettyTable(['Amount', 'Asset', 'Source', 'Destination', 'Tx Hash'])
    for order in orders:
        amount = util.devise(db, order['amount'], order['asset'], 'output')
        asset = order['asset']
        table.add_row([amount, asset, order['source'], order['destination'], util.short(order['tx_hash'])])
    print('orders')
    print(str(table))
    print('\n')
    """

    """
    # order_matches.
    order_matches = address['order_matches']
    json_print(order_matches)
    table = PrettyTable(['Give', 'Get', 'Source', 'Destination', 'Tx Hash'])
    for order_match in order_matches:
        amount = util.devise(db, order_match['amount'], order['asset'], 'output')
        asset = order_match['asset']
        table.add_row([amount, asset, order_match['source'], order_match['destination'], util.short(order_match['tx_hash'])])
    print('order_matches')
    print(str(table))
    print('\n')
    """
    # TODO


def format_order (order):
    give_remaining = util.devise(db, D(order['give_remaining']), order['give_asset'], 'output')
    get_remaining = util.devise(db, D(give_remaining) * D(order['price']), order['get_asset'], 'output')

    give_asset = order['give_asset']
    get_asset = order['get_asset']

    price = util.devise(db, D(get_remaining) / D(give_remaining), 'price', 'output')
    price_assets = get_asset + '/' + give_asset

    if order['fee_required']:
        fee = str(order['fee_required'] / config.UNIT)
    else:
        fee = str(order['fee_provided'] / config.UNIT)

    return [give_remaining, give_asset, get_remaining, get_asset, price, price_assets, fee, util.get_time_left(order), util.short(order['tx_hash'])]

def format_bet (bet):
    odds = D(bet['counterwager_amount']) / D(bet['wager_amount'])

    wager_remaining = D(bet['wager_remaining'])
    counterwager_remaining = round(wager_remaining * odds)

    if not bet['target_value']: target_value = None
    else: target_value = bet['target_value']
    if not bet['leverage']: leverage = None
    else: leverage = util.devise(db, D(bet['leverage']) / 5040, 'leverage', 'output')

    return [util.BET_TYPE_NAME[bet['bet_type']], bet['feed_address'], util.isodt(bet['deadline']), target_value, leverage, str(wager_remaining / config.UNIT) + ' XCP', str(counterwager_remaining / config.UNIT) + ' XCP', util.devise(db, odds, 'odds', 'output'), util.get_time_left(bet), util.short(bet['tx_hash'])]

def format_order_match (order_match):
    order_match_id = order_match['tx0_hash'] + order_match['tx1_hash']
    order_match_time_left = util.get_order_match_time_left(order_match)
    return [order_match_id, order_match_time_left]

def format_feed (feed):
    timestamp = util.isodt(feed['timestamp'])
    if not feed['text']:
        text = '<Locked>'
    else:
        text = feed['text']
    return [feed['source'], timestamp, text, feed['value'], D(feed['fee_multiplier']) / D(1e8)]


if __name__ == '__main__':
    # Parse command-line arguments.
    parser = argparse.ArgumentParser(prog='counterpartyd', description='the reference implementation of the Counterparty protocol')
    parser.add_argument('-V', '--version', action='version', version="counterpartyd v%s" % config.VERSION)

    parser.add_argument('-v', '--verbose', dest='verbose', action='store_true', help='sets log level to DEBUG instead of WARNING')
    parser.add_argument('--force', action='store_true', help='don\'t check whether Bitcoind is caught up')
    parser.add_argument('--testnet', action='store_true', help='use Bitcoin testnet addresses and block numbers')
    parser.add_argument('--testcoin', action='store_true', help='use the test Counterparty network on every blockchain')
    parser.add_argument('--unsigned', action='store_true', help='print out unsigned hex of transaction; do not sign or broadcast')

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

    subparsers = parser.add_subparsers(dest='action', help='the action to be taken')

    parser_server = subparsers.add_parser('server', help='run the server')

    parser_send = subparsers.add_parser('send', help='create and broadcast a *send* message')
    parser_send.add_argument('--from', metavar='SOURCE', dest='source', required=True, help='the source address')
    parser_send.add_argument('--to', metavar='DESTINATION', dest='destination', required=True, help='the destination address')
    parser_send.add_argument('--quantity', metavar='QUANTITY', required=True, help='the quantity of ASSET to send')
    parser_send.add_argument('--asset', metavar='ASSET', dest='asset', required=True, help='the ASSET of which you would like to send QUANTITY')

    parser_order = subparsers.add_parser('order', help='create and broadcast an *order* message')
    parser_order.add_argument('--from', metavar='SOURCE', dest='source', required=True, help='the source address')
    parser_order.add_argument('--get-quantity', metavar='GET_QUANTITY', required=True, help='the quantity of GET_ASSET that you would like to receive')
    parser_order.add_argument('--get-asset', metavar='GET_ASSET', required=True, help='the asset that you would like to sell')
    parser_order.add_argument('--give-quantity', metavar='GIVE_QUANTITY', required=True, help='the quantity of GIVE_ASSET that you are willing to give')
    parser_order.add_argument('--give-asset', metavar='GIVE_ASSET', required=True, help='the asset that you would like to buy')
    parser_order.add_argument('--expiration', metavar='EXPIRATION', type=int, required=True, help='the number of blocks for which the order should be valid')
    parser_order.add_argument('--fee_required', metavar='FEE_REQUIRED', default=0, help='the miners\' fee required to be paid by orders for them to match this one; in BTC; required iff buying BTC (may be zero, though)')
    parser_order.add_argument('--fee_provided', metavar='FEE_PROVIDED', default=(config.MIN_FEE / config.UNIT), help='the miners\' fee provided; in BTC; required iff selling BTC (should not be lower than is required for acceptance in a block)')

    parser_btcpay= subparsers.add_parser('btcpay', help='create and broadcast a *BTCpay* message, to settle an Order Match for which you owe BTC')
    parser_btcpay.add_argument('--order-match-id', metavar='ORDER_MATCH_ID', required=True, help='the concatenation of the hashes of the two transactions which compose the order match')

    parser_issuance = subparsers.add_parser('issuance', help='issue a new asset, issue more of an existing asset or transfer the ownership of an asset')
    parser_issuance.add_argument('--from', metavar='SOURCE', dest='source', required=True, help='the source address')
    parser_issuance.add_argument('--transfer-asset-to', metavar='TRANSFER_DESTINATION', dest='transfer_destination', help='for transfer of ownership of asset issuance rights')
    parser_issuance.add_argument('--quantity', metavar='QUANTITY', required=True, help='the quantity of ASSET to be issued')
    parser_issuance.add_argument('--asset', metavar='ASSET', required=True, help='the name of the asset to be issued (if it\'s available)')
    parser_issuance.add_argument('--divisible', action='store_true', help='whether or not the asset is divisible (must agree with previous issuances, if there are any)')

    parser_broadcast = subparsers.add_parser('broadcast', help='broadcast textual and numerical information to the network')
    parser_broadcast.add_argument('--from', metavar='SOURCE', dest='source', required=True, help='the source address')
    parser_broadcast.add_argument('--text', metavar='TEXT', required=True, help='the textual part of the broadcast')
    parser_broadcast.add_argument('--value', metavar='VALUE', type=float, default=0, help='numerical value of the broadcast')
    parser_broadcast.add_argument('--fee-multiplier', metavar='FEE_MULTIPLIER', required=True, help='how much of every bet on this feed should go to its operator; a fraction of 1, (i.e. .05 is five percent)')

    parser_order = subparsers.add_parser('bet', help='offer to make a bet on the value of a feed')
    parser_order.add_argument('--from', metavar='SOURCE', dest='source', required=True, help='the source address')
    parser_order.add_argument('--feed-address', metavar='FEED_ADDRESS', required=True, help='the address which publishes the feed to bet on')
    parser_order.add_argument('--bet-type', metavar='BET_TYPE', choices=list(util.BET_TYPE_NAME.values()), required=True, help='choices: {}'.format(list(util.BET_TYPE_NAME.values())))
    parser_order.add_argument('--deadline', metavar='DEADLINE', required=True, help='the date and time at which the bet should be decided/settled')
    parser_order.add_argument('--wager', metavar='WAGER_QUANTITY', required=True, help='the quantity of XCP to wager')
    parser_order.add_argument('--counterwager', metavar='COUNTERWAGER_QUANTITY', required=True, help='the minimum quantity of XCP to be wagered by the user to bet against you, if he were to accept the whole thing')
    parser_order.add_argument('--target-value', metavar='TARGET_VALUE', default=0.0, help='target value for Equal/NotEqual bet')
    parser_order.add_argument('--leverage', metavar='LEVERAGE', type=int, default=5040, help='leverage, as a fraction of 5040')
    parser_order.add_argument('--expiration', metavar='EXPIRATION', type=int, required=True, help='the number of blocks for which the bet should be valid')

    parser_dividend = subparsers.add_parser('dividend', help='pay dividends to the holders of an asset (in proportion to their stake in it)')
    parser_dividend.add_argument('--from', metavar='SOURCE', dest='source', required=True, help='the source address')
    parser_dividend.add_argument('--quantity-per-share', metavar='QUANTITY_PER_SHARE', required=True, help='the quantity of XCP to be paid per unit (satoshi) held of SHARE_ASSET')
    parser_dividend.add_argument('--share-asset', metavar='SHARE_ASSET', required=True, help='the asset to which pay dividends')

    parser_burn = subparsers.add_parser('burn', help='destroy bitcoins to earn XCP, during an initial period of time')
    parser_burn.add_argument('--from', metavar='SOURCE', dest='source', required=True, help='the source address')
    parser_burn.add_argument('--quantity', metavar='QUANTITY', required=True, help='quantity of BTC to be destroyed')

    parser_cancel= subparsers.add_parser('cancel', help='cancel an open order or bet you created')
    parser_cancel.add_argument('--offer-hash', metavar='OFFER_HASH', required=True, help='the transaction hash of the order or bet')

    parser_address = subparsers.add_parser('address', help='display the history of a Counterparty address')
    parser_address.add_argument('address', metavar='ADDRESS', help='the address you are interested in')

    parser_asset = subparsers.add_parser('asset', help='display the basic properties of a Counterparty asset')
    parser_asset.add_argument('asset', metavar='ASSET', help='the asset you are interested in')

    parser_wallet = subparsers.add_parser('wallet', help='list the addresses in your Bitcoind wallet along with their balances in all Counterparty assets')

    parser_market = subparsers.add_parser('market', help='fill the screen with an always up-to-date summary of the Counterparty market')
    parser_market.add_argument('--give-asset', metavar='GIVE_ASSET', help='only show orders offering to sell GIVE_ASSET')
    parser_market.add_argument('--get-asset', metavar='GET_ASSET', help='only show orders offering to buy GET_ASSET')

#    parser_purge = subparsers.add_parser('purge', help='reparse all transactions in the database')

    args = parser.parse_args()


    # Configuration

    # Data directory
    if not args.data_dir:
        config.data_dir = appdirs.user_data_dir(appauthor='Counterparty', appname='counterpartyd', roaming=True)
    else:
        config.data_dir = args.data_dir
    if not os.path.isdir(config.data_dir): os.mkdir(config.data_dir)

    # Bitcoind RPC options.
    configfile = configparser.ConfigParser()
    config_path = os.path.join(config.data_dir, 'counterpartyd.conf')
    configfile.read(config_path)
    has_config = 'Default' in configfile
    #logging.debug("Config file: %s; Exists: %s" % (config_path, "Yes" if has_config else "No"))

    # testnet
    if args.testnet:
        config.TESTNET = args.testnet
    elif has_config and 'testnet' in configfile['Default']:
        config.TESTNET = configfile['Default'].getboolean('testnet')
    else:
        config.TESTNET = False

    # testcoin
    if args.testcoin:
        config.TESTCOIN = args.testcoin
    elif has_config and 'testcoin' in configfile['Default']:
        config.TESTCOIN = configfile['Default'].getboolean('testcoin')
    else:
        config.TESTCOIN = False

    # Bitcoind RPC user
    if args.bitcoind_rpc_user:
        config.BITCOIND_RPC_USER = args.bitcoind_rpc_user
    elif has_config and 'bitcoind-rpc-user' in configfile['Default']:
        config.BITCOIND_RPC_USER = configfile['Default']['bitcoind-rpc-user']
    else:
        config.BITCOIND_RPC_USER = 'bitcoinrpc'

    # Bitcoind RPC host
    if args.bitcoind_rpc_connect:
        config.BITCOIND_RPC_CONNECT = args.bitcoind_rpc_connect
    elif has_config and 'bitcoind-rpc-connect' in configfile['Default']:
        config.BITCOIND_RPC_CONNECT = configfile['Default']['bitcoind-rpc-connect']
    else:
        config.BITCOIND_RPC_CONNECT = 'localhost'

    # Bitcoind RPC port
    if args.bitcoind_rpc_port:
        config.BITCOIND_RPC_PORT = args.bitcoind_rpc_port
    elif has_config and 'bitcoind-rpc-port' in configfile['Default']:
        config.BITCOIND_RPC_PORT = configfile['Default']['bitcoind-rpc-port']
    else:
        if config.TESTNET:
            config.BITCOIND_RPC_PORT = '18332'
        else:
            config.BITCOIND_RPC_PORT = '8332'
            
    # Bitcoind RPC password
    if args.bitcoind_rpc_password:
        config.BITCOIND_RPC_PASSWORD = args.bitcoind_rpc_password
    elif has_config and 'bitcoind-rpc-password' in configfile['Default']:
        config.BITCOIND_RPC_PASSWORD = configfile['Default']['bitcoind-rpc-password']
    else:
        raise exceptions.ConfigurationError('RPC password not set. (Use configuration file or --bitcoind-rpc-password=PASSWORD)')

    config.BITCOIND_RPC = 'http://' + config.BITCOIND_RPC_USER + ':' + config.BITCOIND_RPC_PASSWORD + '@' + config.BITCOIND_RPC_CONNECT + ':' + str(config.BITCOIND_RPC_PORT)

    # RPC host
    if args.rpc_host:
        config.RPC_HOST = args.rpc_host
    elif has_config and 'rpc-host' in configfile['Default']:
        config.RPC_HOST = configfile['Default']['rpc-host']
    else:
        config.RPC_HOST = 'localhost'

    # RPC port
    if args.rpc_port:
        config.RPC_PORT = args.rpc_port
    elif has_config and 'rpc-port' in configfile['Default']:
        config.RPC_PORT = configfile['Default']['rpc-port']
    else:
        if config.TESTNET:
            config.RPC_PORT = '14000'
        else:
            config.RPC_PORT = '4000'
  
    # Log
    if args.log_file:
        config.LOG = args.log_file
    elif has_config and 'logfile' in configfile['Default']:
        config.LOG = configfile['Default']['logfile']
    else:
        if config.TESTNET:
            config.LOG = os.path.join(config.data_dir, 'counterpartyd.testnet.log')
        else:
            config.LOG = os.path.join(config.data_dir, 'counterpartyd.log')
    if config.LOG == '-':                       # TODO: Kill
        config.LOG = None   # Log to stdout.    # TODO: Kill
    if args.verbose:
        log_level = logging.DEBUG
    else:
        log_level = logging.INFO
    logging.basicConfig(filename=config.LOG, level=log_level,
                        format='%(asctime)s %(message)s',
                        datefmt='%Y-%m-%d-T%H:%M:%S%z')

    # Log also to stderr.
    console = logging.StreamHandler()
    console.setLevel(logging.INFO)
    formatter = logging.Formatter('%(message)s')
    console.setFormatter(formatter)
    logging.getLogger('').addHandler(console)

    requests_log = logging.getLogger("requests")
    requests_log.setLevel(logging.DEBUG if args.verbose else logging.WARNING)

    # Database
    if config.TESTNET:
        config.DB_VERSION = str(config.DB_VERSION) + '.testnet'
    if args.database_file:
        config.DATABASE = args.database_file
    else:
        config.DATABASE = os.path.join(config.data_dir, 'counterpartyd.' + str(config.DB_VERSION) + '.db')

    # For create()s.
    db = sqlite3.connect(config.DATABASE)
    db.row_factory = sqlite3.Row
    db.isolation_level = None

    # db.execute('pragma foreign_keys=ON')

    # (more) Testnet
    if config.TESTNET:
        config.ADDRESSVERSION = b'\x6f'
        config.BLOCK_FIRST = 154908
        config.BURN_START = 154908
        config.BURN_END = 4017708    # Fifty years, at ten minutes per block.
        config.UNSPENDABLE = 'mvCounterpartyXXXXXXXXXXXXXXW24Hef'

    else:
        config.ADDRESSVERSION = b'\x00'
        config.BLOCK_FIRST = 278270
        config.BURN_START = 278310
        config.BURN_END = 283810
        config.UNSPENDABLE = '1CounterpartyXXXXXXXXXXXXXXXUWLpVr'

    if config.TESTCOIN:
        config.PREFIX = b'XX'                   # 2 bytes (possibly accidentally created)
    else:
        config.PREFIX = b'CNTRPRTY'             # 8 bytes

    if args.action == None: args.action = 'server'

    # Check that bitcoind is running, communicable, and caught up with the blockchain.
    # Check that the database has caught up with bitcoind.
    if not args.force:
        util.bitcoind_check(db)
        if args.action not in ('server',):
            util.database_check(db)

    # Do something.
    if args.action == 'send':
        quantity = util.devise(db, args.quantity, args.asset, 'input')
        unsigned_tx_hex = send.create(db, args.source, args.destination,
                                      quantity, args.asset)
        json_print(bitcoin.transmit(unsigned_tx_hex, unsigned=args.unsigned))

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
                raise exceptions.UselessError('No fee should be required or provided (explicitly) if not buying or selling BTC.')
            fee_required = 0
            fee_provided = config.MIN_FEE

        give_quantity = util.devise(db, args.give_quantity, args.give_asset, 'input')
        get_quantity = util.devise(db, args.get_quantity, args.get_asset, 'input')
        unsigned_tx_hex = order.create(db, args.source, args.give_asset, give_quantity,
                                args.get_asset, get_quantity,
                                args.expiration, fee_required, fee_provided)
        json_print(bitcoin.transmit(unsigned_tx_hex, unsigned=args.unsigned))

    elif args.action == 'btcpay':
        unsigned_tx_hex = btcpay.create(db, args.order_match_id)
        json_print(bitcoin.transmit(unsigned_tx_hex, unsigned=args.unsigned))

    elif args.action == 'issuance':
        quantity = util.devise(db, args.quantity, None, 'input',
                               divisible=args.divisible)
        unsigned_tx_hex = issuance.create(db, args.source,
                                          args.transfer_destination,
                                          args.asset, quantity, args.divisible)
        json_print(bitcoin.transmit(unsigned_tx_hex, unsigned=args.unsigned))

    elif args.action == 'broadcast':
        # Use a magic number to store the fee multplier as an integer.
        fee_multiplier = round(D(args.fee_multiplier) * D(1e8))
        if fee_multiplier > 4294967295:
            raise exceptions.OverflowError('Fee multiplier must be less than or equal to 42.94967295.')
        value = util.devise(db, args.value, 'value', 'input')
        unsigned_tx_hex = broadcast.create(db, args.source, int(time.time()),
                                           value, fee_multiplier, args.text)
        json_print(bitcoin.transmit(unsigned_tx_hex, unsigned=args.unsigned))

    elif args.action == 'bet':
        deadline = round(datetime.timestamp(dateutil.parser.parse(args.deadline)))
        wager = util.devise(db, args.wager, 'XCP', 'input')
        counterwager = util.devise(db, args.counterwager, 'XCP', 'input')
        target_value = util.devise(db, args.target_value, 'value', 'input')
        leverage = util.devise(db, args.leverage, 'leverage', 'input')

        unsigned_tx_hex = bet.create(db, args.source, args.feed_address,
                                     util.BET_TYPE_ID[args.bet_type], deadline,
                                     wager, counterwager, target_value,
                                     leverage, args.expiration)
        json_print(bitcoin.transmit(unsigned_tx_hex, unsigned=args.unsigned))

    elif args.action == 'dividend':
        quantity_per_share = util.devise(db, args.quantity_per_share, 'XCP', 'input')
        unsigned_tx_hex = dividend.create(db, args.source, quantity_per_share,
                                   args.share_asset)
        json_print(bitcoin.transmit(unsigned_tx_hex, unsigned=args.unsigned))

    elif args.action == 'burn':
        quantity = util.devise(db, args.quantity, 'BTC', 'input')
        unsigned_tx_hex = burn.create(db, args.source, quantity)
        json_print(bitcoin.transmit(unsigned_tx_hex, unsigned=args.unsigned))

    elif args.action == 'cancel':
        unsigned_tx_hex = cancel.create(db, args.offer_hash)
        json_print(bitcoin.transmit(unsigned_tx_hex, unsigned=args.unsigned))

    elif args.action == 'address':
        try:
            bitcoin.base58_decode(args.address, config.ADDRESSVERSION)
        except Exception:
            raise exceptions.InvalidAddressError('Invalid Bitcoin address:',
                                                  args.address)
        address(args.address)

    elif args.action == 'asset':
        if args.asset == 'XCP':
            burns = util.get_burns(db, validity='Valid', address=None)
            total = sum([burn['earned'] for burn in burns])
            total = util.devise(db, total, args.asset, 'output')
            divisible = True
            issuer = None
        elif args.asset == 'BTC':
            total = None
            divisible = True
            issuer = None
        else:
            issuances = util.get_issuances(db, validity='Valid', asset=args.asset)
            total = sum([issuance['amount'] for issuance in issuances])
            total = util.devise(db, total, args.asset, 'output')
            divisible = bool(issuances[-1]['divisible'])
            issuer = issuances[-1]['issuer'] # Issuer of last issuance.

        print('Asset Name:', args.asset)
        print('Asset ID:', util.get_asset_id(args.asset))
        print('Total Issued:', total)
        print('Divisible:', divisible)
        print('Issuer:', issuer)

    elif args.action == 'wallet':
        total_table = PrettyTable(['Asset', 'Balance'])
        totals = {}

        print()
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
                    print(str(table))
                    print()
        for asset in totals.keys():
            balance = totals[asset]
            total_table.add_row([asset, balance])
        print('TOTAL')
        print(str(total_table))
        print()

    elif args.action == 'market':
        while True:
            market(args.give_asset, args.get_asset)

#     elif args.action == 'purge':
#         blocks.purge(db)
           
    elif args.action == 'help':
        parser.print_help()

    elif args.action == 'server':
        thread=api.reqthread()
        thread.daemon = True
        thread.start()

        blocks.follow(db)

    else:
        parser.print_help()

# vim: tabstop=8 expandtab shiftwidth=4 softtabstop=4
