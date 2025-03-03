import json
import logging
import time

from counterpartycore.lib import backend, config, exceptions, ledger
from counterpartycore.lib.api.apiwatcher import EVENTS_ADDRESS_FIELDS
from counterpartycore.lib.ledger.currentstate import CurrentState
from counterpartycore.lib.parser import blocks, deserialize

logger = logging.getLogger(config.LOGGER_NAME)


def parse_mempool_transactions(db, raw_tx_list, timestamps=None):
    CurrentState().set_parsing_mempool(True)

    logger.trace(f"Parsing {len(raw_tx_list)} raw transaction(s) from the mempool...")
    now = time.time()
    transaction_events = []
    mempool_transactions = []
    cursor = db.cursor()
    not_supported_txs = []
    try:
        with db:
            # insert fake block
            cursor.execute(
                """INSERT INTO blocks(
                                block_index,
                                block_hash,
                                block_time) VALUES(?,?,?)""",
                (config.MEMPOOL_BLOCK_INDEX, config.MEMPOOL_BLOCK_HASH, now),
            )
            # get the last tx_index
            cursor.execute(
                "SELECT tx_index FROM mempool_transactions ORDER BY tx_index DESC LIMIT 1"
            )
            last_mempool_tx = cursor.fetchone()
            if last_mempool_tx:
                last_mempool_tx_index = last_mempool_tx["tx_index"] + 1
            else:
                last_mempool_tx_index = 1

            cursor.execute("SELECT tx_index FROM transactions ORDER BY tx_index DESC LIMIT 1")
            last_tx = cursor.fetchone()
            if last_tx:
                last_tx_index = last_tx["tx_index"] + 1
            else:
                last_tx_index = 1

            mempool_tx_index = max(last_mempool_tx_index, last_tx_index)

            # get message index before parsing the block
            cursor.execute("SELECT MAX(message_index) as message_index FROM messages")
            last_message = cursor.fetchone()
            if last_message:
                message_index_before = last_message["message_index"]
            else:
                message_index_before = -1

            # list_tx
            decoded_tx_count = 0
            for raw_tx in raw_tx_list:
                decoded_tx = deserialize.deserialize_tx(raw_tx, parse_vouts=True)
                existing_tx = ledger.blocks.get_transaction(db, decoded_tx["tx_hash"])
                not_supported_txs.append(decoded_tx["tx_hash"])
                if existing_tx:
                    logger.trace(f"Transaction {decoded_tx['tx_hash']} already in the database")
                    continue
                existing_tx_in_mempool = cursor.execute(
                    "SELECT * FROM mempool WHERE tx_hash = ? LIMIT 1", (decoded_tx["tx_hash"],)
                ).fetchone()
                if existing_tx_in_mempool:
                    logger.trace(f"Transaction {decoded_tx['tx_hash']} already in the mempool")
                    continue
                mempool_tx_index = blocks.list_tx(
                    db,
                    config.MEMPOOL_BLOCK_HASH,
                    config.MEMPOOL_BLOCK_INDEX,
                    now,
                    decoded_tx["tx_hash"],
                    tx_index=mempool_tx_index,
                    decoded_tx=decoded_tx,
                )
                decoded_tx_count += 1
            logger.trace(f"{decoded_tx_count} transactions inserted from the mempool")

            # parse fake block
            blocks.parse_block(db, config.MEMPOOL_BLOCK_INDEX, now)

            # get messages generated by the transaction
            cursor.execute(
                """SELECT * FROM messages WHERE message_index > ?""",
                (message_index_before,),
            )
            # save the events in memory
            transaction_events = cursor.fetchall()

            # get the mempool transactions
            cursor.execute(
                """SELECT * FROM transactions WHERE block_index = ?""",
                (config.MEMPOOL_BLOCK_INDEX,),
            )
            # save the mempool transactions in memory
            mempool_transactions = cursor.fetchall()
            # we raise an exception to rollback the transaction
            raise exceptions.MempoolError("Mempool transaction parsed successfully.")
    except exceptions.MempoolError:
        # save events in the mempool table
        for event in transaction_events:
            if event["tx_hash"] in not_supported_txs:
                not_supported_txs.remove(event["tx_hash"])

            if timestamps:
                event["timestamp"] = timestamps.get(event["tx_hash"], now)
            else:
                event["timestamp"] = now

            # collect addresses
            addresses = []
            event_bindings = json.loads(event["bindings"])
            if event["event"] in EVENTS_ADDRESS_FIELDS:
                for field in EVENTS_ADDRESS_FIELDS[event["event"]]:
                    if field in event_bindings and event_bindings[field] is not None:
                        addresses.append(event_bindings[field])
            addresses = list(set(addresses))
            event["addresses"] = " ".join(addresses)

            cursor.execute(
                """INSERT INTO mempool VALUES(
                    :tx_hash, :command, :category, :bindings, :timestamp, :event, :addresses
                )""",
                event,
            )

        for tx in mempool_transactions:
            cursor.execute(
                """INSERT INTO mempool_transactions VALUES(
                    :tx_index, :tx_hash, :block_index, :block_hash, :block_time, :source, :destination, :btc_amount, :fee,
                    :data, :supported, :utxos_info, :transaction_type
                )""",
                tx,
            )
    logger.trace("Mempool transaction parsed successfully.")
    CurrentState().set_parsing_mempool(False)
    return not_supported_txs


def clean_transaction_from_mempool(db, tx_hash):
    cursor = db.cursor()
    cursor.execute("DELETE FROM mempool WHERE tx_hash = ?", (tx_hash,))
    cursor.execute("DELETE FROM mempool_transactions WHERE tx_hash = ?", (tx_hash,))


def clean_mempool(db):
    logger.debug("Remove validated transactions from mempool...")
    cursor = db.cursor()
    cursor.execute("SELECT * FROM mempool")
    mempool_events = cursor.fetchall()
    for event in mempool_events:
        tx = ledger.blocks.get_transaction(db, event["tx_hash"])
        if tx:
            clean_transaction_from_mempool(db, event["tx_hash"])
    # remove transactions removed from the mempool
    logger.debug("Remove transactions removed from the mempool...")
    cursor.execute("SELECT distinct tx_hash FROM mempool")
    tx_hashes = cursor.fetchall()
    raw_mempool = backend.bitcoind.getrawmempool(verbose=False)
    for tx_hash in tx_hashes:
        if tx_hash["tx_hash"] not in raw_mempool:
            clean_transaction_from_mempool(db, tx_hash["tx_hash"])
