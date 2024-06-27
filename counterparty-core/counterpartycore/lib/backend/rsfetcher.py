import asyncio
import logging
import time
from concurrent.futures import ThreadPoolExecutor
from threading import Lock, Condition, current_thread
import random

from counterparty_rs import indexer

from counterpartycore.lib import config, util

logger = logging.getLogger(config.LOGGER_NAME)

WORKER_THREADS = 3
PREFETCH_QUEUE_SIZE = 20


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
                while height not in self.prefetch_queue:
                    logger.warning(f"[Thread {self.thread_index}] Block {height} not found in prefetch queue. Waiting for prefetch.")
                    self.queue_condition.wait(timeout=.1)  # Wait for the block to be prefetched
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
        except Exception as e:
            logger.error(f"[Thread {self.thread_index}] Error getting prefetched block: {e}")
            return self.fetcher.get_block()

    def prefetch_blocks(self):
        logger.debug("[Thread %s] Starting prefetching blocks...", self.thread_index)
        expected_height = self.next_height
        while not self.stopped:
            try:
                with self.queue_lock:
                    while self.prefetch_queue_size >= PREFETCH_QUEUE_SIZE and not self.stopped:
                        self.queue_condition.wait(timeout=0.1)  # Wait until there is space in the queue
                    if self.stopped:
                        break
                    block = self.fetcher.get_block_non_blocking()
                    if block is not None:
                        self.prefetch_queue[block["height"]] = block
                        self.prefetch_queue_size += 1
                        expected_height += 1
                        self.queue_condition.notify_all()  # Notify all waiting threads
                        logger.debug(
                            "[Thread %s] Block %s prefetched. Queue size: %s/%s",
                            self.thread_index,
                            block['height'],
                            self.prefetch_queue_size,
                            PREFETCH_QUEUE_SIZE
                        )
                    else:
                        logger.debug("[Thread %s] No block fetched. Waiting before next fetch.", self.thread_index)
                        time.sleep(random.uniform(0.2, 0.7))
            except Exception as e:
                logger.error(f"[Thread {self.thread_index}] Error prefetching block: {e}")
                time.sleep(random.uniform(0.8, 2.0))  # Longer wait on error
        logger.debug("[Thread %s] Prefetching blocks stopped.", self.thread_index)

    def stop(self):
        logger.info("Stopping fetcher...", self.thread_index)
        self.stopped = True
        try:
            if self.prefetch_task:
                self.prefetch_task.cancel()
                logger.debug("[Thread %s] Prefetch task canceled.", self.thread_index)
            if self.executor:
                self.executor.shutdown(wait=True)
                logger.debug("Executor shutdown complete.", self.thread_index)
            if self.fetcher:
                self.fetcher.stop()
                logger.info("[Thread %s] Fetcher stopped.", self.thread_index)
        except Exception as e:
            logger.error(f"[Thread {self.thread_index}] Error during stop: {e}")
            if str(e) != "Stopped error":
                raise e
        finally:
            self.fetcher = None
            self.prefetch_task = None
            logger.debug("[Thread %s] Fetcher and prefetch task set to None.", self.thread_index)

