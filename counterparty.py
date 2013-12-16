#! /usr/bin/env python3

import sys
import argparse
import json
import time
import decimal
D = decimal.Decimal
decimal.getcontext().prec = 8

from lib import (config, util, exceptions, bitcoin, blocks, api)
from lib import (send, order, btcpayment, issuance, broadcast)

json_print = lambda x: print(json.dumps(x, sort_keys=True, indent=4))

if __name__ == '__main__':

    # Parse command‐line arguments.
    parser = argparse.ArgumentParser(prog='counterparty', description='')
    parser.add_argument('--version', action='store_true', 
                        help='print version information')
    subparsers = parser.add_subparsers(dest='action', 
                                       help='the action to be taken')

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
    parser_order.add_argument('--fee', metavar='FEE', type=D, required=True, help='either the required fee, or the provided fee, as appropriate')

    parser_btcpayment = subparsers.add_parser('btcpayment', help='requires bitcoind')
    parser_btcpayment.add_argument('deal_id', metavar='DEAL_ID', type=str, help='')

    parser_issue = subparsers.add_parser('issue', help='requires bitcoind')
    parser_issue.add_argument('--from', metavar='SOURCE', type=str, required=True, help='')
    parser_issue.add_argument('amount', metavar='AMOUNT', type=str, help='')
    parser_issue.add_argument('--asset_id', metavar='ASSET_ID', type=int, help='')

    parser_broadcast = subparsers.add_parser('broadcast', help='requires bitcoind')
    parser_broadcast.add_argument('--from', metavar='SOURCE', type=str, dest='source', required=True, help='')
    parser_broadcast.add_argument('--text', metavar='TEXT', type=str, required=True, help='')
    parser_broadcast.add_argument('--price_id', metavar='PRICE_ASSET', type=str, help='')
    parser_broadcast.add_argument('--price_amount', metavar='PRICE_AMOUNT', type=D, default=0, help='') # TODO: should this be D()?
    parser_broadcast.add_argument('--fee_required', metavar='FEE_REQUIRED', type=D, default=0, help='in XCP')

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
        # Get asset_id from what may have been given as an asset name.
        try:
            asset_id = config.ASSET_ID[args.asset]
        except KeyError:
            asset_id = int(args.asset)
        # Find out whether the asset to be sent is divisible or not.
        if util.is_divisible(asset_id):
            amount = int(args.amount * config.UNIT)
        else:
            amount = int(args.amount)
        json_print(send.send(args.source, args.destination, amount, asset_id))

    elif args.action == 'order':

        if args.give_asset == args.get_asset:
            raise exceptions.UselessError('You can’t trade an asset for itself.')

        # Get Asset IDs from Asset Names.
        try:    # TEMP
            give_id = config.ASSET_ID[args.give_asset]
        except Exception:
            give_id = int(args.give_asset)
        try:    # TEMP
            get_id = config.ASSET_ID[args.get_asset]
        except Exception:
            get_id = int(args.get_asset)

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
        if args.price_id:   # Ugly
            if util.is_divisible(args.price_id):
                price_amount = int(args.price_amount * config.UNIT)
            else:
                price_amount = int(args.price_amount)
            price_id = int(args.price_id)
        else:
            price_id = 0
            price_amount = int(args.price_amount * config.UNIT)
        json_print(broadcast.create(args.source, int(time.time()), 
                   price_id, price_amount, args.fee_required * config.UNIT, args.text))

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
