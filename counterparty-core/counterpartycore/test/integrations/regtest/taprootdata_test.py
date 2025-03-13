import binascii
import json
import os
import time

import requests
from bitcoinutils.keys import PrivateKey
from bitcoinutils.script import Script
from bitcoinutils.setup import setup
from bitcoinutils.transactions import Transaction
from regtestnode import RegtestNodeThread
from taproot import compose_signed_transactions


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
    print(result)
    return result


def test_p2ptr_inscription():
    setup("regtest")

    try:
        regtest_node_thread = RegtestNodeThread(burn_in_one_block=True)
        regtest_node_thread.start()
        while not regtest_node_thread.ready():
            time.sleep(1)
        node = regtest_node_thread.node

        # COMMIT

        random = os.urandom(32)
        source_private_key = PrivateKey(b=random)
        source_pubkey = source_private_key.get_public_key()
        source_address = source_pubkey.get_taproot_address()
        print("From Taproot address:", source_address.to_string())

        # Inputs

        # send some coins to the source address
        commit_utxo_amount = 300330
        txid = node.bitcoin_wallet(
            "sendtoaddress", source_address.to_string(), commit_utxo_amount / 1e8
        ).strip()
        node.mine_blocks(1)

        # search for the vout
        vout = None
        decoded_tx = json.loads(node.bitcoin_cli("getrawtransaction", txid, 1).strip())
        for n, out in enumerate(decoded_tx["vout"]):
            if out["scriptPubKey"]["address"] == source_address.to_string():
                vout = n
                break
        assert vout is not None

        original_content = b"\x01" * 1024 * 387  # near to 100K vbytes transaction

        commit_tx, reveal_tx = compose_signed_transactions(
            source_private_key, original_content, txid, vout, commit_utxo_amount
        )

        # send the transaction and mine a block
        _commit_txid = rpc_call("sendrawtransaction", [commit_tx.serialize()])["result"]
        reveal_txid = rpc_call("sendrawtransaction", [reveal_tx.serialize()])["result"]
        node.mine_blocks(1)

        # VERIFY

        # get the transaction from the blockchain
        verify_raw = node.bitcoin_cli("getrawtransaction", reveal_txid, 0).strip()
        verify_tx = Transaction.from_raw(verify_raw)

        # extract the inscription script
        inscription_script = Script.from_raw(verify_tx.witnesses[0].stack[1])
        # join all the chunks
        inscription_data = "".join(inscription_script.script[2:-1])
        inscription_content = binascii.unhexlify(inscription_data)

        # get our data
        assert inscription_content == original_content

    finally:
        regtest_node_thread.stop()
