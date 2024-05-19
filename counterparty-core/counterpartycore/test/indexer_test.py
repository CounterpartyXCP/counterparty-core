import shutil
from time import sleep

import pytest
from counterparty_rs import indexer

from counterpartycore.lib.backend import fetcher

TEST_DB_PATH = "/tmp/counterparty_test_db"  # noqa: S108

TEST_CONFIG = {
    "rpc_address": "http://127.0.0.1:8332",
    "rpc_user": "rpc",
    "rpc_password": "rpc",
    "db_dir": TEST_DB_PATH,
}


@pytest.mark.skip()
def test_fetcher_singleton():
    fetcher.initialize(TEST_CONFIG)
    with pytest.raises(Exception) as e:
        fetcher.initialize(TEST_CONFIG)

    assert "already been initialized" in str(e)

    assert fetcher.instance() is fetcher.instance()
    fetcher.stop()
    shutil.rmtree(TEST_DB_PATH)


@pytest.mark.skip()
def test_fetcher_interrupt():
    fetcher.initialize_with_config(TEST_CONFIG)
    interrupted = False
    try:
        for _ in range(500):
            block = fetcher.get_block_simple()
            assert isinstance(block, dict)
            assert "height" in block
    except KeyboardInterrupt:
        interrupted = True
        pass
    finally:
        fetcher.stop()
        shutil.rmtree(TEST_DB_PATH)

    assert interrupted


@pytest.mark.skip()
def test_indexer():
    i = indexer.Indexer(TEST_CONFIG)
    i.start()
    sleep(float("inf"))
