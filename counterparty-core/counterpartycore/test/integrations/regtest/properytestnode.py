import json
import os
import time

import hypothesis
from bitcoinutils.keys import PrivateKey
from bitcoinutils.script import Script
from bitcoinutils.setup import setup
from bitcoinutils.transactions import Transaction, TxWitnessInput
from counterpartycore.lib.parser import utxosinfo
from hypothesis import given
from regtestnode import RegtestNodeThread, SignTransactionError

setup("regtest")


class PropertyTestNode:
    def __init__(self):
        try:
            regtest_node_thread = RegtestNodeThread(burn_in_one_block=True)
            regtest_node_thread.start()
            while not regtest_node_thread.ready():
                time.sleep(1)
            self.node = regtest_node_thread.node
            self.addresses = self.node.addresses[0:7]
            self.balances = []

            self.node.start_electrs()
            self.node.wait_for_electrs()

            self.taproot_addresses = {}
            for i in range(3):
                taproot_address, private_key, utxo = self.generate_taproot_funded_address(
                    self.node.addresses[7 + i]
                )
                self.taproot_addresses[taproot_address] = (private_key, utxo)
                self.addresses.append(taproot_address)

            balances = self.node.api_call("assets/XCP/balances")["result"]
            for balance in balances:
                if balance["address"] in self.addresses:
                    self.balances.append([balance["address"], "XCP", balance["quantity"], None])

            self.utxo_to_address = {}

            self.run_tests()
        except KeyboardInterrupt:
            print(regtest_node_thread.node.server_out.getvalue())
            pass
        except Exception as e:  # pylint: disable=broad-except
            print(regtest_node_thread.node.server_out.getvalue())
            raise e
        finally:
            # print(regtest_node_thread.node.server_out.getvalue())
            regtest_node_thread.stop()

    def sign_taproot_transaction(self, source, rawtransaction):
        try:
            if ":" in source:
                source_address = self.get_utxo_address(source)
            else:
                source_address = source
            print("Source address", source, source_address)
            source_private_key, _utxo = self.taproot_addresses[source_address]
            source_pubkey = source_private_key.get_public_key()
            source_address = source_pubkey.get_taproot_address()
            # sign commit tx
            tx = Transaction.from_raw(rawtransaction)
            tx.has_segwit = True
            # retrieve script_pub_key and amount
            source_tx = json.loads(
                self.node.bitcoin_cli("getrawtransaction", tx.inputs[0].txid, 1).strip()
            )
            script_pubkey = Script.from_raw(
                source_tx["vout"][tx.inputs[0].txout_index]["scriptPubKey"]["hex"]
            )
            value = int(source_tx["vout"][tx.inputs[0].txout_index]["value"] * 10**8)
            # sign the input
            sig = source_private_key.sign_taproot_input(tx, 0, [script_pubkey], [value])

            # add the witness to the transaction
            tx.witnesses.append(TxWitnessInput([sig]))
            tx_hash = self.node.bitcoin_wallet("sendrawtransaction", tx.serialize(), 0).strip()
            print("Taproot tx hash", tx_hash)
            return tx_hash
        except Exception as e:
            print(f"Error sign_taproot_transaction {e}")
            raise

    def send_transaction(self, source, transaction_name, params, taproot_encoding=False):
        tx_params = params.copy() | {"disable_utxo_locks": True}
        if taproot_encoding:
            tx_params["encoding"] = "taproot"

        try:
            tx_hash, _block_hash, _block_time, result = self.node.send_transaction(
                source,
                transaction_name,
                tx_params,
                no_confirmation=True,
                dont_wait_mempool=True,
            )
        except SignTransactionError as e:
            print(f"Error signing transaction, trying manually: {e}")
            result = e.result
            tx_hash = self.sign_taproot_transaction(source, result["result"]["rawtransaction"])

        if "signed_reveal_rawtransaction" in result["result"]:
            reveal_tx_hash = self.node.bitcoin_wallet(
                "sendrawtransaction", result["result"]["signed_reveal_rawtransaction"], 0
            ).strip()
            print(f"Reveal tx hash: {reveal_tx_hash}")

        return tx_hash

    def generate_taproot_funded_address(self, funding_address):
        print("Generating taproot funded address")

        random = os.urandom(32)
        source_private_key = PrivateKey(b=random)
        source_pubkey = source_private_key.get_public_key()
        source_address = source_pubkey.get_taproot_address()
        print("Source address", source_address.to_string())
        print("Source script_pub_key", source_address.to_script_pub_key().to_hex())
        print("funding address", funding_address)

        # send some BTC to the source address
        list_unspent = json.loads(
            self.node.bitcoin_cli("listunspent", 0, 9999999, json.dumps([funding_address])).strip()
        )
        inputs = []
        amount = 0
        for utxo in list_unspent:
            inputs.append(
                {
                    "txid": utxo["txid"],
                    "vout": int(utxo["vout"]),
                }
            )
            amount += utxo["amount"]
        outputs = [{source_address.to_string(): amount - 1}, {funding_address: 1}]
        raw_tx = self.node.bitcoin_wallet(
            "createrawtransaction", json.dumps(inputs), json.dumps(outputs)
        ).strip()
        signed_tx = json.loads(
            self.node.bitcoin_wallet("signrawtransactionwithwallet", raw_tx).strip()
        )["hex"]
        txid = self.node.bitcoin_wallet("sendrawtransaction", signed_tx, 0).strip()
        print("Funding txid", txid)

        self.node.mine_blocks(1)

        raw_tx = json.loads(self.node.bitcoin_cli("getrawtransaction", txid, 1).strip())

        n = None
        change_n = None
        for i, vout in enumerate(raw_tx["vout"]):
            if vout["scriptPubKey"]["address"] == source_address.to_string():
                n = i
            else:
                change_n = i
        if n is None:
            raise Exception("Could not find the vout for the source address")

        # send some XCP to the source address
        self.node.send_transaction(
            funding_address,
            "send",
            {
                "destination": source_address.to_string(),
                "quantity": 10 * 10**8,
                "asset": "XCP",
                "inputs_set": f"{txid}:{change_n}",
            },
        )
        return (
            source_address.to_string(),
            source_private_key,
            {
                "txid": txid,
                "n": n,
                "value": int(1 * 10**8),
            },
        )

    def upsert_balance(self, address_or_utxo, asset, quantity, utxo_address=None):
        # print(f"Upserting balance for {address_or_utxo}: {asset} {quantity}")
        for balance in self.balances:
            if balance[0] == address_or_utxo and balance[1] == asset and balance[3] == utxo_address:
                balance[2] += quantity
                return
        self.balances.append([address_or_utxo, asset, quantity, utxo_address])

    def get_utxos_balances(self):
        return [balance for balance in self.balances if utxosinfo.is_utxo_format(balance[0])]

    def get_utxo_address(self, utxo):
        for balance in self.balances:
            if balance[0] == utxo:
                return balance[3]
        if utxo in self.utxo_to_address:
            return self.utxo_to_address[utxo]
        raise Exception(f"UTXO {utxo} not found in balances")

    def check_balance(self, balance):
        address_or_utxo, asset, quantity, utxo_address = balance

        if utxosinfo.is_utxo_format(address_or_utxo):
            field_name = "utxo"
        else:
            field_name = "address"

        balances = self.node.api_call(f"assets/{asset}/balances")["result"]

        for balance_item in balances:
            if (
                balance_item[field_name] == address_or_utxo
                and balance_item["quantity"] == quantity
                and balance_item["asset"] == asset
                and balance_item["utxo_address"] == utxo_address
            ):
                print(f"Valid balance found for {address_or_utxo} {asset}")
                return
        if quantity > 0:
            raise Exception(f"Valid balance not found for {address_or_utxo} {asset}")

    def test_with_given_data(self, function, *strategies):
        # Each test must update the balances with the function `self.upsert_balance()`.
        # All transactions done in the test must be done with the function `self.send_transaction()`.
        # All transactions are done with the `no_confirmation=True` and `dont_wait_mempool=True` flags
        # and are in the mempool after the test.
        # after each test, a block is mined and the balances are checked with the function `self.check_balance()`.
        given(*strategies)(function)()

        # mine block
        self.node.mine_blocks(1)
        self.node.wait_for_counterparty_server()

        # check balances
        given(hypothesis.strategies.sampled_from(self.balances))(self.check_balance)()

    def run_tests(self):
        raise NotImplementedError
