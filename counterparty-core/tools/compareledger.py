#!/usr/bin/python3

import difflib
import sys

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
    query = f"""SELECT 'credit' as table_name, {credit_fields} FROM credits WHERE block_index < {LAST_BLOCK}
            UNION ALL
            SELECT 'debits' as table_name, {debit_fields} FROM debits WHERE block_index < {LAST_BLOCK}
            ORDER BY block_index DESC
            """  # noqa: S608

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
            """  # noqa: S608
    movements1 = cursor1.execute(query, (block_index, block_index)).fetchall()
    movements2 = cursor2.execute(query, (block_index, block_index)).fetchall()
    block1_str = "\n".join([", ".join([str(x) for x in mvnt]) for mvnt in movements1])
    block2_str = "\n".join([", ".join([str(x) for x in mvnt]) for mvnt in movements2])
    print(f"Block {block_index}")
    print(f"----------------{database_file_1}---------------------")
    print(block1_str)
    print(f"----------------{database_file_2}---------------------")
    print(block2_str)
    print("-------------------------------------")
    compare_strings(block1_str, block2_str)


def compare_txlist(database_file_1, database_file_2, block_index):
    db1 = apsw.Connection(database_file_1, flags=apsw.SQLITE_OPEN_READONLY)
    cursor1 = db1.cursor()

    db2 = apsw.Connection(database_file_2, flags=apsw.SQLITE_OPEN_READONLY)
    cursor2 = db2.cursor()

    query = f"""SELECT * FROM transactions WHERE block_index = {block_index} ORDER BY tx_index"""  # noqa: S608

    liste1 = cursor1.execute(query).fetchall()
    liste2 = cursor2.execute(query).fetchall()
    block1_str = "\n".join([", ".join([str(x) for x in mvnt]) for mvnt in liste1])
    block2_str = "\n".join([", ".join([str(x) for x in mvnt]) for mvnt in liste2])
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

    query = f"""SELECT block_index, {hash_name} FROM blocks WHERE block_index < {LAST_BLOCK} ORDER BY block_index """  # noqa: S608

    cursor1.execute(query)
    for block1 in cursor1:
        block2 = cursor2.execute(
            f"SELECT block_index, {hash_name} FROM blocks WHERE block_index = ?",  # noqa: S608
            (block1[0],),  # noqa: S608
        ).fetchone()
        if block1[1] != block2[1]:
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

LAST_BLOCK = 340000
# compare_ledger(database_file_1, database_file_2)
check_hashes(database_file_1, database_file_2, "ledger_hash")
# get_checkpoints(database_file_1)
# get_last_block(database_file_1, database_file_2)
