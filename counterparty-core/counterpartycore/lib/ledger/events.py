import binascii
import json
import time
from contextlib import contextmanager

from counterpartycore.lib import backend, config, exceptions
from counterpartycore.lib.cli import log
from counterpartycore.lib.ledger.balances import get_balance
from counterpartycore.lib.ledger.caches import AssetCache, UTXOBalancesCache
from counterpartycore.lib.ledger.currentstate import ConsensusHashBuilder, CurrentState
from counterpartycore.lib.parser import protocol, utxosinfo
from counterpartycore.lib.utils import helpers


@contextmanager
def get_cursor(db):
    cursor = db.cursor()
    try:
        yield cursor
    finally:
        cursor.close()


def insert_record(db, table_name, record, event, event_info=None):
    fields = list(record.keys())
    placeholders = ", ".join(["?" for _ in fields])
    query = f"INSERT INTO {table_name} ({', '.join(fields)}) VALUES ({placeholders})"  # noqa: S608 # nosec B608

    with get_cursor(db) as cursor:
        cursor.execute(query, list(record.values()))
        if table_name in ["issuances", "destructions"] and not CurrentState().parsing_mempool():
            cursor.execute("SELECT last_insert_rowid() AS rowid")
            inserted_rowid = cursor.fetchone()["rowid"]
            new_record = cursor.execute(
                f"SELECT * FROM {table_name} WHERE rowid = ?",  # noqa: S608 # nosec B608
                (inserted_rowid,),
            ).fetchone()
            if AssetCache in AssetCache._instances:  # pylint: disable=protected-access
                if table_name == "issuances":
                    AssetCache(db).add_issuance(new_record)
                elif table_name == "destructions":
                    AssetCache(db).add_destroyed(new_record)
            else:
                AssetCache(db)  # initialization will add just created record to cache

    add_to_journal(
        db,
        CurrentState().current_block_index(),
        "insert",
        table_name,
        event,
        record | (event_info or {}),
    )


# This function allows you to update a record using an INSERT.
# The `block_index` and `rowid` fields allow you to
# order updates and retrieve the row with the current data.
def insert_update(db, table_name, id_name, id_value, update_data, event, event_info=None):  # noqa: B006
    cursor = db.cursor()
    # select records to update
    select_query = f"""
        SELECT *, rowid
        FROM {table_name}
        WHERE {id_name} = ?
        ORDER BY rowid DESC
        LIMIT 1
    """  # nosec B608  # noqa: S608 # nosec B608
    bindings = (id_value,)
    need_update_record = cursor.execute(select_query, bindings).fetchone()

    # update record
    new_record = need_update_record.copy()
    # updade needed fields
    for key, value in update_data.items():
        new_record[key] = value
    # new block_index and tx_index
    new_record["block_index"] = CurrentState().current_block_index()
    # let's keep the original tx_index so we can preserve order
    # with the old queries (ordered by default by old primary key)
    # if 'tx_index' in new_record:
    #    new_record['tx_index'] = tx_index
    # insert new record
    if "rowid" in new_record:
        del new_record["rowid"]
    fields_name = ", ".join(new_record.keys())
    fields_values = ", ".join([f":{key}" for key in new_record.keys()])
    # no sql injection here
    insert_query = f"""INSERT INTO {table_name} ({fields_name}) VALUES ({fields_values})"""  # nosec B608  # noqa: S608 # nosec B608
    cursor.execute(insert_query, new_record)
    cursor.close()
    # Add event to journal
    event_paylod = update_data | {id_name: id_value} | (event_info or {})
    if "rowid" in event_paylod:
        del event_paylod["rowid"]
    add_to_journal(
        db, CurrentState().current_block_index(), "update", table_name, event, event_paylod
    )


def last_message(db):
    """Return latest message from the db."""
    cursor = db.cursor()
    query = """
        SELECT * FROM messages
        WHERE message_index = (
            SELECT MAX(message_index) from messages
        )
    """
    messages = list(cursor.execute(query))
    if messages:
        assert len(messages) == 1
        message = messages[0]
    else:
        raise exceptions.DatabaseError("No messages found.")
    cursor.close()
    return message


# we are using a function here for testing purposes
def curr_time():
    return int(time.time())


def add_to_journal(db, block_index, command, category, event, bindings):
    # Get last message index.
    try:
        previous_message = last_message(db)
        message_index = previous_message["message_index"] + 1
        previous_event_hash = previous_message["event_hash"] or ""
    except exceptions.DatabaseError:
        message_index = 0
        previous_event_hash = ""

    items = {
        key: binascii.hexlify(value).decode("ascii") if isinstance(value, bytes) else value
        for key, value in bindings.items()
    }

    current_time = curr_time()
    bindings_string = json.dumps(items, sort_keys=True, separators=(",", ":"))
    event_hash_content = "".join(
        [
            str(message_index),
            str(block_index),
            command,
            category,
            bindings_string,
            event,
            CurrentState().current_tx_hash() or "",
            previous_event_hash,
        ]
    )
    event_hash = binascii.hexlify(helpers.dhash(event_hash_content)).decode("ascii")
    message_bindings = {
        "message_index": message_index,
        "block_index": block_index,
        "command": command,
        "category": category,
        "bindings": bindings_string,
        "timestamp": current_time,
        "event": event,
        "tx_hash": CurrentState().current_tx_hash(),
        "event_hash": event_hash,
    }
    query = """INSERT INTO messages (
                message_index, block_index, command, category, bindings, timestamp, event, tx_hash, event_hash
            ) VALUES (
                :message_index,
                :block_index,
                :command,
                :category,
                :bindings,
                :timestamp,
                :event,
                :tx_hash,
                :event_hash
            )"""
    cursor = db.cursor()
    cursor.execute(query, message_bindings)
    cursor.close()

    ConsensusHashBuilder().append_to_block_journal(f"{command}{category}{bindings_string}")

    log.log_event(block_index, message_index, event, items)


def remove_from_balance(db, address, asset, quantity, tx_index, utxo_address=None):
    balance_cursor = db.cursor()

    no_balance = False
    try:
        old_balance = get_balance(db, address, asset, raise_error_if_no_balance=True)
    except exceptions.BalanceError:
        old_balance = 0
        no_balance = True

    if old_balance < quantity:
        raise exceptions.DebitError("Insufficient funds.")

    balance = round(old_balance - quantity)
    balance = min(balance, config.MAX_INT)
    assert balance >= 0

    balance_address = address
    utxo = None
    if protocol.enabled("utxo_support") and utxosinfo.is_utxo_format(address):
        balance_address = None
        utxo = address
        if not CurrentState().parsing_mempool() and balance == 0:
            UTXOBalancesCache(db).remove_balance(utxo)

    if not no_balance:  # don't create balance if quantity is 0 and there is no balance
        bindings = {
            "quantity": balance,
            "address": balance_address,
            "utxo": utxo,
            "utxo_address": utxo_address,
            "asset": asset,
            "block_index": CurrentState().current_block_index(),
            "tx_index": tx_index,
        }
        query = """
            INSERT INTO balances (address, asset, quantity, block_index, tx_index, utxo, utxo_address)
            VALUES (:address, :asset, :quantity, :block_index, :tx_index, :utxo, :utxo_address)
        """
        balance_cursor.execute(query, bindings)


def debit(db, address, asset, quantity, tx_index, action=None, event=None):
    """Debit given address by quantity of asset."""
    block_index = CurrentState().current_block_index()

    if not isinstance(quantity, int):  # noqa: E721
        raise exceptions.DebitError("Quantity must be an integer.")
    if quantity < 0:
        raise exceptions.DebitError("Negative quantity.")
    if quantity > config.MAX_INT:
        raise exceptions.DebitError("Quantity can't be higher than MAX_INT.")
    if asset == config.BTC:
        raise exceptions.DebitError("Cannot debit bitcoins.")

    # Contracts can only hold XCP balances.
    if protocol.enabled("contracts_only_xcp_balances"):  # Protocol change.
        if len(address) == 40:
            assert asset == config.XCP

    debit_address = address
    utxo = None
    utxo_address = None
    if protocol.enabled("utxo_support") and utxosinfo.is_utxo_format(address):
        debit_address = None
        utxo = address
        utxo_address = backend.bitcoind.safe_get_utxo_address(utxo)

    remove_from_balance(db, address, asset, quantity, tx_index, utxo_address)

    # Record debit.
    bindings = {
        "block_index": block_index,
        "address": debit_address,
        "utxo": utxo,
        "utxo_address": utxo_address,
        "asset": asset,
        "quantity": quantity,
        "action": action,
        "event": event,
        "tx_index": tx_index,
    }
    insert_record(db, "debits", bindings, "DEBIT")

    ConsensusHashBuilder().append_to_block_ledger(f"{block_index}{address}{asset}{quantity}")
    ConsensusHashBuilder().append_to_block_migration(
        f"{block_index}{address[0:36]}{asset}{quantity}"
    )
    return utxo_address


def add_to_balance(db, address, asset, quantity, tx_index, utxo_address=None):
    balance_cursor = db.cursor()

    old_balance = get_balance(db, address, asset)
    balance = round(old_balance + quantity)
    balance = min(balance, config.MAX_INT)

    balance_address = address
    utxo = None
    if protocol.enabled("utxo_support") and utxosinfo.is_utxo_format(address):
        balance_address = None
        utxo = address
        if not CurrentState().parsing_mempool() and balance > 0:
            UTXOBalancesCache(db).add_balance(utxo)

    bindings = {
        "quantity": balance,
        "address": balance_address,
        "utxo": utxo,
        "utxo_address": utxo_address,
        "asset": asset,
        "block_index": CurrentState().current_block_index(),
        "tx_index": tx_index,
    }
    query = """
        INSERT INTO balances (address, asset, quantity, block_index, tx_index, utxo, utxo_address)
        VALUES (:address, :asset, :quantity, :block_index, :tx_index, :utxo, :utxo_address)
    """
    balance_cursor.execute(query, bindings)


def credit(db, address, asset, quantity, tx_index, action=None, event=None):
    """Credit given address by quantity of asset."""
    block_index = CurrentState().current_block_index()

    if not isinstance(quantity, int):  # noqa: E721
        raise exceptions.CreditError("Quantity must be an integer.")
    if quantity < 0:
        raise exceptions.CreditError("Negative quantity.")
    if quantity > config.MAX_INT:
        raise exceptions.CreditError("Quantity can't be higher than MAX_INT.")
    if asset == config.BTC:
        raise exceptions.CreditError("Cannot debit bitcoins.")

    # Contracts can only hold XCP balances.
    if protocol.enabled("contracts_only_xcp_balances"):  # Protocol change.
        if len(address) == 40:
            assert asset == config.XCP

    credit_address = address
    utxo = None
    utxo_address = None
    if protocol.enabled("utxo_support") and utxosinfo.is_utxo_format(address):
        credit_address = None
        utxo = address
        utxo_address = backend.bitcoind.safe_get_utxo_address(utxo)

    add_to_balance(db, address, asset, quantity, tx_index, utxo_address)

    # Record credit.
    bindings = {
        "block_index": block_index,
        "address": credit_address,
        "utxo": utxo,
        "utxo_address": utxo_address,
        "asset": asset,
        "quantity": quantity,
        "calling_function": action,
        "event": event,
        "tx_index": tx_index,
    }
    insert_record(db, "credits", bindings, "CREDIT")

    ConsensusHashBuilder().append_to_block_ledger(f"{block_index}{address}{asset}{quantity}")
    ConsensusHashBuilder().append_to_block_migration(
        f"{block_index}{address[0:36]}{asset}{quantity}"
    )

    return utxo_address


def get_messages(db, block_index=None, block_index_in=None, message_index_in=None, limit=100):
    cursor = db.cursor()
    where = []
    bindings = []
    if block_index is not None:
        where.append("block_index = ?")
        bindings.append(block_index)
    if block_index_in is not None:
        where.append(f"block_index IN ({','.join(['?' for e in range(0, len(block_index_in))])})")
        bindings += block_index_in
    if message_index_in is not None:
        where.append(
            f"message_index IN ({','.join(['?' for e in range(0, len(message_index_in))])})"
        )
        bindings += message_index_in
    # no sql injection here
    if len(where) == 0:
        query = """SELECT * FROM messages ORDER BY message_index ASC LIMIT ?"""
    else:
        query = f"""SELECT * FROM messages WHERE ({" AND ".join(where)}) ORDER BY message_index ASC LIMIT ?"""  # nosec B608  # noqa: S608 # nosec B608
    bindings.append(limit)
    cursor.execute(query, tuple(bindings))
    return cursor.fetchall()


def replay_event(db, event, action, table, bindings, id_name=None):
    if action == "insert":
        if event == "DEBIT":
            debit(
                db,
                bindings["address"],
                bindings["asset"],
                bindings["quantity"],
                bindings["tx_index"],
                action=bindings["action"],
                event=bindings["event"],
            )
        elif event == "CREDIT":
            credit(
                db,
                bindings["address"],
                bindings["asset"],
                bindings["quantity"],
                bindings["tx_index"],
                action=bindings["calling_function"],
                event=bindings["event"],
            )
        else:
            insert_record(db, table, bindings, event)
    elif action == "update":
        if id_name is None:
            raise exceptions.DatabaseError("id_name is required for update action")
        id_value = bindings.pop(id_name)
        insert_update(db, table, id_name, id_value, bindings, event)
    else:
        raise exceptions.DatabaseError(f"Unknown action: {action}")


def replay_events(db, events):
    for event in events:
        event_name = event[0]
        bindings = json.loads(event[3])
        if event_name.endswith("_UPDATE"):
            replay_event(db, event[0], event[1], event[2], bindings, id_name=event[4])
        else:
            replay_event(db, event[0], event[1], event[2], bindings)
