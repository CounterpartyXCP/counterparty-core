import collections
import concurrent.futures
import hashlib
import json
import logging
import queue
import socket
import sys
import threading
import time

import bitcoin.wallet

from counterpartycore.lib import config, exceptions, util
from counterpartycore.lib.backend.bitcoind import getblockcount, rpc_call

logger = logging.getLogger(config.LOGGER_NAME)

INITIALIZED = False

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


GETRAWTRANSACTION_MAX_RETRIES = 2
MONOTONIC_CALL_ID = 0


def getrawtransaction_batch(txhash_list, verbose=False, skip_missing=False, _retry=0):
    init()
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
            logger.debug(f"tx missing in rawtx cache: {tx_hash}")
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

    def log(self, message, level=logging.DEBUG):
        message = f"AddrindexRS Client - Server: `{self.host}:{self.port}` - {message}"
        if level == logging.ERROR:
            logger.error(message)
        elif level == logging.WARNING:
            logger.warning(message)
        else:
            logger.debug(message)

    def connect(self):
        try:
            self.socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            self.socket.settimeout(self.timeout)
            self.socket.connect((self.host, self.port))
            self.connected = True
            self.log("Connected")
        except socket.timeout as e:
            self.log("Socket connect timeout")
            raise e
        except ConnectionRefusedError as e:
            self.log("Connection refused")
            raise e
        except Exception as e:
            self.log(f"Unknown exception: {e}")
            raise e

    def disconnect(self):
        if self.connected:
            try:
                self.socket.close()
                self.connected = False
                self.log("Disconnected")
            except Exception as e:
                self.log(f"Unknown exception: {e}", level=logging.ERROR)
                raise e

    def send(self, message):
        if not self.connected:
            self.connect()

        try:
            self.socket.sendall(message)
            self.log(f"Message sent: {message}")
        except socket.timeout as e:
            self.log("Socket send timeout", level=logging.WARNING)
            self.connected = False
            raise e
        except Exception as e:
            self.log(f"Unknown exception: {e}", level=logging.ERROR)
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
                # self.log(""chunk received: {chunk}, response: {response}")
                try:
                    res = parse(response)
                    # self.log("received message: { res}")
                    return res
                except json.JSONDecodeError:
                    # self.log("JSONDecodeError -- continuing")
                    continue
            except socket.timeout as e:
                self.log(f"Timeout receiving message: {e}", level=logging.WARNING)
                self.connected = False
                raise e
            except Exception as e:
                self.log(f"Error receiving message: {e}", level=logging.ERROR)
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
        self.log = self.socket_manager.log
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

        self.log("Starting...")
        while True:
            try:
                self.socket_manager.connect()
                self.is_running = True
                self.thread.start()
                break
            except Exception as e:
                self.is_running = False
                self.log(
                    f"Failed to start: {e}, retrying in {self.backoff} seconds...",
                    level=logging.WARNING,
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
            self.log(f"Error while stopping: {e}", level=logging.ERROR)

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
                self.log(f"Thread exception: {e}", level=logging.ERROR)
                self.res_queue.put({"error": str(e)})


def indexer_check_version():
    logger.debug("Checking version of address indexer.")
    addrindexrs_version = INDEXER_THREAD.send({"method": "server.version", "params": []})

    try:
        addrindexrs_version_label = addrindexrs_version["result"][0][
            12:
        ]  # 12 is the length of "addrindexrs "
    except TypeError as e:  # noqa: F841
        logger.error(f"Error when checking address indexer version: {addrindexrs_version}")
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


def _get_unspent_txouts(source):
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


def get_unspent_txouts(address: str, unconfirmed: bool = False, unspent_tx_hash: str = None):
    """
    Returns a list of unspent outputs for a specific address
    :param address: The address to search for (e.g. 14TjwxgnuqgB4HcDcSZk2m7WKwcGVYxRjS)
    :param unconfirmed: Include unconfirmed transactions
    :param unspent_tx_hash: Filter by unspent_tx_hash
    """
    init()
    unspent = _get_unspent_txouts(address)

    # filter by unspent_tx_hash
    if unspent_tx_hash is not None:
        unspent = list(filter(lambda x: x["txId"] == unspent_tx_hash, unspent))

    # filter unconfirmed
    if not unconfirmed:
        unspent = [utxo for utxo in unspent if utxo["confirmations"] > 0]

    # format
    for utxo in unspent:
        utxo["amount"] = float(utxo["value"] / config.UNIT)
        utxo["txid"] = utxo["txId"]
        del utxo["txId"]
        # do not add scriptPubKey

    return unspent


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
#       "script_pub_key": {
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
    init()
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


def get_transactions_by_address(
    address: str, unconfirmed: bool = True, only_tx_hashes: bool = False
):
    """
    Returns all transactions involving a given address
    :param address: The address to search for (e.g. 14TjwxgnuqgB4HcDcSZk2m7WKwcGVYxRjS)
    :param unconfirmed: Include unconfirmed transactions (e.g. True)
    :param only_tx_hashes: Return only the tx hashes (e.g. True)
    """
    return search_raw_transactions(address, unconfirmed, only_tx_hashes)


def init():
    global INDEXER_THREAD, INITIALIZED  # noqa: PLW0603
    if INITIALIZED:
        return
    INDEXER_THREAD = AddrIndexRsClient(config.INDEXD_CONNECT, config.INDEXD_PORT)
    INDEXER_THREAD.daemon = True
    INDEXER_THREAD.start()
    logger.info("Connecting to address indexer...")
    indexer_check_version()
    INITIALIZED = True


def stop():
    logger.info("Stopping AddrIndexRs thread...")
    if "INDEXER_THREAD" in globals() and INDEXER_THREAD is not None:
        INDEXER_THREAD.stop()


# Basic class to communicate with addrindexrs.
# No locking thread.
# Assume only one instance of this class is used at a time and not concurrently.
# This class does not handle most of the errors, it's up to the caller to do so.
# This class assumes responses are always not longer than READ_BUF_SIZE (65536 bytes).
# This class assumes responses are always valid JSON.

ADDRINDEXRS_CLIENT_TIMEOUT = 60.0


class AddrindexrsSocketError(Exception):
    pass


class AddrindexrsSocketTimeoutError(Exception):
    pass


class AddrindexrsSocket:
    def __init__(self):
        self.next_message_id = 0
        self.connect()

    def connect(self):
        try:
            self.sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            self.sock.settimeout(ADDRINDEXRS_CLIENT_TIMEOUT)
            self.sock.connect((config.INDEXD_CONNECT, config.INDEXD_PORT))
        except Exception:
            logger.warning("Failed to connect to addrindexrs, retrying in 10s...")
            time.sleep(10)
            self.connect()

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
                raise AddrindexrsSocketTimeoutError("Timeout. Please retry.")

    def send(self, query, timeout=ADDRINDEXRS_CLIENT_TIMEOUT, retry=0):
        try:
            return self._send(query, timeout=timeout)
        except BrokenPipeError:
            if retry > 3:
                raise Exception("Too many retries, please check addrindexrs")  # noqa: B904
            self.sock.close()
            self.connect()
            return self.send(query, timeout=timeout, retry=retry + 1)

    def get_oldest_tx(self, address, block_index, timeout=ADDRINDEXRS_CLIENT_TIMEOUT):
        try:
            hsh = _address_to_hash(address)
            query = {
                "method": "blockchain.scripthash.get_oldest_tx",
                "params": [hsh, block_index],
            }
            return self.send(query, timeout=timeout)
        except AddrindexrsSocketTimeoutError:
            logger.warning(
                f"Timeout when fetching oldest tx for {address} at block {block_index}. Retrying in 5s..."
            )
            time.sleep(5)
            self.sock.close()
            self.connect()
            return self.get_oldest_tx(address, block_index, timeout=timeout)


# We hardcoded certain addresses to reproduce or fix `addrindexrs` bug.
GET_OLDEST_TX_HARDCODED = {
    # In comments the real result that `addrindexrs` should have returned.
    "825096-bc1q66u8n4q0ld3furqugr0xzakpedrc00wv8fagmf": {},  # {'block_index': 820886, 'tx_hash': 'e5d130a583983e5d9a9a9175703300f7597eadb6b54fe775055110907b4079ed'}
    # In comments the buggy result that `addrindexrs` returned.
    "820326-1GsjsKKT4nH4GPmDnaxaZEDWgoBpmexwMA": {
        "block_index": 820321,
        "tx_hash": "b61ac3ab1ba9d63d484e8f83e8b9607bd932c8f4b742095445c3527ab575d972",
    },  # {}
}
ADDRINDEXRS_CLIENT = None


def get_oldest_tx(address: str, block_index: int):
    init()
    if block_index is None:
        raise ValueError("block_index is required")
    current_block_index = block_index
    hardcoded_key = f"{current_block_index}-{address}"
    if hardcoded_key in GET_OLDEST_TX_HARDCODED:
        result = GET_OLDEST_TX_HARDCODED[hardcoded_key]
    else:
        global ADDRINDEXRS_CLIENT  # noqa: PLW0603
        if ADDRINDEXRS_CLIENT is None:
            ADDRINDEXRS_CLIENT = AddrindexrsSocket()
        result = ADDRINDEXRS_CLIENT.get_oldest_tx(address, block_index=current_block_index)

    return result
