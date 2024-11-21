#
# file: counterpartycore/lib/api/migrations/0008.create_config_table
#
import logging
import time

from counterpartycore.lib import config, database
from yoyo import step

logger = logging.getLogger(config.LOGGER_NAME)

__depends__ = {"0007.create_views"}


def dict_factory(cursor, row):
    fields = [column[0] for column in cursor.description]
    return {key: value for key, value in zip(fields, row)}


def apply(db):
    start_time = time.time()
    logger.debug("Creating `config` table...")

    db.row_factory = dict_factory

    sql = """
        CREATE TABLE config (
            name TEXT PRIMARY KEY,
            value TEXT
        )
    """
    db.execute(sql)
    db.execute("CREATE INDEX config_config_name_idx ON config (name)")

    database.update_version(db)

    logger.debug(f"`config` table created in {time.time() - start_time:.2f} seconds")


def rollback(db):
    db.execute("DROP TABLE config")


steps = [step(apply, rollback)]
