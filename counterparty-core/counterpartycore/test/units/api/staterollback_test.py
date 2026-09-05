"""Tests for the incremental State DB rollback (issue #3485).

The two tests that matter here are differential: the incremental rollback
replaces "re-derive everything from the ledger" with "undo what changed", and
the only way that is trustworthy is to check, table by table, that it lands on
exactly the same State DB the full rebuild would have produced -- and that a
rollback followed by the watcher's forward replay is a no-op.
"""

import pytest
from counterpartycore.lib import config
from counterpartycore.lib.api import apiwatcher, dbbuilder, staterollback, statetables
from counterpartycore.lib.parser import blocks
from counterpartycore.lib.utils import database

# Tables whose contents are not derived from the ledger (yoyo bookkeeping) or
# whose contents legitimately differ between a rebuild and a rollback (the
# ``config`` table holds the version string, the rollback marker and the
# rebuild-only ``BALANCES_COPIED_AT_BLOCK`` guard).
NON_DERIVED_TABLES = {"config"}


def _derived_tables(db):
    rows = db.execute(
        "SELECT name FROM sqlite_master WHERE type = 'table' ORDER BY name"
    ).fetchall()
    return [
        row["name"]
        for row in rows
        if not row["name"].startswith("_yoyo")
        and not row["name"].startswith("sqlite_")
        and row["name"] not in NON_DERIVED_TABLES
    ]


def _dump_table(db, table):
    """Order-independent, type-stable snapshot of a table's contents."""
    rows = db.execute(f"SELECT * FROM {table}").fetchall()  # noqa: S608  # nosec B608
    return sorted(repr(sorted(row.items())) for row in rows)


def _dump_state_db(db):
    return {table: _dump_table(db, table) for table in _derived_tables(db)}


def _assert_same_state(expected, actual, context):
    assert set(expected) == set(actual), f"{context}: table sets differ"
    for table in sorted(expected):
        assert expected[table] == actual[table], (
            f"{context}: `{table}` differs "
            f"({len(expected[table])} expected rows vs {len(actual[table])})"
        )


def _foreign_keys(db):
    return db.execute("PRAGMA foreign_keys").fetchone()["foreign_keys"]


def _last_block(db):
    return db.execute("SELECT MAX(block_index) AS block_index FROM blocks").fetchone()[
        "block_index"
    ]


def _nth_last_active_block(db, count):
    """Block index of the ``count``-th most recent block that actually contains
    transactions. The fixture ends on a long run of empty blocks, so rolling
    back "N blocks from the tip" would revert nothing at all and make these
    tests vacuous."""
    rows = db.execute(
        "SELECT DISTINCT block_index FROM transactions ORDER BY block_index DESC LIMIT ?",
        (count,),
    ).fetchall()
    return rows[-1]["block_index"]


def _block_of_last_split_fairmint(db):
    """Block of the most recent fairmint on a fairminter that has fairmints in
    more than one block. Rolling back to it leaves the fairminter itself alive
    (restored to an earlier version) while dropping some of its fairmints --
    the only way to exercise the recomputation of earned_quantity /
    paid_quantity / commission, which are aggregated from fairmints
    rather than copied from the ledger row."""
    row = db.execute(
        """
        SELECT MAX(block_index) AS block_index FROM fairmints
        WHERE status = 'valid'
        GROUP BY fairminter_tx_index
        HAVING COUNT(DISTINCT block_index) > 1
        ORDER BY block_index DESC LIMIT 1
        """
    ).fetchone()
    assert row is not None, "the fixture no longer has a multi-block fairminter"
    return row["block_index"]


def _events_of_block(db, block_index):
    return db.execute(
        "SELECT * FROM messages WHERE block_index = ? ORDER BY message_index", (block_index,)
    ).fetchall()


def _touched_objects(db, target):
    """How many consolidated objects the rollback will have to revert."""
    return {
        table: db.execute(
            f"SELECT COUNT(*) AS count FROM {table} WHERE block_index >= ?",  # noqa: S608  # nosec B608
            (target,),
        ).fetchone()["count"]
        for table in statetables.STATE_CONSOLIDATED_KEYS
    }


# =============================================================================
# Differential tests
# =============================================================================

# (case id, target selector, deep-rollback cap override). Targets are chosen
# from the fixture's *active* blocks: its tip sits ~700 empty blocks past the
# last transaction, so "N blocks from the tip" would revert nothing at all.
# The last case reverts essentially the whole fixture -- every consolidated
# table, utxo balances and match tables included -- which needs the depth cap
# lifted for that reason.
ROLLBACK_CASES = [
    ("1-active-block", lambda db: _nth_last_active_block(db, 1), None),
    ("3-active-blocks", lambda db: _nth_last_active_block(db, 3), None),
    ("10-active-blocks", lambda db: _nth_last_active_block(db, 10), None),
    ("30-active-blocks", lambda db: _nth_last_active_block(db, 30), None),
    ("mid-fairminter", _block_of_last_split_fairmint, None),
    ("whole-fixture", lambda db: _nth_last_active_block(db, 60), 5000),
]


@pytest.mark.parametrize(("case", "select_target", "depth_cap"), ROLLBACK_CASES)
def test_incremental_rollback_matches_full_rebuild(
    state_db, ledger_db, monkeypatch, case, select_target, depth_cap
):
    """A reorganization must leave the State DB exactly where a from-scratch
    rebuild against the same rolled-back ledger would. This is the test that
    makes the incremental path trustworthy: the failure mode it guards against
    is a silent divergence no API response would reveal."""
    if depth_cap is not None:
        monkeypatch.setattr(staterollback, "MAX_INCREMENTAL_DEPTH", depth_cap)
    target = select_target(ledger_db)
    touched = _touched_objects(state_db, target)
    assert sum(touched.values()) > 0, "nothing would be reverted; the test is vacuous"

    # The Ledger DB always rolls back first; the API watcher reacts afterwards.
    blocks.rollback(ledger_db, block_index=target, force=True)

    assert staterollback.rollback_reason(state_db, target) is None
    dbbuilder.rollback_state_db(state_db, target)
    incremental = _dump_state_db(state_db)

    # Rebuild from scratch against the same ledger and compare.
    state_db.close()
    database.StateDBConnectionPool().close()
    dbbuilder.build_state_db()
    rebuilt_db = database.get_db_connection(config.STATE_DATABASE, read_only=True)
    try:
        rebuilt = _dump_state_db(rebuilt_db)
    finally:
        rebuilt_db.close()

    _assert_same_state(rebuilt, incremental, f"{case}: rollback to block {target} ({touched})")


@pytest.mark.parametrize(("case", "select_target", "depth_cap"), ROLLBACK_CASES)
def test_rollback_then_replay_is_a_noop(
    state_db, ledger_db, monkeypatch, case, select_target, depth_cap
):
    """Rolling the State DB back and letting the watcher replay the same blocks
    must reproduce it exactly. This covers the other half of the contract: the
    streamed handlers have to be able to run on top of reverted rows."""
    if depth_cap is not None:
        monkeypatch.setattr(staterollback, "MAX_INCREMENTAL_DEPTH", depth_cap)
    before = _dump_state_db(state_db)
    target = select_target(ledger_db)
    assert sum(_touched_objects(state_db, target).values()) > 0

    dbbuilder.rollback_state_db(state_db, target)
    assert _dump_state_db(state_db) != before, "rollback did not change anything"

    apiwatcher.catch_up(ledger_db, state_db)
    _assert_same_state(before, _dump_state_db(state_db), f"{case}: replay from block {target}")


def test_rollback_reverts_balances(state_db, ledger_db):
    """Spot check on the table the whole design hinges on."""
    target = _nth_last_active_block(ledger_db, 10)
    expected = ledger_db.execute(
        """
        SELECT COUNT(*) AS count FROM (
            SELECT MAX(rowid) FROM balances WHERE block_index < ?
            GROUP BY address, utxo_tx_hash, utxo_vout, asset
        )
        """,
        (target,),
    ).fetchone()["count"]

    blocks.rollback(ledger_db, block_index=target, force=True)
    dbbuilder.rollback_state_db(state_db, target)

    assert (
        state_db.execute("SELECT COUNT(*) AS count FROM balances").fetchone()["count"] == expected
    )
    assert (
        state_db.execute(
            "SELECT COUNT(*) AS count FROM balances WHERE block_index >= ?", (target,)
        ).fetchone()["count"]
        == 0
    )


# =============================================================================
# Fallback conditions
# =============================================================================


def test_full_rebuild_for_block_zero(state_db, ledger_db):
    assert staterollback.rollback_reason(state_db, 0) == "full rollback requested"


def test_full_rebuild_for_deep_rollback(state_db, ledger_db):
    last_block = apiwatcher.get_last_block_parsed(state_db, no_cache=True)
    target = max(1, last_block - staterollback.MAX_INCREMENTAL_DEPTH)
    reason = staterollback.rollback_reason(state_db, target)
    assert reason is not None and "exceeds" in reason


def test_full_rebuild_when_marker_missing(state_db, ledger_db):
    """A State DB built by an older release has stale ``balances.block_index``
    values, so it must not take the incremental path."""
    database.set_config_value(state_db, staterollback.READY_FLAG, None)
    assert (
        staterollback.rollback_reason(state_db, _last_block(ledger_db))
        == "State DB predates incremental rollback support"
    )


def test_rollback_undoes_a_half_copied_block(state_db, ledger_db):
    """The watcher advances one event at a time, so between two blocks it sits
    with part of a block copied and that block's BLOCK_PARSED not yet written.
    A reorganization caught there targets ``last_block_parsed + 1``, which reads
    as "above the State DB's tip" if the tip is measured by completed blocks --
    and answering NOTHING_TO_ROLL_BACK leaves the orphaned rows of the block in
    progress, plus the mutations they applied, in place forever.

    Undoing a half-copied block must land exactly where the block started."""
    target = _nth_last_active_block(ledger_db, 1)

    # Put the State DB back to the start of `target`, then copy that block event
    # by event and stop before its BLOCK_PARSED.
    dbbuilder.rollback_state_db(state_db, target)
    at_block_start = _dump_state_db(state_db)

    events = _events_of_block(ledger_db, target)
    assert len(events) > 1, "the test needs a block with events before its BLOCK_PARSED"
    assert events[-1]["event"] == "BLOCK_PARSED"
    for event in events[:-1]:
        apiwatcher.parse_event(state_db, event, ledger_db=ledger_db)
    assert _dump_state_db(state_db) != at_block_start, "nothing was copied; the test is vacuous"

    # The premise: the last block *completed* is still the one below the target,
    # untouched by the reorganization -- only the last block *touched* sees it.
    assert apiwatcher.get_last_block_parsed(state_db, no_cache=True) == target - 1
    assert apiwatcher.get_last_block_touched(state_db) == target

    assert staterollback.rollback_reason(state_db, target) is None
    dbbuilder.rollback_state_db(state_db, target)

    _assert_same_state(
        at_block_start, _dump_state_db(state_db), f"half-copied block {target} rolled back"
    )


def test_nothing_to_roll_back_is_a_noop(state_db, ledger_db, monkeypatch):
    """A target above the State DB's own tip has nothing to undo. Re-deriving
    every table from the whole ledger history to achieve that would be the most
    expensive no-op available -- the watcher just replays forward instead."""
    target = apiwatcher.get_last_block_touched(state_db) + 1
    assert staterollback.rollback_reason(state_db, target) == staterollback.NOTHING_TO_ROLL_BACK

    before = _dump_state_db(state_db)
    rebuilt = []
    monkeypatch.setattr(
        dbbuilder, "full_rollback_state_db", lambda db, block_index: rebuilt.append(block_index)
    )
    dbbuilder.rollback_state_db(state_db, target)

    assert rebuilt == [], "a no-op rollback triggered a full rebuild"
    _assert_same_state(before, _dump_state_db(state_db), "no-op rollback")


def test_incremental_failure_falls_back_to_the_full_rebuild(state_db, ledger_db, monkeypatch):
    """The incremental path is an optimization; the full rebuild is the ground
    truth. A failure must degrade to it, not propagate: the caller is
    ``apiwatcher.check_reorg()`` on the watcher thread, which has no handler for
    it and would die, freezing the State DB behind the Ledger DB."""
    target = _nth_last_active_block(ledger_db, 3)
    before = _dump_state_db(state_db)

    def boom(*args, **kwargs):
        raise RuntimeError("simulated incremental failure")

    # Fail *after* the prune and the consolidated restore have written rows, so
    # the test also proves the enclosing transaction undoes them.
    monkeypatch.setattr(staterollback, "_rollback_events_count", boom)
    rebuilt = []
    monkeypatch.setattr(
        dbbuilder, "full_rollback_state_db", lambda db, block_index: rebuilt.append(block_index)
    )

    dbbuilder.rollback_state_db(state_db, target)

    assert rebuilt == [target], "a failed incremental rollback did not fall back"
    _assert_same_state(
        before, _dump_state_db(state_db), "a failed incremental rollback left rows behind"
    )


def test_unreadable_state_db_selects_the_full_rebuild(state_db, ledger_db, monkeypatch):
    """`rollback_reason` only picks a path, so *any* failure to inspect the
    State DB has to select the full rebuild rather than propagate."""

    def boom(*args, **kwargs):
        raise ValueError("invalid literal for int()")

    monkeypatch.setattr(apiwatcher, "get_last_block_touched", boom)
    reason = staterollback.rollback_reason(state_db, _last_block(ledger_db))
    assert reason is not None and "cannot be inspected" in reason


def test_foreign_keys_are_disabled_outside_the_transaction(state_db, ledger_db, monkeypatch):
    """``PRAGMA foreign_keys`` is a documented no-op inside a transaction, so the
    guard has to be set before the rollback opens one -- and restored after."""
    seen = []
    real_rollback = staterollback.rollback

    def record(db, block_index):
        seen.append(_foreign_keys(db))
        return real_rollback(db, block_index)

    monkeypatch.setattr(staterollback, "rollback", record)
    dbbuilder.rollback_state_db(state_db, _nth_last_active_block(ledger_db, 1))

    assert seen == [0], "foreign key enforcement was still on during the rollback"
    assert _foreign_keys(state_db) == 1, "foreign key enforcement was not restored"


def test_full_rebuild_marks_state_db_ready(state_db, ledger_db):
    database.set_config_value(state_db, staterollback.READY_FLAG, None)
    dbbuilder.rollback_state_db(state_db, _last_block(ledger_db))
    assert staterollback.is_ready(state_db)


def test_build_state_db_marks_ready(state_db, ledger_db):
    assert staterollback.is_ready(state_db)


# =============================================================================
# Invariants the incremental path relies on
# =============================================================================


def test_state_keys_agree_with_ledger_keys():
    """The State DB key columns must be the Ledger DB grouping columns, with
    the single documented exception of ``balances``' utxo pair."""
    ledger_keys = dict(statetables.LEDGER_CONSOLIDATED_KEYS)
    ledger_keys.update(statetables.LEDGER_POOL_KEYS)
    # ``pool_matches`` is append-only (keyed on rowid); it is pruned, not restored.
    del ledger_keys["pool_matches"]

    assert set(ledger_keys) == set(statetables.STATE_CONSOLIDATED_KEYS)
    for table, columns in statetables.STATE_CONSOLIDATED_KEYS.items():
        expected = [column.strip() for column in ledger_keys[table].split(",")]
        if table == "balances":
            expected = ["address", "utxo", "asset"]
        assert columns == expected, f"{table} key columns drifted"


def test_every_consolidated_table_has_a_block_index_index(state_db):
    """``WHERE block_index >= ?`` is how the rollback finds what to revert; on a
    mainnet-sized table a missing index turns that seek into a full scan."""
    for table in statetables.STATE_CONSOLIDATED_KEYS:
        indexed = state_db.execute(
            "SELECT COUNT(*) AS count FROM sqlite_master "
            "WHERE type = 'index' AND tbl_name = ? AND sql LIKE '%block_index%'",
            (table,),
        ).fetchone()["count"]
        assert indexed > 0, f"`{table}` has no index on block_index"


def test_ledger_lookup_uses_an_index(state_db, ledger_db):
    """The per-object ledger lookup must be an index SEARCH. A SCAN here would
    be a full table scan *per reverted object* -- catastrophically worse than
    the full rebuild it replaces."""
    staterollback.attach_ledger_db(state_db)
    for table, key_columns in statetables.STATE_CONSOLIDATED_KEYS.items():
        match = " AND ".join(
            staterollback._ledger_match_clause(column)  # noqa: SLF001
            for column in key_columns
        )
        plan = state_db.execute(
            f"""
            EXPLAIN QUERY PLAN
            SELECT s.rowid, (
                SELECT MAX(b.rowid) FROM ledger_db.{table} b
                WHERE {match} AND b.block_index < 1
            ) FROM {table} s WHERE s.block_index >= 1
            """  # noqa: S608  # nosec B608
        ).fetchall()
        details = [row["detail"] for row in plan]
        scans = [
            detail for detail in details if detail.startswith("SCAN") and f"{table} AS b" in detail
        ]
        assert not scans, f"ledger lookup on `{table}` full-scans: {details}"


def test_projection_covers_every_state_column(state_db, ledger_db):
    """Every consolidated-table column must either be copied from the ledger or
    be maintained by an explicit pass; a column silently dropped from the
    projection would come back NULL after a rollback."""
    # ``fairminters``' aggregates are recomputed from ``fairmints`` by
    # ``_refresh_fairminter_totals``, not copied from the ledger row.
    maintained_separately = {"fairminters": {"earned_quantity", "paid_quantity", "commission"}}
    staterollback.attach_ledger_db(state_db)
    for table in statetables.STATE_CONSOLIDATED_KEYS:
        names, expressions = statetables.consolidated_projection(state_db, table)
        assert len(names) == len(expressions)
        columns = {
            column["name"] for column in state_db.execute(f"PRAGMA table_info({table})").fetchall()
        }
        missing = columns - set(names) - maintained_separately.get(table, set())
        assert not missing, f"`{table}` columns absent from the projection: {missing}"


def test_orphan_events_drive_the_optional_passes(state_db, ledger_db):
    """``assets_info`` / ``transaction_types_count`` are only re-derived when
    the orphaned blocks actually contained the relevant events."""
    staterollback.attach_ledger_db(state_db)
    target = _last_block(ledger_db)
    counts = staterollback._collect_orphan_events(state_db, target)  # noqa: SLF001
    state_db.execute("DROP TABLE temp.rollback_events")
    assert counts, "the fixture's last block should produce events"
    assert counts["BLOCK_PARSED"] == 1
