#! /usr/bin/env python3

import os
import sys
import argparse
import logging
logger = logging.getLogger()

from counterpartylib.lib import log
log.set_logger(logger)

from counterpartylib import server
from counterpartylib.lib import config
from counterpartycli.util import add_config_arguments, bootstrap
from counterpartycli.setup import generate_config_files
from counterpartycli import APP_VERSION

APP_NAME = 'counterparty-server'

CONFIG_ARGS = [
    [('-v', '--verbose'), {'dest': 'verbose', 'action': 'store_true', 'default': False, 'help': 'sets log level to DEBUG instead of WARNING'}],
    [('--testnet',), {'action': 'store_true', 'default': False, 'help': 'use {} testnet addresses and block numbers'.format(config.BTC_NAME)}],
    [('--testcoin',), {'action': 'store_true', 'default': False, 'help': 'use the test {} network on every blockchain'.format(config.XCP_NAME)}],

    [('--backend-name',), {'default': 'addrindex', 'help': 'the backend name to connect to'}],
    [('--backend-connect',), {'default': 'localhost', 'help': 'the hostname or IP of the backend server'}],
    [('--backend-port',), {'type': int, 'help': 'the backend port to connect to'}],
    [('--backend-user',), {'default': 'bitcoinrpc', 'help': 'the username used to communicate with backend'}],
    [('--backend-password',), {'help': 'the password used to communicate with backend'}],
    [('--backend-ssl',), {'action': 'store_true', 'default': False, 'help': 'use SSL to connect to backend (default: false)'}],
    [('--backend-ssl-no-verify',), {'action': 'store_true', 'default': False, 'help': 'verify SSL certificate of backend; disallow use of self‐signed certificates (default: true)'}],
    [('--backend-poll-interval',), {'type': float, 'default': 0.5, 'help': 'poll interval, in seconds (default: 0.5)'}],
    [('--no-check-asset-conservation',), {'action': 'store_true', 'default': False, 'help': 'Skip asset conservation checking (default: false)'}],
    [('--p2sh-dust-return-pubkey',), {'help': 'pubkey to receive dust when multisig encoding is used for P2SH source (default: pubkey from counterparty foundation)'}],

    [('--rpc-host',), {'default': 'localhost', 'help': 'the IP of the interface to bind to for providing JSON-RPC API access (0.0.0.0 for all interfaces)'}],
    [('--rpc-port',), {'type': int, 'help': 'port on which to provide the {} JSON-RPC API'.format(config.APP_NAME)}],
    [('--rpc-user',), {'default': 'rpc', 'help': 'required username to use the {} JSON-RPC API (via HTTP basic auth)'.format(config.APP_NAME)}],
    [('--rpc-password',), {'help': 'required password (for rpc-user) to use the {} JSON-RPC API (via HTTP basic auth)'.format(config.APP_NAME)}],
    [('--rpc-no-allow-cors',), {'action': 'store_true', 'default': False, 'help': 'allow ajax cross domain request'}],
    [('--rpc-batch-size',), {'type': int, 'default': config.DEFAULT_RPC_BATCH_SIZE, 'help': 'number of RPC queries by batch (default: {})'.format(config.DEFAULT_RPC_BATCH_SIZE)}],
    [('--requests-timeout',), {'type': int, 'default': config.DEFAULT_REQUESTS_TIMEOUT, 'help': 'timeout value (in seconds) used for all HTTP requests (default: 5)'}],

    [('--force',), {'action': 'store_true', 'default': False, 'help': 'skip backend check, version check, process lock (NOT FOR USE ON PRODUCTION SYSTEMS)'}],
    [('--database-file',), {'default': None, 'help': 'the path to the SQLite3 database file'}],
    [('--log-file',), {'nargs': '?', 'const': None, 'default': False, 'help': 'log to the specified file (specify option without filename to use the default location)'}],
    [('--api-log-file',), {'nargs': '?', 'const': None, 'default': False, 'help': 'log API requests to the specified file (specify option without filename to use the default location)'}],

    [('--utxo-locks-max-addresses',), {'type': int, 'default': config.DEFAULT_UTXO_LOCKS_MAX_ADDRESSES, 'help': 'max number of addresses for which to track UTXO locks'}],
    [('--utxo-locks-max-age',), {'type': int, 'default': config.DEFAULT_UTXO_LOCKS_MAX_AGE, 'help': 'how long to keep a lock on a UTXO being tracked'}]
]

class VersionError(Exception):
    pass
def main():
    if os.name == 'nt':
        from counterpartylib.lib import util_windows
        #patch up cmd.exe's "challenged" (i.e. broken/non-existent) UTF-8 logging
        util_windows.fix_win32_unicode()

    # Post installation tasks
    generate_config_files()

    # Parse command-line arguments.
    parser = argparse.ArgumentParser(prog=APP_NAME, description='Server for the {} protocol'.format(config.XCP_NAME), add_help=False)
    parser.add_argument('-h', '--help', dest='help', action='store_true', help='show this help message and exit')
    parser.add_argument('-V', '--version', action='version', version="{} v{}; {} v{}".format(APP_NAME, APP_VERSION, 'counterparty-lib', config.VERSION_STRING))
    parser.add_argument('--config-file', help='the path to the configuration file')

    add_config_arguments(parser, CONFIG_ARGS, 'server.conf')

    subparsers = parser.add_subparsers(dest='action', help='the action to be taken')

    parser_server = subparsers.add_parser('start', help='run the server')

    parser_reparse = subparsers.add_parser('reparse', help='reparse all transactions in the database')

    parser_rollback = subparsers.add_parser('rollback', help='rollback database')
    parser_rollback.add_argument('block_index', type=int, help='the index of the last known good block')

    parser_kickstart = subparsers.add_parser('kickstart', help='rapidly build database by reading from Bitcoin Core blockchain')
    parser_kickstart.add_argument('--bitcoind-dir', help='Bitcoin Core data directory')

    parser_bootstrap = subparsers.add_parser('bootstrap', help='bootstrap database with hosted snapshot')
    parser_bootstrap.add_argument('-q', '--quiet', dest='quiet', action='store_true', help='suppress progress bar')

    args = parser.parse_args()

    log.set_up(log.ROOT_LOGGER, verbose=args.verbose, console_logfilter=os.environ.get('COUNTERPARTY_LOGGING', None))

    logger.info('Running v{} of {}.'.format(APP_VERSION, APP_NAME))

    # Help message
    if args.help:
        parser.print_help()
        sys.exit()

    # Bootstrapping
    if args.action == 'bootstrap':
        bootstrap(testnet=args.testnet, quiet=args.quiet)
        sys.exit()

    def init_with_catch(fn, init_args):
        try:
            return fn(**init_args)
        except TypeError as e:
            if 'unexpected keyword argument' in str(e):
                raise VersionError('Unsupported Server Parameter. CLI/Library Version Incompatibility.')
            else:
                raise e

    # Configuration
    COMMANDS_WITH_DB = ['reparse', 'rollback', 'kickstart', 'start']
    COMMANDS_WITH_CONFIG = ['debug_config']
    if args.action in COMMANDS_WITH_DB or args.action in COMMANDS_WITH_CONFIG:
        init_args = dict(database_file=args.database_file,
                                log_file=args.log_file, api_log_file=args.api_log_file,
                                testnet=args.testnet, testcoin=args.testcoin,
                                backend_name=args.backend_name,
                                backend_connect=args.backend_connect,
                                backend_port=args.backend_port,
                                backend_user=args.backend_user,
                                backend_password=args.backend_password,
                                backend_ssl=args.backend_ssl,
                                backend_ssl_no_verify=args.backend_ssl_no_verify,
                                backend_poll_interval=args.backend_poll_interval,
                                rpc_host=args.rpc_host, rpc_port=args.rpc_port, rpc_user=args.rpc_user,
                                rpc_password=args.rpc_password, rpc_no_allow_cors=args.rpc_no_allow_cors,
                                requests_timeout=args.requests_timeout,
                                rpc_batch_size=args.rpc_batch_size,
                                check_asset_conservation=not args.no_check_asset_conservation,
                                force=args.force, verbose=args.verbose, console_logfilter=os.environ.get('COUNTERPARTY_LOGGING', None),
                                p2sh_dust_return_pubkey=args.p2sh_dust_return_pubkey,
                                utxo_locks_max_addresses=args.utxo_locks_max_addresses,
                                utxo_locks_max_age=args.utxo_locks_max_age)
                                #,broadcast_tx_mainnet=args.broadcast_tx_mainnet)

    if args.action in COMMANDS_WITH_DB:
        db = init_with_catch(server.initialise, init_args)

    elif args.action in COMMANDS_WITH_CONFIG:
        init_with_catch(server.initialise_config, init_args)

    # PARSING
    if args.action == 'reparse':
        server.reparse(db)

    elif args.action == 'rollback':
        server.reparse(db, block_index=args.block_index)

    elif args.action == 'kickstart':
        server.kickstart(db, bitcoind_dir=args.bitcoind_dir)

    elif args.action == 'start':
        server.start_all(db)

    elif args.action == 'debug_config':
        server.debug_config()

    else:
        parser.print_help()

# vim: tabstop=8 expandtab shiftwidth=4 softtabstop=4
