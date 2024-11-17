#
# file: counterpartycore/lib/api/migrations/0002.populate_assets_info.py
#
import logging
import os

from counterpartycore.lib import config
from yoyo import step

logger = logging.getLogger(config.LOGGER_NAME)

CURRENT_DIR = os.path.dirname(os.path.realpath(__file__))

__depends__ = {"0001.api_db_to_state_db"}


def dict_factory(cursor, row):
    fields = [column[0] for column in cursor.description]
    return {key: value for key, value in zip(fields, row)}


def apply(db):
    logger.debug("Populate `assets_info` table...")
    db.row_factory = dict_factory

    sql = """
    INSERT INTO assets_info 
    SELECT 
        asset,
        asset_id,
        asset_longname,
        issuer,
        owner,
        divisible,
        locked,
        supply,
        description,
        description_locked,
        first_issuance_block_index,
        last_issuance_block_index,
        confirmed
    FROM (
        SELECT
            asset,
            assets.asset_id,
            assets.asset_longname,
            (
                SELECT issuer
                FROM issuances AS issuances2
                WHERE assets.asset_name = issuances2.asset
                ORDER BY issuances2.rowid ASC
                LIMIT 1
            ) AS issuer,
            issuer AS owner,
            divisible,
            SUM(locked) AS locked,
            SUM(quantity) AS supply,
            description,
            SUM(description_locked) AS description_locked,
            MIN(issuances.block_index) AS first_issuance_block_index,
            MAX(issuances.block_index) AS last_issuance_block_index,
            TRUE AS confirmed,
            MAX(issuances.rowid) AS rowid
        FROM issuances, assets
        WHERE issuances.asset = assets.asset_name
        AND issuances.status = 'valid'
        GROUP BY asset
    );
    """
    cursor = db.cursor()
    cursor.execute(sql)

    logger.debug("`assets_info` ready.")


def rollback(db):
    pass


steps = [step(apply, rollback)]
