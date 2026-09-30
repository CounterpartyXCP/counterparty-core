import binascii
import os
import time

import pytest
from bitcoinutils.keys import P2wpkhAddress, PrivateKey
from bitcoinutils.script import Script
from bitcoinutils.setup import setup
from bitcoinutils.transactions import Transaction, TxInput, TxOutput, TxWitnessInput
from bitcoinutils.utils import ControlBlock
from counterpartycore.lib import exceptions
from regtestnode import RegtestNodeThread, rpc_call

SENDS_COUNT = {}


def source_address_for(source_private_key, source_type):
    source_pubkey = source_private_key.get_public_key()
    if source_type == "p2wpkh":
        return source_pubkey.get_segwit_address()
    return source_pubkey.get_taproot_address()


def sign_commit_input(commit_tx, source_private_key, utxo, source_type):
    source_pubkey = source_private_key.get_public_key()
    source_address = source_address_for(source_private_key, source_type)
    if source_type == "p2wpkh":
        sig = source_private_key.sign_segwit_input(
            commit_tx, 0, source_pubkey.get_address().to_script_pub_key(), utxo["value"]
        )
        commit_tx.witnesses.append(TxWitnessInput([sig, source_pubkey.to_hex()]))
    else:
        sig = source_private_key.sign_taproot_input(
            commit_tx, 0, [source_address.to_script_pub_key()], [utxo["value"]]
        )
        commit_tx.witnesses.append(TxWitnessInput([sig]))


def sign_reveal_transaction(compose_result, commit_tx, source_private_key):
    """The wallet side of a taproot-encoded transaction: add the witness
    `<signature> <envelope_script> <reveal_control_block>` to the unsigned
    reveal returned by the composer. The envelope is closed by the source key
    and the node attributes the reveal to the source only when that key signed
    it (`require_reveal_source_signature`)."""
    reveal_tx = Transaction.from_raw(compose_result["reveal_rawtransaction"])
    reveal_tx.has_segwit = True
    envelope_script = Script.from_raw(compose_result["envelope_script"])
    assert envelope_script.script[-2] == source_private_key.get_public_key().to_x_only_hex()
    assert compose_result["reveal_pubkey"] == envelope_script.script[-2]
    commit_output = commit_tx.outputs[0]
    assert commit_output.script_pubkey.to_hex() == compose_result["reveal_lock_scripts"][0]
    assert commit_output.amount == compose_result["reveal_inputs_values"][0]
    sig = source_private_key.sign_taproot_input(
        reveal_tx,
        0,
        [commit_output.script_pubkey],
        [commit_output.amount],
        script_path=True,
        tapleaf_script=envelope_script,
        tweak=False,
    )
    reveal_tx.witnesses.append(
        TxWitnessInput([sig, envelope_script.to_hex(), compose_result["reveal_control_block"]])
    )
    return reveal_tx


def send_taproot_transaction(
    node,
    utxo,
    source_private_key,
    tx_name,
    params,
    inputs_set=None,
    invalid_sig=False,
    source_type="p2tr",
):
    source_pubkey = source_private_key.get_public_key()
    source_address = source_address_for(source_private_key, source_type)

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
        use_rpc=True,
    )

    # sign commit tx
    commit_tx = Transaction.from_raw(result["rawtransaction"])
    commit_tx.has_segwit = True
    sign_commit_input(commit_tx, source_private_key, utxo, source_type)
    node.broadcast_transaction(commit_tx.serialize())

    print("Commit TX Broadcasted:", commit_tx.get_txid(), commit_tx.serialize())

    # the node no longer signs the reveal: the source does
    assert "signed_reveal_rawtransaction" not in result
    reveal_tx = sign_reveal_transaction(result, commit_tx, source_private_key)
    node.broadcast_transaction(reveal_tx.serialize(), use_rpc=True)

    print("Reveal TX Broadcasted:", reveal_tx.get_txid())

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
            "quantity": 10 * 10**8,
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


def generate_p2wpkh_funded_address(node):
    """A P2WPKH source whose key this test holds, funded with BTC and XCP."""
    source_private_key = PrivateKey(b=os.urandom(32))
    source_address = source_private_key.get_public_key().get_segwit_address()
    txid = node.bitcoin_wallet("sendtoaddress", source_address.to_string(), 1).strip()
    node.mine_blocks(1)
    raw_tx = rpc_call("getrawtransaction", [txid, 1])["result"]
    n = next(
        i
        for i, vout in enumerate(raw_tx["vout"])
        if vout["scriptPubKey"]["address"] == source_address.to_string()
    )
    node.send_transaction(
        node.addresses[0],
        "send",
        {"destination": source_address.to_string(), "quantity": 10 * 10**8, "asset": "XCP"},
    )
    return source_private_key, {"txid": txid, "n": n, "value": int(1 * 10**8)}


def check_send_from_p2wpkh(node, source_private_key, utxo, quantity):
    """A P2WPKH source signs both the commit (segwit v0) and the reveal (the
    tapscript leaf) with the same key."""
    source_address = source_private_key.get_public_key().get_segwit_address().to_string()
    new_utxo = send_taproot_transaction(
        node,
        utxo,
        source_private_key,
        "send",
        {"destination": node.addresses[1], "quantity": quantity, "asset": "XCP"},
        source_type="p2wpkh",
    )
    # `/sends` also lists the incoming XCP funding send: keep the outgoing ones
    result = node.api_call(f"addresses/{source_address}/sends")
    sends = [send for send in result["result"] if send["source"] == source_address]
    assert len(sends) == 1
    assert sends[0]["asset"] == "XCP"
    assert sends[0]["quantity"] == quantity
    assert sends[0]["destination"] == node.addresses[1]
    return new_utxo


def check_unauthorized_reveal_is_ignored(node, victim_private_key, victim_utxo):
    """GHSA-q27c-r246-f6qw replayed: the attacker publishes a commit address
    whose hidden leaf carries a sweep of the victim closed by the *attacker's*
    key, the victim pays plain BTC to it, and the attacker reveals. The node
    must not attribute that reveal to the victim."""
    victim_pubkey = victim_private_key.get_public_key()
    victim_address = victim_pubkey.get_taproot_address()
    attacker_private_key = PrivateKey(b=os.urandom(32))
    attacker_pubkey = attacker_private_key.get_public_key()
    attacker_address = attacker_pubkey.get_segwit_address().to_string()

    balances_before = node.api_call(f"addresses/{victim_address.to_string()}/balances")["result"]
    assert len(balances_before) > 0

    # the sweep message the attacker wants attributed to the victim
    data = node.send_transaction(
        victim_address.to_string(),
        "sweep",
        {"destination": attacker_address, "flags": 3, "memo": ""},
        return_only_data=True,
    )
    message = binascii.unhexlify(data)[len(b"CNTRPRTY") :]
    envelope_script = Script(
        [
            "OP_FALSE",
            "OP_IF",
            binascii.hexlify(message).decode("ascii"),
            "OP_ENDIF",
            attacker_pubkey.to_x_only_hex(),
            "OP_CHECKSIG",
        ]
    )
    commit_address = attacker_pubkey.get_taproot_address([[envelope_script]])

    # the victim makes an ordinary BTC payment to the attacker's address
    commit_value = 100000
    change_value = victim_utxo["value"] - commit_value - 10000
    commit_tx = Transaction(
        [TxInput(victim_utxo["txid"], victim_utxo["n"])],
        [
            TxOutput(commit_value, commit_address.to_script_pub_key()),
            TxOutput(change_value, victim_address.to_script_pub_key()),
        ],
    )
    commit_tx.has_segwit = True
    sig = victim_private_key.sign_taproot_input(
        commit_tx, 0, [victim_address.to_script_pub_key()], [victim_utxo["value"]]
    )
    commit_tx.witnesses.append(TxWitnessInput([sig]))
    node.broadcast_transaction(commit_tx.serialize())

    # the attacker spends it in a reveal-shaped transaction
    reveal_tx = Transaction(
        [TxInput(commit_tx.get_txid(), 0)],
        [
            TxOutput(0, Script(["OP_RETURN", binascii.hexlify(b"CNTRPRTY").decode("ascii")])),
            TxOutput(commit_value - 5000, P2wpkhAddress(attacker_address).to_script_pub_key()),
        ],
    )
    reveal_tx.has_segwit = True
    sig = attacker_private_key.sign_taproot_input(
        reveal_tx,
        0,
        [commit_address.to_script_pub_key()],
        [commit_value],
        script_path=True,
        tapleaf_script=envelope_script,
        tweak=False,
    )
    control_block = ControlBlock(
        attacker_pubkey, scripts=[envelope_script], index=0, is_odd=commit_address.is_odd()
    )
    reveal_tx.witnesses.append(
        TxWitnessInput([sig, envelope_script.to_hex(), control_block.to_hex()])
    )
    node.broadcast_transaction(reveal_tx.serialize(), use_rpc=True)
    print("Unauthorized reveal broadcasted:", reveal_tx.get_txid())

    # Bitcoin accepted it; Counterparty must have ignored it
    result = node.api_call(f"transactions/{reveal_tx.get_txid()}")
    assert "error" in result, result
    assert "not signed by its source" in node.server_out.getvalue()
    balances_after = node.api_call(f"addresses/{victim_address.to_string()}/balances")["result"]
    assert balances_after == balances_before
    attacker_balances = node.api_call(f"addresses/{attacker_address}/balances")["result"]
    assert attacker_balances == []

    return {"txid": commit_tx.get_txid(), "n": 1, "value": change_value}


def check_send(node, source_private_key, utxo, quantity, invalid_sig=False):
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
        invalid_sig=invalid_sig,
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


def check_order(node, source_private_key, utxo):
    new_utxo = send_taproot_transaction(
        node,
        utxo,
        source_private_key,
        "order",
        {
            "give_asset": "XCP",
            "give_quantity": 1000,
            "get_asset": "BTC",
            "get_quantity": 1000,
            "expiration": 21,
            "fee_required": 0,
        },
    )

    source_address = source_private_key.get_public_key().get_taproot_address().to_string()
    result = node.api_call(f"addresses/{source_address}/orders")
    print(result)
    assert len(result["result"]) == 1
    assert result["result"][0]["give_asset"] == "XCP"
    assert result["result"][0]["get_asset"] == "BTC"
    assert result["result"][0]["status"] == "open"

    return new_utxo, result["result"][0]["tx_hash"]


def check_cancel(node, source_private_key, utxo, order_hash):
    new_utxo = send_taproot_transaction(
        node,
        utxo,
        source_private_key,
        "cancel",
        {
            "offer_hash": order_hash,
        },
    )

    source_address = source_private_key.get_public_key().get_taproot_address().to_string()
    result = node.api_call(f"addresses/{source_address}/orders")
    print(result)
    assert len(result["result"]) == 1
    assert result["result"][0]["give_asset"] == "XCP"
    assert result["result"][0]["get_asset"] == "BTC"
    assert result["result"][0]["status"] == "cancelled"

    return new_utxo


def check_destroy(node, source_private_key, utxo):
    new_utxo = send_taproot_transaction(
        node,
        utxo,
        source_private_key,
        "destroy",
        {
            "asset": "XCP",
            "quantity": 1,
            "tag": "destroy",
        },
    )

    source_address = source_private_key.get_public_key().get_taproot_address().to_string()
    result = node.api_call(f"addresses/{source_address}/destructions")
    print(result)
    assert len(result["result"]) == 1
    assert result["result"][0]["asset"] == "XCP"
    assert result["result"][0]["quantity"] == 1
    assert result["result"][0]["tag"] == binascii.hexlify(b"destroy").decode("utf-8")

    return new_utxo


def check_send2(node, source_private_key, utxo, invalid_sig=False):
    global SENDS_COUNT  # pylint: disable=global-statement # noqa PLW0603

    new_utxo = send_taproot_transaction(
        node,
        utxo,
        source_private_key,
        "send",
        {
            "destination": node.addresses[1],
            "quantity": 2,
            "asset": "A95428959745315388",
        },
        invalid_sig=invalid_sig,
    )

    source_address = source_private_key.get_public_key().get_taproot_address().to_string()
    SENDS_COUNT[source_address] = SENDS_COUNT.get(source_address, 0) + 1
    print("SEND COUNT", SENDS_COUNT)

    result = node.api_call(f"addresses/{source_address}/sends")
    assert len(result["result"]) == SENDS_COUNT[source_address]
    assert result["result"][0]["asset"] == "A95428959745315388"
    assert result["result"][0]["quantity"] == 2
    assert result["result"][0]["source"] == source_address
    assert result["result"][0]["destination"] == node.addresses[1]

    result = node.api_call("assets/A95428959745315388/balances")
    print(result)

    return new_utxo


def check_dividend(node, source_private_key, utxo):
    new_utxo = send_taproot_transaction(
        node,
        utxo,
        source_private_key,
        "dividend",
        {
            "asset": "A95428959745315388",
            "quantity_per_unit": 1000000000,
            "dividend_asset": "XCP",
        },
    )

    source_address = source_private_key.get_public_key().get_taproot_address().to_string()
    result = node.api_call(f"addresses/{source_address}/dividends")
    print(result)
    assert len(result["result"]) == 1
    assert result["result"][0]["asset"] == "A95428959745315388"
    assert result["result"][0]["quantity_per_unit"] == 1000000000
    assert result["result"][0]["dividend_asset"] == "XCP"

    return new_utxo


def check_sweep(node, source_private_key, utxo):
    new_utxo = send_taproot_transaction(
        node,
        utxo,
        source_private_key,
        "sweep",
        {
            "destination": node.addresses[2],
            "flags": 3,
            "memo": "sweep sweep",
        },
    )

    source_address = source_private_key.get_public_key().get_taproot_address().to_string()
    result = node.api_call(f"addresses/{source_address}/sweeps")
    assert len(result["result"]) == 1
    assert result["result"][0]["destination"] == node.addresses[2]
    assert result["result"][0]["memo"] == "sweep sweep"

    return new_utxo


def check_fairminter2(node, source_private_key, utxo):
    last_block = int(node.api_call("")["result"]["counterparty_height"])
    new_utxo = send_taproot_transaction(
        node,
        utxo,
        source_private_key,
        "fairminter",
        {
            "asset": "A95428959745315389",
            "price": 1,
            "hard_cap": 100 * 10**8,
            "description": "a" * 400000,
            "mime_type": "image/gif",
            "premint_quantity": 100,
            "start_block": last_block + 1,
            "soft_cap": 90 * 10**8,
            "soft_cap_deadline_block": last_block + 10,
        },
    )

    source_address = source_private_key.get_public_key().get_taproot_address().to_string()
    result = node.api_call(f"addresses/{source_address}/fairminters")
    assert len(result["result"]) == 1
    assert result["result"][0]["asset"] == "A95428959745315389"

    result = node.api_call("assets/A95428959745315389")
    assert result["result"]["mime_type"] == "image/gif"

    return new_utxo


def check_fairminter3(node, source_private_key, utxo, invalid_sig=False):
    last_block = int(node.api_call("")["result"]["counterparty_height"])
    new_utxo = send_taproot_transaction(
        node,
        utxo,
        source_private_key,
        "fairminter",
        {
            "asset": "A95428959745315390",
            "price": 1,
            "hard_cap": 100 * 10**8,
            "description": "a" * 400000,
            "premint_quantity": 100,
            "start_block": last_block + 1,
            "soft_cap": 90 * 10**8,
            "soft_cap_deadline_block": last_block + 10,
        },
        invalid_sig=invalid_sig,
    )

    source_address = source_private_key.get_public_key().get_taproot_address().to_string()
    result = node.api_call(f"addresses/{source_address}/fairminters")
    assert len(result["result"]) == 1
    assert result["result"][0]["asset"] == "A95428959745315390"

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
        utxo = check_unauthorized_reveal_is_ignored(node, source_private_key, utxo)
        p2wpkh_private_key, p2wpkh_utxo = generate_p2wpkh_funded_address(node)
        check_send_from_p2wpkh(node, p2wpkh_private_key, p2wpkh_utxo, 30)
        utxo = check_mpma_send(node, source_private_key, utxo, 10)
        utxo = check_broadcast(node, source_private_key, utxo, "a" * 10000)
        utxo = check_fairminter(node, source_private_key, utxo)
        utxo = check_fairmint(node, source_private_key, utxo)
        utxo = check_dispensers(node, source_private_key, utxo)
        attached_utxo = send_funds_to_utxo(node, source_private_key)
        with pytest.raises(
            exceptions.ComposeError, match="Cannot use `taproot` encoding for UTXO transactions"
        ):
            check_detach(node, source_private_key, attached_utxo)

        utxo_2 = check_issuance(node, source_private_key_2, utxo_2)
        utxo_2, order_hash = check_order(node, source_private_key_2, utxo_2)
        utxo_2 = check_cancel(node, source_private_key_2, utxo_2, order_hash)
        utxo_2 = check_destroy(node, source_private_key_2, utxo_2)
        utxo_2 = check_send2(node, source_private_key_2, utxo_2)
        utxo_2 = check_dividend(node, source_private_key_2, utxo_2)
        utxo_2 = check_sweep(node, source_private_key_2, utxo_2)
        utxo_2 = check_fairminter2(node, source_private_key_2, utxo_2)

        assert (
            "invalid: Soft cap deadline block must be > start block."
            not in node.server_out.getvalue()
        )
        print("All tests passed")

    except Exception as e:  # pylint: disable=broad-exception-caught
        print(regtest_node_thread.node.server_out.getvalue())
        raise e
    finally:
        # print(regtest_node_thread.node.server_out.getvalue())
        regtest_node_thread.stop()
