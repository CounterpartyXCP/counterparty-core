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
    thread_index_counter = 0

    def __init__(self, start_height=0, indexer_config=None):
        self.thread_index = RSFetcher.thread_index_counter
        RSFetcher.thread_index_counter += 1
        self.config = indexer_config or {
            "rpc_address": f"http://{config.BACKEND_CONNECT}:{config.BACKEND_PORT}",
            "rpc_user": config.BACKEND_USER,
            "rpc_password": config.BACKEND_PASSWORD,
            "db_dir": config.FETCHER_DB,
            "log_file": config.FETCHER_LOG,
            "log_level": config.LOG_LEVEL_STRING,
            "start_height": start_height,
        }
        self.config["start_height"] = start_height
        self.start_height = start_height
        self.next_height = start_height
        self.fetcher = None
        self.prefetch_task = None
        self.stopped = False
        self.prefetch_queue = {}
        self.prefetch_queue_size = 0
        self.executor = ThreadPoolExecutor(max_workers=WORKER_THREADS)
        self.queue_lock = Lock()
        self.queue_condition = Condition(self.queue_lock)
        self.start()
        self.prefetch_task = self.executor.submit(self.prefetch_blocks)

    def start(self):
        try:
            self.fetcher = indexer.Indexer(self.config)
            fetcher_version = self.fetcher.get_version()
            logger.debug(f"[Thread {self.thread_index}] Current Fetcher version: {fetcher_version}")
            if fetcher_version != config.__version__:
                logger.error(
                    f"[Thread {self.thread_index}] Fetcher version mismatch. Expected: {config.__version__}, Got: {fetcher_version}. Please re-compile `counterparty-rs`."
                )
                raise Exception("Fetcher version mismatch.")
            self.fetcher.start()
        except Exception as e:
            logger.error(f"[Thread {self.thread_index}] Failed to initialize fetcher: {e}. Retrying in 5 seconds...")
            time.sleep(5)
            self.start()

    def get_block(self):
        logger.trace(f"[Thread {self.thread_index}] Fetching block with Rust backend.")
        block = self.get_prefetched_block(self.next_height)
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
                    self.queue_condition.wait(timeout=.1)
                block = self.prefetch_queue.pop(height)
                self.prefetch_queue_size -= 1
                self.queue_condition.notify()
                logger.debug(
                    f"[Thread {self.thread_index}] Block {height} retrieved from queue. New queue size: {self.prefetch_queue_size}/{PREFETCH_QUEUE_SIZE}"
                )
                return block
        except Exception as e:
            logger.error(f"[Thread {self.thread_index}] Error getting prefetched block: {e}")
            return self.fetcher.get_block()

    def prefetch_blocks(self):
        logger.debug(f"[Thread {self.thread_index}] Starting prefetching blocks...")
        expected_height = self.next_height
        while not self.stopped:
            try:
                with self.queue_lock:
                    while self.prefetch_queue_size >= PREFETCH_QUEUE_SIZE:
                        self.queue_condition.wait()
                    block = self.fetcher.get_block_non_blocking()
                    if block:
                        self.prefetch_queue[block["height"]] = block
                        self.prefetch_queue_size += 1
                        expected_height += 1
                        self.queue_condition.notify_all()
                        logger.debug(
                            f"[Thread {self.thread_index}] Block {block['height']} prefetched. Queue size: {self.prefetch_queue_size}/{PREFETCH_QUEUE_SIZE}"
                        )
                    else:
                        logger.debug(f"[Thread {self.thread_index}] No block fetched. Waiting before next fetch.")
                        time.sleep(random.uniform(0.2, 0.7))
            except Exception as e:
                logger.error(f"[Thread {self.thread_index}] Error prefetching block: {e}")
                time.sleep(random.uniform(0.8, 2.0))

    def stop(self):
        logger.debug(f"[Thread {self.thread_index}] Stopping fetcher...")
        try:
            self.stopped = True
            if self.prefetch_task:
                self.prefetch_task.cancel()
                self.executor.shutdown(wait=True)
            if self.fetcher:
                self.fetcher.stop()
        except Exception as e:
            if str(e) != "Stopped error":
                raise e
        self.fetcher = None
        self.prefetch_task = None
