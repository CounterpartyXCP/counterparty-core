#
# file: counterpartycore/lib/api/migrations/0015.add_dispenser_origin_index.py
#
from yoyo import step

__depends__ = {"0014.add_pool_consolidated_tables"}


def apply(db):
    db.execute("CREATE INDEX IF NOT EXISTS dispensers_origin_idx ON dispensers (origin)")


def rollback(db):
    db.execute("DROP INDEX IF EXISTS dispensers_origin_idx")


if not __name__.startswith("apsw_"):
    steps = [step(apply, rollback)]
