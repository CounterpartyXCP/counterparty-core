import json
import time

import pytest
import requests

from counterpartycore.lib import database
from counterpartycore.test import (
    conftest,  # noqa: F401
)

LOCAL_API_URL = "http://localhost:4000"

# [server_url, api_version, server_version]
CHECK_SERVERS = [
    ["http://rpc:rpc@api1.counterparty.io:4000", "v1", "v9.61.1"],
    ["https://api.counterparty.io:4000", "v2", "v10.4.2"],
    ["https://dev.counterparty.io:4000", "v2", "v10.4.2"],
    ["https://api.counterparty.info", "v2", "v10.4.2"],
    ["http://rpc:1234@public.coindaddy.io:4000", "v1", "v9.61.3"],
    ["https://api.xcp.dev/v9_61/", "xcpdev", "v9.61.3"],
    ["https://api.xcp.dev/v10_1/", "xcpdev", "v10.1.2.CNTRPRTY"],
    ["https://memepool.wtf/api/", "wtf", "v10.2.0"],
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
    version = f'v{response["result"]["version_major"]}.{response["result"]["version_minor"]}.{response["result"]["version_revision"]}'
    return last_block_index, version


def get_last_block_api_v2(api_url):
    response = requests.get(f"{api_url}/v2/", timeout=10).json()
    last_block_index = response["result"]["counterparty_height"]
    version = f'v{response["result"]["version"]}'
    return last_block_index, version


def xcpdev_query(url):
    response = requests.get(url, timeout=10).json()
    if (
        response["data"] is None
        and response["message"] == "Accepted (repeat request in 1 to 5 seconds)"
    ):
        time.sleep(1)
        return xcpdev_query(url)
    return response


def get_last_block_api_xcpdev(api_url):
    response = xcpdev_query(f"{api_url}blocks")
    last_block_index = response["data"]["blocks"][0]["block_index"]
    response = xcpdev_query(f"{api_url}")
    version = f'v{response["data"]["node"]["COUNTERPARTY_VERSION"]}'
    return last_block_index, version


def get_last_block_api_wtf(api_url):
    response = requests.get(f"{api_url}runningInfo", timeout=10).json()
    last_block_index = response["result"]["last_block"]["block_index"]
    version = f'v{response["result"]["version_major"]}.{response["result"]["version_minor"]}.{response["result"]["version_revision"]}'
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


def get_block_hashes_api_xcpdev(api_url, block_index):
    response = xcpdev_query(f"{api_url}blocks/{block_index}")
    return response["data"]["blocks"][0]["ledger_hash"], response["data"]["blocks"][0][
        "txlist_hash"
    ]


def get_block_hashes_api_wtf(api_url, block_index):
    response = requests.get(f"{api_url}block/{block_index}", timeout=10).json()
    return response["block"][0]["ledger_hash"], response["block"][0]["txlist_hash"]


def test_compare_hashes(skip):
    if skip:
        pytest.skip("Skipping compare hashes test.")
        return

    # get last blocks
    local_block_index, _ = get_last_block_api_v2(LOCAL_API_URL)
    print(f"Local block index: {local_block_index}")
    check_servers_block_indexes = [local_block_index]
    for check_server in CHECK_SERVERS:
        check_server_url, check_server_api_version, check_server_version = check_server
        if check_server_api_version == "v1":
            server_last_block_index, server_version = get_last_block_api_v1(check_server_url)
            check_servers_block_indexes.append(server_last_block_index)
        elif check_server_api_version == "xcpdev":
            server_last_block_index, server_version = get_last_block_api_xcpdev(check_server_url)
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
    local_ledger_hash, local_txlist_hash = get_block_hashes_api_v2(LOCAL_API_URL, last_block_index)
    for check_server in CHECK_SERVERS:
        print(f"Checking server: {check_server[0]}")
        check_server_url, check_server_api_version, check_server_version = check_server
        if check_server_api_version == "v1":
            check_ledger_hash, check_txlist_hash = get_block_hashes_api_v1(
                check_server_url, last_block_index
            )
        elif check_server_api_version == "xcpdev":
            check_ledger_hash, check_txlist_hash = get_block_hashes_api_xcpdev(
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
        # compare hashes
        assert check_ledger_hash == local_ledger_hash
        assert check_txlist_hash == local_txlist_hash


# TODO: find a way to find the database path
# MAINNET_DB_DIR = "/home/ouziel/.local/share/counterparty-docker-data/counterparty/"
MAINNET_DB_DIR = "/home/ouziel/snap/docker/2932/.local/share/counterparty-docker-data/counterparty/"
# MAINNET_DB_DIR = "/home/ouziel/.local/share/counterparty/"


def test_mainnet_api_db(skip):
    if skip:
        pytest.skip("Skipping mainnet API database test.")
        return

    ledger_db = database.get_db_connection(
        f"{MAINNET_DB_DIR}counterparty.db", read_only=True, check_wal=False
    )
    api_db = database.get_db_connection(
        f"{MAINNET_DB_DIR}counterparty.api.db", read_only=True, check_wal=False
    )

    api_sql = "SELECT * FROM balances ORDER BY random() LIMIT 10000"
    api_balances = api_db.execute(api_sql)
    i = 0
    for api_balance in api_balances:
        ledger_sql = (
            "SELECT * FROM balances WHERE address = ? AND asset = ? ORDER BY rowid DESC LIMIT 1"
        )
        ledger_balance = ledger_db.execute(
            ledger_sql, (api_balance["address"], api_balance["asset"])
        ).fetchone()
        if ledger_balance is None and api_balance["quantity"] == 0:
            continue
        try:
            assert ledger_balance["quantity"] == api_balance["quantity"]
        except AssertionError:
            print(api_balance, ledger_balance)
        i += 1
    print(f"Checked {i} balances")

    api_sql = "SELECT * FROM orders ORDER BY random() LIMIT 10000"
    api_orders = api_db.execute(api_sql)
    i = 0
    for api_order in api_orders:
        ledger_sql = "SELECT * FROM orders WHERE tx_hash = ? ORDER BY rowid DESC LIMIT 1"
        ledger_order = ledger_db.execute(ledger_sql, (api_order["tx_hash"],)).fetchone()
        try:
            assert ledger_order["give_asset"] == api_order["give_asset"]
            assert ledger_order["get_asset"] == api_order["get_asset"]
            assert ledger_order["give_quantity"] == api_order["give_quantity"]
            assert ledger_order["get_quantity"] == api_order["get_quantity"]
        except AssertionError:
            print(api_order, ledger_order)
        i += 1
    print(f"Checked {i} balances")


def test_mainnet_healthz(skip):
    if skip:
        pytest.skip("Skipping healthz test.")
        return

    response = requests.get(f"{LOCAL_API_URL}/healthz", timeout=10)
    print(response.json())
    assert response.status_code == 200
    assert response.json()["result"]["status"] == "Healthy"
