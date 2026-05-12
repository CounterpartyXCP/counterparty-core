#!/usr/bin/python3
"""Measure SQLite DB size breakdown to estimate hash-deduplication gains.

Usage:
    python tools/measure_db_size.py <path-to-counterparty.db> [--state <path-to-state.db>]

Produces:
    - Total DB size and free pages.
    - Per-table breakdown (table pages + index pages) via the dbstat virtual table.
    - Inventory of *hash columns (TEXT) and counts.
    - Projected savings for three independent storage optimizations:
        BLOB hashes:   TEXT(64 hex) -> BLOB(32)
        Hash FKs:      tx_hash TEXT -> tx_index INTEGER (where applicable)
        Composite IDs: composite match IDs (~129 chars) -> (tx0_index, tx1_index) INTEGERs

The script is strictly read-only; it opens the DB with mode=ro.
"""

import argparse
import os
import sqlite3
import sys
from collections import defaultdict

HASH_COLUMN_PATTERNS = (
    "tx_hash",
    "block_hash",
    "previous_block_hash",
    "ledger_hash",
    "txlist_hash",
    "messages_hash",
    "event_hash",
    "order_hash",
    "bet_hash",
    "rps_hash",
    "offer_hash",
    "dispenser_tx_hash",
    "last_status_tx_hash",
    "fairminter_tx_hash",
    "tx0_hash",
    "tx1_hash",
    "move_random_hash",
    "tx0_move_random_hash",
    "tx1_move_random_hash",
    "order_tx_hash",
)


COMPOSITE_ID_TABLES = {
    "order_matches": "id",
    "bet_matches": "id",
    "rps_matches": "id",
    "order_match_expirations": "order_match_id",
    "bet_match_expirations": "bet_match_id",
    "bet_match_resolutions": "bet_match_id",
    "rps_match_expirations": "rps_match_id",
    "rpsresolves": "rps_match_id",
    "btcpays": "order_match_id",
}


HASH_FK_CANDIDATES = {
    "messages": ("tx_hash",),
    "transaction_outputs": ("tx_hash",),
    "dispenses": ("dispenser_tx_hash",),
    "dispenser_refills": ("dispenser_tx_hash",),
    "fairmints": ("fairminter_tx_hash",),
    "pool_matches": ("order_tx_hash",),
    "cancels": ("offer_hash",),
}


def human(n):
    if n is None:
        return "-"
    units = ["B", "KB", "MB", "GB", "TB"]
    i = 0
    f = float(n)
    while f >= 1024 and i < len(units) - 1:
        f /= 1024
        i += 1
    return f"{f:.2f} {units[i]}"


def open_ro(path):
    uri = f"file:{path}?mode=ro"
    conn = sqlite3.connect(uri, uri=True)
    conn.row_factory = sqlite3.Row
    return conn


def pragma(conn, name):
    return conn.execute(f"PRAGMA {name}").fetchone()[0]


def list_tables(conn):
    rows = conn.execute(
        "SELECT name FROM sqlite_schema WHERE type='table' AND name NOT LIKE 'sqlite_%' ORDER BY name"
    ).fetchall()
    return [r["name"] for r in rows]


def list_indexes(conn):
    rows = conn.execute(
        "SELECT name, tbl_name, sql FROM sqlite_schema WHERE type='index' AND tbl_name NOT LIKE 'sqlite_%' ORDER BY tbl_name, name"
    ).fetchall()
    return rows


def columns_of(conn, table):
    rows = conn.execute(f"PRAGMA table_info({table})").fetchall()
    return [(r["name"], (r["type"] or "").upper()) for r in rows]


def row_count(conn, table):
    try:
        return conn.execute(f"SELECT COUNT(*) AS c FROM {table}").fetchone()["c"]  # noqa: S608
    except sqlite3.DatabaseError:
        return None


def dbstat_breakdown(conn):
    """Return dict {name -> bytes} using dbstat (per table/index).

    SQLite dbstat virtual table reports per-page stats; we sum pages*pagesize.
    """
    page_size = pragma(conn, "page_size")
    result = defaultdict(int)
    cursor = conn.execute("SELECT name, pageno FROM dbstat")
    for name, _pageno in cursor:
        result[name] += page_size
    return result, page_size


def is_hash_column(name):
    n = name.lower()
    return (
        any(n == p or n.endswith("_" + p) or n.endswith(p) for p in HASH_COLUMN_PATTERNS)
        or n.endswith("_hash")
        or n == "id"
        and False
    )


def hashish_columns(conn, table):
    out = []
    for name, dtype in columns_of(conn, table):
        n = name.lower()
        if n.endswith("_hash") or n == "tx_hash":
            out.append((name, dtype))
    return out


def collect_hash_inventory(conn):
    """Return list of (table, column, type, n_rows)."""
    inventory = []
    for table in list_tables(conn):
        cols = hashish_columns(conn, table)
        if not cols:
            continue
        nrows = row_count(conn, table)
        for col, dtype in cols:
            inventory.append((table, col, dtype, nrows))
    return inventory


def measure_avg_text_len(conn, table, column):
    try:
        r = conn.execute(
            f"SELECT AVG(LENGTH({column})) AS a, COUNT({column}) AS c FROM {table}"  # noqa: S608
        ).fetchone()
        return r["a"], r["c"]
    except sqlite3.DatabaseError:
        return None, None


def collect_composite_ids(conn):
    """Measure avg length of composite IDs in match tables."""
    out = []
    for table, col in COMPOSITE_ID_TABLES.items():
        try:
            r = conn.execute(
                f"SELECT AVG(LENGTH({col})) AS a, COUNT({col}) AS c FROM {table}"  # noqa: S608
            ).fetchone()
            if r and r["c"]:
                out.append((table, col, r["a"], r["c"]))
        except sqlite3.DatabaseError:
            continue
    return out


def find_hash_indexes(conn):
    indexes = list_indexes(conn)
    hash_indexes = []
    for idx in indexes:
        sql = (idx["sql"] or "").lower()
        if not sql:
            continue
        if any(
            p in sql
            for p in (
                "tx_hash",
                "block_hash",
                "event_hash",
                "_hash",
                "(id)",
                " id,",
                " id)",
            )
        ):
            hash_indexes.append((idx["name"], idx["tbl_name"]))
    return hash_indexes


def estimate_gains(conn, sizes):
    """Estimate savings per optimization using row counts and avg col sizes."""
    inv = collect_hash_inventory(conn)

    blob_hash_per_row_savings = 64 - 32 + 1
    hash_fk_per_row_savings = 64 - 4

    by_table = defaultdict(
        lambda: {"rows": 0, "hash_cols": 0, "blob_hash_data": 0, "hash_fk_data": 0}
    )

    for table, col, _dtype, nrows in inv:
        if nrows is None:
            continue
        by_table[table]["rows"] = nrows
        by_table[table]["hash_cols"] += 1
        by_table[table]["blob_hash_data"] += nrows * blob_hash_per_row_savings
        cands = HASH_FK_CANDIDATES.get(table, ())
        if col in cands:
            by_table[table]["hash_fk_data"] += nrows * hash_fk_per_row_savings

    return by_table


def fmt_pct(part, whole):
    if not whole:
        return "-"
    return f"{100.0 * part / whole:.1f}%"


def measure_db(path):
    print(f"\n{'=' * 80}\nMeasuring: {path}\n{'=' * 80}")
    print(f"On-disk size: {human(os.path.getsize(path))}")
    conn = open_ro(path)
    try:
        page_size = pragma(conn, "page_size")
        page_count = pragma(conn, "page_count")
        freelist = pragma(conn, "freelist_count")
        print(f"page_size: {page_size}, page_count: {page_count}, freelist: {freelist}")
        print(f"Total pages: {human(page_size * page_count)}, free: {human(page_size * freelist)}")

        sizes, _ = dbstat_breakdown(conn)
        total_used = sum(sizes.values())
        print(f"\nTotal pages used by named objects (tables+indexes): {human(total_used)}")

        tables = list_tables(conn)
        idx_rows = list_indexes(conn)
        idx_by_table = defaultdict(list)
        for idx in idx_rows:
            idx_by_table[idx["tbl_name"]].append(idx["name"])

        rows_by_table = []
        for t in tables:
            t_size = sizes.get(t, 0)
            i_size = sum(sizes.get(i, 0) for i in idx_by_table[t])
            n = row_count(conn, t)
            rows_by_table.append((t, n, t_size, i_size, t_size + i_size))
        rows_by_table.sort(key=lambda r: r[4], reverse=True)

        print("\nTop 30 tables by total size (table + indexes):")
        print(f"{'table':40} {'rows':>14} {'table':>12} {'indexes':>12} {'total':>12} {'pct':>6}")
        for name, nrows, tsz, isz, total in rows_by_table[:30]:
            print(
                f"{name[:40]:40} {str(nrows) if nrows is not None else '-':>14} "
                f"{human(tsz):>12} {human(isz):>12} {human(total):>12} {fmt_pct(total, total_used):>6}"
            )

        print(f"\n{'-' * 80}\nHash column inventory")
        print(f"{'-' * 80}")
        inv = collect_hash_inventory(conn)
        for table, col, dtype, nrows in inv:
            avg, cnt = measure_avg_text_len(conn, table, col)
            avg_s = "-" if avg is None else f"{avg:.1f}"
            print(
                f"  {table + '.' + col:50} type={dtype:6} rows={nrows or 0:>14} "
                f"avg_len={avg_s:>6} non_null={cnt or 0:>14}"
            )

        print(f"\n{'-' * 80}\nComposite match-id column inventory")
        print(f"{'-' * 80}")
        for table, col, avg, cnt in collect_composite_ids(conn):
            print(f"  {table + '.' + col:50} avg_len={avg:.1f}  non_null={cnt}")

        print(f"\n{'-' * 80}\nIndexes touching hash columns")
        print(f"{'-' * 80}")
        hash_indexes = find_hash_indexes(conn)
        total_hash_index_bytes = 0
        for name, table in hash_indexes:
            sz = sizes.get(name, 0)
            total_hash_index_bytes += sz
            print(f"  {table + '.' + name:60} size={human(sz):>12}")
        print(f"  TOTAL hash-related index size: {human(total_hash_index_bytes)}")

        print(f"\n{'-' * 80}\nEstimated savings per optimization (data only; index gains additive)")
        print(f"{'-' * 80}")
        by_table = estimate_gains(conn, sizes)
        total_blob_hash_data = 0
        total_hash_fk_data = 0
        for t, info in sorted(by_table.items(), key=lambda kv: kv[1]["rows"], reverse=True):
            if info["rows"] == 0:
                continue
            total_blob_hash_data += info["blob_hash_data"]
            total_hash_fk_data += info["hash_fk_data"]
            print(
                f"  {t:30} rows={info['rows']:>14} hash_cols={info['hash_cols']:>2} "
                f"blob_hash_save~={human(info['blob_hash_data']):>10} "
                f"hash_fk_save~={human(info['hash_fk_data']):>10}"
            )
        print(f"\n  TOTAL BLOB-hash data savings (TEXT64->BLOB32): {human(total_blob_hash_data)}")
        print(
            f"  TOTAL hash-FK data savings (txhash->tx_index on top tables): "
            f"{human(total_hash_fk_data)}"
        )

        # composite id potential savings
        composite_save = 0
        for _table, _col, avg, cnt in collect_composite_ids(conn):
            saving_per = max(0, (avg or 0) - 8 + 1)
            composite_save += int(saving_per * cnt)
        print(
            f"  TOTAL composite-id data savings (composite id -> (i0,i1)): {human(composite_save)}"
        )

        # rough index gains: hash-related indexes shrink ~50% with BLOB hashes
        # and up to ~95% on messages_tx_* when the column is replaced by a FK.
        approx_blob_hash_index_save = total_hash_index_bytes // 2
        print(
            f"\n  Approx BLOB-hash index savings (~50% on hash indexes): "
            f"{human(approx_blob_hash_index_save)}"
        )

        grand_blob = total_blob_hash_data + approx_blob_hash_index_save
        grand_blob_fk = grand_blob + total_hash_fk_data
        grand_all = grand_blob_fk + composite_save
        db_size = os.path.getsize(path)
        print(
            f"\n  >>> Grand total BLOB hashes:                  {human(grand_blob)}  "
            f"({fmt_pct(grand_blob, db_size)} of DB)"
        )
        print(
            f"  >>> Grand total BLOB hashes + hash FKs:        {human(grand_blob_fk)}  "
            f"({fmt_pct(grand_blob_fk, db_size)} of DB)"
        )
        print(
            f"  >>> Grand total BLOB + hash FKs + composite:   {human(grand_all)}  "
            f"({fmt_pct(grand_all, db_size)} of DB)"
        )

        return {
            "path": path,
            "size": db_size,
            "blob_hash_data": total_blob_hash_data,
            "hash_fk_data": total_hash_fk_data,
            "composite_id_data": composite_save,
            "blob_hash_index_approx": approx_blob_hash_index_save,
            "top_tables": rows_by_table[:10],
        }
    finally:
        conn.close()


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("ledger_db", help="Path to counterparty.db")
    parser.add_argument("--state", help="Optional path to state.db", default=None)
    args = parser.parse_args()

    if not os.path.exists(args.ledger_db):
        print(f"File not found: {args.ledger_db}", file=sys.stderr)
        sys.exit(1)

    measure_db(args.ledger_db)
    if args.state and os.path.exists(args.state):
        measure_db(args.state)


if __name__ == "__main__":
    main()
