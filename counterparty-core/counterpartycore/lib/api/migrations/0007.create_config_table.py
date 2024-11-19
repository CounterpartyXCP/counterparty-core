#
# file: counterpartycore/lib/api/migrations/0007.create_config_table
#
import logging
import time

from counterpartycore.lib import config, database
from yoyo import step

logger = logging.getLogger(config.LOGGER_NAME)

__depends__ = {"0006.create_views"}


def apply(db):
    start_time = time.time()
    logger.debug("Creating `config` table...")

    db.execute("ATTACH DATABASE ? AS ledger_db", (config.DATABASE,))

    sql = """
        CREATE TABLE config (
            name TEXT PRIMARY KEY,
            value TEXT
        )
    """
    db.execute(sql)
    db.execute("CREATE INDEX config_config_name_idx ON config (name)")

    last_parsed_event = db.execute(
        "SELECT MAX(message_index) AS message_index FROM ledger_db.messages"
    ).fetchone()
    last_parsed_event_index = 0
    if last_parsed_event:
        last_parsed_event_index = last_parsed_event["message_index"]
    db.execute(
        "INSERT INTO config (name, value) VALUES (?, ?)",
        ("LAST_PARSED_EVENT", last_parsed_event_index),
    )

    database.update_version(db)

    logger.debug(f"`config` table created in {time.time() - start_time:.2f} seconds")


def rollback(db):
    db.execute("DROP TABLE config")


steps = [step(apply, rollback)]
