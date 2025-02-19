import binascii
import json
import os
import time

import requests
from bitcoinutils.keys import PrivateKey
from bitcoinutils.script import Script
from bitcoinutils.setup import setup
from bitcoinutils.transactions import Transaction, TxInput, TxOutput, TxWitnessInput
from bitcoinutils.utils import ControlBlock
from counterpartycore.lib.utils import helpers
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
        txid = node.bitcoin_wallet("sendtoaddress", source_address.to_string(), 10000 / 1e8).strip()
        node.mine_blocks(1)

        # search for the vout
        vout = None
        decoded_tx = json.loads(node.bitcoin_cli("getrawtransaction", txid, 1).strip())
        for n, out in enumerate(decoded_tx["vout"]):
            if out["scriptPubKey"]["address"] == source_address.to_string():
                vout = n
                break
        assert vout is not None

        # create the input
        tx_in = TxInput(txid, vout)

        # Outputs

        original_content = b"\x01" * 1024 * 1024 * 3  # 3MB of data
        # split the data in chunks of 520 bytes
        datas = helpers.chunkify(original_content, 520)
        datas = [binascii.hexlify(data).decode("utf-8") for data in datas]

        # Build inscription envelope script
        inscription_script = Script(["OP_FALSE", "OP_IF"] + datas + ["OP_ENDIF"])
        # use source address as destination
        destination_address = source_pubkey.get_taproot_address([[inscription_script]])
        print("To Taproot script address", destination_address.to_string())

        # create the output and the transaction
        tx_out = TxOutput(10000, destination_address.to_script_pub_key())
        commit_tx = Transaction([tx_in], [tx_out], has_segwit=True)

        txid_before_sign = commit_tx.get_txid()

        # REVEAL

        txid = txid_before_sign
        vout = 0

        # use commit tx as input
        tx_in = TxInput(txid, vout)
        # use source address as output
        tx_out = TxOutput(10000, source_address.to_script_pub_key())
        reveal_tx = Transaction([tx_in], [tx_out], has_segwit=True)

        # sign the input
        sig = source_private_key.sign_taproot_input(
            commit_tx, 0, [source_address.to_script_pub_key()], [10000]
        )
        # add the witness to the transaction
        commit_tx.witnesses.append(TxWitnessInput([sig]))

        print("Signed Commit Transaction:", commit_tx.serialize())

        # sign the input containing the inscription script
        sig = source_private_key.sign_taproot_input(
            reveal_tx,
            0,
            [destination_address.to_script_pub_key()],
            [10000],
            script_path=True,
            tapleaf_script=inscription_script,
            tweak=False,
        )
        # generate the control block
        control_block = ControlBlock(
            source_pubkey,
            scripts=[inscription_script],
            index=0,
            is_odd=destination_address.is_odd(),
        )

        # add the witness to the transaction
        reveal_tx.witnesses.append(
            TxWitnessInput([sig, inscription_script.to_hex(), control_block.to_hex()])
        )

        print("Signed Reveal Transaction:", reveal_tx.serialize()[0:100])

        # send the transaction and mine a block
        commit_txid = rpc_call("sendrawtransaction", [commit_tx.serialize()])["result"]
        node.mine_blocks(1)

        reveal_txid = rpc_call("sendrawtransaction", [reveal_tx.serialize()])["result"]

        node.mine_blocks(1)
        assert commit_txid == txid_before_sign

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
