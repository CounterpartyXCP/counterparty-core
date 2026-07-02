#!/usr/bin/python3

import difflib
import sys

import apsw


def normalize_hash(value):
    """Normalize a hash value to a canonical hex string.

    The `hashes` branch stores some hashes as raw BLOBs while the legacy
    database stores them as hex TEXT. Convert both to lowercase hex so that
    identical hashes compare equal regardless of storage representation.
    """
    if value is None:
        return None
    if isinstance(value, bytes):
        return value.hex()
    return value.lower()


def normalize_value(value):
    """Render a column value for comparison, BLOBs as hex.

    The `hashes` branch stores tx hashes, block hashes, etc. as raw BLOBs while
    the legacy database stores them as hex TEXT. Hex-encoding BLOBs makes both
    representations comparable.
    """
    if isinstance(value, bytes):
        return value.hex()
    return str(value)


def is_normalized_schema(db):
    """The `hashes` branch adds an `address_list` lookup table to resolve FKs."""
    return bool(
        db.cursor()
        .execute("SELECT 1 FROM sqlite_master WHERE type='table' AND name='address_list'")
        .fetchone()
    )


def ledger_selects(db):
    """Return (credit_select, debit_select) without a WHERE clause, yielding
    comparable (table_name, block_index, address, asset, quantity, fn, event)
    rows regardless of whether `db` uses the normalized (hashes-branch) schema.

    On the normalized schema, address/asset are integer FKs, so resolve them
    back to TEXT via address_list/assets to match the legacy schema.
    """
    if is_normalized_schema(db):
        # `assets` also has a block_index column, so always qualify with alias `t`.
        credit = """SELECT 'credit', t.block_index, al.address, a.asset_name, t.quantity,
                           t.calling_function, t.event
                    FROM credits t
                    LEFT JOIN address_list al ON al.address_id = t.address
                    LEFT JOIN assets a ON a.asset_index = t.asset"""
        debit = """SELECT 'debit', t.block_index, al.address, a.asset_name, t.quantity,
                          t.action, t.event
                   FROM debits t
                   LEFT JOIN address_list al ON al.address_id = t.address
                   LEFT JOIN assets a ON a.asset_index = t.asset"""
    else:
        credit = """SELECT 'credit', t.block_index, t.address, t.asset, t.quantity,
                           t.calling_function, t.event
                    FROM credits t"""
        debit = """SELECT 'debit', t.block_index, t.address, t.asset, t.quantity,
                          t.action, t.event
                   FROM debits t"""
    return credit, debit


TX_COLUMNS = [
    "tx_index",
    "tx_hash",
    "block_index",
    "block_hash",
    "block_time",
    "source",
    "destination",
    "btc_amount",
    "fee",
    "data",
    "supported",
    "utxos_info",
    "transaction_type",
]


def tx_relation_columns(db):
    """Pick a transactions relation and its columns.

    Prefer the `transactions_with_status` view, which on the normalized schema
    resolves source/destination/block_hash back to TEXT; fall back to the raw
    `transactions` table.
    """
    cursor = db.cursor()
    relation = (
        "transactions_with_status"
        if cursor.execute(
            "SELECT 1 FROM sqlite_master WHERE type='view' AND name='transactions_with_status'"
        ).fetchone()
        else "transactions"
    )
    columns = {row[1] for row in cursor.execute(f"PRAGMA table_info({relation})")}
    return relation, columns


def compare_strings(string1, string2):
    """Compare strings diff-style."""
    diff = list(difflib.unified_diff(string1.splitlines(1), string2.splitlines(1), n=0))
    if diff:
        print(f"\n{len(diff)} Differences:")
        print("\n".join(diff))
        print(f"\n{len(diff)} differences")
    return len(diff)


def block_ledger_str(db, where, params):
    credit, debit = ledger_selects(db)
    cursor = db.cursor()
    rows = cursor.execute(f"{credit} WHERE {where}", params).fetchall()  # noqa: S608 # nosec B608
    rows += cursor.execute(f"{debit} WHERE {where}", params).fetchall()  # noqa: S608 # nosec B608
    # Sort so that order differences within a block don't show as spurious diffs.
    return "\n".join(sorted(", ".join(normalize_value(x) for x in row) for row in rows))


def get_ledger(database_file):
    db = apsw.Connection(database_file, flags=apsw.SQLITE_OPEN_READONLY)
    rows_str = block_ledger_str(db, "t.block_index < ?", (LAST_BLOCK,))
    return f"{database_file}\n{rows_str}"


def compare_block_ledger(database_file_1, database_file_2, block_index):
    db1 = apsw.Connection(database_file_1, flags=apsw.SQLITE_OPEN_READONLY)
    db2 = apsw.Connection(database_file_2, flags=apsw.SQLITE_OPEN_READONLY)
    block1_str = block_ledger_str(db1, "t.block_index = ?", (block_index,))
    block2_str = block_ledger_str(db2, "t.block_index = ?", (block_index,))
    print(f"Block {block_index}")
    print(f"----------------{database_file_1}---------------------")
    print(block1_str)
    print(f"----------------{database_file_2}---------------------")
    print(block2_str)
    print("-------------------------------------")
    compare_strings(block1_str, block2_str)


def txlist_str(db, relation, columns, block_index):
    cursor = db.cursor()
    fields = ", ".join(columns)
    rows = cursor.execute(
        f"SELECT {fields} FROM {relation} WHERE block_index = ? ORDER BY tx_index",  # noqa: S608 # nosec B608
        (block_index,),
    ).fetchall()
    return "\n".join(", ".join(normalize_value(x) for x in row) for row in rows)


def compare_txlist(database_file_1, database_file_2, block_index):
    db1 = apsw.Connection(database_file_1, flags=apsw.SQLITE_OPEN_READONLY)
    db2 = apsw.Connection(database_file_2, flags=apsw.SQLITE_OPEN_READONLY)
    relation1, cols1 = tx_relation_columns(db1)
    relation2, cols2 = tx_relation_columns(db2)
    # Compare only the columns both schemas expose (e.g. legacy `block_hash`).
    columns = [c for c in TX_COLUMNS if c in cols1 and c in cols2]
    block1_str = txlist_str(db1, relation1, columns, block_index)
    block2_str = txlist_str(db2, relation2, columns, block_index)
    print(f"Block {block_index}")
    print(f"----------------{database_file_1}---------------------")
    print(block1_str)
    print(f"----------------{database_file_2}---------------------")
    print(block2_str)
    print("-------------------------------------")
    compare_strings(block1_str, block2_str)


def check_hashes(database_file_1, database_file_2, hash_name="ledger_hash"):
    db1 = apsw.Connection(database_file_1, flags=apsw.SQLITE_OPEN_READONLY)
    cursor1 = db1.cursor()

    db2 = apsw.Connection(database_file_2, flags=apsw.SQLITE_OPEN_READONLY)
    cursor2 = db2.cursor()

    query = f"""SELECT block_index, {hash_name} FROM blocks WHERE block_index < {LAST_BLOCK} ORDER BY block_index """  # noqa: S608 # nosec B608

    cursor1.execute(query)
    for block1 in cursor1:
        block2 = cursor2.execute(
            f"SELECT block_index, {hash_name} FROM blocks WHERE block_index = ?",  # noqa: S608 # nosec B608
            (block1[0],),  # noqa: S608 # nosec B608
        ).fetchone()
        if block2 is None:
            print(
                f"Block {block1[0]} is present in {database_file_1} "
                f"but missing in {database_file_2}; stopping comparison."
            )
            break
        if normalize_hash(block1[1]) != normalize_hash(block2[1]):
            print(block1[0], block1[1], block2[1])
            if hash_name == "ledger_hash":
                compare_block_ledger(database_file_1, database_file_2, block1[0])
            else:
                compare_txlist(database_file_1, database_file_2, block1[0])
            raise Exception("Hashes do not match")


def get_checkpoints(database_file):
    checkpoints = [2580000]
    db = apsw.Connection(database_file_1, flags=apsw.SQLITE_OPEN_READONLY)
    cursor = db.cursor()
    for checkpoint in checkpoints:
        block = cursor.execute(
            "SELECT block_index, ledger_hash, txlist_hash FROM blocks WHERE block_index = ?",
            (checkpoint,),
        ).fetchone()
        print(block[0], block[1], block[2])


def compare_ledger(database_file_1, database_file_2):
    ledger_1 = get_ledger(database_file_1)
    ledger_2 = get_ledger(database_file_2)
    compare_strings(ledger_1, ledger_2)


def get_last_block(database_file_1, database_file_2):
    db1 = apsw.Connection(database_file_1, flags=apsw.SQLITE_OPEN_READONLY)
    cursor1 = db1.cursor()

    db2 = apsw.Connection(database_file_2, flags=apsw.SQLITE_OPEN_READONLY)
    cursor2 = db2.cursor()

    print(
        f"Last block {database_file_1}:",
        cursor1.execute("SELECT MAX(block_index) FROM blocks").fetchone(),
    )
    print(
        f"Last block {database_file_2}:",
        cursor2.execute("SELECT MAX(block_index) FROM blocks").fetchone(),
    )


database_file_1 = sys.argv[1]
database_file_2 = sys.argv[2]

LAST_BLOCK = 277880
# compare_ledger(database_file_1, database_file_2)
check_hashes(database_file_1, database_file_2, "ledger_hash")
# get_checkpoints(database_file_1)
# get_last_block(database_file_1, database_file_2)
