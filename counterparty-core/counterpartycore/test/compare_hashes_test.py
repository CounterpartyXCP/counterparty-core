import json

import pytest
import requests

from counterpartycore.test import (
    conftest,  # noqa: F401
)

LOCAL_API_URL = "http://api:api@localhost:4000"

# [server_url, api_version]
CHECK_SERVERS = [
    ["http://rpc:rpc@api1.counterparty.io:4000", "v1"],  # v9.61.3
]


def get_last_block_api_v1(api_url):
    headers = {"content-type": "application/json"}
    payload = {
        "method": "get_running_info",
        "jsonrpc": "2.0",
        "id": 0,
    }
    response = requests.post(api_url, data=json.dumps(payload), headers=headers, timeout=10)
    return response.json()["result"]["last_block"]["block_index"]


def get_last_block_api_v2(api_url):
    response = requests.get(f"{api_url}/", timeout=10)
    return response.json()["result"]["counterparty_height"]


def get_block_hashes_api_v1(api_url, block_index):
    headers = {"content-type": "application/json"}
    payload = {
        "method": "get_block_info",
        "jsonrpc": "2.0",
        "id": 0,
        "params": {"block_index": block_index},
    }
    response = requests.post(api_url, data=json.dumps(payload), headers=headers, timeout=10)
    return response.json()["result"]["ledger_hash"], response.json()["result"]["txlist_hash"]


def get_block_hashes_api_v2(api_url, block_index):
    response = requests.get(f"{api_url}/blocks/{block_index}", timeout=10)
    return response.json()["result"]["ledger_hash"], response.json()["result"]["txlist_hash"]


def test_compare_hashes(skip):
    if skip:
        pytest.skip("Skipping test book")
        return

    # get last blocks
    local_block_index = get_last_block_api_v2(LOCAL_API_URL)
    check_servers_block_indexes = [local_block_index]
    for check_server in CHECK_SERVERS:
        check_server_url, check_server_version = check_server
        if check_server_version == "v1":
            check_servers_block_indexes.append(get_last_block_api_v1(check_server_url))
        else:
            check_servers_block_indexes.append(get_last_block_api_v2(check_server_url))

    # take the lower block
    last_block_index = min(*check_servers_block_indexes)
    print(f"Last block index: {last_block_index}")

    # get block hashes
    local_ledger_hash, local_txlist_hash = get_block_hashes_api_v2(LOCAL_API_URL, last_block_index)
    for check_server in CHECK_SERVERS:
        check_server_url, check_server_version = check_server
        if check_server_version == "v1":
            check_ledger_hash, check_txlist_hash = get_block_hashes_api_v1(
                check_server_url, last_block_index
            )
        else:
            check_ledger_hash, check_txlist_hash = get_block_hashes_api_v2(
                check_server_url, last_block_index
            )

        # compare hashes
        assert check_ledger_hash == local_ledger_hash
        assert check_txlist_hash == local_txlist_hash
