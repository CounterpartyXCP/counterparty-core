"""
Cache manager for integration tests.

This module provides caching functionality to speed up integration tests
by storing the database and block hashes between test runs.
"""

import json
import os
import shutil
from datetime import datetime, timezone

import apsw
from counterpartycore.lib.utils import hashcodec

# Number of block hashes to store in cache
HASH_COUNT = 100

# Default cache directory
DEFAULT_CACHE_DIR = os.path.join(os.path.expanduser("~/.cache"), "counterparty-integration-cache")


def get_cache_dir():
    """Get the cache directory, respecting environment variable override."""
    return os.environ.get("COUNTERPARTY_INTEGRATION_CACHE_DIR", DEFAULT_CACHE_DIR)


def get_network_cache_dir(network):
    """Get the cache directory for a specific network."""
    return os.path.join(get_cache_dir(), network)


def get_db_filename(network):
    """Get the database filename for a network."""
    if network == "mainnet":
        return "counterparty.db"
    return f"counterparty.{network}.db"


def get_cached_db_path(network):
    """Get the path to the cached database file."""
    return os.path.join(get_network_cache_dir(network), get_db_filename(network))


def get_hashes_path(network):
    """Get the path to the hashes JSON file."""
    return os.path.join(get_network_cache_dir(network), "hashes.json")


def cache_exists(network):
    """Check if a valid cache exists for the given network.

    Validates both that the files are present and that the hashes JSON is
    syntactically valid and has the expected structure. A corrupted hashes
    file (e.g. partial write from a previous failed run) is treated as a
    missing cache so the test falls back to a clean bootstrap and rewrites
    the cache rather than aborting with ``JSONDecodeError``.
    """
    db_path = get_cached_db_path(network)
    hashes_path = get_hashes_path(network)
    if not (os.path.exists(db_path) and os.path.exists(hashes_path)):
        return False

    try:
        with open(hashes_path, "r") as f:
            data = json.load(f)
    except (json.JSONDecodeError, OSError) as e:
        print(f"Cache hashes file is unreadable ({e}); treating cache as missing.")
        _discard_corrupted_cache(network)
        return False

    if not isinstance(data, dict) or not isinstance(data.get("hashes"), list) or not data["hashes"]:
        print("Cache hashes file is malformed; treating cache as missing.")
        _discard_corrupted_cache(network)
        return False

    return True


def _discard_corrupted_cache(network):
    """Remove a corrupted cache directory so the next run rebuilds it.

    Used when ``cache_exists`` detects an unreadable or malformed hashes
    file. We can't trust the cached DB either in that case, since the two
    are produced together and may be out of sync.
    """
    network_cache_dir = get_network_cache_dir(network)
    if os.path.exists(network_cache_dir):
        try:
            shutil.rmtree(network_cache_dir)
            print(f"Removed corrupted cache directory: {network_cache_dir}")
        except OSError as e:
            print(f"Failed to remove corrupted cache directory {network_cache_dir}: {e}")


def get_block_hashes_from_db(db_path, count=HASH_COUNT):
    """
    Extract the last N block hashes from the database.

    Returns a list of dicts with block_index, ledger_hash, and txlist_hash.
    Hashes are returned as 64-char lowercase hex strings, regardless of
    whether the underlying schema stores them as BLOB (post-migration 0010)
    or TEXT (pre-migration).
    """
    db = apsw.Connection(db_path)
    try:
        cursor = db.cursor()
        rows = cursor.execute(
            """
            SELECT block_index, ledger_hash, txlist_hash 
            FROM blocks 
            WHERE ledger_hash IS NOT NULL
            ORDER BY block_index DESC 
            LIMIT ?
            """,
            (count,),
        ).fetchall()

        # Return in ascending order (oldest first)
        return [
            {
                "block_index": row[0],
                "ledger_hash": hashcodec.hash_from_db(row[1]),
                "txlist_hash": hashcodec.hash_from_db(row[2]),
            }
            for row in reversed(rows)
        ]
    finally:
        db.close()


def get_last_block_index(db_path):
    """Get the last block index from the database."""
    db = apsw.Connection(db_path)
    try:
        cursor = db.cursor()
        result = cursor.execute(
            "SELECT block_index FROM blocks ORDER BY block_index DESC LIMIT 1"
        ).fetchone()
        return result[0] if result else None
    finally:
        db.close()


def save_hashes(network, db_path):
    """
    Save the last N block hashes to a JSON file.

    Args:
        network: The network name (signet, testnet4, mainnet)
        db_path: Path to the database file
    """
    network_cache_dir = get_network_cache_dir(network)
    os.makedirs(network_cache_dir, exist_ok=True)

    hashes = get_block_hashes_from_db(db_path, HASH_COUNT)
    last_block_index = hashes[-1]["block_index"] if hashes else None

    data = {
        "created_at": datetime.now(timezone.utc).isoformat(),
        "network": network,
        "last_block_index": last_block_index,
        "hash_count": len(hashes),
        "hashes": hashes,
    }

    hashes_path = get_hashes_path(network)
    # Write atomically: dump to a temp file in the same directory, then rename.
    # This prevents leaving a partially-written / corrupted JSON file on disk
    # if json.dump raises mid-write (e.g. a serialization error). Otherwise a
    # subsequent run would find a syntactically broken cache file and abort
    # with a JSONDecodeError instead of falling back to a clean rebuild.
    tmp_path = hashes_path + ".tmp"
    try:
        with open(tmp_path, "w") as f:
            json.dump(data, f, indent=2)
        os.replace(tmp_path, hashes_path)
    except Exception:
        if os.path.exists(tmp_path):
            os.remove(tmp_path)
        raise

    print(f"Saved {len(hashes)} block hashes to {hashes_path}")
    return data


def load_hashes(network):
    """
    Load block hashes from the cache.

    Returns the hashes data dict or None if cache doesn't exist.
    """
    hashes_path = get_hashes_path(network)
    if not os.path.exists(hashes_path):
        return None

    with open(hashes_path, "r") as f:
        data = json.load(f)

    print(
        f"Loaded {len(data['hashes'])} block hashes from cache (last block: {data['last_block_index']})"
    )
    return data


def save_db_to_cache(network, source_db_path):
    """
    Copy the database to the cache directory.

    Before copying, checkpoints the WAL to ensure a clean database state,
    and verifies database integrity.

    Args:
        network: The network name
        source_db_path: Path to the source database file

    Raises:
        RuntimeError: If database integrity check fails
    """
    network_cache_dir = get_network_cache_dir(network)
    os.makedirs(network_cache_dir, exist_ok=True)

    cached_db_path = get_cached_db_path(network)

    # Checkpoint WAL to ensure clean database state before copying
    db = apsw.Connection(source_db_path)
    try:
        # TRUNCATE mode checkpoints and then truncates the WAL file to zero bytes
        db.execute("PRAGMA wal_checkpoint(TRUNCATE)")

        # Verify database integrity before saving to cache
        result = db.execute("PRAGMA integrity_check").fetchone()
        if result[0] != "ok":
            raise RuntimeError(f"Database integrity check failed: {result[0]}")

        print(f"Database integrity verified and WAL checkpointed: {source_db_path}")
    finally:
        db.close()

    # Copy only the main database file (WAL should be empty after checkpoint)
    shutil.copy2(source_db_path, cached_db_path)

    # Remove any stale WAL/SHM files in cache directory
    for suffix in ["-wal", "-shm"]:
        cached_extra = cached_db_path + suffix
        if os.path.exists(cached_extra):
            os.remove(cached_extra)

    print(f"Saved database to cache: {cached_db_path}")


def get_state_db_filename(network):
    """Get the state database filename for a network."""
    if network == "mainnet":
        return "state.db"
    return f"state.{network}.db"


def restore_db_from_cache(network, target_dir):
    """
    Restore the database from cache to the target directory.

    Verifies database integrity after restoration to catch corrupted caches early.

    Args:
        network: The network name
        target_dir: Directory where the database should be restored

    Returns:
        Path to the restored database file

    Raises:
        FileNotFoundError: If no cached database exists
        RuntimeError: If cached database is corrupted
    """
    cached_db_path = get_cached_db_path(network)
    if not os.path.exists(cached_db_path):
        raise FileNotFoundError(f"No cached database found for {network}")

    # Verify cached database integrity before restoring
    db = apsw.Connection(cached_db_path)
    try:
        result = db.execute("PRAGMA integrity_check").fetchone()
        if result[0] != "ok":
            raise RuntimeError(
                f"Cached database is corrupted: {result[0]}. "
                f"Clear the cache with cache_manager.clear_cache('{network}') and re-run."
            )
        print(f"Cached database integrity verified: {cached_db_path}")
    finally:
        db.close()

    os.makedirs(target_dir, exist_ok=True)

    # Delete the state database files (they may be corrupted from previous SIGKILL)
    state_db_filename = get_state_db_filename(network)
    state_db_path = os.path.join(target_dir, state_db_filename)
    for suffix in ["", "-wal", "-shm", "-journal"]:
        state_file = state_db_path + suffix
        if os.path.exists(state_file):
            os.remove(state_file)
            print(f"Removed stale state database file: {state_file}")

    # Delete the fetcher database (may also be corrupted)
    fetcher_db_name = f"fetcherdb.{network}" if network != "mainnet" else "fetcherdb"
    fetcher_db_path = os.path.join(target_dir, fetcher_db_name)
    if os.path.exists(fetcher_db_path):
        shutil.rmtree(fetcher_db_path)
        print(f"Removed stale fetcher database: {fetcher_db_path}")

    db_filename = get_db_filename(network)
    target_db_path = os.path.join(target_dir, db_filename)

    # Copy only the main database file (no WAL/SHM since we checkpoint before saving)
    shutil.copy2(cached_db_path, target_db_path)

    # Remove any stale WAL/SHM files in target directory
    for suffix in ["-wal", "-shm"]:
        target_extra = target_db_path + suffix
        if os.path.exists(target_extra):
            os.remove(target_extra)

    print(f"Restored database from cache: {target_db_path}")
    return target_db_path


def save_cache(network, db_path):
    """
    Save both the database and hashes to the cache.

    Args:
        network: The network name
        db_path: Path to the database file
    """
    save_db_to_cache(network, db_path)
    save_hashes(network, db_path)
    print(f"Cache saved for {network}")


def clear_cache(network=None):
    """
    Clear the cache for a specific network or all networks.

    Args:
        network: The network name, or None to clear all caches
    """
    cache_dir = get_cache_dir()

    if network:
        # Clear specific network cache
        network_cache_dir = get_network_cache_dir(network)
        if os.path.exists(network_cache_dir):
            shutil.rmtree(network_cache_dir)
            print(f"Cleared cache for {network}")
        else:
            print(f"No cache found for {network}")
    else:
        # Clear all caches
        if os.path.exists(cache_dir):
            shutil.rmtree(cache_dir)
            print("Cleared all integration test caches")
        else:
            print("No integration test cache found")


def verify_hashes(db_path, expected_hashes):
    """
    Verify that the database contains the expected block hashes.

    Args:
        db_path: Path to the database file
        expected_hashes: List of expected hash dicts from cache

    Raises:
        AssertionError: If any hash doesn't match
    """
    db = apsw.Connection(db_path)
    try:
        cursor = db.cursor()

        for expected in expected_hashes:
            block_index = expected["block_index"]
            row = cursor.execute(
                """
                SELECT ledger_hash, txlist_hash 
                FROM blocks 
                WHERE block_index = ?
                """,
                (block_index,),
            ).fetchone()

            if row is None:
                raise AssertionError(f"Block {block_index} not found in database")

            # Normalize to hex string so the comparison works regardless of
            # whether the schema stores hashes as BLOB or TEXT.
            actual_ledger_hash = hashcodec.hash_from_db(row[0])
            actual_txlist_hash = hashcodec.hash_from_db(row[1])

            if actual_ledger_hash != expected["ledger_hash"]:
                raise AssertionError(
                    f"Ledger hash mismatch at block {block_index}: "
                    f"expected {expected['ledger_hash']}, got {actual_ledger_hash}"
                )

            if actual_txlist_hash != expected["txlist_hash"]:
                raise AssertionError(
                    f"Txlist hash mismatch at block {block_index}: "
                    f"expected {expected['txlist_hash']}, got {actual_txlist_hash}"
                )

        print(f"Verified {len(expected_hashes)} block hashes successfully")
    finally:
        db.close()


def get_rollback_block_index(expected_hashes):
    """
    Get the block index to rollback to (first block in the cached hashes).

    Args:
        expected_hashes: List of expected hash dicts from cache

    Returns:
        The block index to rollback to
    """
    if not expected_hashes:
        raise ValueError("No expected hashes provided")
    return expected_hashes[0]["block_index"]
