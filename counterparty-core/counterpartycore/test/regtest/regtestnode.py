#!/usr/bin/env python3

import json
import os
import sys
import threading
import time
import urllib.parse
from io import StringIO

import sh

WALLET_NAME = "xcpwallet"


class ServerNotReady(Exception):
    pass


class ComposeError(Exception):
    pass


class RegtestNode:
    def __init__(self, datadir="regtestnode", show_output=False):
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
        self.tx_index = -1
        self.ready = False
        self.show_output = show_output

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

    def disable_protocol_changes(self, change_names):
        regtest_protocole_file = os.path.join(self.datadir, "regtest_disabled_changes.json")
        with open(regtest_protocole_file, "w") as f:
            f.write(json.dumps(change_names))

    def enable_all_protocol_changes(self):
        regtest_protocole_file = os.path.join(self.datadir, "regtest_disabled_changes.json")
        if os.path.exists(regtest_protocole_file):
            os.remove(regtest_protocole_file)

    def broadcast_transaction(self, signed_transaction, no_confirmation=False, retry=0):
        tx_hash = self.bitcoin_wallet("sendrawtransaction", signed_transaction, 0).strip()
        if not no_confirmation:
            block_hash, block_time = self.mine_blocks(1)
        else:
            block_hash, block_time = "mempool", 9999999
            time.sleep(5)
        self.tx_index += 1
        self.wait_for_counterparty_server()
        return tx_hash, block_hash, block_time

    def send_transaction(
        self, source, tx_name, params, return_only_data=False, no_confirmation=False, retry=0
    ):
        self.wait_for_counterparty_server()
        if return_only_data:
            params["return_only_data"] = True
        params["exact_fee"] = 10000  # fixed fee
        query_string = urllib.parse.urlencode(params)
        if tx_name in ["detach", "movetoutxo"]:
            compose_url = f"utxos/{source}/compose/{tx_name}?{query_string}"
        else:
            compose_url = f"addresses/{source}/compose/{tx_name}?{query_string}"
        result = self.api_call(compose_url)
        # print(result)
        if "error" in result:
            if result["error"] == "Counterparty not ready":
                print("Counterparty not ready")
                print("Sleeping for 5 seconds and retrying...")
                time.sleep(5)
                return self.send_transaction(
                    source, tx_name, params, return_only_data, no_confirmation
                )
            raise ComposeError(result["error"])
        if return_only_data:
            return result["result"]["data"]
        raw_transaction = result["result"]["rawtransaction"]
        signed_transaction_json = self.bitcoin_wallet(
            "signrawtransactionwithwallet", raw_transaction
        ).strip()
        signed_transaction = json.loads(signed_transaction_json)["hex"]
        try:
            tx_hash, block_hash, block_time = self.broadcast_transaction(
                signed_transaction, no_confirmation
            )
        except sh.ErrorReturnCode_25 as e:
            if retry < 6:
                print("Error: bad-txns-inputs-missingorspent")
                print("Sleeping for 5 seconds and retrying...")
                time.sleep(10)
                return self.send_transaction(
                    source, tx_name, params, return_only_data, no_confirmation, retry + 1
                )
            else:
                raise e
        print(f"Transaction sent: {tx_name} {params} ({tx_hash})")
        return tx_hash, block_hash, block_time, result["result"]["data"]

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
                    print("Waiting for counterparty...")
                time.sleep(1)

    def wait_for_counterparty_follower(self):
        while True:
            if "Starting blockchain watcher..." in self.server_out.getvalue():
                print("Server ready")
                return
            print("Waiting for counterparty server...")
            time.sleep(2)

    def mine_blocks(self, blocks=1, address=None):
        reward_address = address or self.addresses[0]
        block_hashes_json = self.bitcoin_wallet("generatetoaddress", blocks, reward_address)
        block_hashes = json.loads(block_hashes_json)
        block_hash = block_hashes.pop()
        block_info_json = self.bitcoin_cli("getblock", block_hash, 1)
        block_time = json.loads(block_info_json)["time"]
        self.block_count += blocks
        return block_hash, block_time

    def generate_addresses_with_btc(self):
        for i in range(10):
            address = self.bitcoin_wallet("getnewaddress", WALLET_NAME, "bech32").strip()
            print(f"Address {i}: {address}")
            self.addresses.append(address)
            self.mine_blocks(1, address)
        self.addresses.sort()
        empty_address = self.bitcoin_wallet("getnewaddress", WALLET_NAME, "legacy").strip()
        self.addresses.append(empty_address)
        print(f"Empty address: {empty_address}")
        self.mine_blocks(101)

    def generate_xcp(self):
        print("Generating XCP...")
        for address in self.addresses[0:10]:
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
            "--jsonrpc-import",
            _bg=True,
            # _out=sys.stdout,
            # _err=sys.stdout,
        )

        self.server_out = StringIO()
        self.counterparty_server_process = sh.counterparty_server(
            "--regtest",
            f"--database-file={self.datadir}/counterparty.db",
            "-vv",
            "start",
            _bg=True,
            _out=self.server_out,
            _err_to_out=True,
        )
        self.wait_for_counterparty_follower()

        self.generate_xcp()

        balances = self.api_call("assets/XCP/balances")["result"]
        for balance in balances:
            print(f"{balance['address']}: {balance['quantity'] / 1e8} XCP")

        print("Regtest node ready")
        self.ready = True

        if self.show_output:
            printed_line_count = 0
            print("Server ready, ctrl-c to stop.")
            while True:
                printed_line_count = print_server_output(self, printed_line_count)
                time.sleep(1)

        while True:
            time.sleep(1)

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

    def get_node_state(self):
        return {
            "last_block": self.api_call("blocks/last")["result"],
            "last_event": self.api_call("events?limit=1")["result"],
        }

    def check_node_state(self, previous_state):
        self.server_out = StringIO()
        self.counterparty_server_process = sh.counterparty_server(
            "--regtest",
            f"--database-file={self.datadir}/counterparty.db",
            "-vv",
            "start",
            _bg=True,
            _out=self.server_out,
            _err_to_out=True,
        )
        self.wait_for_counterparty_follower()
        time.sleep(2)
        state = self.get_node_state()
        if state["last_block"] != previous_state["last_block"]:
            raise Exception("Reparse failed, last block is different")
        if state["last_event"] != previous_state["last_event"]:
            raise Exception("Reparse failed, last event is different")

    def test_command(self, command):
        state_before = self.get_node_state()
        self.counterparty_server_process.terminate()  # noqa
        self.counterparty_server_process.wait()
        print(f"Running `{command}`...")
        sh.counterparty_server(
            "--regtest",
            f"--database-file={self.datadir}/counterparty.db",
            "-vv",
            command,
            0,
            _out=sys.stdout,
            _err_to_out=True,
        )
        self.check_node_state(state_before)
        print(f"`{command}` successful")

    def reparse(self):
        self.test_command("reparse")

    def rollback(self):
        self.test_command("rollback")


class RegtestNodeThread(threading.Thread):
    def __init__(self):
        threading.Thread.__init__(self)
        self.daemon = True
        self.node = None

    def run(self):
        self.node = RegtestNode()
        self.node.start()

    def stop(self):
        if self.node:
            self.node.stop()

    def ready(self):
        if self.node:
            return self.node.ready
        return False


def print_server_output(node, printed_line_count):
    unprinted_lines = node.server_out.getvalue().splitlines()[printed_line_count:]
    for line in unprinted_lines:
        print(line)
        printed_line_count += 1
    return printed_line_count


if __name__ == "__main__":
    try:
        node = RegtestNode(show_output=True)
        node.start()
    except KeyboardInterrupt:
        pass
    finally:
        node.stop()
