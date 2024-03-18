#! /usr/bin/python3

import sys
import os
import threading
import decimal
import time
import json
import re
import requests
import collections
import logging
import binascii
from datetime import datetime
from dateutil.tz import tzlocal
import argparse
import configparser
import appdirs
import tarfile
import urllib.request
import shutil
import codecs
import tempfile

from halo import Halo
from termcolor import colored, cprint

from counterpartylib import server
from counterpartylib.lib import config, check
from counterpartylib.lib.util import value_input, value_output

logger = logging.getLogger(config.LOGGER_NAME)
D = decimal.Decimal

OK_GREEN = colored("[OK]", "green")
SPINNER_STYLE = "bouncingBar"

rpc_sessions = {}

class JsonDecimalEncoder(json.JSONEncoder):
    def default(self, o):
        if isinstance(o,  D):
            return str(o)
        return super(JsonDecimalEncoder, self).default(o)


json_dump = lambda x: json.dumps(x, sort_keys=True, indent=4, cls=JsonDecimalEncoder)
json_print = lambda x: print(json_dump(x))

class RPCError(Exception):
    pass
class AssetError(Exception):
    pass

def rpc(url, method, params=None, ssl_verify=False, tries=1):
    headers = {'content-type': 'application/json'}
    payload = {
        "method": method,
        "params": params,
        "jsonrpc": "2.0",
        "id": 0,
    }

    if url not in rpc_sessions:
        rpc_session = requests.Session()
        rpc_sessions[url] = rpc_session
    else:
       	rpc_session = rpc_sessions[url]

    response = None
    for i in range(tries):
        try:
            response = rpc_session.post(url, data=json.dumps(payload), headers=headers, verify=ssl_verify, timeout=config.REQUESTS_TIMEOUT)
            if i > 0:
                logger.debug('Successfully connected.')
            break
        except requests.exceptions.SSLError as e:
            raise e
        except requests.exceptions.Timeout as e:
            raise e
        except requests.exceptions.ConnectionError:
            logger.debug(f'Could not connect to {url}. (Try {i+1}/{tries})')
            time.sleep(5)

    if response == None:
        raise RPCError(f'Cannot communicate with {url}.')
    elif response.status_code not in (200, 500):
        raise RPCError(str(response.status_code) + ' ' + response.reason + ' ' + response.text)

    # Return result, with error handling.
    response_json = response.json()
    if 'error' not in response_json.keys() or response_json['error'] == None:
        return response_json['result']
    else:
        raise RPCError(f"{response_json['error']}")

def api(method, params=None):
    return rpc(config.COUNTERPARTY_RPC, method, params=params, ssl_verify=config.COUNTERPARTY_RPC_SSL_VERIFY)

def wallet_api(method, params=None):
    return rpc(config.WALLET_URL, method, params=params, ssl_verify=config.WALLET_SSL_VERIFY)

def is_divisible(asset):
    if asset in (config.BTC, config.XCP, 'leverage', 'value', 'fraction', 'price', 'odds'):
        return True
    else:
        sql = '''SELECT * FROM issuances WHERE (status = ? AND asset = ?)'''
        bindings = ['valid', asset]
        issuances = api('sql', {'query': sql, 'bindings': bindings})

        if not issuances: raise AssetError(f'No such asset: {asset}')
        return issuances[0]['divisible']

def value_in(quantity, asset, divisible=None):
    if divisible is None:
        divisible = is_divisible(asset)
    return value_input(quantity, asset, divisible)

def value_out(quantity, asset, divisible=None):
    if divisible is None:
        divisible = is_divisible(asset)
    return value_output(quantity, asset, divisible)


# Set default values of command line arguments with config file
def add_config_arguments(arg_parser, config_args, default_config_file, config_file_arg_name='config_file'):
    cmd_args = arg_parser.parse_known_args()[0]

    config_file = getattr(cmd_args, config_file_arg_name, None)
    if not config_file:
        config_dir = appdirs.user_config_dir(appauthor=config.XCP_NAME, appname=config.APP_NAME, roaming=True)
        if not os.path.isdir(config_dir):
            os.makedirs(config_dir, mode=0o755)
        config_file = os.path.join(config_dir, default_config_file)

    # clean BOM
    bufsize = 4096
    bomlen = len(codecs.BOM_UTF8)
    with codecs.open(config_file, 'r+b') as fp:
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

    logger.debug(f'Loading configuration file: `{config_file}`')
    configfile = configparser.SafeConfigParser(allow_no_value=True, inline_comment_prefixes=('#', ';'))
    with codecs.open(config_file, 'r', encoding='utf8') as fp:
        configfile.readfp(fp)

    if not 'Default' in configfile:
        configfile['Default'] = {}

    # Initialize default values with the config file.
    for arg in config_args:
        key = arg[0][-1].replace('--', '')
        if 'action' in arg[1] and arg[1]['action'] == 'store_true' and key in configfile['Default']:
            arg[1]['default'] = configfile['Default'].getboolean(key)
        elif key in configfile['Default'] and configfile['Default'][key]:
            arg[1]['default'] = configfile['Default'][key]
        elif key in configfile['Default'] and arg[1].get('nargs', '') == '?' and 'const' in arg[1]:
            arg[1]['default'] = arg[1]['const']  # bit of a hack
        arg_parser.add_argument(*arg[0], **arg[1])

# vim: tabstop=8 expandtab shiftwidth=4 softtabstop=4
