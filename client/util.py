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

logger = logging.getLogger(__name__)
D = decimal.Decimal

from client import config

# Obsolete in Python 3.4, with enum module.
BET_TYPE_NAME = {0: 'BullCFD', 1: 'BearCFD', 2: 'Equal', 3: 'NotEqual'}
BET_TYPE_ID = {'BullCFD': 0, 'BearCFD': 1, 'Equal': 2, 'NotEqual': 3}

dhash = lambda x: hashlib.sha256(hashlib.sha256(x).digest()).digest()

rpc_sessions = {}

class RPCError(Exception):
    pass

def rpc(url, method, params=None, ssl_verify=False):
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
    TRIES = 12
    for i in range(TRIES):
        try:
            response = rpc_session.post(url, data=json.dumps(payload), headers=headers, verify=ssl_verify)
            if i > 0:
                logger.debug('Successfully connected.', file=sys.stderr)
            break
        except requests.exceptions.SSLError as e:
            raise e
        except requests.exceptions.ConnectionError:
            logger.debug('Could not connect to {}. (Try {}/{})'.format(url, i+1, TRIES))
            time.sleep(5)

    if response == None:
        raise RPCError('Cannot communicate with {}.'.format(url))
    elif response.status_code not in (200, 500):
        raise RPCError(str(response.status_code) + ' ' + response.reason)

    # Return result, with error handling.
    response_json = response.json()
    if 'error' not in response_json.keys() or response_json['error'] == None:
        return response_json['result']
    else:
        raise RPCError('{}'.format(response_json['error']))

def api(method, params=None):
    return rpc(config.COUNTERPARTY_RPC, method, params=params, ssl_verify=config.COUNTERPARTY_RPC_SSL_VERIFY)

class QuantityError(Exception): pass
class AssetError(Exception): pass

def is_divisible(asset):
    if asset in (config.BTC, config.XCP):
        return True
    else:
        sql = '''SELECT * FROM issuances WHERE (status = ? AND asset = ?)'''
        bindings = ['valid', asset]
        issuances = api('sql', {'query': sql, 'bindings': bindings})

        if not issuances: raise AssetError('No such asset: {}'.format(asset))
        return issuances[0]['divisible']

def get_asset_id(asset_name, block_index):
    # we don't need that here, right ?
    '''
    if not enabled('hotfix_numeric_assets'):
        return generate_asset_id(asset_name, block_index)
    '''
    sql = '''SELECT * FROM assets WHERE asset_name = ?'''
    bindings = [asset_name]
    assets = api('sql', {'query': sql, 'bindings': bindings})
    if len(assets) == 1:
        return int(assets[0]['asset_id'])
    else:
        raise AssetError('No such asset: {}'.format(asset_name))

def value_in(quantity, asset, divisible=None):

    if asset == 'leverage':
        return round(quantity)

    if asset in ('value', 'fraction', 'price', 'odds'):
        return float(quantity)  # TODO: Float?!

    if divisible == None:
        divisible = is_divisible(asset)

    if divisible:
        quantity = D(quantity) * config.UNIT
        if quantity == quantity.to_integral():
            return int(quantity)
        else:
            raise QuantityError('divisible assets have only eight decimal places of precision.')
    else:
        quantity = D(quantity)
        if quantity != round(quantity):
            raise QuantityError('Fractional quantities of indivisible assets.')
        return round(quantity)

def value_out(quantity, asset, divisible=None):

    def norm(num, places):
        # Round only if necessary.
        num = round(num, places)
        fmt = '{:.' + str(places) + 'f}'
        num = fmt.format(num)
        return num.rstrip('0')+'0' if num.rstrip('0')[-1] == '.' else num.rstrip('0')

    if asset == 'fraction':
        return str(norm(D(quantity) * D(100), 6)) + '%'

    if asset in ('leverage', 'value', 'price', 'odds'):
        return norm(quantity, 6)

    if divisible == None:
        divisible = is_divisible(asset)

    if divisible:
        quantity = D(quantity) / D(config.UNIT)
        if quantity == quantity.to_integral():
            return str(quantity) + '.0'  # For divisible assets, display the decimal point.
        else:
            return norm(quantity, 8)
    else:
        quantity = D(quantity)
        if quantity != round(quantity):
            raise QuantityError('Fractional quantities of indivisible assets.')
        return round(quantity)


ID_SEPARATOR = '_'
def make_id(hash_1, hash_2):
    return hash_1 + ID_SEPARATOR + hash_2
def parse_id(match_id):
    assert match_id[64] == ID_SEPARATOR
    return match_id[:64], match_id[65:] # UTF-8 encoding means that the indices are doubled.

def isodt(epoch_time):
    try:
        return datetime.fromtimestamp(epoch_time, tzlocal()).isoformat()
    except OSError:
        return '<datetime>'

def hexlify(x):
    return binascii.hexlify(x).decode('ascii')



# vim: tabstop=8 expandtab shiftwidth=4 softtabstop=4