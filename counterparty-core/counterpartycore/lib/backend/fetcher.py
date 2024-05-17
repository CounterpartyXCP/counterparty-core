import json
import logging
import os
import tempfile

from counterparty_rs import indexer

from counterpartycore.lib import config, util

logger = logging.getLogger(config.LOGGER_NAME)

_fetcher = None


def initialize(start_height):
    global _fetcher  # noqa: PLW0603
    if _fetcher is not None:
        raise Exception("Fetcher has already been initialized.")

    _fetcher = indexer.Indexer(
        {
            "rpc_address": f"http://{config.BACKEND_CONNECT}:{config.BACKEND_PORT}",
            "rpc_user": config.BACKEND_USER,
            "rpc_password": config.BACKEND_PASSWORD,
            "db_dir": os.path.join(tempfile.gettempdir(), "fetcherdb"),
            "start_height": start_height,
        }
    )
    _fetcher.start()


def initialize_with_config(config):
    global _fetcher  # noqa: PLW0603
    if _fetcher is not None:
        raise Exception("Fetcher has already been initialized.")

    _fetcher = indexer.Indexer(config)
    _fetcher.start()


def instance():
    if _fetcher is None:
        raise Exception("Fetcher has not been initialized.")

    return _fetcher


def stop():
    logger.info("Stopping fetcher...")
    global _fetcher  # noqa: PLW0603
    if _fetcher is None:
        return
    _fetcher.stop()
    _fetcher = None


def get_block_simple():
    block_bytes = instance().get_block()
    return json.loads(block_bytes)


def get_block():
    logger.debug("Fetching block with Rust backend.")
    block = get_block_simple()

    if util.enabled("correct_segwit_txids", block_index=block["height"]):
        for tx in block["transactions"]:
            tx["tx_hash"] = tx["tx_id"]

    return block
