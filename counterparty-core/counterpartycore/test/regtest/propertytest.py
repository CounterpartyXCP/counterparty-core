#!/usr/bin/env python3

import time

import hypothesis
from counterpartycore.lib import util
from hypothesis import given, settings
from regtestnode import RegtestNodeThread


@hypothesis.strategies.composite
def unique(draw, strategy):
    seen = draw(
        hypothesis.strategies.shared(hypothesis.strategies.builds(dict), key="key-for-unique-elems")
    )
    return draw(
        strategy.filter(lambda x: str(x) not in seen).map(lambda x: seen.update({str(x): x}) or x)
    )


class RegtestNode:
    def __init__(self):
        try:
            regtest_node_thread = RegtestNodeThread()
            regtest_node_thread.start()
            while not regtest_node_thread.ready():
                time.sleep(1)
            self.node = regtest_node_thread.node
            self.addresses = self.node.addresses[:-1]  # skip last empty legacy address
            self.balances = []

            self.run_test()
        except KeyboardInterrupt:
            pass
        except Exception as e:
            print(regtest_node_thread.node.server_out.getvalue())
            raise e
        finally:
            # print(regtest_node_thread.node.server_out.getvalue())
            regtest_node_thread.stop()

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
        given(*strategies)(function)()

        # mine block
        self.node.mine_blocks(1)
        self.node.wait_for_counterparty_server()

        # check balances
        given(hypothesis.strategies.sampled_from(self.balances))(self.check_balance)()

    def run_test(self):
        # issue random assets
        self.test_with_given_data(
            self.issue_assets,
            hypothesis.strategies.sampled_from(self.addresses),
            hypothesis.strategies.text(
                alphabet="BCDEFGHIJKLMNOPQRSTUVWXYZ", min_size=5, max_size=10
            ),
            hypothesis.strategies.integers(min_value=10 * 10e8, max_value=1000 * 10e8),
        )

        # attach assets
        self.test_with_given_data(
            self.attach_asset,
            hypothesis.strategies.sampled_from(self.balances),
            hypothesis.strategies.integers(min_value=1 * 10e8, max_value=10 * 10e8),
        )

        # move assets
        self.test_with_given_data(
            self.move_asset,
            hypothesis.strategies.sampled_from(self.balances),
            hypothesis.strategies.sampled_from(self.addresses),
        )

    @settings(deadline=None)
    def issue_assets(self, source, asset_name, quantity):
        for balance in self.balances:
            if balance[1] == asset_name or balance[0] == source:
                return
        self.node.send_transaction(
            source,
            "issuance",
            {
                "asset": asset_name,
                "quantity": quantity,
                "exact_fee": 0,
            },
            no_confirmation=True,
            dont_wait_mempool=True,
        )
        self.upsert_balance(source, asset_name, quantity)

    @settings(deadline=None)
    def attach_asset(self, balance, attach_quantity):
        source, asset, quantity, utxo_address = balance
        for balance in self.balances:
            if balance[3] == source or balance[2] == 0:
                return
        tx_hash, block_hash, block_time, data = self.node.send_transaction(
            source,
            "attach",
            {
                "asset": asset,
                "quantity": attach_quantity,
                "exact_fee": 0,
            },
            no_confirmation=True,
            dont_wait_mempool=True,
        )
        self.upsert_balance(source, asset, -attach_quantity, None)
        self.upsert_balance(f"{tx_hash}:0", asset, attach_quantity, source)

    @settings(deadline=None)
    def move_asset(self, balance, destination):
        source, asset, quantity, utxo_address = balance
        if utxo_address is None or source == destination or quantity == 0:
            return
        tx_hash, block_hash, block_time, data = self.node.send_transaction(
            source,
            "movetoutxo",
            {
                "destination": destination,
                "exact_fee": 0,
            },
            no_confirmation=True,
            dont_wait_mempool=True,
        )
        self.upsert_balance(source, asset, -quantity, utxo_address)
        self.upsert_balance(f"{tx_hash}:0", asset, quantity, destination)


if __name__ == "__main__":
    RegtestNode()
