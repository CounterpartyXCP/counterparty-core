#!/usr/bin/env python3

import hypothesis
from hypothesis import settings
from properytestnode import PropertyTestNode

MESSAGE_IDS = [
    0,
    2,
    3,
    4,
    10,
    11,
    12,
    13,
    20,
    21,
    22,
    23,
    30,
    40,
    50,
    60,
    70,
    80,
    90,
    91,
    100,
    101,
    102,
    110,
]


class UTXOSupportPropertyTest(PropertyTestNode):
    def run_tests(self):
        # issue random assets
        self.test_with_given_data(
            self.issue_assets,
            hypothesis.strategies.sampled_from(self.addresses),
            hypothesis.strategies.text(
                alphabet="BCDEFGHIJKLMNOPQRSTUVWXYZ", min_size=5, max_size=8
            ),
            hypothesis.strategies.integers(min_value=10 * 1e8, max_value=1000 * 1e8),
        )

        # attach assets
        self.test_with_given_data(
            self.attach_asset,
            hypothesis.strategies.sampled_from(self.balances),
            hypothesis.strategies.integers(min_value=1 * 1e8, max_value=10 * 1e8),
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

        # random invalid transactions
        self.test_with_given_data(
            self.invalid_transaction,
            hypothesis.strategies.sampled_from(self.addresses),
            hypothesis.strategies.sampled_from(MESSAGE_IDS),
            hypothesis.strategies.binary(min_size=20, max_size=30),
        )

        # issue, attach, move and detach assets chaining
        self.test_with_given_data(
            self.issue_attach_move_detach_send,
            hypothesis.strategies.sampled_from(self.addresses),
            hypothesis.strategies.text(
                alphabet="BCDEFGHIJKLMNOPQRSTUVWXYZ", min_size=9, max_size=11
            ),
            hypothesis.strategies.integers(min_value=10 * 1e8, max_value=1000 * 1e8),
            hypothesis.strategies.sampled_from(self.addresses),
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
        self.upsert_balance(f"{tx_hash}:1", asset, attach_quantity, source)

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

    @settings(deadline=None)
    def invalid_transaction(self, source, message_id, data):
        utxo, tx_hash = self.node.compose_and_send_transaction(
            source, message_id, data, no_confirmation=True, dont_wait_mempool=True
        )
        upserts = []
        # check if no utxo moves
        for address_or_utxo, asset, quantity, utxo_address in self.balances:
            if utxo == address_or_utxo:
                upserts.append([utxo, asset, -quantity, utxo_address])
                upserts.append([f"{tx_hash}:1", asset, quantity, utxo_address])
        for upsert in upserts:
            self.upsert_balance(*upsert)

    @settings(deadline=None, max_examples=20)
    def issue_attach_move_detach_send(self, source, asset_name, quantity, destination):
        # don't issue the same asset twice
        # and don't issue twice from the same source
        for balance in self.balances:
            if balance[1] == asset_name or (balance[0] == source and len(balance[1]) > 8):
                return
        tx_hash = self.send_transaction(
            source,
            "issuance",
            {
                "asset": asset_name,
                "quantity": quantity,
                "exact_fee": 0,
            },
        )
        tx_hash = self.send_transaction(
            source,
            "attach",
            {
                "asset": asset_name,
                "quantity": quantity,
                "exact_fee": 0,
                "validate": False,
                "inputs_set": f"{tx_hash}:1",
            },
        )
        tx_hash = self.send_transaction(
            f"{tx_hash}:1",
            "movetoutxo",
            {
                "destination": source,
                "exact_fee": 0,
                "validate": False,
                "inputs_set": f"{tx_hash}:1",
            },
        )
        tx_hash = self.send_transaction(
            f"{tx_hash}:0",
            "movetoutxo",
            {
                "destination": source,
                "exact_fee": 0,
                "validate": False,
                "inputs_set": f"{tx_hash}:0",
            },
        )
        tx_hash = self.send_transaction(
            f"{tx_hash}:0",
            "detach",
            {
                "exact_fee": 0,
                "validate": False,
                "inputs_set": f"{tx_hash}:0",
            },
        )
        if destination != source:
            print(f"source: {source}, destination: {destination}")
            tx_hash = self.send_transaction(
                source,
                "send",
                {
                    "destination": destination,
                    "asset": asset_name,
                    "quantity": int(10 * 1e8),
                    "exact_fee": 0,
                    "validate": False,
                    "inputs_set": f"{tx_hash}:1",
                },
            )
            self.upsert_balance(source, asset_name, quantity - 10 * 1e8)
            self.upsert_balance(destination, asset_name, 10 * 1e8)
        else:
            self.upsert_balance(source, asset_name, quantity)


if __name__ == "__main__":
    UTXOSupportPropertyTest()
