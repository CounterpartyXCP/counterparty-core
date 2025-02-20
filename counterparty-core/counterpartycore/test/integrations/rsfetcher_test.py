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
    "consume_blocks": False,
    "only_write_in_reorg_window": True,
}


def test_fetcher_singleton():
    config.NETWORK_NAME = "mainnet"
    config.REGTEST = False
    config.TESTNET3 = False
    config.TESTNET4 = False
    try:
        # start_http_proxy("https://api.counterparty.io:8332")
        fetcher = rsfetcher.RSFetcher(indexer_config=TEST_CONFIG)
        fetcher.start(start_height=884596)
        block = fetcher.get_block()
        assert block["height"] == 884596
        found_tx = None
        for tx in block["transactions"]:
            if tx["tx_id"] == "34e4856f35ac24dadea24e85478153921b1b341cf5207b0f1318947133ad6c57":
                found_tx = tx
        assert found_tx is not None

        assert found_tx["parsed_vouts"] == (
            ["1LnYFKsS575LqYKTqywaSgvVBe3NUxm673"],
            546,
            -5761,
            b"\x16\x00\x00N\xc5O0;\xc2\x00\x00\x00\x00\x00\x00\x00\x00\x00\x01\x00",
            [
                ("1LnYFKsS575LqYKTqywaSgvVBe3NUxm673", 546),
                (None, None),
                ("bc1qvhxvtd5tznhh76ptwjv5x70qkyvm6swqch7yse", 5215),
            ],
        )

        print(found_tx["vin"][0])

    finally:
        fetcher.stop()
        pass
        # stop_http_proxy()
    config.NETWORK_NAME = "regtest"
    config.REGTEST = True
