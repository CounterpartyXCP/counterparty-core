import binascii  # noqa: F401
import collections
import concurrent.futures
import functools
import hashlib
import json
import logging
import os  # noqa: F401
import queue
import signal  # noqa: F401
import socket
import sys
import threading
import time

import bitcoin.wallet
import requests
from pkg_resources import parse_version  # noqa: F401
from requests.exceptions import ConnectionError, ReadTimeout, Timeout

from counterpartycore.lib import config, exceptions, ledger, util

logger = logging.getLogger(config.LOGGER_NAME)

READ_BUF_SIZE = 65536
SOCKET_TIMEOUT = 30.0
BACKEND_PING_TIME = 30.0
BACKOFF_START = 1
BACKOFF_MAX = 8
BACKOFF_FACTOR = 2

INDEXER_THREAD = None
raw_transactions_cache = util.DictCache(
    size=config.BACKEND_RAW_TRANSACTIONS_CACHE_SIZE
)  # used in getrawtransaction_batch()


class BackendRPCError(Exception):
    pass


class AddrIndexRsRPCError(Exception):
    pass


class AddrIndexRsClientError(Exception):
    pass


def rpc_call(payload):
    """Calls to bitcoin core and returns the response"""
    url = config.BACKEND_URL
    response = None

    tries = 0
    while True:
        try:
            tries += 1
            response = requests.post(
                url,
                data=json.dumps(payload),
                headers={"content-type": "application/json"},
                verify=(not config.BACKEND_SSL_NO_VERIFY),
                timeout=config.REQUESTS_TIMEOUT,
            )

            if response == None:  # noqa: E711
                if config.TESTNET:
                    network = "testnet"
                elif config.REGTEST:
                    network = "regtest"
                else:
                    network = "mainnet"
                raise BackendRPCError(
                    f"Cannot communicate with backend at `{util.clean_url_for_log(url)}`. (server is set to run on {network}, is backend?)"
                )
            elif response.status_code in (401,):
                raise BackendRPCError(
                    f"Authorization error connecting to {util.clean_url_for_log(url)}: {response.status_code} {response.reason}"
                )
            elif response.status_code not in (200, 500):
                raise BackendRPCError(str(response.status_code) + " " + response.reason)

            else:
                break
        except KeyboardInterrupt:
            logger.warning("Interrupted by user")
            exit(0)
        except (Timeout, ReadTimeout, ConnectionError):
            logger.debug(
                f"Could not connect to backend at `{util.clean_url_for_log(url)}`. (Try {tries})"
            )
            time.sleep(5)

    # Handle json decode errors
    try:
        response_json = response.json()
    except json.decoder.JSONDecodeError as e:  # noqa: F841
        raise BackendRPCError(  # noqa: B904
            f"Received invalid JSON from backend with a response of {str(response.status_code) + ' ' + response.reason}"
        )

    # Batch query returns a list
    if isinstance(response_json, list):
        return response_json
    if "error" not in response_json.keys() or response_json["error"] == None:  # noqa: E711
        return response_json["result"]
    elif response_json["error"]["code"] == -5:  # RPC_INVALID_ADDRESS_OR_KEY
        raise BackendRPCError(
            f"{response_json['error']} Is `txindex` enabled in {config.BTC_NAME} Core?"
        )
    elif response_json["error"]["code"] in [-28, -8, -2]:
        # “Verifying blocks...” or “Block height out of range” or “The network does not appear to fully agree!“
        logger.debug("Backend not ready. Sleeping for ten seconds.")
        # If Bitcoin Core takes more than `sys.getrecursionlimit() * 10 = 9970`
        # seconds to start, this’ll hit the maximum recursion depth limit.
        time.sleep(10)
        return rpc_call(payload)
    else:
        raise BackendRPCError(
            f"Error connecting to {util.clean_url_for_log(url)}: {response_json['error']}"
        )


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
        # send a list of requests to bitcoind to be executed
        # note that this is list executed serially, in the same thread in bitcoind
        # e.g. see: https://github.com/bitcoin/bitcoin/blob/master/src/rpcserver.cpp#L939
        responses.extend(rpc_call(chunk))

    chunks = util.chunkify(request_list, config.RPC_BATCH_SIZE)
    with concurrent.futures.ThreadPoolExecutor(
        max_workers=config.BACKEND_RPC_BATCH_NUM_WORKERS
    ) as executor:
        for chunk in chunks:
            executor.submit(make_call, chunk)
    return list(responses)


def extract_addresses(txhash_list):
    tx_hashes_tx = getrawtransaction_batch(txhash_list, verbose=True)

    return extract_addresses_from_txlist(tx_hashes_tx, getrawtransaction_batch)


def extract_addresses_from_txlist(tx_hashes_tx, _getrawtransaction_batch):
    """
    helper for extract_addresses, seperated so we can pass in a mocked _getrawtransaction_batch for test purposes
    """

    tx_hashes_addresses = {}
    tx_inputs_hashes = set()  # use set to avoid duplicates

    for tx_hash, tx in tx_hashes_tx.items():
        tx_hashes_addresses[tx_hash] = set()
        for vout in tx["vout"]:
            if "addresses" in vout["scriptPubKey"]:
                tx_hashes_addresses[tx_hash].update(tuple(vout["scriptPubKey"]["addresses"]))

        tx_inputs_hashes.update([vin["txid"] for vin in tx["vin"]])

    # chunk txs to avoid huge memory spikes
    for tx_inputs_hashes_chunk in util.chunkify(
        list(tx_inputs_hashes), config.BACKEND_RAW_TRANSACTIONS_CACHE_SIZE
    ):
        raw_transactions = _getrawtransaction_batch(tx_inputs_hashes_chunk, verbose=True)
        for tx_hash, tx in tx_hashes_tx.items():
            for vin in tx["vin"]:
                vin_tx = raw_transactions.get(vin["txid"], None)

                if not vin_tx:
                    continue

                vout = vin_tx["vout"][vin["vout"]]
                if "addresses" in vout["scriptPubKey"]:
                    tx_hashes_addresses[tx_hash].update(tuple(vout["scriptPubKey"]["addresses"]))

    return tx_hashes_addresses, tx_hashes_tx


def getblockcount():
    return rpc("getblockcount", [])


def getblockhash(blockcount):
    return rpc("getblockhash", [blockcount])


def getblock(block_hash):
    return rpc("getblock", [block_hash, False])


@functools.lru_cache
def getrawtransaction(tx_hash, verbose=False, skip_missing=False):
    # logger.debug(f"Cache miss on transaction {tx_hash}!")
    return getrawtransaction_batch([tx_hash], verbose=verbose, skip_missing=skip_missing)[tx_hash]


def getrawmempool():
    return rpc("getrawmempool", [])


def fee_per_kb(conf_target, mode, nblocks=None):
    """
    :param conf_target:
    :param mode:
    :return: fee_per_kb in satoshis, or None when unable to determine
    """
    if nblocks is None and conf_target is None:
        conf_target = nblocks

    feeperkb = rpc("estimatesmartfee", [conf_target, mode])

    if "errors" in feeperkb and feeperkb["errors"][0] == "Insufficient data or no feerate found":
        return None

    return int(max(feeperkb["feerate"] * config.UNIT, config.DEFAULT_FEE_PER_KB_ESTIMATE_SMART))


def sendrawtransaction(tx_hex):
    return rpc("sendrawtransaction", [tx_hex])


GETRAWTRANSACTION_MAX_RETRIES = 2
MONOTONIC_CALL_ID = 0


def getrawtransaction_batch(txhash_list, verbose=False, skip_missing=False, _retry=0):
    _logger = logger.getChild("getrawtransaction_batch")

    if len(txhash_list) > config.BACKEND_RAW_TRANSACTIONS_CACHE_SIZE:
        # don't try to load in more than BACKEND_RAW_TRANSACTIONS_CACHE_SIZE entries in a single call
        txhash_list_chunks = util.chunkify(txhash_list, config.BACKEND_RAW_TRANSACTIONS_CACHE_SIZE)
        txes = {}
        for txhash_list_chunk in txhash_list_chunks:
            txes.update(
                getrawtransaction_batch(
                    txhash_list_chunk, verbose=verbose, skip_missing=skip_missing
                )
            )
        return txes

    tx_hash_call_id = {}
    payload = []
    noncached_txhashes = set()

    txhash_list = set(txhash_list)

    # payload for transactions not in cache
    for tx_hash in txhash_list:
        if tx_hash not in raw_transactions_cache:
            # call_id = binascii.hexlify(os.urandom(5)).decode('utf8') # Don't drain urandom
            global MONOTONIC_CALL_ID  # noqa: PLW0603
            MONOTONIC_CALL_ID = MONOTONIC_CALL_ID + 1
            call_id = f"{MONOTONIC_CALL_ID}"
            payload.append(
                {
                    "method": "getrawtransaction",
                    "params": [tx_hash, 1],
                    "jsonrpc": "2.0",
                    "id": call_id,
                }
            )
            noncached_txhashes.add(tx_hash)
            tx_hash_call_id[call_id] = tx_hash
    # refresh any/all cache entries that already exist in the cache,
    # so they're not inadvertently removed by another thread before we can consult them
    # (this assumes that the size of the working set for any given workload doesn't exceed the max size of the cache)
    for tx_hash in txhash_list.difference(noncached_txhashes):
        raw_transactions_cache.refresh(tx_hash)

    # populate cache
    if len(payload) > 0:
        batch_responses = rpc_batch(payload)
        for response in batch_responses:
            if "error" not in response or response["error"] is None:
                tx_hex = response["result"]
                tx_hash = tx_hash_call_id[response["id"]]
                raw_transactions_cache[tx_hash] = tx_hex
            elif skip_missing and "error" in response and response["error"]["code"] == -5:
                raw_transactions_cache[tx_hash] = None
                # missing_tx_hash = tx_hash_call_id.get(response.get("id", "??"), "??")
                # logger.debug(
                #    f"Missing TX with no raw info skipped (txhash: {missing_tx_hash}): {response['error']}"
                # )
            else:
                # TODO: this seems to happen for bogus transactions? Maybe handle it more gracefully than just erroring out?
                raise BackendRPCError(
                    f"{response['error']} (txhash:: {tx_hash_call_id.get(response.get('id', '??'), '??')})"
                )

    # get transactions from cache
    result = {}
    for tx_hash in txhash_list:
        try:
            if verbose:
                result[tx_hash] = raw_transactions_cache[tx_hash]
            else:
                result[tx_hash] = (
                    raw_transactions_cache[tx_hash]["hex"]
                    if raw_transactions_cache[tx_hash] is not None
                    else None
                )
        except KeyError:  # shows up most likely due to finickyness with addrindex not always returning results that we need...
            _logger.debug(f"tx missing in rawtx cache: {tx_hash}")
            if _retry < GETRAWTRANSACTION_MAX_RETRIES:  # try again
                time.sleep(
                    0.05 * (_retry + 1)
                )  # Wait a bit, hitting the index non-stop may cause it to just break down... TODO: Better handling
                r = getrawtransaction_batch(
                    [tx_hash],
                    verbose=verbose,
                    skip_missing=skip_missing,
                    _retry=_retry + 1,
                )
                result[tx_hash] = r[tx_hash]
            else:
                raise  # already tried again, give up

    return result


class SocketManager:
    def __init__(self, host, port, timeout=SOCKET_TIMEOUT):
        self.host = host
        self.port = port
        self.timeout = timeout
        self.socket = None
        self.connected = False

    def connect(self):
        try:
            self.socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            self.socket.settimeout(self.timeout)
            self.socket.connect((self.host, self.port))
            self.connected = True
            logger.debug(f"`{self.host}:{self.port}` -- connected")
        except socket.timeout as e:
            logger.exception(f"`{self.host}:{self.port}` -- socket.connect timeout")
            raise e
        except ConnectionRefusedError as e:
            logger.exception(f"`{self.host}:{self.port}` -- connection refused")
            raise e
        except Exception as e:
            logger.exception(f"`{self.host}:{self.port}` -- unknown exception: {e}")
            raise e

    def disconnect(self):
        if self.connected:
            try:
                self.socket.close()
                self.connected = False
                logger.debug(f"`{self.host}:{self.port}` -- disconnected")
            except Exception as e:
                logger.exception(f"`{self.host}:{self.port}` -- unknown exception: {e}")
                raise e

    def send(self, message):
        if not self.connected:
            self.connect()

        try:
            self.socket.sendall(message)
            logger.debug(f"`{self.host}:{self.port}` -- sent message {message}")
        except socket.timeout as e:
            logger.exception(f"`{self.host}:{self.port}` -- socket.send timeout")
            self.connected = False
            raise e
        except Exception as e:
            logger.exception(f"`{self.host}:{self.port}` -- unknown exception: {e}")
            self.connected = False
            raise e

    def recv(self, parse=lambda a: json.loads(a.decode("utf8")), buffer_size=READ_BUF_SIZE):
        if not self.connected:
            self.connect()

        response = b""
        while True:
            try:
                chunk = self.socket.recv(buffer_size)
                if not chunk:
                    raise Exception("Socket disconnected")
                response += chunk
                # logger.debug(
                #     f"`{self.host}:{self.port}` -- chunk received: {chunk}, response: {response}"
                # )
                try:
                    res = parse(response)
                    # logger.debug(f"`{self.host}:{self.port}` -- received message: { res}")
                    return res
                except json.JSONDecodeError:
                    # logger.debug(f"`{self.host}:{self.port}` -- JSONDecodeError -- continuing")
                    continue
            except socket.timeout as e:
                logger.exception(f"`{self.host}:{self.port}` -- Timeout receiving message: {e}")
                self.connected = False
                raise e
            except Exception as e:
                logger.exception(f"`{self.host}:{self.port}`  -- Error receiving message: {e}")
                self.connected = False
                raise e


class AddrIndexRsClient:
    def __init__(
        self,
        host,
        port,
        timeout=SOCKET_TIMEOUT,
        backoff_start=BACKOFF_START,
        backoff_max=BACKOFF_MAX,
        backoff_factor=BACKOFF_FACTOR,
    ):
        self.host = host
        self.port = port
        self.socket_manager = SocketManager(host, port, timeout)
        self.thread = threading.Thread(target=self._run, name="AddrIndexRsClient")
        self.req_queue = queue.Queue()
        self.res_queue = queue.Queue()
        self.is_running = False

        self.backoff = backoff_start
        self.backoff_max = backoff_max
        self.backoff_factor = backoff_factor

        self.msg_id = 0
        self.msg_id_lock = threading.Lock()

    def start(self):
        if self.is_running:
            return

        logger.debug("AddrIndexRsClient -- starting...")
        while True:
            try:
                self.socket_manager.connect()
                self.is_running = True
                self.thread.start()
                break
            except Exception as e:
                self.is_running = False
                logger.info(
                    f"AddrIndexRsClient -- failed to start: {e}, retrying in {self.backoff} seconds..."
                )
                time.sleep(self.backoff)
                self.backoff = min(self.backoff * self.backoff_factor, self.backoff_max)

    def stop(self):
        if not self.is_running:
            return

        self.is_running = False
        try:
            self.socket_manager.disconnect()
            self.req_queue.join()
            self.res_queue.join()
            self.thread.join()
        except Exception as e:
            logger.exception(f"AddrIndexRsClient -- error while stopping: {e}")

    def send(self, msg):
        with self.msg_id_lock:
            msg["id"] = self.msg_id
            self.msg_id += 1

        serialized_msg = (json.dumps(msg) + "\n").encode("utf8")

        self.req_queue.put(serialized_msg)

        res = self.res_queue.get()

        self.res_queue.task_done()

        if "error" in res:
            if res["error"] == "no txs for address":
                return {}
            raise AddrIndexRsClientError(f"AddrIndexRsClient -- Error in response: {res['error']}")

        if "id" not in res:
            raise AddrIndexRsClientError("AddrIndexRsClient -- No response id.")

        if res["id"] != msg["id"]:
            raise AddrIndexRsClientError(
                "AddrIndexRsClient -- Invalid response id. Expected: {msg['id']}, received: {res['id']}"
            )

        if "result" not in res:
            raise AddrIndexRsClientError(
                "AddrIndexRsClient -- No error and no result in responses."
            )

        return res

    def _run(self):
        while self.is_running:
            try:
                # logger.debug("AddrIndexRsClient.thread -- waiting for message")
                # if there is no messager after 1 sec, it will raise queue.Empty
                msg = self.req_queue.get(timeout=1)
                self.socket_manager.send(msg)
                self.req_queue.task_done()

                # wait for response
                res = self.socket_manager.recv()
                # logger.debug(f"AddrIndexRsClient.thread -- received response: {res}")
                self.res_queue.put(res)

            except queue.Empty:
                continue
            except Exception as e:
                logger.exception(f"AddrIndexRsClient.thread -- exception {e}")
                self.res_queue.put({"error": str(e)})


def indexer_check_version():
    logger.debug("Checking version of address indexer.")
    addrindexrs_version = INDEXER_THREAD.send({"method": "server.version", "params": []})

    try:
        addrindexrs_version_label = addrindexrs_version["result"][0][
            12:
        ]  # 12 is the length of "addrindexrs "
    except TypeError as e:  # noqa: F841
        logger.exception(f"Error when checking address indexer version: {addrindexrs_version}")
        sys.exit(1)

    if addrindexrs_version_label != config.ADDRINDEXRS_VERSION:
        message = f"Wrong addrindexrs version: {config.ADDRINDEXRS_VERSION} is needed but {addrindexrs_version_label} was found"
        # logger.error(message)
        INDEXER_THREAD.stop()
        raise exceptions.InvalidVersion(message)

    logger.debug(
        f"Version check of address indexer passed ({config.ADDRINDEXRS_VERSION} == {addrindexrs_version_label})."
    )


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
    txid, vout = outpoint.split(":")
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
        "confirmations": tx["confirmations"],
    }


def get_unspent_txouts(source):
    block_count = getblockcount()
    result = INDEXER_THREAD.send(
        {
            "method": "blockchain.scripthash.get_utxos",
            "params": [_address_to_hash(source)],
        }
    )

    if result is not None and "result" in result:
        result = result["result"]
        result = [unpack_outpoint(x) for x in result]
        # each item on the result array is like
        # {"tx_hash": hex_encoded_hash}
        batch = getrawtransaction_batch([x[0] for x in result], verbose=True, skip_missing=True)
        batch = [
            unpack_vout(outpoint, batch[outpoint[0]], block_count)
            for outpoint in result
            if outpoint[0] in batch
        ]
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
def search_raw_transactions(address, unconfirmed: bool = True, only_tx_hashes: bool = False):
    hsh = _address_to_hash(address)
    txs = INDEXER_THREAD.send({"method": "blockchain.scripthash.get_history", "params": [hsh]})[
        "result"
    ]

    if only_tx_hashes:
        return txs
    else:
        batch = getrawtransaction_batch([x["tx_hash"] for x in txs], verbose=True)

        if not (unconfirmed):
            batch = [x for x in batch if x.height >= 0]

        return batch


def get_oldest_tx_legacy(address):
    hsh = _address_to_hash(address)
    call_result = INDEXER_THREAD.send(
        {"method": "blockchain.scripthash.get_oldest_tx", "params": [hsh]}
    )

    if call_result is not None and "error" not in call_result:
        txs = call_result["result"]
        return txs

    return {}


# Returns the number of blocks the backend is behind the node
def getindexblocksbehind():
    # Addrindexrs never "gets behind"
    return 0


def init():
    global INDEXER_THREAD  # noqa: PLW0603
    INDEXER_THREAD = AddrIndexRsClient(config.INDEXD_CONNECT, config.INDEXD_PORT)
    INDEXER_THREAD.daemon = True
    INDEXER_THREAD.start()
    logger.info("Connecting to address indexer.")
    indexer_check_version()


def stop():
    if "INDEXER_THREAD" in globals() and INDEXER_THREAD is not None:
        INDEXER_THREAD.stop()


# Basic class to communicate with addrindexrs.
# No locking thread.
# Assume only one instance of this class is used at a time and not concurrently.
# This class does not handle most of the errors, it's up to the caller to do so.
# This class assumes responses are always not longer than READ_BUF_SIZE (65536 bytes).
# This class assumes responses are always valid JSON.

ADDRINDEXRS_CLIENT_TIMEOUT = 20.0


class AddrindexrsSocketError(Exception):
    pass


class AddrindexrsSocket:
    def __init__(self):
        self.next_message_id = 0
        self.connect()

    def connect(self):
        self.sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        self.sock.settimeout(ADDRINDEXRS_CLIENT_TIMEOUT)
        self.sock.connect((config.INDEXD_CONNECT, config.INDEXD_PORT))

    def _send(self, query, timeout=ADDRINDEXRS_CLIENT_TIMEOUT):
        query["id"] = self.next_message_id

        message = (json.dumps(query) + "\n").encode("utf8")

        self.sock.send(message)

        self.next_message_id += 1

        start_time = time.time()
        while True:
            try:
                data = self.sock.recv(READ_BUF_SIZE)
            except (TimeoutError, ConnectionResetError) as e:
                raise AddrindexrsSocketError("Timeout or connection reset. Please retry.") from e
            if data:
                response = json.loads(data.decode("utf-8"))  # assume valid JSON
                if "id" not in response:
                    raise AddrindexrsSocketError("No ID in response")
                if response["id"] != query["id"]:
                    raise AddrindexrsSocketError("ID mismatch in response")
                if "error" in response:
                    if response["error"] == "no txs for address":
                        return {}
                    raise AddrindexrsSocketError(response["error"])
                if "result" not in response:
                    raise AddrindexrsSocketError("No error and no result in response")
                return response["result"]

            duration = time.time() - start_time
            if duration > timeout:
                raise AddrindexrsSocketError("Timeout. Please retry.")

    def send(self, query, timeout=ADDRINDEXRS_CLIENT_TIMEOUT, retry=0):
        try:
            return self._send(query, timeout=timeout)
        except BrokenPipeError:
            if retry > 3:
                raise Exception("Too many retries, please check addrindexrs")  # noqa: B904
            self.sock.close()
            self.connect()
            return self.send(query, timeout=timeout, retry=retry + 1)

    def get_oldest_tx(self, address, timeout=ADDRINDEXRS_CLIENT_TIMEOUT, block_index=None):
        hsh = _address_to_hash(address)
        query = {
            "method": "blockchain.scripthash.get_oldest_tx",
            "params": [hsh, block_index or ledger.CURRENT_BLOCK_INDEX],
        }
        return self.send(query, timeout=timeout)


# We hardcoded certain addresses to reproduce an `addrindexrs` bug.
# In comments the real result that `addrindexrs` should have returned.
GET_OLDEST_TX_HARDCODED = {
    "825096-bc1q66u8n4q0ld3furqugr0xzakpedrc00wv8fagmf": {}  # {'block_index': 820886, 'tx_hash': 'e5d130a583983e5d9a9a9175703300f7597eadb6b54fe775055110907b4079ed'}
}
ADDRINDEXRS_CLIENT = None


def get_oldest_tx(address: str, block_index: int = None):
    current_block_index = block_index or ledger.CURRENT_BLOCK_INDEX
    hardcoded_key = f"{current_block_index}-{address}"
    if hardcoded_key in GET_OLDEST_TX_HARDCODED:
        result = GET_OLDEST_TX_HARDCODED[hardcoded_key]
    else:
        global ADDRINDEXRS_CLIENT  # noqa: PLW0603
        if ADDRINDEXRS_CLIENT is None:
            ADDRINDEXRS_CLIENT = AddrindexrsSocket()
        result = ADDRINDEXRS_CLIENT.get_oldest_tx(address, block_index=current_block_index)

    return result
