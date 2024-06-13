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


def parse_event(api_db, event):
    with api_db:
        sql, sql_bindings = event_to_sql(event)
        if sql is not None:
            cursor = api_db.cursor()
            cursor.execute(sql, sql_bindings)
        insert_event(api_db, event)
        logger.debug(f"Event parsed: {event['message_index']} {event['event']}")


class APIWatcher(Thread):
    def __init__(self):
        logger.debug("Initializing API Watcher...")
        self.stopped = False
        self.api_db = database.get_db_onnection(
            config.API_DATABASE, read_only=False, check_wal=False
        )
        self.ledger_db = database.get_db_onnection(config.DATABASE, read_only=True, check_wal=False)

        # TODO: use migrations library
        with open(MIGRATIONS_FILE, "r") as f:
            cursor = self.api_db.cursor()
            sql = f.read()
            cursor.execute(sql)

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
