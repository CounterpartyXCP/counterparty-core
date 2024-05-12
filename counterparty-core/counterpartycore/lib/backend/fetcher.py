import json

from counterparty_rs import indexer

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
    block_bytes = instance().get_block()
    return json.loads(block_bytes)
