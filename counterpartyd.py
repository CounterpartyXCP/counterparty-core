#! /usr/bin/env python3

import sys
import os
import argparse
import json
import time
import sqlite3
import colorama
colorama.init()
import decimal
D = decimal.Decimal
from prettytable import PrettyTable
import logging
import appdirs

from lib import (config, util, exceptions, bitcoin, blocks, api)
from lib import (send, order, btcpay, issue, broadcast, bet, dividend, burn)

json_print = lambda x: print(json.dumps(x, sort_keys=True, indent=4))


def format_order (cursor, order):
    price = D(order['get_amount']) / D(order['give_amount'])

    give_remaining = D(order['give_remaining'])
    get_remaining = give_remaining * price

    cursor, issuance = util.get_issuance(cursor, order['give_id'])
    if issuance['divisible']: give_remaining /= config.UNIT
    cursor, issuance = util.get_issuance(cursor, order['give_id'])
    if issuance['divisible']: get_remaining /= config.UNIT
    give_name = util.get_asset_name(order['give_id'])
    get_name = util.get_asset_name(order['get_id'])
    give = str(give_remaining) + ' ' + give_name
    get = str(round(get_remaining, 8)) + ' ' + get_name

    price_string = str(price.quantize(config.FOUR).normalize()) + ' ' + get_name + '/' + give_name

    if order['fee_required']:
        fee = str(order['fee_required'] / config.UNIT) + ' BTC (required)'
    else:
        fee = str(order['fee_provided'] / config.UNIT) + ' BTC (provided)'

    return cursor, [give, get, price_string, fee, util.get_time_left(order), util.short(order['tx_hash'])]

def format_bet (cursor, bet):
    odds = D(bet['counterwager_amount']) / D(bet['wager_amount'])

    give_remaining = D(bet['wager_remaining'])
    get_remaining = give_remaining * odds

    if bet['threshold']: threshold = None
    else: threshold = bet['threshold'] / 5040
    if bet['leverage']: leverage = None
    else: leverage = bet['leverage'] / 5040

    return cursor, [bet['feed_address'], threshold, leverage, str(bet['wager_amount'] / config.UNIT) + ' XCP', str(bet['counterwager_amount'] / config.UNIT) + ' XCP', odds.quantize(config.FOUR).normalize(), util.get_time_left(bet), util.short(bet['tx_hash'])]

def format_deal (cursor, deal):
    deal_id = deal['tx0_hash'] + deal['tx1_hash']
    cursor, deal_time_left = util.get_deal_time_left(cursor, deal)
    return cursor, [deal_id, deal_time_left]


if __name__ == '__main__':
    data_dir_default = appdirs.user_data_dir('Counterparty', 'Counterparty')

    # Parse command‐line arguments.
    parser = argparse.ArgumentParser(prog='counterparty', description='')
    parser.add_argument('--version', action='store_true', 
                        help='print version information')
    parser.add_argument('--rpc-connect', type=str, default='localhost', help='')
    parser.add_argument('--rpc-port', type=int, default=18332, help='')    # testnet
    parser.add_argument('--rpc-user', type=str, default='bitcoinrpc', help='')
    parser.add_argument('--rpc-password', type=str, required=True, help='')
    parser.add_argument('--data-dir', type=str, default=data_dir_default, help='')
    parser.add_argument('--database-file', type=str, help='')
    parser.add_argument('--log-file', type=str, help='')

    subparsers = parser.add_subparsers(dest='action', 
                                       help='the action to be taken')

    # TODO: Conversion to Decimals is fragile (and the error message unclear).
    parser_send = subparsers.add_parser('send', help='requires bitcoind')
    parser_send.add_argument('--from', metavar='SOURCE', dest='source', type=str, required=True, help='')
    parser_send.add_argument('--to', metavar='DESTINATION', dest='destination', type=str, required=True, help='')
    parser_send.add_argument('--quantity', metavar='QUANTITY', required=True, type=D, help='')
    parser_send.add_argument('--asset', metavar='ASSET', dest='asset', type=str, required=True, help='')

    parser_order = subparsers.add_parser('order', help='requires bitcoind')
    parser_order.add_argument('--from', metavar='SOURCE', dest='source', type=str, required=True, help='')
    parser_order.add_argument('--get-quantity', metavar='GET_QUANTITY', type=D, required=True, help='')
    parser_order.add_argument('--get-asset', metavar='GET_ASSET', type=str, required=True, help='')
    parser_order.add_argument('--give-quantity', metavar='GIVE_QUANTITY', type=D, required=True, help='')
    parser_order.add_argument('--give-asset', metavar='GIVE_ASSET', type=str, required=True, help='')
    parser_order.add_argument('--expiration', metavar='EXPIRATION', type=int, required=True, help='')
    parser_order.add_argument('--fee', metavar='FEE', type=D, required=True, help='either the required fee, or the provided fee, as appropriate; in BTC, to be paid to miners')

    parser_btcpay= subparsers.add_parser('btcpay', help='requires bitcoind')
    parser_btcpay.add_argument('--deal-id', metavar='DEAL_ID', type=str, required=True, help='')

    parser_issue = subparsers.add_parser('issue', help='requires bitcoind')
    parser_issue.add_argument('--from', metavar='SOURCE', type=str, dest='source', required=True, help='')
    parser_issue.add_argument('--quantity', metavar='QUANTITY', type=D, required=True, help='')
    parser_issue.add_argument('--asset-id', metavar='ASSET_ID', type=int, required=True, help='')
    parser_issue.add_argument('--divisible', metavar='DIVISIBLE', type=bool, required=True, help='whether or not the asset is divisible (must agree with previous issuances, if this is a re‐issuance)')

    parser_broadcast = subparsers.add_parser('broadcast', help='requires bitcoind')
    parser_broadcast.add_argument('--from', metavar='SOURCE', type=str, dest='source', required=True, help='')
    parser_broadcast.add_argument('--text', metavar='TEXT', type=str, required=True, help='')
    parser_broadcast.add_argument('--value', metavar='VALUE', type=float, default=0, help='numerical value of the broadcast')
    parser_broadcast.add_argument('--fee-multiplier', metavar='FEE_MULTIPLIER', type=D, required=True, help='how much of every bet on this feed should go to its operator; a fraction of 1, (i.e. .05 is five percent)')

    parser_order = subparsers.add_parser('bet', help='requires bitcoind')
    parser_order.add_argument('--from', metavar='SOURCE', dest='source', type=str, required=True, help='')
    parser_order.add_argument('--feed-address', metavar='FEED_ADDRESS', type=str, required=True, help='')
    parser_order.add_argument('--bet-type', metavar='BET_TYPE', type=str, choices=list(util.ASSET_NAME.keys()), required=True, help='')
    parser_order.add_argument('--deadline', metavar='DEADLINE', type=int, required=True, help='')
    parser_order.add_argument('--wager-quantity', metavar='WAGER_QUANTITY', type=D, required=True, help='')
    parser_order.add_argument('--counterwager-quantity', metavar='COUNTERWAGER_QUANTITY', type=D, required=True, help='')
    parser_order.add_argument('--threshold', metavar='THRESHOLD', type=D, help='over‐under (?) (bet)')
    parser_order.add_argument('--leverage', metavar='LEVERAGE', type=D, default=5040, help='leverage, as a fraction of 5040')
    parser_order.add_argument('--expiration', metavar='EXPIRATION', type=int, required=True, help='')

    parser_dividend = subparsers.add_parser('dividend', help='requires bitcoind')
    parser_dividend.add_argument('--from', metavar='SOURCE', dest='source', type=str, required=True, help='')
    parser_dividend.add_argument('--quantity-per-share', metavar='QUANTITY_PER_SHARE', type=D, required=True, help='in XCP')
    parser_dividend.add_argument('--share-asset', metavar='SHARE_ASSET', type=str, required=True, help='')

    parser_burn = subparsers.add_parser('burn', help='requires bitcoind')
    parser_burn.add_argument('--from', metavar='SOURCE', dest='source', type=str, required=True, help='')
    parser_burn.add_argument('--quantity', metavar='QUANTITY', type=D, required=True, help='quantity of BTC to be destroyed in miners’ fees')

    parser_watch = subparsers.add_parser('watch', help='open orders and pending BTC payments')

    args = parser.parse_args()


    # Configuration
    config.RPC = 'http://' + args.rpc_user + ':' + args.rpc_password + '@' + args.rpc_connect + ':' + str(args.rpc_port)

    if not args.data_dir: config.data_dir = data_dir_default
    else: config.data_dir = args.data_dir
    if not os.path.isdir(config.data_dir): os.mkdir(config.data_dir)

    if not args.database_file: config.DATABASE = data_dir_default + '/counterparty.' + str(config.DB_VERSION) + '.db'
    else: config.DATABASE = args.database_file

    if not args.log_file: config.LOG = config.data_dir + '/counterparty.log'

    logging.basicConfig(filename=config.LOG, level=logging.INFO, format='%(asctime)s %(message)s', datefmt='%m-%d-%YT%I:%M:%S%z')
    requests_log = logging.getLogger("requests")
    requests_log.setLevel(logging.WARNING)


    # Do something.
    if args.version:
        print('This is Version 0.01 of counterparty.')

    elif args.action == 'send':
        bitcoin.bitcoind_check()
        asset_id = util.get_asset_id(args.asset)

        db = sqlite3.connect(config.DATABASE)
        db.row_factory = sqlite3.Row
        cursor = db.cursor()
        cursor, issuance = util.get_issuance(cursor, asset_id)
        if issuance['divisible']:
            quantity = int(args.quantity * config.UNIT)
        else:
            quantity = int(args.quantity)
        cursor.close()

        json_print(send.create(args.source, args.destination, quantity, asset_id))

    elif args.action == 'order':
        bitcoin.bitcoind_check()
        give_id = util.get_asset_id(args.give_asset)
        get_id = util.get_asset_id(args.get_asset)

        # Fee argument is either fee_required or fee_provided, as necessary.
        fee = round(args.fee * config.UNIT)
        if not give_id:
            fee_provided = fee
            assert fee_provided >= config.MIN_FEE
            fee_required = 0
        elif not get_id:
            fee_required = fee
            assert fee_required >= config.MIN_FEE
            fee_provided = config.MIN_FEE

        db = sqlite3.connect(config.DATABASE)
        db.row_factory = sqlite3.Row
        cursor = db.cursor()
        cursor, issuance = util.get_issuance(cursor, give_id)
        if issuance['divisible']: give_quantity = int(args.give_quantity * config.UNIT)
        else: give_quantity = int(args.give_quantity)
        cursor, issuance = util.get_issuance(cursor, get_id)
        if issuance['divisible']: get_quantity = int(args.get_quantity * config.UNIT)
        else: get_quantity = int(args.get_quantity)
        cursor.close()

        json_print(order.create(args.source, give_id, give_quantity, get_id,
                               get_quantity, args.expiration, fee_required,
                               fee_provided))

    elif args.action == 'btcpay':
        json_print(btcpay.create(args.deal_id))

    elif args.action == 'issue':
        bitcoin.bitcoind_check()
        if args.divisible: quantity = int(args.quantity * config.UNIT)
        else: quantity = int(args.quantity)
        json_print(issue.create(args.source, args.asset_id, quantity, args.divisible))

    elif args.action == 'broadcast':
        bitcoin.bitcoind_check()
        fee_multiplier = int(args.fee_multiplier * D(1e8))   # Magic number: to store multplier as integer.
        json_print(broadcast.create(args.source, int(time.time()), args.value,
                                    fee_multiplier, args.text))

    elif args.action == 'bet':
        json_print(bet.create(args.source, args.feed_address,
                              util.BET_TYPE_ID[args.bet_type], args.deadline,
                              args.wager_quantity * config.UNIT,
                              args.counterwager_quantity * config.UNIT,
                              args.threshold, args.leverage, args.expiration))

    elif args.action == 'dividend':
        bitcoin.bitcoind_check()
        asset_id = util.get_asset_id(args.share_asset)
        json_print(dividend.create(args.source, int(args.quantity_per_share * config.UNIT), asset_id))

    elif args.action == 'burn':
        bitcoin.bitcoind_check()
        json_print(burn.create(args.source, args.quantity * config.UNIT))

    elif args.action == 'watch':
        db = sqlite3.connect(config.DATABASE)
        db.row_factory = sqlite3.Row
        cursor = db.cursor()

        while True:
            os.system('cls' if os.name=='nt' else 'clear')

            # Open orders.
            cursor, orders = util.get_orders(cursor, show_invalid=False, show_expired=False, show_empty=False)
            orders_table = PrettyTable(['Give', 'Get', 'Price', 'Fee', 'Time Left', 'Tx Hash'])
            for order in orders:
                cursor, order = format_order(cursor, order)
                orders_table.add_row(order)
            print(colorama.Fore.WHITE + colorama.Style.BRIGHT + 'Open Orders' + colorama.Style.RESET_ALL)
            print(colorama.Fore.BLUE + str(orders_table) + colorama.Style.RESET_ALL)

            print('\n')

            # Open bets.
            cursor, bets = util.get_bets(cursor, show_invalid=False, show_expired=False, show_empty=False)
            bets_table = PrettyTable(['Feed address', 'Threshold', 'Leverage', 'Wager', 'Counterwager', 'Odds', 'Time Left', 'Tx Hash'])
            for bet in bets:
                cursor, bet = format_bet(cursor, bet)
                bets_table.add_row(bet)
            print(colorama.Fore.WHITE + colorama.Style.BRIGHT + 'Open Bets' + colorama.Style.RESET_ALL)
            print(colorama.Fore.GREEN + str(bets_table) + colorama.Style.RESET_ALL)


            print('\n')

            # Pending BTC payments of mine.
            cursor, btcpays = util.get_btcpays(cursor, show_not_mine=False, show_expired=False)
            btcpays_table = PrettyTable(['Deal ID', 'Time Left'])
            for deal in btcpays:
                cursor, deal = format_deal(cursor, deal)
                btcpays_table.add_row(deal)

            # Print out pending_table.
            print(colorama.Fore.WHITE + colorama.Style.BRIGHT + 'Pending Bitcoin Payments' + colorama.Style.RESET_ALL)
            print(colorama.Fore.CYAN + str(btcpays_table) + colorama.Style.RESET_ALL)

            time.sleep(30)
            
    elif args.action == 'help':
        parser.print_help()

    else:
        bitcoin.bitcoind_check()
        blocks.follow()

# vim: tabstop=8 expandtab shiftwidth=4 softtabstop=4
