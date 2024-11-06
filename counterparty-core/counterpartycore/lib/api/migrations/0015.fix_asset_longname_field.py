#
# file: counterpartycore/lib/api/migrations/0015.fix_asset_longname_field.py
#
import logging
import os

from counterpartycore.lib import config
from yoyo import step

logger = logging.getLogger(config.LOGGER_NAME)

CURRENT_DIR = os.path.dirname(os.path.realpath(__file__))

__depends__ = {"0014.add_index_to_ledger_hash"}


def dict_factory(cursor, row):
    fields = [column[0] for column in cursor.description]
    return {key: value for key, value in zip(fields, row)}


def apply(db):
    logger.info("Update `asset_longname` field...")
    db.row_factory = dict_factory

    cursor = db.cursor()
    sql = """
        SELECT 
            DISTINCT(asset),
            (SELECT asset_longname FROM issuances WHERE asset = i.asset ORDER BY rowid ASC LIMIT 1) AS asset_longname
        FROM issuances AS i WHERE 
            asset IN (SELECT DISTINCT(asset) FROM issuances WHERE asset_longname is NOT NULL AND asset_longname != '')
            AND (asset_longname is NULL OR asset_longname = '') 
            AND status='valid'
            AND fair_minting = 1;
    """
    cursor.execute(sql)
    assets = cursor.fetchall()
    for asset in assets:
        sql = "UPDATE issuances SET asset_longname = ? WHERE asset = ? AND (asset_longname = '' OR asset_longname IS NULL)"
        cursor.execute(sql, (asset["asset_longname"], asset["asset"]))
        sql = "UPDATE assets_info SET asset_longname = ? WHERE asset = ?"
        cursor.execute(sql, (asset["asset_longname"], asset["asset"]))

    logger.info("`asset_longname` field updated...")


def rollback(db):
    pass


steps = [step(apply, rollback)]
