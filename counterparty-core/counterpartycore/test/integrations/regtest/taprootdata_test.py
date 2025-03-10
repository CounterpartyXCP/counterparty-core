import json
import time

import requests
from bitcoinutils.setup import setup
from regtestnode import RegtestNodeThread


def rpc_call(method, params):
    headers = {"content-type": "application/json"}
    payload = {
        "method": method,
        "params": params,
        "jsonrpc": "2.0",
        "id": 0,
    }
    response = requests.post(
        "http://localhost:18443/",
        data=json.dumps(payload),
        headers=headers,
        auth=("rpc", "rpc"),
        timeout=20,
    )
    result = response.json()
    return result


def test_p2ptr_inscription():
    setup("regtest")

    try:
        regtest_node_thread = RegtestNodeThread(burn_in_one_block=True)
        regtest_node_thread.start()
        while not regtest_node_thread.ready():
            time.sleep(1)
        node = regtest_node_thread.node

        result = node.send_transaction(
            node.addresses[0],
            "send",
            {
                "destination": node.addresses[1],
                "quantity": 1,
                "asset": "XCP",
                "encoding": "taproot",
            },
        )

        print(result)

    finally:
        regtest_node_thread.stop()
