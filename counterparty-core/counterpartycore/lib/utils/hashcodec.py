"""Hash codec for converting between the at-rest BLOB(32) representation and
the in-memory/JSON hex string representation used throughout the codebase and
exposed to consensus, API consumers, and existing tests.

Database schema after the compact-hash storage migration stores all
``*_hash``/``tx_hash`` columns (except a few documented exceptions) as
``BLOB`` (32 bytes for 256-bit hashes). The consensus paths in
``parser/blocks.py``/``ledger/events.py`` and the API surface still operate on
the canonical 64-char lowercase hex string, so we expose hex via a row tracer
and accept hex on the way in.

A handful of tables also drop the redundant ``*_tx_hash`` column entirely
in favour of a ``*_tx_index`` integer FK; helpers here are used by the
message handlers and ``insert_record`` to resolve ``hex tx_hash -> tx_index``
transparently.
"""

import binascii

# Names of columns that store a 256-bit hash as BLOB(32) in the optimized
# schema. The row tracer inspects column names against this set to decide
# whether a ``bytes`` value should be returned to Python as a hex string.
# Includes both the canonical name (``tx_hash``) and table-qualified variants
# used in match/expiration tables.
HASH_COLUMN_NAMES = frozenset(
    {
        # blocks
        "block_hash",
        "previous_block_hash",
        "ledger_hash",
        "txlist_hash",
        "messages_hash",
        # transactions / generic
        "tx_hash",
        "event_hash",
        # match-related
        "tx0_hash",
        "tx1_hash",
        # rps random commit
        "move_random_hash",
        "tx0_move_random_hash",
        "tx1_move_random_hash",
        # last-status (dispenser)
        "last_status_tx_hash",
        # expirations
        "order_hash",
        "bet_hash",
        "rps_hash",
        # FK-style hash aliases: in the migrated schema the underlying
        # columns are ``*_tx_index`` integers, but the legacy hash fields
        # are still re-exposed via JOINs/VIEWs and accepted on the input
        # side. Keeping them here means the row tracer / WHERE-clause hex
        # conversion treats them consistently.
        "dispenser_tx_hash",
        "fairminter_tx_hash",
        "order_tx_hash",
        "offer_hash",
    }
)


def hash_to_db(value, strict=False):
    """Convert a hex string or already-bytes value to the BLOB form used by
    the optimized schema. ``None`` passes through.

    Accepts:
      - ``None`` -> ``None``
      - ``bytes`` -> bytes as-is
      - ``str`` (hex) -> ``bytes.fromhex(value)``

    A non-hex string is encoded as its UTF-8 bytes when ``strict=False``.
    This permissive fallback exists for synthetic test fixtures that pass
    non-hash labels through APIs that expect a ``tx_hash`` (e.g. ``"tx1"``).
    Production code always passes 64-char lowercase hex; consensus paths
    should call with ``strict=True`` to assert that contract.

    When ``strict=True``:
      - non-hex strings raise ``ValueError``
      - non-64-char hex strings raise ``ValueError``
      - ``bytes`` not of length 32 raise ``ValueError``
    """
    if value is None:
        return None
    if isinstance(value, bytes):
        if strict and len(value) != 32:
            raise ValueError(f"hash_to_db(strict): expected 32 bytes, got {len(value)}")
        return value
    if isinstance(value, str):
        if value == "":
            if strict:
                raise ValueError("hash_to_db(strict): empty string is not a valid hash")
            return None
        if strict:
            if len(value) != 64:
                raise ValueError(f"hash_to_db(strict): expected 64-char hex, got len={len(value)}")
            # bytes.fromhex will raise ValueError on non-hex content.
            return bytes.fromhex(value)
        try:
            return bytes.fromhex(value)
        except ValueError:
            # Permissive UTF-8 fallback for test fixtures only.
            return value.encode("utf-8")
    raise TypeError(f"hash_to_db: unsupported type {type(value).__name__}")


def hash_from_db(value):
    """Convert a BLOB value back to its 64-char lowercase hex string. Used at
    the API / consensus / JSON boundary."""
    if value is None:
        return None
    if isinstance(value, str):
        return value
    if isinstance(value, bytes):
        return binascii.hexlify(value).decode("ascii")
    raise TypeError(f"hash_from_db: unsupported type {type(value).__name__}")


def normalize_record_hashes(record, hash_columns):
    """In-place normalize the hash-typed values of ``record`` (mapping) to
    BLOB form for ``hash_columns`` present in the dict. Returns ``record``
    for chaining."""
    for col in hash_columns:
        if col in record:
            record[col] = hash_to_db(record[col])
    return record


def register_db_functions(db):
    """Register scalar UDFs on the given connection so SQL can convert
    between BLOB and hex inline (used by VIEW definitions and migrations).

    Works on both ``apsw.Connection`` (``createscalarfunction``) and the
    stdlib ``sqlite3.Connection`` (``create_function``). The stdlib path is
    needed by yoyo-driven migrations of the API state DB, which open a
    plain ``sqlite3`` connection that hasn't been through
    ``database.get_db_connection``. Without it, any DDL that triggers view
    re-validation (e.g. ``ALTER TABLE ... RENAME``) on a table referenced
    by a view that uses ``hex_lower`` will fail with
    ``no such function: hex_lower``.

    - ``hex_lower(blob)`` returns the lowercase hex string of a BLOB, or
      NULL for NULL. Mirrors Python ``binascii.hexlify(value).decode()``.
    - ``unhex(text)`` returns ``BLOB`` for a hex string, or NULL.
    """

    def _hex_lower(blob):
        if blob is None:
            return None
        if isinstance(blob, str):
            return blob.lower()
        return binascii.hexlify(blob).decode("ascii")

    def _unhex(text):
        if text is None:
            return None
        if isinstance(text, bytes):
            return text
        return bytes.fromhex(text)

    if hasattr(db, "createscalarfunction"):
        db.createscalarfunction("hex_lower", _hex_lower, 1)
        db.createscalarfunction("unhex", _unhex, 1)
    else:
        db.create_function("hex_lower", 1, _hex_lower)
        db.create_function("unhex", 1, _unhex)
