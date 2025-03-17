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

SENDS_COUNT = {}


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


def send_taproot_transaction(node, utxo, source_private_key, tx_name, params, inputs_set=None):
    print(utxo)
    source_pubkey = source_private_key.get_public_key()
    source_address = source_pubkey.get_taproot_address()

    # send XCP from the source address
    source = source_address.to_string()
    if tx_name == "detach":
        source = f"{utxo['txid']}:{utxo['n']}"
    result = node.send_transaction(
        source,
        tx_name,
        params
        | {
            "inputs_set": inputs_set or f"{utxo['txid']}:{utxo['n']}",
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
    print("unsigned commit tx", commit_tx.serialize())
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

    return {
        "txid": commit_tx.get_txid(),
        "n": 1,
        "value": commit_tx.outputs[1].amount,
    }


def generate_taproot_funded_address(node):
    global SENDS_COUNT  # pylint: disable=global-statement # noqa PLW0603

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
    SENDS_COUNT[source_address.to_string()] = SENDS_COUNT.get(source_address.to_string(), 0) + 1
    print("SEND COUNT", SENDS_COUNT)
    return source_private_key, {
        "txid": txid,
        "n": n,
        "value": int(1 * 10**8),
    }


def check_send(node, source_private_key, utxo, quantity):
    global SENDS_COUNT  # pylint: disable=global-statement # noqa PLW0603

    new_utxo = send_taproot_transaction(
        node,
        utxo,
        source_private_key,
        "send",
        {
            "destination": node.addresses[1],
            "quantity": quantity,
            "asset": "XCP",
        },
    )

    source_address = source_private_key.get_public_key().get_taproot_address().to_string()
    SENDS_COUNT[source_address] = SENDS_COUNT.get(source_address, 0) + 1
    print("SEND COUNT", SENDS_COUNT)

    result = node.api_call(f"addresses/{source_address}/sends")
    assert len(result["result"]) == SENDS_COUNT[source_address]
    assert result["result"][0]["asset"] == "XCP"
    assert result["result"][0]["quantity"] == quantity
    assert result["result"][0]["source"] == source_address
    assert result["result"][0]["destination"] == node.addresses[1]

    return new_utxo


def check_mpma_send(node, source_private_key, utxo, quantity):
    global SENDS_COUNT  # pylint: disable=global-statement # noqa PLW0603

    destination_count = 7
    assets = ["XCP"] * destination_count
    quantities = [str(quantity)] * destination_count
    destination_addresses = [node.addresses[i] for i in range(1, 1 + destination_count)]

    new_utxo = send_taproot_transaction(
        node,
        utxo,
        source_private_key,
        "mpma",
        {
            "assets": ",".join(assets),
            "quantities": ",".join(quantities),
            "destinations": ",".join(destination_addresses),
            "memo": "lore ipsum, lore ipsum, lore ipsum, lore ipsum, lorem ipsum",
        },
    )

    source_address = source_private_key.get_public_key().get_taproot_address().to_string()
    SENDS_COUNT[source_address] = SENDS_COUNT.get(source_address, 0) + destination_count
    print("SEND COUNT", SENDS_COUNT)

    result = node.api_call(f"addresses/{source_address}/sends")

    assert len(result["result"]) == SENDS_COUNT[source_address]
    for i in reversed(range(destination_count)):
        assert result["result"][i]["asset"] == "XCP"
        assert result["result"][i]["quantity"] == quantity
        assert result["result"][i]["source"] == source_address
        assert result["result"][i]["destination"] == node.addresses[destination_count - i]

    return new_utxo


def check_broadcast(node, source_private_key, utxo, text):
    new_utxo = send_taproot_transaction(
        node,
        utxo,
        source_private_key,
        "broadcast",
        {
            "timestamp": 4003903983,
            "value": 999,
            "fee_fraction": 0.0,
            "text": text,
        },
    )

    source_address = source_private_key.get_public_key().get_taproot_address().to_string()
    result = node.api_call(f"addresses/{source_address}/broadcasts")
    print(result)
    assert len(result["result"]) == 1
    assert result["result"][0]["text"] == text

    return new_utxo


def check_fairminter(node, source_private_key, utxo):
    new_utxo = send_taproot_transaction(
        node,
        utxo,
        source_private_key,
        "fairminter",
        {
            "asset": "FAIRMINT",
            "price": 1,
            "hard_cap": 100 * 10**8,
            "description": "lore ipsum, lore ipsum, lore ipsum, lore ipsum, lorem ipsum",
            "premint_quantity": 100,
        },
    )

    source_address = source_private_key.get_public_key().get_taproot_address().to_string()
    result = node.api_call(f"addresses/{source_address}/fairminters")
    print(result)
    assert len(result["result"]) == 1
    assert result["result"][0]["asset"] == "FAIRMINT"

    return new_utxo


def check_fairmint(node, source_private_key, utxo):
    new_utxo = send_taproot_transaction(
        node,
        utxo,
        source_private_key,
        "fairmint",
        {
            "asset": "FAIRMINT",
            "quantity": 1,
        },
    )

    source_address = source_private_key.get_public_key().get_taproot_address().to_string()
    result = node.api_call(f"addresses/{source_address}/fairmints")
    print(result)
    assert len(result["result"]) == 1
    assert result["result"][0]["asset"] == "FAIRMINT"

    return new_utxo


def check_dispensers(node, source_private_key, utxo):
    new_utxo = send_taproot_transaction(
        node,
        utxo,
        source_private_key,
        "dispenser",
        {
            "asset": "FAIRMINT",
            "give_quantity": 1,
            "escrow_quantity": 1,
            "mainchainrate": 1,  # 1 BTC for 1 XCP
            "status": 0,
            "validate": False,
        },
    )

    source_address = source_private_key.get_public_key().get_taproot_address().to_string()
    result = node.api_call(f"addresses/{source_address}/dispensers")
    print(result)
    assert len(result["result"]) == 1
    assert result["result"][0]["asset"] == "FAIRMINT"

    return new_utxo


def check_dispense(node, source_private_key, utxo, dispenser):
    source_address = source_private_key.get_public_key().get_taproot_address().to_string()

    new_utxo = send_taproot_transaction(
        node,
        utxo,
        source_private_key,
        "dispense",
        {
            "dispenser": dispenser,
            "quantity": 1,
        },
    )

    result = node.api_call(f"addresses/{source_address}/dispenses/receives")
    print(result)
    assert len(result["result"]) == 1
    assert result["result"][0]["asset"] == "FAIRMINT"

    return new_utxo


def send_funds_to_utxo(node, source_private_key):
    global SENDS_COUNT  # pylint: disable=global-statement # noqa PLW0603

    tx_hash, _block_hash, _block_time, _data = node.send_transaction(
        node.addresses[0],
        "attach",
        {
            "asset": "XCP",
            "quantity": 2,
            "utxo_value": 20000,
            "exact_fee": 0,
        },
    )
    result = node.api_call(f"addresses/{node.addresses[0]}/balances?type=utxo")
    assert len(result["result"]) == 1
    assert result["result"][0]["asset"] == "XCP"
    assert result["result"][0]["quantity"] == 2
    assert result["result"][0]["utxo"] == f"{tx_hash}:0"

    source_address = source_private_key.get_public_key().get_taproot_address().to_string()
    tx_hash, _block_hash, _block_time, _data = node.send_transaction(
        f"{tx_hash}:0",
        "movetoutxo",
        {
            "destination": source_address,
            "utxo_value": 20000,
            "exact_fee": 0,
        },
    )
    result = node.api_call(f"addresses/{source_address}/balances?type=utxo")
    assert len(result["result"]) == 1
    assert result["result"][0]["asset"] == "XCP"
    assert result["result"][0]["quantity"] == 2
    assert result["result"][0]["utxo"] == f"{tx_hash}:0"

    SENDS_COUNT[source_address] = SENDS_COUNT.get(source_address, 0) + 1

    return {
        "txid": tx_hash,
        "n": 0,
        "value": 20000,
    }


def check_detach(node, source_private_key, utxo):
    global SENDS_COUNT  # pylint: disable=global-statement # noqa PLW0603

    new_utxo = send_taproot_transaction(
        node,
        utxo,
        source_private_key,
        "detach",
        {
            "destination": node.addresses[1],
        },
        inputs_set=f"{utxo['txid']}:{utxo['n']}",
    )
    result = node.api_call(f"addresses/{node.addresses[1]}/sends?send_type=detach")
    assert len(result["result"]) == 1
    assert result["result"][0]["asset"] == "XCP"
    assert result["result"][0]["quantity"] == 2

    return new_utxo


def check_issuance(node, source_private_key, utxo):
    new_utxo = send_taproot_transaction(
        node,
        utxo,
        source_private_key,
        "issuance",
        {
            "asset": "A95428959745315388",
            "quantity": 100000,
            "description": "lore ipsum",
        },
    )

    source_address = source_private_key.get_public_key().get_taproot_address().to_string()
    result = node.api_call(f"addresses/{source_address}/issuances")
    print(result)
    assert len(result["result"]) == 1
    assert result["result"][0]["asset"] == "A95428959745315388"
    assert result["result"][0]["quantity"] == 100000

    return new_utxo


def test_p2ptr_inscription():
    setup("regtest")

    try:
        regtest_node_thread = RegtestNodeThread(burn_in_one_block=True)
        regtest_node_thread.start()
        while not regtest_node_thread.ready():
            time.sleep(1)
        node = regtest_node_thread.node

        source_private_key, utxo = generate_taproot_funded_address(node)
        source_private_key_2, utxo_2 = generate_taproot_funded_address(node)

        utxo = check_send(node, source_private_key, utxo, 10)
        utxo = check_send(node, source_private_key, utxo, 20)
        utxo = check_mpma_send(node, source_private_key, utxo, 10)
        utxo = check_broadcast(node, source_private_key, utxo, "a" * 10000)
        utxo = check_fairminter(node, source_private_key, utxo)
        utxo = check_fairmint(node, source_private_key, utxo)
        utxo = check_dispensers(node, source_private_key, utxo)
        attached_utxo = send_funds_to_utxo(node, source_private_key)
        utxo = check_detach(node, source_private_key, attached_utxo)
        utxo_2 = check_issuance(node, source_private_key_2, utxo_2)

    finally:
        print(regtest_node_thread.node.server_out.getvalue())
        regtest_node_thread.stop()
