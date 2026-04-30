"""
Memory profiler for tracking memory usage and identifying leaks.

Enable via --memory-profile CLI flag.

Logs memory usage of:
- Process memory (RSS, VmData)
- tracemalloc top allocations
- Known caches (BLOCK_CACHE, OrdersCache, etc.)
"""

import gc
import logging
import platform
import sys
import threading
import tracemalloc

from counterpartycore.lib import config
from counterpartycore.lib.ledger.caches import AssetCache, OrdersCache, UTXOBalancesCache
from counterpartycore.lib.parser.follow import NotSupportedTransactionsCache
from counterpartycore.lib.utils import helpers
from counterpartycore.lib.utils.database import LedgerDBConnectionPool, StateDBConnectionPool

try:
    import resource
except ImportError:
    resource = None

logger = logging.getLogger(config.LOGGER_NAME)

# Default interval in seconds (5 minutes)
DEFAULT_PROFILE_INTERVAL = 300

# Number of top allocations to log
TOP_ALLOCATIONS = 10


def get_process_memory():
    """Get process memory stats from /proc/self/status (Linux only)."""
    try:
        with open("/proc/self/status", "r") as f:
            status = f.read()

        stats = {}
        for line in status.split("\n"):
            if line.startswith("VmRSS:"):
                stats["rss_kb"] = int(line.split()[1])
            elif line.startswith("VmData:"):
                stats["data_kb"] = int(line.split()[1])
            elif line.startswith("VmHWM:"):
                stats["hwm_kb"] = int(line.split()[1])
            elif line.startswith("RssAnon:"):
                stats["rss_anon_kb"] = int(line.split()[1])
            elif line.startswith("RssFile:"):
                stats["rss_file_kb"] = int(line.split()[1])
        return stats
    except (FileNotFoundError, IOError):
        # Not on Linux, try resource module
        if resource is None:
            return {}
        usage = resource.getrusage(resource.RUSAGE_SELF)
        # On macOS, ru_maxrss is in bytes; on Linux it's in KB
        if platform.system() == "Darwin":
            rss_kb = usage.ru_maxrss // 1024
        else:
            rss_kb = usage.ru_maxrss
        return {
            "rss_kb": rss_kb,
            "data_kb": 0,
            "hwm_kb": rss_kb,
        }


def estimate_dict_memory(d):
    """Estimate memory usage of a dictionary (shallow)."""
    if not d:
        return 0
    # Dict overhead + key/value pairs
    # This is approximate - actual memory can vary
    size = sys.getsizeof(d)
    # Sample first 100 items to estimate average
    sample_size = min(100, len(d))
    if sample_size > 0:
        items_iter = iter(d.items())
        sampled_items = [next(items_iter) for _ in range(sample_size)]
        avg_item_size = (
            sum(sys.getsizeof(k) + sys.getsizeof(v) for k, v in sampled_items) / sample_size
        )
        size += int(avg_item_size * len(d))
    return size


def estimate_list_memory(lst):
    """Estimate memory usage of a list (shallow)."""
    if not lst:
        return 0
    size = sys.getsizeof(lst)
    # Sample first 100 items to estimate average
    sample_size = min(100, len(lst))
    if sample_size > 0:
        avg_item_size = sum(sys.getsizeof(item) for item in lst[:sample_size]) / sample_size
        size += int(avg_item_size * len(lst))
    return size


def estimate_set_memory(s):
    """Estimate memory usage of a set (shallow)."""
    if not s:
        return 0
    size = sys.getsizeof(s)
    # Sample first 100 items to estimate average
    sample_size = min(100, len(s))
    if sample_size > 0:
        items_iter = iter(s)
        sampled_items = [next(items_iter) for _ in range(sample_size)]
        avg_item_size = sum(sys.getsizeof(item) for item in sampled_items) / sample_size
        size += int(avg_item_size * len(s))
    return size


def get_cache_sizes():
    """Get sizes of known caches."""
    sizes = {}

    # AssetCache
    if AssetCache in helpers.SingletonMeta._instances:
        cache = helpers.SingletonMeta._instances[AssetCache]
        assets = getattr(cache, "assets", {})
        total_issued = getattr(cache, "assets_total_issued", {})
        total_destroyed = getattr(cache, "assets_total_destroyed", {})

        sizes["AssetCache.assets"] = len(assets)
        sizes["AssetCache.assets_MB"] = estimate_dict_memory(assets) / (1024 * 1024)
        sizes["AssetCache.total_issued"] = len(total_issued)
        sizes["AssetCache.total_issued_MB"] = estimate_dict_memory(total_issued) / (1024 * 1024)
        sizes["AssetCache.total_destroyed"] = len(total_destroyed)
        sizes["AssetCache.total_destroyed_MB"] = estimate_dict_memory(total_destroyed) / (
            1024 * 1024
        )

    # OrdersCache
    if OrdersCache in helpers.SingletonMeta._instances:
        cache = helpers.SingletonMeta._instances[OrdersCache]
        if hasattr(cache, "cache_db") and cache.cache_db:
            try:
                cursor = cache.cache_db.cursor()
                cursor.execute("SELECT COUNT(*) FROM orders")
                row = cursor.fetchone()
                count = row[0] if row else 0
                sizes["OrdersCache.orders"] = count
                # Estimate: each order ~500 bytes in memory
                sizes["OrdersCache.orders_MB"] = (count * 500) / (1024 * 1024)
            except Exception:
                sizes["OrdersCache.orders"] = "error"

    # UTXOBalancesCache
    if UTXOBalancesCache in helpers.SingletonMeta._instances:
        cache = helpers.SingletonMeta._instances[UTXOBalancesCache]
        utxos = getattr(cache, "utxos_with_balance", {})
        sizes["UTXOBalancesCache.utxos"] = len(utxos)
        sizes["UTXOBalancesCache.utxos_MB"] = estimate_dict_memory(utxos) / (1024 * 1024)

    # NotSupportedTransactionsCache
    if NotSupportedTransactionsCache in helpers.SingletonMeta._instances:
        cache = helpers.SingletonMeta._instances[NotSupportedTransactionsCache]
        not_supported = getattr(cache, "not_suppported_txs", set())
        sizes["NotSupportedTxCache"] = len(not_supported)
        sizes["NotSupportedTxCache_MB"] = estimate_set_memory(not_supported) / (1024 * 1024)

    # BLOCK_CACHE (global in apiserver) - import deferred to avoid circular import
    try:
        from counterpartycore.lib.api import apiserver  # noqa: PLC0415

        sizes["BLOCK_CACHE"] = len(getattr(apiserver, "BLOCK_CACHE", {}))

        # Estimate memory usage of BLOCK_CACHE values
        if hasattr(apiserver, "BLOCK_CACHE"):
            total_size = 0
            # Copy items to avoid mutation during iteration
            try:
                items = list(apiserver.BLOCK_CACHE.items())
                for key, value in items:
                    total_size += sys.getsizeof(key) + sys.getsizeof(value)
                sizes["BLOCK_CACHE_bytes"] = total_size
            except RuntimeError:
                # Cache was modified during iteration, skip size calculation
                sizes["BLOCK_CACHE_bytes"] = "skipped"
    except ImportError:
        pass

    # Connection pool sizes
    if LedgerDBConnectionPool in helpers.SingletonMeta._instances:
        pool = helpers.SingletonMeta._instances[LedgerDBConnectionPool]
        if hasattr(pool, "_pool"):
            sizes["LedgerDBPool"] = pool._pool.qsize() if hasattr(pool._pool, "qsize") else "N/A"

    if StateDBConnectionPool in helpers.SingletonMeta._instances:
        pool = helpers.SingletonMeta._instances[StateDBConnectionPool]
        if hasattr(pool, "_pool"):
            sizes["StateDBPool"] = pool._pool.qsize() if hasattr(pool._pool, "qsize") else "N/A"

    return sizes


def get_tracemalloc_top(limit=TOP_ALLOCATIONS):
    """Get top memory allocations from tracemalloc."""
    if not tracemalloc.is_tracing():
        return []

    snapshot = tracemalloc.take_snapshot()
    # Filter out tracemalloc's own allocations
    snapshot = snapshot.filter_traces(
        (
            tracemalloc.Filter(False, "<frozen importlib._bootstrap>"),
            tracemalloc.Filter(False, "<frozen importlib._bootstrap_external>"),
            tracemalloc.Filter(False, tracemalloc.__file__),
        )
    )

    top_stats = snapshot.statistics("lineno")[:limit]

    results = []
    for stat in top_stats:
        results.append(
            {
                "file": str(stat.traceback),
                "size_kb": stat.size / 1024,
                "count": stat.count,
            }
        )

    return results


def log_memory_profile():
    """Log current memory profile."""
    # Force garbage collection first
    gc.collect()

    # Process memory
    proc_mem = get_process_memory()
    if proc_mem:
        # Log basic memory stats
        msg_parts = [
            f"RSS={proc_mem.get('rss_kb', 0) / 1024:.1f}MB",
            f"Data={proc_mem.get('data_kb', 0) / 1024:.1f}MB",
            f"HWM={proc_mem.get('hwm_kb', 0) / 1024:.1f}MB",
        ]

        # Add RssAnon and RssFile if available (Linux only)
        if "rss_anon_kb" in proc_mem:
            msg_parts.append(f"RssAnon={proc_mem['rss_anon_kb'] / 1024:.1f}MB")
        if "rss_file_kb" in proc_mem:
            msg_parts.append(f"RssFile={proc_mem['rss_file_kb'] / 1024:.1f}MB")

        logger.info("Memory Profile - Process: %s", ", ".join(msg_parts))

    # Cache sizes
    cache_sizes = get_cache_sizes()
    if cache_sizes:
        cache_info = ", ".join(f"{k}={v}" for k, v in sorted(cache_sizes.items()))
        logger.info("Memory Profile - Caches: %s", cache_info)

    # tracemalloc top allocations
    top_allocs = get_tracemalloc_top(5)
    if top_allocs:
        for i, alloc in enumerate(top_allocs, 1):
            logger.info(
                "Memory Profile - Top %d: %.1fKB (%d blocks) @ %s",
                i,
                alloc["size_kb"],
                alloc["count"],
                alloc["file"][:100],  # Truncate long paths
            )

    # tracemalloc total
    if tracemalloc.is_tracing():
        current, peak = tracemalloc.get_traced_memory()
        logger.info(
            "Memory Profile - tracemalloc: current=%.1fMB, peak=%.1fMB",
            current / 1024 / 1024,
            peak / 1024 / 1024,
        )


class MemoryProfiler(threading.Thread):
    """Background thread that periodically logs memory usage."""

    def __init__(self, interval_seconds=None):
        super().__init__(daemon=True, name="MemoryProfiler")
        self.interval = interval_seconds or DEFAULT_PROFILE_INTERVAL
        self.stop_event = threading.Event()

    def run(self):
        """Main loop - log memory profile at regular intervals."""
        logger.info(
            "Memory profiler started (interval=%ds, tracemalloc=%s)",
            self.interval,
            "enabled" if tracemalloc.is_tracing() else "disabled",
        )

        while not self.stop_event.is_set():
            try:
                log_memory_profile()
            except Exception as e:
                logger.error("Error in memory profiler: %s", e)

            # Wait for interval or stop event
            self.stop_event.wait(self.interval)

        logger.info("Memory profiler stopped")

    def stop(self):
        """Stop the profiler thread."""
        self.stop_event.set()


# Module-level state container (avoids global statement)
_state = {"profiler": None}


def start_memory_profiler(interval_seconds=None, enable_tracemalloc=True):
    """
    Start the memory profiler.

    Args:
        interval_seconds: Logging interval (default: 300 = 5 minutes)
        enable_tracemalloc: Whether to enable tracemalloc for allocation tracking
    """
    if _state["profiler"] is not None:
        logger.warning("Memory profiler already running")
        return _state["profiler"]

    # Start tracemalloc if requested
    if enable_tracemalloc and not tracemalloc.is_tracing():
        tracemalloc.start(10)  # Keep 10 frames of traceback
        logger.info("tracemalloc started")

    # Create and start profiler thread
    _state["profiler"] = MemoryProfiler(interval_seconds)
    _state["profiler"].start()

    return _state["profiler"]


def stop_memory_profiler():
    """Stop the memory profiler if running."""
    if _state["profiler"] is not None:
        _state["profiler"].stop()
        _state["profiler"].join(timeout=5)
        _state["profiler"] = None

    if tracemalloc.is_tracing():
        tracemalloc.stop()
        logger.info("tracemalloc stopped")
