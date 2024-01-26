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
    query = f"""SELECT 'credit' as table_name, {credit_fields} FROM credits WHERE block_index < 316000
            UNION ALL
            SELECT 'debits' as table_name, {debit_fields} FROM debits WHERE block_index < 316000
            ORDER BY block_index DESC
            """

    cursor.execute(query)

    rows = []
    for row in cursor:
        rows.append(", ".join([str(x) for x in row]))
    rows_str = "\n".join(rows)

    return f"{database_file}\n{rows_str}"

def compare_block_ledger(database_file_1, database_file_2, block_index):
    db1 = apsw.Connection(database_file_1, flags=apsw.SQLITE_OPEN_READONLY)
    cursor1 = db1.cursor()

    db2 = apsw.Connection(database_file_2, flags=apsw.SQLITE_OPEN_READONLY)
    cursor2 = db2.cursor()

    credit_fields = "block_index, address, asset, quantity, calling_function, event"
    debit_fields = "block_index, address, asset, quantity, action, event"
    query = f"""SELECT 'credit' as table_name, {credit_fields} FROM credits WHERE block_index = ?
            UNION ALL
            SELECT 'debits' as table_name, {debit_fields} FROM debits WHERE block_index = ?
            ORDER BY block_index DESC
            """
    movements1 = cursor1.execute(query, (block_index, block_index)).fetchall()
    movements2 = cursor2.execute(query, (block_index, block_index)).fetchall()
    block1_str = "\n".join([", ".join([str(x) for x in mvnt]) for mvnt in movements1])
    block2_str = "\n".join([", ".join([str(x) for x in mvnt]) for mvnt in movements2])
    print(f"Block {block_index}")
    print("-------------------------------------")
    print(block1_str)
    print("-------------------------------------")
    print(block2_str)
    print("-------------------------------------")
    compare_strings(block1_str, block2_str)

def check_hashes(database_file_1, database_file_2):
    db1 = apsw.Connection(database_file_1, flags=apsw.SQLITE_OPEN_READONLY)
    cursor1 = db1.cursor()

    db2 = apsw.Connection(database_file_2, flags=apsw.SQLITE_OPEN_READONLY)
    cursor2 = db2.cursor()

    query = f"""SELECT block_index, ledger_hash FROM blocks WHERE block_index < 316001 ORDER BY block_index """

    cursor1.execute(query)
    for block1 in cursor1:
        block2 = cursor2.execute("SELECT block_index, ledger_hash FROM blocks WHERE block_index = ?", (block1[0],)).fetchone()
        if block1[1] != block2[1]:
            print(block1[0], block1[1], block2[1])
            compare_block_ledger(database_file_1, database_file_2, block1[0])
            raise Exception("Hashes do not match")


def compare_ledger(database_file_1, database_file_2):
    ledger_1 = get_ledger(database_file_1)
    ledger_2 = get_ledger(database_file_2)
    compare_strings(ledger_1, ledger_2)



database_file_1 = sys.argv[1]
database_file_2 = sys.argv[2]

compare_ledger(database_file_1, database_file_2)
check_hashes(database_file_1, database_file_2)

