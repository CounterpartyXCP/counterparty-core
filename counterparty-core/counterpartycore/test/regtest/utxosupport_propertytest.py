#!/usr/bin/env python3

import hypothesis
from hypothesis import settings
from properytestnode import PropertyTestNode


class UTXOSupportPropertyTest(PropertyTestNode):
    def run_tests(self):
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

        # detach assets
        self.test_with_given_data(
            self.detach_asset,
            hypothesis.strategies.sampled_from(self.balances),
            hypothesis.strategies.sampled_from(self.addresses + [None]),
        )

    @settings(deadline=None)
    def issue_assets(self, source, asset_name, quantity):
        # don't issue the same asset twice
        # and don't issue twice from the same source
        for balance in self.balances:
            if balance[1] == asset_name or balance[0] == source:
                return
        self.send_transaction(
            source,
            "issuance",
            {
                "asset": asset_name,
                "quantity": quantity,
                "exact_fee": 0,
            },
        )
        self.upsert_balance(source, asset_name, quantity)

    @settings(deadline=None)
    def attach_asset(self, balance, attach_quantity):
        source, asset, quantity, utxo_address = balance
        # don't attach assets already attached or with 0 quantity
        for balance in self.balances:
            if balance[3] == source or balance[2] == 0:
                return
        tx_hash = self.send_transaction(
            source,
            "attach",
            {
                "asset": asset,
                "quantity": attach_quantity,
                "exact_fee": 0,
            },
        )
        self.upsert_balance(source, asset, -attach_quantity, None)
        self.upsert_balance(f"{tx_hash}:0", asset, attach_quantity, source)

    @settings(deadline=None)
    def move_asset(self, balance, destination):
        source, asset, quantity, utxo_address = balance
        # don't move assets not attached, with 0 quantity or to the same address
        if utxo_address is None or source == destination or quantity == 0:
            return
        tx_hash = self.send_transaction(
            source,
            "movetoutxo",
            {
                "destination": destination,
                "exact_fee": 0,
            },
        )
        self.upsert_balance(source, asset, -quantity, utxo_address)
        self.upsert_balance(f"{tx_hash}:0", asset, quantity, destination)

    @settings(deadline=None)
    def detach_asset(self, balance, destination):
        source, asset, quantity, utxo_address = balance
        # don't detach assets not attached or with 0 quantity
        if utxo_address is None or quantity == 0:
            return
        self.send_transaction(
            source,
            "detach",
            {
                "exact_fee": 0,
                "destination": destination,
            },
        )
        self.upsert_balance(source, asset, -quantity, utxo_address)
        self.upsert_balance(destination or utxo_address, asset, quantity, None)


if __name__ == "__main__":
    UTXOSupportPropertyTest()
