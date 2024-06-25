import asyncio
import logging
import time
from concurrent.futures import ThreadPoolExecutor

from counterparty_rs import indexer

from counterpartycore.lib import config, util

logger = logging.getLogger(config.LOGGER_NAME)

WORKER_THREADS = 3
PREFETCH_QUEUE_SIZE = 5


class RSFetcher(metaclass=util.SingletonMeta):
    def __init__(self, start_height=0, config=None):
        if config is None:
            config = {
                "rpc_address": f"http://{config.BACKEND_CONNECT}:{config.BACKEND_PORT}",
                "rpc_user": config.BACKEND_USER,
                "rpc_password": config.BACKEND_PASSWORD,
                "db_dir": config.FETCHER_DB,
                "log_file": config.FETCHER_LOG,
                "log_level": config.LOG_LEVEL_STRING,
            }
        self.config = config | {"start_height": start_height}
        self.start_height = start_height
        self.next_height = start_height
        self.fetcher = None
        self.prefetch_task = None
        self.start()
        # prefetching
        self.stopped = False
        self.prefetch_queue = {}
        self.prefetch_queue_size = 0
        executor = ThreadPoolExecutor(max_workers=WORKER_THREADS)
        self.prefetch_task = executor.submit(self.prefetch_blocks)

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

    def get_prefetched_block(self, height):
        try:
            if height in self.prefetch_queue:
                block = self.prefetch_queue.pop(height)
                self.prefetch_queue_size -= 1
                logger.debug(
                    f"Block retrieved from queue. New queue size: {self.prefetch_queue_size}/{PREFETCH_QUEUE_SIZE}"
                )
                return block
            else:
                logger.debug("Block not found in prefetch queue. Retrying in 0.5 second.")
                time.sleep(0.5)
                return self.get_prefetched_block(height)
        except asyncio.QueueEmpty:
            logger.warning("Prefetch queue is empty. Fetching block directly.")
            return self.fetcher.get_block()

    def prefetch_blocks(self):
        logger.debug("Starting prefetching blocks...")
        while True and not self.stopped:
            try:
                # block = self.fetcher.get_block_non_blocking()
                block = self.fetcher.get_block()
                if block is not None:
                    self.prefetch_queue[block["height"]] = block
                    self.prefetch_queue_size += 1
                    logger.debug(
                        f"Block prefetched. Queue size: {self.prefetch_queue_size}/{PREFETCH_QUEUE_SIZE}"
                    )
                    if self.prefetch_queue_size > PREFETCH_QUEUE_SIZE:
                        logger.warning("Prefetch queue is full. Waiting before next fetch.")
                        time.sleep(1)
                else:
                    logger.debug("No block fetched. Waiting before next fetch.")
                    time.sleep(1)
            except asyncio.QueueFull:
                logger.debug("Prefetch queue is full. Waiting before next fetch.")
                time.sleep(1)  # Wait a bit before trying again
            except Exception as e:
                logger.error(f"Error prefetching block: {e}")

    def stop(self):
        logger.debug("Stopping fetcher...")
        try:
            self.stopped = True
            if self.fetcher:
                self.fetcher.stop()
            if self.prefetch_task:
                self.prefetch_task.cancel()
        except Exception as e:
            if str(e) == "Stopped error":
                pass
            else:
                raise e
        self.fetcher = None
        self.prefetch_task = None
