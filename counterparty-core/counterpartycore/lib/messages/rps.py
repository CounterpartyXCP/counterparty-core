#! /usr/bin/python3

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

import binascii
import decimal
import logging
import string
import struct

from counterpartycore.lib import (  # noqa: F401
    config,
    database,
    exceptions,
    ledger,
    message_type,
    util,
)

logger = logging.getLogger(config.LOGGER_NAME)
D = decimal.Decimal

# possible_moves wager move_random_hash expiration
FORMAT = ">HQ32sI"
LENGTH = 2 + 8 + 32 + 4
ID = 80


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


def cancel_rps(db, rps, status, block_index, tx_index):
    # Update status of rps.
    ledger.update_rps_status(db, rps["tx_hash"], status)
    # Refund quantity wagered.
    ledger.credit(
        db,
        rps["source"],
        "XCP",
        rps["wager"],
        tx_index,
        action="recredit wager",
        event=rps["tx_hash"],
    )


def update_rps_match_status(db, rps_match, status, block_index, tx_index):
    if status in ["expired", "concluded: tie"]:
        # Recredit tx0 address.
        ledger.credit(
            db,
            rps_match["tx0_address"],
            "XCP",
            rps_match["wager"],
            tx_index,
            action="recredit wager",
            event=rps_match["id"],
        )
        # Recredit tx1 address.
        ledger.credit(
            db,
            rps_match["tx1_address"],
            "XCP",
            rps_match["wager"],
            tx_index,
            action="recredit wager",
            event=rps_match["id"],
        )
    elif status.startswith("concluded"):
        # Credit the winner
        winner = (
            rps_match["tx0_address"]
            if status == "concluded: first player wins"
            else rps_match["tx1_address"]
        )
        ledger.credit(
            db,
            winner,
            "XCP",
            2 * rps_match["wager"],
            tx_index,
            action="wins",
            event=rps_match["id"],
        )

    # Update status of rps match.
    ledger.update_rps_match_status(db, rps_match["id"], status)


def validate(db, source, possible_moves, wager, move_random_hash, expiration, block_index):
    problems = []

    if util.enabled("disable_rps"):
        problems.append("rps disabled")

    if not isinstance(possible_moves, int):
        problems.append("possible_moves must be a integer")
        return problems
    if not isinstance(wager, int):
        problems.append("wager must be in satoshis")
        return problems
    if not isinstance(expiration, int):
        problems.append("expiration must be expressed as an integer block delta")
        return problems

    if not all(c in string.hexdigits for c in move_random_hash):
        problems.append("move_random_hash must be an hexadecimal string")
        return problems
    move_random_hash_bytes = binascii.unhexlify(move_random_hash)

    if possible_moves < 3:
        problems.append("possible moves must be at least 3")
    if possible_moves % 2 == 0:
        problems.append("possible moves must be odd")
    if wager <= 0:
        problems.append("non‐positive wager")
    if expiration < 0:
        problems.append("negative expiration")
    if expiration == 0 and not (
        block_index >= 317500 or config.TESTNET or config.REGTEST
    ):  # Protocol change.
        problems.append("zero expiration")
    if expiration > config.MAX_EXPIRATION:
        problems.append("expiration overflow")
    if len(move_random_hash_bytes) != 32:
        problems.append("move_random_hash must be 32 bytes in hexadecimal format")

    return problems


def compose(
    db, source: str, possible_moves: int, wager: int, move_random_hash: str, expiration: int
):
    problems = validate(
        db, source, possible_moves, wager, move_random_hash, expiration, ledger.CURRENT_BLOCK_INDEX
    )

    if problems:
        raise exceptions.ComposeError(problems)

    data = message_type.pack(ID)
    data += struct.pack(
        FORMAT, possible_moves, wager, binascii.unhexlify(move_random_hash), expiration
    )

    return (source, [], data)


def unpack(message, return_dict=False):
    try:
        if len(message) != LENGTH:
            raise exceptions.UnpackError
        (possible_moves, wager, move_random_hash, expiration) = struct.unpack(FORMAT, message)
        status = "open"
    except (exceptions.UnpackError, struct.error):
        (possible_moves, wager, move_random_hash, expiration) = 0, 0, "", 0
        status = "invalid: could not unpack"

    if return_dict:
        return {
            "possible_moves": possible_moves,
            "wager": wager,
            "move_random_hash": binascii.hexlify(move_random_hash).decode("utf8"),
            "expiration": expiration,
            "status": status,
        }
    return possible_moves, wager, move_random_hash, expiration, status


def parse(db, tx, message):
    rps_parse_cursor = db.cursor()
    # Unpack message.
    possible_moves, wager, move_random_hash, expiration, status = unpack(message)

    if status == "open":
        move_random_hash = binascii.hexlify(move_random_hash).decode("utf8")
        # Overbet
        balance = ledger.get_balance(db, tx["source"], "XCP")
        if balance == 0:
            wager = 0
        else:
            if balance < wager:
                wager = balance

        problems = validate(
            db, tx["source"], possible_moves, wager, move_random_hash, expiration, tx["block_index"]
        )
        if problems:
            status = f"invalid: {', '.join(problems)}"

    # Debit quantity wagered. (Escrow.)
    if status == "open":
        ledger.debit(
            db, tx["source"], "XCP", wager, tx["tx_index"], action="open RPS", event=tx["tx_hash"]
        )

    # Add parsed transaction to message-type–specific table.
    bindings = {
        "tx_index": tx["tx_index"],
        "tx_hash": tx["tx_hash"],
        "block_index": tx["block_index"],
        "source": tx["source"],
        "possible_moves": possible_moves,
        "wager": wager,
        "move_random_hash": move_random_hash,
        "expiration": expiration,
        "expire_index": tx["block_index"] + expiration,
        "status": status,
    }
    ledger.insert_record(db, "rps", bindings, "OPEN_RPS")

    # Match.
    if status == "open":
        match(db, tx, tx["block_index"])

    rps_parse_cursor.close()


def match(db, tx, block_index):
    cursor = db.cursor()

    # Get rps in question.
    rps = ledger.get_rps(db, tx["tx_hash"])
    if not rps:
        cursor.close()
        return
    else:
        assert len(rps) == 1
        if rps[0]["status"] != "open":
            cursor.close()
            return
    tx1 = rps[0]
    possible_moves = tx1["possible_moves"]
    wager = tx1["wager"]
    tx1_status = "open"  # noqa: F841

    # Get rps match
    # dont match twice same RPS
    already_matched = []
    old_rps_matches = ledger.get_already_matched_rps(db, tx1["tx_hash"])
    for old_rps_match in old_rps_matches:
        counter_tx_hash = (
            old_rps_match["tx1_hash"]
            if tx1["tx_hash"] == old_rps_match["tx0_hash"]
            else old_rps_match["tx0_hash"]
        )
        already_matched.append(counter_tx_hash)

    rps_matches = ledger.get_matching_rps(db, possible_moves, wager, tx1["source"], already_matched)

    if rps_matches:
        tx0 = rps_matches[0]

        # update status
        for txn in [tx0, tx1]:
            ledger.update_rps_status(db, txn["tx_hash"], "matched")

        bindings = {
            "id": util.make_id(tx0["tx_hash"], tx1["tx_hash"]),
            "tx0_index": tx0["tx_index"],
            "tx0_hash": tx0["tx_hash"],
            "tx0_address": tx0["source"],
            "tx1_index": tx1["tx_index"],
            "tx1_hash": tx1["tx_hash"],
            "tx1_address": tx1["source"],
            "tx0_move_random_hash": tx0["move_random_hash"],
            "tx1_move_random_hash": tx1["move_random_hash"],
            "wager": wager,
            "possible_moves": possible_moves,
            "tx0_block_index": tx0["block_index"],
            "tx1_block_index": tx1["block_index"],
            "block_index": block_index,
            "tx0_expiration": tx0["expiration"],
            "tx1_expiration": tx1["expiration"],
            "match_expire_index": block_index + 20,
            "status": "pending",
        }
        ledger.insert_record(db, "rps_matches", bindings, "RPS_MATCH")

    cursor.close()


def expire(db, block_index):
    cursor = db.cursor()

    # Expire rps and give refunds for the quantity wager.
    for rps in ledger.get_rps_to_expire(db, block_index):
        # use tx_index=0 for block actions
        cancel_rps(db, rps, "expired", block_index, 0)

        # Record rps expiration.
        bindings = {
            "rps_index": rps["tx_index"],
            "rps_hash": rps["tx_hash"],
            "source": rps["source"],
            "block_index": block_index,
        }
        ledger.insert_record(db, "rps_expirations", bindings, "RPS_EXPIRATION")

    # Expire rps matches
    for rps_match in ledger.get_rps_matches_to_expire(db, block_index):
        new_rps_match_status = "expired"
        # pending loses against resolved
        if rps_match["status"] == "pending and resolved":
            new_rps_match_status = "concluded: second player wins"
        elif rps_match["status"] == "resolved and pending":
            new_rps_match_status = "concluded: first player wins"
        # use tx_index=0 for block actions
        update_rps_match_status(db, rps_match, new_rps_match_status, block_index, 0)

        # Record rps match expiration.
        bindings = {
            "rps_match_id": rps_match["id"],
            "tx0_address": rps_match["tx0_address"],
            "tx1_address": rps_match["tx1_address"],
            "block_index": block_index,
        }
        ledger.insert_record(db, "rps_match_expirations", bindings, "RPS_MATCH_EXPIRATION")

        # Rematch not expired and not resolved RPS
        if new_rps_match_status == "expired":
            matched_rps = ledger.get_matched_not_expired_rps(
                db, rps_match["tx0_hash"], rps_match["tx1_hash"], expire_index=block_index
            )
            for rps in matched_rps:
                ledger.update_rps_status(db, rps["tx_hash"], "open")
                # Re-debit XCP refund by close_rps_match.
                ledger.debit(
                    db,
                    rps["source"],
                    "XCP",
                    rps["wager"],
                    0,
                    action="reopen RPS after matching expiration",
                    event=rps_match["id"],
                )
                # Rematch
                match(
                    db,
                    {
                        "tx_index": rps["tx_index"],
                        "tx_hash": rps["tx_hash"],
                    },
                    block_index,
                )

    cursor.close()
