import json
import logging
import os
import time
from threading import Thread

from counterpartycore.lib import config, database

logger = logging.getLogger(config.LOGGER_NAME)

CURRENT_DIR = os.path.dirname(os.path.realpath(__file__))
MIGRATIONS_FILE = os.path.join(CURRENT_DIR, "migrations", "0001.create-api-database.sql")

UPDATE_EVENTS_ID_FIELDS = {
    "BLOCK_PARSED": ["block_index"],
    "TRANSACTION_PARSED": ["tx_index"],
    "BET_MATCH_UPDATE": ["id"],
    "BET_UPDATE": ["tx_hash"],
    "DISPENSER_UPDATE": ["source", "asset"],
    "ORDER_FILLED": ["tx_hash"],
    "ORDER_MATCH_UPDATE": ["id"],
    "ORDER_UPDATE": ["tx_hash"],
    "RPS_MATCH_UPDATE": ["id"],
    "RPS_UPDATE": ["tx_hash"],
}


def get_last_parsed_message_index(api_db):
    cursor = api_db.cursor()
    sql = "SELECT * FROM messages ORDER BY message_index DESC LIMIT 1"
    cursor.execute(sql)
    last_event = cursor.fetchone()
    last_message_index = -1
    if last_event:
        last_message_index = last_event["message_index"]
    return last_message_index


def get_next_event_to_parse(api_db, ledger_db):
    last_parsed_message_index = get_last_parsed_message_index(api_db)
    cursor = ledger_db.cursor()
    sql = "SELECT * FROM messages WHERE message_index > ? ORDER BY message_index ASC LIMIT 1"
    cursor.execute(sql, (last_parsed_message_index,))
    next_event = cursor.fetchone()
    return next_event


def get_event_bindings(event):
    event_bindings = json.loads(event["bindings"])
    if "order_match_id" in event_bindings:
        del event_bindings["order_match_id"]
    elif event["category"] == "dispenses" and "btc_amount" in event_bindings:
        del event_bindings["btc_amount"]
    return event_bindings


def insert_event_to_sql(event):
    event_bindings = get_event_bindings(event)
    sql_bindings = []
    sql = f"INSERT INTO {event['category']} "
    names = []
    for key, value in event_bindings.items():
        names.append(key)
        sql_bindings.append(value)
    sql += f"({', '.join(names)}) VALUES ({', '.join(['?' for _ in names])})"
    return sql, sql_bindings


def update_event_to_sql(event):
    event_bindings = get_event_bindings(event)
    sql_bindings = []
    sql = f"UPDATE {event['category']} SET "  # noqa: S608
    id_field_names = UPDATE_EVENTS_ID_FIELDS[event["event"]]
    for key, value in event_bindings.items():
        if key in id_field_names:
            continue
        sql += f"{key} = ?, "
        sql_bindings.append(value)
    sql = sql[:-2]  # remove trailing comma
    sql += " WHERE "
    for id_field_name in id_field_names:
        sql += f"{id_field_name} = ? AND "
        sql_bindings.append(event_bindings[id_field_name])
    sql = sql[:-5]  # remove trailing " AND "
    return sql, sql_bindings


def event_to_sql(event):
    if event["command"] == "insert":
        return insert_event_to_sql(event)
    if event["command"] in ["update", "parse"]:
        return update_event_to_sql(event)
    return None, []


def insert_event(api_db, event):
    sql = """
        INSERT INTO messages 
            (message_index, block_index, event, category, command, bindings, tx_hash)
        VALUES (:message_index, :block_index, :event, :category, :command, :bindings, :tx_hash)
    """
    cursor = api_db.cursor()
    cursor.execute(sql, event)


def update_balances(api_db, event):
    if event["event"] not in ["DEBIT", "CREDIT"]:
        return

    cursor = api_db.cursor()

    event_bindings = get_event_bindings(event)
    quantity = event_bindings["quantity"]
    if event["event"] == "DEBIT":
        quantity = -quantity

    existing_balance = cursor.execute(
        "SELECT * FROM balances WHERE address = :address AND asset = :asset",
        event_bindings,
    ).fetchone()

    if existing_balance is None:
        sql = """
            UPDATE balances
            SET quantity = quantity + :quantity
            WHERE address = :address AND asset = :asset
            """
    else:
        sql = """
            INSERT INTO balances (address, asset, quantity)
            VALUES (:address, :asset, :quantity)
            """
    insert_bindings = {
        "address": event_bindings["address"],
        "asset": event_bindings["asset"],
        "quantity": quantity,
    }
    cursor.execute(sql, insert_bindings)


def parse_event(api_db, event, initial_parsing=False):
    initial_event_saved = [
        "NEW_BLOCK",
        "NEW_TRANSACTION",
        "BLOCK_PARSED",
        "TRANSACTION_PARSED",
        "CREDIT",
        "DEBIT",
    ]
    with api_db:
        if initial_parsing and event["event"] in initial_event_saved:
            insert_event(api_db, event)
        else:
            sql, sql_bindings = event_to_sql(event)
            if sql is not None:
                cursor = api_db.cursor()
                cursor.execute(sql, sql_bindings)
            update_balances(api_db, event)
            insert_event(api_db, event)
        logger.trace(f"Event parsed: {event['message_index']} {event['event']}")


def copy_table(api_db, ledger_db, table_name, group_by=None):
    logger.debug(f"Copying table {table_name}...")
    start_time = time.time()
    ledger_cursor = ledger_db.cursor()

    if group_by:
        select_sql = f"SELECT *, MAX(rowid) AS rowid FROM {table_name} GROUP BY {group_by}"  # noqa: S608
    else:
        select_sql = f"SELECT * FROM {table_name}"  # noqa: S608
    ledger_cursor.execute(f"{select_sql} LIMIT 1")
    first_row = ledger_cursor.fetchone()

    ledger_cursor.execute(f"SELECT COUNT(*) AS count FROM ({select_sql})")  # noqa: S608
    total_rows = ledger_cursor.fetchone()["count"]

    field_names = ", ".join(first_row.keys())
    field_values = ", ".join([f":{key}" for key in first_row.keys()])
    insert_sql = f"INSERT INTO {table_name} ({field_names}) VALUES ({field_values})"  # noqa: S608

    ledger_cursor.execute(select_sql)  # noqa: S608
    saved_rows = 0
    with api_db:
        api_cursor = api_db.cursor()
        for row in ledger_cursor:
            api_cursor.execute(insert_sql, row)
            saved_rows += 1
            if saved_rows % 100000 == 0:
                logger.debug(f"{saved_rows}/{total_rows} rows of {table_name} copied")

    duration = time.time() - start_time
    logger.debug(f"Table {table_name} copied in {duration:.2f} seconds")


def initial_events_parsing(api_db, ledger_db):
    logger.debug("Initial event parsing...")
    start_time = time.time()
    ledger_cursor = ledger_db.cursor()

    ledger_cursor.execute("SELECT COUNT(*) AS count FROM messages")
    event_count = ledger_cursor.fetchone()["count"]

    ledger_cursor.execute("SELECT * FROM messages ORDER BY message_index ASC")
    parsed_event_count = 0
    for event in ledger_cursor:
        parse_event(api_db, event, initial_parsing=True)
        parsed_event_count += 1
        if parsed_event_count % 100000 == 0:
            logger.debug(f"{parsed_event_count}/{event_count} events parsed")

    duration = time.time() - start_time
    logger.debug(f"Initial event parsing completed in {duration:.2f} seconds")


def initialize_api_db(api_db, ledger_db):
    logger.info("Initializing API Database...")
    start_time = time.time()

    cursor = api_db.cursor()

    # TODO: use migrations library
    with open(MIGRATIONS_FILE, "r") as f:
        sql = f.read()
        cursor.execute(sql)

    # Create XCP and BTC assets if they don't exist
    cursor.execute("""SELECT * FROM assets WHERE asset_name = ?""", ("BTC",))
    if not list(cursor):
        cursor.execute("""INSERT INTO assets VALUES (?,?,?,?)""", ("0", "BTC", None, None))
        cursor.execute("""INSERT INTO assets VALUES (?,?,?,?)""", ("1", "XCP", None, None))
    cursor.close()

    # check last parsed message index
    last_message_index = get_last_parsed_message_index(api_db)
    if last_message_index == -1:
        logger.info("New API database, initializing...")
        with api_db:  # everything or nothing
            cursor = api_db.cursor()
            cursor.execute("""PRAGMA foreign_keys=OFF""")
            for table in ["blocks", "transactions", "credits", "debits"]:
                copy_table(api_db, ledger_db, table)
            copy_table(api_db, ledger_db, "balances", group_by="address, asset")
            initial_events_parsing(api_db, ledger_db)
            cursor.execute("""PRAGMA foreign_keys=ON""")
        duration = time.time() - start_time
        logger.info(f"API database initialized in {duration:.2f} seconds")


class APIWatcher(Thread):
    def __init__(self):
        logger.debug("Initializing API Watcher...")
        self.stopped = False
        self.api_db = database.get_db_connection(
            config.API_DATABASE, read_only=False, check_wal=False
        )
        self.ledger_db = database.get_db_connection(
            config.DATABASE, read_only=True, check_wal=False
        )

        initialize_api_db(self.api_db, self.ledger_db)

        Thread.__init__(self)

    def run(self):
        logger.info("Starting API Watcher...")
        while True and not self.stopped:
            next_event = get_next_event_to_parse(self.api_db, self.ledger_db)
            if next_event:
                logger.trace(f"Parsing event: {next_event}")
                parse_event(self.api_db, next_event)
            else:
                logger.trace("No new events to parse")
                time.sleep(1)
        return

    def stop(self):
        logger.info("Stopping API Watcher...")
        self.stopped = True
        self.api_db.close()
        self.ledger_db.close()
