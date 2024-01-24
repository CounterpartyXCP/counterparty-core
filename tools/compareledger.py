#!/usr/bin/python3

import sys
import difflib

import apsw


def compare_strings(string1, string2):
    """Compare strings diff-style."""
    diff = list(difflib.unified_diff(string1.splitlines(1), string2.splitlines(1), n=0))
    if len(diff):
        print("\nDifferences:")
        print("\n".join(diff))
    return len(diff)


def get_ledger(database_file):
    db = apsw.Connection(database_file, flags=apsw.SQLITE_OPEN_READONLY)
    cursor = db.cursor()

    query = """SELECT 'credit' as table_name, * FROM credits ORDER BY block_index
            UNION ALL
            SELECT 'debits' as table_name, * FROM debits ORDER BY block_index"""

    cursor.execute(query)

    rows = []
    for row in cursor:
        rows.append([
            row['table_name'],
            row['block_index'],
            row['address'],
            row['asset'],
            row['quantity'],
            row['calling_function'],
            row['event'],
        ])
    rows_str = "\n".join(rows)

    return "{database_file}\n{rows_str}"

database_file_1 = sys.argv[1]
database_file_2 = sys.argv[2]
ledger_1 = get_ledger(database_file_1)
ledger_2 = get_ledger(database_file_2)

compare_strings(ledger_1, ledger_2)
