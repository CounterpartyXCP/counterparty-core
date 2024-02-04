import time
import threading
import queue
import logging

import bitcoin as bitcoinlib

from counterpartylib.lib import backend, util, config

logger = logging.getLogger(__name__)

BLOCK_COUNT_CHECK_FREQ = 100
BLOCKCHAIN_CACHE = {}
BLOCKCHAIN_CACHE_MAX_SIZE = 10000
PREFETCHER_THREADS = []
NEXT_BLOCK_TO_PREFETCH = queue.Queue()

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
        logger.info('Starting Prefetcher process {}.'.format(self.thread_index))

        while True:
            if self.stop_event.is_set():
                break

            if len(BLOCKCHAIN_CACHE) >= BLOCKCHAIN_CACHE_MAX_SIZE:
                logger.debug('Blockchain cache is full. Sleeping Prefetcher thread {}.'.format(self.thread_index))
                time.sleep(10)
                continue

            block_index = next_block_index()
            if not block_index:
                continue

            logger.debug('Fetching block {} with Prefetcher thread {}.'.format(block_index, self.thread_index))
            block_hash = backend.getblockhash(block_index)
            block = backend.getblock(block_hash)
            txhash_list, raw_transactions = backend.get_tx_list(block, block_index=block_index)
            BLOCKCHAIN_CACHE[block_index] = {'block_hash': block_hash,
                                             'txhash_list': txhash_list,
                                             'raw_transactions': raw_transactions,
                                             'previous_block_hash': bitcoinlib.core.b2lx(block.hashPrevBlock),
                                             'block_time': block.nTime,
                                             'block_difficulty': block.difficulty}


def start_all(num_prefetcher_threads):
    # Block Prefetcher and Indexer
    block_first = config.BLOCK_FIRST_TESTNET if config.TESTNET else config.BLOCK_FIRST
    block_first = util.CURRENT_BLOCK_INDEX or block_first
    NEXT_BLOCK_TO_PREFETCH.put(block_first)
    for thread_index in range(1, num_prefetcher_threads + 1):
        prefetcher_thread = Prefetcher(thread_index)
        prefetcher_thread.daemon = True
        time.sleep(0.05) # avoid DOS
        prefetcher_thread.start()
        PREFETCHER_THREADS.append(prefetcher_thread)

def stop_all():
    for prefetcher_thread in PREFETCHER_THREADS:
        prefetcher_thread.stop_event.set()
