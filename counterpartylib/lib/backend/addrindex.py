import logging
logger = logging.getLogger(__name__)
import sys
import json
import requests
from requests.exceptions import Timeout, ReadTimeout, ConnectionError
import time
import threading
import concurrent.futures
import collections
from functools import lru_cache

from counterpartylib.lib import config, script, util

BACKEND_RPC_BATCH_MAX_WORKERS = 6
MEMPOOL_CACHE_INITIALIZED = False
MEMPOOL_CACHE = None

bitcoin_rpc_session = requests.Session()
bitcoin_rpc_session.headers.update({'content-type': 'application/json'})
raw_transactions_cache = util.DictCache(size=config.BACKEND_RAW_TRANSACTIONS_CACHE_SIZE) #used in getrawtransaction_batch()

class BackendRPCError(Exception):
    pass

def rpc_call(payload, session=None):
    url = config.BACKEND_URL
    response = None
    TRIES = 12

    for i in range(TRIES):
        try:
            response = bitcoin_rpc_session.post(url, data=json.dumps(payload), verify=(not config.BACKEND_SSL_NO_VERIFY), timeout=config.REQUESTS_TIMEOUT)
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
    # Batch query returns a list
    if isinstance(response_json, list):
        return response_json
    if 'error' not in response_json.keys() or response_json['error'] == None:
        return response_json['result']
    elif response_json['error']['code'] == -5:   # RPC_INVALID_ADDRESS_OR_KEY
        raise BackendRPCError('{} Is `txindex` enabled in {} Core?'.format(response_json['error'], config.BTC_NAME))
    elif response_json['error']['code'] in [-28, -8, -2]:  
        # “Verifying blocks...” or “Block height out of range” or “The network does not appear to fully agree!“ 
        logger.debug('Backend not ready. Sleeping for ten seconds.')
        # If Bitcoin Core takes more than `sys.getrecursionlimit() * 10 = 9970`
        # seconds to start, this’ll hit the maximum recursion depth limit.
        time.sleep(10)
        return rpc_call(payload)
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
    
def rpc_batch(request_list):
    responses = collections.deque()
    def get_requests_chunk(l, n):
        n = max(1, n)
        return [l[i:i + n] for i in range(0, len(l), n)]
 
    def make_call(chunk):
        #send a list of requests to bitcoind to be executed
        #note that this is list executed serially, in the same thread in bitcoind
        #e.g. see: https://github.com/bitcoin/bitcoin/blob/master/src/rpcserver.cpp#L939
        responses.extend(rpc_call(chunk))
 
    chunks = get_requests_chunk(request_list, config.RPC_BATCH_SIZE)
    with concurrent.futures.ThreadPoolExecutor(max_workers=BACKEND_RPC_BATCH_MAX_WORKERS) as executor:
        for chunk in chunks:
            executor.submit(make_call, chunk)
    return list(responses)

# TODO: use scriptpubkey_to_address()
@lru_cache(maxsize=config.BACKEND_RAW_TRANSACTIONS_CACHE_SIZE)
def extract_addresses(tx_hash):
    logger.debug('Extract addresses: {}'.format(tx_hash))
    tx = getrawtransaction(tx_hash, verbose=True)
    addresses = set() #use set to avoid duplicates

    for vout in tx['vout']:
        if 'addresses' in vout['scriptPubKey']:
            addresses.add(tuple(vout['scriptPubKey']['addresses']))

    txhash_list = [vin['txid'] for vin in tx['vin']]
    raw_transactions = getrawtransaction_batch(txhash_list, verbose=True)
    for vin in tx['vin']:
        vin_tx = raw_transactions[vin['txid']]
        vout = vin_tx['vout'][vin['vout']]
        if 'addresses' in vout['scriptPubKey']:
            addresses.add(tuple(vout['scriptPubKey']['addresses']))
    return list(addresses), tx

def unconfirmed_transactions(address):
    # NOTE: This operation can be very slow.
    logger.debug('Checking mempool for UTXOs -- extract_addresses cache stats: {}'.format(str(extract_addresses.cache_info())))

    unconfirmed_tx = []
    mempool = MEMPOOL_CACHE
    for index, tx_hash in enumerate(mempool):
        logger.debug('Possible mempool UTXO: {} ({}/{})'.format(tx_hash, index, len(mempool)))
        addresses, tx = extract_addresses(tx_hash)
        if address in addresses:
            unconfirmed_tx.append(tx)
    return unconfirmed_tx

def searchrawtransactions(address, unconfirmed=False):
    # Get unconfirmed transactions.
    if unconfirmed:
        logger.debug('Getting unconfirmed transactions.')
        unconfirmed = unconfirmed_transactions(address)
    else:
        unconfirmed = []

    # Get confirmed transactions.
    try:
        logger.debug('Searching raw transactions.')
        rawtransactions = rpc('searchrawtransactions', [address, 1, 0, 9999999])
    except BackendRPCError as e:
        if str(e) == '404 Not Found':
            raise BackendRPCError('Unknown RPC command: `searchrawtransactions`. Please use a version of {} Core which supports an address index.'.format(config.BTC_NAME))
        else:
            raise BackendRPCError(str(e))
    confirmed = [tx for tx in rawtransactions if 'confirmations' in tx and tx['confirmations'] > 0]

    return unconfirmed + confirmed

def getblockcount():
    return rpc('getblockcount', [])

def getblockhash(blockcount):
    return rpc('getblockhash', [blockcount])

def getblock(block_hash):
    return rpc('getblock', [block_hash, False])

def getrawtransaction(tx_hash, verbose=False):
    return getrawtransaction_batch([tx_hash], verbose=verbose)[tx_hash]

def getrawmempool():
    return rpc('getrawmempool', [])

def sendrawtransaction(tx_hex):
    return rpc('sendrawtransaction', [tx_hex])

def getrawtransaction_batch(txhash_list, verbose=False):
    tx_hash_call_id = {}
    call_id = 0
    payload = []
    noncached_txhashes = []

    # payload for transactions not in cache
    for tx_hash in txhash_list:
        if tx_hash not in raw_transactions_cache:
            payload.append({
                "method": 'getrawtransaction',
                "params": [tx_hash, 1],
                "jsonrpc": "2.0",
                "id": call_id
            })
            noncached_txhashes.append(tx_hash)
            tx_hash_call_id[call_id] = tx_hash
            call_id += 1
    #refresh any/all cache entries that already exist in the cache,
    # so they're not inadvertently removed by another thread before we can consult them
    #(this assumes that the size of the working set for any given workload doesn't exceed the max size of the cache)
    for tx_hash in set(txhash_list).difference(set(noncached_txhashes)):
        raw_transactions_cache.refresh(tx_hash)

    logger.debug("getrawtransaction_batch called, txhash_list size: {} / raw_transactions_cache size: {} / # rpc_batch calls: {}".format(
        len(txhash_list), len(raw_transactions_cache), len(payload)))

    # populate cache
    if len(payload) > 0:
        batch_responses = rpc_batch(payload)
        i = 0
        while i < len(batch_responses):
            response = batch_responses[i]
            if 'error' not in response or response['error'] is None:
                tx_hex = response['result']
                tx_hash = tx_hash_call_id[response['id']]
                
                if tx_hash not in txhash_list: #sanity check
                    raise AssertionError("txhash returned from RPC call ({}) not in txhash_list!".format(tx_hash))
                
                if tx_hash not in raw_transactions_cache:
                    raw_transactions_cache[tx_hash] = tx_hex
            else:
                #TODO: this seems to happen for bogus transactions? Maybe handle it more gracefully than just erroring out?
                raise BackendRPCError('{} (txhash:: {})'.format(response['error'], tx_hash_call_id.get(response.get('id', '??'), '??')))
            i += 1

    # get transactions from cache
    result = {}
    for tx_hash in txhash_list:
        if verbose:
            result[tx_hash] = raw_transactions_cache[tx_hash]
        else:
            result[tx_hash] = raw_transactions_cache[tx_hash]['hex']
    return result

# vim: tabstop=8 expandtab shiftwidth=4 softtabstop=4
