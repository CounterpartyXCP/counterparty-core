from typing import Dict, Optional
import logging
import sys
import json
import queue
import time
import threading
import socket
import concurrent.futures
import collections
import hashlib
import functools
import requests
from requests.exceptions import Timeout, ReadTimeout
import bitcoin.wallet

from counterpartylib.lib import config, util, ledger, exceptions

logger = logging.getLogger(config.LOGGER_NAME)

READ_BUF_SIZE = 65536
SOCKET_TIMEOUT = 20.0
BACKEND_PING_TIME = 30.0
BACKOFF_START = 1
BACKOFF_MAX = 8
BACKOFF_FACTOR = 2

INDEXER_THREAD = None
raw_transactions_cache = util.DictCache(size=config.BACKEND_RAW_TRANSACTIONS_CACHE_SIZE)  # used in getrawtransaction_batch()

class BackendRPCError(Exception):
    pass

class AddrIndexRsRPCError(Exception):
    pass

class AddrIndexRsEmptyResponseError(Exception):
    pass

def rpc_call(payload):
    """Calls to bitcoin core and returns the response"""
    url = config.BACKEND_URL
    response = None

    tries = 0
    while True:
        try:
            tries += 1
            response = requests.post(url, data=json.dumps(payload), headers={'content-type': 'application/json'},
                verify=(not config.BACKEND_SSL_NO_VERIFY), timeout=config.REQUESTS_TIMEOUT)

            if response == None:
                if config.TESTNET:
                    network = 'testnet'
                elif config.REGTEST:
                    network = 'regtest'
                else:
                    network = 'mainnet'
                raise BackendRPCError(f'Cannot communicate with backend at `{util.clean_url_for_log(url)}`. (server is set to run on {network}, is backend?)')
            elif response.status_code in (401,):
                raise BackendRPCError(f'Authorization error connecting to {util.clean_url_for_log(url)}: {response.status_code} {response.reason}')
            elif response.status_code not in (200, 500):
                raise BackendRPCError(str(response.status_code) + ' ' + response.reason)

            else:
                break
        except KeyboardInterrupt:
            logger.warning('Interrupted by user')
            exit(0)
        except (Timeout, ReadTimeout, ConnectionError):
            logger.debug(f'Could not connect to backend at `{util.clean_url_for_log(url)}`. (Try {tries})')
            time.sleep(5)

    # Handle json decode errors
    try:
        response_json = response.json()
    except json.decoder.JSONDecodeError as e:
        raise BackendRPCError(f"Received invalid JSON from backend with a response of {str(response.status_code) + ' ' + response.reason}")

    # Batch query returns a list
    if isinstance(response_json, list):
        return response_json
    if 'error' not in response_json.keys() or response_json['error'] == None:
        return response_json['result']
    elif response_json['error']['code'] == -5:   # RPC_INVALID_ADDRESS_OR_KEY
        raise BackendRPCError(f"{response_json['error']} Is `txindex` enabled in {config.BTC_NAME} Core?")
    elif response_json['error']['code'] in [-28, -8, -2]:
        # “Verifying blocks...” or “Block height out of range” or “The network does not appear to fully agree!“
        logger.debug('Backend not ready. Sleeping for ten seconds.')
        # If Bitcoin Core takes more than `sys.getrecursionlimit() * 10 = 9970`
        # seconds to start, this’ll hit the maximum recursion depth limit.
        time.sleep(10)
        return rpc_call(payload)
    else:
        raise BackendRPCError(f"Error connecting to {util.clean_url_for_log(url)}: {response_json['error']}")

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
    logger.debug(f'extract_addresses, txs: {len(txhash_list)}')
    tx_hashes_tx = getrawtransaction_batch(txhash_list, verbose=True)

    return extract_addresses_from_txlist(tx_hashes_tx, getrawtransaction_batch)

def extract_addresses_from_txlist(tx_hashes_tx, _getrawtransaction_batch):
    """
    helper for extract_addresses, seperated so we can pass in a mocked _getrawtransaction_batch for test purposes
    """

    logger.debug(f'extract_addresses_from_txlist, txs: {len(tx_hashes_tx.keys())}')
    tx_hashes_addresses = {}
    tx_inputs_hashes = set()  # use set to avoid duplicates

    for tx_hash, tx in tx_hashes_tx.items():
        tx_hashes_addresses[tx_hash] = set()
        for vout in tx['vout']:
            if 'addresses' in vout['scriptPubKey']:
                tx_hashes_addresses[tx_hash].update(tuple(vout['scriptPubKey']['addresses']))

        tx_inputs_hashes.update([vin['txid'] for vin in tx['vin']])

    logger.debug(f'extract_addresses, input TXs: {len(tx_inputs_hashes)}')

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

@functools.lru_cache
def getrawtransaction(tx_hash, verbose=False, skip_missing=False):
    logger.debug(f'Cache miss on transaction {tx_hash}!')
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
MONOTONIC_CALL_ID = 0
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
            #call_id = binascii.hexlify(os.urandom(5)).decode('utf8') # Don't drain urandom
            global MONOTONIC_CALL_ID
            MONOTONIC_CALL_ID = MONOTONIC_CALL_ID + 1
            call_id = f"{MONOTONIC_CALL_ID}"
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

    _logger.debug(f"getrawtransaction_batch: txhash_list size: {len(txhash_list)} / raw_transactions_cache size: {len(raw_transactions_cache)} / # getrawtransaction calls: {len(payload)}")

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
                missing_tx_hash = tx_hash_call_id.get(response.get('id', '??'), '??')
                logger.debug(f"Missing TX with no raw info skipped (txhash: {missing_tx_hash}): {response['error']}")
            else:
                #TODO: this seems to happen for bogus transactions? Maybe handle it more gracefully than just erroring out?
                raise BackendRPCError(f"{response['error']} (txhash:: {tx_hash_call_id.get(response.get('id', '??'), '??')})")

    # get transactions from cache
    result = {}
    for tx_hash in txhash_list:
        try:
            if verbose:
                result[tx_hash] = raw_transactions_cache[tx_hash]
            else:
                result[tx_hash] = raw_transactions_cache[tx_hash]['hex'] if raw_transactions_cache[tx_hash] is not None else None
        except KeyError as e: #shows up most likely due to finickyness with addrindex not always returning results that we need...
            logger.error("Key error in addrindexrs still exists!!!!!")
            _hash = hashlib.md5(json.dumps(list(txhash_list)).encode(), usedforsecurity=False).hexdigest()
            _list = list(txhash_list.difference(noncached_txhashes))
            _logger.warning(f"tx missing in rawtx cache: {e} -- txhash_list size: {len(txhash_list)}, hash: {_hash} / raw_transactions_cache size: {len(raw_transactions_cache)} / # rpc_batch calls: {len(payload)} / txhash in noncached_txhashes: {tx_hash in noncached_txhashes} / txhash in txhash_list: {tx_hash in txhash_list} -- list {_list}")
            if  _retry < GETRAWTRANSACTION_MAX_RETRIES: #try again
                time.sleep(0.05 * (_retry + 1)) # Wait a bit, hitting the index non-stop may cause it to just break down... TODO: Better handling
                r = getrawtransaction_batch([tx_hash], verbose=verbose, skip_missing=skip_missing, _retry=_retry+1)
                result[tx_hash] = r[tx_hash]
            else:
                raise #already tried again, give up

    return result


class SocketManager():
    def __init__(self, host, port, name):
        self.host = host
        self.port = port
        self.socket = None
        self.name = name
        self.backoff = BACKOFF_START
        self.max_retries = 10


    def connect(self):
        while True:
            try:
                logger.debug(f'{self.name} -- Opening socket at `{self.host}:{self.port}`')
                self.socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
                self.socket.settimeout(SOCKET_TIMEOUT)
                self.socket.connect((self.host, self.port))
                self.backoff = BACKOFF_START
                break
            except ConnectionRefusedError as e:
                logger.debug(f'{self.name} -- Connection refused. Retry in {self.backoff:d}s')
                time.sleep(self.backoff)
                self.backoff = min(self.backoff * BACKOFF_FACTOR, BACKOFF_MAX)
            except Exception as e:
                logger.exception(f"{self.name} -- connecting to `{self.host}:{self.port}`: {e}")
                sys.exit(1)

    def send(self, msg) -> bool:
        if not self.socket:
            logger.debug(f"{self.name} -- `send` called without a socket.")
            return False

        for attempt in range(1, self.max_retries + 1):
            try:
                logger.debug(f"{self.name} -- send msg: {msg}")
                self.socket.send(msg)
                return True
            except Exception as e:
                logger.exception(f"{self.name} -- send exception:  {e}")
                self.recover_connection()
                if attempt < self.max_retries:
                    logger.debug(f'{self.name} -- retrying send in {self.backoff * attempt}s')
                    time.sleep(min(self.backoff * attempt, BACKOFF_MAX))

        logger.debug(f"{self.name} -- Failed to send message after {self.max_retries} attempts.")
        return False


    def recv(self, buffer_size=READ_BUF_SIZE) -> Optional[Dict]:

        if not self.socket:
            logger.debug(f"{self.name} -- `rcv` called without a socket.")
            return

        response = b""
        while True:
            try:
                logger.debug("{self.name} -- waiting for chunk")
                chunk = self.socket.recv(buffer_size)
                if not chunk:
                    raise Exception(f"{self.name} -- Empty response from `{self.name}`")
                response += chunk
                logger.debug(f"{self.name} -- chunk received: {chunk}, response: {response}")

                try:
                    json_ = json.loads(response.decode('utf-8'))
                    logger.debug(f"{self.name} -- received message: {json_}")
                    return json_
                except json.JSONDecodeError:
                    logger.debug(f"{self.name} -- json decode error -- continuing")
                    continue

            except Exception as e:
                logger.exception(f"{self.name} -- Error receiving message: {e}")
                logger.debug(f"{self.name} -- recovering connection")
                self.recover_connection()
                return None

    def close(self):

        if not self.socket:
            logger.debug(f"{self.name} -- `close` called without a socket.")
            return

        try:
            logger.debug(f"{self.name} -- Closing socket")
            self.socket.close()
            logger.debug(f"{self.name} -- Close socket success")
        except Exception as e:
            logger.exception(f"{self.name} -- Close socket failure -- {e}")


    def recover_connection(self):
        if self.socket:
            logger.debug(f"{self.name} -- Recovering connection")
            self.socket.close()
            self.connect()

class AddrIndexRsClient():
    def __init__(self, host, port):
        self.host = host
        self.port = port
        self.socket_manager = SocketManager(host, port, "addrindexrs_socket_manager")
        self.thread = threading.Thread(target=self._start, name="addrindexrs_connect_thread")
        self.req_queue = queue.Queue()
        self.res_queue = queue.Queue()
        self.is_running = False
        self.msg_id = 0

    def start(self):
        logger.debug("AddrIndexRsClient -- starting...")
        self.is_running = True
        self.socket_manager.connect()
        self.thread.start()

    def stop(self):
        logger.debug("AddrIndexRsClient -- stopping...")
        self.is_running = False
        self.socket_manager.close()
        self.req_queue.join()
        self.res_queue.join()
        if self.is_running:
            self.thread.join()
        self.is_running = False

    def send(self, msg):
        logger.debug(f"AddrIndexRsClient -- sending message: {msg}")
        self.req_queue.put(msg)
        logger.debug("AddrIndexRsClient -- waiting for response")
        res = self.res_queue.get()
        self.res_queue.task_done()
        logger.debug(f"AddrIndexRsClient -- received response: {res}")
        if res is None:
            raise AddrIndexRsEmptyResponseError("Empty response from addrindexrs.")
        return res

    def _start(self):
        while self.is_running:
            try:

                logger.debug("AddrIndexRsClient.thread -- waiting for message")
                # if there is no messager after 1 sec, it will raise queue.Empty
                msg = self.req_queue.get(timeout=1)
                serialized_msg = self._serialize_msg(msg, self.msg_id )
                self.msg_id += 1
                if not self.socket_manager.send(serialized_msg):
                    logger.debug("AddrIndexRsClient.thread -- send failed")
                    self.res_queue.put(None)
                    continue
                self.req_queue.task_done()

                res = self.socket_manager.recv()
                if res:
                    logger.debug(f"AddrIndexRsClient.thread -- received response: {res}")
                    self.res_queue.put(res)
                else:
                    logger.debug("AddrIndexRsClient.thread -- received empty response")
                    self.res_queue.put(None)
            except queue.Empty:
                continue
            except Exception as e:
                logger.exception(f"AddrIndexRsClient.thread -- exception {e}")

    def _serialize_msg(self, msg, id_):
        msg["id"] = id_
        return (json.dumps(msg) + "\n").encode('utf8')


def indexer_check_version():
    logger.debug('Checking version of address indexer.')
    addrindexrs_version = INDEXER_THREAD.send({
        "method": "server.version",
        "params": []
    })

    try:
        #12 is the length of "addrindexrs "
        addrindexrs_version_label = addrindexrs_version["result"][0][12:]
    except TypeError as e:
        logger.exception(f'Error when checking address indexer version: {addrindexrs_version}')
        sys.exit(1)

    if addrindexrs_version_label != config.ADDRINDEXRS_VERSION:
        message = f"Wrong addrindexrs version: {config.ADDRINDEXRS_VERSION} is needed but {addrindexrs_version_label} was found"
        #logger.error(message)
        INDEXER_THREAD.stop()
        raise exceptions.InvalidVersion(message)

    logger.debug(f'Version check of address indexer passed ({config.ADDRINDEXRS_VERSION} == {addrindexrs_version_label}).')

def _script_pubkey_to_hash(spk):
    return hashlib.sha256(spk).digest()[::-1].hex()

def _address_to_hash(addr):
    script_pubkey = bitcoin.wallet.CBitcoinAddress(addr).to_scriptPubKey()
    return _script_pubkey_to_hash(script_pubkey)

# Returns an array of UTXOS from an address in the following format
# {
#   "txId": utxo_txid_hex,
#   "vout": num,
#   "height": num,
#   "value": sats,
#   "confirmations": num
# }
# [{"txId":"a0d12eb3716e2e70fd00525486ace0da2947f82d818b7be0285f16ff672cf237","vout":5,"height":647484,"value":30455293,"confirmations":2}]
#
def unpack_outpoint(outpoint):
    txid, vout = outpoint.split(':')
    return (txid, int(vout))

def unpack_vout(outpoint, tx, block_count):
    if tx is None:
        return None

    vout = tx["vout"][outpoint[1]]
    height = -1
    if "confirmations" in tx and tx["confirmations"] > 0:
        height = block_count - tx["confirmations"] + 1
    else:
        tx["confirmations"] = 0

    return {
        "txId": tx["txid"],
        "vout": outpoint[1],
        "height": height,
        "value": int(round(vout["value"] * config.UNIT)),
        "confirmations": tx["confirmations"]
    }

def get_unspent_txouts(source):
    block_count = getblockcount()
    result = INDEXER_THREAD.send({
        "method": "blockchain.scripthash.get_utxos",
        "params": [_address_to_hash(source)]
    })

    if not(result is None) and "result" in result:
        result = result["result"]
        result = [unpack_outpoint(x) for x in result]
        # each item on the result array is like
        # {"tx_hash": hex_encoded_hash}
        batch = getrawtransaction_batch([x[0] for x in result], verbose=True, skip_missing=True)
        batch = [unpack_vout(outpoint, batch[outpoint[0]], block_count) for outpoint in result if outpoint[0] in batch]
        batch = [x for x in batch if x is not None]

        return batch
    else:
        return []

# Returns transactions in the following format
# {
#  "blockhash": hexstring,
#  "blocktime": num,
#  "confirmations": num,
#  "hash": hexstring,
#  "height": num,
#  "hex": hexstring,
#  "locktime": num,
#  "size": num,
#  "time": num,
#  "txid": hexstring,
#  "version": num,
#  "vsize": num,
#  "weight": num,
#  "vin": [
#    {
#      "txinwitness": array of hex_witness_program, // Only if it's a witness-containing tx
#      "vout": num,
#      "txid": hexstring,
#      "sequence": num,
#      "coinbase": X, // contents not important, this is only present if the tx is a coinbase
#      "scriptSig": {
#        "asm": asm_decompiled_program,
#        "hex": hex_program
#      }
#    },...
#  ],
#  "vout": [
#    {
#       "n": num,
#       "value": decimal,
#       "scriptPubKey": {
#           "type": string,
#           "reqSigs": num,
#           "hex": hexstring, // the program in hex
#           "asm": string, // the decompiled program
#           "addresses": [ ...list of found addresses on the program ]
#       }
#    }
#  ]
#
# }
def search_raw_transactions(address, unconfirmed=True, only_tx_hashes=False):
    hsh = _address_to_hash(address)
    txs = INDEXER_THREAD.send({
        "method": "blockchain.scripthash.get_history",
        "params": [hsh]
    })["result"]

    if only_tx_hashes:
        return txs
    else:
        batch = getrawtransaction_batch([x["tx_hash"] for x in txs], verbose=True)

        if not(unconfirmed):
            batch = [x for x in batch if x.height >= 0]

        return batch

def get_oldest_tx_legacy(address):
    hsh = _address_to_hash(address)
    call_result = INDEXER_THREAD.send({
        "method": "blockchain.scripthash.get_oldest_tx",
        "params": [hsh]
    })

    if call_result is not None and not ("error" in call_result):
        txs = call_result["result"]
        return txs

    return {}

# Returns the number of blocks the backend is behind the node
def getindexblocksbehind():
    # Addrindexrs never "gets behind"
    return 0

def init():
    global INDEXER_THREAD
    INDEXER_THREAD = AddrIndexRsClient(config.INDEXD_CONNECT, config.INDEXD_PORT)
    INDEXER_THREAD.start()
    logger.info('Connecting to address indexer.')
    indexer_check_version()

def stop():
    if 'INDEXER_THREAD' in globals():
        INDEXER_THREAD.stop()

# We hardcoded certain addresses to reproduce an `addrindexrs` bug.
# In comments the real result that `addrindexrs` should have returned.
GET_OLDEST_TX_HARDCODED = {
    "825096-bc1q66u8n4q0ld3furqugr0xzakpedrc00wv8fagmf": {} # {'block_index': 820886, 'tx_hash': 'e5d130a583983e5d9a9a9175703300f7597eadb6b54fe775055110907b4079ed'}
}

def get_oldest_tx(address, block_index=None):
    current_block_index = block_index or ledger.CURRENT_BLOCK_INDEX
    hardcoded_key = f"{current_block_index}-{address}"
    if hardcoded_key in GET_OLDEST_TX_HARDCODED:
        result = GET_OLDEST_TX_HARDCODED[hardcoded_key]
    else:
        result = INDEXER_THREAD.send({
            "method": "blockchain.scripthash.get_oldest_tx",
            "params": [_address_to_hash(address), current_block_index]
        })

    return result


