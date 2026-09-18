"""The State DB's replay cursor over ``parsed_events``.

Both the API watcher and the incremental rollback have to agree on where the
State DB has got to: the watcher advances the cursor, the rollback moves it
back. Keeping the queries and the cached values here rather than in
``apiwatcher`` is what lets ``staterollback`` read them without importing the
watcher -- which closed an ``apiwatcher -> dbbuilder -> staterollback ->
apiwatcher`` import cycle, and left the rollback pulling in the whole watcher
module for four names.

This module must stay a leaf: anything it imports is imported by the rollback
path too.
"""

import logging

from counterpartycore.lib import config
from counterpartycore.lib.utils import database

logger = logging.getLogger(config.LOGGER_NAME)


# `parsed_events` carries an index on `event` (`parsed_events_event_idx`) and a
# unique index on `event_index` (`parsed_events_event_index_idx`). For a query
# filtered on `event = 'BLOCK_PARSED'` and ordered by `event_index DESC`, SQLite
# picks the `event` index and then builds a temporary B-tree to sort every
# BLOCK_PARSED row it found -- on a cold mainnet State DB that is minutes of I/O
# to return a single row, on paths that run at every API process start
# (`APIWatcher.__init__` -> `get_last_block_parsed`, then `catch_up` ->
# `check_reorg`) and on every reorganization check afterwards.
#
# Forcing the event-index index instead makes SQLite reverse-scan from the newest
# event and stop as soon as the LIMIT is satisfied. The ORDER BY and LIMIT are
# unchanged, so the ordering semantics are identical; only the access path differs.
#
# `LAST_PARSED_EVENT_SQL` carries no `event` filter, so that plan was never open to
# it; it is pinned to the same index anyway, to keep one access path across all
# three queries and to fail loudly if the index is ever dropped.
#
# `INDEXED BY` is a hard requirement rather than a hint: `parsed_events_event_index_idx`
# is created by migration 0002 and dropping or renaming it makes these queries fail
# outright instead of silently regressing to the slow plan.
LAST_BLOCK_PARSED_SQL = """
    SELECT block_index
    FROM parsed_events INDEXED BY parsed_events_event_index_idx
    WHERE event = 'BLOCK_PARSED'
    ORDER BY event_index DESC
    LIMIT 1
"""

# The last event the State DB parsed, whole row: what `check_reorg` compares
# against the Ledger DB. Neither restriction the historical query carried is safe
# here, and each one hid a different reorganization:
#
#   - `LIMIT 1 OFFSET 1` skipped to the block *before* the last one parsed, which
#     makes the shallowest and by far the most common reorganization -- the tip
#     block replaced by another at the same height -- invisible: the only parsed
#     event whose hash changed is the one the comparison steps over, and the next
#     block on the new branch then appends on top of the orphaned one.
#
#   - `WHERE event = 'BLOCK_PARSED'` compared the last *block* rather than the last
#     *event*. The watcher advances one event at a time (`get_next_event_to_parse`
#     orders by `message_index`, not by block), so between two blocks it sits with
#     part of a block copied and that block's BLOCK_PARSED not yet written. A
#     rollback landing in that window leaves the last BLOCK_PARSED -- the previous
#     block's, untouched by the reorganization -- matching, so the check passes
#     while the State DB holds orphaned events of the block it was in the middle
#     of. Nothing ever repairs that: every BLOCK_PARSED compared afterwards comes
#     from the new branch and matches.
#
# Comparing the newest row cannot yield a false positive: the State DB only ever
# copies events the Ledger DB has committed, whatever their type, so the hash at
# that `message_index` differs only if the ledger really did roll back.
#
# `search_matching_event` keeps the `BLOCK_PARSED` filter -- it looks for the
# rollback *target*, which is a block index.
LAST_PARSED_EVENT_SQL = """
    SELECT *
    FROM parsed_events INDEXED BY parsed_events_event_index_idx
    ORDER BY event_index DESC
    LIMIT 1
"""

# Same plan, unbounded: `search_matching_event` walks back until it finds a
# BLOCK_PARSED row whose hash still matches the Ledger DB. The reverse scan also
# lets that walk stop after the first few blocks in the common shallow-reorg case,
# instead of first sorting every BLOCK_PARSED row ever written.
BLOCKS_PARSED_DESC_SQL = """
    SELECT *
    FROM parsed_events INDEXED BY parsed_events_event_index_idx
    WHERE event = 'BLOCK_PARSED'
    ORDER BY event_index DESC
"""


def fetch_one(db, query, bindings=None):
    cursor = db.cursor()
    cursor.execute(query, bindings)
    return cursor.fetchone()


def get_last_parsed_event_index(state_db, no_cache=False):
    if not no_cache:
        event_index = database.get_config_value(state_db, "LAST_EVENT_PARSED")
        if event_index is not None:
            return int(event_index)
    cursor = state_db.cursor()
    cursor.execute("SELECT event_index FROM parsed_events ORDER BY event_index DESC LIMIT 1")
    parsed_event = cursor.fetchone()
    if parsed_event:
        return parsed_event["event_index"]
    return 0


def get_last_block_parsed(state_db, no_cache=False):
    if not no_cache:
        block_index = database.get_config_value(state_db, "LAST_BLOCK_PARSED")
        if block_index is not None:
            return int(block_index)
    cursor = state_db.cursor()
    cursor.execute(LAST_BLOCK_PARSED_SQL)
    parsed_event = cursor.fetchone()
    if parsed_event:
        return parsed_event["block_index"]
    return 0


def get_last_block_touched(state_db):
    """The block index of the last event the State DB copied, finished or not.

    Differs from `get_last_block_parsed` exactly while a block is half copied:
    that one reports the last block *completed* -- the one whose BLOCK_PARSED is
    written -- while this one reports the block the watcher is currently inside.

    A rollback target has to be compared against this one. The orphaned rows of a
    half-copied block sit one block above the completed tip, so measuring against
    the completed tip reads them as "already below the target" and leaves them in
    place -- which is precisely the case `check_reorg` aims at when it rolls back
    to `last_block_parsed + 1`. See `staterollback.rollback_reason`.

    Deliberately uncached: `LAST_BLOCK_PARSED` only advances on a BLOCK_PARSED
    event, which is what makes it the wrong number here, and there is no cached
    counterpart for a block still being copied. Callers are on the rollback path,
    where one index lookup does not matter.
    """
    last_event_parsed = fetch_one(state_db, LAST_PARSED_EVENT_SQL)
    if last_event_parsed is None:
        return 0
    return last_event_parsed["block_index"]


def update_last_parsed_events_cache(state_db, event=None):
    if event is None:
        last_event_parsed = get_last_parsed_event_index(state_db, no_cache=True)
        last_block_parsed = get_last_block_parsed(state_db, no_cache=True)
        database.set_config_value(state_db, "LAST_BLOCK_PARSED", last_block_parsed)
        database.set_config_value(state_db, "LAST_EVENT_PARSED", last_event_parsed)
    else:
        last_event_parsed = event["message_index"]
        last_block_parsed = event["block_index"]
        if event["event"] == "BLOCK_PARSED":
            database.set_config_value(state_db, "LAST_BLOCK_PARSED", last_block_parsed)
        database.set_config_value(state_db, "LAST_EVENT_PARSED", last_event_parsed)
