#!/usr/bin/env python3

import json
import os
import sys
import time
import urllib.parse
from io import StringIO

import sh

WALLET_NAME = "xcpwallet"


class ServerNotReady(Exception):
    pass


class RegtestNode:
    def __init__(self, datadir="regtestnode"):
        self.datadir = datadir
        self.bitcoin_cli = sh.bitcoin_cli.bake(
            "-regtest",
            "-rpcuser=rpc",
            "-rpcpassword=rpc",
            "-rpcconnect=localhost",
            f"-datadir={self.datadir}",
        )
        self.bitcoin_wallet = self.bitcoin_cli.bake(f"-rpcwallet={WALLET_NAME}")
        self.bitcoind_process = None
        self.addresses = []
        self.block_count = 0

    def api_call(self, url):
        return json.loads(sh.curl(f"http://localhost:24000/v2/{url}").strip())

    def wait_for_bitcoind(self):
        while True:
            try:
                self.bitcoin_cli("getblockchaininfo")
                break
            except sh.ErrorReturnCode:
                print("Waiting for bitcoind to start...")
                time.sleep(1)

    def send_transaction(self, source, tx_name, params):
        self.wait_for_counterparty_server()
        query_string = urllib.parse.urlencode(params)
        compose_url = f"addresses/{source}/compose/{tx_name}?{query_string}"
        result = self.api_call(compose_url)
        raw_transaction = result["result"]["rawtransaction"]
        signed_transaction_json = self.bitcoin_wallet(
            "signrawtransactionwithwallet", raw_transaction
        ).strip()
        signed_transaction = json.loads(signed_transaction_json)["hex"]
        self.bitcoin_wallet("sendrawtransaction", signed_transaction)
        self.mine_blocks(1)
        self.wait_for_counterparty_server()
        print(f"Transaction sent: {tx_name} {params}")

    def wait_for_counterparty_server(self, block=None):
        while True:
            try:
                result = self.api_call("")
                if result and "result" in result and result["result"]["server_ready"]:
                    current_block = result["result"]["counterparty_height"]
                    target_block = block or self.block_count
                    if current_block < target_block:
                        print(f"Waiting for block {current_block} < {target_block}")
                        raise ServerNotReady
                    else:
                        print("Server ready")
                        return
                elif result and "result" in result:
                    print(
                        f"Server not ready: {result['result']['counterparty_height']} < {result['result']['backend_height']}"
                    )
                    raise ServerNotReady
                raise json.JSONDecodeError("Invalid response", "", 0)
            except (sh.ErrorReturnCode, ServerNotReady, json.JSONDecodeError) as e:
                if not isinstance(e, ServerNotReady):
                    print("Waiting for counterparty server to start...")
                time.sleep(1)

    def wait_for_counterparty_follower(self, server_output):
        while True:
            if "Starting blockchain watcher..." in server_output.getvalue():
                print("Server ready")
                return
            print("Waiting for counterparty server to start...")
            time.sleep(2)

    def mine_blocks(self, blocks=1, address=None):
        reward_address = address or self.addresses[0]
        self.bitcoin_wallet("generatetoaddress", blocks, reward_address)
        self.block_count += blocks

    def generate_addresses_with_btc(self):
        for i in range(10):
            address = self.bitcoin_wallet("getnewaddress", "", "bech32").strip()
            print(f"Address {i}: {address}")
            self.addresses.append(address)
            self.mine_blocks(1, address)
        self.mine_blocks(101)

    def generate_xcp(self):
        print("Generating XCP...")
        for address in self.addresses:
            self.send_transaction(address, "burn", {"quantity": 50000000})

    def start(self):
        if os.path.exists(self.datadir):
            sh.rm("-rf", self.datadir)
        sh.mkdir(self.datadir)

        self.bitcoind_process = sh.bitcoind(
            "-regtest",
            "-daemon",
            "-server",
            "-txindex",
            "-rpcuser=rpc",
            "-rpcpassword=rpc",
            "-rpcallowip=0.0.0.0",
            "-zmqpubrawtx=tcp://0.0.0.0:29332",
            "-zmqpubhashtx=tcp://0.0.0.0:29332",
            "-zmqpubsequence=tcp://0.0.0.0:29332",
            "-zmqpubrawblock=tcp://0.0.0.0:29333",
            "-fallbackfee=0.0002",
            f"-datadir={self.datadir}",
            _bg=True,
            _out=sys.stdout,
        )

        self.wait_for_bitcoind()

        self.bitcoin_cli(
            "createwallet",
            WALLET_NAME,
        )
        print("Wallet created")

        self.generate_addresses_with_btc()

        # print(self.bitcoin_cli("listreceivedbyaddress"))

        self.addrindexrs_process = sh.addrindexrs(
            "--network=regtest",
            "-vvvv",
            "--cookie=rpc:rpc",
            f"--db-dir={self.datadir}",
            f"--daemon-dir={self.datadir}",
            "--daemon-rpc-port=18443",
            _bg=True,
            # _out=sys.stdout,
            # _err=sys.stdout,
        )

        buf = StringIO()
        self.counterparty_server_process = sh.counterparty_server(
            "--regtest",
            f"--database-file={self.datadir}/counterparty.db",
            "-vv",
            "start",
            _bg=True,
            _out=buf,
            _err_to_out=True,
        )
        self.wait_for_counterparty_follower(buf)

        self.generate_xcp()

        balances = self.api_call("assets/XCP/balances")["result"]
        for balance in balances:
            print(f"{balance['address']}: {balance['quantity'] / 1e8} XCP")

        print("Regtest node ready")

        self.counterparty_server_process.wait()

    def stop(self):
        print("Stopping...")
        try:
            self.bitcoin_cli("stop", _out=sys.stdout)
        except sh.ErrorReturnCode:
            pass
        try:
            self.addrindexrs_process.terminate()  # noqa
        except Exception as e:
            print(e)
            pass
        try:
            self.counterparty_server_process.terminate()  # noqa
        except Exception as e:
            print(e)
            pass


try:
    node = RegtestNode()
    node.start()
except KeyboardInterrupt:
    pass
finally:
    node.stop()
