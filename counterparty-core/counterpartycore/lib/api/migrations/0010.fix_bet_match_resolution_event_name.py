#
# file: counterpartycore/lib/api/migrations/0009.create_and_populate_transaction_types_count.py
#
import logging
import time

from counterpartycore.lib import config
from yoyo import step

logger = logging.getLogger(config.LOGGER_NAME)

__depends__ = {"0008.create_config_table"}


def dict_factory(cursor, row):
    fields = [column[0] for column in cursor.description]
    return dict(zip(fields, row))


def apply(db):
    start_time = time.time()
    logger.debug("Fix `BET_MATCH_RESOLUTION` event name...")

    db.execute(
        "UPDATE events_count SET event = 'BET_MATCH_RESOLUTION' WHERE event = 'BET_MATCH_RESOLUTON'"
    )

    logger.debug(
        "`BET_MATCH_RESOLUTION` event name fixed in %.2f seconds", time.time() - start_time
    )


def rollback(db):
    pass


if not __name__.startswith("apsw_"):
    steps = [step(apply, rollback)]
