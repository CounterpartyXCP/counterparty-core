#! /usr/bin/env python3

import os
import sys
import argparse
import decimal
import logging
import time
import dateutil.parser
import calendar
import configparser
import binascii
import string
from urllib.parse import quote_plus as urlencode

import appdirs
from prettytable import PrettyTable
from colorlog import ColoredFormatter

from counterpartycli import util
from counterpartycli import messages
from counterpartycli import wallet
from counterpartycli import APP_VERSION
from counterpartycli.util import add_config_arguments
from counterpartycli.setup import generate_config_files
from counterpartycli import console

from counterpartylib.lib import config
from counterpartylib.lib import script
from counterpartylib.lib.util import make_id, BET_TYPE_NAME, BET_TYPE_ID, dhash
from counterpartylib.lib import log
from counterpartylib.lib.log import isodt

if os.name == 'nt':
    from counterpartylib.lib import util_windows

APP_NAME = 'counterparty-client'

D = decimal.Decimal

logger = logging.getLogger()

CONFIG_ARGS = [
    [('--testnet',), {'action': 'store_true', 'default': False, 'help': 'use {} testnet addresses and block numbers'.format(config.BTC_NAME)}],    

    [('--counterparty-rpc-connect',), {'default': 'localhost', 'help': 'the hostname or IP of the counterparty JSON-RPC server'}],
    [('--counterparty-rpc-port',), {'type': int, 'help': 'the counterparty JSON-RPC port to connect to'}],
    [('--counterparty-rpc-user',), {'default': 'rpc', 'help': 'the username used to communicate with counterparty over JSON-RPC'}],
    [('--counterparty-rpc-password',), {'help': 'the password used to communicate with counterparty over JSON-RPC'}],
    [('--counterparty-rpc-ssl',), {'default': False, 'action': 'store_true', 'help': 'use SSL to connect to counterparty (default: false)'}],
    [('--counterparty-rpc-ssl-verify',), {'default': False, 'action': 'store_true', 'help': 'verify SSL certificate of counterparty; disallow use of self‐signed certificates (default: false)'}],

    [('--wallet-name',), {'default': 'bitcoincore', 'help': 'the wallet name to connect to'}],
    [('--wallet-connect',), {'default': 'localhost', 'help': 'the hostname or IP of the wallet server'}],
    [('--wallet-port',), {'type': int, 'help': 'the wallet port to connect to'}],
    [('--wallet-user',), {'default': 'bitcoinrpc', 'help': 'the username used to communicate with wallet'}],
    [('--wallet-password',), {'help': 'the password used to communicate with wallet'}],
    [('--wallet-ssl',), {'action': 'store_true', 'default': False, 'help': 'use SSL to connect to wallet (default: false)'}],
    [('--wallet-ssl-verify',), {'action': 'store_true', 'default': False, 'help': 'verify SSL certificate of wallet; disallow use of self‐signed certificates (default: false)'}],

    [('--json-output',), {'action': 'store_true', 'default': False, 'help': 'display result in json format'}],
    [('-v', '--verbose'), {'dest': 'verbose', 'action': 'store_true', 'help': 'sets log level to DEBUG instead of WARNING'}],
    [('--testcoin',), {'action': 'store_true', 'default': False, 'help': 'use the test {} network on every blockchain'.format(config.XCP_NAME)}],
    [('--unconfirmed',), {'action': 'store_true', 'default': False, 'help': 'allow the spending of unconfirmed transaction outputs'}],
    [('--encoding',), {'default': 'auto', 'type': str, 'help': 'data encoding method'}],
    [('--fee-per-kb',), {'type': D, 'default': D(config.DEFAULT_FEE_PER_KB / config.UNIT), 'help': 'fee per kilobyte, in {}'.format(config.BTC)}],
    [('--regular-dust-size',), {'type': D, 'default': D(config.DEFAULT_REGULAR_DUST_SIZE / config.UNIT), 'help': 'value for dust Pay‐to‐Pubkey‐Hash outputs, in {}'.format(config.BTC)}],
    [('--multisig-dust-size',), {'type': D, 'default': D(config.DEFAULT_MULTISIG_DUST_SIZE / config.UNIT), 'help': 'for dust OP_CHECKMULTISIG outputs, in {}'.format(config.BTC)}],
    [('--op-return-value',), {'type': D, 'default': D(config.DEFAULT_OP_RETURN_VALUE / config.UNIT), 'help': 'value for OP_RETURN outputs, in {}'.format(config.BTC)}],
    [('--unsigned',), {'action': 'store_true', 'default': False, 'help': 'print out unsigned hex of transaction; do not sign or broadcast'}]
]

class ConfigurationError(Exception): pass

def sign_tx(unsigned_tx_hex, source):
    """Sign unsigned transaction serialisation."""
    logger.info('Transaction (unsigned): {}'.format(unsigned_tx_hex))

    if script.is_multisig(source):
        logger.info('Multi‐signature transactions are signed and broadcasted manually.')
    
    elif input('Sign and broadcast? (y/N) ') == 'y':
        if wallet.is_mine(source):
            signed_tx_hex = wallet.sign_raw_transaction(unsigned_tx_hex)
        else:
            private_key_wif = input('Source address not in wallet. Please enter the private key in WIF formar for {}:'.format(source))

            if not private_key_wif:
                raise exceptions.TransactionError('invalid private key')

            for char in private_key_wif:
                if char not in script.b58_digits:
                    raise exceptions.TransactionError('invalid private key')

            # TODO: Hack! (pybitcointools is Python 2 only)
            import subprocess
            i = 0
            tx_hex = unsigned_tx_hex
            while True: # pybtctool doesn’t implement `signall`
                try:
                    tx_hex = subprocess.check_output(['pybtctool', 'sign', tx_hex, str(i), private_key_wif], stderr=subprocess.DEVNULL)
                except Exception as e:
                    break
            if tx_hex != unsigned_tx_hex:
                signed_tx_hex = tx_hex.decode('utf-8')
                signed_tx_hex = signed_tx_hex[:-1]   # Get rid of newline.
            else:
                raise exceptions.TransactionError('Could not sign transaction with pybtctool.')

        logger.info('Transaction (signed): {}'.format(signed_tx_hex))
        tx_hash = wallet.send_raw_transaction(signed_tx_hex)
        logger.info('Hash of transaction (broadcasted): {}'.format(tx_hash))

def set_options(testnet=False, testcoin=False,
                counterparty_rpc_connect=None, counterparty_rpc_port=None, 
                counterparty_rpc_user=None, counterparty_rpc_password=None,
                counterparty_rpc_ssl=False, counterparty_rpc_ssl_verify=False,
                wallet_name=None, wallet_connect=None, wallet_port=None, 
                wallet_user=None, wallet_password=None,
                wallet_ssl=False, wallet_ssl_verify=False):

    def handle_exception(exc_type, exc_value, exc_traceback):
        logger.error("Unhandled Exception", exc_info=(exc_type, exc_value, exc_traceback))
    sys.excepthook = handle_exception

    logger.debug('Running v{} of {}.'.format(APP_VERSION, APP_NAME))

    # testnet
    config.TESTNET = testnet or False

    # testcoin
    config.TESTCOIN = testcoin or False

    ##############
    # THINGS WE CONNECT TO

    # Counterparty server host (Bitcoin Core)
    config.COUNTERPARTY_RPC_CONNECT = counterparty_rpc_connect or 'localhost'

    # Counterparty server RPC port (Bitcoin Core)
    if counterparty_rpc_port:
        config.COUNTERPARTY_RPC_PORT = counterparty_rpc_port
    else:
        if config.TESTNET:
            config.COUNTERPARTY_RPC_PORT = config.DEFAULT_RPC_PORT_TESTNET
        else:
            config.COUNTERPARTY_RPC_PORT = config.DEFAULT_RPC_PORT
    try:
        config.COUNTERPARTY_RPC_PORT = int(config.COUNTERPARTY_RPC_PORT)
        if not (int(config.COUNTERPARTY_RPC_PORT) > 1 and int(config.COUNTERPARTY_RPC_PORT) < 65535):
            raise ConfigurationError('invalid RPC port number')
    except:
        raise Exception("Please specific a valid port number counterparty-rpc-port configuration parameter")

    # Counterparty server RPC user (Bitcoin Core)
    config.COUNTERPARTY_RPC_USER = counterparty_rpc_user or 'rpc'

    # Counterparty server RPC password (Bitcoin Core)
    if counterparty_rpc_password:
        config.COUNTERPARTY_RPC_PASSWORD = counterparty_rpc_password
    else:
        raise ConfigurationError('counterparty RPC password not set. (Use configuration file or --counterparty-rpc-password=PASSWORD)')

    # Counterparty server RPC SSL
    config.COUNTERPARTY_RPC_SSL = counterparty_rpc_ssl or False  # Default to off.

    # Counterparty server RPC SSL Verify
    config.COUNTERPARTY_RPC_SSL_VERIFY = counterparty_rpc_ssl_verify or False # Default to off (support self‐signed certificates)

    # Construct Counterparty server URL.
    config.COUNTERPARTY_RPC = urlencode(config.COUNTERPARTY_RPC_USER) + ':' + urlencode(config.COUNTERPARTY_RPC_PASSWORD) + '@' + config.COUNTERPARTY_RPC_CONNECT + ':' + str(config.COUNTERPARTY_RPC_PORT)
    if config.COUNTERPARTY_RPC_SSL:
        config.COUNTERPARTY_RPC = 'https://' + config.COUNTERPARTY_RPC
    else:
        config.COUNTERPARTY_RPC = 'http://' + config.COUNTERPARTY_RPC


    # BTC Wallet name
    config.WALLET_NAME = wallet_name or 'bitcoincore'

    # BTC Wallet host
    config.WALLET_CONNECT = wallet_connect or 'localhost'

    # BTC Wallet port
    if wallet_port:
        config.WALLET_PORT = wallet_port
    else:
        if config.TESTNET:
            config.WALLET_PORT = config.DEFAULT_BACKEND_PORT_TESTNET
        else:
            config.WALLET_PORT = config.DEFAULT_BACKEND_PORT
    try:
        config.WALLET_PORT = int(config.WALLET_PORT)
        if not (int(config.WALLET_PORT) > 1 and int(config.WALLET_PORT) < 65535):
            raise ConfigurationError('invalid wallet API port number')
    except:
        raise ConfigurationError("Please specific a valid port number wallet-port configuration parameter")

    # BTC Wallet user
    config.WALLET_USER = wallet_user or 'bitcoinrpc'

    # BTC Wallet password
    if wallet_password:
        config.WALLET_PASSWORD = wallet_password
    else:
        raise ConfigurationError('wallet RPC password not set. (Use configuration file or --wallet-password=PASSWORD)')

    # BTC Wallet SSL
    config.WALLET_SSL = wallet_ssl or False  # Default to off.

    # BTC Wallet SSL Verify
    config.WALLET_SSL_VERIFY = wallet_ssl_verify or False # Default to off (support self‐signed certificates)

    # Construct BTC wallet URL.
    config.WALLET_URL = urlencode(config.WALLET_USER) + ':' + urlencode(config.WALLET_PASSWORD) + '@' + config.WALLET_CONNECT + ':' + str(config.WALLET_PORT)
    if config.WALLET_SSL:
        config.WALLET_URL = 'https://' + config.WALLET_URL
    else:
        config.WALLET_URL = 'http://' + config.WALLET_URL

    # (more) Testnet
    if config.TESTNET:
        config.MAGIC_BYTES = config.MAGIC_BYTES_TESTNET
        if config.TESTCOIN:
            config.ADDRESSVERSION = config.ADDRESSVERSION_TESTNET
            config.BLOCK_FIRST = config.BLOCK_FIRST_TESTNET_TESTCOIN
            config.BURN_START = config.BURN_START_TESTNET_TESTCOIN
            config.BURN_END = config.BURN_END_TESTNET_TESTCOIN
            config.UNSPENDABLE = config.UNSPENDABLE_TESTNET
        else:
            config.ADDRESSVERSION = config.ADDRESSVERSION_TESTNET
            config.BLOCK_FIRST = config.BLOCK_FIRST_TESTNET
            config.BURN_START = config.BURN_START_TESTNET
            config.BURN_END = config.BURN_END_TESTNET
            config.UNSPENDABLE = config.UNSPENDABLE_TESTNET
    else:
        config.MAGIC_BYTES = config.MAGIC_BYTES_MAINNET
        if config.TESTCOIN:
            config.ADDRESSVERSION = config.ADDRESSVERSION_MAINNET
            config.BLOCK_FIRST = config.BLOCK_FIRST_MAINNET_TESTCOIN
            config.BURN_START = config.BURN_START_MAINNET_TESTCOIN
            config.BURN_END = config.BURN_END_MAINNET_TESTCOIN
            config.UNSPENDABLE = config.UNSPENDABLE_MAINNET
        else:
            config.ADDRESSVERSION = config.ADDRESSVERSION_MAINNET
            config.BLOCK_FIRST = config.BLOCK_FIRST_MAINNET
            config.BURN_START = config.BURN_START_MAINNET
            config.BURN_END = config.BURN_END_MAINNET
            config.UNSPENDABLE = config.UNSPENDABLE_MAINNET

def main():
    logger.info('Running v{} of {}.'.format(APP_VERSION, APP_NAME))

    if os.name == 'nt':
        #patch up cmd.exe's "challenged" (i.e. broken/non-existent) UTF-8 logging
        util_windows.fix_win32_unicode()

    # Post installation tasks
    generate_config_files()

    # Parse command-line arguments.
    parser = argparse.ArgumentParser(prog=APP_NAME, description='Counterparty CLI for counterparty-server', add_help=False)
    parser.add_argument('-h', '--help', dest='help', action='store_true', help='show this help message and exit')
    parser.add_argument('-V', '--version', action='version', version="{} v{}".format(APP_NAME, APP_VERSION))
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

    parser_rps = subparsers.add_parser('rps', help='open a rock-paper-scissors like game')
    parser_rps.add_argument('--source', required=True, help='the source address')
    parser_rps.add_argument('--wager', required=True, help='the quantity of XCP to wager')
    parser_rps.add_argument('--move', type=int, required=True, help='the selected move')
    parser_rps.add_argument('--possible-moves', type=int, required=True, help='the number of possible moves (odd number greater or equal than 3)')
    parser_rps.add_argument('--expiration', type=int, required=True, help='the number of blocks for which the bet should be valid')
    parser_rps.add_argument('--fee', help='the exact BTC fee to be paid to miners')

    parser_rpsresolve = subparsers.add_parser('rpsresolve', help='resolve a rock-paper-scissors like game')
    parser_rpsresolve.add_argument('--source', required=True, help='the source address')
    parser_rpsresolve.add_argument('--random', type=str, required=True, help='the random number used in the corresponding rps transaction')
    parser_rpsresolve.add_argument('--move', type=int, required=True, help='the selected move in the corresponding rps transaction')
    parser_rpsresolve.add_argument('--rps-match-id', required=True, help='the concatenation of the hashes of the two transactions which compose the rps match')
    parser_rpsresolve.add_argument('--fee', help='the exact BTC fee to be paid to miners')

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

    parser_market = subparsers.add_parser('market', help='fill the screen with an always up-to-date summary of the {} market'.format(config.XCP_NAME))
    parser_market.add_argument('--give-asset', help='only show orders offering to sell GIVE_ASSET')
    parser_market.add_argument('--get-asset', help='only show orders offering to buy GET_ASSET')

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

    args = parser.parse_args()

    # Help message
    if args.help:
        parser.print_help()
        sys.exit()

    # Logging
    log.set_up(logger, verbose=args.verbose)

    # Configuration
    set_options(testnet=args.testnet, testcoin=args.testcoin,
                counterparty_rpc_connect=args.counterparty_rpc_connect, counterparty_rpc_port=args.counterparty_rpc_port,
                counterparty_rpc_user=args.counterparty_rpc_user, counterparty_rpc_password=args.counterparty_rpc_password,
                counterparty_rpc_ssl=args.counterparty_rpc_ssl, counterparty_rpc_ssl_verify=args.counterparty_rpc_ssl_verify,
                wallet_name=args.wallet_name, wallet_connect=args.wallet_connect, wallet_port=args.wallet_port, 
                wallet_user=args.wallet_user, wallet_password=args.wallet_password,
                wallet_ssl=args.wallet_ssl, wallet_ssl_verify=args.wallet_ssl_verify)

    # MESSAGE CREATION
    if args.action in list(messages.MESSAGE_PARAMS.keys()):
        unsigned_hex = messages.compose(args.action, args)
        if not args.unsigned:
            sign_tx(unsigned_hex, args.source)

    # VIEWING
    elif args.action in ['balances', 'asset', 'wallet', 'pending', 'getinfo', 'getrows']:
        view = console.get_view(args.action, args)
        if args.json_output:
            util.json_print(view)
        else:
            print_method = getattr(console, 'print_{}'.format(args.action), None)
            if print_method:
                print_method(view)
            else:
                util.json_print(view)

    else:
        parser.print_help()

# vim: tabstop=8 expandtab shiftwidth=4 softtabstop=4
