import logging
import random
import time
from concurrent.futures import ThreadPoolExecutor

from counterparty_rs import indexer

from counterpartycore.lib import config, util

logger = logging.getLogger(config.LOGGER_NAME)

WORKER_THREADS = 3
PREFETCH_QUEUE_SIZE = 20


class RSFetcher(metaclass=util.SingletonMeta):
    thread_index_counter = 0  # Add a thread index counter

    def __init__(self, start_height=0, indexer_config=None):
        RSFetcher.thread_index_counter += 1
        if indexer_config is None:
            self.config = {
                "rpc_address": f"http://{config.BACKEND_CONNECT}:{config.BACKEND_PORT}",
                "rpc_user": config.BACKEND_USER,
                "rpc_password": config.BACKEND_PASSWORD,
                "db_dir": config.FETCHER_DB,
                "log_file": config.FETCHER_LOG,
                "log_level": config.LOG_LEVEL_STRING,
                "json_format": config.JSON_LOGS,
                "start_height": start_height,
            }
        else:
            self.config = indexer_config | {"start_height": start_height}
        self.config["network"] = "testnet" if config.TESTNET else "mainnet"
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
        self.prefetch_task = self.executor.submit(self.prefetch_blocks)
        self.prefetch_queue_initialized = False

    def start(self):
        logger.debug("Starting Prefetcher...")
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
                raise ValueError(
                    f"Fetcher version mismatch {config.__version__} != {fetcher_version}."
                )
            self.fetcher.start()
        except Exception as e:
            logger.error(f"Failed to initialize fetcher: {e}. Retrying in 5 seconds...")
            raise e

    def get_block(self):
        logger.trace("Fetching block with Rust backend.")
        block = self.get_prefetched_block(self.next_height)

        # Handle potentially out-of-order blocks
        if block["height"] != self.next_height:
            logger.warning(f"Received block {block['height']} when expecting {self.next_height}")
            self.next_height = block["height"]

        self.next_height += 1

        if util.enabled("correct_segwit_txids", block_index=block["height"]):
            for tx in block["transactions"]:
                tx["tx_hash"] = tx["tx_id"]

        return block

    def get_prefetched_block(self, height):
        try:
            logger.debug(f"Looking for Block {height} in prefetch queue...")
            while height not in self.prefetch_queue:
                if self.prefetch_queue_size == 0 and self.prefetch_queue_initialized:
                    logger.trace("Prefetch queue is empty.")
                logger.debug(f"Block {height} not found in prefetch queue. Waiting...")
                time.sleep(0.1)
            block = self.prefetch_queue.pop(height)
            self.prefetch_queue_size -= 1
            logger.debug(
                "Block %s retrieved from queue. (Queue: %s/%s)",
                height,
                self.prefetch_queue_size,
                PREFETCH_QUEUE_SIZE,
            )
            return block
        except Exception as e:
            logger.error(f"Error getting prefetched block: {e}")
            raise e

    def prefetch_blocks(self):
        logger.debug("Starting prefetching blocks...")
        expected_height = self.next_height
        while not self.stopped:
            try:
                while self.prefetch_queue_size >= PREFETCH_QUEUE_SIZE and not self.stopped:
                    time.sleep(0.1)  # Wait until there is space in the queue
                if self.stopped:
                    break
                block = self.fetcher.get_block_non_blocking()
                if block is not None:
                    self.prefetch_queue[block["height"]] = block
                    self.prefetch_queue_size += 1
                    expected_height += 1
                    logger.debug(
                        "Block %s prefetched. (Queue: %s/%s)",
                        block["height"],
                        self.prefetch_queue_size,
                        PREFETCH_QUEUE_SIZE,
                    )

                    # Mark the queue as "initialized" after it has been half-full at least once.
                    if (
                        not self.prefetch_queue_initialized
                        and self.prefetch_queue_size >= PREFETCH_QUEUE_SIZE // 2
                    ):
                        self.prefetch_queue_initialized = True
                        logger.debug("Prefetch queue initialized.")

                else:
                    logger.debug("No block fetched. Waiting before next fetch.")
                    time.sleep(random.uniform(0.2, 0.7))  # noqa: S311
            except Exception as e:
                logger.error(f"Error prefetching block: {e}")
                time.sleep(random.uniform(0.8, 2.0))  # noqa: S311; longer wait on error
        logger.debug("Prefetching blocks stopped.")

    def stop(self):
        logger.info("Stopping prefetcher...")
        self.stopped = True
        try:
            if self.prefetch_task:
                self.prefetch_task.cancel()
                logger.debug("Prefetch task cancelled.")
            if self.executor:
                self.executor.shutdown(wait=True)
                logger.debug("Executor shutdown complete.")
            if self.fetcher:
                self.fetcher.stop()
                logger.debug("Prefetcher stopped.")
        except Exception as e:
            logger.error(f"Error during stop: {e}")
            if str(e) != "Stopped error":
                raise e
        finally:
            self.fetcher = None
            self.prefetch_task = None
            logger.debug("Prefetcher shutdown complete.")


def stop():
    if RSFetcher in RSFetcher._instances and RSFetcher._instances[RSFetcher] is not None:
        RSFetcher().stop()
