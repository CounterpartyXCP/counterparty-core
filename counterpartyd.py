#! /usr/bin/env python3

import os
import argparse
import json

from prettytable import PrettyTable

import decimal
D = decimal.Decimal

import sqlite3
import logging
import appdirs
import configparser

import time
import dateutil.parser
from datetime import datetime

from lib import (config, util, exceptions, bitcoin, blocks)
from lib import (send, order, btcpay, issuance, broadcast, bet, dividend, burn, util)

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
    bets = util.get_bets(db, validity='Valid', show_expired=False, show_empty=False)
    table = PrettyTable(['Bet Type', 'Feed Address', 'Deadline', 'Target Value', 'Leverage', 'Wager', 'Counterwager', 'Odds', 'Time Left', 'Tx Hash'])
    for bet in bets:
        bet = format_bet(bet)
        table.add_row(bet)
    print('Open Bets')
    print(str(table))
    print('\n')

    # Matched orders awaiting BTC payments from you.
    my_addresses  = [ element['address'] for element in bitcoin.rpc('listreceivedbyaddress', [0,True])['result'] ]
    awaiting_btcs = util.get_order_matches(db, validity='Valid: awaiting BTC payment', addresses=my_addresses, show_expired=False)
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
    for balance in balances:
        asset = balance['asset']
        amount = util.devise(db, balance['amount'], balance['asset'], 'output')
        table.add_row([asset, amount])
    print('Balances')
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
    price = D(order['get_amount']) / D(order['give_amount'])

    give_remaining = util.devise(db, D(order['give_remaining']), order['give_asset'], 'output')
    get_remaining = give_remaining * price

    give_asset = order['give_asset']
    get_asset = order['get_asset']

    price = util.devise(db, get_remaining/ give_remaining, 'price', 'output')
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

    return [util.BET_TYPE_NAME[bet['bet_type']], bet['feed_address'], bet['deadline'], target_value, leverage, str(wager_remaining / config.UNIT) + ' XCP', str(counterwager_remaining / config.UNIT) + ' XCP', util.devise(db, odds, 'odds', 'output'), util.get_time_left(bet), util.short(bet['tx_hash'])]

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
    # Parse command‐line arguments.
    parser = argparse.ArgumentParser(prog='counterpartyd', description='the reference implementation of the Counterparty protocol')
    parser.add_argument('-V', '--version', action='version', version="counterpartyd v%s" % config.VERSION)

    parser.add_argument('-v', '--verbose', dest='verbose', action='store_true', help='sets log level to DEBUG instead of WARNING')
    parser.add_argument('--force', action='store_true', help='don’t check whether Bitcoind is caught up')
    parser.add_argument('--testnet', action='store_true', help='use Bitcoin testnet addresses and block numbers')
    parser.add_argument('--testcoin', action='store_true', help='use the test Counterparty network on every blockchain')

    parser.add_argument('--data-dir', help='the directory in which to keep the database, config file and log file, by default')
    parser.add_argument('--database-file', help='the location of the SQLite3 database')
    parser.add_argument('--config-file', help='the location of the configuration file')
    parser.add_argument('--log-file', help='the location of the log file')

    parser.add_argument('--rpc-connect', help='the hostname of the Bitcoind JSON‐RPC server')
    parser.add_argument('--rpc-port', type=int, help='the port used to communicate with Bitcoind over JSON‐RPC')
    parser.add_argument('--rpc-user', help='the username used to communicate with Bitcoind over JSON‐RPC')
    parser.add_argument('--rpc-password', help='the password used to communicate with Bitcoind over JSON‐RPC')

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
    parser_order.add_argument('--fee', metavar='FEE', help='either the required fee, or the provided fee, as appropriate; in BTC, to be paid to miners; required iff the order involves BTC')

    parser_btcpay= subparsers.add_parser('btcpay', help='create and broadcast a *BTCpay* message, to settle an Order Match for which you owe BTC')
    parser_btcpay.add_argument('--order-match-id', metavar='ORDER_MATCH_ID', required=True, help='the concatenation of the hashes of the two transactions which compose the order match')

    parser_issuance = subparsers.add_parser('issuance', help='issue a new asset, issue more of an existing asset or transfer the ownership of an asset')
    parser_issuance.add_argument('--from', metavar='SOURCE', dest='source', required=True, help='the source address')
    parser_issuance.add_argument('--transfer-asset-to', metavar='TRANSFER_DESTINATION', dest='transfer_destination', help='for transfer of ownership of asset issuance rights')
    parser_issuance.add_argument('--quantity', metavar='QUANTITY', required=True, help='the quantity of ASSET to be issued')
    parser_issuance.add_argument('--asset', metavar='ASSET', required=True, help='the name of the asset to be issued (if it’s available)')
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

    parser_burn = subparsers.add_parser('burn', help='destroy bitcoins in miners’s fees to earn XCP, during an initial period of time')
    parser_burn.add_argument('--from', metavar='SOURCE', dest='source', required=True, help='the source address')
    parser_burn.add_argument('--quantity', metavar='QUANTITY', required=True, help='quantity of BTC to be destroyed in miners’ fees')

    parser_address = subparsers.add_parser('address', help='display the history of a Counterparty address')
    parser_address.add_argument('address', metavar='ADDRESS', help='the address you are interested in')

    parser_asset = subparsers.add_parser('asset', help='display the basic properties of a Counterparty asset')
    parser_asset.add_argument('asset', metavar='ASSET', help='the asset you are interested in')

    parser_market = subparsers.add_parser('market', help='fill the screen with an always up‐to‐date summary of the Counterparty market')
    parser_market.add_argument('--give-asset', metavar='GIVE_ASSET', help='only show orders offering to sell GIVE_ASSET')
    parser_market.add_argument('--get-asset', metavar='GET_ASSET', help='only show orders offering to buy GET_ASSET')

    args = parser.parse_args()


    # Configuration

    # Data directory
    if not args.data_dir:
        config.data_dir = appdirs.user_data_dir(appauthor='Counterparty', appname='counterpartyd')
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

    # RPC user
    if args.rpc_user:
        config.rpc_user = args.rpc_user
    elif has_config and 'rpc-user' in configfile['Default']:
        config.rpc_user = configfile['Default']['rpc-user']
    else:
        config.rpc_user = 'bitcoinrpc'

    # RPC host
    if args.rpc_connect:
        config.rpc_connect = args.rpc_connect
    elif has_config and 'rpc-connect' in configfile['Default']:
        config.rpc_connect = configfile['Default']['rpc-connect']
    else:
        config.rpc_connect = 'localhost'

    # RPC port
    if args.rpc_port:
        config.rpc_port = args.rpc_port
    elif has_config and 'rpc-port' in configfile['Default']:
        config.rpc_port = configfile['Default']['rpc-port']
    else:
        if config.TESTNET:
            config.rpc_port = '18332'
        else:
            config.rpc_port = '8332'
            
    # RPC password
    if args.rpc_password:
        config.rpc_password = args.rpc_password
    elif has_config and 'rpc-password' in configfile['Default']:
        config.rpc_password = configfile['Default']['rpc-password']
    else:
        raise exceptions.ConfigurationError('RPC password not set. (Use configuration file or --rpc-password=PASSWORD)')

    config.RPC = 'http://' + config.rpc_user + ':' + config.rpc_password + '@' + config.rpc_connect + ':' + str(config.rpc_port)

    # Database
    if args.database_file:
        config.DATABASE = args.database_file
    else:
        config.DATABASE = os.path.join(config.data_dir, 'counterpartyd.' + str(config.DB_VERSION) + '.db')

    # For create()s.
    db = sqlite3.connect(config.DATABASE)
    db.row_factory = sqlite3.Row
    follow_cursor = db.cursor()

    # Log
    if args.log_file:
        config.LOG = args.log_file
    elif 'logfile' in configfile['Default']:
        config.LOG = configfile['Default']['logfile']
    else:
        config.LOG = os.path.join(config.data_dir, 'counterpartyd.log')
    if config.LOG == '-':
        config.LOG = None   # Log to stdout.
    logging.basicConfig(filename=config.LOG, level=logging.INFO,
                        format='%(asctime)s %(message)s',
                        datefmt='%m-%d-%YT%I:%M:%S%z')
    requests_log = logging.getLogger("requests")
    requests_log.setLevel(logging.DEBUG if args.verbose else logging.WARNING)

    # (more) Testnet
    if config.TESTNET:
        config.ADDRESSVERSION = b'\x6F'
        config.BLOCK_FIRST = 154759
        config.BURN_START = 154759
        config.BURN_END = 156000
    else:
        config.ADDRESSVERSION = b'\x00'
        config.BLOCK_FIRST = 277910 # TODO: TEMP
        config.BURN_START = 277910 # TODO: TEMP
        config.BURN_END = 278910 # TODO: TEMP

    if config.TESTCOIN:
        config.PREFIX = b'XX'                   # 2 bytes (possibly accidentally created)
    else:
        config.PREFIX = b'CNTRPRTY'             # 8 bytes

    # Check that bitcoind is running, communicable, and caught up with the blockchain.
    if not args.force:
        bitcoin.bitcoind_check()

    # Do something.
    if args.action == 'send':
        quantity = util.devise(db, args.quantity, args.asset, 'input')
        unsigned_tx_hex = send.create(db, args.source, args.destination,
                                      quantity, args.asset)
        json_print(bitcoin.transmit(unsigned_tx_hex))

    elif args.action == 'order':
        # Fee argument is either fee_required or fee_provided, as necessary.
        if give_asset == 'BTC':
            fee_provided = round(D(args.fee) * config.UNIT)
            assert fee_provided >= config.MIN_FEE
            fee_required = 0
        elif get_asset == 'BTC':
            fee_required = round(D(args.fee) * config.UNIT)
            assert fee_required >= config.MIN_FEE
            fee_provided = config.MIN_FEE
        else:
            if args.fee:
                raise exceptions.UselessError('No fee should be specified if not buying or selling BTC.')
            fee_required = 0
            fee_provided = config.MIN_FEE

        give_quantity = util.devise(db, args.give_quantity, args.give_asset, 'input')
        get_quantity = util.devise(db, args.get_quantity, args.get_asset, 'input')
        unsigned_tx_hex = order.create(db, args.source, args.give_asset, give_quantity,
                                args.get_asset, get_quantity,
                                args.expiration, fee_required, fee_provided)
        json_print(bitcoin.transmit(unsigned_tx_hex))

    elif args.action == 'btcpay':
        unsigned_tx_hex = btcpay.create(db, args.order_match_id)
        json_print(bitcoin.transmit(unsigned_tx_hex))

    elif args.action == 'issuance':
        quantity = util.devise(db, args.quantity, None, 'input',
                               divisible=args.divisible)
        unsigned_tx_hex = issuance.create(db, args.source,
                                          args.transfer_destination,
                                          args.asset, quantity, args.divisible)
        json_print(bitcoin.transmit(unsigned_tx_hex))

    elif args.action == 'broadcast':
        # Use a magic number to store the fee multplier as an integer.
        fee_multiplier = round(D(args.fee_multiplier) * D(1e8))
        if fee_multiplier > 4294967295:
            raise exceptions.OverflowError('Fee multiplier must be less than or equal to 42.94967295.')
        value = util.devise(db, value, 'value', 'input')
        unsigned_tx_hex = broadcast.create(db, args.source, int(time.time()),
                                           value, fee_multiplier, args.text)
        json_print(bitcoin.transmit(unsigned_tx_hex))

    elif args.action == 'bet':
        deadline = round(datetime.timestamp(dateutil.parser.parse(args.deadline)))
        wager = util.devise(db, value, 'XCP', 'input')
        counterwager = util.devise(db, value, 'XCP', 'input')
        target_value = util.devise(db, value, 'value', 'input')
        leverage = util.devise(db, value, 'leverage', 'input')

        unsigned_tx_hex = bet.create(db, args.source, args.feed_address,
                                     util.BET_TYPE_ID[args.bet_type], deadline,
                                     wager, counterwager, target_value,
                                     leverage, args.expiration)
        json_print(bitcoin.transmit(unsigned_tx_hex))

    elif args.action == 'dividend':
        quantity_per_share = util.devise(db, args.quantity_per_share, 'XCP', 'input')
        unsigned_tx_hex = dividend.create(db, args.source, quantity_per_share,
                                   args.share_asset)
        json_print(bitcoin.transmit(unsigned_tx_hex))

    elif args.action == 'burn':
        quantity = util.devise(db, args.quantity, 'BTC', 'input')
        unsigned_tx_hex = burn.create(db, args.source, quantity)
        json_print(bitcoin.transmit(unsigned_tx_hex))

    elif args.action == 'address':
        address(args.address)

    elif args.action == 'asset':
        issuances = util.get_issuances(db, validity='Valid', asset=args.asset)
        total = sum([issuance['amount'] for issuance in issuances])
        print('Asset Name:', args.asset)
        print('Asset ID:', util.get_asset_id(args.asset))
        print('Total Issued:', util.devise(db, total, args.asset, 'output'))
        print('Divisible:', bool(issuances[-1]['divisible']))
        print('Issuer:', issuances[-1]['issuer']) # Issuer of last issuance.

    elif args.action == 'market':
        while True:
            market(args.give_asset, args.get_asset)
           
    elif args.action == 'help':
        parser.print_help()

    else:
        blocks.follow()

# vim: tabstop=8 expandtab shiftwidth=4 softtabstop=4
