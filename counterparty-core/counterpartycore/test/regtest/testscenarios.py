#!/usr/bin/env python3

import difflib
import json
import time

from regtestnode import RegtestNodeThread
from scenarios import fairminter
from termcolor import colored

SCENARIOS = []
SCENARIOS += fairminter.SCENARIO


def compare_strings(string1, string2):
    """Compare strings diff-style."""
    diff = list(difflib.unified_diff(string1.splitlines(1), string2.splitlines(1), n=0))
    if len(diff):
        print("\nDifferences:")
        print("\n".join(diff))
    return len(diff)


def run_item(node, item):
    print(f"Running: {item['title']}")
    for i, address in enumerate(node.addresses):
        item["source"] = item["source"].replace(f"$ADDRESS_{i+1}", address)
    tx_hash, block_hash, block_time = node.send_transaction(
        item["source"], item["transaction"], item["params"]
    )
    for control in item["controls"]:
        control_url = control["url"].replace("$TX_HASH", tx_hash)
        for i, address in enumerate(node.addresses):
            control_url = control_url.replace(f"$ADDRESS_{i+1}", address)
        result = node.api_call(control_url)
        try:
            expected_result = control["result"]
            expected_result = (
                json.dumps(expected_result)
                .replace("$TX_HASH", tx_hash)
                .replace("$BLOCK_HASH", block_hash)
                .replace('"$BLOCK_TIME"', str(block_time))
            )
            for i, address in enumerate(node.addresses):
                expected_result = expected_result.replace(f"$ADDRESS_{i+1}", address)
            expected_result = json.loads(expected_result)

            assert result["result"] == expected_result

            print(f"{item['title']}: " + colored("Success", "green"))
        except AssertionError as e:
            print(f"Failed: {item['title']}")
            expected_result_str = json.dumps(expected_result, indent=4, sort_keys=True)
            got_result_str = json.dumps(result["result"], indent=4, sort_keys=True)
            print(f"Expected: {expected_result_str}")
            print(f"Got: {got_result_str}")
            compare_strings(expected_result_str, got_result_str)
            raise e


def run_scenarios():
    try:
        regtest_node_thread = RegtestNodeThread()
        regtest_node_thread.start()

        while not regtest_node_thread.ready():
            time.sleep(1)

        for item in SCENARIOS:
            run_item(regtest_node_thread.node, item)
    except KeyboardInterrupt:
        pass
    except Exception as e:
        print(regtest_node_thread.node.server_out.getvalue())
        raise e
    finally:
        regtest_node_thread.stop()


if __name__ == "__main__":
    run_scenarios()
