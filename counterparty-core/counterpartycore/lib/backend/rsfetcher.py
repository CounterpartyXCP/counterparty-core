import asyncio
import logging
import time
from concurrent.futures import ThreadPoolExecutor
from threading import Lock
import random

from counterparty_rs import indexer

from counterpartycore.lib import config, util

logger = logging.getLogger(config.LOGGER_NAME)

WORKER_THREADS = 20
PREFETCH_QUEUE_SIZE = 100


class RSFetcher(metaclass=util.SingletonMeta):
    def __init__(self, start_height=0, indexer_config=None):
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
        self.prefetch_task = self.executor.submit(self.prefetch_blocks)

    def start(self):
        try:
            self.fetcher = indexer.Indexer(self.config)
            # check fetcher version
            fetcher_version = self.fetcher.get_version()
            logger.debug("Current Fetcher version: %s", fetcher_version)
            if fetcher_version != config.__version__:
                logger.error(
                    "Fetcher version mismatch. Expected: %s, Got: %s. Please re-compile `counterparty-rs`.",
                    config.__version__,
                    fetcher_version,
                )
                raise Exception("Fetcher version mismatch.")
            else:
                # start fetcher
                self.fetcher.start()
        except Exception as e:
            logger.error(f"Failed to initialize fetcher: {e}. Retrying in 5 seconds...")
            time.sleep(5)
            self.start()

    def get_block(self):
        logger.trace("Fetching block with Rust backend.")
        block = self.get_prefetched_block(self.next_height)
        self.next_height += 1

        if util.enabled("correct_segwit_txids", block_index=block["height"]):
            for tx in block["transactions"]:
                tx["tx_hash"] = tx["tx_id"]

        return block

    def prefetch_blocks(self):
        logger.debug("Starting prefetching blocks...")
        expected_height = self.next_height
        while True and not self.stopped:
            try:
                with self.queue_lock:
                    if self.prefetch_queue_size < PREFETCH_QUEUE_SIZE:
                        block = self.fetcher.get_block_non_blocking()
                        if block is not None:
                            self.prefetch_queue[block["height"]] = block
                            self.prefetch_queue_size += 1
                            expected_height += 1
                            logger.debug(
                                f"Block {block['height']} prefetched. Queue size: {self.prefetch_queue_size}/{PREFETCH_QUEUE_SIZE}"
                            )
                        else:
                            logger.debug("No block fetched. Waiting before next fetch.")
                            time.sleep(random.uniform(0.5, 1.5))
                    else:
                        logger.debug("Prefetch queue full. Waiting before next fetch.")
                        time.sleep(random.uniform(0.5, 1.5))
            except Exception as e:
                logger.error(f"Error prefetching block: {e}")
                time.sleep(random.uniform(1, 3))  # Longer wait on error

    def get_prefetched_block(self, height):
        try:
            with self.queue_lock:
                if height in self.prefetch_queue:
                    block = self.prefetch_queue.pop(height)
                    self.prefetch_queue_size -= 1
                    logger.debug(
                        f"Block {height} retrieved from queue. New queue size: {self.prefetch_queue_size}/{PREFETCH_QUEUE_SIZE}"
                    )
                    return block
                else:
                    logger.warning(f"Block {height} not found in prefetch queue. Fetching directly.")
                    return self.fetcher.get_block()
        except Exception as e:
            logger.error(f"Error getting prefetched block: {e}")
            return self.fetcher.get_block()

    def stop(self):
        logger.debug("Stopping fetcher...")
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
