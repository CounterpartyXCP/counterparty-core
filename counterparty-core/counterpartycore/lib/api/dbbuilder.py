import hashlib
import importlib.util
import json
import logging
import os
import shutil
import sys
import time

from yoyo.migrations import topological_sort

from counterpartycore.lib import config, exceptions
from counterpartycore.lib.cli import log
from counterpartycore.lib.utils import database

logger = logging.getLogger(config.LOGGER_NAME)

STAGED_STATE_DB_SUFFIX = ".rebuild"
STAGED_STATE_DB_READY_SUFFIX = ".ready"
PREVIOUS_STATE_DB_SUFFIX = ".previous"
LAST_LEDGER_BLOCK_EVENT_SQL = (
    "SELECT message_index, event_hash, block_index FROM messages NOT INDEXED "
    "WHERE event = 'BLOCK_PARSED' ORDER BY message_index DESC LIMIT 1"
)

MIGRATIONS_AFTER_ROLLBACK = [
    # Rebuild address_events from the same Ledger tip as parsed_events. Leaving
    # 0001 out causes 0012 to transform only the ancestor rows that survived
    # rollback while 0002 advances parsed_events to the new tip, permanently
    # preventing catch-up from restoring the missing address rows.
    "0001.create_and_populate_address_events",
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
]

ROLLBACKABLE_TABLES = [
    "all_expirations",
    "address_events",
    "parsed_events",
]


def _database_files(db_file):
    return [db_file, f"{db_file}-wal", f"{db_file}-shm"]


def _remove_database_files(db_file):
    for path in [*_database_files(db_file), f"{db_file}-journal"]:
        try:
            os.unlink(path)
        except FileNotFoundError:
            pass


def staged_state_db_path():
    return f"{config.STATE_DATABASE}{STAGED_STATE_DB_SUFFIX}"


def staged_state_db_ready_path():
    return f"{staged_state_db_path()}{STAGED_STATE_DB_READY_SUFFIX}"


def previous_state_db_path():
    return f"{config.STATE_DATABASE}{PREVIOUS_STATE_DB_SUFFIX}"


def staged_ledger_snapshot_path():
    return f"{staged_state_db_path()}.ledger-snapshot"


def discard_staged_state_db():
    _remove_database_files(staged_state_db_path())
    _remove_database_files(staged_ledger_snapshot_path())
    for path in (staged_state_db_ready_path(), f"{staged_state_db_ready_path()}.tmp"):
        try:
            os.unlink(path)
        except FileNotFoundError:
            pass


def _check_cancelled(stop_event):
    if stop_event is not None and stop_event.is_set():
        raise exceptions.StateDBRebuildCancelled("State DB rebuild cancelled during shutdown")


def _fsync_file(path):
    descriptor = os.open(path, os.O_RDONLY)
    try:
        os.fsync(descriptor)
    finally:
        os.close(descriptor)


def _fsync_directory(path):
    descriptor = os.open(path, os.O_RDONLY)
    try:
        os.fsync(descriptor)
    finally:
        os.close(descriptor)


def _migration_digest():
    digest = hashlib.sha256()
    for name in sorted(os.listdir(config.STATE_DB_MIGRATIONS_DIR)):
        if not name.endswith((".py", ".sql")):
            continue
        path = os.path.join(config.STATE_DB_MIGRATIONS_DIR, name)
        digest.update(name.encode())
        with open(path, "rb") as migration_file:
            digest.update(migration_file.read())
    return digest.hexdigest()


def _ensure_staged_rebuild_space():
    data_dir = os.path.dirname(config.STATE_DATABASE) or "."
    ledger_size = os.path.getsize(config.DATABASE)
    state_size = os.path.getsize(config.STATE_DATABASE)
    safety_margin = 4 * 1024**3
    required = ledger_size + state_size + safety_margin
    free = shutil.disk_usage(data_dir).free
    previous_size = sum(
        os.path.getsize(path)
        for path in [
            *_database_files(previous_state_db_path()),
            f"{previous_state_db_path()}-journal",
        ]
        if os.path.exists(path)
    )
    if free + previous_size < required:
        raise exceptions.DatabaseError(
            "Insufficient free space for nonblocking State DB rebuild: "
            f"need {required} bytes, have {free} bytes free and "
            f"{previous_size} bytes reclaimable"
        )
    return free < required


def _backup_ledger_database(destination_path, stop_event=None):
    """Create a transactionally consistent ledger snapshot for migrations."""
    _remove_database_files(destination_path)
    source = database.get_db_connection(config.DATABASE, read_only=True, check_wal=False)
    destination = database.get_db_connection(destination_path, read_only=False, check_wal=False)
    try:
        source.setbusytimeout(60_000)
        destination.setbusytimeout(60_000)
        # The destination is private and immutable after this copy. Do not
        # inherit APSW's WAL best-practice mode: a full-database backup in one
        # transaction otherwise accumulates an enormous WAL (observed to
        # plateau around 8 GiB) before any checkpoint is possible.
        destination.execute("PRAGMA journal_mode=DELETE").fetchone()
        # Pin one WAL snapshot for the entire copy. Without an explicit source
        # read transaction, SQLite can restart backup progress whenever the
        # live parser changes a source page (mempool traffic can otherwise
        # starve a small-step backup indefinitely).
        source.execute("BEGIN")
        source.execute("SELECT rootpage FROM sqlite_master LIMIT 1").fetchone()
        last_progress = -10
        with destination.backup("main", source, "main") as backup:
            while not backup.done:
                _check_cancelled(stop_event)
                # Keep individual copy calls small: APSW's backup step holds
                # the Python runtime while copying pages. Large 32 MiB steps
                # made even the in-memory dedicated health server pause for
                # several seconds on production-sized databases.
                backup.step(256)
                time.sleep(0)
                if backup.pagecount:
                    progress = int(100 * (backup.pagecount - backup.remaining) / backup.pagecount)
                    if progress >= last_progress + 10:
                        logger.info("Ledger snapshot copy %d%% complete.", progress)
                        last_progress = progress
    finally:
        try:
            source.execute("ROLLBACK")
        except Exception as error:  # pylint: disable=broad-except
            logger.debug("Could not close Ledger DB snapshot transaction: %s", error)
        destination.close()
        source.close()


def _checkpoint_database(db_file):
    connection = database.get_db_connection(db_file, read_only=False, check_wal=False)
    try:
        checkpoint = connection.execute("PRAGMA wal_checkpoint(TRUNCATE)").fetchone()
        if checkpoint is not None:
            values = list(checkpoint.values()) if isinstance(checkpoint, dict) else checkpoint
            if values[0] != 0:
                raise exceptions.DatabaseError(
                    f"Could not checkpoint State DB before activation: {checkpoint!r}"
                )
    finally:
        connection.close()


def _replacement_manifest(staged_db, ledger_snapshot, stop_event=None):
    ledger_db = database.get_db_connection(ledger_snapshot, read_only=True, check_wal=False)
    state_db = None
    try:
        state_db = database.get_db_connection(staged_db, read_only=True, check_wal=False)
        if stop_event is not None:

            def progress_handler():
                return 1 if stop_event.is_set() else 0

            ledger_db.set_progress_handler(progress_handler, 10_000)
            state_db.set_progress_handler(progress_handler, 10_000)
        _check_cancelled(stop_event)
        ledger_last = ledger_db.execute(
            "SELECT message_index, event_hash, block_index FROM messages "
            "ORDER BY message_index DESC LIMIT 1"
        ).fetchone()
        state_last = state_db.execute(
            "SELECT event_index, event_hash, block_index FROM parsed_events "
            "ORDER BY event_index DESC LIMIT 1"
        ).fetchone()
        ledger_block = ledger_db.execute(LAST_LEDGER_BLOCK_EVENT_SQL).fetchone()
        state_block = state_db.execute(
            "SELECT event_index, event_hash, block_index FROM parsed_events "
            "INDEXED BY parsed_events_event_index_idx WHERE event = 'BLOCK_PARSED' "
            "ORDER BY event_index DESC LIMIT 1"
        ).fetchone()
        ledger_count = ledger_db.execute("SELECT COUNT(*) AS count FROM messages").fetchone()[
            "count"
        ]
        state_count = state_db.execute("SELECT COUNT(*) AS count FROM parsed_events").fetchone()[
            "count"
        ]
    finally:
        if stop_event is not None and state_db is not None:
            state_db.set_progress_handler(None, 0)
            ledger_db.set_progress_handler(None, 0)
        if state_db is not None:
            state_db.close()
        ledger_db.close()

    if ledger_last is None or state_last is None or ledger_block is None or state_block is None:
        raise exceptions.DatabaseError("Replacement State DB lineage rows are incomplete")
    if (
        state_last["event_index"] != ledger_last["message_index"]
        or state_last["event_hash"] != ledger_last["event_hash"]
        or state_last["block_index"] != ledger_last["block_index"]
        or state_block["event_index"] != ledger_block["message_index"]
        or state_block["event_hash"] != ledger_block["event_hash"]
        or state_block["block_index"] != ledger_block["block_index"]
        or state_count != ledger_count
    ):
        raise exceptions.DatabaseError("Replacement State DB does not match its Ledger snapshot")
    return {
        "source_event_index": ledger_last["message_index"],
        "source_event_hash": ledger_last["event_hash"],
        "source_event_block_index": ledger_last["block_index"],
        "source_block_event_index": ledger_block["message_index"],
        "source_block_event_hash": ledger_block["event_hash"],
        "source_block_index": ledger_block["block_index"],
        "source_message_count": ledger_count,
        "migration_digest": _migration_digest(),
        "builder_commit": config.CURRENT_COMMIT,
        "version": config.VERSION_STRING,
        "staged_size": os.path.getsize(staged_db),
        "created_at": time.time(),
    }


def _write_ready_manifest(ready_path, manifest):
    marker_tmp = f"{ready_path}.tmp"
    try:
        os.unlink(marker_tmp)
    except FileNotFoundError:
        pass
    marker_fd = os.open(marker_tmp, os.O_WRONLY | os.O_CREAT | os.O_EXCL, 0o600)
    try:
        os.write(marker_fd, json.dumps(manifest, sort_keys=True).encode() + b"\n")
        os.fsync(marker_fd)
    finally:
        os.close(marker_fd)
    os.replace(marker_tmp, ready_path)
    _fsync_directory(os.path.dirname(ready_path) or ".")


def _read_ready_manifest(ready_path):
    try:
        with open(ready_path, encoding="utf-8") as marker_file:
            manifest = json.load(marker_file)
    except (OSError, ValueError, TypeError) as error:
        raise exceptions.DatabaseError(f"Invalid State DB rebuild manifest: {error}") from error
    required = {
        "source_event_index",
        "source_event_hash",
        "source_event_block_index",
        "source_block_event_index",
        "source_block_event_hash",
        "source_block_index",
        "source_message_count",
        "migration_digest",
        "builder_commit",
        "version",
        "staged_size",
    }
    if not isinstance(manifest, dict) or not required <= manifest.keys():
        raise exceptions.DatabaseError("State DB rebuild manifest is incomplete")
    return manifest


def _manifest_matches_live_ledger(manifest):
    ledger_db = database.get_db_connection(config.DATABASE, read_only=True, check_wal=False)
    try:
        event = ledger_db.execute(
            "SELECT event_hash, block_index FROM messages WHERE message_index = ?",
            (manifest["source_event_index"],),
        ).fetchone()
        block_event = ledger_db.execute(
            "SELECT event_hash, block_index FROM messages WHERE message_index = ?",
            (manifest["source_block_event_index"],),
        ).fetchone()
    finally:
        ledger_db.close()
    return (
        event is not None
        and event["event_hash"] == manifest["source_event_hash"]
        and event["block_index"] == manifest["source_event_block_index"]
        and block_event is not None
        and block_event["event_hash"] == manifest["source_block_event_hash"]
        and block_event["block_index"] == manifest["source_block_index"]
    )


def _state_db_matches_manifest(db_file, manifest, check_integrity=False):
    if os.path.getsize(db_file) != manifest["staged_size"]:
        return False
    state_db = database.get_db_connection(db_file, read_only=True, check_wal=False)
    try:
        if check_integrity:
            check_result = state_db.execute("PRAGMA quick_check(1)").fetchone()
            check_value = (
                next(iter(check_result.values()))
                if isinstance(check_result, dict)
                else check_result[0]
            )
            if check_value != "ok":
                return False
        state_last = state_db.execute(
            "SELECT event_index, event_hash, block_index FROM parsed_events "
            "INDEXED BY parsed_events_event_index_idx ORDER BY event_index DESC LIMIT 1"
        ).fetchone()
        state_block = state_db.execute(
            "SELECT event_index, event_hash, block_index FROM parsed_events "
            "INDEXED BY parsed_events_event_index_idx WHERE event = 'BLOCK_PARSED' "
            "ORDER BY event_index DESC LIMIT 1"
        ).fetchone()
        state_count = state_db.execute("SELECT COUNT(*) AS count FROM parsed_events").fetchone()[
            "count"
        ]
    finally:
        state_db.close()
    return (
        state_last is not None
        and state_last["event_index"] == manifest["source_event_index"]
        and state_last["event_hash"] == manifest["source_event_hash"]
        and state_last["block_index"] == manifest["source_event_block_index"]
        and state_block is not None
        and state_block["event_index"] == manifest["source_block_event_index"]
        and state_block["event_hash"] == manifest["source_block_event_hash"]
        and state_block["block_index"] == manifest["source_block_index"]
        and state_count == manifest["source_message_count"]
    )


def _manifest_is_current(manifest, state_db_path, check_integrity=False):
    return (
        manifest["version"] == config.VERSION_STRING
        and manifest["builder_commit"] == config.CURRENT_COMMIT
        and manifest["migration_digest"] == _migration_digest()
        and _state_db_matches_manifest(
            state_db_path,
            manifest,
            check_integrity=check_integrity,
        )
        and _manifest_matches_live_ledger(manifest)
    )


def stage_state_db_rebuild(stop_event=None):
    """Build and verify a replacement State DB without touching the live one."""
    staged_db = staged_state_db_path()
    ready_path = staged_state_db_ready_path()
    ledger_snapshot = staged_ledger_snapshot_path()
    started_at = time.monotonic()

    discard_staged_state_db()
    reclaim_previous = _ensure_staged_rebuild_space()
    _check_cancelled(stop_event)
    if reclaim_previous:
        # Release the one-generation recovery copy only when staging truly
        # needs its bytes and only after preflight/cancellation checks pass.
        _remove_database_files(previous_state_db_path())

    logger.warning("Copying live Ledger DB to %s for a stable rebuild snapshot.", ledger_snapshot)
    _backup_ledger_database(ledger_snapshot, stop_event=stop_event)
    _check_cancelled(stop_event)

    logger.warning("Building replacement State DB at %s; live API DB remains online.", staged_db)
    previous_ledger_source = config.STATE_DB_LEDGER_SOURCE_DATABASE
    config.STATE_DB_LEDGER_SOURCE_DATABASE = ledger_snapshot
    try:
        database.apply_outstanding_migration(
            staged_db,
            config.STATE_DB_MIGRATIONS_DIR,
            stop_event=stop_event,
        )
    finally:
        config.STATE_DB_LEDGER_SOURCE_DATABASE = previous_ledger_source

    staged_connection = database.get_db_connection(staged_db, read_only=False, check_wal=False)
    try:
        if stop_event is not None:
            staged_connection.set_progress_handler(
                lambda: 1 if stop_event.is_set() else 0,
                10_000,
            )
        check_result = staged_connection.execute("PRAGMA quick_check(1)").fetchone()
        if check_result is None:
            raise exceptions.DatabaseError("Replacement State DB quick_check returned no result")
        check_value = (
            next(iter(check_result.values())) if isinstance(check_result, dict) else check_result[0]
        )
        if check_value != "ok":
            raise exceptions.DatabaseError(
                f"Replacement State DB failed quick_check: {check_result!r}"
            )
    finally:
        if stop_event is not None:
            staged_connection.set_progress_handler(None, 0)
        staged_connection.close()
    _check_cancelled(stop_event)
    _checkpoint_database(staged_db)
    _fsync_file(staged_db)
    manifest = _replacement_manifest(staged_db, ledger_snapshot, stop_event=stop_event)
    _remove_database_files(ledger_snapshot)

    # The marker is created only after the replacement DB is closed, checked,
    # and checkpointed. An interrupted build therefore cannot be activated.
    _write_ready_manifest(ready_path, manifest)
    logger.warning(
        "Replacement State DB ready for activation after %.2fs.",
        time.monotonic() - started_at,
    )


def activate_staged_state_db():
    """Atomically activate a verified staged DB during API-child startup.

    The old database is retained as ``.previous``. If activation is
    interrupted between the two atomic renames, the ready marker and staged
    file remain and the next startup completes the operation.
    """
    staged_db = staged_state_db_path()
    ready_path = staged_state_db_ready_path()
    previous_db = previous_state_db_path()

    if not os.path.exists(ready_path):
        # A partial build has no marker and is never eligible for activation.
        discard_staged_state_db()
        return False

    if not os.path.exists(staged_db):
        # The staged file can disappear because activation completed, but it can
        # also be lost or manually removed. Consume the durable marker only if
        # the live DB is exactly the staged lineage described by its manifest.
        if os.path.exists(config.STATE_DATABASE):
            try:
                manifest = _read_ready_manifest(ready_path)
                if _manifest_is_current(
                    manifest,
                    config.STATE_DATABASE,
                    check_integrity=True,
                ):
                    _remove_database_files(staged_db)
                    os.unlink(ready_path)
                    _fsync_directory(os.path.dirname(config.STATE_DATABASE) or ".")
                    return True
            except Exception as error:  # pylint: disable=broad-except
                logger.error("Could not validate interrupted State DB activation: %s", error)
        raise exceptions.DatabaseError(
            "State DB activation marker exists, but the staged database is missing and the "
            "live database does not match its manifest"
        )

    try:
        manifest = _read_ready_manifest(ready_path)
        valid_manifest = _manifest_is_current(manifest, staged_db)
    except Exception as error:  # pylint: disable=broad-except
        logger.error("Discarding staged State DB with invalid manifest: %s", error)
        valid_manifest = False
    if not valid_manifest:
        logger.warning("Staged State DB lineage is stale or invalid; keeping live State DB.")
        if not os.path.exists(config.STATE_DATABASE) and os.path.exists(previous_db):
            os.replace(previous_db, config.STATE_DATABASE)
            _fsync_directory(os.path.dirname(config.STATE_DATABASE) or ".")
        discard_staged_state_db()
        return False

    live_moved = False
    try:
        if os.path.exists(config.STATE_DATABASE):
            # The old API child is fully stopped before activation. Fold every
            # committed WAL frame into the main file so the recovery copy is
            # self-contained and a crash between renames cannot pair the new
            # database with the old database's WAL.
            _checkpoint_database(config.STATE_DATABASE)
            _remove_database_files(previous_db)
            os.replace(config.STATE_DATABASE, previous_db)
            live_moved = True
        # Complete sidecar cleanup even when resuming an activation that
        # crashed immediately after moving the old main file.
        for suffix in ("-wal", "-shm"):
            live_sidecar = f"{config.STATE_DATABASE}{suffix}"
            if os.path.exists(live_sidecar):
                os.replace(live_sidecar, f"{previous_db}{suffix}")
        _fsync_directory(os.path.dirname(config.STATE_DATABASE) or ".")
        os.replace(staged_db, config.STATE_DATABASE)
        # A successful checkpoint should leave no WAL/SHM, but move either one
        # if SQLite retained it so no committed data can be separated.
        for suffix in ("-wal", "-shm"):
            staged_path = f"{staged_db}{suffix}"
            if os.path.exists(staged_path):
                os.replace(staged_path, f"{config.STATE_DATABASE}{suffix}")
        _fsync_directory(os.path.dirname(config.STATE_DATABASE) or ".")
        os.unlink(ready_path)
        _fsync_directory(os.path.dirname(config.STATE_DATABASE) or ".")
    except Exception:
        if live_moved and not os.path.exists(config.STATE_DATABASE):
            for previous_path, live_path in zip(
                _database_files(previous_db),
                _database_files(config.STATE_DATABASE),
                strict=True,
            ):
                if os.path.exists(previous_path):
                    os.replace(previous_path, live_path)
            _fsync_directory(os.path.dirname(config.STATE_DATABASE) or ".")
        raise

    logger.warning("Activated rebuilt State DB; previous database retained at %s.", previous_db)
    return True


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


def rollback_migrations(state_db, migration_ids):
    for migration_id in reversed(migration_ids):
        logger.debug("Rolling back migration `%s`...", migration_id)
        rollback_migration(state_db, migration_id)


def apply_migrations(state_db, migration_ids):
    for migration_id in migration_ids:
        logger.debug("Applying migration `%s`...", migration_id)
        apply_migration(state_db, migration_id)


def reapply_migrations(state_db, migration_ids):
    rollback_migrations(state_db, migration_ids)
    apply_migrations(state_db, migration_ids)


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
    with log.Spinner("Applying Ledger DB migrations"):
        database.apply_outstanding_migration(config.DATABASE, config.LEDGER_DB_MIGRATIONS_DIR)

    with log.Spinner("Applying migrations"):
        database.apply_outstanding_migration(config.STATE_DATABASE, config.STATE_DB_MIGRATIONS_DIR)

    with log.Spinner("Vacuuming State DB..."):
        state_db = database.get_db_connection(config.STATE_DATABASE, read_only=False)
        database.vacuum(state_db)
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
    logger.info("Rolling back State DB to block index %s...", block_index)
    start_time = time.time()

    with state_db:
        with log.Spinner("Rolling back State DB tables..."):
            rollback_tables(state_db, block_index)
        with log.Spinner("Re-applying migrations..."):
            reapply_migrations(state_db, MIGRATIONS_AFTER_ROLLBACK)
        # Record the ledger_db block index to prevent double-counting of balances
        # during catch-up (see record_balances_copied_block docstring for details)
        record_balances_copied_block(state_db)

    logger.info("State DB rolled back in %.2f seconds", time.time() - start_time)


def refresh_state_db(state_db):
    logger.info("Rebuilding non rollbackable tables in State DB...")
    start_time = time.time()

    with state_db:
        with log.Spinner("Re-applying migrations..."):
            reapply_migrations(state_db, MIGRATIONS_AFTER_ROLLBACK)
        # Record the ledger_db block index to prevent double-counting of balances
        # during catch-up (see record_balances_copied_block docstring for details)
        record_balances_copied_block(state_db)

    logger.info("State DB refreshed in %.2f seconds", time.time() - start_time)
