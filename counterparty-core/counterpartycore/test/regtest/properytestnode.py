import time

import hypothesis
from counterpartycore.lib import util
from hypothesis import given
from regtestnode import RegtestNodeThread


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

            self.run_tests()
        except KeyboardInterrupt:
            pass
        except Exception as e:
            print(regtest_node_thread.node.server_out.getvalue())
            raise e
        finally:
            # print(regtest_node_thread.node.server_out.getvalue())
            regtest_node_thread.stop()

    def send_transaction(self, source, transaction_name, params):
        tx_hash, _block_hash, _block_time, _data = self.node.send_transaction(
            source,
            transaction_name,
            params,
            no_confirmation=True,
            dont_wait_mempool=True,
        )
        return tx_hash

    def upsert_balance(self, address_or_utxo, asset, quantity, utxo_address=None):
        for balance in self.balances:
            if balance[0] == address_or_utxo and balance[1] == asset and balance[3] == utxo_address:
                balance[2] += quantity
                return
        self.balances.append([address_or_utxo, asset, quantity, utxo_address])

    def check_balance(self, balance):
        address_or_utxo, asset, quantity, utxo_address = balance

        if util.is_utxo_format(address_or_utxo):
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
        time.sleep(0.1)
        given(hypothesis.strategies.sampled_from(self.balances))(self.check_balance)()

    def run_tests(self):
        raise NotImplementedError
