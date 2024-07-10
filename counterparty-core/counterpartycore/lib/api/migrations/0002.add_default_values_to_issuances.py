#
# file: counterpartycore/lib/api/migrations/0002.add_default_values_to_issuances.py
#
import logging
import os

from counterpartycore.lib import config
from yoyo import step

logger = logging.getLogger(config.LOGGER_NAME)

CURRENT_DIR = os.path.dirname(os.path.realpath(__file__))

__depends__ = {"0001.create_api_database"}


# def dict_factory(cursor, row):
#    fields = [column[0] for column in cursor.description]
#    return {key: value for key, value in zip(fields, row)}


def apply(db):
    logger.info("Add defaul value for `locked` and `reset` fields in `issuances` table...")
    # db.row_factory = dict_factory

    cursor = db.cursor()
    sqls = [
        # locked field
        "ALTER TABLE issuances RENAME COLUMN locked TO locked_old",
        "ALTER TABLE issuances ADD COLUMN locked BOOL DEFAULT FALSE",
        "UPDATE issuances SET locked = locked_old",
        "ALTER TABLE issuances DROP COLUMN locked_old",
        "UPDATE issuances SET locked = 0 WHERE locked IS NULL",
        # reset field
        "ALTER TABLE issuances RENAME COLUMN reset TO reset_old",
        "ALTER TABLE issuances ADD COLUMN reset BOOL DEFAULT FALSE",
        "UPDATE issuances SET reset = reset_old",
        "ALTER TABLE issuances DROP COLUMN reset_old",
        "UPDATE issuances SET locked = 0 WHERE locked IS NULL",
    ]
    for sql in sqls:
        cursor.execute(sql)

    logger.info("`locked` and `reset` fields updated...")


def rollback(db):
    pass


steps = [step(apply, rollback)]
