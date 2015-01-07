#! /usr/bin/env python3

import os
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

from lib import config, api, util, exceptions, blocks, check, backend, database, transaction, script, log

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
        error = 'Another copy of {} is currently running.'.format(config.XCP_CLIENT)
    else:
        socket_family = socket.AF_UNIX
        socket_address = '\0' + config.DATABASE
        error = 'Another copy of {} is currently writing to database {}'.format(config.XCP_CLIENT, config.DATABASE)

    lock_socket = socket.socket(socket_family, socket.SOCK_DGRAM)
    try:
        lock_socket.bind(socket_address)
    except socket.error:
        raise LockingError(error)
    logger.debug('Lock acquired.')

def set_options(
        data_dir=None, backend_name=None, backend_connect=None, backend_port=None,
        backend_user=None, backend_password=None,
        backend_ssl=False, backend_ssl_verify=True,
        rpc_host=None, rpc_port=None, rpc_user=None, rpc_password=None,
        rpc_allow_cors=None, log_file=None, config_file=None,
        database_file=None, testnet=False, testcoin=False, force=False,
        broadcast_tx_mainnet=None, backend_poll_interval=None, verbose=False):

    if force:
        config.FORCE = force
    else:
        config.FORCE = False

    # Data directory
    if not data_dir:
        config.DATA_DIR = appdirs.user_config_dir(appauthor=config.XCP_NAME, appname=config.XCP_CLIENT, roaming=True)
    else:
        config.DATA_DIR = os.path.expanduser(data_dir)
    if not os.path.isdir(config.DATA_DIR):
        os.mkdir(config.DATA_DIR)

    # Configuration file
    config_file_changed = False
    configfile = configparser.ConfigParser()
    if config_file:
        config_path = config_file
    else:
        config_path = os.path.join(config.DATA_DIR, '{}.conf'.format(config.XCP_CLIENT))
    configfile.read(config_path)
    if not 'Default' in configfile:
        configfile['Default'] = {}

    # testnet
    if testnet:
        config.TESTNET = testnet
    elif 'testnet' in configfile['Default']:
        config.TESTNET = configfile['Default'].getboolean('testnet')
    else:
        config.TESTNET = False

    # testcoin
    if testcoin:
        config.TESTCOIN = testcoin
    elif 'testcoin' in configfile['Default']:
        config.TESTCOIN = configfile['Default'].getboolean('testcoin')
    else:
        config.TESTCOIN = False

    ##############
    # THINGS WE CONNECT TO

    # Backend name
    if backend_name:
        config.BACKEND_NAME = backend_name
    elif 'backend-name' in configfile['Default'] and configfile['Default']['backend-name']:
        config.BACKEND_NAME = configfile['Default']['backend-name']
    else:
        config.BACKEND_NAME = 'addrindex'
    if config.BACKEND_NAME == 'jmcorgan':
        config.BACKEND_NAME = 'addrindex'

    # Backend RPC host (Bitcoin Core)
    if backend_connect:
        config.BACKEND_CONNECT = backend_connect
    elif 'backend-connect' in configfile['Default'] and configfile['Default']['backend-connect']:
        config.BACKEND_CONNECT = configfile['Default']['backend-connect']
    else:
        config.BACKEND_CONNECT = 'localhost'

    # Backend Core RPC port (Bitcoin Core)
    if backend_port:
        config.BACKEND_PORT = backend_port
    elif 'backend-port' in configfile['Default'] and configfile['Default']['backend-port']:
        config.BACKEND_PORT = configfile['Default']['backend-port']
    else:
        if config.TESTNET:
            config.BACKEND_PORT = config.DEFAULT_BACKEND_PORT_TESTNET
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
    elif 'backend-user' in configfile['Default'] and configfile['Default']['backend-user']:
        config.BACKEND_USER = configfile['Default']['backend-user']
    else:
        config.BACKEND_USER = 'bitcoinrpc'

    # Backend Core RPC password (Bitcoin Core)
    if backend_password:
        config.BACKEND_PASSWORD = backend_password
    elif 'backend-password' in configfile['Default'] and configfile['Default']['backend-password']:
        config.BACKEND_PASSWORD = configfile['Default']['backend-password']
    else:
        raise ConfigurationError('backend RPC password not set. (Use configuration file or --backend-password=PASSWORD)')

    # Backend Core RPC SSL
    if backend_ssl:
        config.BACKEND_SSL = backend_ssl
    elif 'backend-ssl' in configfile['Default'] and configfile['Default']['backend-ssl']:
        config.BACKEND_SSL = configfile['Default']['backend-ssl']
    else:
        config.BACKEND_SSL = False  # Default to off.

    # Backend Core RPC SSL Verify
    if backend_ssl_verify:
        config.BACKEND_SSL_VERIFY = backend_ssl_verify
    elif 'backend-ssl-verify' in configfile['Default'] and configfile['Default']['backend-ssl-verify']:
        config.BACKEND_SSL_VERIFY = configfile['Default']['backend-ssl-verify']
    else:
        config.BACKEND_SSL_VERIFY = False # Default to off (support self‐signed certificates)

    # Backend Poll Interval
    if backend_poll_interval:
        config.BACKEND_POLL_INTERVAL = backend_poll_interval
    elif 'backend-poll-interval' in configfile['Default'] and configfile['Default']['backend-poll-interval']:
        config.BACKEND_POLL_INTERVAL = configfile['Default']['backend-poll-interval']
    else:
        config.BACKEND_POLL_INTERVAL = 2.0

    # Construct backend URL.
    config.BACKEND_URL = config.BACKEND_USER + ':' + config.BACKEND_PASSWORD + '@' + config.BACKEND_CONNECT + ':' + str(config.BACKEND_PORT)
    if config.BACKEND_SSL:
        config.BACKEND_URL = 'https://' + config.BACKEND_URL
    else:
        config.BACKEND_URL = 'http://' + config.BACKEND_URL


    ##############
    # THINGS WE SERVE

    # counterpartyd API RPC host
    if rpc_host:
        config.RPC_HOST = rpc_host
    elif 'rpc-host' in configfile['Default'] and configfile['Default']['rpc-host']:
        config.RPC_HOST = configfile['Default']['rpc-host']
    else:
        config.RPC_HOST = 'localhost'

    # counterpartyd API RPC port
    if rpc_port:
        config.RPC_PORT = rpc_port
    elif 'rpc-port' in configfile['Default'] and configfile['Default']['rpc-port']:
        config.RPC_PORT = configfile['Default']['rpc-port']
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
            raise ConfigurationError('invalid counterpartyd API port number')
    except:
        raise ConfigurationError("Please specific a valid port number rpc-port configuration parameter")

    #  counterpartyd API RPC user
    if rpc_user:
        config.RPC_USER = rpc_user
    elif 'rpc-user' in configfile['Default'] and configfile['Default']['rpc-user']:
        config.RPC_USER = configfile['Default']['rpc-user']
    else:
        config.RPC_USER = 'rpc'

    #  counterpartyd API RPC password
    if rpc_password:
        config.RPC_PASSWORD = rpc_password
    elif 'rpc-password' in configfile['Default'] and configfile['Default']['rpc-password']:
        config.RPC_PASSWORD = configfile['Default']['rpc-password']
    else:
        config_file_changed = True
        config.RPC_PASSWORD = util.hexlify(util.dhash(os.urandom(16)))
        configfile['Default']['rpc-password'] = config.RPC_PASSWORD
        logger.info('Generated password for counterpartyd RPC API: {}'.format(config.RPC_PASSWORD))
        logger.info('Saved in configuration file: {}'.format(config_file))
        # raise ConfigurationError('RPC password not set. (Use configuration file or --rpc-password=PASSWORD)')

    config.RPC = 'http://' + config.RPC_USER + ':' + config.RPC_PASSWORD + '@' + config.RPC_HOST + ':' + str(config.RPC_PORT)

    # RPC CORS
    if rpc_allow_cors:
        config.RPC_ALLOW_CORS = rpc_allow_cors
    elif 'rpc-allow-cors' in configfile['Default'] and configfile['Default']['rpc-allow-cors']:
        config.RPC_ALLOW_CORS = configfile['Default'].getboolean('rpc-allow-cors')
    else:
        config.RPC_ALLOW_CORS = True

    ##############
    # OTHER SETTINGS

    # Log
    if log_file:
        config.LOG = log_file
    elif 'log-file' in configfile['Default'] and configfile['Default']['log-file']:
        config.LOG = configfile['Default']['log-file']
    else:
        string = config.XCP_CLIENT
        if config.TESTNET:
            string += '.testnet'
        if config.TESTCOIN:
            string += '.testcoin'
        config.LOG = os.path.join(config.DATA_DIR, string + '.log')

    # Encoding
    if config.TESTCOIN:
        config.PREFIX = b'XX'                   # 2 bytes (possibly accidentally created)
    else:
        config.PREFIX = b'CNTRPRTY'             # 8 bytes

    # Database
    if database_file:
        config.DATABASE = database_file
    elif 'database-file' in configfile['Default'] and configfile['Default']['database-file']:
        config.DATABASE = configfile['Default']['database-file']
    else:
        string = '{}.'.format(config.XCP_CLIENT) + str(config.VERSION_MAJOR)
        if config.TESTNET:
            string += '.testnet'
        if config.TESTCOIN:
            string += '.testcoin'
        config.DATABASE = os.path.join(config.DATA_DIR, string + '.db')

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

    # method used to broadcast signed transactions. bitcoind or bci (default: bitcoind)
    if broadcast_tx_mainnet:
        config.BROADCAST_TX_MAINNET = broadcast_tx_mainnet
    elif 'broadcast-tx-mainnet' in configfile['Default']:
        config.BROADCAST_TX_MAINNET = configfile['Default']['broadcast-tx-mainnet']
    else:
        config.BROADCAST_TX_MAINNET = '{}'.format(config.BTC_CLIENT)

    # Save generated settings.
    if config_file_changed:
        with open(config_path, 'w') as f:
            configfile.write(f)

    # Set up logging.
    # Log unhandled errors.
    log.set_up(verbose)
    def handle_exception(exc_type, exc_value, exc_traceback):
        logger.error("Unhandled Exception", exc_info=(exc_type, exc_value, exc_traceback))
    sys.excepthook = handle_exception

    logger.info('Running v{} of counterpartyd.'.format(config.VERSION_STRING, config.XCP_CLIENT))

    if config.FORCE:
        logger.warning('THE OPTION `--force` IS NOT FOR USE ON PRODUCTION SYSTEMS.')


def generate_move_random_hash(move):
    move = int(move).to_bytes(2, byteorder='big')
    random_bin = os.urandom(16)
    move_random_hash_bin = util.dhash(random_bin + move)
    return binascii.hexlify(random_bin).decode('utf8'), binascii.hexlify(move_random_hash_bin).decode('utf8')

# vim: tabstop=8 expandtab shiftwidth=4 softtabstop=4
