import logging
import sys
import time
import asyncio
from concurrent.futures import ThreadPoolExecutor

from counterparty_rs import indexer

from counterpartycore.lib import config, util

logger = logging.getLogger(config.LOGGER_NAME)

_fetcher = None
_prefetch_queue = asyncio.Queue(maxsize=50)  # Adjust queue size as needed
_executor = ThreadPoolExecutor(max_workers=10)  # Adjust number of workers as needed
_prefetch_task = None

def prefetch_blocks():
    while True:
        try:
            block = _fetcher.get_block()
            _prefetch_queue.put_nowait(block)
            logger.debug(f"Block prefetched. Queue size: {_prefetch_queue.qsize()}/{_prefetch_queue.maxsize}")
        except asyncio.QueueFull:
            logger.debug("Prefetch queue is full. Waiting before next fetch.")
            time.sleep(1)  # Wait a bit before trying again
        except Exception as e:
            logger.error(f"Error prefetching block: {e}")
            time.sleep(1)  # Wait before retrying

def start_prefetching():
    global _prefetch_task
    if _prefetch_task is None or _prefetch_task.done():
        _prefetch_task = _executor.submit(prefetch_blocks)

def get_block_simple():
    try:
        block = _prefetch_queue.get_nowait()
        logger.debug(f"Block retrieved from queue. New queue size: {_prefetch_queue.qsize()}/{_prefetch_queue.maxsize}")
        return block
    except asyncio.QueueEmpty:
        logger.warning("Prefetch queue is empty. Fetching block directly.")
        return _fetcher.get_block()

def initialize(start_height):
    global _fetcher
    if _fetcher is not None:
        logger.warning("Fetcher has already been initialized.")
        return

    try:
        _fetcher = indexer.Indexer(
            {
                "rpc_address": f"http://{config.BACKEND_CONNECT}:{config.BACKEND_PORT}",
                "rpc_user": config.BACKEND_USER,
                "rpc_password": config.BACKEND_PASSWORD,
                "db_dir": config.FETCHER_DB,
                "start_height": start_height,
                "log_file": config.FETCHER_LOG,
                "log_level": config.LOG_LEVEL_STRING,
            }
        )
        # check fetcher version
        fetcher_version = _fetcher.get_version()
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
            _fetcher.start()
            start_prefetching()
            logger.info(f"Prefetch queue initialized with max size: {_prefetch_queue.maxsize}")
    except Exception as e:
        logger.error(f"Failed to initialize fetcher: {e}. Retrying in 5 seconds...")
        time.sleep(5)
        initialize(start_height)

def stop():
    logger.debug("Stopping fetcher...")
    global _fetcher, _prefetch_task
    if _fetcher is None:
        return
    try:
        _fetcher.stop()
    except Exception as e:
        if str(e) == "Stopped error":
            pass
        else:
            raise e
    if _prefetch_task:
        _prefetch_task.cancel()
    _fetcher = None
    _prefetch_task = None

def get_block():
    logger.trace("Fetching block with Rust backend.")
    block = get_block_simple()

    if util.enabled("correct_segwit_txids", block_index=block["height"]):
        for tx in block["transactions"]:
            tx["tx_hash"] = tx["tx_id"]

    return block

