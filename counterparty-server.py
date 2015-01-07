#! /usr/bin/env python3

import os
import argparse
import decimal
import sys
import logging
logger = logging.getLogger(__name__)
import time
import dateutil.parser
import calendar
import configparser
import traceback
import binascii
import socket
import signal
import appdirs
import platform

from lib import config, api, util, exceptions, blocks, check, backend, database, transaction, script, log, server

if __name__ == '__main__':
    if os.name == 'nt':
        from lib import util_windows
        #patch up cmd.exe's "challenged" (i.e. broken/non-existent) UTF-8 logging
        util_windows.fix_win32_unicode()

    # Parse command-line arguments.
    parser = argparse.ArgumentParser(prog=config.XCP_CLIENT, description='the reference implementation of the {} protocol'.format(config.XCP_NAME))
    parser.add_argument('-V', '--version', action='version', version="{} v{}".format(config.XCP_CLIENT, config.VERSION_STRING))

    parser.add_argument('-v', '--verbose', dest='verbose', action='store_true', help='sets log level to DEBUG instead of WARNING')
    parser.add_argument('--testnet', action='store_true', help='use {} testnet addresses and block numbers'.format(config.BTC_NAME))
    parser.add_argument('--testcoin', action='store_true', help='use the test {} network on every blockchain'.format(config.XCP_NAME))
    
    parser.add_argument('--data-dir', help='the directory in which to keep the database, config file and log file, by default')
    parser.add_argument('--database-file', help='the location of the SQLite3 database')
    parser.add_argument('--config-file', help='the location of the configuration file')
    parser.add_argument('--log-file', help='the location of the log file')

    parser.add_argument('--backend-name', help='the backend name to connect to')
    parser.add_argument('--backend-connect', help='the hostname or IP of the backend server')
    parser.add_argument('--backend-port', type=int, help='the backend port to connect to')
    parser.add_argument('--backend-user', help='the username used to communicate with backend')
    parser.add_argument('--backend-password', help='the password used to communicate with backend')
    parser.add_argument('--backend-ssl', action='store_true', help='use SSL to connect to backend (default: false)')
    parser.add_argument('--backend-ssl-verify', action='store_true', help='verify SSL certificate of backend; disallow use of self‐signed certificates (default: false)')
    parser.add_argument('--backend-poll-interval', type=float, help='poll interval, in seconds (default: 2.0)')

    parser.add_argument('--rpc-host', help='the IP of the interface to bind to for providing JSON-RPC API access (0.0.0.0 for all interfaces)')
    parser.add_argument('--rpc-port', type=int, help='port on which to provide the {} JSON-RPC API'.format(config.XCP_CLIENT))
    parser.add_argument('--rpc-user', help='required username to use the {} JSON-RPC API (via HTTP basic auth)'.format(config.XCP_CLIENT))
    parser.add_argument('--rpc-password', help='required password (for rpc-user) to use the {} JSON-RPC API (via HTTP basic auth)'.format(config.XCP_CLIENT))
    parser.add_argument('--rpc-allow-cors', action='store_true', default=True, help='Allow ajax cross domain request')

    subparsers = parser.add_subparsers(dest='action', help='the action to be taken')

    parser_server = subparsers.add_parser('server', help='run the server')
    parser_server.add_argument('--force', action='store_true', help='skip backend check, version check, process lock (NOT FOR USE ON PRODUCTION SYSTEMS)')

    parser_reparse = subparsers.add_parser('reparse', help='reparse all transactions in the database')
    parser_reparse.add_argument('--force', action='store_true', help='skip backend check, version check, process lock (NOT FOR USE ON PRODUCTION SYSTEMS)')

    parser_rollback = subparsers.add_parser('rollback', help='rollback database')
    parser_rollback.add_argument('block_index', type=int, help='the index of the last known good block')
    parser_rollback.add_argument('--force', action='store_true', help='skip backend check, version check, process lock (NOT FOR USE ON PRODUCTION SYSTEMS)')

    parser_kickstart = subparsers.add_parser('kickstart', help='rapidly bring database up to the present')
    parser_kickstart.add_argument('--bitcoind-dir', help='Bitcoin Core data directory')
    parser_kickstart.add_argument('--force', action='store_true', help='skip backend check, version check, singleton check (NOT FOR USE ON PRODUCTION SYSTEMS)')

    args = parser.parse_args()

    # TODO: Hack
    try:
        args.force
    except (NameError, AttributeError):
        args.force = None

    # Configuration
    server.set_options(data_dir=args.data_dir,
                backend_name=args.backend_name,
                backend_connect=args.backend_connect,
                backend_port=args.backend_port,
                backend_user=args.backend_user,
                backend_password=args.backend_password,
                backend_ssl=args.backend_ssl,
                backend_ssl_verify=args.backend_ssl_verify,
                rpc_host=args.rpc_host, rpc_port=args.rpc_port, rpc_user=args.rpc_user,
                rpc_password=args.rpc_password, rpc_allow_cors=args.rpc_allow_cors,
                log_file=args.log_file, config_file=args.config_file,
                database_file=args.database_file, testnet=args.testnet,
                testcoin=args.testcoin, force=args.force, backend_poll_interval=args.backend_poll_interval,
                verbose=args.verbose)

    # Backend
    if args.action in ('server', 'reparse', 'rollback') and not config.FORCE:
        logger.info('Connecting to backend.')
        backend.getblockcount()

    # Lock
    if args.action in ('rollback', 'reparse', 'server', 'kickstart') and not config.FORCE:
        server.get_lock()

    # Database
    logger.info('Connecting to database.')
    db = database.get_connection(read_only=False)

    util.CURRENT_BLOCK_INDEX = blocks.last_db_index(db)

    # PARSING
    if args.action == 'reparse':
        blocks.reparse(db)

    elif args.action == 'rollback':
        blocks.reparse(db, block_index=args.block_index)

    elif args.action == 'kickstart':
        blocks.kickstart(db, bitcoind_dir=args.bitcoind_dir)

    elif args.action == 'server':
        api_status_poller = api.APIStatusPoller()
        api_status_poller.daemon = True
        api_status_poller.start()

        api_server = api.APIServer()
        api_server.daemon = True
        api_server.start()

        # Check blockchain explorer.
        if not config.FORCE:
            time_wait = 10
            num_tries = 10
            for i in range(1, num_tries + 1):
                try:
                    backend.check()
                except Exception as e: # TODO
                    logging.exception(e)
                    logging.warn("Blockchain backend (%s) not yet initialized. Waiting %i seconds and trying again (try %i of %i)..." % (
                        config.BACKEND_NAME, time_wait, i, num_tries))
                    time.sleep(time_wait)
                else:
                    break
            else:
                raise Exception("Blockchain backend (%s) not initialized! Aborting startup after %i tries." % (
                    config.BACKEND_NAME, num_tries))

        blocks.follow(db)

    else:
        parser.print_help()

# vim: tabstop=8 expandtab shiftwidth=4 softtabstop=4
