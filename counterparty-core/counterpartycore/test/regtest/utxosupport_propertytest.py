#!/usr/bin/env python3

import hypothesis
from counterpartycore.lib import util
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

        # random invalid transactions
        self.test_with_given_data(
            self.invalid_transaction,
            hypothesis.strategies.sampled_from(self.addresses),
            hypothesis.strategies.sampled_from(MESSAGE_IDS),
            hypothesis.strategies.binary(min_size=20, max_size=30),
        )

        # issue, attach, move and detach assets chaining
        self.already_chained = []
        self.test_with_given_data(
            self.issue_attach_move_detach_send,
            hypothesis.strategies.sampled_from(self.addresses),
            hypothesis.strategies.text(
                alphabet="BCDEFGHIJKLMNOPQRSTUVWXYZ", min_size=9, max_size=11
            ),
            hypothesis.strategies.integers(min_value=10 * 1e8, max_value=1000 * 1e8),
            hypothesis.strategies.sampled_from(self.addresses),
        )

        # test move with counterparty data
        self.alrady_used = []
        self.test_with_given_data(
            self.move_with_counterparty_data,
            hypothesis.strategies.sampled_from(self.get_utxos_balances()),
            hypothesis.strategies.sampled_from(self.addresses),
        )

        # detach assets
        self.alrady_used = []
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
            if balance[1] == asset_name or (balance[0] == source and balance[1] != "XCP"):
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
        # issuance fee
        self.upsert_balance(source, "XCP", -50000000, None)

    @settings(deadline=None)
    def attach_asset(self, balance, attach_quantity):
        source, asset, quantity, utxo_address = balance
        if asset == "XCP":
            return
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
        if asset_name == "XCP":
            return
        for balance in self.balances:
            if balance[1] == asset_name or (balance[0] == source and len(balance[1]) > 8):
                return
        if source in self.already_chained:
            return
        self.already_chained.append(source)

        tx_hash = self.send_transaction(
            source,
            "issuance",
            {
                "asset": asset_name,
                "quantity": quantity,
                "exact_fee": 0,
                "exclude_utxos_with_balances": True,
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

        # issuance fee
        self.upsert_balance(source, "XCP", -50000000, None)
        if destination != source:
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

    @settings(deadline=None)
    def move_with_counterparty_data(self, utxo_balance, destination):
        utxo, utxo_asset, utxo_quantity, utxo_address = utxo_balance

        if utxo in self.alrady_used or utxo_quantity == 0 or utxo_asset == "XCP":
            return
        self.alrady_used.append(utxo)

        tx_hash = self.send_transaction(
            utxo_address,
            "send",
            {
                "destination": destination,
                "asset": "XCP",
                "quantity": 100,
                "exact_fee": 0,
                "inputs_set": utxo,
                "use_utxos_with_balances": True,
            },
        )
        tx_hash = self.send_transaction(
            utxo_address,
            "broadcast",
            {
                "timestamp": 4003903983,
                "value": 999,
                "fee_fraction": 0.0,
                "text": "Hello, world!",
                "exact_fee": 0,
                "inputs_set": f"{tx_hash}:1",
                "use_utxos_with_balances": True,
            },
        )
        tx_hash = self.send_transaction(
            utxo_address,
            "attach",
            {
                "asset": "XCP",
                "quantity": 200,
                "exact_fee": 0,
                "inputs_set": f"{tx_hash}:1",
                "use_utxos_with_balances": True,
            },
        )
        tx_hash = self.send_transaction(
            utxo_address,
            "order",
            {
                "give_asset": "XCP",
                "give_quantity": 1000,
                "get_asset": "BTC",
                "get_quantity": 1000,
                "expiration": 21,
                "fee_required": 0,
                "exact_fee": 0,
                "inputs_set": f"{tx_hash}:0",
                "use_utxos_with_balances": True,
            },
        )
        tx_hash = self.send_transaction(
            utxo_address,
            "fairminter",
            {
                "asset": util.gen_random_asset_name(utxo_asset),
                "price": 1,
                "quantity_by_price": 5,
                "exact_fee": 0,
                "inputs_set": f"{tx_hash}:1",
                "use_utxos_with_balances": True,
            },
        )

        self.upsert_balance(utxo, utxo_asset, -utxo_quantity, utxo_address)
        self.upsert_balance(f"{tx_hash}:1", utxo_asset, utxo_quantity, utxo_address)
        self.upsert_balance(utxo_address, "XCP", -1300)
        self.upsert_balance(destination, "XCP", 100)
        self.upsert_balance(f"{tx_hash}:1", "XCP", 200, utxo_address)

    @settings(deadline=None)
    def detach_asset(self, balance, destination):
        source, asset, quantity, utxo_address = balance
        # don't detach assets not attached or with 0 quantity
        if utxo_address is None or quantity == 0:
            return
        if source in self.alrady_used:
            return
        self.alrady_used.append(source)

        self.send_transaction(
            source,
            "detach",
            {
                "exact_fee": 0,
                "destination": destination,
            },
        )
        for balance in self.balances:
            if balance[0] == source:
                asset, quantity = balance[1], balance[2]
                self.upsert_balance(source, asset, -quantity, utxo_address)
                self.upsert_balance(destination or utxo_address, asset, quantity, None)


if __name__ == "__main__":
    UTXOSupportPropertyTest()
