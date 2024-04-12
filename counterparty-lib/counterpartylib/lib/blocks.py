"""
Initialise database.

Sieve blockchain for Counterparty transactions, and add them to the database.
"""

import binascii
import decimal
import os
import struct
import time
from datetime import timedelta

D = decimal.Decimal
import collections  # noqa: E402
import copy  # noqa: E402, F401
import csv  # noqa: E402
import http  # noqa: E402
import logging  # noqa: E402
import platform  # noqa: E402, F401

import apsw  # noqa: E402
import bitcoin as bitcoinlib  # noqa: E402
from bitcoin.core.script import CScriptInvalidError  # noqa: E402, F401
from halo import Halo  # noqa: E402
from termcolor import colored  # noqa: E402

from counterpartylib import server  # noqa: E402
from counterpartylib.lib import (  # noqa: E402
    arc4,  # noqa: F401
    backend,
    check,
    config,
    database,
    exceptions,
    ledger,
    log,  # noqa: F401
    message_type,
    prefetcher,
    script,  # noqa: F401
    util,  # noqa: F401
)
from counterpartylib.lib.gettxinfo import get_tx_info  # noqa: E402
from counterpartylib.lib.kickstart.blocks_parser import BlockchainParser  # noqa: E402
from counterpartylib.lib.transaction_helper import p2sh_encoding  # noqa: E402, F401

from .exceptions import BTCOnlyError, DecodeError  # noqa: E402, F401
from .kickstart.utils import ib2h  # noqa: E402, F401
from .messages import (  # noqa: E402
    bet,
    broadcast,
    btcpay,
    burn,
    cancel,
    destroy,
    dispenser,
    dividend,
    issuance,
    order,
    rps,
    rpsresolve,
    send,
    sweep,
)
from .messages.versions import enhanced_send, mpma  # noqa: E402

logger = logging.getLogger(config.LOGGER_NAME)

NUM_PREFETCHER_THREADS = 3

# Order matters for FOREIGN KEY constraints.
TABLES = ["balances", "credits", "debits", "messages"] + [
    "order_match_expirations",
    "order_matches",
    "order_expirations",
    "orders",
    "bet_match_expirations",
    "bet_matches",
    "bet_match_resolutions",
    "bet_expirations",
    "bets",
    "broadcasts",
    "btcpays",
    "burns",
    "cancels",
    "dividends",
    "issuances",
    "sends",
    "rps_match_expirations",
    "rps_expirations",
    "rpsresolves",
    "rps_matches",
    "rps",
    "destructions",
    "assets",
    "addresses",
    "sweeps",
    "dispensers",
    "dispenses",
    "dispenser_refills",
]

MAINNET_BURNS = {}
CURR_DIR = os.path.dirname(os.path.realpath(__file__))
with open(CURR_DIR + "/../mainnet_burns.csv", "r") as f:
    mainnet_burns_reader = csv.DictReader(f)
    for line in mainnet_burns_reader:
        MAINNET_BURNS[line["tx_hash"]] = line

OK_GREEN = colored("[OK]", "green")
SPINNER_STYLE = "bouncingBar"


def parse_tx(db, tx):
    """Parse the transaction, return True for success."""
    cursor = db.cursor()

    try:
        with db:
            # Only one source and one destination allowed for now.
            if len(tx["source"].split("-")) > 1:
                return
            if tx["destination"]:
                if len(tx["destination"].split("-")) > 1:
                    return

            # Burns.
            if tx["destination"] == config.UNSPENDABLE:
                burn.parse(db, tx, MAINNET_BURNS)
                return

            if len(tx["data"]) > 1:
                try:
                    message_type_id, message = message_type.unpack(tx["data"], tx["block_index"])
                except struct.error:  # Deterministically raised.
                    message_type_id = None
                    message = None
            else:
                message_type_id = None
                message = None

            # Protocol change.
            rps_enabled = tx["block_index"] >= 308500 or config.TESTNET or config.REGTEST

            supported = True

            if message_type_id == send.ID:
                send.parse(db, tx, message)
            elif message_type_id == enhanced_send.ID and ledger.enabled(
                "enhanced_sends", block_index=tx["block_index"]
            ):
                enhanced_send.parse(db, tx, message)
            elif message_type_id == mpma.ID and ledger.enabled(
                "mpma_sends", block_index=tx["block_index"]
            ):
                mpma.parse(db, tx, message)
            elif message_type_id == order.ID:
                order.parse(db, tx, message)
            elif message_type_id == btcpay.ID:
                btcpay.parse(db, tx, message)
            elif message_type_id == issuance.ID or (
                ledger.enabled("issuance_backwards_compatibility", block_index=tx["block_index"])
                and message_type_id == issuance.LR_ISSUANCE_ID
            ):
                issuance.parse(db, tx, message, message_type_id)
            elif (
                message_type_id == issuance.SUBASSET_ID
                and ledger.enabled("subassets", block_index=tx["block_index"])
            ) or (
                ledger.enabled("issuance_backwards_compatibility", block_index=tx["block_index"])
                and message_type_id == issuance.LR_SUBASSET_ID
            ):
                issuance.parse(db, tx, message, message_type_id)
            elif message_type_id == broadcast.ID:
                broadcast.parse(db, tx, message)
            elif message_type_id == bet.ID:
                bet.parse(db, tx, message)
            elif message_type_id == dividend.ID:
                dividend.parse(db, tx, message)
            elif message_type_id == cancel.ID:
                cancel.parse(db, tx, message)
            elif message_type_id == rps.ID and rps_enabled:
                rps.parse(db, tx, message)
            elif message_type_id == rpsresolve.ID and rps_enabled:
                rpsresolve.parse(db, tx, message)
            elif message_type_id == destroy.ID and ledger.enabled(
                "destroy_reactivated", block_index=tx["block_index"]
            ):
                destroy.parse(db, tx, message)
            elif message_type_id == sweep.ID and ledger.enabled(
                "sweep_send", block_index=tx["block_index"]
            ):
                sweep.parse(db, tx, message)
            elif message_type_id == dispenser.ID and ledger.enabled(
                "dispensers", block_index=tx["block_index"]
            ):
                dispenser.parse(db, tx, message)
            elif message_type_id == dispenser.DISPENSE_ID and ledger.enabled(
                "dispensers", block_index=tx["block_index"]
            ):
                dispenser.dispense(db, tx)
            else:
                supported = False

            ledger.add_to_journal(
                db,
                tx["block_index"],
                "parse",
                "transactions",
                "TRANSACTION_PARSED",
                {
                    "tx_index": tx["tx_index"],
                    "tx_hash": tx["tx_hash"],
                    "supported": supported,
                },
            )

            if not supported:
                cursor.execute(
                    """UPDATE transactions \
                                    SET supported=$supported \
                                    WHERE tx_hash=$tx_hash""",
                    {"supported": False, "tx_hash": tx["tx_hash"]},
                )
                if tx["block_index"] != config.MEMPOOL_BLOCK_INDEX:
                    logger.info(f"Unsupported transaction: hash {tx['tx_hash']}; data {tx['data']}")
                cursor.close()
                return False

            # NOTE: for debugging (check asset conservation after every `N` transactions).
            # if not tx['tx_index'] % N:
            #     check.asset_conservation(db)

            return True
    except Exception as e:
        raise exceptions.ParseTransactionError(f"{e}")  # noqa: B904
    finally:
        cursor.close()


def parse_block(
    db,
    block_index,
    block_time,
    previous_ledger_hash=None,
    ledger_hash=None,
    previous_txlist_hash=None,
    txlist_hash=None,
    previous_messages_hash=None,
):
    """Parse the block, return hash of new ledger, txlist and messages.

    The unused arguments `ledger_hash` and `txlist_hash` are for the test suite.
    """

    ledger.BLOCK_LEDGER = []
    ledger.BLOCK_JOURNAL = []

    assert block_index == ledger.CURRENT_BLOCK_INDEX

    # Expire orders, bets and rps.
    order.expire(db, block_index)
    bet.expire(db, block_index, block_time)
    rps.expire(db, block_index)

    # Close dispensers
    dispenser.close_pending(db, block_index)

    # Parse transactions, sorting them by type.
    cursor = db.cursor()
    cursor.execute(
        """SELECT * FROM transactions \
                      WHERE block_index=$block_index ORDER BY tx_index""",
        {"block_index": block_index},
    )
    txlist = []
    for tx in list(cursor):
        try:
            parse_tx(db, tx)
            data = binascii.hexlify(tx["data"]).decode("UTF-8") if tx["data"] else ""
            txlist.append(
                f"{tx['tx_hash']}{tx['source']}{tx['destination']}{tx['btc_amount']}{tx['fee']}{data}"
            )
        except exceptions.ParseTransactionError as e:
            logger.warning(f"ParseTransactionError for tx {tx['tx_hash']}: {e}")
            raise e
            # pass

    cursor.close()

    # Calculate consensus hashes.
    new_txlist_hash, found_txlist_hash = check.consensus_hash(
        db, "txlist_hash", previous_txlist_hash, txlist
    )
    new_ledger_hash, found_ledger_hash = check.consensus_hash(
        db, "ledger_hash", previous_ledger_hash, ledger.BLOCK_LEDGER
    )
    new_messages_hash, found_messages_hash = check.consensus_hash(
        db, "messages_hash", previous_messages_hash, ledger.BLOCK_JOURNAL
    )

    ledger.add_to_journal(
        db,
        block_index,
        "parse",
        "blocks",
        "BLOCK_PARSED",
        {
            "block_index": block_index,
            "ledger_hash": new_ledger_hash,
            "txlist_hash": new_txlist_hash,
            "messages_hash": new_messages_hash,
        },
    )

    return new_ledger_hash, new_txlist_hash, new_messages_hash, found_messages_hash


def initialise(db):
    """Initialise data, create and populate the database."""
    cursor = db.cursor()

    # remove misnamed indexes
    database.drop_indexes(
        cursor,
        [
            "block_index_idx",
            "index_hash_idx",
            "tx_index_idx",
            "tx_hash_idx",
            "index_index_idx",
            "index_hash_index_idx",
            "address_idx",
            "asset_idx",
            "name_idx",
            "id_idx",
            "addresses_idx",
            "block_index_message_index_idx",
            "asset_longname_idx",
        ],
    )

    # Blocks
    cursor.execute("""CREATE TABLE IF NOT EXISTS blocks(
                      block_index INTEGER UNIQUE,
                      block_hash TEXT UNIQUE,
                      block_time INTEGER,
                      previous_block_hash TEXT UNIQUE,
                      difficulty INTEGER,
                      PRIMARY KEY (block_index, block_hash))
                   """)

    # SQLite can’t do `ALTER TABLE IF COLUMN NOT EXISTS`.
    block_columns = [column["name"] for column in cursor.execute("""PRAGMA table_info(blocks)""")]
    if "ledger_hash" not in block_columns:
        cursor.execute("""ALTER TABLE blocks ADD COLUMN ledger_hash TEXT""")
    if "txlist_hash" not in block_columns:
        cursor.execute("""ALTER TABLE blocks ADD COLUMN txlist_hash TEXT""")
    if "messages_hash" not in block_columns:
        cursor.execute("""ALTER TABLE blocks ADD COLUMN messages_hash TEXT""")
    if "previous_block_hash" not in block_columns:
        cursor.execute("""ALTER TABLE blocks ADD COLUMN previous_block_hash TEXT""")
    if "difficulty" not in block_columns:
        cursor.execute("""ALTER TABLE blocks ADD COLUMN difficulty TEXT""")

    database.create_indexes(
        cursor,
        "blocks",
        [
            ["block_index"],
            ["block_index", "block_hash"],
        ],
    )

    # Check that first block in DB is BLOCK_FIRST.
    cursor.execute("""SELECT * from blocks ORDER BY block_index LIMIT 1""")
    blocks = list(cursor)
    if len(blocks):
        if blocks[0]["block_index"] != config.BLOCK_FIRST:
            raise exceptions.DatabaseError(
                f"First block in database is not block {config.BLOCK_FIRST}."
            )

    # Transactions
    cursor.execute("""CREATE TABLE IF NOT EXISTS transactions(
                      tx_index INTEGER UNIQUE,
                      tx_hash TEXT UNIQUE,
                      block_index INTEGER,
                      block_hash TEXT,
                      block_time INTEGER,
                      source TEXT,
                      destination TEXT,
                      btc_amount INTEGER,
                      fee INTEGER,
                      data BLOB,
                      supported BOOL DEFAULT 1,
                      FOREIGN KEY (block_index, block_hash) REFERENCES blocks(block_index, block_hash),
                      PRIMARY KEY (tx_index, tx_hash, block_index))
                    """)
    database.create_indexes(
        cursor,
        "transactions",
        [
            ["block_index"],
            ["tx_index"],
            ["tx_hash"],
            ["block_index", "tx_index"],
            ["tx_index", "tx_hash", "block_index"],
        ],
    )

    # Purge database of blocks, transactions from before BLOCK_FIRST.
    cursor.execute("""DELETE FROM blocks WHERE block_index < ?""", (config.BLOCK_FIRST,))
    cursor.execute("""DELETE FROM transactions WHERE block_index < ?""", (config.BLOCK_FIRST,))

    # (Valid) debits
    cursor.execute("""CREATE TABLE IF NOT EXISTS debits(
                      block_index INTEGER,
                      address TEXT,
                      asset TEXT,
                      quantity INTEGER,
                      action TEXT,
                      event TEXT,
                      FOREIGN KEY (block_index) REFERENCES blocks(block_index))
                   """)

    debits_columns = [column["name"] for column in cursor.execute("""PRAGMA table_info(debits)""")]
    if "tx_index" not in debits_columns:
        cursor.execute("""ALTER TABLE debits ADD COLUMN tx_index INTEGER""")

    database.create_indexes(
        cursor,
        "debits",
        [
            ["address"],
            ["asset"],
        ],
    )

    # (Valid) credits
    cursor.execute("""CREATE TABLE IF NOT EXISTS credits(
                      block_index INTEGER,
                      address TEXT,
                      asset TEXT,
                      quantity INTEGER,
                      calling_function TEXT,
                      event TEXT,
                      FOREIGN KEY (block_index) REFERENCES blocks(block_index))
                   """)

    credits_columns = [
        column["name"] for column in cursor.execute("""PRAGMA table_info(credits)""")
    ]
    if "tx_index" not in credits_columns:
        cursor.execute("""ALTER TABLE credits ADD COLUMN tx_index INTEGER""")

    database.create_indexes(
        cursor,
        "credits",
        [
            ["address"],
            ["asset"],
        ],
    )

    # Balances
    cursor.execute("""CREATE TABLE IF NOT EXISTS balances(
                      address TEXT,
                      asset TEXT,
                      quantity INTEGER)
                   """)

    balances_columns = [
        column["name"] for column in cursor.execute("""PRAGMA table_info(balances)""")
    ]
    # TODO: add foreign key constraint
    if "block_index" not in balances_columns:
        cursor.execute("""ALTER TABLE balances ADD COLUMN block_index INTEGER""")
    if "tx_index" not in balances_columns:
        cursor.execute("""ALTER TABLE balances ADD COLUMN tx_index INTEGER""")

    database.create_indexes(
        cursor,
        "balances",
        [
            ["address", "asset"],
            ["address"],
            ["asset"],
            ["block_index"],
        ],
    )

    # Assets
    # TODO: Store more asset info here?!
    cursor.execute("""CREATE TABLE IF NOT EXISTS assets(
                      asset_id TEXT UNIQUE,
                      asset_name TEXT UNIQUE,
                      block_index INTEGER,
                      asset_longname TEXT)
                   """)

    database.create_indexes(
        cursor,
        "assets",
        [
            ["asset_name"],
            ["asset_id"],
        ],
    )

    # Add asset_longname for sub-assets
    #   SQLite can’t do `ALTER TABLE IF COLUMN NOT EXISTS`.
    columns = [column["name"] for column in cursor.execute("""PRAGMA table_info(assets)""")]
    if "asset_longname" not in columns:
        cursor.execute("""ALTER TABLE assets ADD COLUMN asset_longname TEXT""")

    database.create_indexes(
        cursor,
        "assets",
        [
            ["asset_longname"],
        ],
        unique=True,
    )

    cursor.execute("""SELECT * FROM assets WHERE asset_name = ?""", ("BTC",))
    if not list(cursor):
        cursor.execute("""INSERT INTO assets VALUES (?,?,?,?)""", ("0", "BTC", None, None))
        cursor.execute("""INSERT INTO assets VALUES (?,?,?,?)""", ("1", "XCP", None, None))

    # Addresses
    # Leaving this here because in the future this could work for other things besides broadcast
    cursor.execute("""CREATE TABLE IF NOT EXISTS addresses(
                      address TEXT UNIQUE,
                      options INTEGER,
                      block_index INTEGER)
                   """)

    database.create_indexes(
        cursor,
        "addresses",
        [
            ["address"],
        ],
    )

    # Consolidated
    send.initialise(db)
    destroy.initialise(db)
    order.initialise(db)
    btcpay.initialise(db)
    issuance.initialise(db)
    broadcast.initialise(db)
    bet.initialise(db)
    dividend.initialise(db)
    burn.initialise(db)
    cancel.initialise(db)
    rps.initialise(db)
    rpsresolve.initialise(db)
    sweep.initialise(db)
    dispenser.initialise(db)

    # Messages
    cursor.execute("""CREATE TABLE IF NOT EXISTS messages(
                      message_index INTEGER PRIMARY KEY,
                      block_index INTEGER,
                      command TEXT,
                      category TEXT,
                      bindings TEXT,
                      timestamp INTEGER,
                      event TEXT)
                  """)
    columns = [column["name"] for column in cursor.execute("""PRAGMA table_info(messages)""")]
    if "event" not in columns:
        cursor.execute("""ALTER TABLE messages ADD COLUMN event TEXT""")

    # TODO: FOREIGN KEY (block_index) REFERENCES blocks(block_index) DEFERRABLE INITIALLY DEFERRED)
    database.create_indexes(
        cursor,
        "messages",
        [
            ["block_index"],
            ["block_index", "message_index"],
            ["event"],
        ],
    )

    cursor.execute("""CREATE TABLE IF NOT EXISTS transaction_outputs(
                        tx_index,
                        tx_hash TEXT,
                        block_index INTEGER,
                        out_index INTEGER,
                        destination TEXT,
                        btc_amount INTEGER,
                        PRIMARY KEY (tx_hash, out_index),
                        FOREIGN KEY (tx_index, tx_hash, block_index) REFERENCES transactions(tx_index, tx_hash, block_index))
                   """)

    # Mempool messages
    # NOTE: `status`, 'block_index` are removed from bindings.
    cursor.execute("""DROP TABLE IF EXISTS mempool""")
    cursor.execute("""CREATE TABLE mempool(
                      tx_hash TEXT,
                      command TEXT,
                      category TEXT,
                      bindings TEXT,
                      timestamp INTEGER)
                  """)

    # Lock UPDATE on all tables
    for table in TABLES:
        cursor.execute(f"""CREATE TRIGGER IF NOT EXISTS block_update_{table}
                           BEFORE UPDATE ON {table} BEGIN
                               SELECT RAISE(FAIL, "UPDATES NOT ALLOWED");
                           END;
                        """)
    cursor.close()


def list_tx(
    db,
    block_hash,
    block_index,
    block_time,
    tx_hash,
    tx_index,
    tx_hex=None,
    decoded_tx=None,
    block_parser=None,
):
    assert type(tx_hash) == str  # noqa: E721
    cursor = db.cursor()

    # Edge case: confirmed tx_hash also in mempool
    # TODO: This is dog-slow.
    if block_parser is None:  # skip on kickstart
        cursor.execute("""SELECT * FROM transactions WHERE tx_hash = ?""", (tx_hash,))
        transactions = list(cursor)
        if transactions:
            return tx_index

    # Get the important details about each transaction.
    if decoded_tx is None:
        if tx_hex is None:
            tx_hex = backend.getrawtransaction(tx_hash, block_index=block_index)
        decoded_tx = BlockchainParser().deserialize_tx(tx_hex)

    source, destination, btc_amount, fee, data, dispensers_outs = get_tx_info(
        db, decoded_tx, block_index, block_parser=block_parser
    )

    # For mempool
    if block_hash == None:  # noqa: E711
        block_hash = config.MEMPOOL_BLOCK_HASH
        block_index = config.MEMPOOL_BLOCK_INDEX
    else:
        assert block_index == ledger.CURRENT_BLOCK_INDEX

    if source and (data or destination == config.UNSPENDABLE or dispensers_outs):
        logger.debug(f"Saving transaction: {tx_hash}")
        transaction_bindings = {
            "tx_index": tx_index,
            "tx_hash": tx_hash,
            "block_index": block_index,
            "block_hash": block_hash,
            "block_time": block_time,
            "source": source,
            "destination": destination,
            "btc_amount": btc_amount,
            "fee": fee,
            "data": data,
        }
        ledger.insert_record(db, "transactions", transaction_bindings, "NEW_TRANSACTION")

        for next_out in dispensers_outs:
            transaction_outputs_bindings = {
                "tx_index": tx_index,
                "tx_hash": tx_hash,
                "block_index": block_index,
                "out_index": next_out["out_index"],
                "destination": next_out["destination"],
                "btc_amount": next_out["btc_amount"],
            }
            ledger.insert_record(
                db, "transaction_outputs", transaction_outputs_bindings, "NEW_TRANSACTION_OUTPUT"
            )

        cursor.close()

        return tx_index + 1
    else:
        pass

    return tx_index


def clean_table_from(cursor, table, block_index):
    logger.info(f"Rolling table `{table}` back to block {block_index}...")
    # internal function, no sql injection here
    cursor.execute(f"""DELETE FROM {table} WHERE block_index >= ?""", (block_index,))  # nosec B608  # noqa: S608


def clean_messages_tables(db, block_index=0):
    # clean all tables except assets' blocks', 'transaction_outputs' and 'transactions'
    block_index = max(block_index, config.BLOCK_FIRST)
    if block_index == config.BLOCK_FIRST:
        rebuild_database(db, include_transactions=False)
    else:
        cursor = db.cursor()
        cursor.execute("""PRAGMA foreign_keys=OFF""")
        for table in TABLES:
            clean_table_from(cursor, table, block_index)
        cursor.execute("""PRAGMA foreign_keys=ON""")


def clean_transactions_tables(cursor, block_index=0):
    # clean all tables except assets' blocks', 'transaction_outputs' and 'transactions'
    cursor.execute("""PRAGMA foreign_keys=OFF""")
    for table in ["transaction_outputs", "transactions", "blocks"]:
        clean_table_from(cursor, table, block_index)
    cursor.execute("""PRAGMA foreign_keys=ON""")


def rebuild_database(db, include_transactions=True):
    cursor = db.cursor()
    cursor.execute("""PRAGMA foreign_keys=OFF""")
    tables_to_clean = list(TABLES)
    if include_transactions:
        tables_to_clean += ["transaction_outputs", "transactions", "blocks"]
    for table in tables_to_clean:
        cursor.execute(f"DROP TABLE {table}")  # nosec B608
    cursor.execute("""PRAGMA foreign_keys=ON""")
    initialise(db)


def rollback(db, block_index=0):
    block_index = max(block_index, config.BLOCK_FIRST)
    # clean all tables
    start_time = time.time()
    step = f"Rolling database back to block {block_index}..."
    with Halo(text=step, spinner=SPINNER_STYLE):
        if block_index == config.BLOCK_FIRST:
            rebuild_database(db)
        else:
            clean_messages_tables(db, block_index=block_index)
            cursor = db.cursor()
            clean_transactions_tables(cursor, block_index=block_index)
            cursor.close()
        logger.info(f"Database rolled back to block_index {block_index}")
    ledger.CURRENT_BLOCK_INDEX = block_index - 1
    print(f"{OK_GREEN} {step}")
    print(f"Rollback done in {time.time() - start_time:.2f}s")


def generate_progression_message(
    block,
    start_time_block_parse,
    start_time_all_blocks_parse,
    block_parsed_count,
    block_count,
    tx_index=None,
):
    block_parsing_duration = time.time() - start_time_block_parse
    cumulated_duration = time.time() - start_time_all_blocks_parse
    expected_duration = (cumulated_duration / block_parsed_count) * block_count
    remaining_duration = expected_duration - cumulated_duration
    current_block = f"Block {block['block_index']} parsed in {block_parsing_duration:.3f}s"
    blocks_parsed = f"{block_parsed_count}/{block_count} blocks parsed"
    txs_indexed = " - "
    if tx_index is not None:
        txs_indexed = f" - tx_index: {tx_index} - "
    cumulated_duration = timedelta(seconds=int(cumulated_duration))
    expected_duration = timedelta(seconds=int(expected_duration))
    remaining_duration = timedelta(seconds=int(remaining_duration))
    duration = f"{cumulated_duration}/{expected_duration} ({remaining_duration})"
    return f"{current_block} [{blocks_parsed}{txs_indexed}{duration}]"


def reparse(db, block_index=0):
    server.connect_to_addrindexrs()

    cursor = db.cursor()
    # clean all tables except assets' blocks', 'transaction_outputs' and 'transactions'
    step = f"Rolling database back to block {block_index}..."
    with Halo(text=step, spinner=SPINNER_STYLE):
        clean_messages_tables(db, block_index=block_index)
    print(f"{OK_GREEN} {step}")

    step = "Clean consensus hashes..."
    with Halo(text=step, spinner=SPINNER_STYLE):
        query = """
            UPDATE blocks 
            SET ledger_hash=NULL, txlist_hash=NULL, messages_hash=NULL 
            WHERE block_index >= ?
        """
        cursor.execute(query, (block_index,))
    print(f"{OK_GREEN} {step}")

    # reparse blocks
    start_time_all_blocks_parse = time.time()
    block_parsed_count = 0
    count_query = "SELECT COUNT(*) AS cnt FROM blocks WHERE block_index >= ?"
    block_count = cursor.execute(count_query, (block_index,)).fetchone()["cnt"]
    step = f"Reparsing blocks from block {block_index}..."
    with Halo(text=step, spinner=SPINNER_STYLE) as spinner:
        cursor.execute(
            """SELECT * FROM blocks WHERE block_index >= ? ORDER BY block_index""", (block_index,)
        )
        for block in cursor.fetchall():
            start_time_block_parse = time.time()
            ledger.CURRENT_BLOCK_INDEX = block["block_index"]
            parse_block(db, block["block_index"], block["block_time"])
            block_parsed_count += 1
            message = generate_progression_message(
                block,
                start_time_block_parse,
                start_time_all_blocks_parse,
                block_parsed_count,
                block_count,
            )
            spinner.text = message
    print(f"{OK_GREEN} {message}")
    print(f"All blocks reparsed in {time.time() - start_time_all_blocks_parse:.2f}s")


def last_db_index(db):
    cursor = db.cursor()
    query = "SELECT name FROM sqlite_master WHERE type='table' AND name='blocks'"
    if len(list(cursor.execute(query))) == 0:
        return 0

    query = "SELECT block_index FROM blocks ORDER BY block_index DESC LIMIT 1"
    blocks = list(cursor.execute(query))
    if len(blocks) == 0:
        return 0

    return blocks[0]["block_index"]


def get_next_tx_index(db):
    """Return index of next transaction."""
    cursor = db.cursor()
    txes = list(
        cursor.execute(
            """SELECT * FROM transactions WHERE tx_index = (SELECT MAX(tx_index) from transactions)"""
        )
    )
    if txes:
        assert len(txes) == 1
        tx_index = txes[0]["tx_index"] + 1
    else:
        tx_index = 0
    cursor.close()
    return tx_index


class MempoolError(Exception):
    pass


def follow(db):
    # Check software version.
    check.software_version()
    last_software_check = time.time()

    # Initialise.
    initialise(db)

    # Get index of last block.
    if ledger.CURRENT_BLOCK_INDEX == 0:
        logger.warning("New database.")
        block_index = config.BLOCK_FIRST
        database.update_version(db)
    else:
        block_index = ledger.CURRENT_BLOCK_INDEX + 1

        # Check database version.
        try:
            check.database_version(db)
        except check.DatabaseVersionError as e:
            logger.info(str(e))
            # no need to rollback a new database
            if block_index != config.BLOCK_FIRST:
                if e.required_action == "rollback":
                    rollback(db, block_index=e.from_block_index)
                    block_index = e.from_block_index
                elif e.required_action == "reparse":
                    reparse(db, block_index=e.from_block_index)
            database.update_version(db)

    logger.info("Resuming parsing.")

    # If we're far behind, start Prefetcher.
    block_count = backend.getblockcount()  # TODO: Need retry logic
    if block_index <= block_count - 2000:
        prefetcher.start_all(NUM_PREFETCHER_THREADS)

    # Get index of last transaction.
    tx_index = get_next_tx_index(db)

    not_supported = {}  # No false positives. Use a dict to allow for O(1) lookups
    not_supported_sorted = collections.deque()
    # ^ Entries in form of (block_index, tx_hash), oldest first. Allows for easy removal of past, unncessary entries
    cursor = db.cursor()

    # a reorg can happen without the block count increasing, or even for that
    # matter, with the block count decreasing. This should only delay
    # processing of the new blocks a bit.
    while True:
        start_time = time.time()

        # Get block count.
        # If the backend is unreachable and `config.FORCE` is set, just sleep
        # and try again repeatedly.
        try:
            block_count = backend.getblockcount()
        except (
            ConnectionRefusedError,
            http.client.CannotSendRequest,
            backend.addrindexrs.BackendRPCError,
        ) as e:
            if config.FORCE:
                time.sleep(config.BACKEND_POLL_INTERVAL)
                continue
            else:
                raise e

        # Stop Prefetcher thread as we get close to today.
        if block_index >= block_count - 100:
            prefetcher.stop_all()

        # Get new blocks.
        if block_index <= block_count:
            # Backwards check for incorrect blocks due to chain reorganisation, and stop when a common parent is found.
            current_index = block_index
            requires_rollback = False
            while True:
                if current_index == config.BLOCK_FIRST:
                    break

                logger.debug(f"Checking that block {current_index} is not an orphan.")
                # Backend parent hash.
                current_hash = backend.getblockhash(current_index)
                current_cblock = backend.getblock(current_hash)
                backend_parent = bitcoinlib.core.b2lx(current_cblock.hashPrevBlock)

                # DB parent hash.
                blocks = list(
                    cursor.execute(
                        """SELECT * FROM blocks
                                                WHERE block_index = ?""",
                        (current_index - 1,),
                    )
                )
                if len(blocks) != 1:  # For empty DB.
                    break
                db_parent = blocks[0]["block_hash"]

                # Compare.
                assert type(db_parent) == str  # noqa: E721
                assert type(backend_parent) == str  # noqa: E721
                if db_parent == backend_parent:
                    break
                else:
                    current_index -= 1
                    requires_rollback = True

            # Rollback for reorganisation.
            if requires_rollback:
                # Record reorganisation.
                logger.warning(f"Blockchain reorganisation at block {current_index}.")
                ledger.add_to_journal(
                    db,
                    block_index,
                    "reorg",
                    "blocks",
                    "BLOCKCHAIN_REORGANISATION",
                    {"block_index": current_index},
                )

                # Rollback the DB.
                rollback(db, block_index=current_index - 1)
                block_index = current_index
                tx_index = get_next_tx_index(db)
                continue

            # Check version every 24H.
            # (Don’t add more blocks to the database while
            # running an out‐of‐date client!)
            if time.time() - last_software_check > 86400:
                last_software_check = time.time()
                check.software_version()

            # Get and parse transactions in this block (atomically).
            # logger.debug(f'Blockchain cache size: {len(prefetcher.BLOCKCHAIN_CACHE)}')
            if current_index in prefetcher.BLOCKCHAIN_CACHE:
                # logger.debug(f'Blockchain cache hit! Block index: {current_index}')
                block_hash = prefetcher.BLOCKCHAIN_CACHE[current_index]["block_hash"]
                txhash_list = prefetcher.BLOCKCHAIN_CACHE[current_index]["txhash_list"]
                raw_transactions = prefetcher.BLOCKCHAIN_CACHE[current_index]["raw_transactions"]
                previous_block_hash = prefetcher.BLOCKCHAIN_CACHE[current_index][
                    "previous_block_hash"
                ]
                block_time = prefetcher.BLOCKCHAIN_CACHE[current_index]["block_time"]
                block_difficulty = prefetcher.BLOCKCHAIN_CACHE[current_index]["block_difficulty"]
                del prefetcher.BLOCKCHAIN_CACHE[current_index]
            else:
                if block_index < block_count - 100:
                    logger.warning(f"Blockchain cache miss :/ Block index: {current_index}")
                block_hash = backend.getblockhash(current_index)
                block = backend.getblock(block_hash)
                previous_block_hash = bitcoinlib.core.b2lx(block.hashPrevBlock)
                block_time = block.nTime
                txhash_list, raw_transactions = backend.get_tx_list(block)
                block_difficulty = block.difficulty

            with db:
                ledger.CURRENT_BLOCK_INDEX = block_index

                # List the block.
                block_bindings = {
                    "block_index": block_index,
                    "block_hash": block_hash,
                    "block_time": block_time,
                    "previous_block_hash": previous_block_hash,
                    "difficulty": block_difficulty,
                }
                ledger.insert_record(db, "blocks", block_bindings, "NEW_BLOCK")

                # List the transactions in the block.
                for tx_hash in txhash_list:
                    tx_hex = raw_transactions[tx_hash]
                    tx_index = list_tx(
                        db, block_hash, block_index, block_time, tx_hash, tx_index, tx_hex
                    )

                # Parse the transactions in the block.
                new_ledger_hash, new_txlist_hash, new_messages_hash, found_messages_hash = (
                    parse_block(db, block_index, block_time)
                )

            # When newly caught up, check for conservation of assets.
            if block_index == block_count:
                if config.CHECK_ASSET_CONSERVATION:
                    check.asset_conservation(db)

            # Remove any non‐supported transactions older than ten blocks.
            while len(not_supported_sorted) and not_supported_sorted[0][0] <= block_index - 10:
                tx_h = not_supported_sorted.popleft()[1]
                del not_supported[tx_h]

            duration = time.time() - start_time
            overwrote_hash = (
                found_messages_hash
                if found_messages_hash and found_messages_hash != new_messages_hash
                else ""
            )
            overwrote = f"[overwrote {overwrote_hash}]" if overwrote_hash else ""
            logger.info(
                f"Block: {block_index} ({duration:.2f}, hashes: L:{new_ledger_hash[-5:]} / TX:{new_txlist_hash[-5:]} / M:{new_messages_hash[-5:]}{overwrote})"
            )

            # Increment block index.
            block_count = backend.getblockcount()
            block_index += 1

        else:
            # TODO: add zeromq support here to await TXs and Blocks instead of constantly polling
            # Get old mempool.
            old_mempool = list(cursor.execute("""SELECT * FROM mempool"""))
            old_mempool_hashes = [message["tx_hash"] for message in old_mempool]

            if backend.MEMPOOL_CACHE_INITIALIZED is False:
                backend.init_mempool_cache()
                logger.info("Ready for queries.")

            # Fake values for fake block.
            curr_time = int(time.time())
            mempool_tx_index = tx_index

            xcp_mempool = []
            raw_mempool = backend.getrawmempool()

            # For each transaction in Bitcoin Core mempool, if it’s new, create
            # a fake block, a fake transaction, capture the generated messages,
            # and then save those messages.
            # Every transaction in mempool is parsed independently. (DB is rolled back after each one.)
            # We first filter out which transactions we've already parsed before so we can batch fetch their raw data
            parse_txs = []
            for tx_hash in raw_mempool:
                # If already in mempool, copy to new one.
                if tx_hash in old_mempool_hashes:
                    for message in old_mempool:
                        if message["tx_hash"] == tx_hash:
                            xcp_mempool.append((tx_hash, message))

                # If not a supported XCP transaction, skip.
                elif tx_hash in not_supported:
                    pass

                # Else: list, parse and save it.
                else:
                    parse_txs.append(tx_hash)

            # fetch raw for all transactions that need to be parsed
            # Sometimes the transactions can’t be found: `{'code': -5, 'message': 'No information available about transaction'}`
            #  - is txindex enabled in Bitcoind?
            #  - or was there a block found while batch feting the raw txs
            #  - or was there a double spend for w/e reason accepted into the mempool (replace-by-fee?)
            try:
                raw_transactions = backend.getrawtransaction_batch(parse_txs, skip_missing=True)
            except Exception as e:
                logger.warning("Failed to fetch raw for mempool TXs, restarting loop; %s", (e,))
                continue  # restart the follow loop

            parsed_txs_count = 0
            for tx_hash in parse_txs:
                # Get block count everytime we parse some mempool_txs. If there is a new block, we just interrupt this process
                if parsed_txs_count % 100 == 0:
                    if len(parse_txs) > 1000:
                        logger.info(
                            f"Mempool parsed txs count:{parsed_txs_count} from {len(parse_txs)}"
                        )

                    try:
                        block_count = backend.getblockcount()

                        if block_index <= block_count:
                            logger.info("Mempool parsing interrupted, there are blocks to parse")
                            break  # Interrupt the process if there is a new block to parse
                    except (
                        ConnectionRefusedError,
                        http.client.CannotSendRequest,
                        backend.addrindexrs.BackendRPCError,
                    ) as e:  # noqa: F841
                        # Keep parsing what we have, anyway if there is a temporary problem with the server,
                        # normal parse won't work
                        pass

                try:
                    with db:
                        # List the fake block.
                        cursor.execute(
                            """INSERT INTO blocks(
                                            block_index,
                                            block_hash,
                                            block_time) VALUES(?,?,?)""",
                            (config.MEMPOOL_BLOCK_INDEX, config.MEMPOOL_BLOCK_HASH, curr_time),
                        )

                        tx_hex = raw_transactions[tx_hash]
                        if tx_hex is None:
                            logger.debug(
                                "tx_hash %s not found in backend.  Not adding to mempool.",
                                (tx_hash,),
                            )
                            raise MempoolError
                        mempool_tx_index = list_tx(
                            db,
                            None,
                            block_index,
                            curr_time,
                            tx_hash,
                            tx_index=mempool_tx_index,
                            tx_hex=tx_hex,
                        )

                        # Parse transaction.
                        cursor.execute(
                            """SELECT * FROM transactions WHERE tx_hash = ?""", (tx_hash,)
                        )
                        transactions = list(cursor)
                        if transactions:
                            assert len(transactions) == 1
                            transaction = transactions[0]
                            supported = parse_tx(db, transaction)
                            if not supported:
                                not_supported[tx_hash] = ""
                                not_supported_sorted.append((block_index, tx_hash))
                        else:
                            # If a transaction hasn’t been added to the
                            # table `transactions`, then it’s not a
                            # Counterparty transaction.
                            not_supported[tx_hash] = ""
                            not_supported_sorted.append((block_index, tx_hash))
                            raise MempoolError

                        # Save transaction and side‐effects in memory.
                        cursor.execute(
                            """SELECT * FROM messages WHERE block_index = ?""",
                            (config.MEMPOOL_BLOCK_INDEX,),
                        )
                        for message in list(cursor):
                            xcp_mempool.append((tx_hash, message))

                        # Rollback.
                        raise MempoolError
                except exceptions.ParseTransactionError as e:
                    logger.warning(f"ParseTransactionError for tx {tx_hash}: {e}")
                except MempoolError:
                    pass

                parsed_txs_count = parsed_txs_count + 1

            if parsed_txs_count < len(parse_txs):
                continue  # if parse didn't finish is an interruption
            else:
                if len(parse_txs) > 1000:
                    logger.info("Mempool parsing finished")

            # Re‐write mempool messages to database.
            with db:
                cursor.execute("""DELETE FROM mempool""")
                for message in xcp_mempool:
                    tx_hash, new_message = message
                    new_message["tx_hash"] = tx_hash
                    cursor.execute(
                        """INSERT INTO mempool VALUES(:tx_hash, :command, :category, :bindings, :timestamp)""",
                        new_message,
                    )

            elapsed_time = time.time() - start_time
            sleep_time = (
                config.BACKEND_POLL_INTERVAL - elapsed_time
                if elapsed_time <= config.BACKEND_POLL_INTERVAL
                else 0
            )

            logger.getChild("mempool").debug(
                f"Refresh mempool: {len(xcp_mempool)} XCP txs seen, out of {len(raw_mempool)} total entries (took {elapsed_time:.2f}, next refresh in {sleep_time:.2f})"
            )

            # Wait
            db.wal_checkpoint(mode=apsw.SQLITE_CHECKPOINT_PASSIVE)
            time.sleep(sleep_time)

    cursor.close()
