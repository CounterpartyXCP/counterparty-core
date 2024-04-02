#!/usr/bin/env python
import os
import argparse
import configparser
import appdirs
import codecs
import configparser, platform
import logging
from decimal import Decimal as D

from counterpartylib.lib import config

logger = logging.getLogger(config.LOGGER_NAME)

# generate commented config file from arguments list (client.CONFIG_ARGS and server.CONFIG_ARGS) and known values
def generate_config_file(filename, config_args, known_config={}, overwrite=False):
    if not overwrite and os.path.exists(filename):
        return

    config_dir = os.path.dirname(os.path.abspath(filename))
    if not os.path.exists(config_dir):
        os.makedirs(config_dir, mode=0o755)

    config_lines = []
    config_lines.append('[Default]')
    config_lines.append('')

    for arg in config_args:
        key = arg[0][-1].replace('--', '')
        value = None

        if key in known_config:
            value = known_config[key]
        elif 'default' in arg[1]:
            value = arg[1]['default']

        if value is None:
            value = ''
        elif isinstance(value, bool):
            value = '1' if value else '0'
        elif isinstance(value, (float, D)):
            value = format(value, '.8f')

        if 'default' in arg[1] or value == '':
            key = f'# {key}'

        config_lines.append(f"{key} = {value}\t\t\t\t# {arg[1]['help']}")

    with open(filename, 'w', encoding='utf8') as config_file:
        config_file.writelines("\n".join(config_lines))
    # user and group have "rw" access
    os.chmod(filename, 0o660) # nosec B103


def extract_old_config():
    old_config = {}

    old_appdir = appdirs.user_config_dir(appauthor='Counterparty', appname='counterpartyd', roaming=True)
    old_configfile = os.path.join(old_appdir, 'counterpartyd.conf')

    if os.path.exists(old_configfile):
        configfile = configparser.SafeConfigParser(allow_no_value=True, inline_comment_prefixes=('#', ';'))
        configfile.read(old_configfile)
        if 'Default' in configfile:
            for key in configfile['Default']:
                new_key = key.replace('backend-rpc-', 'backend-')
                new_key = new_key.replace('blockchain-service-name', 'backend-name')
                new_value = configfile['Default'][key].replace('jmcorgan', 'addrindex')
                old_config[new_key] = new_value

    return old_config


def extract_bitcoincore_config():
    bitcoincore_config = {}

    # Figure out the path to the bitcoin.conf file
    if platform.system() == 'Darwin':
        btc_conf_file = os.path.expanduser('~/Library/Application Support/Bitcoin/')
    elif platform.system() == 'Windows':
        btc_conf_file = os.path.join(os.environ['APPDATA'], 'Bitcoin')
    else:
        btc_conf_file = os.path.expanduser('~/.bitcoin')
    btc_conf_file = os.path.join(btc_conf_file, 'bitcoin.conf')

    # Extract contents of bitcoin.conf to build service_url
    if os.path.exists(btc_conf_file):
        conf = {}
        with open(btc_conf_file, 'r') as fd:
            # Bitcoin Core accepts empty rpcuser, not specified in btc_conf_file
            for line in fd.readlines():
                if '#' in line or '=' not in line:
                    continue
                k, v = line.split('=', 1)
                conf[k.strip()] = v.strip()

            config_keys = {
                'rpcport': 'backend-port',
                'rpcuser': 'backend-user',
                'rpcpassword': 'backend-password',
                'rpcssl': 'backend-ssl'
            }

            for bitcoind_key in config_keys:
                if bitcoind_key in conf:
                    counterparty_key = config_keys[bitcoind_key]
                    bitcoincore_config[counterparty_key] = conf[bitcoind_key]

    return bitcoincore_config


def get_server_known_config():
    server_known_config = {}

    bitcoincore_config = extract_bitcoincore_config()
    server_known_config.update(bitcoincore_config)

    old_config = extract_old_config()
    server_known_config.update(old_config)

    return server_known_config


# generate client config from server config
def server_to_client_config(server_config):
    client_config = {}

    config_keys = {
        'backend-connect': 'wallet-connect',
        'backend-port': 'wallet-port',
        'backend-user': 'wallet-user',
        'backend-password': 'wallet-password',
        'backend-ssl': 'wallet-ssl',
        'backend-ssl-verify': 'wallet-ssl-verify',
        'rpc-host': 'counterparty-rpc-connect',
        'rpc-port': 'counterparty-rpc-port',
        'rpc-user': 'counterparty-rpc-user',
        'rpc-password': 'counterparty-rpc-password'
    }

    for server_key in config_keys:
        if server_key in server_config:
            client_key = config_keys[server_key]
            client_config[client_key] = server_config[server_key]

    return client_config


def generate_client_config_files(client_config_args):
    configdir = appdirs.user_config_dir(appauthor=config.XCP_NAME, appname=config.APP_NAME, roaming=True)

    client_configfile = os.path.join(configdir, 'client.conf')
    if not os.path.exists(client_configfile):
        server_known_config = get_server_known_config()
        client_known_config = server_to_client_config(server_known_config)
        generate_config_file(client_configfile, client_config_args, client_known_config)

    return client_configfile


def generate_server_config_file(server_config_args):
    configdir = appdirs.user_config_dir(appauthor=config.XCP_NAME, appname=config.APP_NAME, roaming=True)

    server_configfile = os.path.join(configdir, 'server.conf')
    if not os.path.exists(server_configfile):
        # extract known configuration
        server_known_config = get_server_known_config()
        generate_config_file(server_configfile, server_config_args, server_known_config)

    return server_configfile


def read_config_file(default_config_file, config_file_path=None):
    if not config_file_path:
        config_dir = appdirs.user_config_dir(appauthor=config.XCP_NAME, appname=config.APP_NAME, roaming=True)
        if not os.path.isdir(config_dir):
            os.makedirs(config_dir, mode=0o755)
        config_file_path = os.path.join(config_dir, default_config_file)

    # clean BOM
    bufsize = 4096
    bomlen = len(codecs.BOM_UTF8)
    with codecs.open(config_file_path, 'r+b') as fp:
        chunk = fp.read(bufsize)
        if chunk.startswith(codecs.BOM_UTF8):
            i = 0
            chunk = chunk[bomlen:]
            while chunk:
                fp.seek(i)
                fp.write(chunk)
                i += len(chunk)
                fp.seek(bomlen, os.SEEK_CUR)
                chunk = fp.read(bufsize)
            fp.seek(-bomlen, os.SEEK_CUR)
            fp.truncate()

    logger.debug(f'Loading configuration file: `{config_file_path}`')
    configfile = configparser.SafeConfigParser(allow_no_value=True, inline_comment_prefixes=('#', ';'))
    with codecs.open(config_file_path, 'r', encoding='utf8') as fp:
        configfile.readfp(fp)

    if not 'Default' in configfile:
        configfile['Default'] = {}
    
    return configfile


def add_config_arguments(parser, args, configfile, add_default=False):
    for arg in args:
        if add_default:
            key = arg[0][-1].replace('--', '')
            if 'action' in arg[1] and arg[1]['action'] == 'store_true' and key in configfile['Default']:
                arg[1]['default'] = configfile['Default'].getboolean(key)
            elif key in configfile['Default'] and configfile['Default'][key]:
                arg[1]['default'] = configfile['Default'][key]
            elif key in configfile['Default'] and arg[1].get('nargs', '') == '?' and 'const' in arg[1]:
                arg[1]['default'] = arg[1]['const']  # bit of a hack
        else:
            arg[1]['default'] = argparse.SUPPRESS
        parser.add_argument(*arg[0], **arg[1])
