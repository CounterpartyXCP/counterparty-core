#!/usr/bin/env python3

import time

import hypothesis
import sh
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

    @settings(max_examples=100, deadline=None)
    def issue_assets(self, source, asset_name, quantity):
        print("Issuing asset: ", asset_name, source)
        try:
            for issued_asset in self.issued_assets:
                if issued_asset[1] == asset_name:
                    return
            self.node.send_transaction(
                source,
                "issuance",
                {
                    "asset": asset_name,
                    "quantity": quantity,
                    "allow_unconfirmed_inputs": True,
                },
                no_confirmation=True,
                dont_wait_mempool=True,
            )
            self.issued_assets.append([source, asset_name, quantity])
        except (sh.ErrorReturnCode_26, ComposeError):
            pass

    def check_balance(self, balance):
        address, asset, quantity = balance
        address_balances = self.node.api_call(f"assets/{asset}/balances/{address}")["result"]
        for address_balance in address_balances:
            if address_balance["address"] == address and address_balance["quantity"] == quantity:
                print(f"Valid balance found for {address} {asset}")
                return
        raise Exception(f"Valid balance not found for {address} {asset}")


if __name__ == "__main__":
    RegtestNode()
