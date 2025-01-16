#!/usr/bin/env python3
import decimal
import math

import hypothesis
from counterpartycore.lib import config
from counterpartycore.lib.utils import assetnames
from hypothesis import settings
from properytestnode import PropertyTestNode
from regtestnode import ComposeError

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


def D(value):
    return decimal.Decimal(str(value))


class UTXOSupportPropertyTest(PropertyTestNode):
    def run_tests(self):
        # issue random assets
        self.asset_owners = {}
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
        self.already_used = []
        self.test_with_given_data(
            self.move_with_counterparty_data,
            hypothesis.strategies.sampled_from(self.get_utxos_balances()),
            hypothesis.strategies.sampled_from(self.addresses),
        )

        # detach assets
        self.already_used = []
        self.test_with_given_data(
            self.detach_asset,
            hypothesis.strategies.sampled_from(self.balances),
            hypothesis.strategies.sampled_from(self.addresses + [None]),
        )

        # create fairminter
        self.fairminters = {}
        self.test_with_given_data(
            self.create_fairminter,
            hypothesis.strategies.sampled_from(self.addresses),
            hypothesis.strategies.integers(min_value=1, max_value=1000 * 1e8),  # price
            hypothesis.strategies.integers(min_value=1, max_value=10),  # quantity_by_price
            hypothesis.strategies.booleans(),  # soft_caped
            hypothesis.strategies.booleans(),  # with_commission
            hypothesis.strategies.integers(min_value=1, max_value=10),  # commission
        )

        # create fairmints
        self.fairminted = []
        self.minters = []
        self.test_with_given_data(
            self.create_fairmints,
            hypothesis.strategies.sampled_from(self.balances),
            hypothesis.strategies.sampled_from(list(self.fairminters.keys())),
            hypothesis.strategies.integers(min_value=1, max_value=1000 * 1e8),  # quantity
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
        self.asset_owners[source] = asset_name

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
                "inputs_source": utxo_address,
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

        if utxo in self.already_used or utxo_quantity == 0 or utxo_asset == "XCP":
            return
        self.already_used.append(utxo)

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
                "asset": assetnames.gen_random_asset_name(utxo_asset),
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
        if source in self.already_used:
            return
        self.already_used.append(source)

        self.send_transaction(
            source,
            "detach",
            {
                "exact_fee": 0,
                "destination": destination,
                "inputs_source": utxo_address,
                "exclude_utxos_with_balances": True,
            },
        )
        for balance in self.balances:
            if balance[0] == source:
                asset, quantity = balance[1], balance[2]
                self.upsert_balance(source, asset, -quantity, utxo_address)
                self.upsert_balance(destination or utxo_address, asset, quantity, None)

    @settings(deadline=None)
    def create_fairminter(
        self, source, price, quantity_by_price, soft_caped, with_commission, commission
    ):
        if source in self.fairminters:
            return
        minted_asset_commission = commission / 100 if with_commission else 0.0
        self.send_transaction(
            source,
            "fairminter",
            {
                "asset": self.asset_owners[source],
                "price": price,
                "quantity_by_price": quantity_by_price,
                "soft_cap": int(100 * 1e8) if soft_caped else 0,
                "soft_cap_deadline_block": 1000 if soft_caped else 0,
                "minted_asset_commission": minted_asset_commission,
            },
        )
        self.fairminters[source] = (price, quantity_by_price, soft_caped, minted_asset_commission)

    @settings(deadline=None)
    def create_fairmints(self, balance_source, fairminter_source, quantity):
        source, asset, balance, utxo_address = balance_source
        if (
            asset != "XCP"
            or utxo_address is not None
            or source == fairminter_source
            or source in self.minters
        ):
            return
        if fairminter_source not in self.fairminters:
            return
        if fairminter_source in self.fairminted:
            return

        price, quantity_by_price, soft_caped, minted_asset_commission = self.fairminters[
            fairminter_source
        ]

        total_price = (D(quantity) / D(quantity_by_price)) * D(price)
        total_price = int(math.ceil(total_price))
        earn_quantity = quantity
        commission = 0
        if minted_asset_commission > 0:
            commission = int(D(minted_asset_commission) * D(earn_quantity))
            earn_quantity -= commission

        fairminer_asset = self.asset_owners[fairminter_source]

        if total_price > balance:
            error_raised = False
            try:
                self.send_transaction(
                    source,
                    "fairmint",
                    {
                        "asset": fairminer_asset,
                        "quantity": quantity,
                    },
                )
            except ComposeError as e:
                assert str(e) == "['insufficient XCP balance']"
                error_raised = True
            assert error_raised
        else:
            self.send_transaction(
                source,
                "fairmint",
                {
                    "asset": fairminer_asset,
                    "quantity": quantity,
                },
            )
            print(f"Fairminted {quantity} {fairminer_asset} for {total_price} XCP")
            self.upsert_balance(source, "XCP", -total_price)
            if soft_caped:
                self.upsert_balance(config.UNSPENDABLE_REGTEST, "XCP", total_price)
                self.upsert_balance(
                    config.UNSPENDABLE_REGTEST, fairminer_asset, earn_quantity + commission
                )
            else:
                self.upsert_balance(fairminter_source, "XCP", total_price)
                self.upsert_balance(source, fairminer_asset, earn_quantity)
                if commission > 0:
                    self.upsert_balance(fairminter_source, fairminer_asset, commission)
            self.fairminted.append(fairminter_source)
            self.minters.append(source)


if __name__ == "__main__":
    UTXOSupportPropertyTest()
