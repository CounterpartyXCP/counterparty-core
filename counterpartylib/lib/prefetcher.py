#! /usr/bin/python3

import time
import threading
import bitcoin as bitcoinlib
import logging
logger = logging.getLogger(__name__)
from logging import handlers as logging_handlers

from counterpartylib.lib import backend

BLOCK_COUNT_CHECK_FREQ = 100
BLOCKCHAIN_CACHE = {}
BLOCKCHAIN_CACHE_MAX_SIZE = 1000
PREFETCHER_THREADS = []

class Prefetcher(threading.Thread):

    def __init__(self, thread_index, num_threads):
        threading.Thread.__init__(self)
        self.stop_event = threading.Event()
        self.thread_index = thread_index
        self.num_threads = num_threads
        self.block_count = backend.getblockcount()
        assert self.num_threads < BLOCK_COUNT_CHECK_FREQ

    def stop(self):
        self.stop_event.set()

    def run(self):
        logger.info('Starting Prefetcher process.')

        block_index = self.thread_index - 1
        while True:
            if self.stop_event.is_set():
                break

            if len(BLOCKCHAIN_CACHE) >= BLOCKCHAIN_CACHE_MAX_SIZE:
                logger.debug('Blockchain cache is full. Sleeping Prefetcher thread {}.'.format(self.thread_index))
                time.sleep(10)
                continue

            if block_index % BLOCK_COUNT_CHECK_FREQ == 0:
                block_count = backend.getblockcount()
            if block_index >= self.block_count:
                self.stop_event.set()   # This is only for catching up when behind.
                break

            logger.debug('Fetching block {} with Prefetcher thread {}.'.format(block_index, self.thread_index))
            block_hash = backend.getblockhash(block_index)
            block = backend.getblock(block_hash)
            txhash_list, raw_transactions = backend.get_tx_list(block)
            BLOCKCHAIN_CACHE[block_index] = {'block_hash': block_hash,
                                             'txhash_list': txhash_list,
                                             'raw_transactions': raw_transactions,
                                             'previous_block_hash': bitcoinlib.core.b2lx(block.hashPrevBlock),
                                             'block_time': block.nTime,
                                             'block_difficulty': block.difficulty}

            block_index += self.num_threads

def start_all(num_prefetcher_threads):
    # Block Prefetcher and Indexer
    for thread_index in range(1, num_prefetcher_threads + 1):
        prefetcher_thread = Prefetcher(thread_index, num_prefetcher_threads)
        prefetcher_thread.daemon = True
        prefetcher_thread.start()
        PREFETCHER_THREADS.append(prefetcher_thread)

def stop_all():
    for prefetcher_thread in PREFETCHER_THREADS:
        prefetcher_thread.stop_event.set()
