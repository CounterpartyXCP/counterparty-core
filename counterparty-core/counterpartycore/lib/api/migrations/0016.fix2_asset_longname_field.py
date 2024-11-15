#
# file: counterpartycore/lib/api/migrations/0016.fix2_asset_longname_field.py
#
import logging

from counterpartycore.lib import config
from yoyo import step

logger = logging.getLogger(config.LOGGER_NAME)

__depends__ = {"0015.fix_asset_longname_field"}


def dict_factory(cursor, row):
    fields = [column[0] for column in cursor.description]
    return {key: value for key, value in zip(fields, row)}


def apply(db):
    logger.debug("Update `asset_longname` field...")
    db.row_factory = dict_factory

    cursor = db.cursor()
    cursor.execute("UPDATE fairminters SET asset_longname = NULL WHERE asset_longname = ''")
    cursor.execute("UPDATE fairminters SET asset_parent = NULL WHERE asset_parent = ''")
    cursor.execute("UPDATE issuances SET asset_longname = NULL WHERE asset_longname = ''")
    cursor.execute("UPDATE assets_info SET asset_longname = NULL WHERE asset_longname = ''")

    logger.debug("`asset_longname` field updated...")


def rollback(db):
    pass


steps = [step(apply, rollback)]
