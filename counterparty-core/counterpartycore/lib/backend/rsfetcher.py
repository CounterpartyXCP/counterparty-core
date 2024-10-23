import errno
import fcntl
import logging
import os
import random
import threading
import time
import queue
from concurrent.futures import ThreadPoolExecutor

from counterparty_rs import indexer

from counterpartycore.lib import config, util

logger = logging.getLogger(config.LOGGER_NAME)

WORKER_THREADS = 3
PREFETCH_QUEUE_SIZE = 20


class RSFetcher(metaclass=util.SingletonMeta):
    thread_index_counter = 0  # Add a thread index counter

    def __init__(self, indexer_config=None):
        logger.debug("Initializing RSFetcher...")
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
            }
        else:
            self.config = indexer_config
        self.config["network"] = config.NETWORK_NAME
        self.fetcher = None
        self.prefetch_task = None
        self.running = False
        self.lock = threading.Lock()
        self.lockfile_path = os.path.join(self.config["db_dir"], "rocksdb.lock")
        self.lockfile = None

        # Initialize additional attributes
        self.executor = None
        self.stopped_event = threading.Event()  # Use an Event for stopping threads
        # Use queue.Queue for thread-safe prefetching
        self.prefetch_queue = queue.Queue(maxsize=PREFETCH_QUEUE_SIZE)
        self.prefetch_queue_initialized = False
        self.next_height = 0

    def acquire_lockfile(self):
        # Ensure the directory exists
        os.makedirs(self.config["db_dir"], exist_ok=True)
        logger.debug(f"RSFetcher - Ensured that directory {self.config['db_dir']} exists for lockfile.")

        try:
            fd = os.open(self.lockfile_path, os.O_CREAT | os.O_RDWR)
            self.lockfile = os.fdopen(fd, "w")
            fcntl.flock(self.lockfile, fcntl.LOCK_EX | fcntl.LOCK_NB)
            logger.debug("RSFetcher - Lockfile acquired.")
        except IOError as e:
            if e.errno in (errno.EACCES, errno.EAGAIN):
                logger.error(f"RSFetcher - Another instance is running. Unable to acquire lockfile: {e}")
                raise RuntimeError("Failed to acquire lockfile.") from e
            else:
                logger.error(f"RSFetcher - Unexpected error acquiring lockfile: {e}")
                raise

    def release_lockfile(self):
        if self.lockfile:
            if not self.lockfile.closed:
                fcntl.flock(self.lockfile, fcntl.LOCK_UN)
                self.lockfile.close()
                logger.debug("RSFetcher - Lockfile released.")
            else:
                logger.debug("RSFetcher - Lockfile was already closed.")
            os.remove(self.lockfile_path)

    def start(self, start_height=0):
        logger.info("Starting RSFetcher thread...")
        self.acquire_lockfile()
        try:
            self.config["start_height"] = start_height
            self.next_height = start_height
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
        # prefetching
        self.stopped_event.clear()  # Clear the stop event
        self.prefetch_queue = queue.Queue(maxsize=PREFETCH_QUEUE_SIZE)  # Reset the queue
        self.executor = ThreadPoolExecutor(max_workers=WORKER_THREADS)
        self.prefetch_task = self.executor.submit(self.prefetch_blocks)
        self.prefetch_queue_initialized = False

    def get_block(self):
        logger.trace("Fetching block with Rust backend.")
        block = self.get_prefetched_block()

        if block is None:
            # Fetcher has been stopped, handle accordingly
            logger.debug("No block retrieved. Fetcher might have stopped.")
            return None  # Handle as appropriate for your application

        # Handle potentially out-of-order blocks
        if block["height"] != self.next_height:
            logger.warning(f"Received block {block['height']} when expecting {self.next_height}")
            self.next_height = block["height"]

        self.next_height += 1

        if util.enabled("correct_segwit_txids", block_index=block["height"]):
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
        except Exception as e:
            logger.error(f"Error getting prefetched block: {e}")
            raise e

    def prefetch_blocks(self):
        logger.debug("Starting to prefetch blocks...")
        expected_height = self.next_height
        self.running = True
        while not self.stopped_event.is_set():
            try:
                block = self.fetcher.get_block_non_blocking()
                if block is not None:
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
                else:
                    logger.debug("No block fetched. Waiting before next fetch.")
                    # Use Event's wait method instead of time.sleep for better responsiveness
                    self.stopped_event.wait(timeout=random.uniform(0.2, 0.7))  # noqa: S311
            except Exception as e:
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
        except Exception as e:
            logger.error(f"Error during stop: {e}")
            if str(e) != "Stopped error":
                raise e
        finally:
            self.fetcher = None
            self.prefetch_task = None
            self.release_lockfile()
            logger.info("RSFetcher thread stopped.")

    def restart(self):
        self.stop()
        while self.running:
            time.sleep(0.1)
        self.start(self.next_height)

def stop():
    if RSFetcher in RSFetcher._instances and RSFetcher._instances[RSFetcher] is not None:
        RSFetcher().stop()
