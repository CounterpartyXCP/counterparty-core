import logging
import queue
import threading
import time
from collections import OrderedDict

from counterpartycore.lib import backend, config, deserialize, util

logger = logging.getLogger(config.LOGGER_NAME)


BLOCKCHAIN_CACHE = {}
BLOCKCHAIN_CACHE_MAX_SIZE = 100
PREFETCHER_THREADS = []
NEXT_BLOCK_TO_PREFETCH = queue.Queue()
TRANSACTIONS_CACHE = OrderedDict()
TRANSACTIONS_CACHE_MAX_SIZE = 10000


def next_block_index():
    block_index = NEXT_BLOCK_TO_PREFETCH.get()
    NEXT_BLOCK_TO_PREFETCH.put(block_index + 1)
    return block_index


class Prefetcher(threading.Thread):
    def __init__(self, thread_index):
        threading.Thread.__init__(self)
        self.stop_event = threading.Event()
        self.thread_index = thread_index

    def stop(self):
        self.stop_event.set()

    def run(self):
        logger.info(f"Starting Prefetcher process {self.thread_index}.")

        while True:
            if self.stop_event.is_set():
                break

            if len(BLOCKCHAIN_CACHE) >= BLOCKCHAIN_CACHE_MAX_SIZE:
                logger.debug(
                    f"Blockchain cache is full. Sleeping Prefetcher thread {self.thread_index}."
                )
                time.sleep(10)
                continue

            block_index = next_block_index()
            if not block_index:
                continue

            logger.trace(
                f"Fetching block {block_index} with Prefetcher thread {self.thread_index}."
            )
            get_decoded_block(block_index)


def start_all(num_prefetcher_threads):
    # Block Prefetcher and Indexer
    block_first = config.BLOCK_FIRST_TESTNET if config.TESTNET else config.BLOCK_FIRST
    block_first = util.CURRENT_BLOCK_INDEX or block_first
    NEXT_BLOCK_TO_PREFETCH.put(block_first)
    for thread_index in range(1, num_prefetcher_threads + 1):
        prefetcher_thread = Prefetcher(thread_index)
        prefetcher_thread.daemon = True
        time.sleep(0.05)  # avoid DOS
        prefetcher_thread.start()
        PREFETCHER_THREADS.append(prefetcher_thread)


def stop_all():
    for prefetcher_thread in PREFETCHER_THREADS:
        prefetcher_thread.stop_event.set()


def add_transaction_in_cache(tx_hash, tx):
    TRANSACTIONS_CACHE[tx_hash] = tx
    if len(TRANSACTIONS_CACHE) > TRANSACTIONS_CACHE_MAX_SIZE:
        TRANSACTIONS_CACHE.popitem(last=False)


def add_block_in_cache(block_index, block):
    BLOCKCHAIN_CACHE[block_index] = block
    for transaction in block["transactions"]:
        add_transaction_in_cache(transaction["tx_hash"], transaction)


def get_decoded_block(block_index):
    if block_index in BLOCKCHAIN_CACHE:
        # remove from cache when used
        return BLOCKCHAIN_CACHE.pop(block_index)

    block_hash = backend.bitcoind.getblockhash(block_index)
    raw_block = backend.bitcoind.getblock(block_hash)
    use_txid = util.enabled("correct_segwit_txids", block_index=block_index)
    block = deserialize.deserialize_block(raw_block, use_txid=use_txid)

    add_block_in_cache(block_index, block)

    return block


def get_decoded_transaction(tx_hash, block_index=None):
    if tx_hash in TRANSACTIONS_CACHE:
        return TRANSACTIONS_CACHE[tx_hash]

    raw_tx = backend.bitcoind.getrawtransaction(tx_hash)
    use_txid = util.enabled("correct_segwit_txids", block_index=block_index)
    tx = deserialize.deserialize_tx(raw_tx, use_txid=use_txid)

    add_transaction_in_cache(tx_hash, tx)

    return tx
