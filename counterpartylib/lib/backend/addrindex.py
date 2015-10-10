import logging
logger = logging.getLogger(__name__)
import sys
import os
import json
import requests
from requests.exceptions import Timeout, ReadTimeout, ConnectionError
import time
import threading
import concurrent.futures
import collections
import binascii
import hashlib

from counterpartylib.lib import config, script, util

raw_transactions_cache = util.DictCache(size=config.BACKEND_RAW_TRANSACTIONS_CACHE_SIZE) #used in getrawtransaction_batch()
unconfirmed_transactions_cache = None

class BackendRPCError(Exception):
    pass

def rpc_call(payload):
    url = config.BACKEND_URL
    response = None
    TRIES = 12

    for i in range(TRIES):
        try:
            response = requests.post(url, data=json.dumps(payload), headers={'content-type': 'application/json'},
                verify=(not config.BACKEND_SSL_NO_VERIFY), timeout=config.REQUESTS_TIMEOUT)
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

    def make_call(chunk):
        #send a list of requests to bitcoind to be executed
        #note that this is list executed serially, in the same thread in bitcoind
        #e.g. see: https://github.com/bitcoin/bitcoin/blob/master/src/rpcserver.cpp#L939
        responses.extend(rpc_call(chunk))
 
    chunks = util.chunkify(request_list, config.RPC_BATCH_SIZE)
    with concurrent.futures.ThreadPoolExecutor(max_workers=config.BACKEND_RPC_BATCH_NUM_WORKERS) as executor:
        for chunk in chunks:
            executor.submit(make_call, chunk)
    return list(responses)

def extract_addresses(txhash_list):
    tx_hashes_tx = getrawtransaction_batch(txhash_list, verbose=True)
    tx_hashes_addresses = {}
    tx_inputs_hashes = set() #use set to avoid duplicates
    
    for tx_hash, tx in tx_hashes_tx.items():
        tx_hashes_addresses[tx_hash] = set()
        for vout in tx['vout']:
            if 'addresses' in vout['scriptPubKey']:
                tx_hashes_addresses[tx_hash].update(tuple(vout['scriptPubKey']['addresses']))
        tx_inputs_hashes.update([vin['txid'] for vin in tx['vin']])

    raw_transactions = getrawtransaction_batch(list(tx_inputs_hashes), verbose=True)
    for tx_hash, tx in tx_hashes_tx.items():
        for vin in tx['vin']:
            vin_tx = raw_transactions[vin['txid']]
            if vin_tx is None: #bogus transaction
                continue
            vout = vin_tx['vout'][vin['vout']]
            if 'addresses' in vout['scriptPubKey']:
                tx_hashes_addresses[tx_hash].update(tuple(vout['scriptPubKey']['addresses']))

    return tx_hashes_addresses, tx_hashes_tx

def unconfirmed_transactions(address):
    logger.debug("unconfirmed_transactions called: %s" % address)
    if unconfirmed_transactions_cache is None:
        raise Exception("Unconfirmed transactions cache is not initialized")
    return unconfirmed_transactions_cache.get(address, [])

def refresh_unconfirmed_transactions_cache(mempool_txhash_list):
    # NOTE: This operation can be very slow.
    global unconfirmed_transactions_cache

    unconfirmed_txes = {}
    tx_hashes_addresses, tx_hashes_tx = extract_addresses(mempool_txhash_list)
    for tx_hash, addresses in tx_hashes_addresses.items():
        for address in addresses:
            if address not in unconfirmed_txes:
                unconfirmed_txes[address] = []
            unconfirmed_txes[address].append(tx_hashes_tx[tx_hash])
    unconfirmed_transactions_cache = unconfirmed_txes
    logger.debug('Unconfirmed transactions cache refreshed ({} entries, from {} supported mempool txes)'.format(
        len(unconfirmed_transactions_cache), len(mempool_txhash_list)))

def searchrawtransactions(address, unconfirmed=False):
    # Get unconfirmed transactions.
    if unconfirmed:
        logger.debug('searchrawtransactions: Getting unconfirmed transactions.')
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

def getrawtransaction_batch(txhash_list, verbose=False, _recursing=False):
    if len(txhash_list) > config.BACKEND_RAW_TRANSACTIONS_CACHE_SIZE:
        #don't try to load in more than BACKEND_RAW_TRANSACTIONS_CACHE_SIZE entries in a single call
        txhash_list_chunks = util.chunkify(txhash_list, config.BACKEND_RAW_TRANSACTIONS_CACHE_SIZE)
        txes = {}
        for txhash_list_chunk in txhash_list_chunks:
            txes.update(getrawtransaction_batch(txhash_list_chunk, verbose=verbose))
        return txes
    
    tx_hash_call_id = {}
    payload = []
    noncached_txhashes = set()
    
    txhash_list = set(txhash_list)

    # payload for transactions not in cache
    for tx_hash in txhash_list:
        if tx_hash not in raw_transactions_cache:
            call_id = binascii.hexlify(os.urandom(5)).decode('utf8')
            payload.append({
                "method": 'getrawtransaction',
                "params": [tx_hash, 1],
                "jsonrpc": "2.0",
                "id": call_id
            })
            noncached_txhashes.add(tx_hash)
            tx_hash_call_id[call_id] = tx_hash
    #refresh any/all cache entries that already exist in the cache,
    # so they're not inadvertently removed by another thread before we can consult them
    #(this assumes that the size of the working set for any given workload doesn't exceed the max size of the cache)
    for tx_hash in txhash_list.difference(noncached_txhashes):
        raw_transactions_cache.refresh(tx_hash)

    logger.debug("getrawtransaction_batch: txhash_list size: {} / raw_transactions_cache size: {} / # getrawtransaction calls: {}".format(
        len(txhash_list), len(raw_transactions_cache), len(payload)))

    # populate cache
    if len(payload) > 0:
        batch_responses = rpc_batch(payload)
        for response in batch_responses:
            if 'error' not in response or response['error'] is None:
                tx_hex = response['result']
                tx_hash = tx_hash_call_id[response['id']]
                raw_transactions_cache[tx_hash] = tx_hex
            else:
                #TODO: this seems to happen for bogus transactions? Maybe handle it more gracefully than just erroring out?
                raise BackendRPCError('{} (txhash:: {})'.format(response['error'], tx_hash_call_id.get(response.get('id', '??'), '??')))

    # get transactions from cache
    result = {}
    for tx_hash in txhash_list:
        try:
            if verbose:
                result[tx_hash] = raw_transactions_cache[tx_hash]
            else:
                result[tx_hash] = raw_transactions_cache[tx_hash]['hex']
        except KeyError as e: #shows up most likely due to finickyness with addrindex not always returning results that we need...
            logger.debug("tx missing in rawtx cache: {} -- txhash_list size: {}, hash: {} / raw_transactions_cache size: {} / # rpc_batch calls: {} / txhash in noncached_txhashes: {} / txhash in txhash_list: {} -- list {}".format(
                e, len(txhash_list), hashlib.md5(json.dumps(list(txhash_list)).encode()).hexdigest(), len(raw_transactions_cache), len(payload),
                tx_hash in noncached_txhashes, tx_hash in txhash_list, list(txhash_list.difference(noncached_txhashes)) ))
            if not _recursing: #try again
                r = getrawtransaction_batch([tx_hash], verbose=verbose, _recursing=True)
                result[tx_hash] = r[tx_hash]
            else:
                raise #already tried again, give up

    return result

# vim: tabstop=8 expandtab shiftwidth=4 softtabstop=4
