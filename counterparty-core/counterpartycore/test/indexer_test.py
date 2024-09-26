import shutil
from time import sleep

import pytest
from counterparty_rs import indexer

from counterpartycore.lib.backend import rsfetcher

TEST_DB_PATH = "/tmp/counterparty_test_db"  # noqa: S108

TEST_CONFIG = {
    "rpc_address": "http://127.0.0.1:8332",
    "rpc_user": "rpc",
    "rpc_password": "rpc",
    "db_dir": TEST_DB_PATH,
    "log_file": "/Users/wilfred/Desktop/indexer_test.log",
    "log_level": "debug",
    "json_format": False,
    # "consume_blocks": True,
}


@pytest.mark.skip()
def test_fetcher_singleton():
    fetcher = rsfetcher.RSFetcher(config=TEST_CONFIG)
    fetcher.start_fetcher()
    fetcher.is_me = "Coucou"

    fetcher2 = rsfetcher.RSFetcher(config=TEST_CONFIG)
    fetcher2.start_fetcher()
    assert fetcher2.is_me == "Coucou"

    assert fetcher.instance() is fetcher2.instance()
    fetcher.stop()
    shutil.rmtree(TEST_DB_PATH)


@pytest.mark.skip()
def test_fetcher_interrupt():
    fetcher = rsfetcher.RSFetcher(config=TEST_CONFIG)
    fetcher.start_fetcher()
    interrupted = False
    try:
        for _ in range(500):
            block = fetcher.get_block()
            assert isinstance(block, dict)
            assert "height" in block
            for t in block["transactions"]:
                for v in t["vin"]:
                    assert isinstance(v["script_sig"], bytes)
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
    sleep(1000000000)
