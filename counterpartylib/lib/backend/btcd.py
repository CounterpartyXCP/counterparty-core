import logging
logger = logging.getLogger(__name__)
import sys
import json

from counterpartylib.lib import script
from counterpartylib.lib import config

import requests
import time
import json

from functools import lru_cache

bitcoin_rpc_session = None

class BackendRPCError(Exception):
    pass

def rpc(method, params):
    url = config.BACKEND_URL
    headers = {'content-type': 'application/json'}
    payload = {
        "method": method,
        "params": params,
        "jsonrpc": "2.0",
        "id": 0,
    }
    
    global bitcoin_rpc_session
    if not bitcoin_rpc_session:
        bitcoin_rpc_session = requests.Session()
    response = None
    TRIES = 12
    for i in range(TRIES):
        try:
            response = bitcoin_rpc_session.post(url, data=json.dumps(payload), headers=headers, verify=config.BACKEND_SSL_VERIFY)
            if i > 0:
                logger.debug('Successfully connected.')
            break
        except requests.exceptions.SSLError as e:
            raise e
        except requests.exceptions.ConnectionError:
            logger.debug('Could not connect to backend at `{}`. (Try {}/{})'.format(url, i+1, TRIES))
            time.sleep(5)

    if response == None:
        if config.TESTNET:
            network = 'testnet'
        else:
            network = 'mainnet'
        raise BackendRPCError('Cannot communicate with backend at `{}`. (server is set to run on {}, is backend?)'.format(url, network))
    elif response.status_code not in (200, 500):
        raise BackendRPCError(str(response.status_code) + ' ' + response.reason)

    # Return result, with error handling.
    response_json = response.json()
    if 'error' not in response_json.keys() or response_json['error'] == None:
        return response_json['result']
    elif response_json['error']['code'] == -5:   # RPC_INVALID_ADDRESS_OR_KEY
        raise BackendRPCError('{} Is `txindex` enabled in {} Core?'.format(response_json['error'], config.BTC_NAME))
    elif response_json['error']['code'] == -4:   # Unknown private key (locked wallet?)
        raise BackendRPCError('Unknown private key. (Locked wallet?)')
    elif response_json['error']['code'] == -28:   # “Verifying blocks...”
        logger.debug('Backend not ready. Sleeping for ten seconds.')
        # If Bitcoin Core takes more than `sys.getrecursionlimit() * 10 = 9970`
        # seconds to start, this’ll hit the maximum recursion depth limit.
        time.sleep(10)
        return rpc(method, params)
    else:
        raise BackendRPCError('{}'.format(response_json['error']))

def extract_addresses(tx_hash):
    pass

def searchrawtransactions(address):
    logger.debug('Searching raw transactions.')

    try:
        rawtransactions = rpc('searchrawtransaction', [address, True, 0, 9999999])
    except BackendRPCError as e:
        if str(e) == '404 Not Found':
            raise BackendRPCError('Unknown RPC command: `searchrawtransaction`. Please use a version of {} Core which supports an address index.'.format(config.BTC_NAME))
        else:
            raise BackendRPCError(str(e))
    
    return rawtransactions

def getblockcount():
    return rpc('getblockcount', [])

def getblockhash(blockcount):
    return rpc('getblockhash', [blockcount])

@lru_cache(maxsize=4096)
def getblock(block_hash):
    return rpc('getblock', [block_hash, False])

@lru_cache(maxsize=4096)
def getrawtransaction(tx_hash, verbose=False):
    return rpc('getrawtransaction', [tx_hash, 1 if verbose else 0])

def getrawmempool():
    return rpc('getrawmempool', [])

# vim: tabstop=8 expandtab shiftwidth=4 softtabstop=4
