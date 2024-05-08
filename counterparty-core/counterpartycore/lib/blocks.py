"""
Initialise database.

Sieve blockchain for Counterparty transactions, and add them to the database.
"""

import binascii
import csv  # noqa: E402
import decimal
import logging  # noqa: E402
import os
import struct
import time
from datetime import timedelta

from halo import Halo  # noqa: E402
from termcolor import colored  # noqa: E402

from counterpartycore.lib import (  # noqa: E402
    backend,
    check,
    config,
    database,
    exceptions,
    ledger,
    message_type,
    prefetcher,
    util,
)
from counterpartycore.lib.gettxinfo import get_tx_info  # noqa: E402
from counterpartycore.lib.kickstart import blocks_parser
from counterpartycore.lib.kickstart.blocks_parser import BlockchainParser  # noqa: E402

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

D = decimal.Decimal
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
    util.CURRENT_TX_HASH = tx["tx_hash"]
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
            elif message_type_id == enhanced_send.ID and util.enabled(
                "enhanced_sends", block_index=tx["block_index"]
            ):
                enhanced_send.parse(db, tx, message)
            elif message_type_id == mpma.ID and util.enabled(
                "mpma_sends", block_index=tx["block_index"]
            ):
                mpma.parse(db, tx, message)
            elif message_type_id == order.ID:
                order.parse(db, tx, message)
            elif message_type_id == btcpay.ID:
                btcpay.parse(db, tx, message)
            elif message_type_id == issuance.ID or (
                util.enabled("issuance_backwards_compatibility", block_index=tx["block_index"])
                and message_type_id == issuance.LR_ISSUANCE_ID
            ):
                issuance.parse(db, tx, message, message_type_id)
            elif (
                message_type_id == issuance.SUBASSET_ID
                and util.enabled("subassets", block_index=tx["block_index"])
            ) or (
                util.enabled("issuance_backwards_compatibility", block_index=tx["block_index"])
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
            elif message_type_id == destroy.ID and util.enabled(
                "destroy_reactivated", block_index=tx["block_index"]
            ):
                destroy.parse(db, tx, message)
            elif message_type_id == sweep.ID and util.enabled(
                "sweep_send", block_index=tx["block_index"]
            ):
                sweep.parse(db, tx, message)
            elif message_type_id == dispenser.ID and util.enabled(
                "dispensers", block_index=tx["block_index"]
            ):
                dispenser.parse(db, tx, message)
            elif message_type_id == dispenser.DISPENSE_ID and util.enabled(
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
        util.CURRENT_TX_HASH = None


def parse_block(
    db,
    block_index,
    block_time,
    previous_ledger_hash=None,
    ledger_hash=None,
    previous_txlist_hash=None,
    txlist_hash=None,
    previous_messages_hash=None,
    reparsing=False,
):
    """Parse the block, return hash of new ledger, txlist and messages.

    The unused arguments `ledger_hash` and `txlist_hash` are for the test suite.
    """

    ledger.BLOCK_LEDGER = []
    ledger.BLOCK_JOURNAL = []

    if block_index != config.MEMPOOL_BLOCK_INDEX:
        assert block_index == util.CURRENT_BLOCK_INDEX

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
            # Add manual event to journal because transaction already exists
            if reparsing:
                transaction_bindings = {
                    "tx_index": tx["tx_index"],
                    "tx_hash": tx["tx_hash"],
                    "block_index": tx["block_index"],
                    "block_hash": tx["block_hash"],
                    "block_time": tx["block_time"],
                    "source": tx["source"],
                    "destination": tx["destination"],
                    "btc_amount": tx["btc_amount"],
                    "fee": tx["fee"],
                    "data": tx["data"],
                }
                ledger.add_to_journal(
                    db,
                    block_index,
                    "insert",
                    "transactions",
                    "NEW_TRANSACTION",
                    transaction_bindings,
                )
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

    if block_index != config.MEMPOOL_BLOCK_INDEX:
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
        # trigger BLOCK_PARSED event
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

    return None, None, None, None


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
            ["block_index"],
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
            ["block_index"],
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
                      event TEXT,
                      tx_hash TEXT)
                  """)
    columns = [column["name"] for column in cursor.execute("""PRAGMA table_info(messages)""")]
    if "event" not in columns:
        cursor.execute("""ALTER TABLE messages ADD COLUMN event TEXT""")
    if "tx_hash" not in columns:
        cursor.execute("""ALTER TABLE messages ADD COLUMN tx_hash TEXT""")

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

    # Mempool events
    cursor.execute("""CREATE TABLE IF NOT EXISTS mempool(
                      tx_hash TEXT,
                      command TEXT,
                      category TEXT,
                      bindings TEXT,
                      timestamp INTEGER,
                      event TEXT)
                  """)
    columns = [column["name"] for column in cursor.execute("""PRAGMA table_info(mempool)""")]
    if "event" not in columns:
        cursor.execute("""ALTER TABLE mempool ADD COLUMN event TEXT""")

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
    if block_hash is None or block_hash == config.MEMPOOL_BLOCK_HASH:
        block_hash = config.MEMPOOL_BLOCK_HASH
        block_index = config.MEMPOOL_BLOCK_INDEX
    else:
        assert block_index == util.CURRENT_BLOCK_INDEX

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
    util.CURRENT_BLOCK_INDEX = block_index - 1
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
    cursor = db.cursor()
    # clean all tables except assets' blocks', 'transaction_outputs' and 'transactions'
    step = f"Rolling database back to block {block_index}..."
    with Halo(text=step, spinner=SPINNER_STYLE):
        clean_messages_tables(db, block_index=block_index)
    print(f"{OK_GREEN} {step}")

    step = "Cleaning consensus hashes..."
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
    message = ""
    with Halo(text=step, spinner=SPINNER_STYLE) as spinner:
        cursor.execute(
            """SELECT * FROM blocks WHERE block_index >= ? ORDER BY block_index""", (block_index,)
        )
        for block in cursor.fetchall():
            start_time_block_parse = time.time()
            util.CURRENT_BLOCK_INDEX = block["block_index"]
            # Add event manually to journal because block already exists
            ledger.add_to_journal(
                db,
                block["block_index"],
                "insert",
                "blocks",
                "NEW_BLOCK",
                {
                    "block_index": block["block_index"],
                    "block_hash": block["block_hash"],
                    "block_time": block["block_time"],
                    "previous_block_hash": block["previous_block_hash"],
                    "difficulty": block["difficulty"],
                },
            )
            previous_block = ledger.get_block(db, block["block_index"] - 1)
            parse_block(
                db,
                block["block_index"],
                block["block_time"],
                previous_ledger_hash=previous_block["ledger_hash"],
                previous_txlist_hash=previous_block["txlist_hash"],
                previous_messages_hash=previous_block["messages_hash"],
                reparsing=True,
            )
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


def parse_new_block(db, decoded_block, block_parser=None, tx_index=None):
    util.CURRENT_BLOCK_INDEX = decoded_block["block_index"]

    # get next tx index if not provided
    if tx_index is None:
        tx_index = get_next_tx_index(db)

    # get previous block
    previous_block = ledger.get_block(db, decoded_block["block_index"] - 1)

    # check if reorg is needed
    if decoded_block["hash_prev"] != previous_block["block_hash"]:
        previous_block = ledger.get_block_by_hash(db, decoded_block["hash_prev"])
        if previous_block is None:
            raise exceptions.BlockNotFoundError(
                f"Previous block hash {decoded_block['hash_prev']} not found"
            )
        logger.info(
            "Blockchain reorganization detected from block %s", decoded_block["block_index"]
        )
        new_block_index = previous_block["block_index"] + 1
        # roolback to the previous block
        rollback(db, block_index=new_block_index)
        # update the current block index
        util.CURRENT_BLOCK_INDEX = new_block_index
        decoded_block["block_index"] = new_block_index

    with db:  # ensure all the block or nothing
        # insert block
        block_bindings = {
            "block_index": decoded_block["block_index"],
            "block_hash": decoded_block["block_hash"],
            "block_time": decoded_block["block_time"],
            "previous_block_hash": decoded_block["hash_prev"],
            "difficulty": decoded_block["bits"],
        }
        ledger.insert_record(db, "blocks", block_bindings, "NEW_BLOCK")

        # save transactions
        for transaction in decoded_block["transactions"]:
            # for kickstart
            if block_parser is not None:
                # Cache transaction. We do that here because the block is fetched by another process.
                block_parser.put_in_cache(transaction)
            # update transaction cache first time we see the transaction
            backend.BLOCKCHAIN_CACHE[transaction["tx_hash"]] = transaction
            tx_index = list_tx(
                db,
                decoded_block["block_hash"],
                decoded_block["block_index"],
                decoded_block["block_time"],
                transaction["tx_hash"],
                tx_index,
                decoded_tx=transaction,
                block_parser=block_parser,
            )
        # Parse the transactions in the block.
        parse_block(
            db,
            decoded_block["block_index"],
            decoded_block["block_time"],
            previous_ledger_hash=previous_block["ledger_hash"],
            previous_txlist_hash=previous_block["txlist_hash"],
            previous_messages_hash=previous_block["messages_hash"],
        )

    return tx_index


def get_decoded_block(block_index):
    if block_index in backend.BLOCKCHAIN_CACHE:
        block = backend.BLOCKCHAIN_CACHE[block_index]
        del backend.BLOCKCHAIN_CACHE[block_index]
        return block

    block_hash = backend.getblockhash(block_index)
    raw_block = backend.getrawblock(block_hash)
    block = blocks_parser.BlockchainParser().deserialize_block(raw_block)
    return block


def check_versions(db):
    # Check software version.
    check.software_version()

    # Check database version.
    if util.CURRENT_BLOCK_INDEX <= config.BLOCK_FIRST:
        database.update_version(db)
        return
    try:
        check.database_version(db)
    except check.DatabaseVersionError as e:
        logger.info(str(e))
        # rollback or reparse the database
        if e.required_action == "rollback":
            rollback(db, block_index=e.from_block_index)
        elif e.required_action == "reparse":
            reparse(db, block_index=e.from_block_index)
        # refresh the current block index
        util.CURRENT_BLOCK_INDEX = last_db_index(db)
        # update the database version
        database.update_version(db)


def catch_up(db, check_asset_conservation=True):
    # update the current block index
    util.CURRENT_BLOCK_INDEX = last_db_index(db)
    if util.CURRENT_BLOCK_INDEX == 0:
        logger.info("New database.")
        util.CURRENT_BLOCK_INDEX = config.BLOCK_FIRST

    # Get block count.
    block_count = backend.getblockcount()

    # If we're far behind, start Prefetcher.
    if util.CURRENT_BLOCK_INDEX <= block_count - 2000:
        prefetcher.start_all(NUM_PREFETCHER_THREADS)

    # Get index of last transaction.
    tx_index = get_next_tx_index(db)

    while util.CURRENT_BLOCK_INDEX < block_count:
        print(f"Block {util.CURRENT_BLOCK_INDEX}/{block_count}")
        # increment block index
        util.CURRENT_BLOCK_INDEX = util.CURRENT_BLOCK_INDEX + 1

        # Get block information and transactions
        decoded_block = get_decoded_block(util.CURRENT_BLOCK_INDEX)
        decoded_block["block_index"] = util.CURRENT_BLOCK_INDEX
        tx_index = parse_new_block(db, decoded_block, block_parser=None, tx_index=tx_index)

        # Refresh block count.
        block_count = backend.getblockcount()

    if config.CHECK_ASSET_CONSERVATION and check_asset_conservation:
        # TODO: timer to check asset conservation every N hours
        check.asset_conservation(db)
        # catch up new blocks during asset conservation check
        catch_up(db, check_asset_conservation=False)

    logger.info("Catch up done.")
