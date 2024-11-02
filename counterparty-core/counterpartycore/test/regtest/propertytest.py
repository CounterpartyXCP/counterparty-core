#!/usr/bin/env python3

import time

import hypothesis
import sh
from counterpartycore.lib import util
from hypothesis import given, settings
from regtestnode import ComposeError, RegtestNodeThread


class RegtestNode:
    def __init__(self):
        try:
            regtest_node_thread = RegtestNodeThread()
            regtest_node_thread.start()
            while not regtest_node_thread.ready():
                time.sleep(1)
            self.node = regtest_node_thread.node

            self.run_test()
        except KeyboardInterrupt:
            pass
        except Exception as e:
            print(regtest_node_thread.node.server_out.getvalue())
            raise e
        finally:
            # print(regtest_node_thread.node.server_out.getvalue())
            regtest_node_thread.stop()

    def run_test(self):
        # issue random assets
        self.issued_assets = []
        given(
            hypothesis.strategies.sampled_from(self.node.addresses),
            hypothesis.strategies.text(
                alphabet="BCDEFGHIJKLMNOPQRSTUVWXYZ", min_size=5, max_size=10
            ),
            hypothesis.strategies.integers(min_value=10 * 10e8, max_value=1000 * 10e8),
        )(self.issue_assets)()

        # mine block
        self.node.mine_blocks(1)
        self.node.wait_for_counterparty_server()

        # check balances
        given(hypothesis.strategies.sampled_from(self.issued_assets))(self.check_balance)()

        # attach assets
        self.attached_assets = []
        given(
            hypothesis.strategies.sampled_from(self.issued_assets),
            hypothesis.strategies.integers(min_value=1 * 10e8, max_value=10 * 10e8),
        )(self.attach_asset)()

        # mine block
        self.node.mine_blocks(1)
        self.node.wait_for_counterparty_server()

        # check balances
        given(hypothesis.strategies.sampled_from(self.attached_assets))(self.check_balance)()

        # move assets
        self.moved_assets = []
        self.moved_utxo_list = []
        given(
            hypothesis.strategies.sampled_from(self.attached_assets),
            hypothesis.strategies.sampled_from(self.node.addresses),
        )(self.move_asset)()

        # mine block
        self.node.mine_blocks(1)
        self.node.wait_for_counterparty_server()

        # check balances
        given(hypothesis.strategies.sampled_from(self.moved_assets))(self.check_balance)()

    def check_balance(self, balance):
        address_or_utxo, asset, quantity, utxo_address = balance
        if util.is_utxo_format(address_or_utxo):
            balances = self.node.api_call(f"utxos/{address_or_utxo}/balances")["result"]
            field_name = "utxo"
        else:
            balances = self.node.api_call(f"addresses/{address_or_utxo}/balances")["result"]
            field_name = "address"

        for balance_item in balances:
            if (
                balance_item[field_name] == address_or_utxo
                and balance_item["quantity"] == quantity
                and balance_item["asset"] == asset
                and balance_item["utxo_address"] == utxo_address
            ):
                print(f"Valid balance found for {address_or_utxo} {asset}")
                return
        raise Exception(f"Valid balance not found for {address_or_utxo} {asset}")

    @settings(deadline=None)
    def issue_assets(self, source, asset_name, quantity):
        try:
            for issued_asset in self.issued_assets:
                if issued_asset[1] == asset_name or issued_asset[0] == source:
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
            self.issued_assets.append([source, asset_name, quantity, None])
        except (sh.ErrorReturnCode_26, ComposeError):
            pass

    @settings(deadline=None)
    def attach_asset(self, balance, attach_quantity):
        address, asset, quantity, utxo_address = balance
        for attached_asset in self.attached_assets:
            if attached_asset[1] == asset:
                return
        tx_hash, block_hash, block_time, data = self.node.send_transaction(
            address,
            "attach",
            {
                "asset": asset,
                "quantity": attach_quantity,
                "exact_fee": 0,
            },
            no_confirmation=True,
            dont_wait_mempool=True,
        )
        self.attached_assets.append([f"{tx_hash}:0", asset, attach_quantity, address])

    def move_asset(self, balance, destination):
        source, asset, quantity, utxo_address = balance
        if source == destination or source in self.moved_utxo_list:
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
        self.moved_utxo_list.append(source)
        self.moved_assets.append([f"{tx_hash}:0", asset, quantity, destination])


if __name__ == "__main__":
    RegtestNode()
