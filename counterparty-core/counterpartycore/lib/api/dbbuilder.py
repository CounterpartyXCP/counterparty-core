import importlib.util
import logging
import os
import sys
import time

from yoyo.migrations import topological_sort

from counterpartycore.lib import config
from counterpartycore.lib.api import dbstatus, staterollback
from counterpartycore.lib.cli import log
from counterpartycore.lib.utils import database

logger = logging.getLogger(config.LOGGER_NAME)

MIGRATIONS_AFTER_ROLLBACK = [
    # 0002 / 0003 are included so that pre-existing state DBs built before the
    # compact-hash storage migration get rebuilt with the ``hex_lower(...)``
    # projection on the next rollback:
    #   - 0002 populates ``parsed_events.event_hash`` (TEXT) from
    #     ``ledger_db.messages.event_hash`` (now BLOB(32)); without the
    #     ``hex_lower`` projection, BLOBs end up stored in the TEXT column.
    #   - 0003 has the same problem on ``all_expirations.object_id``.
    # ``parsed_events`` and ``all_expirations`` are also in ``ROLLBACKABLE_TABLES``
    # (DELETE-only path); the DELETE is harmless since the table is dropped
    # and recreated by the migration apply.
    "0002.create_and_populate_parsed_events",
    "0003.create_and_populate_all_expirations",
    "0004.create_and_populate_assets_info",
    "0005.create_and_populate_events_count",
    "0006.create_and_populate_consolidated_tables",
    "0007.create_views",
    "0008.create_config_table",
    "0009.create_and_populate_transaction_types_count",
    "0011.create_orders_views",
    "0013.add_performance_indexes",
    "0014.add_pool_consolidated_tables",
    "0015.add_dispenser_origin_index",
    # 0016 indexes tables that 0006 drops and recreates, so it must be
    # re-applied with them.
    "0016.add_rollback_block_index_indexes",
]

ROLLBACKABLE_TABLES = [
    "all_expirations",
    "address_events",
    "parsed_events",
]


def filter_migrations(migrations, wanted_ids):
    filtered_migrations = (m for m in migrations if m.id in wanted_ids)
    return migrations.__class__(topological_sort(filtered_migrations), migrations.post_apply)


def import_from_path(module_name, file_path):
    spec = importlib.util.spec_from_file_location(module_name, file_path)
    module = importlib.util.module_from_spec(spec)
    sys.modules[module_name] = module
    spec.loader.exec_module(module)
    return module


def import_migration(migration_id):
    migration_path = os.path.join(config.STATE_DB_MIGRATIONS_DIR, f"{migration_id}.py")
    module_name = "apsw_" + migration_id.split(".")[1]
    return import_from_path(module_name, migration_path)


def apply_migration(state_db, migration_id):
    module = import_migration(migration_id)
    module.apply(state_db)


def rollback_migration(state_db, migration_id):
    module = import_migration(migration_id)
    module.rollback(state_db)


def rollback_migrations(state_db, migration_ids, progress=None, offset=0):
    for index, migration_id in enumerate(reversed(migration_ids)):
        _run_migration_step(
            state_db, rollback_migration, "Rolling back", migration_id, progress, offset + index
        )


def apply_migrations(state_db, migration_ids, progress=None, offset=0):
    for index, migration_id in enumerate(migration_ids):
        _run_migration_step(
            state_db, apply_migration, "Applying", migration_id, progress, offset + index
        )


def _run_migration_step(state_db, run, verb, migration_id, progress, index):
    """Run one migration, reporting it to the operator and to the health probes.

    Reported at INFO, not DEBUG: these steps are what a State DB rebuild
    actually spends its tens of minutes on, and their absence from the log is
    why the 33-minute rebuild in #3485 was indistinguishable from a hang.
    """
    if progress is not None:
        progress.step(f"{verb.lower()} `{migration_id}`", index + 1)
    logger.info("%s migration `%s`...", verb, migration_id)
    start_time = time.time()
    run(state_db, migration_id)
    logger.info("%s migration `%s` in %.2f seconds", verb, migration_id, time.time() - start_time)


def reapply_migrations(state_db, migration_ids, progress=None):
    # Each migration is dropped and re-applied, hence 2 * len(migration_ids)
    # reportable steps.
    rollback_migrations(state_db, migration_ids, progress=progress)
    apply_migrations(state_db, migration_ids, progress=progress, offset=len(migration_ids))


def rollback_tables(state_db, block_index):
    cursor = state_db.cursor()
    cursor.execute("""PRAGMA foreign_keys=OFF""")

    for table in ROLLBACKABLE_TABLES:
        logger.debug("Rolling back table `%s`...", table)
        cursor.execute(f"DELETE FROM {table} WHERE block_index >= ?", (block_index,))  # noqa S608 # nosec B608

    cursor.execute("""PRAGMA foreign_keys=ON""")
    cursor.close()


def build_state_db():
    logger.info("Building State DB...")
    start_time = time.time()

    # Remove existing State DB
    for ext in ["", "-wal", "-shm"]:
        if os.path.exists(config.STATE_DATABASE + ext):
            os.unlink(config.STATE_DATABASE + ext)

    # The State DB migrations read from the Ledger DB schema (e.g. migration
    # 0006 references ``fairmints.fairminter_tx_index``, introduced by ledger
    # migration 0010). Make sure the Ledger DB is fully migrated before
    # building the State DB so this command works against bootstrap snapshots
    # that predate the latest Ledger DB migrations.
    # Published for the health probes: this runs before the API listener exists,
    # so ``rebuilding`` is the only thing that distinguishes a pod that is busy
    # from one that is wedged (see ``api/dbstatus.py``).
    with dbstatus.rebuilding("build", "applying Ledger DB migrations") as progress:
        with log.Spinner("Applying Ledger DB migrations"):
            database.apply_outstanding_migration(config.DATABASE, config.LEDGER_DB_MIGRATIONS_DIR)

        progress.step("applying State DB migrations")
        with log.Spinner("Applying migrations"):
            database.apply_outstanding_migration(
                config.STATE_DATABASE, config.STATE_DB_MIGRATIONS_DIR
            )

        progress.step("vacuuming")
        with log.Spinner("Vacuuming State DB..."):
            state_db = database.get_db_connection(config.STATE_DATABASE, read_only=False)
            database.vacuum(state_db)
            # Every table was just derived from the Ledger DB, so the invariants
            # the incremental rollback relies on hold (see ``staterollback``).
            staterollback.mark_ready(state_db)
            state_db.close()

    logger.info("State DB built in %.2f seconds", time.time() - start_time)


def record_balances_copied_block(state_db):
    """
    Record the current ledger_db block index to prevent double-counting of
    CREDIT/DEBIT events during catch-up.

    When state_db is rolled back, migration 0006 copies balances from ledger_db.
    However, ledger_db may already be ahead (reparsing after its own rollback).
    This creates a race condition where balances reflect block X, but parsed_events
    only go up to block Y < X. When catch_up processes events from Y to X,
    CREDIT/DEBIT events get applied twice.

    By recording the ledger_db block index at the time of the copy, we can skip
    CREDIT/DEBIT events that are already reflected in the copied balances.
    """
    cursor = state_db.cursor()

    # Check if ledger_db is already attached (migration 0006 may have attached it)
    already_attached = (
        cursor.execute(
            "SELECT COUNT(*) AS count FROM pragma_database_list WHERE name = ?", ("ledger_db",)
        ).fetchone()["count"]
        > 0
    )

    if not already_attached:
        cursor.execute("ATTACH DATABASE ? AS ledger_db", (config.DATABASE,))

    result = cursor.execute("""
        SELECT MAX(block_index) as block_index 
        FROM ledger_db.messages 
        WHERE event = 'BLOCK_PARSED'
    """).fetchone()

    if not already_attached:
        cursor.execute("DETACH DATABASE ledger_db")

    if result and result["block_index"]:
        database.set_config_value(state_db, "BALANCES_COPIED_AT_BLOCK", str(result["block_index"]))
        logger.debug(
            "Recorded balances copied at block %s to prevent double-counting",
            result["block_index"],
        )


def rollback_state_db(state_db, block_index):
    """Roll the State DB back to ``block_index - 1``.

    Prefers the incremental path (:mod:`counterpartycore.lib.api.staterollback`),
    whose cost is proportional to the number of rows the rolled back blocks
    touched. Falls back to :func:`full_rollback_state_db` -- which re-derives
    every table from the entire ledger history -- for a deep rollback, for a
    State DB predating the invariants the incremental path relies on, and if the
    incremental path raises for any reason at all.

    The ``UPGRADE_ACTIONS`` rollbacks do not come through here: they call
    :func:`full_rollback_state_db` directly (see
    ``apiserver.execute_upgrade_actions``), because a release that ships one may
    also have changed the derivation rules themselves, and only the full rebuild
    re-applies those.
    """
    reason = staterollback.rollback_reason(state_db, block_index)
    if reason is None:
        try:
            staterollback.rollback_state_db(state_db, block_index)
            return
        except Exception as e:  # pylint: disable=broad-except
            # The incremental path is an optimization; the full rebuild is the
            # ground truth and is always correct. Anything unexpected -- a State
            # DB whose schema the projection does not fit, a SQL error in a
            # table this release has never seen -- must degrade to the slow path
            # rather than propagate: the caller is `apiwatcher.check_reorg()`,
            # running on the watcher thread, which has no handler for it and
            # would die, leaving the State DB frozen behind the Ledger DB.
            logger.warning(
                "Incremental State DB rollback failed (%s); falling back to the full rebuild.",
                e,
                exc_info=True,
            )
    elif reason == staterollback.NOTHING_TO_ROLL_BACK:
        # Re-deriving every table from the entire ledger history to undo nothing
        # would be the most expensive no-op available. The watcher replays
        # forward from where the State DB actually is.
        logger.info("State DB is already below block index %s; nothing to roll back.", block_index)
        return
    else:
        logger.info("Full State DB rebuild required: %s.", reason)
    full_rollback_state_db(state_db, block_index)


def full_rollback_state_db(state_db, block_index):
    logger.info("Rolling back State DB to block index %s...", block_index)
    start_time = time.time()

    with dbstatus.rebuilding(
        "rollback", "pruning rolled back rows", total=2 * len(MIGRATIONS_AFTER_ROLLBACK)
    ) as progress:
        with state_db:
            with log.Spinner("Rolling back State DB tables..."):
                rollback_tables(state_db, block_index)
            with log.Spinner("Re-applying migrations..."):
                reapply_migrations(state_db, MIGRATIONS_AFTER_ROLLBACK, progress=progress)
            # Record the ledger_db block index to prevent double-counting of balances
            # during catch-up (see record_balances_copied_block docstring for details)
            record_balances_copied_block(state_db)
            staterollback.mark_ready(state_db)

    logger.info("State DB rolled back in %.2f seconds", time.time() - start_time)


def refresh_state_db(state_db):
    logger.info("Rebuilding non rollbackable tables in State DB...")
    start_time = time.time()

    with dbstatus.rebuilding(
        "refresh", "re-applying migrations", total=2 * len(MIGRATIONS_AFTER_ROLLBACK)
    ) as progress:
        with state_db:
            with log.Spinner("Re-applying migrations..."):
                reapply_migrations(state_db, MIGRATIONS_AFTER_ROLLBACK, progress=progress)
            # Record the ledger_db block index to prevent double-counting of balances
            # during catch-up (see record_balances_copied_block docstring for details)
            record_balances_copied_block(state_db)
            staterollback.mark_ready(state_db)

    logger.info("State DB refreshed in %.2f seconds", time.time() - start_time)
