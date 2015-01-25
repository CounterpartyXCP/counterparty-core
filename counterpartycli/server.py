#! /usr/bin/env python3

import os
import argparse
import configparser
import appdirs
import logging

from counterpartylib import server
from counterpartylib.lib import config
from counterpartylib.lib import log

APP_NAME = 'counterparty-server'
APP_VERSION = '1.0.0'

logger = logging.getLogger()

def main():
    if os.name == 'nt':
        from counterpartylib.lib import util_windows
        #patch up cmd.exe's "challenged" (i.e. broken/non-existent) UTF-8 logging
        util_windows.fix_win32_unicode()

    # Parse command-line arguments.
    parser = argparse.ArgumentParser(prog=APP_NAME, description='Server for the {} protocol'.format(config.XCP_NAME))
    parser.add_argument('-V', '--version', action='version', version="{} v{}".format(APP_NAME, APP_VERSION))

    parser.add_argument('-v', '--verbose', dest='verbose', action='store_true', help='sets log level to DEBUG instead of WARNING')
    parser.add_argument('--testnet', action='store_true', help='use {} testnet addresses and block numbers'.format(config.BTC_NAME))
    parser.add_argument('--testcoin', action='store_true', help='use the test {} network on every blockchain'.format(config.XCP_NAME))
    parser.add_argument('--force', action='store_true', help='skip backend check, version check, process lock (NOT FOR USE ON PRODUCTION SYSTEMS)')

    parser.add_argument('--database-file', help='the location of the SQLite3 database')
    parser.add_argument('--config-file', help='the location of the configuration file')
    parser.add_argument('--log-file', help='the location of the log file')
    parser.add_argument('--api-log-file', help='the location of the API log file')

    parser.add_argument('--backend-name', help='the backend name to connect to')
    parser.add_argument('--backend-connect', help='the hostname or IP of the backend server')
    parser.add_argument('--backend-port', type=int, help='the backend port to connect to')
    parser.add_argument('--backend-user', help='the username used to communicate with backend')
    parser.add_argument('--backend-password', help='the password used to communicate with backend')
    parser.add_argument('--backend-ssl', action='store_true', help='use SSL to connect to backend (default: false)')
    parser.add_argument('--backend-ssl-verify', action='store_true', help='verify SSL certificate of backend; disallow use of self‐signed certificates (default: false)')
    parser.add_argument('--backend-poll-interval', type=float, help='poll interval, in seconds (default: 2.0)')

    parser.add_argument('--rpc-host', help='the IP of the interface to bind to for providing JSON-RPC API access (0.0.0.0 for all interfaces)')
    parser.add_argument('--rpc-port', type=int, help='port on which to provide the {} JSON-RPC API'.format(APP_NAME))
    parser.add_argument('--rpc-user', help='required username to use the {} JSON-RPC API (via HTTP basic auth)'.format(APP_NAME))
    parser.add_argument('--rpc-password', help='required password (for rpc-user) to use the {} JSON-RPC API (via HTTP basic auth)'.format(APP_NAME))
    parser.add_argument('--rpc-allow-cors', action='store_true', default=True, help='Allow ajax cross domain request')

    subparsers = parser.add_subparsers(dest='action', help='the action to be taken')

    parser_server = subparsers.add_parser('start', help='run the server')

    parser_reparse = subparsers.add_parser('reparse', help='reparse all transactions in the database')
   
    parser_rollback = subparsers.add_parser('rollback', help='rollback database')
    parser_rollback.add_argument('block_index', type=int, help='the index of the last known good block')
    
    parser_kickstart = subparsers.add_parser('kickstart', help='rapidly bring database up to the present')
    parser_kickstart.add_argument('--bitcoind-dir', help='Bitcoin Core data directory')
    
    args = parser.parse_args()

    # Logging
    log.set_up(False)

    # Config directory
    config_dir = appdirs.user_config_dir(appauthor=config.XCP_NAME, appname=APP_NAME, roaming=True)
    if not os.path.isdir(config_dir):
        os.makedirs(config_dir)

    logger.info('Running v{} of {}.'.format(APP_VERSION, APP_NAME))

    # Configuration file
    config_file_changed = False
    configfile = configparser.ConfigParser()
    if not args.config_file:
        args.config_file = os.path.join(config_dir, '{}.conf'.format(APP_NAME))
    logger.info('Loading configuration file: `{}`'.format(args.config_file))
    configfile.read(args.config_file)
    if not 'Default' in configfile:
        configfile['Default'] = {}

    #TODO: dry (use a loop)
    # testnet
    if not args.testnet and 'testnet' in configfile['Default'] and configfile['Default'].getboolean('testnet'):
        args.testnet = True
    # testcoin
    if not args.testcoin and 'testcoin' in configfile['Default'] and configfile['Default'].getboolean('testcoin'):
        args.testcoin = True
    # verbose
    if not args.verbose and 'verbose' in configfile['Default'] and configfile['Default'].getboolean('verbose'):
        args.verbose = True
    # force
    if not args.force and 'force' in configfile['Default'] and configfile['Default'].getboolean('force'):
        args.force = True
    # Database
    if not args.database_file and 'database-file' in configfile['Default'] and configfile['Default']['database-file']:
        args.database_file = configfile['Default']['database-file']
    # Log
    if not args.log_file and 'log-file' in configfile['Default'] and configfile['Default']['log-file']:
        args.log_file = configfile['Default']['log-file']
    # API Log
    if not args.api_log_file and 'api-log-file' in configfile['Default'] and configfile['Default']['api-log-file']:
        args.api_log_file = configfile['Default']['api-log-file']
    # Backend
    if not args.backend_name and 'backend-name' in configfile['Default'] and configfile['Default']['backend-name']:
        args.backend_name = configfile['Default']['backend-name']
    if not args.backend_connect and 'backend-connect' in configfile['Default'] and configfile['Default']['backend-connect']:
        args.backend_connect = configfile['Default']['backend-connect']
    if not args.backend_port and 'backend-port' in configfile['Default'] and configfile['Default']['backend-port']:
        args.backend_port = configfile['Default']['backend-port']
    if not args.backend_user and 'backend-user' in configfile['Default'] and configfile['Default']['backend-user']:
        args.backend_user = configfile['Default']['backend-user']
    if not args.backend_password and 'backend-password' in configfile['Default'] and configfile['Default']['backend-password']:
        args.backend_password = configfile['Default']['backend-password']
    if not args.backend_ssl and 'backend-ssl' in configfile['Default'] and configfile['Default']['backend-ssl']:
        args.backend_ssl = configfile['Default']['backend-ssl']
    if not args.backend_ssl_verify and 'backend-ssl-verify' in configfile['Default'] and configfile['Default']['backend-ssl-verify']:
        args.backend_ssl_verify = configfile['Default']['backend-ssl-verify']
    if not args.backend_poll_interval and 'backend-poll-interval' in configfile['Default'] and configfile['Default']['backend-poll-interval']:
        args.backend_poll_interval = configfile['Default']['backend-poll-interval']
    # RPC
    if not args.rpc_host and 'rpc-host' in configfile['Default'] and configfile['Default']['rpc-host']:
        args.rpc_host = configfile['Default']['rpc-host']
    if not args.rpc_port and 'rpc-port' in configfile['Default'] and configfile['Default']['rpc-port']:
        args.rpc_port = configfile['Default']['rpc-port']
    if not args.rpc_user and 'rpc-user' in configfile['Default'] and configfile['Default']['rpc-user']:
        args.rpc_user = configfile['Default']['rpc-user']
    if not args.rpc_password and 'rpc-password' in configfile['Default'] and configfile['Default']['rpc-password']:
        args.rpc_password = configfile['Default']['rpc-password']
    if not args.rpc_allow_cors and 'rpc-allow-cors' in configfile['Default'] and configfile['Default']['rpc-allow-cors']:
        args.rpc_allow_cors = configfile['Default'].getboolean('rpc-allow-cors')

    broadcast_tx_mainnet = None
    if 'broadcast-tx-mainnet' in configfile['Default']:
        broadcast_tx_mainnet = configfile['Default']['broadcast-tx-mainnet']

    # Configuration
    db = server.initialise(database_file=args.database_file, 
                            log_file=args.log_file, api_log_file=args.api_log_file,
                            testnet=args.testnet, testcoin=args.testcoin,
                            backend_name=args.backend_name,
                            backend_connect=args.backend_connect,
                            backend_port=args.backend_port,
                            backend_user=args.backend_user,
                            backend_password=args.backend_password,
                            backend_ssl=args.backend_ssl,
                            backend_ssl_verify=args.backend_ssl_verify,
                            backend_poll_interval=args.backend_poll_interval,
                            rpc_host=args.rpc_host, rpc_port=args.rpc_port, rpc_user=args.rpc_user,
                            rpc_password=args.rpc_password, rpc_allow_cors=args.rpc_allow_cors,
                            force=args.force, verbose=args.verbose,
                            broadcast_tx_mainnet=broadcast_tx_mainnet)

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
