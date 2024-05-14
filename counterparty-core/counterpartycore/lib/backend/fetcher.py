import binascii
import json
import logging

from counterparty_rs import indexer

from counterpartycore.lib import config

logger = logging.getLogger(config.LOGGER_NAME)

_fetcher = None


def initialize(config):
    global _fetcher  # noqa: PLW0603
    if _fetcher is not None:
        raise Exception("Fetcher has already been initialized.")

    _fetcher = indexer.Indexer(config)


def instance():
    if _fetcher is None:
        raise Exception("Fetcher has not been initialized.")

    return _fetcher


def start():
    instance().start()


def stop():
    instance().stop()
    global _fetcher  # noqa: PLW0603
    _fetcher = None


def get_block():
    logger.debug("Fetching block with Rust backend.")
    block_bytes = instance().get_block()
    block = json.loads(block_bytes)
    # TODO: move this
    for tx in block["transactions"]:
        for vout in tx["vout"]:
            vout["script_pub_key"] = binascii.unhexlify(vout["script_pub_key"])
    return block
