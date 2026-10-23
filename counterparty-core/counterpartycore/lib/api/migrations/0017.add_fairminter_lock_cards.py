#
# file: counterpartycore/lib/api/migrations/0017.add_fairminter_lock_cards.py
#
# Ledger migration 0012 adds ``fairminters.lock_cards`` (fairminter cards).
# A State DB built after it copies the column with the ledger schema (0006);
# one built before needs it added so the watcher can replicate card
# fairminters.
#
from yoyo import step

__depends__ = {"0016.add_rollback_block_index_indexes"}


def apply(db):
    columns = [row[1] for row in db.execute("PRAGMA table_info(fairminters)").fetchall()]
    if "lock_cards" not in columns:
        db.execute("ALTER TABLE fairminters ADD COLUMN lock_cards BOOL DEFAULT 0")


def rollback(db):
    pass


if not __name__.startswith("apsw_"):
    steps = [step(apply, rollback)]
