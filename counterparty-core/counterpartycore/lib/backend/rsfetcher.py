import logging
import os
import queue
import shutil
import threading
import time
from concurrent.futures import ThreadPoolExecutor

from counterparty_rs import indexer  # pylint: disable=no-name-in-module

from counterpartycore.lib import config, exceptions
from counterpartycore.lib.parser import protocol
from counterpartycore.lib.utils import helpers

logger = logging.getLogger(config.LOGGER_NAME)

WORKER_THREADS = 3
PREFETCH_QUEUE_SIZE = 20


def delete_database_directory():
    if os.path.isdir(config.FETCHER_DB_OLD):
        shutil.rmtree(config.FETCHER_DB_OLD)
        logger.debug(f"RSFetcher - Deleted old database at {config.FETCHER_DB_OLD}")

    if os.path.isdir(config.FETCHER_DB):
        shutil.rmtree(config.FETCHER_DB)
        logger.debug(f"RSFetcher - Reset database at {config.FETCHER_DB}")


class RSFetcher(metaclass=helpers.SingletonMeta):
    thread_index_counter = 0  # Add a thread index counter

    def __init__(self, indexer_config=None):
        logger.debug("Initializing RSFetcher...")
        RSFetcher.thread_index_counter += 1
        if indexer_config is None:
            rpc_address = f"://{config.BACKEND_CONNECT}:{config.BACKEND_PORT}"
            if config.BACKEND_SSL:
                rpc_address = f"https{rpc_address}"
            else:
                rpc_address = f"http{rpc_address}"
            self.config = {
                "rpc_address": rpc_address,
                "rpc_user": config.BACKEND_USER,
                "rpc_password": config.BACKEND_PASSWORD,
                "db_dir": config.FETCHER_DB,
                "log_file": config.FETCHER_LOG,
                "json_format": config.JSON_LOGS,
                "only_write_in_reorg_window": True,
            }
            if (
                isinstance(config.LOG_EXCLUDE_FILTERS, list)
                and "RSFETCHER" in config.LOG_EXCLUDE_FILTERS
            ):
                self.config["log_level"] = "OFF"
            elif isinstance(config.LOG_INCLUDE_FILTERS, list):
                if "RSFETCHER" in config.LOG_INCLUDE_FILTERS:
                    self.config["log_level"] = config.LOG_LEVEL_STRING
                else:
                    self.config["log_level"] = "OFF"
            else:
                self.config["log_level"] = config.LOG_LEVEL_STRING
        else:
            logger.warning("Using custom indexer config.")
            self.config = indexer_config
        self.config["network"] = config.NETWORK_NAME
        self.fetcher = None
        self.prefetch_task = None
        self.running = False

        # Initialize additional attributes
        self.executor = None
        self.stopped_event = threading.Event()  # Use an Event for stopping threads
        # Use queue.Queue for thread-safe prefetching
        self.prefetch_queue = queue.Queue(maxsize=PREFETCH_QUEUE_SIZE)
        self.prefetch_queue_initialized = False
        self.next_height = 0

    def start(self, start_height=0):
        logger.info("Starting RSFetcher thread...")

        self.config["start_height"] = start_height
        self.next_height = start_height
        self.fetcher = indexer.Indexer(self.config)
        # check fetcher version
        fetcher_version = self.fetcher.get_version()
        logger.debug("Current Fetcher version: %s", fetcher_version)
        if fetcher_version != config.__version__:
            error_message = f"Fetcher version mismatch. Expected: {config.__version__}, Got: {fetcher_version}. "
            error_message += "Please re-compile `counterparty-rs`."
            raise exceptions.InvalidVersion(error_message)
        self.fetcher.start()

        # prefetching
        self.stopped_event.clear()  # Clear the stop event
        self.prefetch_queue = queue.Queue(maxsize=PREFETCH_QUEUE_SIZE)  # Reset the queue
        self.executor = ThreadPoolExecutor(
            max_workers=WORKER_THREADS, thread_name_prefix="RSFetcher.Prefetcher"
        )
        self.prefetch_task = self.executor.submit(self.prefetch_blocks)
        self.prefetch_queue_initialized = False

    def get_block(self):
        block = self.get_prefetched_block()

        if block is None:
            # handled in blocks.catch_up()
            return None

        # Handle potentially out-of-order blocks
        if block["height"] != self.next_height:
            logger.warning(f"Received block {block['height']} when expecting {self.next_height}")
            self.next_height = block["height"]

        self.next_height += 1

        if protocol.enabled("correct_segwit_txids", block_index=block["height"]):
            for tx in block["transactions"]:
                tx["tx_hash"] = tx["tx_id"]

        return block

    def get_prefetched_block(self):
        try:
            logger.debug("Looking for block in prefetch queue...")
            while not self.stopped_event.is_set():
                try:
                    block = self.prefetch_queue.get(timeout=1)
                    logger.debug(
                        "Block %s retrieved from queue. (Queue size: %s)",
                        block["height"],
                        self.prefetch_queue.qsize(),
                    )
                    return block
                except queue.Empty:
                    logger.debug("Prefetch queue is empty; waiting for blocks...")
            # If stopped and queue is empty
            logger.debug("Fetcher stopped and prefetch queue is empty.")
            return None
        except Exception as e:  # pylint: disable=broad-except
            logger.error(f"Error getting prefetched block: {e}")
            raise e

    def prefetch_blocks(self):
        logger.debug("Starting to prefetch blocks...")
        expected_height = self.next_height
        self.running = True
        retry = 0
        while not self.stopped_event.is_set():
            try:
                block = self.fetcher.get_block_non_blocking()
                if block is not None:
                    retry = 0
                    while not self.stopped_event.is_set():
                        try:
                            self.prefetch_queue.put(block, timeout=1)
                            expected_height += 1
                            logger.debug(
                                "Block %s prefetched. (Queue size: %s/%s)",
                                block["height"],
                                self.prefetch_queue.qsize(),
                                PREFETCH_QUEUE_SIZE,
                            )

                            # Mark the queue as "initialized" after it has been half-full at least once.
                            if (
                                not self.prefetch_queue_initialized
                                and self.prefetch_queue.qsize() >= PREFETCH_QUEUE_SIZE // 2
                            ):
                                self.prefetch_queue_initialized = True
                                logger.debug("Prefetch queue initialized.")
                            break  # Break out of the inner loop after successfully putting the block
                        except queue.Full:
                            logger.debug("Prefetch queue is full; waiting...")
                            time.sleep(0.1)
                elif not self.stopped_event.is_set():
                    retry += 1
                    logger.debug(f"Waiting to prefetch block {expected_height}...({retry / 10}s)")
                    # Use Event's wait method instead of time.sleep for better responsiveness
                    self.stopped_event.wait(retry / 10)  # noqa: S311
            except Exception as e:  # pylint: disable=broad-except
                if str(e) == "Stopped error":
                    logger.warning(
                        "RSFetcher thread found stopped due to an error. Restarting in 5 seconds..."
                    )
                    self.stopped_event.wait(timeout=5)
                    self.restart()
                else:
                    raise e
        self.running = False
        logger.debug("Prefetching blocks stopped.")

    def stop(self):
        logger.info("Stopping RSFetcher thread...")
        self.stopped_event.set()  # Signal all threads to stop
        try:
            if self.prefetch_task:
                # No need to cancel; threads should exit when they check the stop event
                logger.debug("Waiting for prefetch task to finish...")
            if self.executor:
                self.executor.shutdown(wait=True)
                logger.debug("Executor shutdown complete.")
            if self.fetcher:
                self.fetcher.stop()
                logger.debug("Fetcher stopped.")
        except Exception as e:  # pylint: disable=broad-except
            logger.error(f"Error during stop: {e}")
            if str(e) != "Stopped error":
                raise e
        finally:
            self.fetcher = None
            self.prefetch_task = None
            logger.info("RSFetcher thread stopped.")

    def restart(self):
        self.stop()
        while self.running:
            time.sleep(0.1)
        self.start(self.next_height)


def stop():
    if RSFetcher in RSFetcher._instances and RSFetcher._instances[RSFetcher] is not None:
        RSFetcher().stop()
