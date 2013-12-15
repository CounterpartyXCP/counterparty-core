#! /usr/bin/env python3

import sys
import argparse
import json
import decimal
D = decimal.Decimal
decimal.getcontext().prec = 8

from lib import (config, exceptions, bitcoin, blocks, api)
from lib import (send, order, btcpayment, issuance)

# Obsolete in Python 3.4.
ASSET_NAME = {0: 'BTC', 1: 'XCP'}
ASSET_ID = {'BTC': 0, 'XCP': 1}

json_print = lambda x: print(json.dumps(x, sort_keys=True, indent=4))

if __name__ == '__main__':

    # Parse command‐line arguments.
    parser = argparse.ArgumentParser(prog='counterparty', description='')
    parser.add_argument('--version', action='store_true', 
                        help='print version information')
    subparsers = parser.add_subparsers(dest='action', 
                                       help='the action to be taken')

    # TODO
    parser_send = subparsers.add_parser('send', help='requires bitcoind')
    parser_send.add_argument('source', metavar='SOURCE', type=str, help='')
    parser_send.add_argument('destination', metavar='DESTINATION', type=str, help='')
    parser_send.add_argument('amount', metavar='AMOUNT', type=str, help='')
    parser_send.add_argument('asset_name', metavar='ASSET_NAME', type=str, help='')

    # TODO
    parser_order = subparsers.add_parser('order', help='requires bitcoind')
    parser_order.add_argument('source', metavar='SOURCE', type=str, help='')
    parser_order.add_argument('get_amount', metavar='GET_AMOUNT', type=str, help='')
    parser_order.add_argument('get_name', metavar='GET_NAME', type=str, help='')
    parser_order.add_argument('give_amount', metavar='GIVE_AMOUNT', type=str, help='')
    parser_order.add_argument('give_name', metavar='GIVE_NAME', type=str, help='')
    parser_order.add_argument('price', metavar='PRICE', type=float, help='equal to GIVE/GET')
    parser_order.add_argument('expiration', metavar='EXPIRATION', type=int, help='')
    parser_order.add_argument('fee', metavar='FEE_REQUIRED or FEE_PROVIDED, as appropriate', type=float, help='')

    parser_btcpayment = subparsers.add_parser('btcpayment', help='requires bitcoind')
    parser_btcpayment.add_argument('deal_id', metavar='DEAL_ID', type=str, help='')

    parser_issuee = subparsers.add_parser('issue', help='requires bitcoind')
    parser_issuee.add_argument('source', metavar='SOURCE', type=str, help='')
    parser_issuee.add_argument('amount', metavar='AMOUNT', type=str, help='')
    parser_issuee.add_argument('asset_id', metavar='ASSET_ID', type=int, help='')

    parser_follow = subparsers.add_parser('follow', help='requires bitcoind')

    parser_history = subparsers.add_parser('history', help='')
    parser_history.add_argument('address', metavar='ADDRESS', type=str,
                                help='''get the history, balance of an
                                        address''')

    parser_orderbook = subparsers.add_parser('orderbook', help='')

    parser_pending = subparsers.add_parser('pending', help='')

    args = parser.parse_args()


    # Do something.
    if args.version:
        print('This is Version 0.01 of counterparty.')

    elif args.action == 'send':
        bitcoin.bitcoind_check()
        try:    # TEMP
            asset_id = ASSET_ID[args.asset_name]
        except Exception:
            asset_id = int(args.asset_name)

        if '.' in args.amount: amount = int(float(args.amount) * config.UNIT)
        else: amount = int(args.amount)

        json_print(send.send(args.source, args.destination, amount,
                   asset_id))

    elif args.action == 'order':
        source = args.source
        give_amount = int(D(args.give_amount) * config.UNIT)
        get_amount = int(D(args.get_amount) * config.UNIT)
        give_name = args.give_name
        get_name = args.get_name
        expiration = args.expiration
        fee = int(D(args.fee) * config.UNIT)
        price = args.price

        assert give_name != get_name            # TODO
        assert price == give_amount/get_amount  # TODO

        try:    # TEMP
            give_id = ASSET_ID[args.give_name]
        except Exception:
            give_id = int(args.give_name)
        try:    # TEMP
            get_id = ASSET_ID[args.get_name]
        except Exception:
            get_id = int(args.get_name)

        # fee argument is either fee_required or fee_provided, as necessary.
        if not give_id:
            fee_provided = fee
            assert fee_provided >= config.MIN_FEE
            fee_required = 0
        elif not get_id:
            fee_required = fee
            assert fee_required >= config.MIN_FEE
            fee_provided = config.MIN_FEE

        if '.' in args.give_amount:
            give_divisible = True
            give_amount = int(float(args.give_amount) * config.UNIT)
        else:
            give_divisible = False
            give_amount = int(args.give_amount)
        if '.' in args.get_amount:
            get_divisible = True
            get_amount = int(float(args.get_amount) * config.UNIT)
        else:
            get_divisible = False
            get_amount = int(args.get_amount)

        # The order of the order is reversed when it is written as a ‘buy’.
        print('Order:', source, 'wants to buy', get_amount, get_name,
              'for', give_amount, give_name, 'in', expiration, 'blocks')   # TODO (and fee_required, fee_provided)

        json_print(order.order(source, give_id, give_amount,
                    get_id, get_amount, expiration, fee_required, fee_provided))

    elif args.action == 'btcpayment':
        json_print(btcpayment.btcpayment(args.deal_id))

    elif args.action == 'issue':
        bitcoin.bitcoind_check()
        if '.' in args.amount:
            divisible = True
            amount = int(float(args.amount) * config.UNIT)
        else:
            divisible = False
            amount = int(args.amount)
        json_print(issuance.issuance(args.source, args.asset_id, amount, divisible))

    elif args.action == 'follow':
        bitcoin.bitcoind_check()
        blocks.follow()

    elif args.action == 'history':
        address = args.address
        json_print(api.history(address))

    elif args.action == 'orderbook':
        json_print(api.orderbook())
            
    elif args.action == 'pending':
        json_print(api.pending())
            
    elif args.action == 'help':
        parser.print_help()

    else:
        parser.print_help()
        sys.exit(1)

# vim: tabstop=8 expandtab shiftwidth=4 softtabstop=4
