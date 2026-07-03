from collections import OrderedDict

BLOCK_CACHE = OrderedDict()

# Per-key row counts and a running total, so the cache can be bounded by total
# rows (a memory proxy) in addition to entry count. A row count is an O(1) proxy
# for an entry's memory (len of its result list); true byte sizing would be
# O(rows*cols) on every cache miss, adding latency to the path we want cheap.
# These are mutated only via cache_insert(), under the same lock-free,
# GIL-atomic model as BLOCK_CACHE itself.
BLOCK_CACHE_SIZES = {}
BLOCK_CACHE_ROWS = 0


def estimate_rows(value):
    """O(1) row-count proxy for a cached value: the number of rows in its result
    list (CachedResponse.result / QueryResult.result). A single-object result
    (a dict) or any non-list value counts as one row."""
    result = getattr(value, "result", value)
    if isinstance(result, (list, tuple)):
        return len(result) or 1
    return 1


def reset_block_cache():
    """Clear the cache and its row accounting (used by tests)."""
    global BLOCK_CACHE_ROWS  # noqa: PLW0603  # pylint: disable=global-statement
    BLOCK_CACHE.clear()
    BLOCK_CACHE_SIZES.clear()
    BLOCK_CACHE_ROWS = 0


def cache_insert(cache_key, value, max_entries, max_rows):
    """Insert value and FIFO-evict oldest entries until within BOTH the entry
    count cap and the row budget. max_rows <= 0 disables the row bound. The
    `and BLOCK_CACHE` guard just stops the loop on an empty dict (never popitem
    on empty); note a single entry larger than max_rows would itself be evicted
    on insert -- not reachable today since a page caps at API_LIMIT_ROWS, well
    below the budget. The running total is clamped >= 0 to self-heal drift from
    the lock-free concurrent updates."""
    global BLOCK_CACHE_ROWS  # noqa: PLW0603  # pylint: disable=global-statement
    # account for overwriting an existing key
    BLOCK_CACHE_ROWS -= BLOCK_CACHE_SIZES.pop(cache_key, 0)
    BLOCK_CACHE[cache_key] = value
    rows = estimate_rows(value)
    BLOCK_CACHE_SIZES[cache_key] = rows
    BLOCK_CACHE_ROWS += rows
    while BLOCK_CACHE and (
        len(BLOCK_CACHE) > max_entries or (0 < max_rows < BLOCK_CACHE_ROWS)
    ):
        evicted_key, _ = BLOCK_CACHE.popitem(last=False)
        BLOCK_CACHE_ROWS -= BLOCK_CACHE_SIZES.pop(evicted_key, 0)
    BLOCK_CACHE_ROWS = max(BLOCK_CACHE_ROWS, 0)
