#!/usr/bin/env python3

import difflib
import json
import time

import sh

SERVER_1 = "https://dev.counterparty.io:4000/"
SERVER_2 = "http://localhost:4000/"

START_BLOCK = 872150


def compare_strings(string1, string2):
    """Compare strings diff-style."""
    diff = list(difflib.unified_diff(string1.splitlines(1), string2.splitlines(1), n=0))
    if len(diff):
        print("\nDifferences:")
        print("\n".join(diff))
    return len(diff)


def get_hashes(server, block_index):
    result = json.loads(sh.curl(f"{server}v2/blocks/{block_index}").strip())["result"]
    return result["ledger_hash"], result["txlist_hash"]


def get_events(server, block_index):
    result = json.loads(sh.curl(f"{server}v2/blocks/{block_index}/events").strip())["result"]
    return result


block_index = START_BLOCK
hashes_1 = get_hashes(SERVER_1, block_index)
hashes_2 = get_hashes(SERVER_2, block_index)
while hashes_1[0] != hashes_2[0]:
    print(f"Block {block_index} NOK")
    time.sleep(0.1)
    block_index -= 1
    hashes_1 = get_hashes(SERVER_1, block_index)
    hashes_2 = get_hashes(SERVER_2, block_index)

print(f"Block {block_index} OK")

block_index += 1
print(f"First bad block: {block_index}")
events_1 = get_events(SERVER_1, block_index)
events_2 = get_events(SERVER_2, block_index)

compare_strings(json.dumps(events_1, indent=4), json.dumps(events_2, indent=4))
