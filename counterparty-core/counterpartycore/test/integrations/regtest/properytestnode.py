import time

import hypothesis
from bitcoinutils.setup import setup
from counterpartycore.lib.parser import utxosinfo
from hypothesis import given
from regtestnode import RegtestNodeThread

setup("regtest")


class PropertyTestNode:
    def __init__(self):
        try:
            regtest_node_thread = RegtestNodeThread(burn_in_one_block=True)
            regtest_node_thread.start()
            while not regtest_node_thread.ready():
                time.sleep(1)
            self.node = regtest_node_thread.node
            self.addresses = self.node.addresses[:-1]  # skip last empty legacy address
            self.balances = []

            balances = self.node.api_call("assets/XCP/balances")["result"]
            for balance in balances:
                self.balances.append([balance["address"], "XCP", balance["quantity"], None])

            print(self.balances)

            self.node.start_electrs()
            self.node.wait_for_electrs()

            self.run_tests()
        except KeyboardInterrupt:
            print(regtest_node_thread.node.server_out.getvalue())
            pass
        except Exception as e:  # pylint: disable=broad-except
            print(regtest_node_thread.node.server_out.getvalue())
            raise e
        finally:
            # self.node.stop_electrs()
            # print(regtest_node_thread.node.server_out.getvalue())
            regtest_node_thread.stop()

    def send_transaction(self, source, transaction_name, params, taproot_encoding=False):
        if taproot_encoding:
            return self.send_taproot_transaction(source, transaction_name, params)
        tx_hash, _block_hash, _block_time, _data = self.node.send_transaction(
            source,
            transaction_name,
            params,
            no_confirmation=True,
            dont_wait_mempool=True,
        )
        return tx_hash

    def send_taproot_transaction(self, source, transaction_name, params):
        try:
            tx_hash, _block_hash, _block_time, result = self.node.send_transaction(
                source,
                transaction_name,
                params
                | {
                    "encoding": "taproot",
                },
                no_confirmation=True,
                dont_wait_mempool=True,
            )
            reveal_tx_hash = self.node.bitcoin_wallet(
                "sendrawtransaction", result["result"]["signed_reveal_rawtransaction"], 0
            ).strip()
            print(f"Reveal tx hash: {reveal_tx_hash}")

            return tx_hash
        except Exception as e:
            print(f"Error sending taproot transaction: {e}")
            raise

    def upsert_balance(self, address_or_utxo, asset, quantity, utxo_address=None):
        # print(f"Upserting balance for {address_or_utxo}: {asset} {quantity}")
        for balance in self.balances:
            if balance[0] == address_or_utxo and balance[1] == asset and balance[3] == utxo_address:
                balance[2] += quantity
                return
        self.balances.append([address_or_utxo, asset, quantity, utxo_address])

    def get_utxos_balances(self):
        return [balance for balance in self.balances if utxosinfo.is_utxo_format(balance[0])]

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
