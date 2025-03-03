#!/usr/bin/python3


import apsw

db_ok = apsw.Connection(
    "/home/ouziel/.local/share/counterparty/counterparty.db", flags=apsw.SQLITE_OPEN_READONLY
)
db_nok = apsw.Connection(
    "/home/ouziel/.local/share/counterparty/asset_conservation.db", flags=apsw.SQLITE_OPEN_READONLY
)


sql = """
    SELECT address, asset, quantity, (address || asset) AS aa, MAX(rowid)
    FROM balances
    WHERE address IS NOT NULL AND utxo IS NULL AND asset = 'XCP' AND quantity > 0
    GROUP BY aa
"""

cursor_ok = db_ok.cursor()
cursor_nok = db_nok.cursor()

cursor_ok.execute(sql)
cursor_nok.execute(sql)

balances_ok = cursor_ok.fetchall()
balances_nok = cursor_nok.fetchall()

print(len(balances_ok))
print(len(balances_nok))

balances_by_address_ok = {}
for balance in balances_ok:
    address = balance[0]
    quantity = balance[2]
    balances_by_address_ok[address] = quantity

balances_by_address_nok = {}
for balance in balances_nok:
    address = balance[0]
    quantity = balance[2]
    balances_by_address_nok[address] = quantity

for address, balance in balances_by_address_ok.items():
    if address not in balances_by_address_nok:
        print(f"Address {address} not found in asset_conservation.db")
    elif balance != balances_by_address_nok[address]:
        print(
            f"Address {address} has different balance in asset_conservation.db: {balance} != {balances_by_address_nok[address]}"
        )
