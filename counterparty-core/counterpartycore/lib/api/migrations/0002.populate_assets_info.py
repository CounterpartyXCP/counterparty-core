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

    cursor = db.cursor()
    sql = """
        INSERT INTO assets_info (asset, asset_id, asset_longname, first_issuance_block_index)
        SELECT asset_name AS asset, asset_id, asset_longname, block_index AS first_issuance_block_index
        FROM assets
    """
    cursor.execute(sql)

    sql = """
        UPDATE assets_info SET 
            divisible = (
                SELECT divisible FROM (
                    SELECT issuances.divisible AS divisible, issuances.rowid
                    FROM issuances
                    WHERE assets_info.asset = issuances.asset AND status = 'valid'
                    ORDER BY issuances.rowid DESC
                    LIMIT 1
                )
            ),
            description = (
                SELECT description FROM (
                    SELECT issuances.description AS description, issuances.rowid
                    FROM issuances
                    WHERE assets_info.asset = issuances.asset AND status = 'valid'
                    ORDER BY issuances.rowid DESC
                    LIMIT 1
                )
            ),
            owner = (
                SELECT issuer FROM (
                    SELECT issuances.issuer AS issuer, issuances.rowid
                    FROM issuances
                    WHERE assets_info.asset = issuances.asset AND status = 'valid'
                    ORDER BY issuances.rowid DESC
                    LIMIT 1
                )
            ),
            last_issuance_block_index = (
                SELECT block_index FROM (
                    SELECT issuances.block_index AS block_index, issuances.rowid
                    FROM issuances
                    WHERE assets_info.asset = issuances.asset AND status = 'valid'
                    ORDER BY issuances.rowid DESC
                    LIMIT 1
                )
            ),
            issuer = (
                SELECT issuer FROM (
                    SELECT issuances.issuer AS issuer, issuances.rowid
                    FROM issuances
                    WHERE assets_info.asset = issuances.asset AND status = 'valid'
                    ORDER BY issuances.rowid ASC
                    LIMIT 1
                )
            ),
            supply = (
                SELECT supply FROM (
                    SELECT SUM(issuances.quantity) AS supply, issuances.asset
                    FROM issuances
                    WHERE assets_info.asset = issuances.asset AND status = 'valid'
                    GROUP BY issuances.asset
                )
            ) - (
                SELECT quantity FROM (
                    SELECT SUM(destructions.quantity) AS quantity, destructions.asset
                    FROM destructions
                    WHERE assets_info.asset = destructions.asset AND status = 'valid'
                    GROUP BY destructions.asset
                )
            ),
            locked = (
                SELECT locked FROM (
                    SELECT SUM(issuances.locked) AS locked, issuances.asset
                    FROM issuances
                    WHERE assets_info.asset = issuances.asset AND status = 'valid'
                    GROUP BY issuances.asset
                )
            );
    """
    cursor.execute(sql)

    logger.debug("`assets_info` ready.")


def rollback(db):
    pass


steps = [step(apply, rollback)]
