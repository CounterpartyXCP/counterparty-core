"""
Transaction 1: rps (Open the game)
source: address used to play the game
wager: amount to bet
move_random_hash: sha256(sha256(move + random)) (stored as bytes, 16 bytes random)
possible_moves: arbitrary odd number >= 3
expiration: how many blocks the game is valid

Matching conditions:
- tx0_possible_moves = tx1_possible_moves
- tx0_wager = tx1_wager

Transaction 2:  rpsresolve (Resolve the game)
source: same address as first transaction
random: 16 bytes random
move: the move number
rps_match_id: matching id
"""

import json
import logging
import os

from counterpartycore.lib import config, ledger
from counterpartycore.lib.parser import protocol

logger = logging.getLogger(config.LOGGER_NAME)

# possible_moves wager move_random_hash expiration
ID = 80

CURR_DIR = os.path.dirname(os.path.realpath(__file__))
with open(os.path.join(CURR_DIR, "data", "rps_events.json")) as f:
    RPS_EVENTS = json.load(f)


def replay_events(db, key):
    if protocol.is_test_network():
        return
    events = RPS_EVENTS.get(key)
    if events:
        ledger.events.replay_events(db, events)


def parse(db, tx, message):
    logger.debug(
        "Replay RPS events for transaction %(tx_hash)s",
        {
            "tx_hash": tx["tx_hash"],
        },
    )
    replay_events(db, tx["tx_hash"])


def expire(db, block_index):
    logger.trace(
        "Replay RPS events for block %(block_index)s",
        {
            "block_index": block_index if block_index != config.MEMPOOL_BLOCK_INDEX else "mempool",
        },
    )
    replay_events(db, str(block_index))
