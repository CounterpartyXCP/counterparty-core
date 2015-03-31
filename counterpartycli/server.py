#! /usr/bin/env python3

import os
import sys
import argparse
import logging

from counterpartylib.lib import log
logger = logging.getLogger(__name__)

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
    [('--backend-poll-interval',), {'type': float, 'default': 2.0, 'help': 'poll interval, in seconds (default: 2.0)'}],

    [('--rpc-host',), {'default': 'localhost', 'help': 'the IP of the interface to bind to for providing JSON-RPC API access (0.0.0.0 for all interfaces)'}],
    [('--rpc-port',), {'type': int, 'help': 'port on which to provide the {} JSON-RPC API'.format(config.APP_NAME)}],
    [('--rpc-user',), {'default': 'rpc', 'help': 'required username to use the {} JSON-RPC API (via HTTP basic auth)'.format(config.APP_NAME)}],
    [('--rpc-password',), {'help': 'required password (for rpc-user) to use the {} JSON-RPC API (via HTTP basic auth)'.format(config.APP_NAME)}],
    [('--rpc-no-allow-cors',), {'action': 'store_true', 'default': False, 'help': 'Allow ajax cross domain request'}],

    [('--force',), {'action': 'store_true', 'default': False, 'help': 'skip backend check, version check, process lock (NOT FOR USE ON PRODUCTION SYSTEMS)'}],
    [('--database-file',), {'default': None, 'help': 'the path to the SQLite3 database file'}],
    [('--log-file',), {'default': None, 'help': 'the path to the server log file'}],
    [('--api-log-file',), {'default': None, 'help': 'the path to the API log file'}]
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

    parser = add_config_arguments(parser, CONFIG_ARGS, 'server.conf')

    subparsers = parser.add_subparsers(dest='action', help='the action to be taken')

    parser_server = subparsers.add_parser('start', help='run the server')

    parser_reparse = subparsers.add_parser('reparse', help='reparse all transactions in the database')
   
    parser_rollback = subparsers.add_parser('rollback', help='rollback database')
    parser_rollback.add_argument('block_index', type=int, help='the index of the last known good block')
    
    parser_kickstart = subparsers.add_parser('kickstart', help='rapidly build database by reading from Bitcoin Core blockchain')
    parser_kickstart.add_argument('--bitcoind-dir', help='Bitcoin Core data directory')

    parser_bootstrap = subparsers.add_parser('bootstrap', help='bootstrap database with hosted snapshot')

    args = parser.parse_args()

    log.set_up(logger, verbose=args.verbose)
    
    logger.info('Running v{} of {}.'.format(APP_VERSION, APP_NAME))

    # Help message
    if args.help:
        parser.print_help()
        sys.exit()

    # Bootstrapping
    if args.action == 'bootstrap':
        bootstrap(testnet=args.testnet)
        sys.exit()

    # Configuration
    if args.action in ['reparse', 'rollback', 'kickstart', 'start']:
        try:
            db = server.initialise(database_file=args.database_file,
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
                                force=args.force, verbose=args.verbose)
                                #,broadcast_tx_mainnet=args.broadcast_tx_mainnet)
        except TypeError as e:
            if 'unexpected keyword argument' in str(e):
                raise VersionError('Unsupported Server Parameter. CLI/Library Version Incompatibility.')
            else:
                raise e

    # PARSING
    if args.action == 'reparse':
        server.reparse(db)

    elif args.action == 'rollback':
        server.reparse(db, block_index=args.block_index)

    elif args.action == 'kickstart':
        server.kickstart(db, bitcoind_dir=args.bitcoind_dir)

    elif args.action == 'start':
        server.start_all(db)

    else:
        parser.print_help()

# vim: tabstop=8 expandtab shiftwidth=4 softtabstop=4
