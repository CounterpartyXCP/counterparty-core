#! /usr/bin/python3

import time
import threading
import bitcoin as bitcoinlib
import logging
logger = logging.getLogger(__name__)
from logging import handlers as logging_handlers

from counterpartylib.lib import backend, util, config
from counterpartylib.lib import script
from .kickstart.utils import ib2h

BLOCK_COUNT_CHECK_FREQ = 100
BLOCKCHAIN_CACHE = {}
BLOCKCHAIN_CACHE_MAX_SIZE = 10000
PREFETCHER_THREADS = []

class Prefetcher(threading.Thread):

    def __init__(self, thread_index, num_threads, thread_first_block):
        threading.Thread.__init__(self)
        self.stop_event = threading.Event()
        self.thread_index = thread_index
        self.num_threads = num_threads
        self.block_first = thread_first_block
        self.fetch_block_index = thread_first_block

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

            BLOCKCHAIN_CACHE[self.fetch_block_index] = None

            #logger.debug('Fetching block {} with Prefetcher thread {}.'.format(self.fetch_block_index, self.thread_index))
            block_hash = backend.getblockhash(self.fetch_block_index)
            block = backend.getblock(block_hash)
            txhash_list, raw_transactions = backend.get_tx_list(block)
            BLOCKCHAIN_CACHE[self.fetch_block_index] = {'block_hash': block_hash,
                                             'txhash_list': txhash_list,
                                             'raw_transactions': raw_transactions,
                                             'previous_block_hash': bitcoinlib.core.b2lx(block.hashPrevBlock),
                                             'block_time': block.nTime,
                                             'block_difficulty': block.difficulty}

            # Index PubKeyHash -> PubKey
            for tx_hash in txhash_list:
                tx_hex = raw_transactions[tx_hash]
                ctx = backend.deserialize(tx_hex)

                print(ctx.vin)
                for vin in ctx.vin:
                    print(vin)
                    # vin_tx = backend.getrawtransaction(ib2h(vin.prevout.hash), block_index=self.fetch_block_index - 1)
                    try:
                        vin_tx = backend.getrawtransaction(ib2h(vin.prevout.hash))
                    except backend.addrindexrs.BackendRPCError:
                        continue
                    vin_ctx = backend.deserialize(vin_tx)

                    for vout in vin_ctx.vout:
                        asm = script.get_asm(vout.scriptPubKey)
                        if len(asm) == 5 and asm[0] == 'OP_DUP' and asm[1] == 'OP_HASH160' and asm[3] == 'OP_EQUALVERIFY' and asm[4] == 'OP_CHECKSIG':
                            pubkeyhash = asm[2]
                            pubkey = vin.scriptSig[1]   # TODO: integer
                            print(pubkeyhash, pubkey)   # TODO

            self.fetch_block_index += self.num_threads


def start_all(num_prefetcher_threads):
    # Block Prefetcher and Indexer
    block_first = util.CURRENT_BLOCK_INDEX
    for thread_index in range(1, num_prefetcher_threads + 1):
        thread_first_block = block_first + thread_index - 1
        prefetcher_thread = Prefetcher(thread_index, num_prefetcher_threads, thread_first_block)
        prefetcher_thread.daemon = True
        prefetcher_thread.start()
        PREFETCHER_THREADS.append(prefetcher_thread)

def stop_all():
    for prefetcher_thread in PREFETCHER_THREADS:
        prefetcher_thread.stop_event.set()





