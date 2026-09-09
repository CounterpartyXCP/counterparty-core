#
# file: counterpartycore/lib/api/migrations/0004.create_and_populate_assets_info.py
#
import logging
import time

from counterpartycore.lib import config
from counterpartycore.lib.api.statetables import populate_assets_info
from yoyo import step

logger = logging.getLogger(config.LOGGER_NAME)

__depends__ = {"0003.create_and_populate_all_expirations"}


def dict_factory(cursor, row):
    fields = [column[0] for column in cursor.description]
    return dict(zip(fields, row, strict=True))


def apply(db):
    start_time = time.time()
    logger.debug("Populating the `assets_info` table...")

    if hasattr(db, "row_factory"):
        db.row_factory = dict_factory

    attached = (
        db.execute(
            "SELECT COUNT(*) AS count FROM pragma_database_list WHERE name = ?", ("ledger_db",)
        ).fetchone()["count"]
        > 0
    )
    if not attached:
        db.execute("ATTACH DATABASE ? AS ledger_db", (config.DATABASE,))

    db.execute("""
        CREATE TABLE assets_info(
            asset TEXT,
            asset_id TEXT,
            asset_longname TEXT,
            issuer TEXT,
            owner TEXT,
            divisible BOOL,
            locked BOOL DEFAULT 0,
            supply INTEGER DEFAULT 0,
            description TEXT,
            description_locked BOOL DEFAULT 0,
            first_issuance_block_index INTEGER,
            last_issuance_block_index INTEGER,
            mime_type TEXT DEFAULT 'text/plain'
    )""")

    # ``assets_info`` is a pure projection of the ledger's issuance /
    # destruction / burn history. The derivation is shared with the
    # incremental rollback path (which needs the same rules bounded to a block
    # index) so the two can never drift apart -- see ``api/statetables.py``.
    populate_assets_info(db)

    db.execute("CREATE UNIQUE INDEX assets_info_asset_idx ON assets_info (asset)")
    db.execute("CREATE UNIQUE INDEX assets_info_asset_id_idx ON assets_info (asset_id)")
    db.execute("CREATE INDEX assets_info_asset_longname_idx ON assets_info (asset_longname)")
    db.execute("CREATE INDEX assets_info_issuer_idx ON assets_info (issuer)")
    db.execute("CREATE INDEX assets_info_owner_idx ON assets_info (owner)")

    logger.debug("Populated the `assets_info` table in %.2f seconds", time.time() - start_time)


def rollback(db):
    db.execute("DROP TABLE assets_info")


if not __name__.startswith("apsw_"):
    steps = [step(apply, rollback)]
