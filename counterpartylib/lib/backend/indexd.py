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

from counterpartylib.lib import config, util

raw_transactions_cache = util.DictCache(size=config.BACKEND_RAW_TRANSACTIONS_CACHE_SIZE)  # used in getrawtransaction_batch()


class BackendRPCError(Exception):
    pass

class IndexdRPCError(Exception):
    pass


def rpc_call(payload):
    """Calls to bitcoin core and returns the response"""
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
            logger.debug('Could not connect to backend at `{}`. (Try {}/{})'.format(util.clean_url_for_log(url), i+1, TRIES))
            time.sleep(5)

    if response == None:
        if config.TESTNET:
            network = 'testnet'
        elif config.REGTEST:
            network = 'regtest'
        else:
            network = 'mainnet'
        raise BackendRPCError('Cannot communicate with backend at `{}`. (server is set to run on {}, is backend?)'.format(util.clean_url_for_log(url), network))
    elif response.status_code in (401,):
        raise BackendRPCError('Authorization error connecting to {}: {} {}'.format(util.clean_url_for_log(url), response.status_code, response.reason))
    elif response.status_code not in (200, 500):
        raise BackendRPCError(str(response.status_code) + ' ' + response.reason)

    # Handle json decode errors
    try:
        response_json = response.json()
    except json.decoder.JSONDecodeError:
        raise BackendRPCError('Received invalid JSON from backend with a response of {}'.format(str(response.status_code) + ' ' + response.reason))

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
        raise BackendRPCError('Error connecting to {}: {}'.format(util.clean_url_for_log(url), response_json['error']))

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
    logger.debug('extract_addresses, txs: %d' % (len(txhash_list), ))
    tx_hashes_tx = getrawtransaction_batch(txhash_list, verbose=True)

    return extract_addresses_from_txlist(tx_hashes_tx, getrawtransaction_batch)


def extract_addresses_from_txlist(tx_hashes_tx, _getrawtransaction_batch):
    """
    helper for extract_addresses, seperated so we can pass in a mocked _getrawtransaction_batch for test purposes
    """

    logger.debug('extract_addresses_from_txlist, txs: %d' % (len(tx_hashes_tx.keys()), ))
    tx_hashes_addresses = {}
    tx_inputs_hashes = set()  # use set to avoid duplicates

    for tx_hash, tx in tx_hashes_tx.items():
        tx_hashes_addresses[tx_hash] = set()
        for vout in tx['vout']:
            if 'addresses' in vout['scriptPubKey']:
                tx_hashes_addresses[tx_hash].update(tuple(vout['scriptPubKey']['addresses']))

        tx_inputs_hashes.update([vin['txid'] for vin in tx['vin']])

    logger.debug('extract_addresses, input TXs: %d' % (len(tx_inputs_hashes), ))

    # chunk txs to avoid huge memory spikes
    for tx_inputs_hashes_chunk in util.chunkify(list(tx_inputs_hashes), config.BACKEND_RAW_TRANSACTIONS_CACHE_SIZE):
        raw_transactions = _getrawtransaction_batch(tx_inputs_hashes_chunk, verbose=True)
        for tx_hash, tx in tx_hashes_tx.items():
            for vin in tx['vin']:
                vin_tx = raw_transactions.get(vin['txid'], None)

                if not vin_tx:
                    continue

                vout = vin_tx['vout'][vin['vout']]
                if 'addresses' in vout['scriptPubKey']:
                    tx_hashes_addresses[tx_hash].update(tuple(vout['scriptPubKey']['addresses']))

    return tx_hashes_addresses, tx_hashes_tx

def getblockcount():
    return rpc('getblockcount', [])

def getblockhash(blockcount):
    return rpc('getblockhash', [blockcount])

def getblock(block_hash):
    return rpc('getblock', [block_hash, False])

def getrawtransaction(tx_hash, verbose=False, skip_missing=False):
    return getrawtransaction_batch([tx_hash], verbose=verbose, skip_missing=skip_missing)[tx_hash]

def getrawmempool():
    return rpc('getrawmempool', [])

def fee_per_kb(conf_target, mode, nblocks=None):
    """
    :param conf_target:
    :param mode:
    :return: fee_per_kb in satoshis, or None when unable to determine
    """
    if nblocks is None and conf_target is None:
        conf_target = nblocks

    feeperkb = rpc('estimatesmartfee', [conf_target, mode])

    if 'errors' in feeperkb and feeperkb['errors'][0] == 'Insufficient data or no feerate found':
        return None

    return int(max(feeperkb['feerate'] * config.UNIT, config.DEFAULT_FEE_PER_KB_ESTIMATE_SMART))

def sendrawtransaction(tx_hex):
    return rpc('sendrawtransaction', [tx_hex])

GETRAWTRANSACTION_MAX_RETRIES=2
def getrawtransaction_batch(txhash_list, verbose=False, skip_missing=False, _retry=0):
    _logger = logger.getChild("getrawtransaction_batch")

    if len(txhash_list) > config.BACKEND_RAW_TRANSACTIONS_CACHE_SIZE:
        #don't try to load in more than BACKEND_RAW_TRANSACTIONS_CACHE_SIZE entries in a single call
        txhash_list_chunks = util.chunkify(txhash_list, config.BACKEND_RAW_TRANSACTIONS_CACHE_SIZE)
        txes = {}
        for txhash_list_chunk in txhash_list_chunks:
            txes.update(getrawtransaction_batch(txhash_list_chunk, verbose=verbose, skip_missing=skip_missing))
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

    _logger.debug("getrawtransaction_batch: txhash_list size: {} / raw_transactions_cache size: {} / # getrawtransaction calls: {}".format(
        len(txhash_list), len(raw_transactions_cache), len(payload)))

    # populate cache
    if len(payload) > 0:
        batch_responses = rpc_batch(payload)
        for response in batch_responses:
            if 'error' not in response or response['error'] is None:
                tx_hex = response['result']
                tx_hash = tx_hash_call_id[response['id']]
                raw_transactions_cache[tx_hash] = tx_hex
            elif skip_missing and 'error' in response and response['error']['code'] == -5:
                raw_transactions_cache[tx_hash] = None
                logging.debug('Missing TX with no raw info skipped (txhash: {}): {}'.format(
                    tx_hash_call_id.get(response.get('id', '??'), '??'), response['error']))
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
                result[tx_hash] = raw_transactions_cache[tx_hash]['hex'] if raw_transactions_cache[tx_hash] is not None else None
        except KeyError as e: #shows up most likely due to finickyness with addrindex not always returning results that we need...
            _logger.warning("tx missing in rawtx cache: {} -- txhash_list size: {}, hash: {} / raw_transactions_cache size: {} / # rpc_batch calls: {} / txhash in noncached_txhashes: {} / txhash in txhash_list: {} -- list {}".format(
                e, len(txhash_list), hashlib.md5(json.dumps(list(txhash_list)).encode()).hexdigest(), len(raw_transactions_cache), len(payload),
                tx_hash in noncached_txhashes, tx_hash in txhash_list, list(txhash_list.difference(noncached_txhashes)) ))
            if  _retry < GETRAWTRANSACTION_MAX_RETRIES: #try again
                time.sleep(0.05 * (_retry + 1)) # Wait a bit, hitting the index non-stop may cause it to just break down... TODO: Better handling
                r = getrawtransaction_batch([tx_hash], verbose=verbose, skip_missing=skip_missing, _retry=_retry+1)
                result[tx_hash] = r[tx_hash]
            else:
                raise #already tried again, give up

    return result

def get_unspent_txouts(source):
    return indexd_rpc_call('/a/'+source+'/utxos')

def search_raw_transactions(address, unconfirmed=True):
    all_transactions = indexd_rpc_call('/a/'+address+'/txs?verbose=1')

    if unconfirmed:
        return all_transactions

    # filter for confirmed transactions only
    confirmed_transactions = list(filter(lambda t: 'confirmations' in t and t['confirmations'] > 0, all_transactions))
    return confirmed_transactions



def getindexblocksbehind():
    status = indexd_rpc_call('/status')
    if status['ready']:
        return 0
    if status['blocksBehind']:
        return status['blocksBehind']
    raise IndexdRPCError('Unknown status for indexd')

def indexd_rpc_call(path):
    url = config.INDEXD_URL+path

    response = None
    try:
        response = requests.get(url, headers={'content-type': 'application/json'},
            timeout=config.REQUESTS_TIMEOUT)
    except (Timeout, ReadTimeout, ConnectionError):
        logger.debug('Could not connect to backend at `{}`.'.format(util.clean_url_for_log(url),))

    if response == None:
        if config.TESTNET:
            network = 'testnet'
        elif config.REGTEST:
            network = 'regtest'
        else:
            network = 'mainnet'
        raise IndexdRPCError('Cannot communicate with {} indexd server at `{}`.'.format(network, util.clean_url_for_log(url)))
    elif response.status_code == 400:
        raise IndexdRPCError('Indexd returned error: {} {} {}'.format(response.status_code, response.reason, response.text))
    elif response.status_code not in (200, 500):
        raise IndexdRPCError("Bad response from {}: {} {}".format(util.clean_url_for_log(url), response.status_code, response.reason))

    # Return result, with error handling.
    response_json = response.json()
    if isinstance(response_json, (list, tuple)) or 'error' not in response_json.keys() or response_json['error'] == None:
        return response_json
    else:
        raise IndexdRPCError('{}'.format(response_json['error']))

# vim: tabstop=8 expandtab shiftwidth=4 softtabstop=4
