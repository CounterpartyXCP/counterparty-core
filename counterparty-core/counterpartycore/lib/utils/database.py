import logging
import os
import re
import threading
import time
import weakref
from collections import OrderedDict
from contextlib import contextmanager

import apsw
import apsw.bestpractice
import apsw.ext
import psutil
from counterpartycore.lib import config, exceptions
from counterpartycore.lib.utils import hashcodec, helpers
from termcolor import cprint
from yoyo import get_backend, read_migrations
from yoyo.exceptions import LockTimeout

apsw.bestpractice.apply(apsw.bestpractice.recommended)  # includes WAL mode

logger = logging.getLogger(config.LOGGER_NAME)
apsw.ext.log_sqlite(logger=logger)


# Local reference for the rowtracer hot path: avoids the per-call attribute
# lookup ``hashcodec.HASH_COLUMN_NAMES``. The rowtracer runs once per row per
# column so trimming a few attribute lookups matters in the load test.
_HASH_COLUMN_NAMES = hashcodec.HASH_COLUMN_NAMES


# Columns that store the compact integer ``asset_index`` foreign key (see the
# asset-normalization rewrite in ``0010``). On read the rowtracer transparently
# decodes the index back to the asset *name* so the rest of the codebase
# (consensus handlers, API, tests) keeps seeing names exactly as before the
# normalization. This frozenset MUST stay in sync with the union of
# ``migration_data.compact_hash_tables.ASSET_NAME_COLUMNS`` values; it is
# duplicated here (rather than imported) because ``database`` is a low-level
# module and importing ``lib.ledger.*`` at load time would create a cycle. A
# unit test asserts the two stay identical.
ASSET_INDEX_COLUMN_NAMES = frozenset(
    {
        "asset",
        "give_asset",
        "get_asset",
        "forward_asset",
        "backward_asset",
        "dividend_asset",
        "asset_parent",
        "asset_a",
        "asset_b",
    }
)

# Columns that store the compact integer ``address_id`` foreign key (see the
# address-normalization rewrite in ``0010``). On read the rowtracer transparently
# decodes the id back to the address *string* so the rest of the codebase
# (consensus handlers, API, tests) keeps seeing addresses exactly as before the
# normalization. This frozenset MUST stay in sync with the union of
# ``migration_data.compact_hash_tables.ADDRESS_NAME_COLUMNS`` values; it is
# duplicated here (rather than imported) because ``database`` is a low-level
# module and importing ``lib.ledger.*`` at load time would create a cycle. A
# unit test asserts the two stay identical.
#
# CAUTION: this is matched by column NAME globally in the rowtracer -- any int
# value in a column with one of these names is decoded as an address. No table
# may have a same-named column holding a non-address integer. ``mempool``'s
# ``addresses`` (a comma-separated list) and ``mempool_transactions``'s
# ``source``/``destination`` (transient, kept TEXT) are not in this set.
ADDRESS_INDEX_COLUMN_NAMES = frozenset(
    {
        "address",
        "utxo_address",
        "source",
        "destination",
        "source_address",
        "destination_address",
        "issuer",
        "feed_address",
        "tx0_address",
        "tx1_address",
        "winner",
        "oracle_address",
        "origin",
        "last_status_tx_source",
    }
)

# Union of every column that holds the compact integer asset_index / address_id
# on the Ledger DB. Used to retype the State DB consolidated-table DDL below.
INDEX_NAME_COLUMNS = ASSET_INDEX_COLUMN_NAMES | ADDRESS_INDEX_COLUMN_NAMES


def text_affinitize_index_columns(create_sql):
    """Rewrite ``<col> INTEGER`` -> ``<col> TEXT`` for every asset/address index
    column in a copied ``CREATE TABLE`` statement.

    The Ledger DB stores these columns as the compact ``INTEGER`` index, but the
    State DB consolidated tables (api/migrations ``0006`` and ``0014``) copy that
    DDL verbatim while populating the columns with the *decoded* TEXT
    name/address. Left at INTEGER affinity the column mismatches
    ``assets_info.asset`` (TEXT) in the ``orders_info`` view join and the
    dispenser ``price`` subquery, which silently defeats the index on
    ``assets_info`` and turns those reads into a full scan per row (observed: a
    single ``/addresses/<a>/orders`` request took ~55s on mainnet). Restoring
    TEXT affinity lets the joins use the index again.

    The match is anchored on a non-word boundary so ``asset`` does not rewrite
    ``give_asset``/``asset_parent`` and ``address`` does not rewrite
    ``utxo_address``/``source_address``.
    """
    for col in INDEX_NAME_COLUMNS:
        create_sql = re.sub(
            rf"(?<!\w){re.escape(col)}\s+INTEGER\b",
            f"{col} TEXT",
            create_sql,
        )
    return create_sql


# Per-connection cache size cap for the high-cardinality address/tx_hash
# resolvers. Assets are a few thousand (unbounded dict is fine), but addresses
# and transactions number in the millions, so an unbounded dict would grow the
# parser's RSS without bound. An LRU cap keeps the working set hot while
# bounding memory.
ADDRESS_CACHE_MAXSIZE = 100_000

# Per-connection asset_index<->name caches. Asset rows are append-only (never
# renamed or deleted), and ``asset_index`` is monotonic, so:
#   * index->name hits and misses are both permanently valid (a stored index
#     always references an asset that already exists), so misses are cached.
#   * name->index misses may later become hits (the asset gets registered), so
#     only hits are cached there.
_CACHE_MISS = object()

# Serializes the *container-level* mutations of the per-connection cache maps
# below (creating/dropping a connection's entry, the weakref-cleanup path).
# Each connection is used by a single thread at a time, so the inner per-
# connection caches are touched lock-free by their one owning thread; only the
# shared outer ``WeakKeyDictionary`` containers need guarding. The lock is NEVER
# held across a DB query, so API threads never serialise on it during reads.
_CACHE_CONTAINER_LOCK = threading.RLock()


def _conn_cache(cache_dict, db, factory):
    """Return the per-connection cache for ``db`` from ``cache_dict``, creating
    it with ``factory()`` on first use. Guards only the shared-container access;
    the returned object is then used lock-free by the single owning thread."""
    with _CACHE_CONTAINER_LOCK:
        cache = cache_dict.get(db)
        if cache is None:
            cache = factory()
            cache_dict[db] = cache
        return cache


_ASSET_NAME_BY_INDEX = weakref.WeakKeyDictionary()
_ASSET_INDEX_BY_NAME = weakref.WeakKeyDictionary()
# Per-connection name of the ``assets`` table. On a Ledger DB connection it is
# ``assets``; on a read-only State DB connection (which ATTACHes the Ledger DB
# as ``ledger_db``) it is ``ledger_db.assets``. ``None`` => not resolvable.
_ASSETS_TABLE_NAME = weakref.WeakKeyDictionary()


def _resolve_assets_table(db):
    with _CACHE_CONTAINER_LOCK:
        cached = _ASSETS_TABLE_NAME.get(db, _CACHE_MISS)
    if cached is not _CACHE_MISS:
        return cached
    name = None
    for candidate in ("assets", "ledger_db.assets"):
        try:
            db.cursor().execute(f"SELECT 1 FROM {candidate} LIMIT 0")  # nosec B608  # noqa: S608
        except apsw.SQLError:
            continue
        name = candidate
        break
    with _CACHE_CONTAINER_LOCK:
        _ASSETS_TABLE_NAME[db] = name
    return name


def asset_name_from_index(db, index):
    """Resolve a stored ``asset_index`` to its asset name. Returns the raw
    index unchanged if it cannot be resolved (e.g. the ``assets`` table is not
    reachable from this connection)."""
    cache = _conn_cache(_ASSET_NAME_BY_INDEX, db, dict)
    name = cache.get(index, _CACHE_MISS)
    if name is _CACHE_MISS:
        table = _resolve_assets_table(db)
        if table is None:
            return index
        row = (
            db.cursor()
            .execute(
                f"SELECT asset_name FROM {table} WHERE asset_index = ?",  # nosec B608  # noqa: S608
                (index,),
            )
            .fetchone()
        )
        name = row["asset_name"] if row else None
        cache[index] = name
    return name if name is not None else index


def asset_index_from_name(db, asset_name):
    """Resolve an asset name to its compact ``asset_index``. Returns ``None``
    when the asset is not registered (e.g. an invalid record referencing a
    never-issued asset), which stores as NULL."""
    if asset_name is None:
        return None
    cache = _conn_cache(_ASSET_INDEX_BY_NAME, db, dict)
    index = cache.get(asset_name, _CACHE_MISS)
    if index is _CACHE_MISS:
        table = _resolve_assets_table(db)
        if table is None:
            return None
        row = (
            db.cursor()
            .execute(
                f"SELECT asset_index FROM {table} WHERE asset_name = ?",  # nosec B608  # noqa: S608
                (asset_name,),
            )
            .fetchone()
        )
        index = row["asset_index"] if row else None
        if index is not None:
            # Only cache hits: a miss can become a hit once the asset is issued.
            cache[asset_name] = index
    return index


def reset_asset_caches(db):
    """Drop the per-connection ``asset_index``<->name caches for ``db``.

    The caches assume asset rows are append-only and ``asset_index`` is
    immutable, which holds during a committed forward parse. It is VIOLATED
    whenever a transaction that created ``assets`` rows is ROLLED BACK on the
    same connection: the freed ``asset_index`` is reused by a different asset
    on the next parse, so a cached name->index (or index->name) mapping then
    resolves to the wrong asset. The mempool parser creates this exact
    situation -- it parses a fake block (creating/caching asset rows) and then
    rolls back the DB to discard the mempool state -- and so do reorg/reparse.
    Call this right after such a rollback so subsequent parsing re-resolves
    against the actual committed ``assets`` table."""
    with _CACHE_CONTAINER_LOCK:
        _ASSET_NAME_BY_INDEX.pop(db, None)
        _ASSET_INDEX_BY_NAME.pop(db, None)


# Hot-path local reference (avoids the per-cell attribute lookup in rowtracer).
_ADDRESS_INDEX_COLUMN_NAMES = ADDRESS_INDEX_COLUMN_NAMES

# Per-connection address_id<->string caches. Unlike assets these are BOUNDED
# (LRU) because addresses number in the millions. Each maps db -> OrderedDict.
#   * index->string: a stored id always references an existing address, so both
#     hits and misses (stored as None) are permanently valid during a committed
#     forward parse and may be cached; LRU-evicted past the cap.
#   * string->index: a miss can become a hit once the address is first seen
#     (``ensure_address``), so only hits are cached; LRU-evicted past the cap.
_ADDRESS_STRING_BY_INDEX = weakref.WeakKeyDictionary()
_ADDRESS_INDEX_BY_STRING = weakref.WeakKeyDictionary()
# Per-connection name of the ``address_list`` table (``address_list`` on a
# Ledger DB connection, ``ledger_db.address_list`` on a read-only State DB
# connection, or ``None`` if not reachable).
_ADDRESS_LIST_TABLE_NAME = weakref.WeakKeyDictionary()


def _lru_get(cache_dict, db, key):
    """Return (found, value) from the per-connection ``OrderedDict`` for ``db``,
    moving the key to the most-recently-used end on a hit."""
    with _CACHE_CONTAINER_LOCK:
        cache = cache_dict.get(db)
    if cache is None:
        return False, None
    value = cache.get(key, _CACHE_MISS)
    if value is _CACHE_MISS:
        return False, None
    cache.move_to_end(key)
    return True, value


def _lru_put(cache_dict, db, key, value, maxsize):
    """Insert ``key -> value`` into the per-connection ``OrderedDict`` for
    ``db``, evicting the least-recently-used entry past ``maxsize``."""
    cache = _conn_cache(cache_dict, db, OrderedDict)
    cache[key] = value
    cache.move_to_end(key)
    while len(cache) > maxsize:
        cache.popitem(last=False)


def _resolve_address_list_table(db):
    with _CACHE_CONTAINER_LOCK:
        cached = _ADDRESS_LIST_TABLE_NAME.get(db, _CACHE_MISS)
    if cached is not _CACHE_MISS:
        return cached
    name = None
    for candidate in ("address_list", "ledger_db.address_list"):
        try:
            db.cursor().execute(f"SELECT 1 FROM {candidate} LIMIT 0")  # nosec B608  # noqa: S608
        except apsw.SQLError:
            continue
        name = candidate
        break
    with _CACHE_CONTAINER_LOCK:
        _ADDRESS_LIST_TABLE_NAME[db] = name
    return name


def address_string_from_index(db, index):
    """Resolve a stored ``address_id`` to its address string. Returns the raw
    index unchanged if it cannot be resolved (e.g. ``address_list`` is not
    reachable from this connection)."""
    found, value = _lru_get(_ADDRESS_STRING_BY_INDEX, db, index)
    if found:
        return value if value is not None else index
    table = _resolve_address_list_table(db)
    if table is None:
        return index
    row = (
        db.cursor()
        .execute(
            f"SELECT address FROM {table} WHERE address_id = ?",  # nosec B608  # noqa: S608
            (index,),
        )
        .fetchone()
    )
    value = row["address"] if row else None
    _lru_put(_ADDRESS_STRING_BY_INDEX, db, index, value, ADDRESS_CACHE_MAXSIZE)
    return value if value is not None else index


def address_index_from_name(db, address):
    """Resolve an address string to its compact ``address_id``. Returns ``None``
    when the address is not registered in ``address_list`` (callers that write
    addresses pre-register them via ``events.ensure_address``)."""
    if address is None:
        return None
    found, value = _lru_get(_ADDRESS_INDEX_BY_STRING, db, address)
    if found:
        return value
    table = _resolve_address_list_table(db)
    if table is None:
        return None
    row = (
        db.cursor()
        .execute(
            f"SELECT address_id FROM {table} WHERE address = ?",  # nosec B608  # noqa: S608
            (address,),
        )
        .fetchone()
    )
    index = row["address_id"] if row else None
    if index is not None:
        # Only cache hits: a miss can become a hit once the address is seen.
        _lru_put(_ADDRESS_INDEX_BY_STRING, db, address, index, ADDRESS_CACHE_MAXSIZE)
    return index


def reset_address_caches(db):
    """Drop the per-connection ``address_id``<->string caches for ``db``.

    Like the asset caches, these assume ``address_id`` is immutable -- which is
    violated when a transaction that created ``address_list`` rows is ROLLED
    BACK on the same connection (mempool parse, reorg/reparse): the freed id is
    reused by a different address on the next parse. Call this right after such
    a rollback. See ``reset_asset_caches``."""
    with _CACHE_CONTAINER_LOCK:
        _ADDRESS_STRING_BY_INDEX.pop(db, None)
        _ADDRESS_INDEX_BY_STRING.pop(db, None)


def split_utxo(utxo):
    """Split a ``tx_hash:vout`` UTXO string into the stored
    ``(utxo_tx_hash, utxo_vout)`` pair: the 64-char hex tx_hash is converted to
    its compact ``BLOB(32)`` form and the vout to an int. Returns
    ``(None, None)`` for a ``None`` utxo (an address balance).

    The tx_hash is stored RAW (as a BLOB) rather than resolved to a ``tx_index``
    FK because an attach destination may be ANY valid bitcoin UTXO whose tx is
    not a Counterparty transaction (and so is absent from ``transactions``);
    a tx_index FK would lose such balances. The single choke point shared by the
    write path (``events``) and the read/WHERE path (``balances``/``caches``)."""
    if utxo is None:
        return None, None
    tx_hash_hex, _, vout = utxo.partition(":")
    return hashcodec.hash_to_db(tx_hash_hex), int(vout)


def utxo_from_split(utxo_tx_hash, utxo_vout):
    """Reconstruct the ``tx_hash:vout`` UTXO string from the stored
    ``(utxo_tx_hash, utxo_vout)`` pair. Returns ``None`` when there is no utxo
    (an address balance)."""
    if utxo_tx_hash is None:
        return None
    if utxo_tx_hash.__class__ is bytes:
        utxo_tx_hash = utxo_tx_hash.hex()
    return f"{utxo_tx_hash}:{utxo_vout}"


def _convert_value(name, field_type, value):
    # Fast path: most columns are non-NULL primitives (int, str, ...) and
    # not BOOL/BLOB hashes. Putting the cheapest checks first avoids the
    # ``isinstance(..., bytes)`` and ``str(field_type) == "BOOL"``
    # allocations that previously ran for every cell.
    if value is None:
        # Preserve the pre-optimization rowtracer contract: ``BOOL`` columns
        # always materialize as a real Python bool, even when the underlying
        # SQLite value is NULL (``bool(None) == False``). Several handlers
        # and serialized events rely on this.
        if field_type == "BOOL":
            return False
        return None
    # Columns storing 256-bit hashes are BLOB(32) at rest after the size
    # optimization migration, but the rest of the codebase (consensus,
    # API, tests) expects 64-char lowercase hex strings. Convert lazily
    # in the rowtracer so downstream code is unchanged. ``bytes.hex()`` is
    # ~1.6x faster than ``binascii.hexlify(value).decode("ascii")``.
    if value.__class__ is bytes and name in _HASH_COLUMN_NAMES:
        return value.hex()
    if field_type == "BOOL":
        return bool(value)
    return value


def rowtracer(cursor, sql):
    """Converts fetched SQL data into dict-style. Auto-converts BLOB hash
    columns back to lowercase hex strings, the compact integer ``asset_index``
    foreign keys back to asset names, the compact ``address_id`` foreign keys
    back to address strings, and the split ``(utxo_tx_hash, utxo_vout)`` pair
    back to the ``utxo`` string (``tx_hash:vout``). This preserves the legacy
    contract that ``row['tx_hash']`` is hex, ``row['asset']`` is a name,
    ``row['source']`` is an address and ``row['utxo']`` is ``tx_hash:vout``.
    """
    db = None
    out = {}
    for (name, field_type), value in zip(cursor.getdescription(), sql, strict=True):
        # Asset-index columns hold a small integer at rest; decode to the asset
        # name. A name already materialized as TEXT (e.g. ``assets.asset_name``,
        # ``assets_info.asset``, or a view that pre-resolves the name) is left
        # untouched, as is a NULL (invalid record with no asset).
        if value.__class__ is int and name in ASSET_INDEX_COLUMN_NAMES:
            if db is None:
                db = cursor.getconnection()
            out[name] = asset_name_from_index(db, value)
        # Address-id columns hold a small integer at rest; decode to the address
        # string. A string already materialized as TEXT (a view that
        # pre-resolves the address, or a State DB table that keeps TEXT
        # addresses) is left untouched, as is a NULL.
        elif value.__class__ is int and name in _ADDRESS_INDEX_COLUMN_NAMES:
            if db is None:
                db = cursor.getconnection()
            out[name] = address_string_from_index(db, value)
        else:
            out[name] = _convert_value(name, field_type, value)
    # Reconstruct the ``utxo`` string from the split ``(utxo_tx_hash,
    # utxo_vout)`` pair (balances/credits/debits on the Ledger DB). Only fires
    # when both columns are present; the synthesized ``utxo`` replaces the two
    # raw columns so the row shape is identical to the pre-split schema. A NULL
    # ``utxo_tx_hash`` (an address-balance row) yields ``utxo = None``.
    if "utxo_tx_hash" in out and "utxo_vout" in out:
        out["utxo"] = utxo_from_split(out.pop("utxo_tx_hash"), out.pop("utxo_vout"))
    return out


def get_file_openers(filename):
    pids = []
    for proc in psutil.process_iter():
        try:
            # this returns the list of opened files by the current process
            flist = proc.open_files()
            if flist:
                for nt in flist:
                    if filename in nt.path:
                        pids.append(proc.pid)
                        break
        # This catches a race condition where a process ends
        # before we can examine its files
        except (psutil.NoSuchProcess, psutil.AccessDenied):
            pass
    return pids


def check_wal_file(db_file):
    wal_file = f"{db_file}-wal"
    if os.path.exists(wal_file):
        pids = get_file_openers(wal_file)
        if len(pids) > 0:
            raise exceptions.DatabaseError(f"Database already opened by a process ({pids}).")
        raise exceptions.WALFileFoundError("Found WAL file. Database may be corrupted.")


def _should_attach_ledger_db(read_only, db_file):
    """Return True when a read-only State DB connection should ATTACH the
    Ledger DB so that hash-FK projections can JOIN against ``transactions``.
    """
    if not read_only:
        return False
    if not hasattr(config, "STATE_DATABASE") or db_file != config.STATE_DATABASE:
        return False
    if not hasattr(config, "DATABASE") or not config.DATABASE:
        return False
    return os.path.exists(config.DATABASE)


def get_db_connection(db_file, read_only=True, check_wal=False):
    """Connects to the SQLite database, returning a db `Connection` object"""

    if hasattr(config, "DATABASE") and db_file == config.DATABASE:
        db_file_name = "Ledger DB"
    elif hasattr(config, "STATE_DATABASE") and db_file == config.STATE_DATABASE:
        db_file_name = "State DB"
    else:
        db_file_name = db_file
    if hasattr(logger, "trace"):
        logger.trace(f"Creating connection to {db_file_name}...")

    if not read_only and check_wal:
        try:
            check_wal_file(db_file)
        except exceptions.WALFileFoundError:
            logger.warning(
                "Database WAL file detected. To ensure no data corruption has occurred, run `counterpary-server check-db`."
            )

    if read_only:
        db = apsw.Connection(db_file, flags=apsw.SQLITE_OPEN_READONLY)
    else:
        db = apsw.Connection(db_file)

    # Register UDFs before opening any cursor. SQLite 3.41+ ships a built-in
    # ``unhex``; overriding a built-in fails with SQLITE_BUSY when there are
    # active prepared statements on the connection, so we must register here
    # before any cursor/PRAGMA work creates such statements.
    hashcodec.register_db_functions(db)

    cursor = db.cursor()

    # Make case sensitive the `LIKE` operator.
    # For insensitive queries use 'UPPER(fieldname) LIKE value.upper()''
    cursor.execute("PRAGMA case_sensitive_like = ON")
    cursor.execute("PRAGMA foreign_keys = ON")
    cursor.execute("PRAGMA defer_foreign_keys = ON")
    if not read_only:
        cursor.execute("PRAGMA auto_vacuum = 1")
        cursor.execute("PRAGMA synchronous = normal")
        cursor.execute("PRAGMA journal_size_limit = 6144000")

    # State DB read-only connections (used by API request handlers) need to
    # see ``ledger_db.transactions`` so that hash-FK projections that
    # re-hydrate ``order_tx_hash`` / ``dispenser_tx_hash`` from their
    # ``*_tx_index`` foreign keys can JOIN against it. We do this only for
    # read-only connections to avoid taking a write lock on ledger_db
    # (which would conflict with the ledger writer / test fixtures).
    if _should_attach_ledger_db(read_only, db_file):
        try:
            attached_row = cursor.execute(
                "SELECT COUNT(*) FROM pragma_database_list WHERE name = ?",
                ("ledger_db",),
            ).fetchone()
            already_attached = (attached_row[0] if attached_row else 0) > 0
            if not already_attached:
                cursor.execute("ATTACH DATABASE ? AS ledger_db", (config.DATABASE,))
        except apsw.SQLError:
            # Ledger DB may not exist yet during early bootstrap; the caller
            # will retry once it's available.
            pass

    db.setrowtrace(rowtracer)

    cursor.close()
    return db


def get_connection(read_only=True, check_wal=True):
    return get_db_connection(config.DATABASE, read_only=read_only, check_wal=check_wal)


class _ThreadLocalConnections:
    """
    Per-thread connection cache. When CPython GCs this object (on thread exit),
    __del__ closes any cached connections and decrements the pool counter,
    preventing the connection_count leak caused by short-lived per-request
    threads (e.g. Werkzeug threaded=True spawns one thread per HTTP request).
    """

    __slots__ = ("connections", "_pool_ref")

    def __init__(self, pool):
        self.connections = []
        self._pool_ref = weakref.ref(pool)

    def __del__(self):
        pool = self._pool_ref()
        if pool is None or not self.connections:
            return
        n = len(self.connections)
        for db in self.connections:
            try:
                db.close()
            except apsw.Error as e:
                logger.debug("Error closing connection: %s", e)
        self.connections = []
        if pool.closed:
            return
        with pool.connection_available:
            pool.connection_count -= n
            if n > 0:
                pool.connection_available.notify_all()


class APSWConnectionPool:
    def __init__(self, db_file, name):
        self.db_file = db_file
        self.name = name
        self.closed = False
        # Thread-local storage for connections
        self.thread_local = threading.local()
        # Lock for connection count management
        self.lock = threading.RLock()
        # Condition variable for waiting when at max connections
        self.connection_available = threading.Condition(self.lock)
        # Use a counter instead of tracking every connection
        self.connection_count = 0
        # Max connections (0 = unlimited)
        self.max_connections = getattr(config, "DB_MAX_CONNECTIONS", 50)
        # Track peak connections for monitoring
        self.peak_connection_count = 0

    def _create_connection_with_limit(self):
        """Create a new connection, waiting if at max_connections limit."""
        wait_start = None
        with self.connection_available:
            # Wait if at max connections (0 = unlimited)
            if self.max_connections > 0:
                while self.connection_count >= self.max_connections and not self.closed:
                    if wait_start is None:
                        wait_start = time.time()
                        logger.warning(
                            "CONTENTION: %s at %d/%d, thread=%s waiting",
                            self.name,
                            self.connection_count,
                            self.max_connections,
                            threading.current_thread().name,
                        )
                    else:
                        logger.debug(
                            "Connection pool %s at max (%d), waiting...",
                            self.name,
                            self.max_connections,
                        )
                    # Wait up to 30 seconds for a connection to become available
                    if not self.connection_available.wait(timeout=30):
                        raise exceptions.DatabaseError(
                            f"Timeout waiting for database connection (pool {self.name} at max {self.max_connections})"
                        )
                    # Check if pool was closed while waiting
                    if self.closed:
                        raise exceptions.DatabaseError(
                            f"Connection pool {self.name} closed while waiting for connection"
                        )

            # Log wait time if we waited
            if wait_start is not None:
                wait_ms = (time.time() - wait_start) * 1000
                logger.warning(
                    "Connection acquired after %.0fms wait (%s, thread=%s)",
                    wait_ms,
                    self.name,
                    threading.current_thread().name,
                )

            self.connection_count += 1

            # Track peak connection count
            self.peak_connection_count = max(self.peak_connection_count, self.connection_count)

        return get_db_connection(self.db_file, read_only=True, check_wal=False)

    def _release_connection(self):
        """Decrement connection count and notify waiters."""
        with self.connection_available:
            self.connection_count -= 1
            self.connection_available.notify()

    @contextmanager
    def connection(self):
        # Fast path: initialize thread-local storage if needed
        if not hasattr(self.thread_local, "state"):
            self.thread_local.state = _ThreadLocalConnections(self)

        # Quick check without acquiring lock
        if self.closed:
            # Create a temporary connection if pool is closed
            db = get_db_connection(self.db_file, read_only=True, check_wal=False)
            try:
                yield db
            finally:
                db.close()
            return

        thread_connections = self.thread_local.state.connections

        # Get or create a connection
        if thread_connections:
            # Reuse existing connection - fast path without locking
            db = thread_connections.pop()
            try:
                # Minimal validation - use a cheap operation
                cursor = db.execute("SELECT 1")
                cursor.fetchone()
            except (apsw.ThreadingViolationError, apsw.BusyError):
                # Release the slot for the bad connection before acquiring a new one
                try:
                    db.close()
                except apsw.Error:  # noqa: S110
                    pass  # Connection may already be closed or in bad state
                self._release_connection()
                db = self._create_connection_with_limit()
        else:
            db = self._create_connection_with_limit()

        try:
            yield db
        finally:
            # Check closed status without lock first
            if self.closed:
                db.close()
                self._release_connection()
            else:
                # Fast path: return to local pool without locking
                if len(thread_connections) < config.DB_CONNECTION_POOL_SIZE:
                    thread_connections.append(db)
                else:
                    # Close connection and notify waiters
                    db.close()
                    self._release_connection()

    def close(self):
        # Set closed flag first - fast path for new connection requests
        self.closed = True

        with self.connection_available:
            logger.trace(
                "Closing all connections in pool (%s)... (%s)", self.name, self.connection_count
            )
            # Wake up any threads waiting for connections
            self.connection_available.notify_all()

        # Close connections in current thread
        if hasattr(self.thread_local, "state"):
            for db in self.thread_local.state.connections:
                try:
                    db.close()
                except apsw.ThreadingViolationError:
                    logger.trace("ThreadingViolationError occurred while closing connection.")
            # Clear thread local connections
            self.thread_local.state.connections = []

    def get_stats(self):
        """Get current connection pool statistics."""
        with self.lock:
            utilization = (
                (self.connection_count / self.max_connections * 100)
                if self.max_connections > 0
                else 0
            )
            return {
                "current": self.connection_count,
                "max": self.max_connections,
                "peak": self.peak_connection_count,
                "utilization": utilization,
            }


class LedgerDBConnectionPool(APSWConnectionPool, metaclass=helpers.SingletonMeta):
    def __init__(self):
        super().__init__(config.DATABASE, "Ledger DB")


class StateDBConnectionPool(APSWConnectionPool, metaclass=helpers.SingletonMeta):
    def __init__(self):
        super().__init__(config.STATE_DATABASE, "API DB")


def initialise_db():
    if config.FORCE:
        cprint("THE OPTION `--force` IS NOT FOR USE ON PRODUCTION SYSTEMS.", "yellow")

    # Database
    logger.debug("Connecting to database... (SQLite %s)", apsw.apswversion())
    db = get_connection(read_only=False)

    return db


class DatabaseIntegrityError(exceptions.DatabaseError):
    pass


def check_foreign_keys(db):
    cursor = db.cursor()

    logger.info("Checking database foreign keys...")

    cursor.execute("PRAGMA foreign_key_check")
    rows = cursor.fetchall()
    if rows:
        for row in rows:
            logger.debug("Foreign Key Error: %s", row)
        raise exceptions.DatabaseError("Foreign key check failed.")

    logger.info("Foreign key check completed.")


def intergrity_check(db):
    cursor = db.cursor()

    logger.info("Checking database integrity...")

    cursor.execute("PRAGMA integrity_check")
    rows = cursor.fetchall()
    if not (len(rows) == 1 and rows[0]["integrity_check"] == "ok"):
        for row in rows:
            logger.debug("Integrity Error: %s", row)
        raise exceptions.DatabaseError("Integrity check failed.")

    logger.info("Integrity check completed.")


def set_config_value(db, name, value):
    cursor = db.cursor()
    cursor.execute("INSERT OR REPLACE INTO config (name, value) VALUES (?, ?)", (name, value))


def get_config_value(db, name):
    cursor = db.cursor()
    cursor.execute("SELECT value FROM config WHERE name = ?", (name,))
    rows = cursor.fetchall()
    if rows:
        return rows[0]["value"]
    return None


def update_version(db):
    set_config_value(db, "VERSION_STRING", config.VERSION_STRING)
    logger.info("Database version number updated.")


def vacuum(db):
    logger.info("Starting database VACUUM... this may take a while!")
    cursor = db.cursor()
    cursor.execute("VACUUM")
    logger.info("Database VACUUM completed.")


def optimize(db):
    logger.info("Running PRAGMA optimize...")
    cursor = db.cursor()
    cursor.execute("PRAGMA optimize")
    logger.debug("PRAGMA optimize completed.")


def close(db):
    logger.info("Closing database connections...")
    LedgerDBConnectionPool().close()
    db.close()  # always close connection with write access last


_VACUUM_AFTER_MIGRATIONS = {"0010.compact_hash_storage"}


def apply_outstanding_migration(db_file, migration_dir):
    logger.info("Applying migrations to %s...", db_file)
    backend = get_backend(f"sqlite:///{db_file}")
    migrations = read_migrations(migration_dir)
    to_apply = backend.to_apply(migrations)
    needs_vacuum = any(any(name in m.id for name in _VACUUM_AFTER_MIGRATIONS) for m in to_apply)
    try:
        backend.apply_migrations(to_apply)
    except LockTimeout:
        logger.debug("API Watcher - Migration lock timeout. Breaking lock and retrying...")
        backend.break_lock()
        backend.apply_migrations(backend.to_apply(migrations))
    backend.connection.close()
    if needs_vacuum:
        logger.info("Running VACUUM after compact-hash migration to reclaim disk space...")
        conn = apsw.Connection(db_file)
        conn.cursor().execute("VACUUM")
        conn.close()
        logger.info("VACUUM completed.")


def rollback_all_migrations(db_file, migration_dir):
    logger.info("Rolling back all migrations from %s...", db_file)
    backend = get_backend(f"sqlite:///{db_file}")
    migrations = read_migrations(migration_dir)
    backend.rollback_migrations(backend.to_rollback(migrations))
