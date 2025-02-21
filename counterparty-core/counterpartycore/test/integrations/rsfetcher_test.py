import os
import shutil
import tempfile
import time

from counterpartycore.lib import config
from counterpartycore.lib.backend import rsfetcher
from counterpartycore.test.integrations.http2https import start_http_proxy, stop_http_proxy

TEST_DB_PATH = os.path.join(tempfile.gettempdir(), "rsfetcher_test_db")

if os.path.exists(TEST_DB_PATH):
    shutil.rmtree(TEST_DB_PATH)

PROXY_PORT = 48500
TEST_CONFIG = {
    "rpc_address": f"http://127.0.0.1:{PROXY_PORT}",
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

    proxy_server = None
    try:
        # Start proxy with proper error handling
        proxy_server = start_http_proxy(
            "https://api.counterparty.io:8332",
            port=PROXY_PORT,
            rpc_user=TEST_CONFIG["rpc_user"],
            rpc_password=TEST_CONFIG["rpc_password"],
        )

        # Initialize fetcher and start at specific height
        fetcher = rsfetcher.RSFetcher(indexer_config=TEST_CONFIG)
        fetcher.start(start_height=884596)

        # Wait for block with timeout
        timeout = 30  # 30 seconds timeout
        start_time = time.time()
        block = None

        while block is None and (time.time() - start_time) < timeout:
            block = fetcher.get_block()
            if block is None:
                time.sleep(1)

        if block is None:
            raise TimeoutError("Failed to fetch block within timeout period")

        # Verify block data
        assert block["height"] == 884596
        assert len(block["transactions"]) == 3690
        assert (
            block["block_hash"]
            == "0000000000000000000009f688fb460c5f878005ef943b9e75c7ff333313285d"
        )

        # Verify specific transaction
        found_tx = None
        for tx in block["transactions"]:
            if tx["tx_id"] == "34e4856f35ac24dadea24e85478153921b1b341cf5207b0f1318947133ad6c57":
                found_tx = tx
                break

        assert found_tx is not None
        # ... rest of your assertions ...

    except Exception as e:
        print(f"Error: {e}")
        raise  # Re-raise the exception for the test framework

    finally:
        if fetcher:
            fetcher.stop()
        if proxy_server:
            stop_http_proxy(proxy_server)

    # Reset config
    config.NETWORK_NAME = "regtest"
    config.REGTEST = True
