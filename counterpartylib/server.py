#! /usr/bin/env python3

import os
import decimal
import sys
import logging
logger = logging.getLogger(__name__)
import time
import dateutil.parser
import calendar
import traceback
import binascii
import socket
import signal
import appdirs
import platform
from urllib.parse import quote_plus as urlencode

from counterpartylib.lib import api, config, util, exceptions, blocks, check, backend, database, transaction, script, log

D = decimal.Decimal


class ConfigurationError(Exception):
    pass


def sigterm_handler(_signo, _stack_frame):
    if _signo == 15:
        signal_name = 'SIGTERM'
    elif _signo == 2:
        signal_name = 'SIGINT'
    else:
        assert False
    logger.info('Received {}.'.format(signal_name))

    if 'api_server' in globals():
        logger.info('Stopping API server.')
        api_server.stop()
        api_status_poller.stop()
    logger.info('Shutting down.')
    logging.shutdown()
    sys.exit(0)
signal.signal(signal.SIGTERM, sigterm_handler)
signal.signal(signal.SIGINT, sigterm_handler)


# Lock database access by opening a socket.
class LockingError(Exception):
    pass
def get_lock():
    logger.info('Acquiring lock.')

    # Cross‐platform.
    if os.name == 'nt' or platform.system() == 'Darwin':    # Windows or OS X
        # Not database‐specific.
        socket_family = socket.AF_INET
        socket_address = ('localhost', 8999)
        error = 'Another copy of server is currently running.'
    else:
        socket_family = socket.AF_UNIX
        socket_address = '\0' + config.DATABASE
        error = 'Another copy of server is currently writing to database {}'.format(config.DATABASE)

    lock_socket = socket.socket(socket_family, socket.SOCK_DGRAM)
    try:
        lock_socket.bind(socket_address)
    except socket.error:
        raise LockingError(error)
    logger.debug('Lock acquired.')


def initialise(database_file=None, log_file=None, api_log_file=None,
                testnet=False, testcoin=False,
                backend_name=None, backend_connect=None, backend_port=None,
                backend_user=None, backend_password=None,
                backend_ssl=False, backend_ssl_no_verify=False,
                backend_poll_interval=None, 
                rpc_host=None, rpc_port=None,
                rpc_user=None, rpc_password=None,
                rpc_no_allow_cors=False,
                force=False, verbose=False,
                requests_timeout=config.DEFAULT_REQUESTS_TIMEOUT,
                rpc_batch_size=config.DEFAULT_RPC_BATCH_SIZE,
                check_asset_conservation=config.DEFAULT_CHECK_ASSET_CONSERVATION,
                backend_ssl_verify=None, rpc_allow_cors=None):

     # Data directory
    data_dir = appdirs.user_data_dir(appauthor=config.XCP_NAME, appname=config.APP_NAME, roaming=True)
    if not os.path.isdir(data_dir):
        os.makedirs(data_dir, mode=0o755)

    # testnet
    if testnet:
        config.TESTNET = testnet
    else:
        config.TESTNET = False

    # testcoin
    if testcoin:
        config.TESTCOIN = testcoin
    else:
        config.TESTCOIN = False

    network = ''
    if config.TESTNET:
        network += '.testnet'
    if config.TESTCOIN:
        network += '.testcoin'

    # Database
    if database_file:
        config.DATABASE = database_file
    else:
        filename = '{}{}.db'.format(config.APP_NAME, network)
        config.DATABASE = os.path.join(data_dir, filename)

    # Log directory
    log_dir = appdirs.user_log_dir(appauthor=config.XCP_NAME, appname=config.APP_NAME)
    if not os.path.isdir(log_dir):
        os.makedirs(log_dir, mode=0o755)

    # Log
    if log_file:
        config.LOG = log_file
    else:
        filename = 'server{}.log'.format(network)
        config.LOG = os.path.join(log_dir, filename)
    logger.debug('Writing server log to file: `{}`'.format(config.LOG))

    if api_log_file:
        config.API_LOG = api_log_file
    else:
        filename = 'server{}.access.log'.format(network)
        config.API_LOG = os.path.join(log_dir, filename)
    logger.debug('Writing API accesses log to file: `{}`'.format(config.API_LOG))

    # Set up logging.
    root_logger = logging.getLogger()    # Get root logger.
    log.set_up(root_logger, verbose=verbose, logfile=config.LOG)
    # Log unhandled errors.
    def handle_exception(exc_type, exc_value, exc_traceback):
        logger.error("Unhandled Exception", exc_info=(exc_type, exc_value, exc_traceback))
    sys.excepthook = handle_exception

    ##############
    # THINGS WE CONNECT TO

    # Backend name
    if backend_name:
        config.BACKEND_NAME = backend_name
    else:
        config.BACKEND_NAME = 'addrindex'
    if config.BACKEND_NAME == 'jmcorgan':
        config.BACKEND_NAME = 'addrindex'

    # Backend RPC host (Bitcoin Core)
    if backend_connect:
        config.BACKEND_CONNECT = backend_connect
    else:
        config.BACKEND_CONNECT = 'localhost'

    # Backend Core RPC port (Bitcoin Core)
    if backend_port:
        config.BACKEND_PORT = backend_port
    else:
        if config.TESTNET:
            if config.BACKEND_NAME == 'btcd':
                config.BACKEND_PORT = config.DEFAULT_BACKEND_PORT_TESTNET_BTCD
            else:
                config.BACKEND_PORT = config.DEFAULT_BACKEND_PORT_TESTNET
        else:
            if config.BACKEND_NAME == 'btcd':
                config.BACKEND_PORT = config.DEFAULT_BACKEND_PORT_BTCD
            else:
                config.BACKEND_PORT = config.DEFAULT_BACKEND_PORT

    try:
        config.BACKEND_PORT = int(config.BACKEND_PORT)
        if not (int(config.BACKEND_PORT) > 1 and int(config.BACKEND_PORT) < 65535):
            raise ConfigurationError('invalid backend API port number')
    except:
        raise ConfigurationError("Please specific a valid port number backend-port configuration parameter")

    # Backend Core RPC user (Bitcoin Core)
    if backend_user:
        config.BACKEND_USER = backend_user
    else:
        config.BACKEND_USER = 'bitcoinrpc'

    # Backend Core RPC password (Bitcoin Core)
    if backend_password:
        config.BACKEND_PASSWORD = backend_password
    else:
        raise ConfigurationError('backend RPC password not set. (Use configuration file or --backend-password=PASSWORD)')

    # Backend Core RPC SSL
    if backend_ssl:
        config.BACKEND_SSL = backend_ssl
    else:
        config.BACKEND_SSL = False  # Default to off.

    # Backend Core RPC SSL Verify
    if backend_ssl_verify is not None:
        logger.warning('The server parameter `backend_ssl_verify` is deprecated. Use `backend_ssl_no_verify` instead.')
        config.BACKEND_SSL_NO_VERIFY = not backend_ssl_verify
    else:
        if backend_ssl_no_verify:
            config.BACKEND_SSL_NO_VERIFY = backend_ssl_no_verify
        else:
            config.BACKEND_SSL_NO_VERIFY = False # Default to on (don't support self‐signed certificates)

    # Backend Poll Interval
    if backend_poll_interval:
        config.BACKEND_POLL_INTERVAL = backend_poll_interval
    else:
        config.BACKEND_POLL_INTERVAL = 0.5

    # Construct backend URL.
    config.BACKEND_URL = config.BACKEND_USER + ':' + config.BACKEND_PASSWORD + '@' + config.BACKEND_CONNECT + ':' + str(config.BACKEND_PORT)
    if config.BACKEND_SSL:
        config.BACKEND_URL = 'https://' + config.BACKEND_URL
    else:
        config.BACKEND_URL = 'http://' + config.BACKEND_URL


    ##############
    # THINGS WE SERVE

    # Server API RPC host
    if rpc_host:
        config.RPC_HOST = rpc_host
    else:
        config.RPC_HOST = 'localhost'

    # The web root directory for API calls, eg. localhost:14000/rpc/
    config.RPC_WEBROOT = '/rpc/'

    # Server API RPC port
    if rpc_port:
        config.RPC_PORT = rpc_port
    else:
        if config.TESTNET:
            if config.TESTCOIN:
                config.RPC_PORT = config.DEFAULT_RPC_PORT_TESTNET + 1
            else:
                config.RPC_PORT = config.DEFAULT_RPC_PORT_TESTNET
        else:
            if config.TESTCOIN:
                config.RPC_PORT = config.DEFAULT_RPC_PORT + 1
            else:
                config.RPC_PORT = config.DEFAULT_RPC_PORT
    try:
        config.RPC_PORT = int(config.RPC_PORT)
        if not (int(config.RPC_PORT) > 1 and int(config.RPC_PORT) < 65535):
            raise ConfigurationError('invalid server API port number')
    except:
        raise ConfigurationError("Please specific a valid port number rpc-port configuration parameter")

    # Server API RPC user
    if rpc_user:
        config.RPC_USER = rpc_user
    else:
        config.RPC_USER = 'rpc'

    # Server API RPC password
    if rpc_password:
        config.RPC_PASSWORD = rpc_password
        config.RPC = 'http://' + urlencode(config.RPC_USER) + ':' + urlencode(config.RPC_PASSWORD) + '@' + config.RPC_HOST + ':' + str(config.RPC_PORT) + config.RPC_WEBROOT
    else:
        config.RPC = 'http://' + config.RPC_HOST + ':' + str(config.RPC_PORT) + config.RPC_WEBROOT

    # RPC CORS
    if rpc_allow_cors is not None:
        logger.warning('The server parameter `rpc_allow_cors` is deprecated. Use `rpc_no_allow_cors` instead.')
        config.RPC_NO_ALLOW_CORS = not rpc_allow_cors
    else:
        if rpc_no_allow_cors:
            config.RPC_NO_ALLOW_CORS = rpc_no_allow_cors
        else:
            config.RPC_NO_ALLOW_CORS = False

    config.REQUESTS_TIMEOUT = requests_timeout
    config.RPC_BATCH_SIZE = rpc_batch_size
    config.CHECK_ASSET_CONSERVATION = check_asset_conservation

    ##############
    # OTHER SETTINGS

    # skip checks
    if force:
        config.FORCE = force
    else:
        config.FORCE = False

    # Encoding
    if config.TESTCOIN:
        config.PREFIX = b'XX'                   # 2 bytes (possibly accidentally created)
    else:
        config.PREFIX = b'CNTRPRTY'             # 8 bytes

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

    logger.info('Running v{} of counterparty-lib.'.format(config.VERSION_STRING))

    if config.FORCE:
        logger.warning('THE OPTION `--force` IS NOT FOR USE ON PRODUCTION SYSTEMS.')

    # Lock
    if not config.FORCE:
        get_lock()

    # Database
    logger.info('Connecting to database.')
    db = database.get_connection(read_only=False)

    util.CURRENT_BLOCK_INDEX = blocks.last_db_index(db)

    return db


def connect_to_backend():
    if not config.FORCE:
        logger.info('Connecting to backend.')
        backend.getblockcount()


def start_all(db):

    # Backend.
    connect_to_backend()

    # API Status Poller.
    api_status_poller = api.APIStatusPoller()
    api_status_poller.daemon = True
    api_status_poller.start()

    # API Server.
    api_server = api.APIServer()
    api_server.daemon = True
    api_server.start()

    # Server.
    blocks.follow(db)


def reparse(db, block_index=None):
    connect_to_backend()
    blocks.reparse(db, block_index=block_index)


def kickstart(db, bitcoind_dir):
    blocks.kickstart(db, bitcoind_dir=bitcoind_dir)


def generate_move_random_hash(move):
    move = int(move).to_bytes(2, byteorder='big')
    random_bin = os.urandom(16)
    move_random_hash_bin = util.dhash(random_bin + move)
    return binascii.hexlify(random_bin).decode('utf8'), binascii.hexlify(move_random_hash_bin).decode('utf8')

# vim: tabstop=8 expandtab shiftwidth=4 softtabstop=4
