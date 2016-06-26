#! /usr/bin/env python3

import os
import sys
import argparse
import logging
import getpass
from decimal import Decimal as D

from counterpartylib.lib import log
logger = logging.getLogger(__name__)

from counterpartylib.lib import config, script
from counterpartylib.lib.util import make_id, BET_TYPE_NAME
from counterpartylib.lib.log import isodt
from counterpartylib.lib.exceptions import TransactionError
from counterpartycli.util import add_config_arguments
from counterpartycli.setup import generate_config_files
from counterpartycli import APP_VERSION, util, messages, wallet, console, clientapi

APP_NAME = 'counterparty-client'

CONFIG_ARGS = [
    [('-v', '--verbose'), {'dest': 'verbose', 'action': 'store_true', 'help': 'sets log level to DEBUG instead of WARNING'}],
    [('--testnet',), {'action': 'store_true', 'default': False, 'help': 'use {} testnet addresses and block numbers'.format(config.BTC_NAME)}],    
    [('--testcoin',), {'action': 'store_true', 'default': False, 'help': 'use the test {} network on every blockchain'.format(config.XCP_NAME)}],
    
    [('--counterparty-rpc-connect',), {'default': 'localhost', 'help': 'the hostname or IP of the Counterparty JSON-RPC server'}],
    [('--counterparty-rpc-port',), {'type': int, 'help': 'the port of the Counterparty JSON-RPC server'}],
    [('--counterparty-rpc-user',), {'default': 'rpc', 'help': 'the username for the Counterparty JSON-RPC server'}],
    [('--counterparty-rpc-password',), {'help': 'the password for the Counterparty JSON-RPC server'}],
    [('--counterparty-rpc-ssl',), {'default': False, 'action': 'store_true', 'help': 'use SSL to connect to the Counterparty server (default: false)'}],
    [('--counterparty-rpc-ssl-verify',), {'default': False, 'action': 'store_true', 'help': 'verify SSL certificate of the Counterparty server; disallow use of self‐signed certificates (default: false)'}],

    [('--wallet-name',), {'default': 'bitcoincore', 'help': 'the wallet name to connect to'}],
    [('--wallet-connect',), {'default': 'localhost', 'help': 'the hostname or IP of the wallet server'}],
    [('--wallet-port',), {'type': int, 'help': 'the wallet port to connect to'}],
    [('--wallet-user',), {'default': 'bitcoinrpc', 'help': 'the username used to communicate with wallet'}],
    [('--wallet-password',), {'help': 'the password used to communicate with wallet'}],
    [('--wallet-ssl',), {'action': 'store_true', 'default': False, 'help': 'use SSL to connect to wallet (default: false)'}],
    [('--wallet-ssl-verify',), {'action': 'store_true', 'default': False, 'help': 'verify SSL certificate of wallet; disallow use of self‐signed certificates (default: false)'}],

    [('--json-output',), {'action': 'store_true', 'default': False, 'help': 'display result in json format'}],
    [('--unconfirmed',), {'action': 'store_true', 'default': False, 'help': 'allow the spending of unconfirmed transaction outputs'}],
    [('--encoding',), {'default': 'auto', 'type': str, 'help': 'data encoding method'}],
    [('--fee-per-kb',), {'type': D, 'default': D(config.DEFAULT_FEE_PER_KB / config.UNIT), 'help': 'fee per kilobyte, in {}'.format(config.BTC)}],
    [('--regular-dust-size',), {'type': D, 'default': D(config.DEFAULT_REGULAR_DUST_SIZE / config.UNIT), 'help': 'value for dust Pay‐to‐Pubkey‐Hash outputs, in {}'.format(config.BTC)}],
    [('--multisig-dust-size',), {'type': D, 'default': D(config.DEFAULT_MULTISIG_DUST_SIZE / config.UNIT), 'help': 'for dust OP_CHECKMULTISIG outputs, in {}'.format(config.BTC)}],
    [('--op-return-value',), {'type': D, 'default': D(config.DEFAULT_OP_RETURN_VALUE / config.UNIT), 'help': 'value for OP_RETURN outputs, in {}'.format(config.BTC)}],
    [('--unsigned',), {'action': 'store_true', 'default': False, 'help': 'print out unsigned hex of transaction; do not sign or broadcast'}],
    [('--disable-utxo-locks',), {'action': 'store_true', 'default': False, 'help': 'disable locking of UTXOs being spend'}],
    [('--dust-return-pubkey',), {'help': 'pubkey for dust outputs (required for P2SH)'}],
    [('--requests-timeout',), {'type': int, 'default': clientapi.DEFAULT_REQUESTS_TIMEOUT, 'help': 'timeout value (in seconds) used for all HTTP requests (default: 5)'}]
]

def main():
    if os.name == 'nt':
        from counterpartylib.lib import util_windows
        #patch up cmd.exe's "challenged" (i.e. broken/non-existent) UTF-8 logging
        util_windows.fix_win32_unicode()

    # Post installation tasks
    generate_config_files()

    # Parse command-line arguments.
    parser = argparse.ArgumentParser(prog=APP_NAME, description='Counterparty CLI for counterparty-server', add_help=False)
    parser.add_argument('-h', '--help', dest='help', action='store_true', help='show this help message and exit')
    parser.add_argument('-V', '--version', action='version', version="{} v{}; {} v{}".format(APP_NAME, APP_VERSION, 'counterparty-lib', config.VERSION_STRING))
    parser.add_argument('--config-file', help='the location of the configuration file')

    parser = add_config_arguments(parser, CONFIG_ARGS, 'client.conf')

    subparsers = parser.add_subparsers(dest='action', help='the action to be taken')

    parser_send = subparsers.add_parser('send', help='create and broadcast a *send* message')
    parser_send.add_argument('--source', required=True, help='the source address')
    parser_send.add_argument('--destination', required=True, help='the destination address')
    parser_send.add_argument('--quantity', required=True, help='the quantity of ASSET to send')
    parser_send.add_argument('--asset', required=True, help='the ASSET of which you would like to send QUANTITY')
    parser_send.add_argument('--fee', help='the exact {} fee to be paid to miners'.format(config.BTC))

    parser_order = subparsers.add_parser('order', help='create and broadcast an *order* message')
    parser_order.add_argument('--source', required=True, help='the source address')
    parser_order.add_argument('--get-quantity', required=True, help='the quantity of GET_ASSET that you would like to receive')
    parser_order.add_argument('--get-asset', required=True, help='the asset that you would like to buy')
    parser_order.add_argument('--give-quantity', required=True, help='the quantity of GIVE_ASSET that you are willing to give')
    parser_order.add_argument('--give-asset', required=True, help='the asset that you would like to sell')
    parser_order.add_argument('--expiration', type=int, required=True, help='the number of blocks for which the order should be valid')
    parser_order.add_argument('--fee-fraction-required', default=config.DEFAULT_FEE_FRACTION_REQUIRED, help='the miners’ fee required for an order to match this one, as a fraction of the {} to be bought'.format(config.BTC))
    parser_order_fees = parser_order.add_mutually_exclusive_group()
    parser_order_fees.add_argument('--fee-fraction-provided', default=config.DEFAULT_FEE_FRACTION_PROVIDED, help='the miners’ fee provided, as a fraction of the {} to be sold'.format(config.BTC))
    parser_order_fees.add_argument('--fee', help='the exact {} fee to be paid to miners'.format(config.BTC))

    parser_btcpay = subparsers.add_parser('{}pay'.format(config.BTC).lower(), help='create and broadcast a *{}pay* message, to settle an Order Match for which you owe {}'.format(config.BTC, config.BTC))
    parser_btcpay.add_argument('--source', required=True, help='the source address')
    parser_btcpay.add_argument('--order-match-id', required=True, help='the concatenation of the hashes of the two transactions which compose the order match')
    parser_btcpay.add_argument('--fee', help='the exact {} fee to be paid to miners'.format(config.BTC))

    parser_issuance = subparsers.add_parser('issuance', help='issue a new asset, issue more of an existing asset or transfer the ownership of an asset')
    parser_issuance.add_argument('--source', required=True, help='the source address')
    parser_issuance.add_argument('--transfer-destination', help='for transfer of ownership of asset issuance rights')
    parser_issuance.add_argument('--quantity', default=0, help='the quantity of ASSET to be issued')
    parser_issuance.add_argument('--asset', required=True, help='the name of the asset to be issued (if it’s available)')
    parser_issuance.add_argument('--divisible', action='store_true', help='whether or not the asset is divisible (must agree with previous issuances)')
    parser_issuance.add_argument('--description', type=str, required=True, help='a description of the asset (set to ‘LOCK’ to lock against further issuances with non‐zero quantitys)')
    parser_issuance.add_argument('--fee', help='the exact {} fee to be paid to miners'.format(config.BTC))

    parser_broadcast = subparsers.add_parser('broadcast', help='broadcast textual and numerical information to the network')
    parser_broadcast.add_argument('--source', required=True, help='the source address')
    parser_broadcast.add_argument('--text', type=str, required=True, help='the textual part of the broadcast (set to ‘LOCK’ to lock feed)')
    parser_broadcast.add_argument('--value', type=float, default=-1, help='numerical value of the broadcast')
    parser_broadcast.add_argument('--fee-fraction', default=0, help='the fraction of bets on this feed that go to its operator')
    parser_broadcast.add_argument('--fee', help='the exact {} fee to be paid to miners'.format(config.BTC))

    parser_bet = subparsers.add_parser('bet', help='offer to make a bet on the value of a feed')
    parser_bet.add_argument('--source', required=True, help='the source address')
    parser_bet.add_argument('--feed-address', required=True, help='the address which publishes the feed to bet on')
    parser_bet.add_argument('--bet-type', choices=list(BET_TYPE_NAME.values()), required=True, help='choices: {}'.format(list(BET_TYPE_NAME.values())))
    parser_bet.add_argument('--deadline', required=True, help='the date and time at which the bet should be decided/settled')
    parser_bet.add_argument('--wager', required=True, help='the quantity of XCP to wager')
    parser_bet.add_argument('--counterwager', required=True, help='the minimum quantity of XCP to be wagered by the user to bet against you, if he were to accept the whole thing')
    parser_bet.add_argument('--target-value', default=0.0, help='target value for Equal/NotEqual bet')
    parser_bet.add_argument('--leverage', type=int, default=5040, help='leverage, as a fraction of 5040')
    parser_bet.add_argument('--expiration', type=int, required=True, help='the number of blocks for which the bet should be valid')
    parser_bet.add_argument('--fee', help='the exact {} fee to be paid to miners'.format(config.BTC))

    parser_dividend = subparsers.add_parser('dividend', help='pay dividends to the holders of an asset (in proportion to their stake in it)')
    parser_dividend.add_argument('--source', required=True, help='the source address')
    parser_dividend.add_argument('--quantity-per-unit', required=True, help='the quantity of XCP to be paid per whole unit held of ASSET')
    parser_dividend.add_argument('--asset', required=True, help='the asset to which pay dividends')
    parser_dividend.add_argument('--dividend-asset', required=True, help='asset in which to pay the dividends')
    parser_dividend.add_argument('--fee', help='the exact {} fee to be paid to miners'.format(config.BTC))

    parser_burn = subparsers.add_parser('burn', help='destroy {} to earn XCP, during an initial period of time')
    parser_burn.add_argument('--source', required=True, help='the source address')
    parser_burn.add_argument('--quantity', required=True, help='quantity of {} to be burned'.format(config.BTC))
    parser_burn.add_argument('--fee', help='the exact {} fee to be paid to miners'.format(config.BTC))

    parser_cancel = subparsers.add_parser('cancel', help='cancel an open order or bet you created')
    parser_cancel.add_argument('--source', required=True, help='the source address')
    parser_cancel.add_argument('--offer-hash', required=True, help='the transaction hash of the order or bet')
    parser_cancel.add_argument('--fee', help='the exact {} fee to be paid to miners'.format(config.BTC))

    parser_publish = subparsers.add_parser('publish', help='publish contract code in the blockchain')
    parser_publish.add_argument('--source', required=True, help='the source address')
    parser_publish.add_argument('--gasprice', required=True, type=int, help='the price of gas')
    parser_publish.add_argument('--startgas', required=True, type=int, help='the maximum quantity of {} to be used to pay for the execution (satoshis)'.format(config.XCP))
    parser_publish.add_argument('--endowment', required=True, type=int, help='quantity of {} to be transfered to the contract (satoshis)'.format(config.XCP))
    parser_publish.add_argument('--code-hex', required=True, type=str, help='the hex‐encoded contract (returned by `serpent compile`)')
    parser_publish.add_argument('--fee', help='the exact {} fee to be paid to miners'.format(config.BTC))

    parser_execute = subparsers.add_parser('execute', help='execute contract code in the blockchain')
    parser_execute.add_argument('--source', required=True, help='the source address')
    parser_execute.add_argument('--contract-id', required=True, help='the contract ID of the contract to be executed')
    parser_execute.add_argument('--gasprice', required=True, type=int, help='the price of gas')
    parser_execute.add_argument('--startgas', required=True, type=int, help='the maximum quantity of {} to be used to pay for the execution (satoshis)'.format(config.XCP))
    parser_execute.add_argument('--value', required=True, type=int, help='quantity of {} to be transfered to the contract (satoshis)'.format(config.XCP))
    parser_execute.add_argument('--payload-hex', required=True, type=str, help='data to be provided to the contract (returned by `serpent encode_datalist`)')
    parser_execute.add_argument('--fee', help='the exact {} fee to be paid to miners'.format(config.BTC))

    parser_destroy = subparsers.add_parser('destroy', help='destroy a quantity of a Counterparty asset')
    parser_destroy.add_argument('--source', required=True, help='the source address')
    parser_destroy.add_argument('--asset', required=True, help='the ASSET of which you would like to destroy QUANTITY')
    parser_destroy.add_argument('--quantity', required=True, help='the quantity of ASSET to destroy')
    parser_destroy.add_argument('--tag', default='', help='tag')
    parser_destroy.add_argument('--fee', help='the exact {} fee to be paid to miners'.format(config.BTC))

    parser_address = subparsers.add_parser('balances', help='display the balances of a {} address'.format(config.XCP_NAME))
    parser_address.add_argument('address', help='the address you are interested in')

    parser_asset = subparsers.add_parser('asset', help='display the basic properties of a {} asset'.format(config.XCP_NAME))
    parser_asset.add_argument('asset', help='the asset you are interested in')

    parser_wallet = subparsers.add_parser('wallet', help='list the addresses in your backend wallet along with their balances in all {} assets'.format(config.XCP_NAME))

    parser_pending = subparsers.add_parser('pending', help='list pending order matches awaiting {}payment from you'.format(config.BTC))

    parser_getrows = subparsers.add_parser('getrows', help='get rows from a Counterparty table')
    parser_getrows.add_argument('--table', required=True, help='table name')
    parser_getrows.add_argument('--filter', nargs=3, action='append', help='filters to get specific rows')
    parser_getrows.add_argument('--filter-op', choices=['AND', 'OR'], help='operator uses to combine filters', default='AND')
    parser_getrows.add_argument('--order-by', help='field used to order results')
    parser_getrows.add_argument('--order-dir', choices=['ASC', 'DESC'], help='direction used to order results')
    parser_getrows.add_argument('--start-block', help='return only rows with block_index greater than start-block')
    parser_getrows.add_argument('--end-block', help='return only rows with block_index lower than end-block')
    parser_getrows.add_argument('--status', help='return only rows with the specified status')
    parser_getrows.add_argument('--limit', help='number of rows to return', default=100)
    parser_getrows.add_argument('--offset', help='number of rows to skip', default=0)

    parser_getrunninginfo = subparsers.add_parser('getinfo', help='get the current state of the server')

    parser_get_tx_info = subparsers.add_parser('get_tx_info', help='display info of a raw TX')
    parser_get_tx_info.add_argument('tx_hex', help='the raw TX')

    args = parser.parse_args()

    # Logging
    log.set_up(logger, verbose=args.verbose)
    logger.propagate = False

    logger.info('Running v{} of {}.'.format(APP_VERSION, APP_NAME))

    # Help message
    if args.help:
        parser.print_help()
        sys.exit()

    # Configuration
    clientapi.initialize(testnet=args.testnet, testcoin=args.testcoin,
                        counterparty_rpc_connect=args.counterparty_rpc_connect, counterparty_rpc_port=args.counterparty_rpc_port,
                        counterparty_rpc_user=args.counterparty_rpc_user, counterparty_rpc_password=args.counterparty_rpc_password,
                        counterparty_rpc_ssl=args.counterparty_rpc_ssl, counterparty_rpc_ssl_verify=args.counterparty_rpc_ssl_verify,
                        wallet_name=args.wallet_name, wallet_connect=args.wallet_connect, wallet_port=args.wallet_port, 
                        wallet_user=args.wallet_user, wallet_password=args.wallet_password,
                        wallet_ssl=args.wallet_ssl, wallet_ssl_verify=args.wallet_ssl_verify,
                        requests_timeout=args.requests_timeout)

    # MESSAGE CREATION
    if args.action in list(messages.MESSAGE_PARAMS.keys()):
        unsigned_hex = messages.compose(args.action, args)
        logger.info('Transaction (unsigned): {}'.format(unsigned_hex))
        if not args.unsigned:
            if script.is_multisig(args.source):
                logger.info('Multi‐signature transactions are signed and broadcasted manually.')
            
            elif input('Sign and broadcast? (y/N) ') == 'y':

                if wallet.is_mine(args.source):
                    if wallet.is_locked():
                        passphrase = getpass.getpass('Enter your wallet passhrase: ')
                        logger.info('Unlocking wallet for 60 (more) seconds.')
                        wallet.unlock(passphrase)
                    signed_tx_hex = wallet.sign_raw_transaction(unsigned_hex)
                else:
                    private_key_wif = input('Source address not in wallet. Please enter the private key in WIF format for {}:'.format(args.source))
                    if not private_key_wif:
                        raise TransactionError('invalid private key')
                    signed_tx_hex = wallet.sign_raw_transaction(unsigned_hex, private_key_wif=private_key_wif)

                logger.info('Transaction (signed): {}'.format(signed_tx_hex))
                tx_hash = wallet.send_raw_transaction(signed_tx_hex)
                logger.info('Hash of transaction (broadcasted): {}'.format(tx_hash))


    # VIEWING
    elif args.action in ['balances', 'asset', 'wallet', 'pending', 'getinfo', 'getrows', 'get_tx_info']:
        view = console.get_view(args.action, args)
        print_method = getattr(console, 'print_{}'.format(args.action), None)
        if args.json_output or print_method is None:
            util.json_print(view)
        else:
            print_method(view)

    else:
        parser.print_help()

# vim: tabstop=8 expandtab shiftwidth=4 softtabstop=4
