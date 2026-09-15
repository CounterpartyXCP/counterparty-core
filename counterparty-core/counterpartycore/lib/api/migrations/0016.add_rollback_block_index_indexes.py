#
# file: counterpartycore/lib/api/migrations/0016.add_rollback_block_index_indexes.py
#
# The incremental rollback (issue #3485) finds the objects a reorganization
# invalidated with ``SELECT ... FROM <table> WHERE block_index >= ?``. Most
# consolidated tables inherit a ``block_index`` index from the Ledger DB schema
# (migration 0006 copies the ledger's indexes verbatim), but ``addresses``,
# ``rps`` and ``rps_matches`` never had one. They are small, so the missing
# index is not a correctness problem -- it just turns three seeks into three
# full scans on every reorg. Add them explicitly.
#
from yoyo import step

__depends__ = {"0015.add_dispenser_origin_index"}

INDEXES = {
    "addresses_block_index_idx": "addresses (block_index)",
    "rps_block_index_idx": "rps (block_index)",
    "rps_matches_block_index_idx": "rps_matches (block_index)",
}


def apply(db):
    for name, target in INDEXES.items():
        db.execute(f"CREATE INDEX IF NOT EXISTS {name} ON {target}")  # noqa: S608  # nosec B608


def rollback(db):
    for name in INDEXES:
        db.execute(f"DROP INDEX IF EXISTS {name}")  # noqa: S608  # nosec B608


if not __name__.startswith("apsw_"):
    steps = [step(apply, rollback)]
