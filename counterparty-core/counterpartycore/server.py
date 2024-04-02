#! /usr/bin/env python3

import argparse
import logging
from urllib.parse import quote_plus as urlencode

from termcolor import cprint

from counterpartylib import server
from counterpartylib.lib import log, config, setup


logger = logging.getLogger(config.LOGGER_NAME)

APP_NAME = 'counterparty-core'
APP_VERSION = config.VERSION_STRING

CONFIG_ARGS = [
    [('-v', '--verbose'), {'dest': 'verbose', 'action': 'store_true', 'default': False, 'help': 'sets log level to DEBUG'}],
    [('--quiet',), {'dest': 'quiet', 'action': 'store_true', 'default': False, 'help': 'sets log level to ERROR'}],
    [('--mainnet',), {'action': 'store_true', 'default': True, 'help': f'use {config.BTC_NAME} mainet addresses and block numbers'}],
    [('--testnet',), {'action': 'store_true', 'default': False, 'help': f'use {config.BTC_NAME} testnet addresses and block numbers'}],
    [('--testcoin',), {'action': 'store_true', 'default': False, 'help': f'use the test {config.XCP_NAME} network on every blockchain'}],
    [('--regtest',), {'action': 'store_true', 'default': False, 'help': f'use {config.BTC_NAME} regtest addresses and block numbers'}],
    [('--customnet',), {'default': '', 'help': 'use a custom network (specify as UNSPENDABLE_ADDRESS|ADDRESSVERSION|P2SH_ADDRESSVERSION with version bytes in HH hex format)'}],
    [('--api-limit-rows',), {'type': int, 'default': 1000, 'help': 'limit api calls to the set results (defaults to 1000). Setting to 0 removes the limit.'}],
    [('--backend-name',), {'default': 'addrindex', 'help': 'the backend name to connect to'}],
    [('--backend-connect',), {'default': 'localhost', 'help': 'the hostname or IP of the backend server'}],
    [('--backend-port',), {'type': int, 'help': 'the backend port to connect to'}],
    [('--backend-user',), {'default': 'rpc', 'help': 'the username used to communicate with backend'}],
    [('--backend-password',), {'default': 'rpc', 'help': 'the password used to communicate with backend'}],
    [('--backend-ssl',), {'action': 'store_true', 'default': False, 'help': 'use SSL to connect to backend (default: false)'}],
    [('--backend-ssl-no-verify',), {'action': 'store_true', 'default': False, 'help': 'verify SSL certificate of backend; disallow use of self‐signed certificates (default: true)'}],
    [('--backend-poll-interval',), {'type': float, 'default': 0.5, 'help': 'poll interval, in seconds (default: 0.5)'}],
    [('--no-check-asset-conservation',), {'action': 'store_true', 'default': False, 'help': 'Skip asset conservation checking (default: false)'}],
    [('--p2sh-dust-return-pubkey',), {'help': 'pubkey to receive dust when multisig encoding is used for P2SH source (default: none)'}],

    [('--indexd-connect',), {'default': 'localhost', 'help': 'the hostname or IP of the indexd server'}],
    [('--indexd-port',), {'type': int, 'help': 'the indexd server port to connect to'}],

    [('--rpc-host',), {'default': 'localhost', 'help': 'the IP of the interface to bind to for providing JSON-RPC API access (0.0.0.0 for all interfaces)'}],
    [('--rpc-port',), {'type': int, 'help': f'port on which to provide the {config.APP_NAME} JSON-RPC API'}],
    [('--rpc-user',), {'default': 'rpc', 'help': f'required username to use the {config.APP_NAME} JSON-RPC API (via HTTP basic auth)'}],
    [('--rpc-password',), {'default': 'rpc', 'help':f'required password (for rpc-user) to use the {config.APP_NAME} JSON-RPC API (via HTTP basic auth)'}],
    [('--rpc-no-allow-cors',), {'action': 'store_true', 'default': False, 'help': 'allow ajax cross domain request'}],
    [('--rpc-batch-size',), {'type': int, 'default': config.DEFAULT_RPC_BATCH_SIZE, 'help': f'number of RPC queries by batch (default: {config.DEFAULT_RPC_BATCH_SIZE})'}],
    [('--requests-timeout',), {'type': int, 'default': config.DEFAULT_REQUESTS_TIMEOUT, 'help': 'timeout value (in seconds) used for all HTTP requests (default: 5)'}],

    [('--force',), {'action': 'store_true', 'default': False, 'help': 'skip backend check, version check, process lock (NOT FOR USE ON PRODUCTION SYSTEMS)'}],
    [('--no-confirm',), {'action': 'store_true', 'default': False, 'help': 'don\'t ask for confirmation'}],
    [('--database-file',), {'default': None, 'help': 'the path to the SQLite3 database file'}],
    [('--log-file',), {'nargs': '?', 'const': None, 'default': False, 'help': 'log to the specified file'}],
    [('--api-log-file',), {'nargs': '?', 'const': None, 'default': False, 'help': 'log API requests to the specified file'}],
    [('--no-log-files',), {'action': 'store_true', 'default': False, 'help': 'Don\'t write log files'}],
    [('--json-log',), {'action': 'store_true', 'default': False, 'help': 'Log events in JSON format'}],

    [('--utxo-locks-max-addresses',), {'type': int, 'default': config.DEFAULT_UTXO_LOCKS_MAX_ADDRESSES, 'help': 'max number of addresses for which to track UTXO locks'}],
    [('--utxo-locks-max-age',), {'type': int, 'default': config.DEFAULT_UTXO_LOCKS_MAX_AGE, 'help': 'how long to keep a lock on a UTXO being tracked'}],
]

def welcome_message(action, server_configfile):
    cprint(f'Running v{config.__version__} of {config.FULL_APP_NAME}.', 'magenta')

    # print some info
    cprint(f"Configuration file: {server_configfile}", 'light_grey')
    cprint(f"Counterparty database: {config.DATABASE}", 'light_grey')
    if config.LOG:
        cprint(f'Writing log to file: `{config.LOG}`', 'light_grey')
    else:
        cprint('Warning: log disabled', 'yellow')
    if config.API_LOG:
        cprint(f'Writing API accesses log to file: `{config.API_LOG}`', 'light_grey')
    else:
        cprint('Warning: API log disabled', 'yellow')

    if config.VERBOSE:
        if config.TESTNET:
            cprint('NETWORK: Testnet', 'light_grey')
        elif config.REGTEST:
            cprint('NETWORK: Regtest', 'light_grey')
        else:
            cprint('NETWORK: Mainnet', 'light_grey')

        pass_str = f":{urlencode(config.BACKEND_PASSWORD)}@"
        cleaned_backend_url = config.BACKEND_URL.replace(pass_str, ":*****@")
        cprint(f'BACKEND_URL: {cleaned_backend_url}', 'light_grey')
        cprint(f'INDEXD_URL: {config.INDEXD_URL}', 'light_grey')
        pass_str = f":{urlencode(config.RPC_PASSWORD)}@"
        cleaned_rpc_url = config.RPC.replace(pass_str, ":*****@")
        cprint(f'RPC: {cleaned_rpc_url}', 'light_grey')

    cprint(f"{'-' * 30} {action} {'-' * 30}\n", 'green')


class VersionError(Exception):
    pass
def main():
    # Post installation tasks
    server_configfile = setup.generate_server_config_file(CONFIG_ARGS)

    # Parse command-line arguments.
    parser = argparse.ArgumentParser(
        prog=APP_NAME,
        description=f'Server for the {config.XCP_NAME} protocol',
        add_help=False,
        exit_on_error=False
    )
    parser.add_argument('-h', '--help', dest='help', action='store_true', help='show this help message and exit')
    parser.add_argument('-V', '--version', action='version', version=f"{APP_NAME} v{APP_VERSION}; counterparty-lib v{config.VERSION_STRING}")
    parser.add_argument('--config-file', help='the path to the configuration file')

    cmd_args = parser.parse_known_args()[0]
    config_file_path = getattr(cmd_args, 'config_file', None)
    configfile = setup.read_config_file('server.conf', config_file_path)

    setup.add_config_arguments(parser, CONFIG_ARGS, configfile, add_default=True)

    subparsers = parser.add_subparsers(dest='action', help='the action to be taken')

    parser_server = subparsers.add_parser('start', help='run the server')
    parser_server.add_argument('--config-file', help='the path to the configuration file')
    parser_server.add_argument('--catch-up', choices=['normal', 'bootstrap'], default='normal', help='Catch up mode (default: normal)')
    setup.add_config_arguments(parser_server, CONFIG_ARGS, configfile)

    parser_reparse = subparsers.add_parser('reparse', help='reparse all transactions in the database')
    parser_reparse.add_argument('block_index', type=int, help='the index of the last known good block')
    setup.add_config_arguments(parser_reparse, CONFIG_ARGS, configfile)

    parser_vacuum = subparsers.add_parser('vacuum', help='VACUUM the database (to improve performance)')
    setup.add_config_arguments(parser_vacuum, CONFIG_ARGS, configfile)

    parser_rollback = subparsers.add_parser('rollback', help='rollback database')
    parser_rollback.add_argument('block_index', type=int, help='the index of the last known good block')
    setup.add_config_arguments(parser_rollback, CONFIG_ARGS, configfile)

    parser_kickstart = subparsers.add_parser('kickstart', help='rapidly build database by reading from Bitcoin Core blockchain')
    parser_kickstart.add_argument('--bitcoind-dir', help='Bitcoin Core data directory')
    parser_kickstart.add_argument('--max-queue-size', type=int, help='Size of the multiprocessing.Queue for parsing blocks')
    parser_kickstart.add_argument('--debug-block', type=int, help='Rollback and run kickstart for a single block;')
    setup.add_config_arguments(parser_kickstart, CONFIG_ARGS, configfile)

    parser_bootstrap = subparsers.add_parser('bootstrap', help='bootstrap database with hosted snapshot')
    setup.add_config_arguments(parser_bootstrap, CONFIG_ARGS, configfile)

    parser_checkdb = subparsers.add_parser('check-db', help='do an integrity check on the database')
    setup.add_config_arguments(parser_checkdb, CONFIG_ARGS, configfile)

    parser_show_config = subparsers.add_parser('show-params', help='Show counterparty-server configuration')
    setup.add_config_arguments(parser_show_config, CONFIG_ARGS, configfile)

    args = parser.parse_args()

    # Help message
    if args.help:
        parser.print_help()
        exit(0)

    # Configuration
    init_args = dict(database_file=args.database_file,
                    testnet=args.testnet, testcoin=args.testcoin, regtest=args.regtest,
                    customnet=args.customnet,
                    api_limit_rows=args.api_limit_rows,
                    backend_connect=args.backend_connect,
                    backend_port=args.backend_port,
                    backend_user=args.backend_user,
                    backend_password=args.backend_password,
                    backend_ssl=args.backend_ssl,
                    backend_ssl_no_verify=args.backend_ssl_no_verify,
                    backend_poll_interval=args.backend_poll_interval,
                    indexd_connect=args.indexd_connect, indexd_port=args.indexd_port,
                    rpc_host=args.rpc_host, rpc_port=args.rpc_port, rpc_user=args.rpc_user,
                    rpc_password=args.rpc_password, rpc_no_allow_cors=args.rpc_no_allow_cors,
                    requests_timeout=args.requests_timeout,
                    rpc_batch_size=args.rpc_batch_size,
                    check_asset_conservation=not args.no_check_asset_conservation,
                    force=args.force,
                    p2sh_dust_return_pubkey=args.p2sh_dust_return_pubkey,
                    utxo_locks_max_addresses=args.utxo_locks_max_addresses,
                    utxo_locks_max_age=args.utxo_locks_max_age)

    server.initialise_log_config(
        verbose=args.verbose, quiet=args.quiet,
        log_file=args.log_file, api_log_file=args.api_log_file, no_log_files=args.no_log_files,
        testnet=args.testnet, testcoin=args.testcoin, regtest=args.regtest,
        json_log=args.json_log
    )

    # set up logging
    log.set_up(
        verbose=config.VERBOSE,
        quiet=config.QUIET,
        log_file=config.LOG,
        log_in_console=args.action == 'start'
    )

    server.initialise_config(**init_args)

    logger.info(f'Running v{APP_VERSION} of {APP_NAME}.')

    welcome_message(args.action, server_configfile)

    # Bootstrapping
    if args.action == 'bootstrap':
        server.bootstrap(no_confirm=args.no_confirm)

    # PARSING
    elif args.action == 'reparse':
        server.reparse(block_index=args.block_index)

    elif args.action == 'rollback':
        server.rollback(block_index=args.block_index)

    elif args.action == 'kickstart':
        server.kickstart(
            bitcoind_dir=args.bitcoind_dir,
            force=args.force,
            max_queue_size=args.max_queue_size,
            debug_block=args.debug_block)

    elif args.action == 'start':
        server.start_all(catch_up=args.catch_up)

    elif args.action == 'show-params':
        server.show_params()

    elif args.action == 'vacuum':
        server.vacuum()

    elif args.action == 'check-db':
        server.check_database()
    else:
        parser.print_help()

# vim: tabstop=8 expandtab shiftwidth=4 softtabstop=4
