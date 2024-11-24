#
# file: counterpartycore/lib/api/migrations/0008.create_config_table
#
import logging
import time

from counterpartycore.lib import config, database
from yoyo import step

logger = logging.getLogger(config.LOGGER_NAME)

__depends__ = {"0007.create_views"}


def apply(db, block_index=None):
    start_time = time.time()
    logger.debug("Creating `config` table...")

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


def rollback(db, block_index=None):
    db.execute("DROP TABLE config")


if not __name__.startswith("apsw_"):
    steps = [step(apply, rollback)]
