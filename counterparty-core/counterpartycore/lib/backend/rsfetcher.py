import asyncio
import logging
import time
from concurrent.futures import ThreadPoolExecutor
from threading import Lock, Condition, current_thread
import random

from counterparty_rs import indexer

from counterpartycore.lib import config, util

logger = logging.getLogger(config.LOGGER_NAME)

WORKER_THREADS = 20
PREFETCH_QUEUE_SIZE = 100


class RSFetcher(metaclass=util.SingletonMeta):
    thread_index_counter = 0  # Add a thread index counter

    def __init__(self, start_height=0, indexer_config=None):
        self.thread_index = RSFetcher.thread_index_counter
        RSFetcher.thread_index_counter += 1
        if indexer_config is None:
            self.config = {
                "rpc_address": f"http://{config.BACKEND_CONNECT}:{config.BACKEND_PORT}",
                "rpc_user": config.BACKEND_USER,
                "rpc_password": config.BACKEND_PASSWORD,
                "db_dir": config.FETCHER_DB,
                "log_file": config.FETCHER_LOG,
                "log_level": config.LOG_LEVEL_STRING,
                "start_height": start_height,
            }
        else:
            self.config = indexer_config | {"start_height": start_height}
        self.start_height = start_height
        self.next_height = start_height
        self.fetcher = None
        self.prefetch_task = None
        self.start()
        # prefetching
        self.stopped = False
        self.prefetch_queue = {}
        self.prefetch_queue_size = 0
        self.executor = ThreadPoolExecutor(max_workers=WORKER_THREADS)
        self.queue_lock = Lock()
        self.queue_condition = Condition(self.queue_lock)  # Add a condition variable
        self.prefetch_task = self.executor.submit(self.prefetch_blocks)

    def start(self):
        try:
            self.fetcher = indexer.Indexer(self.config)
            # check fetcher version
            fetcher_version = self.fetcher.get_version()
            logger.debug("[Thread %s] Current Fetcher version: %s", self.thread_index, fetcher_version)
            if fetcher_version != config.__version__:
                logger.error(
                    "[Thread %s] Fetcher version mismatch. Expected: %s, Got: %s. Please re-compile `counterparty-rs`.",
                    self.thread_index,
                    config.__version__,
                    fetcher_version,
                )
                raise Exception("Fetcher version mismatch.")
            else:
                # start fetcher
                self.fetcher.start()
        except Exception as e:
            logger.error(f"[Thread {self.thread_index}] Failed to initialize fetcher: {e}. Retrying in 5 seconds...")
            time.sleep(5)
            self.start()

    def get_block(self):
        logger.trace("[Thread %s] Fetching block with Rust backend.", self.thread_index)
        block = self.get_prefetched_block(self.next_height)
        
        # Handle potentially out-of-order blocks
        if block['height'] != self.next_height:
            logger.warning(f"Received block {block['height']} when expecting {self.next_height}")
            self.next_height = block['height']
        
        self.next_height += 1

        if util.enabled("correct_segwit_txids", block_index=block["height"]):
            for tx in block["transactions"]:
                tx["tx_hash"] = tx["tx_id"]

        return block

    def get_prefetched_block(self, height):
        try:
            with self.queue_lock:
                if height in self.prefetch_queue:
                    block = self.prefetch_queue.pop(height)
                    self.prefetch_queue_size -= 1
                    self.queue_condition.notify()  # Notify the prefetching thread
                    logger.debug(
                        "[Thread %s] Block %s retrieved from queue. New queue size: %s/%s",
                        self.thread_index,
                        height,
                        self.prefetch_queue_size,
                        PREFETCH_QUEUE_SIZE
                    )
                    return block
                else:
                    logger.warning(f"[Thread {self.thread_index}] Block {height} not found in prefetch queue. Fetching directly.")
                    return self.fetcher.get_block()
        except Exception as e:
            logger.error(f"[Thread {self.thread_index}] Error getting prefetched block: {e}")
            return self.fetcher.get_block()

    def prefetch_blocks(self):
        logger.debug("[Thread %s] Starting prefetching blocks...", self.thread_index)
        expected_height = self.next_height
        while True and not self.stopped:
            try:
                with self.queue_lock:
                    while self.prefetch_queue_size >= PREFETCH_QUEUE_SIZE:
                        self.queue_condition.wait()  # Wait until there is space in the queue
                    block = self.fetcher.get_block_non_blocking()
                    if block is not None:
                        self.prefetch_queue[block["height"]] = block
                        self.prefetch_queue_size += 1
                        expected_height += 1
                        logger.debug(
                            "[Thread %s] Block %s prefetched. Queue size: %s/%s",
                            self.thread_index,
                            block['height'],
                            self.prefetch_queue_size,
                            PREFETCH_QUEUE_SIZE
                        )
                    else:
                        logger.debug("[Thread %s] No block fetched. Waiting before next fetch.", self.thread_index)
                        time.sleep(random.uniform(0.5, 1.5))
            except Exception as e:
                logger.error(f"[Thread {self.thread_index}] Error prefetching block: {e}")
                time.sleep(random.uniform(1, 3))  # Longer wait on error

    def stop(self):
        logger.debug("[Thread %s] Stopping fetcher...", self.thread_index)
        try:
            self.stopped = True
            if self.prefetch_task:
                self.executor.shutdown(wait=False, cancel_futures=True)
                self.prefetch_task.cancel()
                while not self.prefetch_task.done():
                    time.sleep(0.1)
            if self.fetcher:
                self.fetcher.stop()

        except Exception as e:
            if str(e) == "Stopped error":
                pass
            else:
                raise e
        self.fetcher = None
        self.prefetch_task = None
