import json
import os
import time

import requests
from bitcoinutils.keys import PrivateKey
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

        random = os.urandom(32)
        source_private_key = PrivateKey(b=random)
        source_pubkey = source_private_key.get_public_key()
        source_address = source_pubkey.get_taproot_address()

        _txid = node.bitcoin_wallet("sendtoaddress", source_address.to_string(), 1).strip()
        node.mine_blocks(1)

        node.send_transaction(
            node.addresses[0],
            "send",
            {
                "destination": source_address.to_string(),
                "quantity": 100,
                "asset": "XCP",
            },
        )
        node.start_electrs()
        node.wait_for_electrs()

        result = node.send_transaction(
            source_address.to_string(),
            "send",
            {
                "destination": node.addresses[1],
                "quantity": 10,
                "asset": "XCP",
                "encoding": "taproot",
            },
        )
        result = list(result).pop()
        print(result)
    finally:
        print(regtest_node_thread.node.server_out.getvalue())
        regtest_node_thread.stop()
