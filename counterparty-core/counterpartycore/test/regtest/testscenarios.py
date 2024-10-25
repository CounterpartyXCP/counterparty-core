#!/usr/bin/env python3

import difflib
import json
import os
import sys
import time

import sh
from regtestcli import atomic_swap
from regtestnode import ComposeError, RegtestNodeThread, print_server_output
from scenarios import (
    scenario_1_fairminter,
    scenario_2_fairminter,
    scenario_3_fairminter,
    scenario_4_broadcast,
    scenario_5_dispenser,
    scenario_6_dispenser,
    scenario_7_utxo,
    scenario_8_atomicswap,
    scenario_9_issuance,
    scenario_10_orders,
    scenario_11_btcpay,
    scenario_12_send,
    scenario_13_cancel,
    scenario_14_sweep,
    scenario_15_destroy,
    scenario_16_fairminter,
    scenario_17_dispenser,
    scenario_18_utxo,
    scenario_last_mempool,
)
from termcolor import colored

SCENARIOS = []
SCENARIOS += scenario_1_fairminter.SCENARIO
SCENARIOS += scenario_2_fairminter.SCENARIO
SCENARIOS += scenario_3_fairminter.SCENARIO
SCENARIOS += scenario_4_broadcast.SCENARIO
SCENARIOS += scenario_5_dispenser.SCENARIO
SCENARIOS += scenario_6_dispenser.SCENARIO
SCENARIOS += scenario_7_utxo.SCENARIO
SCENARIOS += scenario_16_fairminter.SCENARIO
SCENARIOS += scenario_8_atomicswap.SCENARIO
SCENARIOS += scenario_9_issuance.SCENARIO
SCENARIOS += scenario_10_orders.SCENARIO
SCENARIOS += scenario_11_btcpay.SCENARIO
SCENARIOS += scenario_12_send.SCENARIO
SCENARIOS += scenario_13_cancel.SCENARIO
SCENARIOS += scenario_14_sweep.SCENARIO
SCENARIOS += scenario_15_destroy.SCENARIO
SCENARIOS += scenario_17_dispenser.SCENARIO
SCENARIOS += scenario_18_utxo.SCENARIO
# more scenarios before this one
SCENARIOS += scenario_last_mempool.SCENARIO

CURR_DIR = os.path.dirname(os.path.realpath(__file__))
BASE_DIR = os.path.join(CURR_DIR, "../../../../")

SCENARIOS = scenario_18_utxo.SCENARIO


def compare_strings(string1, string2):
    """Compare strings diff-style."""
    diff = list(difflib.unified_diff(string1.splitlines(1), string2.splitlines(1), n=0))
    if len(diff):
        print("\nDifferences:")
        print("\n".join(diff))
    return len(diff)


def prepare_item(item, node, context):
    for i in reversed(range(11)):
        address = node.addresses[i]
        if "source" in item:
            item["source"] = item["source"].replace(f"$ADDRESS_{i+1}", address)
        for key in item["params"]:
            if isinstance(item["params"][key], str):
                item["params"][key] = item["params"][key].replace(f"$ADDRESS_{i+1}", address)
    for name, value in context.items():
        if "source" in item:
            item["source"] = item["source"].replace(f"${name}", value)
        for key in item["params"]:
            if isinstance(item["params"][key], str):
                item["params"][key] = item["params"][key].replace(f"${name}", value)
    return item


def control_result(item, node, context, block_hash, block_time, tx_hash, data, retry=0):
    block_index = node.block_count
    events = node.api_call(f"blocks/{block_index}/events")["result"]
    event_indexes = sorted([event["event_index"] for event in events])
    for control in item["controls"]:
        control_url = (
            control["url"].replace("$TX_HASH", tx_hash).replace("$BLOCK_INDEX", str(block_index))
        )
        for i in reversed(range(11)):
            address = node.addresses[i]
            control_url = control_url.replace(f"$ADDRESS_{i+1}", address)
        result = node.api_call(control_url)

        if (
            "result" in result
            and result["result"] == []
            and control.get("retry", False)
            and retry < 10
        ):
            time.sleep(2)
            return control_result(
                item, node, context, block_hash, block_time, tx_hash, data, retry=retry + 1
            )

        expected_result = control["result"]
        expected_result = (
            json.dumps(expected_result)
            .replace("$TX_HASH", tx_hash)
            .replace("$BLOCK_HASH", block_hash)
            .replace('"$BLOCK_INDEX"', str(block_index))
            .replace('"$TX_INDEX"', str(node.tx_index))
            .replace('"$BLOCK_TIME"', str(block_time))
        )
        if data:
            expected_result = expected_result.replace("$TX_DATA", data[16:])  # strip the prefix
        for i in reversed(range(len(event_indexes))):
            event_index = event_indexes[i]
            expected_result = expected_result.replace(f'"$EVENT_INDEX_{i + 1}"', str(event_index))
        for i in reversed(range(11)):
            address = node.addresses[i]
            expected_result = expected_result.replace(f"$ADDRESS_{i + 1}", address)
        for name, value in context.items():
            if name.endswith("_INDEX"):
                expected_result = expected_result.replace(f'"${name}"', value)
            else:
                expected_result = expected_result.replace(f"${name}", value)
        # print(f"Expected result: {expected_result}")
        expected_result = json.loads(expected_result)

        # don't compare decoded_tx because it's not deterministic
        if isinstance(expected_result, dict) and "decoded_tx" in expected_result:
            del expected_result["decoded_tx"]
            if "decoded_tx" not in result["result"]:
                raise AssertionError("decoded_tx not in result")
        if isinstance(result["result"], dict) and "decoded_tx" in result["result"]:
            del result["result"]["decoded_tx"]
        # don't compare timestamp because it's not deterministic
        if isinstance(expected_result, list):
            for event in expected_result:
                if "timestamp" in event:
                    del event["timestamp"]
        if isinstance(result["result"], list):
            for event in result["result"]:
                if "timestamp" in event:
                    del event["timestamp"]

        try:
            assert result["result"] == expected_result
            print(f"{item['title']}: " + colored("Success", "green"))
        except AssertionError:
            print(colored(f"Failed: {item['title']}", "red"))
            expected_result_str = json.dumps(expected_result, indent=4, sort_keys=True)
            got_result_str = json.dumps(result["result"], indent=4, sort_keys=True)
            print(f"Expected: {expected_result_str}")
            print(f"Got: {got_result_str}")
            compare_strings(expected_result_str, got_result_str)
            # raise e


def run_item(node, item, context):
    print(f"Running: {item['title']}")
    tx_data = None

    if "disable_protocol_changes" in item:
        node.disable_protocol_changes(item["disable_protocol_changes"])

    if item["transaction"] == "mine_blocks":
        block_hash, block_time = node.mine_blocks(item["params"]["blocks"])
        tx_hash = "null"
        node.wait_for_counterparty_server()
    else:
        item = prepare_item(item, node, context)
        try:
            no_confirmation = item.get("no_confirmation", False)
            if item["transaction"] == "atomic_swap":
                data = None
                if "counterparty_tx" in item["params"]:
                    counterparty_tx = prepare_item(item["params"]["counterparty_tx"], node, context)
                    data = node.send_transaction(
                        counterparty_tx["source"],
                        counterparty_tx["transaction"],
                        counterparty_tx["params"],
                        return_only_data=True,
                    )

                signed_transaction = atomic_swap(
                    item["params"]["seller"],
                    item["params"]["utxo"],
                    item["params"]["price"] / 1e8,
                    item["params"]["buyer"],
                    data,
                )
                tx_hash, block_hash, block_time = node.broadcast_transaction(signed_transaction)
            else:
                tx_hash, block_hash, block_time, tx_data = node.send_transaction(
                    item["source"],
                    item["transaction"],
                    item["params"],
                    no_confirmation=no_confirmation,
                )
            # test that the mempool is properly cleaned after each regtest transaction is confirmed
            if not no_confirmation:
                while True:
                    try:
                        mempool_events = node.api_call("mempool/events")["result"]
                        break
                    except KeyError:
                        print("Error getting mempool events, retrying...")
                        time.sleep(1)
                if len(mempool_events) != 0:
                    raise Exception(f"Mempool events not empty after transaction: {mempool_events}")
        except ComposeError as e:
            if "expected_error" in item:
                try:
                    assert (str(item["expected_error"]),) == e.args
                    print(f"{item['title']}: " + colored("Success", "green"))
                except AssertionError:
                    print(colored(f"Failed: {item['title']}", "red"))
                    print(f"Expected: {item['expected_error']}")
                    print(f"Got: {str(e)}")
                    # raise e
            else:
                raise e

    node.enable_all_protocol_changes()

    for name, value in item.get("set_variables", {}).items():
        context[name] = (
            value.replace("$TX_HASH", tx_hash)
            .replace("$BLOCK_HASH", block_hash)
            .replace("$TX_INDEX", str(node.tx_index))
            .replace("$BLOCK_INDEX + 20", str(node.block_count + 20))
            .replace("$BLOCK_INDEX + 21", str(node.block_count + 21))  # TODO: make it more generic
            .replace("$BLOCK_INDEX", str(node.block_count))
        )

    if "controls" in item:
        control_result(item, node, context, block_hash, block_time, tx_hash, tx_data)

    return context


def rpc_call(command, params=None):
    if params is None:
        params = []
    curl_client = sh.curl.bake(
        "-X",
        "POST",
        "http://localhost:24000/v1/",
        "-H",
        "Content-Type: application/json; charset=UTF-8",
        "-H",
        "Accept: application/json, text/javascript",
        "--data-binary",
    )
    query = {
        "method": command,
        "params": params,
        "jsonrpc": "2.0",
        "id": 0,
    }
    result = json.loads(curl_client(json.dumps(query)).strip())
    return result


def check_api_v1(node):
    running_info = rpc_call("get_running_info")

    if not running_info["result"]["server_ready"]:
        raise Exception("Server not ready")
    if not running_info["result"]["db_caught_up"]:
        raise Exception("DB not caught up")

    tx = rpc_call(
        "create_send",
        {
            "source": node.addresses[0],
            "destination": node.addresses[1],
            "asset": "XCP",
            "quantity": 1,
        },
    )
    # check that the hex transaction is generated
    int(tx["result"], 16)


def run_scenarios(serve=False, wsgi_server="gunicorn"):
    try:
        regtest_node_thread = RegtestNodeThread(wsgi_server=wsgi_server)
        regtest_node_thread.start()

        while not regtest_node_thread.ready():
            time.sleep(1)

        context = {}

        check_api_v1(regtest_node_thread.node)

        # run all scenarios
        for item in SCENARIOS:
            context = run_item(regtest_node_thread.node, item, context)

        if serve:
            printed_line_count = 0
            print("Server ready, ctrl-c to stop.")
            while True:
                printed_line_count = print_server_output(
                    regtest_node_thread.node, printed_line_count
                )
                time.sleep(1)
        else:
            if os.path.exists(os.path.join(CURR_DIR, "apidoc/apicache.json")):
                os.unlink(os.path.join(CURR_DIR, "apidoc/apicache.json"))
            print("Generating API documentation...")
            sh.python3(
                os.path.join(CURR_DIR, "genapidoc.py"),
                os.path.abspath("regtestnode"),
                _out=sys.stdout,
                _err_to_out=True,
                _cwd=CURR_DIR,
            )
            print("Running Dredd...")
            sh.dredd(_cwd=BASE_DIR, _out=sys.stdout, _err_to_out=True)
            print("Tesing reparse...")
            regtest_node_thread.node.reparse()
            print("Testing rollback...")
            regtest_node_thread.node.rollback()
            print("Testing reorg...")
            regtest_node_thread.node.test_reorg()
    except KeyboardInterrupt:
        pass
    except Exception as e:
        print(regtest_node_thread.node.server_out.getvalue())
        raise e
    finally:
        print(regtest_node_thread.node.server_out.getvalue())
        regtest_node_thread.stop()


if __name__ == "__main__":
    serve = False
    wsgi_server = "waitress"
    for arg in sys.argv[1:]:
        if arg == "serve":
            serve = True
        if arg in ["gunicorn", "waitress", "werkzeug"]:
            wsgi_server = arg
    run_scenarios(serve=serve, wsgi_server=wsgi_server)
