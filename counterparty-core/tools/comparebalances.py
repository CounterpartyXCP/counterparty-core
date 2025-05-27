#!/usr/bin/python3


import apsw

LAST_BLOCK = 885705

db_v10 = apsw.Connection(
    "/home/ouziel/.local/share/counterparty/counterparty.db", flags=apsw.SQLITE_OPEN_READONLY
)
db_v11 = apsw.Connection(
    "/home/ouziel/.local/share/counterparty/v11/counterparty.db", flags=apsw.SQLITE_OPEN_READONLY
)


sql = f"SELECT * FROM balances WHERE block_index <= {LAST_BLOCK} ORDER BY rowid"  # noqa: S608

cursor_v10 = db_v10.cursor()
cursor_v11 = db_v11.cursor()

cursor_v10.execute(sql)
cursor_v11.execute(sql)

for row_v10, row_v11 in zip(cursor_v10, cursor_v11):
    if row_v10 != row_v11:
        print("Mismatch:")
        print("v10:", row_v10)
        print("v11:", row_v11)
        row_v10_with_truncated_address = [row_v10[0][:36]] + list(row_v10[1:])
        row_v11_with_truncated_address = [row_v11[0][:36]] + list(row_v11[1:])
        assert row_v10_with_truncated_address == row_v11_with_truncated_address
        print("Only difference is the address length: OK")
        print("-" * 50)
