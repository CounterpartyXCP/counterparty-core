#!/usr/bin/env python3

import json
import os
import sys
import time

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

    def api_call(self, url):
        return sh.curl(f"http://localhost:24000/v2/{url}").strip()

    def wait_for_bitcoind(self):
        while True:
            try:
                self.bitcoin_cli("getblockchaininfo")
                break
            except sh.ErrorReturnCode:
                print("Waiting for bitcoind to start...")
                time.sleep(1)

    def wait_for_counterparty_server(self):
        while True:
            try:
                result = self.api_call("")
                result = json.loads(result)
                if result and "result" in result and result["result"]["server_ready"]:
                    return
                print(
                    f"Server not ready: {result['result']['counterparty_height']} < {result['result']['backend_height']}"
                )
                raise ServerNotReady
            except (sh.ErrorReturnCode, ServerNotReady, json.JSONDecodeError) as e:
                if not isinstance(e, ServerNotReady):
                    print("Waiting for counterparty server to start...")
                time.sleep(1)

    def generate_addresses_with_btc(self):
        for _i in range(10):
            address = self.bitcoin_wallet("getnewaddress", "", "bech32").strip()
            print(f"Address: {address}")
            self.addresses.append(address)

        self.bitcoin_wallet("generatetoaddress", 101, address)

        for address in self.addresses:
            if address != self.addresses[0]:
                self.bitcoin_wallet("sendtoaddress", address, 1)
        self.bitcoin_wallet("generatetoaddress", 10, address)

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

        self.counterparty_server_process = sh.counterparty_server(
            "--regtest",
            f"--database-file={self.datadir}/counterparty.db",
            "-vv",
            "start",
            _bg=True,
            # _out=sys.stdout,
            # _err=sys.stdout,
        )

        self.wait_for_counterparty_server()

        self.counterparty_server_process.wait()

        # print(self.bitcoin_cli("listreceivedbyaddress"))

        self.bitcoin_cli("stop", _out=sys.stdout)
        self.counterparty_server_process.terminate()


node = RegtestNode()
node.start()
