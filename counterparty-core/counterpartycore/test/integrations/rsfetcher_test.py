import os
import shutil
import tempfile

from counterpartycore.lib import config
from counterpartycore.lib.backend import rsfetcher

TEST_DB_PATH = os.path.join(tempfile.gettempdir(), "rsfetcher_test_db")

if os.path.exists(TEST_DB_PATH):
    shutil.rmtree(TEST_DB_PATH)

TEST_CONFIG = {
    # "rpc_address": f"http://127.0.0.1:{PROXY_PORT}",
    "rpc_address": "http://127.0.0.1:8332",
    "rpc_user": "rpc",
    "rpc_password": "rpc",
    "db_dir": TEST_DB_PATH,
    "log_file": os.path.join(tempfile.gettempdir(), "rsfetcher_test.log"),
    "log_level": "debug",
    "json_format": False,
    "consume_blocks": True,
    "only_write_in_reorg_window": True,
}


def test_fetcher_singleton():
    config.NETWORK_NAME = "mainnet"
    config.REGTEST = False
    try:
        # start_http_proxy("https://api.counterparty.io:8332")
        fetcher = rsfetcher.RSFetcher(indexer_config=TEST_CONFIG)
        fetcher.start(start_height=300000)
        print("STARTED")
        block = fetcher.get_block()
        print("BLOCKKKK")
        print(block)

    finally:
        fetcher.stop()
        pass
        # stop_http_proxy()
    config.NETWORK_NAME = "regtest"
