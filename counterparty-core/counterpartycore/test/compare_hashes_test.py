import json

import pytest
import requests

from counterpartycore.test import (
    conftest,  # noqa: F401
)

# This two servers must be up and running
API_V9_URL = "http://rpc:rpc@api1.counterparty.io:4000"
API_V10_URL = "http://api:api@localhost:4000"


def test_compare_hashes(skip):
    if skip:
        pytest.skip("Skipping test book")
        return

    # get v9 last block
    headers = {"content-type": "application/json"}
    payload = {
        "method": "get_running_info",
        "jsonrpc": "2.0",
        "id": 0,
    }
    response = requests.post(API_V9_URL, data=json.dumps(payload), headers=headers, timeout=10)
    v9_block_index = response.json()["result"]["last_block"]["block_index"]
    # print(v9_block_index)

    # get v10 last block
    response = requests.get(f"{API_V10_URL}/", timeout=10)
    v10_block_index = response.json()["result"]["counterparty_height"]
    # print(v10_block_index)

    # take the lower block
    last_block_index = min(v9_block_index, v10_block_index)

    # get v9 block hashes
    payload = {
        "method": "get_block_info",
        "jsonrpc": "2.0",
        "id": 0,
        "params": {"block_index": last_block_index},
    }
    response = requests.post(API_V9_URL, data=json.dumps(payload), headers=headers, timeout=10)
    v9_ledger_hash = response.json()["result"]["ledger_hash"]
    v9_txlist_hash = response.json()["result"]["txlist_hash"]
    # print(v9_ledger_hash, v9_txlist_hash)

    # get v10 block hashes
    response = requests.get(f"{API_V10_URL}/blocks/{last_block_index}", timeout=10)
    v10_ledger_hash = response.json()["result"]["ledger_hash"]
    v10_txlist_hash = response.json()["result"]["txlist_hash"]
    # print(v10_ledger_hash, v10_txlist_hash)

    # compare hashes
    assert v9_ledger_hash == v10_ledger_hash
    assert v9_txlist_hash == v10_txlist_hash
