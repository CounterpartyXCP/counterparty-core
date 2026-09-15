"""Address associations for Ledger events.

``address_events`` is the projection behind ``/v2/addresses/<address>/events``,
``/credits`` and ``/debits``. It is derived in three places -- the watcher as
events stream in, migration ``0001`` on a full State DB build, and
``dbbuilder.backfill_address_events()`` when a refresh or a full rollback
advances the replay cursor past events it never associated -- and all three
have to agree, down to the UTXO-owner alias, or the API answers differently
depending on how the State DB was built.

They therefore share these rules rather than each restating them. This lives
outside ``apiwatcher`` because ``apiwatcher`` imports ``dbbuilder``, so
``dbbuilder`` cannot import it back.
"""

import json

from counterpartycore.lib.parser import utxosinfo

EVENTS_ADDRESS_FIELDS = {
    "NEW_TRANSACTION": ["source", "destination"],
    "DEBIT": ["address"],
    "CREDIT": ["address"],
    "ENHANCED_SEND": ["source", "destination"],
    "MPMA_SEND": ["source", "destination"],
    "SEND": ["source", "destination"],
    "ASSET_TRANSFER": ["source", "issuer"],
    "SWEEP": ["source", "destination"],
    "ASSET_DIVIDEND": ["source"],
    "RESET_ISSUANCE": ["source", "issuer"],
    "ASSET_ISSUANCE": ["source", "issuer"],
    "ASSET_DESTRUCTION": ["source"],
    "OPEN_ORDER": ["source"],
    "ORDER_MATCH": ["tx0_address", "tx1_address"],
    "BTC_PAY": ["source", "destination"],
    "CANCEL_ORDER": ["source"],
    "ORDER_EXPIRATION": ["source"],
    "ORDER_MATCH_EXPIRATION": ["tx0_address", "tx1_address"],
    "OPEN_DISPENSER": ["source", "origin", "oracle_address"],
    "DISPENSER_UPDATE": ["source"],
    "REFILL_DISPENSER": ["source", "destination"],
    "DISPENSE": ["source", "destination"],
    "BROADCAST": ["source"],
    "BURN": ["source"],
    "NEW_FAIRMINT": ["source"],
    "NEW_FAIRMINTER": ["source"],
    "ATTACH_TO_UTXO": ["source", "destination_address"],
    "DETACH_FROM_UTXO": ["source_address", "destination"],
    "UTXO_MOVE": ["source_address", "destination_address"],
    "OPEN_POOL": ["source"],
    "POOL_UPDATE": [],
    "NEW_POOL_DEPOSIT": ["source"],
    "NEW_POOL_WITHDRAWAL": ["source"],
    "POOL_MATCH": ["source"],
}


def search_address_from_utxo(state_db, utxo):
    cursor = state_db.cursor()
    sql = "SELECT utxo_address FROM balances WHERE utxo = ? LIMIT 1"
    cursor.execute(sql, (utxo,))
    address = cursor.fetchone()
    if address is not None:
        return address["utxo_address"]
    return None


def update_address_events(state_db, event):
    if event["event"] not in EVENTS_ADDRESS_FIELDS:
        return
    event_bindings = json.loads(event["bindings"])
    cursor = state_db.cursor()
    for field in EVENTS_ADDRESS_FIELDS[event["event"]]:
        if field not in event_bindings:
            continue
        address = event_bindings[field]
        sql = """
            INSERT INTO address_events (address, event_index, block_index, event)
            VALUES (:address, :event_index, :block_index, :event)
            """
        cursor.execute(
            sql,
            {
                "address": address,
                "event_index": event["message_index"],
                "block_index": event["block_index"],
                "event": event["event"],
            },
        )
        if utxosinfo.is_utxo_format(address):
            utxo_address = search_address_from_utxo(state_db, address)
            if utxo_address is not None:
                cursor.execute(
                    sql,
                    {
                        "address": utxo_address,
                        "event_index": event["message_index"],
                        "block_index": event["block_index"],
                        "event": event["event"],
                    },
                )
