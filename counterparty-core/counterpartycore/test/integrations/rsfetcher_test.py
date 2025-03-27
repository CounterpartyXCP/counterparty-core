import os
import shutil
import tempfile
import time

from counterpartycore.lib import config
from counterpartycore.lib.backend import rsfetcher

TEST_DB_PATH = os.path.join(tempfile.gettempdir(), "rsfetcher_test_db")

if os.path.exists(TEST_DB_PATH):
    shutil.rmtree(TEST_DB_PATH)


TEST_CONFIG = {
    "rpc_address": "https://api.counterparty.io:8332",
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
        # Initialize fetcher and start at specific height
        fetcher = rsfetcher.RSFetcher(indexer_config=TEST_CONFIG)
        fetcher.start(start_height=748821)

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
        assert block["height"] == 748821
        assert len(block["transactions"]) == 2459
        assert (
            block["block_hash"]
            == "00000000000000000001ed6f3c0393ec1973e15b5515e3689ee536d2fc9da3b4"
        )

        # Verify specific transaction
        found_tx = None
        for tx in block["transactions"]:
            if tx["tx_id"] == "4283e880864fefc8e5acbd6bcd281b0d0ff0f4ca109dc2cbb383fbba7bb2fbc1":
                found_tx = tx
                break

        assert found_tx is not None

        assert found_tx["parsed_vouts"] == ([], 0, 0, b"P2SH", [(None, None)], False)
        assert found_tx["vin"] == [
            {
                "hash": "13685986077c9c458bab13553ea3fc6533d013cdb225947b109aff92e73a7d42",
                "n": 0,
                "sequence": 4294967295,
                "script_sig": b'G0D\x02 \x0c\x9d\x96\x15Z\xbcK\x8f\xb8\x00=\xd1\x9b\x97\x0c\xec\x9cq/\xdc\xd1\xaa5\xa6\x9d[\x8dHM\x1a}\x9f\x02 lSIG\xcb\xe3\xec\x05<w\x12S\xb9\x80\x97YM\xc7n\xca>R\xfeT".4\x12\xa8"\xc0\xa3\x01L\x90LeCNTRPRTY\x03\x00\x01\x00UIo=\xc6\x9f\xde\xb3\x1a\x1f\xa7\x87L<}\xca*\x89\x8a.@\x00\x00\x00E\xdc\x10\xf3\x80\x00\x00\x00\x00\x00\x00\x00`6\xa3V\x97\x0f\x9c\x82\x01`\x00\x00\x00\x00\x00\x00\x000\x15\x88\x8d\t)X`\x91\xd0\x00\x00\x00\x00\x00\x00\x00\x18\x0b\x94\x11\xb5\xe0\xc1\'{\x80\x00\x00\x00\x00\x00\x00\x00\x0c\x00u!\x03\xa2|\x9b\x9d{\xfb\xa6\xde\x12\xeb\xb3\xcf\xb5\x01}GE\xbb(\xe7:h\xfc\xe9O\x15\x8bH\xa3w\x02\xf2\xad\x00ut\x00\x87',
                "info": {
                    "script_pub_key": b"\xa9\x14jk\xf3\xe1Cy\xba\x94\xa4\xd1\xa9\xa5\x15TF\x95\xad\x18\x91\x06\x87",
                    "value": 1000,
                    "is_segwit": True,
                },
            }
        ]

    except Exception as e:  # pylint: disable=broad-except
        print(f"Error: {e}")
        raise
    finally:
        if fetcher:
            fetcher.stop()

    # Reset config
    config.NETWORK_NAME = "regtest"
    config.REGTEST = True
