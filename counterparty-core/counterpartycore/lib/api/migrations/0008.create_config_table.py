#
# file: counterpartycore/lib/api/migrations/0008.create_config_table
#
import logging
import time

from counterpartycore.lib import config
from counterpartycore.lib.utils import database
from yoyo import step

logger = logging.getLogger(config.LOGGER_NAME)

__depends__ = {"0007.create_views"}


def apply(db):
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

    logger.debug("`config` table created in %.2f seconds", time.time() - start_time)


def rollback(db):
    db.execute("DROP TABLE config")


if not __name__.startswith("apsw_"):
    steps = [step(apply, rollback)]
