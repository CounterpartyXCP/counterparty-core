import json
import os
import time

import requests
from bitcoinutils.keys import PrivateKey
from bitcoinutils.script import Script
from bitcoinutils.setup import setup
from bitcoinutils.transactions import Transaction, TxWitnessInput
from bitcoinutils.utils import ControlBlock
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


def send_taproot_transaction(node, utxo, source_private_key, tx_name, params):
    source_pubkey = source_private_key.get_public_key()
    source_address = source_pubkey.get_taproot_address()

    # send XCP from the source address
    result = node.send_transaction(
        source_address.to_string(),
        tx_name,
        params
        | {
            "inputs_set": f"{utxo['txid']}:{utxo['n']}",
            "encoding": "taproot",
            "multisig_pubkey": source_pubkey.to_hex(),
        },
        return_result=True,
    )

    # sign commit tx
    commit_tx = Transaction.from_raw(result["rawtransaction"])
    commit_tx.has_segwit = True
    # sign the input
    sig = source_private_key.sign_taproot_input(
        commit_tx, 0, [source_address.to_script_pub_key()], [utxo["value"]]
    )
    # add the witness to the transaction
    commit_tx.witnesses.append(TxWitnessInput([sig]))
    node.broadcast_transaction(commit_tx.serialize())

    print("Commit TX Broadcasted:", commit_tx.get_txid(), commit_tx.serialize())

    inscription_script = Script.from_raw(result["envelope_script"])
    reveal_tx = Transaction.from_raw(result["reveal_rawtransaction"])
    reveal_tx.has_segwit = True

    commit_address = source_pubkey.get_taproot_address([[inscription_script]])
    commit_value = commit_tx.outputs[0].amount

    # sign the input containing the inscription script
    sig = source_private_key.sign_taproot_input(
        reveal_tx,
        0,
        [commit_address.to_script_pub_key()],
        [commit_value],
        script_path=True,
        tapleaf_script=inscription_script,
        tweak=True,
    )
    # generate the control block
    control_block = ControlBlock(
        source_pubkey,
        scripts=[inscription_script],
        index=0,
        is_odd=commit_address.is_odd(),
    )

    # add the witness to the transaction
    reveal_tx.witnesses.append(
        TxWitnessInput([sig, inscription_script.to_hex(), control_block.to_hex()])
    )

    node.broadcast_transaction(reveal_tx.serialize())

    return reveal_tx.get_txid()


def generate_taproot_funded_address(node):
    random = os.urandom(32)
    source_private_key = PrivateKey(b=random)
    source_pubkey = source_private_key.get_public_key()
    source_address = source_pubkey.get_taproot_address()
    print("Source address", source_address.to_string())
    print("Source script_pub_key", source_address.to_script_pub_key().to_hex())

    # send some BTC to the source address
    txid = node.bitcoin_wallet("sendtoaddress", source_address.to_string(), 1).strip()
    node.mine_blocks(1)
    raw_tx = rpc_call("getrawtransaction", [txid, 1])["result"]

    n = None
    for i, vout in enumerate(raw_tx["vout"]):
        if vout["scriptPubKey"]["address"] == source_address.to_string():
            n = i
            break
    if n is None:
        raise Exception("Could not find the vout for the source address")

    # send some XCP to the source address
    node.send_transaction(
        node.addresses[0],
        "send",
        {
            "destination": source_address.to_string(),
            "quantity": 1 * 10**8,
            "asset": "XCP",
        },
    )
    return source_private_key, {
        "txid": txid,
        "n": n,
        "value": int(1 * 10**8),
    }


def check_send(node, source_private_key, utxo):
    reveal_txid = send_taproot_transaction(
        node,
        utxo,
        source_private_key,
        "send",
        {
            "destination": node.addresses[1],
            "quantity": 10,
            "asset": "XCP",
        },
    )

    source_address = source_private_key.get_public_key().get_taproot_address().to_string()
    result = node.api_call(f"addresses/{source_address}/sends")
    assert len(result["result"]) == 2
    assert result["result"][0]["asset"] == "XCP"
    assert result["result"][0]["quantity"] == 10
    assert result["result"][0]["source"] == source_address
    assert result["result"][0]["destination"] == node.addresses[1]

    return reveal_txid


def test_p2ptr_inscription():
    setup("regtest")

    try:
        regtest_node_thread = RegtestNodeThread(burn_in_one_block=True)
        regtest_node_thread.start()
        while not regtest_node_thread.ready():
            time.sleep(1)
        node = regtest_node_thread.node

        source_private_key, utxo = generate_taproot_funded_address(node)
        reveal_txid = check_send(node, source_private_key, utxo)
        print("Taproot send OK:", reveal_txid)

    finally:
        print(regtest_node_thread.node.server_out.getvalue())
        regtest_node_thread.stop()
