#! /usr/bin/env python3

import sys
import argparse
import json
import time
import decimal
D = decimal.Decimal
# decimal.getcontext().prec = 8

from lib import (config, util, exceptions, bitcoin, blocks, api)
from lib import (send, order, btcpayment, issuance, broadcast, bet)

json_print = lambda x: print(json.dumps(x, sort_keys=True, indent=4))

if __name__ == '__main__':

    # Parse command‐line arguments.
    parser = argparse.ArgumentParser(prog='counterparty', description='')
    parser.add_argument('--version', action='store_true', 
                        help='print version information')
    subparsers = parser.add_subparsers(dest='action', 
                                       help='the action to be taken')

    # TODO: Replace underscores with hyphen‐minuses in command‐line options?
    parser_send = subparsers.add_parser('send', help='requires bitcoind')
    parser_send.add_argument('--from', metavar='SOURCE', dest='source', type=str, required=True, help='')
    parser_send.add_argument('--to', metavar='DESTINATION', dest='destination', type=str, required=True, help='')
    parser_send.add_argument('amount', metavar='AMOUNT', type=D, help='')
    parser_send.add_argument('--asset', metavar='ASSET', dest='asset', type=str, required=True, help='')

    parser_order = subparsers.add_parser('order', help='requires bitcoind')
    parser_order.add_argument('--from', metavar='SOURCE', dest='source', type=str, required=True, help='')
    parser_order.add_argument('--get_amount', metavar='GET_AMOUNT', type=D, required=True, help='')
    parser_order.add_argument('--get_asset', metavar='GET_ASSET', type=str, required=True, help='')
    parser_order.add_argument('--give_amount', metavar='GIVE_AMOUNT', type=D, required=True, help='')
    parser_order.add_argument('--give_asset', metavar='GIVE_ASSET', type=str, required=True, help='')
    parser_order.add_argument('--expiration', metavar='EXPIRATION', type=int, required=True, help='')
    parser_order.add_argument('--fee', metavar='FEE', type=D, required=True, help='either the required fee, or the provided fee, as appropriate; in BTC, to be paid to miners')

    parser_btcpayment = subparsers.add_parser('btcpayment', help='requires bitcoind')
    parser_btcpayment.add_argument('deal_id', metavar='DEAL_ID', type=str, help='')

    parser_issue = subparsers.add_parser('issue', help='requires bitcoind')
    parser_issue.add_argument('--from', metavar='SOURCE', type=str, required=True, help='')
    parser_issue.add_argument('amount', metavar='AMOUNT', type=str, help='')
    parser_issue.add_argument('--asset_id', metavar='ASSET_ID', type=int, help='')

    parser_broadcast = subparsers.add_parser('broadcast', help='requires bitcoind')
    parser_broadcast.add_argument('--from', metavar='SOURCE', type=str, dest='source', required=True, help='')
    parser_broadcast.add_argument('--text', metavar='TEXT', type=str, required=True, help='')
    parser_broadcast.add_argument('--value', metavar='VALUE', type=float, default=0, help='numerical value of the broadcast')
    parser_broadcast.add_argument('--fee_multiplier', metavar='FEE_MULTIPLIER', type=D, help='how much of every bet on this feed should go to its operator; a fraction of 1 (i.e. .05 is 5%)')

    parser_order = subparsers.add_parser('bet', help='requires bitcoind')
    parser_order.add_argument('--from', metavar='SOURCE', dest='source', type=str, required=True, help='')
    parser_order.add_argument('--feed_address', metavar='FEED_ADDRESS', type=str, required=True, help='')
    parser_order.add_argument('--bet_type', metavar='BET_TYPE', type=int, required=True, help='')
    parser_order.add_argument('--time_start', metavar='TIME_START', type=int, required=True, help='')
    parser_order.add_argument('--time_end', metavar='TIME_END', type=int, required=True, help='')
    parser_order.add_argument('--wager_amount', metavar='WAGER_AMOUNT', type=D, required=True, help='')
    parser_order.add_argument('--counterwager_amount', metavar='COUNTERWAGER_AMOUNT', type=D, required=True, help='')
    parser_order.add_argument('--threshold_leverage', metavar='THRESHOLD_LEVERAGE', type=D, required=True, help='over‐under (?) (bet), leverage, as a fraction of 5040 (CFD)')
    parser_order.add_argument('--expiration', metavar='EXPIRATION', type=int, required=True, help='')

    parser_follow = subparsers.add_parser('follow', help='requires bitcoind')

    parser_history = subparsers.add_parser('history', help='')
    parser_history.add_argument('address', metavar='ADDRESS', type=str,
                                help='''get the history, balance of an
                                        address''')

    parser_orderbook = subparsers.add_parser('orderbook', help='')

    parser_pending = subparsers.add_parser('pending', help='')

    args = parser.parse_args()

    # TODO: Re‐name send.send, e.g., to send.create, etc.

    # Do something.
    if args.version:
        print('This is Version 0.01 of counterparty.')

    elif args.action == 'send':
        bitcoin.bitcoind_check()
        asset_id = util.get_asset_id(args.asset)
        # Find out whether the asset to be sent is divisible or not.
        if util.is_divisible(asset_id):
            amount = int(args.amount * config.UNIT)
        else:
            amount = int(args.amount)
        json_print(send.send(args.source, args.destination, amount, asset_id))

    elif args.action == 'order':

        if args.give_asset == args.get_asset:
            raise exceptions.UselessError('You can’t trade an asset for itself.')

        give_id = util.get_asset_id(args.give_asset)
        get_id = util.get_asset_id(args.get_asset)

        # Fee argument is either fee_required or fee_provided, as necessary.
        # TODO: Make this more comprehensive.
        if not give_id:
            fee_provided = int(args.fee * config.UNIT)
            assert fee_provided >= config.MIN_FEE
            fee_required = 0
        elif not get_id:
            fee_required = int(args.fee * config.UNIT)
            assert fee_required >= config.MIN_FEE
            fee_provided = config.MIN_FEE

        # If give_id is divisible, multiply get_amount by UNIT.
        if util.is_divisible(give_id):
            give_amount = int(args.give_amount * config.UNIT)
        else:
            give_amount = int(args.give_amount)

        # If get_id is divisible, multiply get_amount by UNIT.
        if util.is_divisible(get_id):
            get_amount = int(args.get_amount * config.UNIT)
        else:
            get_amount = int(args.get_amount)

        json_print(order.order(args.source, give_id, give_amount, get_id,
                               get_amount, args.expiration, fee_required,
                               fee_provided))

    elif args.action == 'btcpayment':
        json_print(btcpayment.btcpayment(args.deal_id))

    elif args.action == 'issue':
        bitcoin.bitcoind_check()
        if util.is_divisible(args.asset_id):
            divisible = True
            amount = int(args.amount * config.UNIT)
        else:
            divisible = False
            amount = int(args.amount)
        json_print(issuance.issuance(args.source, args.asset_id, amount, divisible))

    elif args.action == 'broadcast':
        bitcoin.bitcoind_check()
        fee_multiplier = int(args.fee_multiplier * D(1e8))   # Magic number: to store multplier as integer.
        json_print(broadcast.create(args.source, int(time.time()), args.value,
                                    fee_multiplier, args.text))

    elif args.action == 'bet':
        # TODO: Not real
        if args.bet_type == 'CFD':
            threshold_leverage = int(args.threshold_leverage)
        else:
            threshold_leverage = args.threshold_leverage

        json_print(bet.create(args.source, args.feed_address, args.bet_type,
                              args.time_start, args.time_end,
                              args.wager_amount * config.UNIT,
                              args.counterwager_amount * config.UNIT,
                              threshold_leverage, args.expiration))

    elif args.action == 'follow':
        bitcoin.bitcoind_check()
        blocks.follow()

    elif args.action == 'history':
        address = args.address
        json_print(api.history(address))

    elif args.action == 'orderbook':
        orderbook = api.orderbook()
        json_print(orderbook)
        '''
        width = 8
        fields = ['give_amount', 'give_id', 'get_amount', 'get_id', 'ask_price', 'expiration']
        for field in fields: print(field.ljust(width), end='\t')
        print()
        for order in orderbook:
            for field in fields:
                print(str(order[field]).ljust(width), end='\t')
        print()
        '''
            
    elif args.action == 'pending':
        json_print(api.pending())
            
    elif args.action == 'help':
        parser.print_help()

    else:
        parser.print_help()
        sys.exit(1)

# vim: tabstop=8 expandtab shiftwidth=4 softtabstop=4
