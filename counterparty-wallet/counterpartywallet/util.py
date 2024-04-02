
import decimal
import time
import json
import requests
import logging

from counterpartylib.lib import config
from counterpartylib.lib.util import value_input, value_output

logger = logging.getLogger(config.LOGGER_NAME)
D = decimal.Decimal

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
