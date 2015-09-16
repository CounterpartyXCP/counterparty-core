import logging
logger = logging.getLogger(__name__)
import sys
import json

from counterpartylib.lib import script
from counterpartylib.lib import config

import requests
from requests.exceptions import Timeout, ReadTimeout, ConnectionError
import time
import json

from functools import lru_cache

bitcoin_rpc_session = None

class BackendRPCError(Exception):
    pass

def rpc_call(payload):
    url = config.BACKEND_URL
    headers = {'content-type': 'application/json'}

    global bitcoin_rpc_session
    if not bitcoin_rpc_session:
        bitcoin_rpc_session = requests.Session()
    response = None
    TRIES = 12
    for i in range(TRIES):
        try:
            response = bitcoin_rpc_session.post(url, data=json.dumps(payload), headers=headers, verify=(not config.BACKEND_SSL_NO_VERIFY), timeout=config.REQUESTS_TIMEOUT)
            if i > 0:
                logger.debug('Successfully connected.')
            break
        except (Timeout, ReadTimeout, ConnectionError):
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
    else:
        raise BackendRPCError('{}'.format(response_json['error']))

def rpc(method, params):
    payload = {
        "method": method,
        "params": params,
        "jsonrpc": "2.0",
        "id": 0,
    }
    return rpc_call(payload)

def rpc_batch(payload):

    def get_chunks(l, n):
        n = max(1, n)
        return [l[i:i + n] for i in range(0, len(l), n)]

    responses = []

    # TODO: waiting for https://github.com/btcsuite/btcd/issues/329
    '''
    chunks = get_chunks(payload, config.RPC_BATCH_SIZE)
    for chunk in chunks:
        responses += rpc_call(chunk)
    '''
    for query in payload:
        responses.append(rpc_call(query))

    return responses

def extract_addresses(txhash_list):
    raise NotImplementedError

def searchrawtransactions(address, unconfirmed=False):
    logger.debug('Searching raw transactions.')

    try:
        rawtransactions = rpc('searchrawtransactions', [address, 1, 0, 9999999])
    except BackendRPCError as e:
        raise BackendRPCError(str(e))
    
    return rawtransactions

def unconfirmed_transactions():
    raise NotImplementedError

def refresh_unconfirmed_transactions_cache():
    raise NotImplementedError

def getblockcount():
    return rpc('getblockcount', [])

def getblockhash(blockcount):
    return rpc('getblockhash', [blockcount])

@lru_cache(maxsize=64)      # Assume each block is 50 KB.
def getblock(block_hash):
    return rpc('getblock', [block_hash, False])

@lru_cache(maxsize=16384)   # Assume each transaction is 4 KB.
def getrawtransaction(tx_hash, verbose=False):
    return getrawtransaction_batch([tx_hash], verbose=verbose)[tx_hash]

def getrawmempool():
    return rpc('getrawmempool', [])

# TODO: move to __init__.py
RAW_TRANSACTIONS_CACHE = {}
RAW_TRANSACTIONS_CACHE_KEYS = []
RAW_TRANSACTIONS_CACHE_SIZE = 10000

def getrawtransaction_batch(txhash_list, verbose=False):
    tx_hash_call_id = {}
    call_id = 0
    payload = []
    # payload for transactions not in cache
    for tx_hash in txhash_list:
        if tx_hash not in RAW_TRANSACTIONS_CACHE:
            payload.append({
                "method": 'getrawtransaction',
                "params": [tx_hash, 1],
                "jsonrpc": "2.0",
                "id": call_id
            })
            tx_hash_call_id[call_id] = tx_hash
            call_id += 1

    # populate cache
    if len(payload) > 0:
        batch_responses = rpc_batch(payload)
        for tx_hex in batch_responses:
            tx_hash = tx_hex['txid']
            if tx_hash not in RAW_TRANSACTIONS_CACHE:
                RAW_TRANSACTIONS_CACHE[tx_hash] = tx_hex
                RAW_TRANSACTIONS_CACHE_KEYS.append(tx_hash)

    # get transactions from cache
    result = {}
    for tx_hash in txhash_list:
        if verbose:
            result[tx_hash] = RAW_TRANSACTIONS_CACHE[tx_hash]
        else:
            result[tx_hash] = RAW_TRANSACTIONS_CACHE[tx_hash]['hex']

    # remove oldest hashes from cache
    while len(RAW_TRANSACTIONS_CACHE_KEYS) > RAW_TRANSACTIONS_CACHE_SIZE:
        first_hash = RAW_TRANSACTIONS_CACHE_KEYS[0]
        del(RAW_TRANSACTIONS_CACHE[first_hash])
        RAW_TRANSACTIONS_CACHE_KEYS.pop(0) 

    return result

# vim: tabstop=8 expandtab shiftwidth=4 softtabstop=4
