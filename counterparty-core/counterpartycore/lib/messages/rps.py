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

from counterpartycore.lib import (  # noqa: F401
    config,
    database,
    ledger,
    log,
    util,
)

logger = logging.getLogger(config.LOGGER_NAME)

# possible_moves wager move_random_hash expiration
ID = 80

CURR_DIR = os.path.dirname(os.path.realpath(__file__))
with open(os.path.join(CURR_DIR, "data", "rps_events.json")) as f:
    RPS_EVENTS = json.load(f)


def initialise(db):
    cursor = db.cursor()

    # remove misnamed indexes
    database.drop_indexes(
        cursor,
        [
            "source_idx",
            "matching_idx",
            "status_idx",
            "rps_match_expire_idx",
            "rps_tx0_address_idx",
            "rps_tx1_address_idx",
            "block_index_idx",
            "tx0_address_idx",
            "tx1_address_idx",
        ],
    )

    # RPS (Rock-Paper-Scissors)
    create_rps_query = """CREATE TABLE IF NOT EXISTS rps(
                        tx_index INTEGER,
                        tx_hash TEXT,
                        block_index INTEGER,
                        source TEXT,
                        possible_moves INTEGER,
                        wager INTEGER,
                        move_random_hash TEXT,
                        expiration INTEGER,
                        expire_index INTEGER,
                        status TEXT)
                        """
    # create table
    cursor.execute(create_rps_query)
    # migrate old table
    if database.field_is_pk(cursor, "rps", "tx_index"):
        database.copy_old_table(cursor, "rps", create_rps_query)
    # create indexes
    database.create_indexes(
        cursor,
        "rps",
        [
            ["source"],
            ["wager", "possible_moves"],
            ["status"],
            ["tx_index"],
            ["tx_hash"],
            ["expire_index"],
            ["tx_index", "tx_hash"],
        ],
    )

    # RPS Matches
    create_rps_matches_query = """CREATE TABLE IF NOT EXISTS rps_matches(
                                id TEXT,
                                tx0_index INTEGER,
                                tx0_hash TEXT,
                                tx0_address TEXT,
                                tx1_index INTEGER,
                                tx1_hash TEXT,
                                tx1_address TEXT,
                                tx0_move_random_hash TEXT,
                                tx1_move_random_hash TEXT,
                                wager INTEGER,
                                possible_moves INTEGER,
                                tx0_block_index INTEGER,
                                tx1_block_index INTEGER,
                                block_index INTEGER,
                                tx0_expiration INTEGER,
                                tx1_expiration INTEGER,
                                match_expire_index INTEGER,
                                status TEXT)
                                """
    # create table
    cursor.execute(create_rps_matches_query)
    # migrate old table
    if database.field_is_pk(cursor, "rps_matches", "id"):
        database.copy_old_table(cursor, "rps_matches", create_rps_matches_query)
    # create indexes
    database.create_indexes(
        cursor,
        "rps_matches",
        [
            ["tx0_address"],
            ["tx1_address"],
            ["status"],
            ["id"],
            ["match_expire_index"],
        ],
    )

    # RPS Expirations
    create_rps_expirations_query = """CREATE TABLE IF NOT EXISTS rps_expirations(
                                    rps_index INTEGER PRIMARY KEY,
                                    rps_hash TEXT UNIQUE,
                                    source TEXT,
                                    block_index INTEGER,
                                    FOREIGN KEY (block_index) REFERENCES blocks(block_index))
                                    """
    # create table
    cursor.execute(create_rps_expirations_query)
    # migrate old table
    if database.has_fk_on(cursor, "rps_expirations", "rps.tx_index"):
        database.copy_old_table(cursor, "rps_expirations", create_rps_expirations_query)
    # create indexes
    database.create_indexes(
        cursor,
        "rps_expirations",
        [
            ["block_index"],
            ["source"],
        ],
    )

    # RPS Match Expirations
    create_rps_match_expirations_query = """CREATE TABLE IF NOT EXISTS rps_match_expirations(
                                            rps_match_id TEXT PRIMARY KEY,
                                            tx0_address TEXT,
                                            tx1_address TEXT,
                                            block_index INTEGER,
                                            FOREIGN KEY (block_index) REFERENCES blocks(block_index))
                                            """
    # create table
    cursor.execute(create_rps_match_expirations_query)
    # migrate old table
    if database.has_fk_on(cursor, "rps_match_expirations", "rps_matches.id"):
        database.copy_old_table(cursor, "rps_match_expirations", create_rps_match_expirations_query)
    # create indexes
    database.create_indexes(
        cursor,
        "rps_match_expirations",
        [
            ["block_index"],
            ["tx0_address"],
            ["tx1_address"],
        ],
    )


def replay_events(db, key):
    if util.is_test_network():
        return
    events = RPS_EVENTS.get(key)
    if events:
        ledger.replay_events(db, events)


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
