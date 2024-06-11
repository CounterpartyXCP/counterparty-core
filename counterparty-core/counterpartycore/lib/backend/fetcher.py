import logging
import sys
import time

from counterparty_rs import indexer

from counterpartycore.lib import config, util

logger = logging.getLogger(config.LOGGER_NAME)

_fetcher = None


def initialize(start_height):
    global _fetcher  # noqa: PLW0603
    if _fetcher is not None:
        raise Exception("Fetcher has already been initialized.")
    exiting = False

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
            exiting = True
            raise Exception("Fetcher version mismatch.")
        else:
            # start fetcher
            _fetcher.start()
    except BaseException as e:  # TODO: BaseException is too broad
        if exiting:
            sys.exit()
        logger.error("Failed to initialize fetcher: %s. Retrying in 5 seconds...", e)
        time.sleep(5)
        initialize(start_height)


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
    try:
        _fetcher.stop()
    except Exception as e:
        if str(e) == "Stopped error":
            pass
        else:
            raise e
    _fetcher = None


def get_block_simple():
    return instance().get_block()


def get_block():
    logger.trace("Fetching block with Rust backend.")
    block = get_block_simple()

    if util.enabled("correct_segwit_txids", block_index=block["height"]):
        for tx in block["transactions"]:
            tx["tx_hash"] = tx["tx_id"]

    return block
