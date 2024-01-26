#!/usr/bin/python3

import sys
import difflib

import apsw


def compare_strings(string1, string2):
    """Compare strings diff-style."""
    diff = list(difflib.unified_diff(string1.splitlines(1), string2.splitlines(1), n=0))
    if len(diff):
        print(f"\n{len(diff)} Differences:")
        print("\n".join(diff))
        print(f"\n{len(diff)} differences")
    return len(diff)


def get_ledger(database_file):
    db = apsw.Connection(database_file, flags=apsw.SQLITE_OPEN_READONLY)
    cursor = db.cursor()

    credit_fields = "block_index, address, asset, quantity, calling_function, event"
    debit_fields = "block_index, address, asset, quantity, action, event"
    query = f"""SELECT 'credit' as table_name, {credit_fields} FROM credits
            UNION ALL
            SELECT 'debits' as table_name, {debit_fields} FROM debits
            ORDER BY block_index DESC
            """

    cursor.execute(query)

    rows = []
    for row in cursor:
        rows.append(", ".join([str(x) for x in row]))
    rows_str = "\n".join(rows)

    return f"{database_file}\n{rows_str}"

database_file_1 = sys.argv[1]
database_file_2 = sys.argv[2]
ledger_1 = get_ledger(database_file_1)
ledger_2 = get_ledger(database_file_2)

compare_strings(ledger_1, ledger_2)
