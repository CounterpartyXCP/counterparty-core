#! /usr/bin/env python3

import os
import argparse
import json

import colorama
colorama.init()
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
from lib import (send, order, btcpay, issuance, broadcast, bet, dividend, burn, api)

json_print = lambda x: print(json.dumps(x, sort_keys=True, indent=4))


def watch ():
    os.system('cls' if os.name=='nt' else 'clear')

    # Open orders.
    orders = api.get_orders(db, validity='Valid', show_expired=False, show_empty=False)
    table = PrettyTable(['Give', 'Get', 'Price', 'Fee', 'Time Left', 'Tx Hash'])
    for order in orders:
        order = format_order(order)
        table.add_row(order)
    print(colorama.Fore.WHITE + colorama.Style.BRIGHT + 'Open Orders' + colorama.Style.RESET_ALL)
    print(colorama.Fore.BLUE + str(table) + colorama.Style.RESET_ALL)
    print('\n')

    # Open bets.
    bets = api.get_bets(db, validity='Valid', show_expired=False, show_empty=False)
    table = PrettyTable(['Bet Type', 'Feed Address', 'Deadline', 'target_value', 'Leverage', 'Wager', 'Counterwager', 'Odds', 'Time Left', 'Tx Hash'])
    for bet in bets:
        bet = format_bet(bet)
        table.add_row(bet)
    print(colorama.Fore.WHITE + colorama.Style.BRIGHT + 'Open Bets' + colorama.Style.RESET_ALL)
    print(colorama.Fore.GREEN + str(table) + colorama.Style.RESET_ALL)
    print('\n')

    # Matched orders awaiting BTC payments from you.
    my_addresses  = [ element['address'] for element in bitcoin.rpc('listreceivedbyaddress', [0,True])['result'] ]
    awaiting_btcs = api.get_order_matches(db, validity='Valid: awaiting BTC payment', addresses=my_addresses, show_expired=False)
    table = PrettyTable(['Matched Order ID', 'Time Left'])
    for order_match in awaiting_btcs:
        order_match = format_order_match(order_match)
        table.add_row(order_match)
    print(colorama.Fore.WHITE + colorama.Style.BRIGHT + 'Order Matches Awaiting BTC Payment' + colorama.Style.RESET_ALL)
    print(colorama.Fore.CYAN + colorama.Style.BRIGHT + str(table) + colorama.Style.RESET_ALL)
    print('\n')

    # Running feeds
    broadcasts = api.get_broadcasts(db, validity='Valid', order_by='timestamp DESC')
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
    print(colorama.Fore.WHITE + colorama.Style.BRIGHT + 'Running Feeds' + colorama.Style.RESET_ALL)
    print(colorama.Fore.MAGENTA + str(table) + colorama.Style.RESET_ALL)

    time.sleep(30)


def history (address):
    history = api.get_history(db, address)

    # TODO: Debits, credits

    # Balances.
    balances = history['balances']
    table = PrettyTable(['Asset', 'Amount'])
    for balance in balances:
        asset = util.get_asset_name(balance['asset_id'])
        amount = util.devise(db, balance['amount'], balance['asset_id'], 'output')
        table.add_row([asset, amount])
    print(colorama.Fore.WHITE + colorama.Style.BRIGHT + 'Balances' + colorama.Style.RESET_ALL)
    print(colorama.Fore.CYAN + str(table) + colorama.Style.RESET_ALL)
    print('\n')

    # Sends.
    sends = history['sends']
    table = PrettyTable(['Amount', 'Asset', 'Source', 'Destination', 'Tx Hash'])
    for send in sends:
        amount = util.devise(db, send['amount'], send['asset_id'], 'output')
        asset = util.get_asset_name(send['asset_id'])
        table.add_row([amount, asset, send['source'], send['destination'], util.short(send['tx_hash'])])
    print(colorama.Fore.WHITE + colorama.Style.BRIGHT + 'Sends' + colorama.Style.RESET_ALL)
    print(colorama.Fore.YELLOW + str(table) + colorama.Style.RESET_ALL)
    print('\n')

    # TODO


def format_order (order):
    price = D(order['get_amount']) / D(order['give_amount'])

    give_remaining = util.devise(db, D(order['give_remaining']), order['give_id'], 'output')
    get_remaining = give_remaining * price
    give_name = util.get_asset_name(order['give_id'])
    get_name = util.get_asset_name(order['get_id'])
    give = str(give_remaining) + ' ' + give_name
    get = str(round(get_remaining, 8)) + ' ' + get_name

    price_string = str(price.quantize(config.FOUR).normalize())
    price_string += ' ' + get_name + '/' + give_name

    if order['fee_required']:
        fee = str(order['fee_required'] / config.UNIT) + ' BTC (required)'
    else:
        fee = str(order['fee_provided'] / config.UNIT) + ' BTC (provided)'

    return [give, get, price_string, fee, util.get_time_left(order), util.short(order['tx_hash'])]

def format_bet (bet):
    odds = D(bet['counterwager_amount']) / D(bet['wager_amount'])

    wager_remaining = D(bet['wager_remaining'])
    counterwager_remaining = round(wager_remaining * odds)

    if not bet['target_value']: target_value = None
    else: target_value = bet['target_value']
    if not bet['leverage']: leverage = None
    else: leverage = D(D(bet['leverage']) / 5040).quantize(config.FOUR).normalize()

    return [util.BET_TYPE_NAME[bet['bet_type']], bet['feed_address'], bet['deadline'], target_value, leverage, str(wager_remaining / config.UNIT) + ' XCP', str(counterwager_remaining / config.UNIT) + ' XCP', odds.quantize(config.FOUR).normalize(), util.get_time_left(bet), util.short(bet['tx_hash'])]

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
    parser = argparse.ArgumentParser(prog='counterpartyd', description='')
    parser.add_argument('-V', '--version', action='version',
        version="counterpartyd v%s" % config.VERSION)

    parser.add_argument('--testnet', type=bool, help='')
    parser.add_argument('--testcoin', type=bool, help='')

    parser.add_argument('--data-dir', help='')
    parser.add_argument('--database-file', help='')
    parser.add_argument('--config-file', help='')
    parser.add_argument('--log-file', help='')

    parser.add_argument('--rpc-connect', help='')
    parser.add_argument('--rpc-port', type=int, help='')
    parser.add_argument('--rpc-user', help='')
    parser.add_argument('--rpc-password', help='')

    subparsers = parser.add_subparsers(dest='action', 
                                       help='the action to be taken')

    parser_send = subparsers.add_parser('send', help='requires bitcoind')
    parser_send.add_argument('--from', metavar='SOURCE', dest='source', required=True, help='')
    parser_send.add_argument('--to', metavar='DESTINATION', dest='destination', required=True, help='')
    parser_send.add_argument('--quantity', metavar='QUANTITY', required=True, help='')
    parser_send.add_argument('--asset', metavar='ASSET', dest='asset', required=True, help='')

    parser_order = subparsers.add_parser('order', help='requires bitcoind')
    parser_order.add_argument('--from', metavar='SOURCE', dest='source', required=True, help='')
    parser_order.add_argument('--get-quantity', metavar='GET_QUANTITY', required=True, help='')
    parser_order.add_argument('--get-asset', metavar='GET_ASSET', required=True, help='')
    parser_order.add_argument('--give-quantity', metavar='GIVE_QUANTITY', required=True, help='')
    parser_order.add_argument('--give-asset', metavar='GIVE_ASSET', required=True, help='')
    parser_order.add_argument('--expiration', metavar='EXPIRATION', type=int, required=True, help='')
    parser_order.add_argument('--fee', metavar='FEE', required=True, help='either the required fee, or the provided fee, as appropriate; in BTC, to be paid to miners')

    parser_btcpay= subparsers.add_parser('btcpay', help='requires bitcoind')
    parser_btcpay.add_argument('--order-match-id', metavar='ORDER_MATCH_ID', required=True, help='')

    parser_issuance = subparsers.add_parser('issuance', help='requires bitcoind')
    parser_issuance.add_argument('--from', metavar='SOURCE', dest='source', required=True, help='')
    parser_issuance.add_argument('--quantity', metavar='QUANTITY', required=True, help='')
    parser_issuance.add_argument('--asset-id', metavar='ASSET_ID', type=int, required=True, help='')
    parser_issuance.add_argument('--divisible', metavar='DIVISIBLE', type=bool, required=True, help='whether or not the asset is divisible (must agree with previous issuances, if this is a re‐issuance)')

    parser_broadcast = subparsers.add_parser('broadcast', help='requires bitcoind')
    parser_broadcast.add_argument('--from', metavar='SOURCE', dest='source', required=True, help='')
    parser_broadcast.add_argument('--text', metavar='TEXT', required=True, help='')
    parser_broadcast.add_argument('--value', metavar='VALUE', type=float, default=0, help='numerical value of the broadcast')
    parser_broadcast.add_argument('--fee-multiplier', metavar='FEE_MULTIPLIER', required=True, help='how much of every bet on this feed should go to its operator; a fraction of 1, (i.e. .05 is five percent)')

    parser_order = subparsers.add_parser('bet', help='requires bitcoind')
    parser_order.add_argument('--from', metavar='SOURCE', dest='source', required=True, help='')
    parser_order.add_argument('--feed-address', metavar='FEED_ADDRESS', required=True, help='')
    parser_order.add_argument('--bet-type', metavar='BET_TYPE', choices=list(util.BET_TYPE_NAME.values()), required=True, help='')
    parser_order.add_argument('--deadline', metavar='DEADLINE', required=True, help='')
    parser_order.add_argument('--wager', metavar='WAGER_QUANTITY', required=True, help='')
    parser_order.add_argument('--counterwager', metavar='COUNTERWAGER_QUANTITY', required=True, help='')
    parser_order.add_argument('--target-value', metavar='target_value', help='over‐under (?) (bet)')
    parser_order.add_argument('--leverage', metavar='LEVERAGE', type=int, default=5040, help='leverage, as a fraction of 5040')
    parser_order.add_argument('--expiration', metavar='EXPIRATION', type=int, required=True, help='')

    parser_dividend = subparsers.add_parser('dividend', help='requires bitcoind')
    parser_dividend.add_argument('--from', metavar='SOURCE', dest='source', required=True, help='')
    parser_dividend.add_argument('--quantity-per-share', metavar='QUANTITY_PER_SHARE', required=True, help='in XCP')
    parser_dividend.add_argument('--share-asset', metavar='SHARE_ASSET', required=True, help='')

    parser_burn = subparsers.add_parser('burn', help='requires bitcoind')
    parser_burn.add_argument('--from', metavar='SOURCE', dest='source', required=True, help='')
    parser_burn.add_argument('--quantity', metavar='QUANTITY', required=True, help='quantity of BTC to be destroyed in miners’ fees')

    parser_watch = subparsers.add_parser('watch', help='')

    parser_history = subparsers.add_parser('history', help='')
    parser_history.add_argument('--address', metavar='ADDRESS', required=True, help='')

    args = parser.parse_args()


    # Configuration

    # Data directory
    if not args.data_dir:
        config.data_dir = appdirs.user_data_dir('Counterparty', 'counterpartyd')
    else:
        config.data_dir = args.data_dir
    if not os.path.isdir(config.data_dir): os.mkdir(config.data_dir)

    # Bitcoind RPC options.
    configfile = configparser.ConfigParser()
    configfile.read(config.data_dir + '/counterpartyd.config.ini')

    # testnet
    if args.testnet:
        config.TESTNET = args.testnet
    elif 'testnet' in configfile['Default']:
        config.TESTNET = configfile['Default'].getboolean('testnet')
    else:
        config.TESTNET = False

    # testcoin
    if args.testcoin:
        config.TESTCOIN = args.testcoin
    elif 'testcoin' in configfile['Default']:
        config.TESTCOIN = configfile['Default'].getboolean('testcoin')
    else:
        config.TESTCOIN = False

    # RPC user
    if args.rpc_user:
        config.rpc_user = args.rpc_user
    elif 'rpcuser' in configfile['Default']:
        config.rpc_user = configfile['Default']['rpcuser']
    else:
        config.rpc_user = 'bitcoinrpc'

    # RPC host
    if args.rpc_connect:
        config.rpc_connect = args.rpc_connect
    elif 'rpcconnect' in configfile['Default']:
        config.rpc_connect = configfile['Default']['rpcconnect']
    else:
        config.rpc_connect = 'localhost'

    # RPC port
    if args.rpc_port:
        config.rpc_port = args.rpc_port
    elif 'rpcport' in configfile['Default']:
        config.rpc_port = configfile['Default']['rpcport']
    else:
        if config.TESTNET:
            config.rpc_port = '18332'
        else:
            config.rpc_port = '8332'
            
    # RPC password
    if args.rpc_password:
        config.rpc_password = args.rpc_password
    elif 'rpcpassword' in configfile['Default']:
        config.rpc_password = configfile['Default']['rpcpassword']
    else:
        raise exceptions.ConfigurationError('RPC password not set. (Use configuration file or --rpc-password=PASSWORD)')

    config.RPC = 'http://' + config.rpc_user + ':' + config.rpc_password + '@' + config.rpc_connect + ':' + str(config.rpc_port)

    # Database
    if args.database_file:
        config.DATABASE = args.database_file
    else:
        config.DATABASE = config.data_dir + '/counterpartyd.' + str(config.DB_VERSION) + '.db'

    # For create()s.
    db = sqlite3.connect(config.DATABASE)
    db.row_factory = sqlite3.Row
    follow_cursor = db.cursor()

    # Log
    if args.log_file:
        config.LOG = args.log_file
    else:
        config.LOG = config.data_dir + '/counterpartyd.log'
    if config.LOG == '-':
        config.LOG = None   # Log to stdout.
    logging.basicConfig(filename=config.LOG, level=logging.INFO,
                        format='%(asctime)s %(message)s',
                        datefmt='%m-%d-%YT%I:%M:%S%z')
    requests_log = logging.getLogger("requests")
    requests_log.setLevel(logging.WARNING)

    # (more) Testnet
    if config.TESTNET:
        config.BLOCK_FIRST = 153560
        config.BURN_START = 153000
        config.BURN_END = 156000
    else:
        pass
        # TODO

    config.TESTCOIN = True
    if config.TESTCOIN:
        config.PREFIX = b'TEST'                # 4 bytes (possibly accidentally created)
    else:
        pass
        # TODO


    # Do something.
    if args.action == 'send':
        bitcoin.bitcoind_check()

        asset_id = util.get_asset_id(args.asset)
        quantity = util.devise(db, args.quantity, asset_id, 'input')

        unsigned_tx_hex = send.create(db, args.source, args.destination,
                                      round(quantity), asset_id)
        json_print(bitcoin.transmit(unsigned_tx_hex))

    elif args.action == 'order':
        bitcoin.bitcoind_check()

        give_id = util.get_asset_id(args.give_asset)
        get_id = util.get_asset_id(args.get_asset)

        # Fee argument is either fee_required or fee_provided, as necessary.
        fee = round(D(args.fee) * config.UNIT)
        if not give_id:
            fee_provided = fee
            assert fee_provided >= config.MIN_FEE
            fee_required = 0
        elif not get_id:
            fee_required = fee
            assert fee_required >= config.MIN_FEE
            fee_provided = config.MIN_FEE

        give_quantity = util.devise(db, args.give_quantity, give_id, 'input')
        get_quantity = util.devise(db, args.get_quantity, get_id, 'input')
        unsigned_tx_hex = order.create(db, args.source, give_id, round(give_quantity),
                                get_id, round(get_quantity),
                                args.expiration, fee_required, fee_provided)
        json_print(bitcoin.transmit(unsigned_tx_hex))

    elif args.action == 'btcpay':
        unsigned_tx_hex = btcpay.create(db, args.order_match_id)
        json_print(bitcoin.transmit(unsigned_tx_hex))

    elif args.action == 'issuance':
        bitcoin.bitcoind_check()

        quantity = util.devise(db, args.quantity, asset_id, 'input')
        unsigned_tx_hex = issuance.create(db, args.source, args.asset_id, round(quantity),
                                args.divisible)
        json_print(bitcoin.transmit(unsigned_tx_hex))

    elif args.action == 'broadcast':
        bitcoin.bitcoind_check()

        # Use a magic number to store the fee multplier as an integer.
        fee_multiplier = D(args.fee_multiplier) * D(1e8)
        if fee_multiplier > 4294967295:
            raise exceptions.OverflowError('Fee multiplier must be less than or equal to 42.94967295.')

        unsigned_tx_hex = broadcast.create(args.source, int(time.time()), args.value,
                                    round(fee_multiplier), args.text)
        json_print(bitcoin.transmit(unsigned_tx_hex))

    elif args.action == 'bet':
        bitcoin.bitcoind_check()

        deadline = datetime.timestamp(dateutil.parser.parse(args.deadline))

        unsigned_tx_hex = bet.create(args.source, args.feed_address,
                              util.BET_TYPE_ID[args.bet_type], round(deadline),
                              round(D(args.wager) * config.UNIT),
                              round(D(args.counterwager) * config.UNIT),
                              float(args.target_value), args.leverage,
                              args.expiration)
        json_print(bitcoin.transmit(unsigned_tx_hex))

    elif args.action == 'dividend':
        bitcoin.bitcoind_check()

        asset_id = util.get_asset_id(args.share_asset)
        quantity_per_share = D(args.quantity_per_share) * config.UNIT

        unsigned_tx_hex = dividend.create(db, args.source, round(quantity_per_share),
                                   asset_id)
        json_print(bitcoin.transmit(unsigned_tx_hex))

    elif args.action == 'burn':
        bitcoin.bitcoind_check()
        unsigned_tx_hex = burn.create(db, args.source, round(D(args.quantity) * config.UNIT))
        json_print(bitcoin.transmit(unsigned_tx_hex))

    elif args.action == 'watch':
        while True:
            watch()
           
    elif args.action == 'history':
        history(args.address)

    elif args.action == 'help':
        parser.print_help()

    else:
        bitcoin.bitcoind_check()
        blocks.follow()

# vim: tabstop=8 expandtab shiftwidth=4 softtabstop=4
