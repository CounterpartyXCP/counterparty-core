"""
Initialise database.

Sieve blockchain for Counterparty transactions, and add them to the database.
"""

import binascii
import decimal
import logging
import os
import struct
import sys
import time
from datetime import timedelta

from counterpartycore.lib import (
    backend,
    config,
    exceptions,
    ledger,
)
from counterpartycore.lib.backend import rsfetcher
from counterpartycore.lib.cli import log
from counterpartycore.lib.ledger.currentstate import CurrentState
from counterpartycore.lib.messages import (
    attach,
    bet,
    broadcast,
    btcpay,
    burn,
    cancel,
    destroy,
    detach,
    dispense,
    dispenser,
    dividend,
    fairmint,
    fairminter,
    issuance,
    move,
    order,
    rps,
    rpsresolve,
    send,
    sweep,
    utxo,
)
from counterpartycore.lib.messages.versions import enhancedsend, mpma
from counterpartycore.lib.parser import check, deserialize, messagetype, protocol
from counterpartycore.lib.parser.gettxinfo import get_tx_info
from counterpartycore.lib.utils import database, helpers

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
    "fairminters",
    "fairmints",
    "transaction_count",
]


def update_transaction(db, tx, supported):
    ledger.events.add_to_journal(
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
        cursor = db.cursor()
        cursor.execute(
            """UPDATE transactions \
                            SET supported=$supported \
                            WHERE tx_hash=$tx_hash""",
            {"supported": False, "tx_hash": tx["tx_hash"]},
        )
        if tx["block_index"] != config.MEMPOOL_BLOCK_INDEX:
            logger.info(f"Unsupported transaction: hash {tx['tx_hash']}; data {tx['data']}")
        cursor.close()


def parse_tx(db, tx):
    CurrentState().set_current_tx_hash(tx["tx_hash"])
    """Parse the transaction, return True for success."""
    cursor = db.cursor()

    supported = True
    moved = False

    try:
        with db:
            if tx["data"] and len(tx["data"]) > 1:
                try:
                    message_type_id, message = messagetype.unpack(tx["data"], tx["block_index"])
                except struct.error:  # Deterministically raised.
                    message_type_id = None
                    message = None
            else:
                message_type_id = None
                message = None

            # After "spend_utxo_to_detach" protocol change we move assets before parsing
            # only if the message is not an Attach or Detach, else will be moved after parsing
            if not protocol.enabled("spend_utxo_to_detach") or message_type_id not in [
                attach.ID,
                detach.ID,
            ]:
                moved = move.move_assets(db, tx)

            if (
                not tx["source"]
                or len(tx["source"].split("-")) > 1
                or (tx["destination"] and len(tx["destination"].split("-")) > 1)
            ):
                return

            # Burns.
            if tx["destination"] == config.UNSPENDABLE:
                burn.parse(db, tx)
                return

            # Protocol change.
            rps_enabled = protocol.after_block_or_test_network(tx["block_index"], 308500)

            if message_type_id == send.ID:
                send.parse(db, tx, message)
            elif message_type_id == enhancedsend.ID and protocol.enabled(
                "enhanced_sends", block_index=tx["block_index"]
            ):
                enhancedsend.parse(db, tx, message)
            elif message_type_id == mpma.ID and protocol.enabled(
                "mpma_sends", block_index=tx["block_index"]
            ):
                mpma.parse(db, tx, message)
            elif message_type_id == order.ID:
                order.parse(db, tx, message)
            elif message_type_id == btcpay.ID:
                btcpay.parse(db, tx, message)
            elif message_type_id == issuance.ID or (
                protocol.enabled("issuance_backwards_compatibility", block_index=tx["block_index"])
                and message_type_id == issuance.LR_ISSUANCE_ID
            ):
                issuance.parse(db, tx, message, message_type_id)
            elif (
                message_type_id == issuance.SUBASSET_ID
                and protocol.enabled("subassets", block_index=tx["block_index"])
            ) or (
                protocol.enabled("issuance_backwards_compatibility", block_index=tx["block_index"])
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
            elif message_type_id == destroy.ID and protocol.enabled(
                "destroy_reactivated", block_index=tx["block_index"]
            ):
                destroy.parse(db, tx, message)
            elif message_type_id == sweep.ID and protocol.enabled(
                "sweep_send", block_index=tx["block_index"]
            ):
                sweep.parse(db, tx, message)
            elif message_type_id == dispenser.ID and protocol.enabled(
                "dispensers", block_index=tx["block_index"]
            ):
                dispenser.parse(db, tx, message)
            elif message_type_id == dispenser.DISPENSE_ID and protocol.enabled(
                "dispensers", block_index=tx["block_index"]
            ):
                dispense.parse(db, tx)
            elif message_type_id == fairminter.ID and protocol.enabled(
                "fairminter", block_index=tx["block_index"]
            ):
                fairminter.parse(db, tx, message)
            elif message_type_id == fairmint.ID and protocol.enabled(
                "fairminter", block_index=tx["block_index"]
            ):
                fairmint.parse(db, tx, message)
            elif (
                message_type_id == utxo.ID
                and protocol.enabled("utxo_support", block_index=tx["block_index"])
                and not protocol.enabled("spend_utxo_to_detach")
            ):
                utxo.parse(db, tx, message)
            elif message_type_id == attach.ID and protocol.enabled("spend_utxo_to_detach"):
                attach.parse(db, tx, message)
            elif message_type_id == detach.ID and protocol.enabled("spend_utxo_to_detach"):
                detach.parse(db, tx, message)
            else:
                supported = False

            # if attach or detach we move assets after parsing
            if protocol.enabled("spend_utxo_to_detach") and message_type_id == attach.ID:
                moved = move.move_assets(db, tx)

    except Exception as e:
        raise exceptions.ParseTransactionError(f"{e}") from e
    finally:
        cursor.close()
        supported = supported or moved
        update_transaction(db, tx, supported)
        CurrentState().set_current_tx_hash(None)

    return supported


def replay_transactions_events(db, transactions):
    cursor = db.cursor()
    for tx in transactions:
        CurrentState().set_current_tx_hash(tx["tx_hash"])
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
            "utxos_info": tx["utxos_info"],
            "transaction_type": tx["transaction_type"],
        }
        ledger.events.add_to_journal(
            db,
            tx["block_index"],
            "insert",
            "transactions",
            "NEW_TRANSACTION",
            transaction_bindings,
        )
        dispensers_outs = cursor.execute(
            "SELECT * FROM transaction_outputs WHERE tx_index = ? ORDER BY rowid",
            (tx["tx_index"],),
        ).fetchall()
        for next_out in dispensers_outs:
            transaction_outputs_bindings = {
                "tx_index": tx["tx_index"],
                "tx_hash": tx["tx_hash"],
                "block_index": tx["block_index"],
                "out_index": next_out["out_index"],
                "destination": next_out["destination"],
                "btc_amount": next_out["btc_amount"],
            }
            ledger.events.add_to_journal(
                db,
                tx["block_index"],
                "insert",
                "transaction_outputs",
                "NEW_TRANSACTION_OUTPUT",
                transaction_outputs_bindings,
            )
        CurrentState().set_current_tx_hash(None)


def parse_block(
    db,
    block_index,
    block_time,
    previous_ledger_hash=None,
    previous_txlist_hash=None,
    previous_messages_hash=None,
    reparsing=False,
):
    """Parse the block, return hash of new ledger, txlist and messages.

    The unused arguments `ledger_hash` and `txlist_hash` are for the test suite.
    """

    # Get block transactions
    cursor = db.cursor()
    cursor.execute(
        """SELECT * FROM transactions \
                      WHERE block_index=$block_index ORDER BY tx_index""",
        {"block_index": block_index},
    )
    transactions = cursor.fetchall()

    # Add manual event to journal because transaction already exists
    if reparsing:
        replay_transactions_events(db, transactions)

    ledger.currentstate.ConsensusHashBuilder().reset()

    if block_index != config.MEMPOOL_BLOCK_INDEX:
        assert block_index == CurrentState().current_block_index()

    # Expire orders, bets and rps.
    order.expire(db, block_index)
    bet.expire(db, block_index, block_time)
    rps.expire(db, block_index)

    # Close dispensers
    dispenser.close_pending(db, block_index)

    # Fairminters operations
    fairminter.before_block(db, block_index)

    txlist = []
    for tx in transactions:
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

    # Fairminters operations
    fairminter.after_block(db, block_index)

    if block_index != config.MEMPOOL_BLOCK_INDEX:
        # Calculate consensus hashes.
        new_txlist_hash, found_txlist_hash = check.consensus_hash(
            db, "txlist_hash", previous_txlist_hash, txlist
        )
        new_ledger_hash, found_ledger_hash = check.consensus_hash(
            db,
            "ledger_hash",
            previous_ledger_hash,
            ledger.currentstate.ConsensusHashBuilder().block_ledger(),
        )
        new_messages_hash, found_messages_hash = check.consensus_hash(
            db,
            "messages_hash",
            previous_messages_hash,
            ledger.currentstate.ConsensusHashBuilder().block_journal(),
        )

        update_block_query = """
            UPDATE blocks
            SET
                txlist_hash=:txlist_hash,
                ledger_hash=:ledger_hash,
                messages_hash=:messages_hash,
                transaction_count=:transaction_count
            WHERE block_index=:block_index
        """
        update_block_bindings = {
            "txlist_hash": new_txlist_hash,
            "ledger_hash": new_ledger_hash,
            "messages_hash": new_messages_hash,
            "transaction_count": len(transactions),
            "block_index": block_index,
        }
        cursor.execute(update_block_query, update_block_bindings)

        # trigger BLOCK_PARSED event
        ledger.events.add_to_journal(
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
                "transaction_count": len(transactions),
            },
        )

        cursor.close()

        return new_ledger_hash, new_txlist_hash, new_messages_hash

    cursor.close()
    return None, None, None


def list_tx(db, block_hash, block_index, block_time, tx_hash, tx_index, decoded_tx):
    assert type(tx_hash) == str  # noqa: E721
    CurrentState().set_current_tx_hash(tx_hash)
    cursor = db.cursor()

    source, destination, btc_amount, fee, data, dispensers_outs, utxos_info = get_tx_info(
        db, decoded_tx, block_index
    )

    # For mempool
    if block_hash is None or block_hash == config.MEMPOOL_BLOCK_HASH:
        block_hash = config.MEMPOOL_BLOCK_HASH
        block_index = config.MEMPOOL_BLOCK_INDEX
        existing_tx = ledger.blocks.get_transaction(db, tx_hash)
        if existing_tx:
            CurrentState().set_current_tx_hash(None)
            return tx_index
    else:
        assert block_index == CurrentState().current_block_index()

    if (
        (
            source
            and (data or destination == config.UNSPENDABLE or dispensers_outs)  # counterparty tx
        )
        or (
            len(utxos_info) > 0
            and utxos_info[0] != ""
            and protocol.enabled(
                "spend_utxo_to_detach"
            )  # utxo move or detach with a single OP_RETURN
        )
        or (len(utxos_info) > 1 and utxos_info[0] != "" and utxos_info[1] != "")
    ):
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
            "utxos_info": " ".join(utxos_info),
            "transaction_type": messagetype.get_transaction_type(
                data, destination, utxos_info, block_index
            ),
        }
        ledger.events.insert_record(db, "transactions", transaction_bindings, "NEW_TRANSACTION")

        if dispensers_outs:
            for next_out in dispensers_outs:
                transaction_outputs_bindings = {
                    "tx_index": tx_index,
                    "tx_hash": tx_hash,
                    "block_index": block_index,
                    "out_index": next_out["out_index"],
                    "destination": next_out["destination"],
                    "btc_amount": next_out["btc_amount"],
                }
                ledger.events.insert_record(
                    db,
                    "transaction_outputs",
                    transaction_outputs_bindings,
                    "NEW_TRANSACTION_OUTPUT",
                )

        cursor.close()

        return tx_index + 1
    else:
        pass
    CurrentState().set_current_tx_hash(None)
    return tx_index


def clean_table_from(cursor, table, block_index):
    logger.debug(f"Rolling back table `{table}`...")
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
        cursor.execute(f"DROP TABLE IF EXISTS {table}")  # nosec B608
    cursor.execute("""PRAGMA foreign_keys=ON""")
    with open(
        os.path.join(config.LEDGER_DB_MIGRATIONS_DIR, "0001.initial_migration.sql"), "r"
    ) as sql_file:
        db.execute(sql_file.read())


def rollback(db, block_index=0, force=False):
    if not force and block_index > CurrentState().current_block_index():
        logger.debug("Block index is higher than current block index. No need to reparse.")
        return
    block_index = max(block_index, config.BLOCK_FIRST)
    # clean all tables
    step = f"Rolling Ledger DB back to block {block_index}..."
    done_message = f"Ledger DB rolled back to block {block_index} ({{}}s)"
    with log.Spinner(step, done_message):
        if block_index == config.BLOCK_FIRST:
            rebuild_database(db)
        else:
            clean_messages_tables(db, block_index=block_index)
            cursor = db.cursor()
            clean_transactions_tables(cursor, block_index=block_index)
            cursor.close()
    CurrentState().set_current_block_index(block_index - 1)


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
    current_block = f"Block {block['block_index']} parsed in {block_parsing_duration:.2f}s"
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
    if block_index > CurrentState().current_block_index():
        logger.debug("Block index is higher than current block index. No need to reparse.")
        return
    cursor = db.cursor()
    # clean all tables except assets' blocks', 'transaction_outputs' and 'transactions'
    with log.Spinner(f"Rolling database back to block {block_index}..."):
        clean_messages_tables(db, block_index=block_index)

    step = "Recalculating consensus hashes..."
    with log.Spinner("Recalculating consensus hashes..."):
        query = """
            UPDATE blocks
            SET ledger_hash=NULL, txlist_hash=NULL, messages_hash=NULL
            WHERE block_index >= ?
        """
        cursor.execute(query, (block_index,))

    # reparse blocks
    start_time_all_blocks_parse = time.time()
    block_parsed_count = 0
    count_query = "SELECT COUNT(*) AS cnt FROM blocks WHERE block_index >= ?"
    block_count = cursor.execute(count_query, (block_index,)).fetchone()["cnt"]
    step = f"Reparsing blocks from block {block_index}..."
    message = ""
    with log.Spinner(step) as spinner:
        cursor.execute(
            """SELECT * FROM blocks WHERE block_index >= ? ORDER BY block_index""",
            (block_index,),
        )
        for block in cursor.fetchall():
            start_time_block_parse = time.time()
            CurrentState().set_current_block_index(block["block_index"])

            # Add event manually to journal because block already exists
            ledger.events.add_to_journal(
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
            previous_ledger_hash = None
            previous_txlist_hash = None
            previous_messages_hash = None
            if CurrentState().current_block_index() > config.BLOCK_FIRST:
                previous_block = ledger.blocks.get_block(db, block["block_index"] - 1)
                previous_ledger_hash = previous_block["ledger_hash"]
                previous_txlist_hash = previous_block["txlist_hash"]
                previous_messages_hash = previous_block["messages_hash"]
            parse_block(
                db,
                block["block_index"],
                block["block_time"],
                previous_ledger_hash=previous_ledger_hash,
                previous_txlist_hash=previous_txlist_hash,
                previous_messages_hash=previous_messages_hash,
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
            spinner.set_messsage(message)
            spinner.done_message = str(block_parsed_count) + " blocks reparsed in {:.2f}s."


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


def handle_reorg(db):
    # search last block with the correct hash
    previous_block_index = CurrentState().current_block_index() - 1
    while True:
        previous_block_hash = backend.bitcoind.getblockhash(previous_block_index)

        try:
            current_block_hash = backend.bitcoind.getblockhash(previous_block_index + 1)
        except exceptions.BlockOutOfRange:
            # current block is not in the blockchain
            logger.debug(f"Current block is not in the blockchain ({previous_block_index + 1}).")
            previous_block_index -= 1
            continue

        if previous_block_hash != ledger.blocks.get_block_hash(db, previous_block_index):
            # hashes don't match
            logger.debug(f"Hashes don't match ({previous_block_index}).")
            previous_block_index -= 1
            continue

        break

    # rollback to the previous block
    current_block_index = previous_block_index + 1
    rollback(db, block_index=current_block_index)
    CurrentState().set_current_block_index(previous_block_index)

    # get the new deserialized current block
    current_block = deserialize.deserialize_block(
        backend.bitcoind.getblock(current_block_hash),
        parse_vouts=True,
        block_index=current_block_index,
    )

    return current_block


def parse_new_block(db, decoded_block, tx_index=None):
    start_time = time.time()

    # increment block index
    CurrentState().set_current_block_index(CurrentState().current_block_index() + 1)

    # get next tx index if not provided
    if tx_index is None:
        tx_index = get_next_tx_index(db)

    if CurrentState().current_block_index() == config.BLOCK_FIRST:
        previous_block = {
            "ledger_hash": None,
            "txlist_hash": None,
            "messages_hash": None,
            "block_index": config.BLOCK_FIRST - 1,
        }
    else:
        # get previous block
        previous_block = ledger.blocks.get_block(db, CurrentState().current_block_index() - 1)
        # check if reorg is needed
        if decoded_block["hash_prev"] != previous_block["block_hash"]:
            logger.warning(
                "Blockchain reorganization detected at block %s.",
                CurrentState().current_block_index(),
            )
            new_current_block = handle_reorg(db)
            return parse_new_block(db, new_current_block)

    # Sanity checks
    if decoded_block["block_index"] != config.BLOCK_FIRST:
        assert previous_block["ledger_hash"] is not None
        assert previous_block["txlist_hash"] is not None
    assert previous_block["block_index"] == decoded_block["block_index"] - 1

    with db:  # ensure all the block or nothing
        logger.info(f"Block {decoded_block['block_index']}", extra={"bold": True})
        # insert block
        block_bindings = {
            "block_index": decoded_block["block_index"],
            "block_hash": decoded_block["block_hash"],
            "block_time": decoded_block["block_time"],
            "previous_block_hash": decoded_block["hash_prev"],
            "difficulty": decoded_block["bits"],
        }
        ledger.events.insert_record(db, "blocks", block_bindings, "NEW_BLOCK")

        # save transactions
        for transaction in decoded_block["transactions"]:
            tx_index = list_tx(
                db,
                decoded_block["block_hash"],
                decoded_block["block_index"],
                decoded_block["block_time"],
                transaction["tx_hash"],
                tx_index,
                decoded_tx=transaction,
            )
        # Parse the transactions in the block.
        new_ledger_hash, new_txlist_hash, new_messages_hash = parse_block(
            db,
            decoded_block["block_index"],
            decoded_block["block_time"],
            previous_ledger_hash=previous_block["ledger_hash"],
            previous_txlist_hash=previous_block["txlist_hash"],
            previous_messages_hash=previous_block["messages_hash"],
        )

        duration = time.time() - start_time

        log_message = "Block %(block_index)s - Parsing complete. L: %(ledger_hash)s, TX: %(txlist_hash)s, M: %(messages_hash)s (%(duration).2fs)"
        logger.info(
            log_message,
            {
                "block_index": decoded_block["block_index"],
                "ledger_hash": new_ledger_hash,
                "txlist_hash": new_txlist_hash,
                "messages_hash": new_messages_hash,
                "duration": duration,
            },
        )

    return tx_index, decoded_block["block_index"]


def rollback_empty_block(db):
    cursor = db.cursor()
    cursor.execute("""
        SELECT block_index FROM blocks 
        WHERE ledger_hash IS NULL 
        ORDER BY block_index ASC
        LIMIT 1
    """)
    block = cursor.fetchone()
    if block:
        logger.warning(
            f"Ledger hashes are empty from block {block['block_index']}. Rolling back..."
        )
        rollback(db, block_index=block["block_index"], force=True)


def check_database_version(db):
    # Update version if new database.
    if CurrentState().current_block_index() <= config.BLOCK_FIRST:
        database.update_version(db)
        return
    try:
        check.database_version(db)
    except exceptions.VersionError as e:
        logger.info(str(e))
        # rollback or reparse the database
        if e.required_action == "rollback":
            rollback(db, block_index=e.from_block_index)
        elif e.required_action == "reparse":
            reparse(db, block_index=e.from_block_index)
        # refresh the current block index
        CurrentState().set_current_block_index(ledger.blocks.last_db_index(db))
        # update the database version
        database.update_version(db)


def start_rsfetcher():
    fetcher = rsfetcher.RSFetcher()
    try:
        fetcher.start(CurrentState().current_block_index() + 1)
    except exceptions.InvalidVersion as e:
        logger.error(e)
        sys.exit(1)
    except Exception:
        logger.warning("Failed to start RSFetcher. Retrying in 5 seconds...")
        time.sleep(5)
        return start_rsfetcher()
    return fetcher


def catch_up(db, check_asset_conservation=True):
    logger.info("Catching up...")

    fetcher = None

    try:
        CurrentState().set_block_parser_status("catching up")
        # update the current block index
        current_block_index = ledger.blocks.last_db_index(db)
        if current_block_index == 0:
            logger.info("New database.")
            current_block_index = config.BLOCK_FIRST - 1
        CurrentState().set_current_block_index(current_block_index)

        # Get block count.
        block_count = backend.bitcoind.getblockcount()

        # Wait for bitcoind to catch up at least one block after CurrentState().current_block_index()
        if (
            backend.bitcoind.get_blocks_behind() > 0
            and block_count <= CurrentState().current_block_index()
        ):
            backend.bitcoind.wait_for_block(CurrentState().current_block_index() + 1)
            block_count = backend.bitcoind.getblockcount()

        # Get index of last transaction.
        tx_index = get_next_tx_index(db)

        start_time = time.time()
        parsed_blocks = 0

        while CurrentState().current_block_index() < block_count:
            # Get block information and transactions
            fetch_time_start = time.time()
            if fetcher is None:
                fetcher = start_rsfetcher()

            retry = 0
            decoded_block = fetcher.get_block()
            while decoded_block is None:
                retry += 1
                if retry > 5:
                    raise exceptions.RSFetchError("RSFetcher returned None too many times.")
                logger.warning("RSFetcher returned None. Trying again in 5 seconds...")
                time.sleep(5)
                fetcher.stop()
                fetcher = start_rsfetcher()
                decoded_block = fetcher.get_block()

            block_height = decoded_block.get("height")
            fetch_time_end = time.time()
            fetch_duration = fetch_time_end - fetch_time_start
            logger.debug(f"Block {block_height} fetched. ({fetch_duration:.6f}s)")

            # Check for gaps in the blockchain
            assert block_height <= CurrentState().current_block_index() + 1

            # Parse the current block
            tx_index, parsed_block_index = parse_new_block(db, decoded_block, tx_index=tx_index)
            # check if the parsed block is the expected one
            # if not that means a reorg happened
            if parsed_block_index < block_height:
                fetcher.stop()
                fetcher = start_rsfetcher()
            else:
                assert parsed_block_index == block_height

            parsed_blocks += 1
            formatted_duration = helpers.format_duration(time.time() - start_time)
            logger.debug(
                f"Block {CurrentState().current_block_index()}/{block_count} parsed, for {parsed_blocks} blocks in {formatted_duration}."
            )

            # Refresh block count.
            if CurrentState().current_block_index() == block_count:
                # if bitcoind is catching up, wait for the next block
                if backend.bitcoind.get_blocks_behind() > 0:
                    backend.bitcoind.wait_for_block(CurrentState().current_block_index() + 1)
                block_count = backend.bitcoind.getblockcount()
    finally:
        if fetcher is not None:
            fetcher.stop()

    logger.info("Catch up complete.")


def reset_rust_fetcher_database():
    rsfetcher.delete_database_directory()
