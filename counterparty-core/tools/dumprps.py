import json

import apsw

DATABASE = "/home/ouziel/.local/share/counterparty/counterparty.db"

EVENTS = [
    "CANCEL_RPS",
    "OPEN_RPS",
    "RPS_MATCH",
    "RPS_EXPIRATION",
    "RPS_MATCH_EXPIRATION",
    "RPS_RESOLVE",
    "RPS_MATCH_UPDATE",
    "RPS_UPDATE",
]

credits_calling_function = ["recredit wager", "wins"]
debits_acions = ["open RPS", "reopen RPS after matching expiration"]


db = apsw.Connection(DATABASE, flags=apsw.SQLITE_OPEN_READONLY)
cursor = db.cursor()

query = f"""
    SELECT block_index, tx_hash, event, command, category, bindings 
    FROM messages 
    WHERE
        event IN ('{"', '".join(EVENTS)}') OR
        (event = 'CREDIT' AND bindings LIKE '%"calling_function":"recredit wager"%') OR
        (event = 'CREDIT' AND bindings LIKE '%"calling_function":"wins"%') OR
        (event = 'DEBIT' AND bindings LIKE '%"action":"open RPS"%') OR
        (event = 'DEBIT' AND bindings LIKE '%"action":"reopen RPS after matching expiration"%')
    ORDER BY block_index, tx_hash, rowid
"""  # noqa S608

cursor.execute(query)
rows = cursor.fetchall()

events_by_hash = {}
for row in rows:
    block_index, tx_hash, event, command, category, bindings = row
    event_key = tx_hash
    if event_key is None:
        event_key = block_index
    if event_key not in events_by_hash:
        events_by_hash[event_key] = []
    values = [event, command, category, bindings]
    if event == "RPS_MATCH_UPDATE":
        values.append("id")
    elif event == "RPS_UPDATE":
        values.append("tx_hash")
    events_by_hash[event_key].append(values)

with open("counterpartycore/lib/messages/data/rps_events.json", "w") as f:
    json.dump(events_by_hash, f, indent=4)
