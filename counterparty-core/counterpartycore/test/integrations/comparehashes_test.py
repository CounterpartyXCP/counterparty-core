import json

import requests

LOCAL_API_URL = "http://localhost:4000"

# [server_url, api_version, server_version]
CHECK_SERVERS = [
    # ["http://rpc:rpc@api1.counterparty.io:4000", "v1", "v9.61.1"],
    ["https://api.counterparty.io:4000", "v2", "v10.9.1"],
    ["https://api.unspendablelabs.com:4000", "v2", "v10.9.1"],
    # ["https://api.counterparty.info", "v2", "v10.6.0"],
    # ["http://rpc:1234@public.coindaddy.io:4000", "v1", "v9.61.3"],
    # ["https://memepool.wtf/api/", "wtf", "v10.6.0"],
]


def get_last_block_api_v1(api_url):
    headers = {"content-type": "application/json"}
    payload = {
        "method": "get_running_info",
        "jsonrpc": "2.0",
        "id": 0,
    }
    response = requests.post(api_url, data=json.dumps(payload), headers=headers, timeout=10).json()
    last_block_index = response["result"]["last_block"]["block_index"]
    version = f"v{response['result']['version_major']}.{response['result']['version_minor']}.{response['result']['version_revision']}"
    return last_block_index, version


def get_last_block_api_v2(api_url):
    response = requests.get(f"{api_url}/v2/", timeout=10).json()
    last_block_index = response["result"]["counterparty_height"]
    version = f"v{response['result']['version']}"
    return last_block_index, version


def get_last_block_api_wtf(api_url):
    response = requests.get(f"{api_url}runningInfo", timeout=10).json()
    last_block_index = response["result"]["last_block"]["block_index"]
    version = f"v{response['result']['version_major']}.{response['result']['version_minor']}.{response['result']['version_revision']}"
    return last_block_index, version


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
    response = requests.get(f"{api_url}/v2/blocks/{block_index}", timeout=10)
    return response.json()["result"]["ledger_hash"], response.json()["result"]["txlist_hash"]


def get_block_hashes_api_wtf(api_url, block_index):
    response = requests.get(f"{api_url}block/{block_index}", timeout=10).json()
    return response["block"][0]["ledger_hash"], response["block"][0]["txlist_hash"]


def test_compare_hashes():
    # get last blocks
    check_servers_block_indexes = []
    for check_server in CHECK_SERVERS:
        check_server_url, check_server_api_version, check_server_version = check_server
        if check_server_api_version == "v1":
            server_last_block_index, server_version = get_last_block_api_v1(check_server_url)
            check_servers_block_indexes.append(server_last_block_index)
        elif check_server_api_version == "wtf":
            server_last_block_index, server_version = get_last_block_api_wtf(check_server_url)
            check_servers_block_indexes.append(server_last_block_index)
        else:
            server_last_block_index, server_version = get_last_block_api_v2(check_server_url)
            check_servers_block_indexes.append(server_last_block_index)
        assert server_version == check_server_version

    # take the lower block
    last_block_index = min(*check_servers_block_indexes)
    print(f"Last block index: {last_block_index}")

    # get block hashes
    ledger_hashes = []
    txlist_hashes = []
    for check_server in CHECK_SERVERS:
        print(f"Checking server: {check_server[0]}")
        check_server_url, check_server_api_version, check_server_version = check_server
        if check_server_api_version == "v1":
            check_ledger_hash, check_txlist_hash = get_block_hashes_api_v1(
                check_server_url, last_block_index
            )
        elif check_server_api_version == "wtf":
            check_ledger_hash, check_txlist_hash = get_block_hashes_api_wtf(
                check_server_url, last_block_index
            )
        else:
            check_ledger_hash, check_txlist_hash = get_block_hashes_api_v2(
                check_server_url, last_block_index
            )
        ledger_hashes.append(check_ledger_hash)
        txlist_hashes.append(check_txlist_hash)
    # compare hashes
    last_ledger_hash = ledger_hashes.pop()
    last_txlist_hash = txlist_hashes.pop()
    for check_ledger_hash in ledger_hashes:
        assert check_ledger_hash == last_ledger_hash
    for check_txlist_hash in txlist_hashes:
        assert check_txlist_hash == last_txlist_hash
    print("All hashes are equal")
