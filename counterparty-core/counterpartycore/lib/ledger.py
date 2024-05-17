import binascii
import fractions
import json
import logging
import time
from decimal import Decimal as D

from counterpartycore.lib import backend, config, exceptions, log, util

logger = logging.getLogger(config.LOGGER_NAME)

BLOCK_LEDGER = []
BLOCK_JOURNAL = []

###########################
#         MESSAGES        #
###########################


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
        last_message = messages[0]
    else:
        raise exceptions.DatabaseError("No messages found.")
    cursor.close()
    return last_message


def get_messages(db, block_index=None, block_index_in=None, message_index_in=None):
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
    query = f"""SELECT * FROM messages WHERE ({" AND ".join(where)}) ORDER BY message_index ASC"""  # nosec B608  # noqa: S608
    cursor.execute(query, tuple(bindings))
    return cursor.fetchall()


def get_events(
    db, block_index=None, event=None, event_index=None, last=None, limit=None, tx_hash=None
):
    cursor = db.cursor()
    where = []
    bindings = []
    if block_index is not None:
        where.append("block_index = ?")
        bindings.append(block_index)
    if event is not None:
        where.append("event = ?")
        bindings.append(event)
    if event_index is not None:
        where.append("message_index = ?")
        bindings.append(event_index)
    if last is not None:
        where.append("message_index <= ?")
        bindings.append(last)
    if tx_hash is not None:
        where.append("tx_hash = ?")
        bindings.append(tx_hash)
    if block_index is None and limit is None:
        limit = 100
    if limit is not None:
        limit = f"LIMIT {int(limit)}"
    else:
        limit = ""
    # no sql injection here
    select_fields = "message_index AS event_index, event, bindings AS params, tx_hash"
    if block_index is None:
        select_fields += ", block_index, timestamp"
    query = f"""
        SELECT {select_fields}
        FROM messages
    """  # noqa S608
    if len(where) > 0:
        query += f"""
            WHERE ({" AND ".join(where)})
        """  # nosec B608  # noqa: S608
    query += f"""
        ORDER BY message_index DESC {limit}
    """
    cursor.execute(query, tuple(bindings))
    events = cursor.fetchall()
    for i, _ in enumerate(events):
        events[i]["params"] = json.loads(events[i]["params"])
    return events


def get_all_events(db, last: int = None, limit: int = 100):
    """
    Returns all events
    :param int last: The last event index to return (e.g. 10665092)
    :param int limit: The maximum number of events to return (e.g. 5)
    """
    return get_events(db, last=last, limit=limit)


def get_events_by_block(db, block_index: int):
    """
    Returns the events of a block
    :param int block_index: The index of the block to return (e.g. 840464)
    """
    return get_events(db, block_index=block_index)


def get_events_by_transaction_hash(db, tx_hash: str):
    """
    Returns the events of a transaction
    :param str tx_hash: The hash of the transaction to return (e.g. 84b34b19d971adc2ad2dc6bfc5065ca976db1488f207df4887da976fbf2fd040)
    """
    return get_events(db, tx_hash=tx_hash)


def get_events_by_transaction_hash_and_event(db, tx_hash: str, event: str):
    """
    Returns the events of a transaction
    :param str tx_hash: The hash of the transaction to return (e.g. 84b34b19d971adc2ad2dc6bfc5065ca976db1488f207df4887da976fbf2fd040)
    :param str event: The event to filter by (e.g. CREDIT)
    """
    return get_events(db, tx_hash=tx_hash, event=event)


def get_events_by_transaction_index(db, tx_index: int):
    """
    Returns the events of a transaction
    :param str tx_index: The index of the transaction to return (e.g. 1000)
    """
    txs = get_transactions(db, tx_index=tx_index)
    if txs:
        tx = txs[0]
        return get_events(db, tx_hash=tx["tx_hash"])
    return None


def get_events_by_transaction_index_and_event(db, tx_index: int, event: str):
    """
    Returns the events of a transaction
    :param str tx_index: The index of the transaction to return (e.g. 1000)
    :param str event: The event to filter by (e.g. CREDIT)
    """
    txs = get_transactions(db, tx_index=tx_index)
    if txs:
        tx = txs[0]
        return get_events(db, tx_hash=tx["tx_hash"], event=event)
    return None


def get_events_by_block_and_event(db, block_index: int, event: str):
    """
    Returns the events of a block filtered by event
    :param int block_index: The index of the block to return (e.g. 840464)
    :param str event: The event to filter by (e.g. CREDIT)
    """
    if event == "count":
        return get_event_counts_by_block(db, block_index=block_index)
    return get_events(db, block_index=block_index, event=event)


def get_event_by_index(db, event_index: int):
    """
    Returns the event of an index
    :param int event_index: The index of the event to return (e.g. 10665092)
    """
    return get_events(db, event_index=event_index)


def get_events_by_name(db, event: str, last: int = None, limit: int = 100):
    """
    Returns the events filtered by event name
    :param str event: The event to return (e.g. CREDIT)
    :param int last: The last event index to return (e.g. 10665092)
    :param int limit: The maximum number of events to return (e.g. 5)
    """
    return get_events(db, event=event, last=last, limit=limit)


def get_mempool_events(db, event_name=None):
    cursor = db.cursor()
    where = []
    bindings = []
    if event_name is not None:
        where.append("event = ?")
        bindings.append(event_name)
    # no sql injection here
    query = """
        SELECT tx_hash, event, bindings AS params, timestamp
        FROM mempool
    """
    if event_name is not None:
        query += f"""WHERE ({" AND ".join(where)})"""  # nosec B608  # noqa: S608
    query += """ORDER BY timestamp DESC"""
    cursor.execute(query, tuple(bindings))
    events = cursor.fetchall()
    for i, _ in enumerate(events):
        events[i]["params"] = json.loads(events[i]["params"])
    return events


def get_all_mempool_events(db):
    """
    Returns all mempool events
    """
    return get_mempool_events(db)


def get_mempool_events_by_name(db, event: str):
    """
    Returns the mempool events filtered by event name
    :param str event: The event to return (e.g. OPEN_ORDER)
    """
    return get_mempool_events(db, event_name=event)


def get_events_counts(db, block_index=None):
    cursor = db.cursor()
    bindings = []
    query = """
        SELECT event, COUNT(*) AS event_count
        FROM messages
    """
    if block_index is not None:
        query += "WHERE block_index = ?"
        bindings.append(block_index)
    query += " GROUP BY event"
    cursor.execute(query, bindings)
    return cursor.fetchall()


def get_event_counts_by_block(db, block_index: int):
    """
    Returns the event counts of a block
    :param int block_index: The index of the block to return (e.g. 840464)
    """
    return get_events_counts(db, block_index=block_index)


def get_all_events_counts(db):
    """
    Returns the event counts of all blocks
    """
    return get_events_counts(db)


# we are using a function here for testing purposes
def curr_time():
    return int(time.time())


def add_to_journal(db, block_index, command, category, event, bindings):
    cursor = db.cursor()

    # Get last message index.
    try:
        message = last_message(db)
        message_index = message["message_index"] + 1
    except exceptions.DatabaseError:
        message_index = 0

    # Handle binary data.
    items = {}
    for key, value in bindings.items():
        if isinstance(value, bytes):
            items[key] = binascii.hexlify(value).decode("ascii")
        else:
            items[key] = value

    current_time = curr_time()
    bindings_string = json.dumps(items, sort_keys=True, separators=(",", ":"))
    message_bindings = {
        "message_index": message_index,
        "block_index": block_index,
        "command": command,
        "category": category,
        "bindings": bindings_string,
        "timestamp": current_time,
        "event": event,
        "tx_hash": util.CURRENT_TX_HASH,
    }
    query = """INSERT INTO messages VALUES (
                    :message_index,
                    :block_index,
                    :command,
                    :category,
                    :bindings,
                    :timestamp,
                    :event,
                    :tx_hash)"""
    cursor.execute(query, message_bindings)
    cursor.close()

    BLOCK_JOURNAL.append(f"{command}{category}{bindings_string}")

    log.log_event(block_index, event, items)


###########################
#         BALANCES        #
###########################


def remove_from_balance(db, address, asset, quantity, tx_index):
    balance_cursor = db.cursor()

    no_balance = False
    try:
        old_balance = get_balance(db, address, asset, raise_error_if_no_balance=True)
    except exceptions.BalanceError:
        old_balance = 0
        no_balance = True

    if old_balance < quantity:
        raise DebitError("Insufficient funds.")

    balance = round(old_balance - quantity)
    balance = min(balance, config.MAX_INT)
    assert balance >= 0

    if not no_balance:  # don't create balance if quantity is 0 and there is no balance
        bindings = {
            "quantity": balance,
            "address": address,
            "asset": asset,
            "block_index": util.CURRENT_BLOCK_INDEX,
            "tx_index": tx_index,
        }
        query = """
            INSERT INTO balances
            VALUES (:address, :asset, :quantity, :block_index, :tx_index)
        """
        balance_cursor.execute(query, bindings)


class DebitError(Exception):
    pass


def debit(db, address, asset, quantity, tx_index, action=None, event=None):
    """Debit given address by quantity of asset."""
    block_index = util.CURRENT_BLOCK_INDEX

    if type(quantity) != int:  # noqa: E721
        raise DebitError("Quantity must be an integer.")
    if quantity < 0:
        raise DebitError("Negative quantity.")
    if quantity > config.MAX_INT:
        raise DebitError("Quantity can't be higher than MAX_INT.")
    if asset == config.BTC:
        raise DebitError("Cannot debit bitcoins.")

    debit_cursor = db.cursor()  # noqa: F841

    # Contracts can only hold XCP balances.
    if util.enabled("contracts_only_xcp_balances"):  # Protocol change.
        if len(address) == 40:
            assert asset == config.XCP

    if asset == config.BTC:
        raise exceptions.BalanceError(f"Cannot debit bitcoins from a {config.XCP_NAME} address!")

    remove_from_balance(db, address, asset, quantity, tx_index)

    # Record debit.
    bindings = {
        "block_index": block_index,
        "address": address,
        "asset": asset,
        "quantity": quantity,
        "action": action,
        "event": event,
        "tx_index": tx_index,
    }
    insert_record(db, "debits", bindings, "DEBIT")

    BLOCK_LEDGER.append(f"{block_index}{address}{asset}{quantity}")


def add_to_balance(db, address, asset, quantity, tx_index):
    balance_cursor = db.cursor()

    old_balance = get_balance(db, address, asset)
    balance = round(old_balance + quantity)
    balance = min(balance, config.MAX_INT)

    bindings = {
        "quantity": balance,
        "address": address,
        "asset": asset,
        "block_index": util.CURRENT_BLOCK_INDEX,
        "tx_index": tx_index,
    }
    query = """
        INSERT INTO balances
        VALUES (:address, :asset, :quantity, :block_index, :tx_index)
    """
    balance_cursor.execute(query, bindings)


class CreditError(Exception):
    pass


def credit(db, address, asset, quantity, tx_index, action=None, event=None):
    """Credit given address by quantity of asset."""
    block_index = util.CURRENT_BLOCK_INDEX

    if type(quantity) != int:  # noqa: E721
        raise CreditError("Quantity must be an integer.")
    if quantity < 0:
        raise CreditError("Negative quantity.")
    if quantity > config.MAX_INT:
        raise CreditError("Quantity can't be higher than MAX_INT.")
    if asset == config.BTC:
        raise CreditError("Cannot debit bitcoins.")

    credit_cursor = db.cursor()  # noqa: F841

    # Contracts can only hold XCP balances.
    if util.enabled("contracts_only_xcp_balances"):  # Protocol change.
        if len(address) == 40:
            assert asset == config.XCP

    add_to_balance(db, address, asset, quantity, tx_index)

    # Record credit.
    bindings = {
        "block_index": block_index,
        "address": address,
        "asset": asset,
        "quantity": quantity,
        "calling_function": action,
        "event": event,
        "tx_index": tx_index,
    }
    insert_record(db, "credits", bindings, "CREDIT")

    BLOCK_LEDGER.append(f"{block_index}{address}{asset}{quantity}")


def transfer(db, source, destination, asset, quantity, action, event):
    """Transfer quantity of asset from source to destination."""
    debit(db, source, asset, quantity, action=action, event=event)
    credit(db, destination, asset, quantity, action=action, event=event)


def get_balance(db, address, asset, raise_error_if_no_balance=False, return_list=False):
    """Get balance of contract or address."""
    cursor = db.cursor()
    query = """
        SELECT * FROM balances
        WHERE (address = ? AND asset = ?)
        ORDER BY rowid DESC LIMIT 1
    """
    bindings = (address, asset)
    balances = list(cursor.execute(query, bindings))
    cursor.close()
    if return_list:
        return balances
    if not balances and raise_error_if_no_balance:
        raise exceptions.BalanceError(f"No balance for this address and asset: {address}, {asset}.")
    if not balances:
        return 0
    return balances[0]["quantity"]


def get_balance_by_address_and_asset(db, address: str, asset: str):
    """
    Returns the balance of an address and asset
    :param str address: The address to return (e.g. 1C3uGcoSGzKVgFqyZ3kM2DBq9CYttTMAVs)
    :param str asset: The asset to return (e.g. XCP)
    """
    return {
        "address": address,
        "asset": asset,
        "quantity": get_balance(db, address, asset),
    }


def get_address_balances(db, address: str):
    """
    Returns the balances of an address
    :param str address: The address to return (e.g. 1C3uGcoSGzKVgFqyZ3kM2DBq9CYttTMAVs)
    """
    cursor = db.cursor()
    query = """
        SELECT address, asset, quantity, MAX(rowid)
        FROM balances
        WHERE address = ?
        GROUP BY address, asset
    """
    bindings = (address,)
    cursor.execute(query, bindings)
    return cursor.fetchall()


def get_address_assets(db, address):
    cursor = db.cursor()
    query = """
        SELECT DISTINCT asset
        FROM balances
        WHERE address=:address
        GROUP BY asset
    """
    bindings = {"address": address}
    cursor.execute(query, bindings)
    return cursor.fetchall()


def get_balances_count(db, address):
    cursor = db.cursor()
    query = """
        SELECT COUNT(*) AS cnt FROM (
            SELECT DISTINCT asset
            FROM balances
            WHERE address=:address
            GROUP BY asset
        )
    """
    bindings = {"address": address}
    cursor.execute(query, bindings)
    return cursor.fetchall()


def get_credits_or_debits(
    db, table, address=None, asset=None, block_index=None, tx_index=None, offset=0, limit=None
):
    cursor = db.cursor()
    where = []
    bindings = []
    if address is not None:
        where.append("address = ?")
        bindings.append(address)
    if asset is not None:
        where.append("asset = ?")
        bindings.append(asset)
    if block_index is not None:
        where.append("block_index = ?")
        bindings.append(block_index)
    if tx_index is not None:
        where.append("tx_index = ?")
        bindings.append(tx_index)
    query_limit = ""
    if limit is not None:
        query_limit = "LIMIT ?"
        bindings.append(limit)
    query_offset = ""
    if offset > 0:
        query_offset = "OFFSET ?"
        bindings.append(offset)
    # no sql injection here
    query = f"""SELECT * FROM {table} WHERE ({" AND ".join(where)}) {query_limit} {query_offset}"""  # nosec B608  # noqa: S608
    cursor.execute(query, tuple(bindings))
    return cursor.fetchall()


def get_credits(db, address=None, asset=None, block_index=None, tx_index=None, limit=100, offset=0):
    return get_credits_or_debits(
        db, "credits", address, asset, block_index, tx_index, limit=limit, offset=offset
    )


def get_credits_by_block(db, block_index: int):
    """
    Returns the credits of a block
    :param int block_index: The index of the block to return (e.g. 840464)
    """
    return get_credits(db, block_index=block_index)


def get_credits_by_address(db, address: str, limit: int = 100, offset: int = 0):
    """
    Returns the credits of an address
    :param str address: The address to return (e.g. 1C3uGcoSGzKVgFqyZ3kM2DBq9CYttTMAVs)
    :param int limit: The maximum number of credits to return (e.g. 5)
    :param int offset: The offset of the credits to return (e.g. 0)
    """
    return get_credits(db, address=address, limit=limit, offset=offset)


def get_credits_by_asset(db, asset: str, limit: int = 100, offset: int = 0):
    """
    Returns the credits of an asset
    :param str asset: The asset to return (e.g. UNNEGOTIABLE)
    :param int limit: The maximum number of credits to return (e.g. 5)
    :param int offset: The offset of the credits to return (e.g. 0)
    """
    return get_credits(db, asset=asset, limit=limit, offset=offset)


def get_debits(db, address=None, asset=None, block_index=None, tx_index=None, limit=100, offset=0):
    return get_credits_or_debits(
        db, "debits", address, asset, block_index, tx_index, limit=limit, offset=offset
    )


def get_debits_by_block(db, block_index: int):
    """
    Returns the debits of a block
    :param int block_index: The index of the block to return (e.g. 840464)
    """
    return get_debits(db, block_index=block_index)


def get_debits_by_address(db, address: str, limit: int = 100, offset: int = 0):
    """
    Returns the debits of an address
    :param str address: The address to return (e.g. bc1q7787j6msqczs58asdtetchl3zwe8ruj57p9r9y)
    :param int limit: The maximum number of debits to return (e.g. 5)
    :param int offset: The offset of the debits to return (e.g. 0)
    """
    return get_debits(db, address=address, limit=limit, offset=offset)


def get_debits_by_asset(db, asset: str, limit: int = 100, offset: int = 0):
    """
    Returns the debits of an asset
    :param str asset: The asset to return (e.g. XCP)
    :param int limit: The maximum number of debits to return (e.g. 5)
    :param int offset: The offset of the debits to return (e.g. 0)
    """
    return get_debits(db, asset=asset, limit=limit, offset=offset)


def get_sends_or_receives(
    db,
    source=None,
    destination=None,
    asset=None,
    block_index=None,
    status="valid",
    limit=None,
    offset=0,
):
    cursor = db.cursor()
    where = []
    bindings = []
    if source is not None:
        where.append("source = ?")
        bindings.append(source)
    if destination is not None:
        where.append("destination = ?")
        bindings.append(destination)
    if asset is not None:
        where.append("asset = ?")
        bindings.append(asset)
    if block_index is not None:
        where.append("block_index = ?")
        bindings.append(block_index)
    if status is not None:
        where.append("status = ?")
        bindings.append(status)
    query_limit = ""
    if limit is not None:
        query_limit = "LIMIT ?"
        bindings.append(limit)
    query_offset = ""
    if offset > 0:
        query_offset = "OFFSET ?"
        bindings.append(offset)
    # no sql injection here
    query = f"""SELECT * FROM sends WHERE ({" AND ".join(where)}) {query_limit} {query_offset}"""  # nosec B608  # noqa: S608
    cursor.execute(query, tuple(bindings))
    return cursor.fetchall()


def get_sends_by_block(db, block_index: int, limit: int = 100, offset: int = 0):
    """
    Returns the sends of a block
    :param int block_index: The index of the block to return (e.g. 840459)
    :param int limit: The maximum number of sends to return (e.g. 5)
    :param int offset: The offset of the sends to return (e.g. 0)
    """
    return get_sends_or_receives(db, block_index=block_index, limit=limit, offset=offset)


def get_sends_by_asset(db, asset: str, limit: int = 100, offset: int = 0):
    """
    Returns the sends of an asset
    :param str asset: The asset to return (e.g. XCP)
    :param int limit: The maximum number of sends to return (e.g. 5)
    :param int offset: The offset of the sends to return (e.g. 0)
    """
    return get_sends_or_receives(db, asset=asset, limit=limit, offset=offset)


def get_sends(
    db,
    address=None,
    asset=None,
    block_index=None,
    status="valid",
    limit: int = 100,
    offset: int = 0,
):
    return get_sends_or_receives(
        db,
        source=address,
        asset=asset,
        block_index=block_index,
        status=status,
        limit=limit,
        offset=offset,
    )


def get_send_by_address(db, address: str, limit: int = 100, offset: int = 0):
    """
    Returns the sends of an address
    :param str address: The address to return (e.g. 1HVgrYx3U258KwvBEvuG7R8ss1RN2Z9J1W)
    :param int limit: The maximum number of sends to return (e.g. 5)
    :param int offset: The offset of the sends to return (e.g. 0)
    """
    return get_sends(db, address=address, limit=limit, offset=offset)


def get_send_by_address_and_asset(db, address: str, asset: str):
    """
    Returns the sends of an address and asset
    :param str address: The address to return (e.g. 1HVgrYx3U258KwvBEvuG7R8ss1RN2Z9J1W)
    :param str asset: The asset to return (e.g. XCP)
    """
    return get_sends(db, address=address, asset=asset)


def get_receives(
    db,
    address=None,
    asset=None,
    block_index=None,
    status="valid",
    limit: int = 100,
    offset: int = 0,
):
    return get_sends_or_receives(
        db,
        destination=address,
        asset=asset,
        block_index=block_index,
        status=status,
        limit=limit,
        offset=offset,
    )


def get_receive_by_address(db, address: str, limit: int = 100, offset: int = 0):
    """
    Returns the receives of an address
    :param str address: The address to return (e.g. 1C3uGcoSGzKVgFqyZ3kM2DBq9CYttTMAVs)
    :param int limit: The maximum number of receives to return (e.g. 5)
    :param int offset: The offset of the receives to return (e.g. 0)
    """
    return get_receives(db, address=address, limit=limit, offset=offset)


def get_receive_by_address_and_asset(
    db, address: str, asset: str, limit: int = 100, offset: int = 0
):
    """
    Returns the receives of an address and asset
    :param str address: The address to return (e.g. 1C3uGcoSGzKVgFqyZ3kM2DBq9CYttTMAVs)
    :param str asset: The asset to return (e.g. XCP)
    :param int limit: The maximum number of receives to return (e.g. 5)
    :param int offset: The offset of the receives to return (e.g. 0)
    """
    return get_receives(db, address=address, asset=asset, limit=limit, offset=offset)


def get_sweeps(db, address=None, block_index=None, status="valid"):
    cursor = db.cursor()
    where = []
    bindings = []
    if address is not None:
        where.append("source = ?")
        bindings.append(address)
    if block_index is not None:
        where.append("block_index = ?")
        bindings.append(block_index)
    if status is not None:
        where.append("status = ?")
        bindings.append(status)
    # no sql injection here
    query = f"""SELECT * FROM sweeps WHERE ({" AND ".join(where)})"""  # nosec B608  # noqa: S608
    cursor.execute(query, tuple(bindings))
    return cursor.fetchall()


def get_sweeps_by_block(db, block_index: int):
    """
    Returns the sweeps of a block
    :param int block_index: The index of the block to return (e.g. 836519)
    """
    return get_sweeps(db, block_index=block_index)


def get_sweeps_by_address(db, address: str):
    """
    Returns the sweeps of an address
    :param str address: The address to return (e.g. 18szqTVJUWwYrtRHq98Wn4DhCGGiy3jZ87)
    """
    return get_sweeps(db, address=address)


#####################
#     ISSUANCES     #
#####################


def generate_asset_id(asset_name, block_index):
    """Create asset_id from asset_name."""
    if asset_name == config.BTC:
        return 0
    elif asset_name == config.XCP:
        return 1

    if len(asset_name) < 4:
        raise exceptions.AssetNameError("too short")

    # Numeric asset names.
    if util.enabled("numeric_asset_names"):  # Protocol change.
        if asset_name[0] == "A":
            # Must be numeric.
            try:
                asset_id = int(asset_name[1:])
            except ValueError:
                raise exceptions.AssetNameError("non‐numeric asset name starts with ‘A’")  # noqa: B904

            # Number must be in range.
            if not (26**12 + 1 <= asset_id <= 2**64 - 1):
                raise exceptions.AssetNameError("numeric asset name not in range")

            return asset_id
        elif len(asset_name) >= 13:
            raise exceptions.AssetNameError("long asset names must be numeric")

    if asset_name[0] == "A":
        raise exceptions.AssetNameError("non‐numeric asset name starts with ‘A’")

    # Convert the Base 26 string to an integer.
    n = 0
    for c in asset_name:
        n *= 26
        if c not in util.B26_DIGITS:
            raise exceptions.AssetNameError("invalid character:", c)
        digit = util.B26_DIGITS.index(c)
        n += digit
    asset_id = n

    if asset_id < 26**3:
        raise exceptions.AssetNameError("too short")

    return asset_id


def generate_asset_name(asset_id, block_index):
    """Create asset_name from asset_id."""
    if asset_id == 0:
        return config.BTC
    elif asset_id == 1:
        return config.XCP

    if asset_id < 26**3:
        raise exceptions.AssetIDError("too low")

    if util.enabled("numeric_asset_names"):  # Protocol change.
        if asset_id <= 2**64 - 1:
            if 26**12 + 1 <= asset_id:
                asset_name = "A" + str(asset_id)
                return asset_name
        else:
            raise exceptions.AssetIDError("too high")

    # Divide that integer into Base 26 string.
    res = []
    n = asset_id
    while n > 0:
        n, r = divmod(n, 26)
        res.append(util.B26_DIGITS[r])
    asset_name = "".join(res[::-1])

    """
    return asset_name + checksum.compute(asset_name)
    """
    return asset_name


def get_asset_id(db, asset_name, block_index):
    """Return asset_id from asset_name."""
    if not util.enabled("hotfix_numeric_assets"):
        return generate_asset_id(asset_name, block_index)
    cursor = db.cursor()
    query = """
        SELECT * FROM assets
        WHERE asset_name = ?
    """
    bindings = (asset_name,)
    cursor.execute(query, bindings)
    assets = list(cursor)
    if len(assets) == 1:
        return int(assets[0]["asset_id"])
    else:
        raise exceptions.AssetError(f"No such asset: {asset_name}")


def get_asset_name(db, asset_id, block_index):
    """Return asset_name from asset_id."""
    if not util.enabled("hotfix_numeric_assets"):
        return generate_asset_name(asset_id, block_index)
    cursor = db.cursor()
    query = """
        SELECT * FROM assets
        WHERE asset_id = ?
    """
    bindings = (str(asset_id),)
    cursor.execute(query, bindings)
    assets = list(cursor)
    if len(assets) == 1:
        return assets[0]["asset_name"]
    elif not assets:
        return 0  # Strange, I know…


# If asset_name is an existing subasset (PARENT.child) then return the corresponding numeric asset name (A12345)
#   If asset_name is not an existing subasset, then return the unmodified asset_name
def resolve_subasset_longname(db, asset_name):
    if util.enabled("subassets"):
        subasset_longname = None
        try:
            subasset_parent, subasset_longname = util.parse_subasset_from_asset_name(asset_name)
        except Exception as e:  # noqa: F841
            logger.warning(f"Invalid subasset {asset_name}")
            subasset_longname = None

        if subasset_longname is not None:
            cursor = db.cursor()
            query = """
                SELECT asset_name FROM assets
                WHERE asset_longname = ?
            """
            bindings = (subasset_longname,)
            cursor.execute(query, bindings)
            assets = list(cursor)
            cursor.close()
            if len(assets) == 1:
                return assets[0]["asset_name"]

    return asset_name


def is_divisible(db, asset):
    """Check if the asset is divisible."""
    if asset in (config.BTC, config.XCP):
        return True
    else:
        cursor = db.cursor()
        query = """
            SELECT * FROM issuances
            WHERE (status = ? AND asset = ?)
            ORDER BY tx_index DESC
        """
        bindings = ("valid", asset)
        cursor.execute(query, bindings)
        issuances = cursor.fetchall()
        if not issuances:
            raise exceptions.AssetError(f"No such asset: {asset}")
        return issuances[0]["divisible"]


def value_out(db, quantity, asset, divisible=None):
    if asset not in ["leverage", "value", "fraction", "price", "odds"] and divisible == None:  # noqa: E711
        divisible = is_divisible(db, asset)
    return util.value_output(quantity, asset, divisible)


def value_in(db, quantity, asset, divisible=None):
    if asset not in ["leverage", "value", "fraction", "price", "odds"] and divisible == None:  # noqa: E711
        divisible = is_divisible(db, asset)
    return util.value_input(quantity, asset, divisible)


def price(numerator, denominator):
    """Return price as Fraction or Decimal."""
    if util.CURRENT_BLOCK_INDEX >= 294500 or config.TESTNET or config.REGTEST:  # Protocol change.
        return fractions.Fraction(numerator, denominator)
    else:
        numerator = D(numerator)
        denominator = D(denominator)
        return D(numerator / denominator)


def get_asset_issuer(db, asset):
    """Check if the asset is divisible."""
    if asset in (config.BTC, config.XCP):
        return True
    else:
        cursor = db.cursor()
        query = """
            SELECT * FROM issuances
            WHERE (status = ? AND asset = ?)
            ORDER BY tx_index DESC
        """
        bindings = ("valid", asset)
        cursor.execute(query, bindings)
        issuances = cursor.fetchall()
        if not issuances:
            raise exceptions.AssetError(f"No such asset: {asset}")
        return issuances[0]["issuer"]


def get_asset_description(db, asset):
    if asset in (config.BTC, config.XCP):
        return ""
    else:
        cursor = db.cursor()
        query = """
            SELECT * FROM issuances
            WHERE (status = ? AND asset = ?)
            ORDER BY tx_index DESC
        """
        bindings = ("valid", asset)
        cursor.execute(query, bindings)
        issuances = cursor.fetchall()
        if not issuances:
            raise exceptions.AssetError(f"No such asset: {asset}")
        return issuances[0]["description"]


def get_issuances_count(db, address):
    cursor = db.cursor()
    query = """
        SELECT COUNT(DISTINCT(asset)) cnt
        FROM issuances
        WHERE issuer = ?
    """
    bindings = (address,)
    cursor.execute(query, bindings)
    return cursor.fetchall()[0]["cnt"]


def get_asset_issued(db, address):
    cursor = db.cursor()
    query = """
        SELECT DISTINCT(asset)
        FROM issuances
        WHERE issuer = ?
    """
    bindings = (address,)
    cursor.execute(query, bindings)
    return cursor.fetchall()


def get_asset_balances(db, asset: str, exclude_zero_balances: bool = True):
    """
    Returns the asset balances
    :param str asset: The asset to return (e.g. UNNEGOTIABLE)
    :param bool exclude_zero_balances: Whether to exclude zero balances (e.g. True)
    """
    cursor = db.cursor()
    query = """
        SELECT address, asset, quantity, MAX(rowid)
        FROM balances
        WHERE asset = ?
        GROUP BY address, asset
        ORDER BY address
    """
    if exclude_zero_balances:
        query = f"""
            SELECT * FROM (
                {query}
            ) WHERE quantity > 0
        """  # nosec B608  # noqa: S608
    bindings = (asset,)
    cursor.execute(query, bindings)
    return cursor.fetchall()


def get_asset_issuances_quantity(db, asset):
    cursor = db.cursor()
    query = """
        SELECT COUNT(*) AS issuances_count
        FROM issuances
        WHERE (status = ? AND asset = ?)
        ORDER BY tx_index DESC
    """
    bindings = ("valid", asset)
    cursor.execute(query, bindings)
    issuances = cursor.fetchall()
    return issuances[0]["issuances_count"]


def get_asset_info(db, asset: str):
    """
    Returns the asset information
    :param str asset: The asset to return (e.g. UNNEGOTIABLE)
    """
    asset_name = resolve_subasset_longname(db, asset)

    # Defaults.
    asset_info = {
        "asset": asset_name,
        "asset_longname": None,
        "owner": None,
        "divisible": True,
        "locked": False,
        "supply": 0,
        "description": "",
        "issuer": None,
    }

    if asset_name == config.BTC:
        asset_info["supply"] = backend.bitcoind.get_btc_supply(normalize=False)
        return asset_info

    if asset_name == config.XCP:
        asset_info["supply"] = xcp_supply(db)
        asset_info["holder_count"] = get_asset_holder_count(db, asset)
        return asset_info

    asset_info["supply"] = asset_supply(db, asset_name)
    asset_info["holder_count"] = get_asset_holder_count(db, asset)

    cursor = db.cursor()
    query = """
        SELECT * FROM issuances
        WHERE (status = ? AND asset = ?)
        ORDER BY rowid DESC
        LIMIT 1
    """
    bindings = ("valid", asset)
    cursor.execute(query, bindings)
    issuance = cursor.fetchone()

    asset_info = asset_info | {
        "asset_longname": issuance["asset_longname"],
        "owner": issuance["issuer"],
        "divisible": bool(issuance["divisible"]),
        "locked": bool(issuance["locked"]),
        "description": issuance["description"],
        "issuer": issuance["issuer"],
    }

    return asset_info


def get_assets_last_issuance(db, asset_list):
    cursor = db.cursor()
    fields = ["asset", "asset_longname", "description", "issuer", "divisible", "locked"]
    query = f"""
        SELECT {", ".join(fields)}, MAX(rowid) AS rowid
        FROM issuances
        WHERE asset IN ({",".join(["?"] * len(asset_list))})
        AND status = ?
        GROUP BY asset
    """  # nosec B608  # noqa: S608
    cursor.execute(query, asset_list + ["valid"])
    issuances = cursor.fetchall()

    result = {
        "BTC": {
            "divisible": True,
            "asset_longname": "Bitcoin",
            "description": "The Bitcoin cryptocurrency",
            "locked": False,
        },
        "XCP": {
            "divisible": True,
            "asset_longname": "Counterparty",
            "description": "The Counterparty protocol native currency",
            "locked": True,
        },
    }
    for issuance in issuances:
        del issuance["rowid"]
        asset = issuance["asset"]
        del issuance["asset"]
        result[asset] = issuance
    return result


def get_issuances(
    db, asset=None, status=None, locked=None, block_index=None, first=False, last=False
):
    cursor = db.cursor()
    cursor = db.cursor()
    where = []
    bindings = []
    if status is not None:
        where.append("status = ?")
        bindings.append(status)
    if asset is not None:
        where.append("asset = ?")
        bindings.append(asset)
    if locked is not None:
        where.append("locked = ?")
        bindings.append(locked)
    if block_index is not None:
        where.append("block_index = ?")
        bindings.append(block_index)
    # no sql injection here
    query = f"""SELECT * FROM issuances WHERE ({" AND ".join(where)})"""  # nosec B608  # noqa: S608
    if first:
        query += f""" ORDER BY tx_index ASC"""  # noqa: F541
    elif last:
        query += f""" ORDER BY tx_index DESC"""  # noqa: F541
    cursor.execute(query, tuple(bindings))
    return cursor.fetchall()


def get_issuances_by_block(db, block_index: int):
    """
    Returns the issuances of a block
    :param int block_index: The index of the block to return (e.g. 840464)
    """
    return get_issuances(db, block_index=block_index)


def get_issuances_by_asset(db, asset: str):
    """
    Returns the issuances of an asset
    :param str asset: The asset to return (e.g. UNNEGOTIABLE)
    """
    return get_issuances(db, asset=asset)


def get_assets_by_longname(db, asset_longname):
    cursor = db.cursor()
    query = """
        SELECT * FROM assets
        WHERE (asset_longname = ?)
    """
    bindings = (asset_longname,)
    cursor.execute(query, bindings)
    return cursor.fetchall()


def get_valid_assets(db, offset: int = 0, limit: int = 100):
    """
    Returns the valid assets
    :param int offset: The offset of the assets to return (e.g. 0)
    :param int limit: The limit of the assets to return (e.g. 5)
    """
    try:
        int(offset)
        int(limit)
    except ValueError as e:
        raise exceptions.InvalidArgument("Invalid offset or limit parameter") from e
    cursor = db.cursor()
    query = """
        SELECT asset, asset_longname
        FROM issuances
        WHERE status = 'valid'
        GROUP BY asset
        ORDER BY asset ASC
        LIMIT ? OFFSET ?
    """
    cursor.execute(query, (limit, offset))
    return cursor.fetchall()


def get_dividends(db, asset: str):
    """
    Returns the dividends of an asset
    :param str asset: The asset to return (e.g. GMONEYPEPE)
    """
    cursor = db.cursor()
    query = """
        SELECT * FROM dividends
        WHERE asset = ? AND status = ?
    """
    bindings = (asset, "valid")
    cursor.execute(query, bindings)
    return cursor.fetchall()


#####################
#    BROADCASTS     #
#####################


def get_oracle_last_price(db, oracle_address, block_index):
    cursor = db.cursor()
    query = """
        SELECT * FROM broadcasts
        WHERE source = :source AND status = :status AND block_index < :block_index
        ORDER by tx_index DESC LIMIT 1
    """
    bindings = {"source": oracle_address, "status": "valid", "block_index": block_index}
    cursor.execute(query, bindings)
    broadcasts = cursor.fetchall()
    cursor.close()

    if len(broadcasts) == 0:
        return None, None, None, None

    oracle_broadcast = broadcasts[0]
    oracle_label = oracle_broadcast["text"].split("-")
    if len(oracle_label) == 2:
        fiat_label = oracle_label[1]
    else:
        fiat_label = ""

    return (
        oracle_broadcast["value"],
        oracle_broadcast["fee_fraction_int"],
        fiat_label,
        oracle_broadcast["block_index"],
    )


def get_broadcasts_by_source(db, address: str, status: str = "valid", order_by: str = "DESC"):
    """
    Returns the broadcasts of a source
    :param str address: The address to return (e.g. 1QKEpuxEmdp428KEBSDZAKL46noSXWJBkk)
    :param str status: The status of the broadcasts to return (e.g. valid)
    :param str order_by: The order of the broadcasts to return (e.g. ASC)
    """
    if order_by not in ["ASC", "DESC"]:
        raise exceptions.InvalidArgument("Invalid order_by parameter")
    cursor = db.cursor()
    query = f"""
        SELECT * FROM broadcasts
        WHERE (status = ? AND source = ?)
        ORDER BY tx_index {order_by}
    """  # nosec B608  # noqa: S608
    bindings = (status, address)
    cursor.execute(query, bindings)
    return cursor.fetchall()


#####################
#       BURNS       #
#####################


def get_burns(db, address: str = None, status: str = "valid"):
    """
    Returns the burns of an address
    :param str address: The address to return
    :param str status: The status of the burns to return
    """
    cursor = db.cursor()
    where = []
    bindings = []
    if status is not None:
        where.append("status = ?")
        bindings.append(status)
    if address is not None:
        where.append("source = ?")
        bindings.append(address)
    # no sql injection here
    query = f"""SELECT * FROM burns WHERE ({" AND ".join(where)})"""  # nosec B608  # noqa: S608
    cursor.execute(query, tuple(bindings))
    return cursor.fetchall()


def get_burns_by_address(db, address: str):
    """
    Returns the burns of an address
    :param str address: The address to return (e.g. 1HVgrYx3U258KwvBEvuG7R8ss1RN2Z9J1W)
    """
    return get_burns(db, address=address)


def get_all_burns(db, status: str = "valid", offset: int = 0, limit: int = 100):
    """
    Returns the burns
    :param str status: The status of the burns to return (e.g. valid)
    :param int offset: The offset of the burns to return (e.g. 10)
    :param int limit: The limit of the burns to return (e.g. 5)
    """
    try:
        int(offset)
        int(limit)
    except ValueError as e:
        raise exceptions.InvalidArgument("Invalid offset or limit parameter") from e
    cursor = db.cursor()
    query = """
        SELECT * FROM burns
        WHERE status = ?
        ORDER BY tx_index ASC
        LIMIT ? OFFSET ?
    """
    bindings = (status, limit, offset)
    cursor.execute(query, bindings)
    return cursor.fetchall()


######################################
#       BLOCKS AND TRANSACTIONS      #
######################################


def get_blocks(db, last: int = None, limit: int = 10):
    """
    Returns the list of the last ten blocks
    :param int last: The index of the most recent block to return (e.g. 840000)
    :param int limit: The number of blocks to return (e.g. 2)
    """
    cursor = db.cursor()
    bindings = []
    query = """
        SELECT * FROM blocks
    """
    if last is not None:
        query += "WHERE block_index <= ?"
        bindings.append(last)
    query += " ORDER BY block_index DESC LIMIT ?"
    bindings.append(limit)
    cursor.execute(query, tuple(bindings))
    return cursor.fetchall()


def get_block(db, block_index: int):
    """
    Return the information of a block
    :param int block_index: The index of the block to return (e.g. 840464)
    """
    blocks = get_blocks(db, last=block_index, limit=1)
    if blocks:
        return blocks[0]
    return None


def last_db_index(db):
    cursor = db.cursor()
    query = "SELECT name FROM sqlite_master WHERE type='table' AND name='blocks'"
    if len(list(cursor.execute(query))) == 0:
        return 0

    query = "SELECT block_index FROM blocks ORDER BY block_index DESC LIMIT 1"
    blocks = list(cursor.execute(query))
    if len(blocks) == 0:
        return 0

    return blocks[0]["block_index"]


def get_block_by_hash(db, block_hash: str):
    """
    Return the information of a block
    :param int block_hash: The hash of the block to return (e.g. 00000000000000000001158f52eae43aa7fede1bb675736f105ccb545edcf5dd)
    """
    query = """
        SELECT * FROM blocks
        WHERE block_hash = ?
    """
    bindings = (block_hash,)
    cursor = db.cursor()
    cursor.execute(query, bindings)
    return cursor.fetchone()


def get_last_block(db):
    cursor = db.cursor()
    query = "SELECT * FROM blocks ORDER BY block_index DESC LIMIT 1"
    cursor.execute(query)
    block = cursor.fetchone()
    return block


def get_transactions_by_block(db, block_index: int):
    """
    Returns the transactions of a block
    :param int block_index: The index of the block to return (e.g. 840464)
    """
    cursor = db.cursor()
    query = """
        SELECT * FROM transactions
        WHERE block_index = ?
        ORDER BY tx_index ASC
    """
    bindings = (block_index,)
    cursor.execute(query, bindings)
    return cursor.fetchall()


def get_vouts(db, tx_hash):
    cursor = db.cursor()
    query = """
        SELECT txs.source AS source, txs_outs.*
        FROM transaction_outputs txs_outs
        LEFT JOIN transactions txs ON txs.tx_hash = txs_outs.tx_hash
        WHERE txs_outs.tx_hash=:tx_hash
        ORDER BY txs_outs.out_index
    """
    bindings = {"tx_hash": tx_hash}
    cursor.execute(query, bindings)
    return cursor.fetchall()


def get_transactions(db, tx_hash=None, tx_index=None):
    cursor = db.cursor()
    where = []
    bindings = []
    if tx_hash is not None:
        where.append("tx_hash = ?")
        bindings.append(tx_hash)
    if tx_index is not None:
        where.append("tx_index = ?")
        bindings.append(tx_index)
    # no sql injection here
    query = f"""SELECT * FROM transactions WHERE ({" AND ".join(where)})"""  # nosec B608  # noqa: S608
    cursor.execute(query, tuple(bindings))
    return cursor.fetchall()


def get_transaction(db, tx_hash: str):
    """
    Returns the information of a transaction
    :param str tx_hash: The hash of the transaction to return (e.g. 876a6cfbd4aa22ba4fa85c2e1953a1c66649468a43a961ad16ea4d5329e3e4c5)
    """
    transactions = get_transactions(db, tx_hash)
    if transactions:
        return transactions[0]
    return None


def get_transaction_source(db, tx_hash):
    cursor = db.cursor()
    query = """SELECT source FROM transactions WHERE tx_hash = ?"""
    bindings = (tx_hash,)
    cursor.execute(query, tuple(bindings))
    return cursor.fetchone()["source"]


def get_addresses(db, address=None):
    cursor = db.cursor()
    where = []
    bindings = []
    if address is not None:
        where.append("address = ?")
        bindings.append(address)
    # no sql injection here
    query = f"""SELECT * FROM addresses WHERE ({" AND ".join(where)})"""  # nosec B608  # noqa: S608
    cursor.execute(query, tuple(bindings))
    return cursor.fetchall()


def get_expirations(db, block_index: int):
    """
    Returns the expirations of a block
    :param int block_index: The index of the block to return (e.g. 840356)
    """
    cursor = db.cursor()
    queries = [
        """
        SELECT 'order' AS type, order_hash AS object_id FROM order_expirations
        WHERE block_index = ?
        """,
        """
        SELECT 'order_match' AS type, order_match_id AS object_id FROM order_match_expirations
        WHERE block_index = ?
        """,
        """
        SELECT 'bet' AS type, bet_hash AS object_id FROM bet_expirations
        WHERE block_index = ?
        """,
        """
        SELECT 'bet_match' AS type, bet_match_id AS object_id FROM bet_match_expirations
        WHERE block_index = ?
        """,
        """
        SELECT 'rps' AS type, rps_hash AS object_id FROM rps_expirations
        WHERE block_index = ?
        """,
        """
        SELECT 'rps_match' AS type, rps_match_id AS object_id FROM rps_match_expirations
        WHERE block_index = ?
        """,
    ]
    query = " UNION ALL ".join(queries)
    bindings = (block_index,) * 6
    cursor.execute(query, bindings)
    return cursor.fetchall()


def get_cancels(db, block_index: int):
    """
    Returns the cancels of a block
    :param int block_index: The index of the block to return (e.g. 839746)
    """
    cursor = db.cursor()
    query = """
        SELECT * FROM cancels
        WHERE block_index = ?
    """
    bindings = (block_index,)
    cursor.execute(query, bindings)
    return cursor.fetchall()


def get_destructions(db, block_index: int):
    """
    Returns the destructions of a block
    :param int block_index: The index of the block to return (e.g. 839988)
    """
    cursor = db.cursor()
    query = """
        SELECT * FROM destructions
        WHERE block_index = ?
    """
    bindings = (block_index,)
    cursor.execute(query, bindings)
    return cursor.fetchall()


###############################
#       UTIL FUNCTIONS        #
###############################


def insert_record(db, table_name, record, event):
    cursor = db.cursor()
    fields_name = ", ".join(record.keys())
    fields_values = ", ".join([f":{key}" for key in record.keys()])
    # no sql injection here
    query = f"""INSERT INTO {table_name} ({fields_name}) VALUES ({fields_values})"""  # nosec B608  # noqa: S608
    cursor.execute(query, record)
    cursor.close()
    # Add event to journal
    add_to_journal(db, util.CURRENT_BLOCK_INDEX, "insert", table_name, event, record)


# This function allows you to update a record using an INSERT.
# The `block_index` and `rowid` fields allow you to
# order updates and retrieve the row with the current data.
def insert_update(db, table_name, id_name, id_value, update_data, event, event_info={}):  # noqa: B006
    cursor = db.cursor()
    # select records to update
    select_query = f"""
        SELECT *, rowid
        FROM {table_name}
        WHERE {id_name} = ?
        ORDER BY rowid DESC
        LIMIT 1
    """  # nosec B608  # noqa: S608
    bindings = (id_value,)
    need_update_record = cursor.execute(select_query, bindings).fetchone()

    # update record
    new_record = need_update_record.copy()
    # updade needed fields
    for key, value in update_data.items():
        new_record[key] = value
    # new block_index and tx_index
    new_record["block_index"] = util.CURRENT_BLOCK_INDEX
    # let's keep the original tx_index so we can preserve order
    # with the old queries (ordered by default by old primary key)
    # TODO: restore with protocol change and checkpoints update
    # if 'tx_index' in new_record:
    #    new_record['tx_index'] = tx_index
    # insert new record
    if "rowid" in new_record:
        del new_record["rowid"]
    fields_name = ", ".join(new_record.keys())
    fields_values = ", ".join([f":{key}" for key in new_record.keys()])
    # no sql injection here
    insert_query = f"""INSERT INTO {table_name} ({fields_name}) VALUES ({fields_values})"""  # nosec B608  # noqa: S608
    cursor.execute(insert_query, new_record)
    cursor.close()
    # Add event to journal
    event_paylod = update_data | {id_name: id_value} | event_info
    if "rowid" in event_paylod:
        del event_paylod["rowid"]
    add_to_journal(
        db, util.CURRENT_BLOCK_INDEX, "update", table_name, event, update_data | event_paylod
    )


MUTABLE_FIELDS = {
    "balances": ["quantity"],
    "orders": [
        "give_remaining",
        "get_remaining",
        "fee_required_remaining",
        "fee_provided_remaining",
        "status",
    ],
    "order_matches": ["status"],
    "bets": ["wager_remaining", "counterwager_remaining", "status"],
    "bet_matches": ["status"],
    "rps": ["status"],
    "rps_matches": ["status"],
    "dispensers": ["give_remaining", "status", "last_status_tx_hash"],
}
ID_FIELDS = {
    "balances": ["address", "asset"],
    "orders": ["tx_hash"],
    "order_matches": ["id"],
    "bets": ["tx_hash"],
    "bet_matches": ["id"],
    "rps": ["tx_hash"],
    "rps_matches": ["id"],
    "dispensers": ["tx_hash"],
}


def _gen_where_and_binding(key, value):
    where = ""
    bindings = []
    _key = key.replace("_in", "")
    if key.endswith("_in"):
        assert isinstance(value, list)
        where = f'{_key} IN ({",".join(["?" for e in range(0, len(value))])})'
        bindings += value
    else:
        where = f"{_key} = ?"
        bindings.append(value)
    return where, bindings


def select_last_revision(db, table_name, where_data):
    cursor = db.cursor()
    if table_name not in MUTABLE_FIELDS.keys():
        raise exceptions.UnknownTable(f"Unknown table: {table_name}")
    query = """
        PRAGMA table_info(?)
    """
    bindings = (table_name,)
    columns = [column["name"] for column in cursor.execute(query, bindings)]
    for key in where_data.keys():
        _key = key.replace("_in", "")
        if _key not in columns:
            raise exceptions.UnknownField(f"Unknown field: {key}")

    where_immutable = []
    where_mutable = []
    bindings = []
    for key, value in where_data.items():
        if key.replace("_in", "") not in MUTABLE_FIELDS[table_name]:
            _where, _bindings = _gen_where_and_binding(key, value)
            where_immutable.append(_where)
            bindings += _bindings
    for key, value in where_data.items():
        if key.replace("_in", "") in MUTABLE_FIELDS[table_name]:
            _where, _bindings = _gen_where_and_binding(key, value)
            where_mutable.append(_where)
            bindings += _bindings
    # no sql injection here
    query = f"""SELECT * FROM (
        SELECT *, MAX(rowid)
        FROM {table_name}
        WHERE ({" AND ".join(where_immutable)})
        GROUP BY {", ".join(ID_FIELDS[table_name])}
    ) WHERE ({" AND ".join(where_mutable)})
    """  # nosec B608  # noqa: S608
    cursor.execute(query, tuple(bindings))
    return cursor.fetchall()


#####################
#     DISPENSERS    #
#####################

### SELECTS ###


def get_dispenser_info(db, tx_hash=None, tx_index=None):
    cursor = db.cursor()
    where = []
    bindings = []
    if tx_hash is not None:
        where.append("tx_hash = ?")
        bindings.append(tx_hash)
    if tx_index is not None:
        where.append("tx_index = ?")
        bindings.append(tx_index)
    # no sql injection here
    query = f"""
        SELECT *
        FROM dispensers
        WHERE ({" AND ".join(where)})
        ORDER BY rowid DESC LIMIT 1
    """  # nosec B608  # noqa: S608
    cursor.execute(query, tuple(bindings))
    return cursor.fetchall()


def get_dispensers_info(db, tx_hash_list):
    cursor = db.cursor()
    query = """
        SELECT *, MAX(rowid) AS rowid FROM dispensers
        WHERE tx_hash IN ({})
        GROUP BY tx_hash
    """.format(",".join(["?" for e in range(0, len(tx_hash_list))]))  # nosec B608  # noqa: S608
    cursor.execute(query, tx_hash_list)
    dispensers = cursor.fetchall()
    result = {}
    for dispenser in dispensers:
        del dispenser["rowid"]
        tx_hash = dispenser["tx_hash"]
        del dispenser["tx_hash"]
        del dispenser["asset"]
        result[tx_hash] = dispenser
    return result


def get_dispenser_info_by_hash(db, dispenser_hash: str):
    """
    Returns the dispenser information by tx_hash
    :param str dispenser_hash: The hash of the dispenser to return (e.g. 753787004d6e93e71f6e0aa1e0932cc74457d12276d53856424b2e4088cc542a)
    """
    return get_dispenser_info(db, tx_hash=dispenser_hash)


def get_refilling_count(db, dispenser_tx_hash):
    cursor = db.cursor()
    query = """
        SELECT count(*) cnt
        FROM dispenser_refills
        WHERE dispenser_tx_hash = ?
    """
    bindings = (dispenser_tx_hash,)
    cursor.execute(query, bindings)
    return cursor.fetchall()[0]["cnt"]


def get_pending_dispensers_old(db, status, delay, block_index):
    cursor = db.cursor()
    query = """
        SELECT * FROM
            (SELECT d.*, t.source AS tx_source, t.block_index AS tx_block_index, MAX(d.rowid) AS rowid
            FROM dispensers AS d
            LEFT JOIN transactions t ON t.tx_hash = d.last_status_tx_hash
            WHERE :block_index = t.block_index + :delay
            GROUP BY d.source, d.asset)
        WHERE status = :status
        AND last_status_tx_hash IS NOT NULL
        ORDER BY tx_index
    """
    bindings = {"status": status, "delay": delay, "block_index": block_index}
    cursor.execute(query, bindings)
    return cursor.fetchall()


def get_pending_dispensers(db, delay, block_index):
    status_closed = 10
    status_closing = 11

    cursor = db.cursor()
    # we assume here that the status_closed and status_closing are the last statuses
    # and that dispenser with status_closing can be closed before the delay if it's empty
    query = """
        SELECT d.*, t.source AS tx_source, t.block_index AS tx_block_index, MAX(d.rowid) AS rowid
        FROM dispensers AS d
        LEFT JOIN transactions t ON t.tx_hash = d.last_status_tx_hash
        WHERE :block_index = t.block_index + :delay
        AND status IN (:status_closed, :status_closing)
        GROUP BY d.source, d.asset
        ORDER BY tx_index
    """
    bindings = {
        "status_closed": status_closed,
        "status_closing": status_closing,
        "delay": delay,
        "block_index": block_index,
    }
    cursor.execute(query, bindings)
    return [dispenser for dispenser in cursor.fetchall() if dispenser["status"] == status_closing]


def get_dispensers_count(db, source, status, origin):
    cursor = db.cursor()
    query = """
        SELECT count(*) cnt FROM (
            SELECT *, MAX(rowid)
            FROM dispensers
            WHERE source = ? AND origin = ?
            GROUP BY tx_hash
        ) WHERE status = ?
        ORDER BY tx_index
    """
    bindings = (source, origin, status)
    cursor.execute(query, bindings)
    return cursor.fetchall()[0]["cnt"]


def get_dispenses_count(db, dispenser_tx_hash, from_block_index):
    cursor = db.cursor()
    query = """
        SELECT COUNT(*) AS dispenses_count
        FROM dispenses
        WHERE dispenser_tx_hash = :dispenser_tx_hash
        AND block_index >= :block_index
    """
    bindings = {"dispenser_tx_hash": dispenser_tx_hash, "block_index": from_block_index}
    cursor.execute(query, bindings)
    dispenses_count_result = cursor.fetchall()[0]
    return dispenses_count_result["dispenses_count"]


def get_last_refills_block_index(db, dispenser_tx_hash):
    cursor = db.cursor()
    query = """
        SELECT MAX(block_index) AS max_block_index
        FROM dispenser_refills
        WHERE dispenser_tx_hash = :dispenser_tx_hash
    """
    bindings = {"dispenser_tx_hash": dispenser_tx_hash}
    cursor.execute(query, bindings)
    return cursor.fetchall()


def get_dispenser(db, tx_hash):
    cursor = db.cursor()
    query = """
        SELECT * FROM dispensers
        WHERE tx_hash = ?
        ORDER BY rowid DESC LIMIT 1
    """
    bindings = (tx_hash,)
    cursor.execute(query, bindings)
    return cursor.fetchall()


def get_dispensers(
    db,
    status_in=None,
    source_in=None,
    address=None,
    asset=None,
    origin=None,
    status=None,
    tx_hash=None,
    order_by=None,
    group_by=None,
):
    cursor = db.cursor()
    bindings = []
    # where for immutable fields
    first_where = []
    if address is not None:
        first_where.append("source = ?")
        bindings.append(address)
    if source_in is not None:
        first_where.append(f"source IN ({','.join(['?' for e in range(0, len(source_in))])})")
        bindings += source_in
    if asset is not None:
        first_where.append("asset = ?")
        bindings.append(asset)
    if origin is not None:
        first_where.append("origin = ?")
        bindings.append(origin)
    # where for mutable fields
    second_where = []
    if status is not None:
        second_where.append("status = ?")
        bindings.append(status)
    if status_in is not None:
        second_where.append(f"status IN ({','.join(['?' for e in range(0, len(status_in))])})")
        bindings += status_in
    # build query
    first_where_str = " AND ".join(first_where)
    if first_where_str != "":
        first_where_str = f"WHERE ({first_where_str})"
    second_where_str = " AND ".join(second_where)
    if second_where_str != "":
        second_where_str = f"WHERE ({second_where_str})"
    order_clause = f"ORDER BY {order_by}" if order_by is not None else "ORDER BY tx_index"
    group_clause = f"GROUP BY {group_by}" if group_by is not None else "GROUP BY asset, source"
    # no sql injection here
    query = f"""
        SELECT *, rowid FROM (
            SELECT *, MAX(rowid) as rowid
            FROM dispensers
            {first_where_str}
            {group_clause}
        ) {second_where_str}
        {order_clause}
    """  # nosec B608  # noqa: S608
    cursor.execute(query, tuple(bindings))
    return cursor.fetchall()


def get_dispensers_by_address(db, address: str, status: int = 0):
    """
    Returns the dispensers of an address
    :param str address: The address to return (e.g. bc1qlzkcy8c5fa6y6xvd8zn4axnvmhndfhku3hmdpz)
    """
    return get_dispensers(db, address=address, status=status)


def get_dispensers_by_asset(db, asset: str, status: int = 0):
    """
    Returns the dispensers of an asset
    :param str asset: The asset to return (e.g. ERYKAHPEPU)
    """
    return get_dispensers(db, asset=asset, status=status)


def get_dispensers_by_address_and_asset(db, address: str, asset: str, status: int = 0):
    """
    Returns the dispensers of an address and an asset
    :param str address: The address to return (e.g. bc1qlzkcy8c5fa6y6xvd8zn4axnvmhndfhku3hmdpz)
    :param str asset: The asset to return (e.g. ERYKAHPEPU)
    """
    return get_dispensers(db, address=address, asset=asset, status=status)


def get_dispenses(db, dispenser_tx_hash=None, block_index=None):
    cursor = db.cursor()
    where = []
    bindings = []
    if dispenser_tx_hash is not None:
        where.append("dispenser_tx_hash = ?")
        bindings.append(dispenser_tx_hash)
    if block_index is not None:
        where.append("block_index = ?")
        bindings.append(block_index)
    # no sql injection here
    query = f"""SELECT * FROM dispenses WHERE ({" AND ".join(where)})"""  # nosec B608  # noqa: S608
    cursor.execute(query, tuple(bindings))
    return cursor.fetchall()


def get_dispenses_by_block(db, block_index: int):
    """
    Returns the dispenses of a block
    :param int block_index: The index of the block to return (e.g. 840322)
    """
    return get_dispenses(db, block_index=block_index)


def get_dispenses_by_dispenser(db, dispenser_hash: str):
    """
    Returns the dispenses of a dispenser
    :param str dispenser_hash: The hash of the dispenser to return (e.g. 753787004d6e93e71f6e0aa1e0932cc74457d12276d53856424b2e4088cc542a)
    """
    return get_dispenses(db, dispenser_tx_hash=dispenser_hash)


### UPDATES ###


def update_dispenser(db, rowid, update_data, dispenser_info):
    insert_update(db, "dispensers", "rowid", rowid, update_data, "DISPENSER_UPDATE", dispenser_info)


#####################
#       BETS        #
#####################

### SELECTS ###


def get_pending_bet_matches(db, feed_address, order_by=None):
    cursor = db.cursor()
    query = """
        SELECT * FROM (
            SELECT *, MAX(rowid) as rowid
            FROM bet_matches
            WHERE feed_address = ?
            GROUP BY id
        ) WHERE status = ?
    """
    if order_by is not None:
        query += f""" ORDER BY {order_by}"""
    else:
        query += f""" ORDER BY rowid"""  # noqa: F541
    bindings = (feed_address, "pending")
    cursor.execute(query, bindings)
    return cursor.fetchall()


def get_bet_matches_to_expire(db, block_time):
    cursor = db.cursor()
    query = """
        SELECT * FROM (
            SELECT *, MAX(rowid) as rowid
            FROM bet_matches
            WHERE deadline < ? AND deadline > ?
            GROUP BY id
        ) WHERE status = ?
        ORDER BY rowid
    """
    bindings = (
        block_time - config.TWO_WEEKS,
        block_time
        - 2 * config.TWO_WEEKS,  # optimize query: assuming before that we have already expired
        "pending",
    )
    cursor.execute(query, bindings)
    return cursor.fetchall()


def get_bet(db, bet_hash: str):
    """
    Returns the information of a bet
    :param str bet_hash: The hash of the transaction that created the bet (e.g. 5d097b4729cb74d927b4458d365beb811a26fcee7f8712f049ecbe780eb496ed)
    """
    cursor = db.cursor()
    query = """
        SELECT * FROM bets
        WHERE tx_hash = ?
        ORDER BY rowid DESC LIMIT 1
    """
    bindings = (bet_hash,)
    cursor.execute(query, bindings)
    return cursor.fetchall()


def get_bets_to_expire(db, block_index):
    cursor = db.cursor()
    query = """
        SELECT * FROM (
            SELECT *, MAX(rowid)
            FROM bets
            WHERE expire_index = ? - 1
            GROUP BY tx_hash
        ) WHERE status = ?
        ORDER BY tx_index, tx_hash
    """
    bindings = (block_index, "open")
    cursor.execute(query, bindings)
    return cursor.fetchall()


def get_matching_bets(db, feed_address, bet_type):
    cursor = db.cursor()
    query = """
        SELECT * FROM (
            SELECT *, MAX(rowid)
            FROM bets
            WHERE (feed_address = ? AND bet_type = ?)
            GROUP BY tx_hash
        ) WHERE status = ?
        ORDER BY tx_index, tx_hash
    """
    bindings = (feed_address, bet_type, "open")
    cursor.execute(query, bindings)
    return cursor.fetchall()


def get_bet_by_feed(db, address: str, status: str = "open"):
    """
    Returns the bets of a feed
    :param str address: The address of the feed (e.g. 1QKEpuxEmdp428KEBSDZAKL46noSXWJBkk)
    :param str status: The status of the bet (e.g. filled)
    """
    cursor = db.cursor()
    query = """
        SELECT * FROM (
            SELECT *, MAX(rowid)
            FROM bets
            WHERE feed_address = ?
            GROUP BY tx_hash
        ) WHERE status = ?
        ORDER BY tx_index, tx_hash
    """
    bindings = (address, status)
    cursor.execute(query, bindings)
    return cursor.fetchall()


def get_bet_matches_by_bet(db, bet_hash: str, status: str = "pending"):
    """
    Returns the bet matches of a bet
    :param str bet_hash: The hash of the transaction that created the bet (e.g. 5d097b4729cb74d927b4458d365beb811a26fcee7f8712f049ecbe780eb496ed)
    :param str status: The status of the bet matches (e.g. expired)
    """
    cursor = db.cursor()
    query = """
        SELECT * FROM (
            SELECT *, MAX(rowid)
            FROM bet_matches
            WHERE (tx0_hash = ? OR tx1_hash = ?)
            GROUP BY id
        ) WHERE status = ?
    """
    bindings = (bet_hash, bet_hash, status)
    cursor.execute(query, bindings)
    return cursor.fetchall()


def get_resolutions_by_bet(db, bet_hash: str):
    """
    Returns the resolutions of a bet
    :param str bet_hash: The hash of the transaction that created the bet (e.g. 36bbbb7dbd85054dac140a8ad8204eda2ee859545528bd2a9da69ad77c277ace)
    """
    cursor = db.cursor()
    query = """
        SELECT *
        FROM bet_match_resolutions
        WHERE bet_match_id LIKE ?
    """
    bindings = (f"%{bet_hash}%",)
    cursor.execute(query, bindings)
    return cursor.fetchall()


### UPDATES ###


def update_bet(db, tx_hash, update_data):
    insert_update(db, "bets", "tx_hash", tx_hash, update_data, "BET_UPDATE")


def update_bet_match_status(db, id, status):
    update_data = {"status": status}
    insert_update(db, "bet_matches", "id", id, update_data, "BET_MATCH_UPDATE")


#####################
#       ORDERS      #
#####################

### SELECTS ###


def get_pending_order_matches(db, tx0_hash, tx1_hash):
    cursor = db.cursor()
    query = """
        SELECT * FROM (
            SELECT *, MAX(rowid) as rowid FROM order_matches
            WHERE (
                tx0_hash in (:tx0_hash, :tx1_hash) OR
                tx1_hash in (:tx0_hash, :tx1_hash)
            )
            GROUP BY id
        ) WHERE status = :status
        ORDER BY rowid
    """
    bindings = {"status": "pending", "tx0_hash": tx0_hash, "tx1_hash": tx1_hash}
    cursor.execute(query, bindings)
    return cursor.fetchall()


def get_pending_btc_order_matches(db, address):
    cursor = db.cursor()
    query = """
        SELECT * FROM (
            SELECT *, MAX(rowid) AS rowid
            FROM order_matches
            WHERE (tx0_address = ? AND forward_asset = ?) OR (tx1_address = ? AND backward_asset = ?)
        ) WHERE status = ?
        ORDER BY rowid
    """
    bindings = (address, config.BTC, address, config.BTC, "pending")
    cursor.execute(query, bindings)
    return cursor.fetchall()


def get_order_match(db, id):
    cursor = db.cursor()
    query = """
        SELECT *, rowid
        FROM order_matches
        WHERE id = ?
        ORDER BY rowid DESC LIMIT 1"""
    bindings = (id,)
    cursor.execute(query, bindings)
    return cursor.fetchall()


def get_order_matches_to_expire(db, block_index):
    cursor = db.cursor()
    query = """SELECT * FROM (
        SELECT *, MAX(rowid) AS rowid
        FROM order_matches
        WHERE match_expire_index = ? - 1
        GROUP BY id
    ) WHERE status = ?
    ORDER BY rowid
    """
    bindings = (block_index, "pending")
    cursor.execute(query, bindings)
    return cursor.fetchall()


def get_order(db, order_hash: str):
    """
    Returns the information of an order
    :param str order_hash: The hash of the transaction that created the order (e.g. 23f68fdf934e81144cca31ce8ef69062d553c521321a039166e7ba99aede0776)
    """
    cursor = db.cursor()
    query = """
        SELECT * FROM orders
        WHERE tx_hash = ?
        ORDER BY rowid DESC LIMIT 1
    """
    bindings = (order_hash,)
    cursor.execute(query, bindings)
    return cursor.fetchall()


def get_order_first_block_index(cursor, tx_hash):
    query = """
        SELECT block_index FROM orders
        WHERE tx_hash = ?
        ORDER BY rowid ASC LIMIT 1
    """
    bindings = (tx_hash,)
    cursor.execute(query, bindings)
    return cursor.fetchone()["block_index"]


def get_orders_to_expire(db, block_index):
    cursor = db.cursor()
    query = """
        SELECT * FROM (
            SELECT *, MAX(rowid)
            FROM orders
            WHERE expire_index = ? - 1
            GROUP BY tx_hash
        ) WHERE status = ?
        ORDER BY tx_index, tx_hash
    """
    bindings = (block_index, "open")
    cursor.execute(query, bindings)
    return cursor.fetchall()


def get_open_btc_orders(db, address):
    cursor = db.cursor()
    query = """
        SELECT * FROM (
            SELECT *, MAX(rowid)
            FROM orders
            WHERE (source = ? AND give_asset = ?)
            GROUP BY tx_hash
        ) WHERE status = ?
        ORDER BY tx_index, tx_hash
    """
    bindings = (address, config.BTC, "open")
    cursor.execute(query, bindings)
    return cursor.fetchall()


def get_matching_orders(db, tx_hash, give_asset, get_asset):
    cursor = db.cursor()
    query = """
        SELECT * FROM (
            SELECT *, MAX(rowid)
            FROM orders
            WHERE (tx_hash != ? AND give_asset = ? AND get_asset = ?)
            GROUP BY tx_hash
        ) WHERE status = ?
        ORDER BY tx_index, tx_hash
    """
    bindings = (tx_hash, get_asset, give_asset, "open")
    cursor.execute(query, bindings)
    return cursor.fetchall()


def get_orders_by_asset(db, asset: str, status: str = "open"):
    """
    Returns the orders of an asset
    :param str asset: The asset to return (e.g. NEEDPEPE)
    :param str status: The status of the orders to return (e.g. filled)
    """
    cursor = db.cursor()
    query = """
        SELECT * FROM (
            SELECT *, MAX(rowid)
            FROM orders
            WHERE (give_asset = ? OR get_asset = ?)
            GROUP BY tx_hash
        ) WHERE status = ?
    """
    bindings = (asset, asset, status)
    cursor.execute(query, bindings)
    return cursor.fetchall()


def get_orders_by_two_assets(db, asset1: str, asset2: str, status: str = "open"):
    """
    Returns the orders to exchange two assets
    :param str asset1: The first asset to return (e.g. NEEDPEPE)
    :param str asset2: The second asset to return (e.g. XCP)
    :param str status: The status of the orders to return (e.g. filled)
    """
    cursor = db.cursor()
    query = """
        SELECT * FROM (
            SELECT *, MAX(rowid)
            FROM orders
            WHERE (give_asset = ? AND get_asset = ?) OR (give_asset = ? AND get_asset = ?)
            GROUP BY tx_hash
        ) WHERE status = ?
    """
    bindings = (asset1, asset2, asset2, asset1, status)
    cursor.execute(query, bindings)
    orders = cursor.fetchall()
    for order in orders:
        order["market_pair"] = f"{asset1}/{asset2}"
        if order["give_asset"] == asset1:
            order["market_dir"] = "SELL"
        else:
            order["market_dir"] = "BUY"
    return orders


def get_order_matches_by_order(db, order_hash: str, status: str = "pending"):
    """
    Returns the order matches of an order
    :param str order_hash: The hash of the transaction that created the order (e.g. 5461e6f99a37a7167428b4a720a52052cd9afed43905f818f5d7d4f56abd0947)
    :param str status: The status of the order matches to return (e.g. completed)
    """
    cursor = db.cursor()
    query = """
        SELECT * FROM (
            SELECT *, MAX(rowid)
            FROM order_matches
            WHERE (tx0_hash = ? OR tx1_hash = ?)
            GROUP BY id
        ) WHERE status = ?
    """
    bindings = (order_hash, order_hash, status)
    cursor.execute(query, bindings)
    return cursor.fetchall()


def get_btcpays_by_order(db, order_hash: str):
    """
    Returns the BTC pays of an order
    :param str order_hash: The hash of the transaction that created the order (e.g. 299b5b648f54eacb839f3487232d49aea373cdd681b706d4cc0b5e0b03688db4)
    """
    cursor = db.cursor()
    query = """
        SELECT *
        FROM btcpays
        WHERE order_match_id LIKE ?
    """
    bindings = (f"%{order_hash}%",)
    cursor.execute(query, bindings)
    return cursor.fetchall()


### UPDATES ###


def update_order(db, tx_hash, update_data):
    insert_update(db, "orders", "tx_hash", tx_hash, update_data, "ORDER_UPDATE")


def mark_order_as_filled(db, tx0_hash, tx1_hash, source=None):
    select_bindings = {"tx0_hash": tx0_hash, "tx1_hash": tx1_hash}

    where_source = ""
    if source is not None:
        where_source = f" AND source = :source"  # noqa: F541
        select_bindings["source"] = source

    # no sql injection here
    select_query = f"""
        SELECT * FROM (
            SELECT *, MAX(rowid) as rowid
            FROM orders
            WHERE
                tx_hash in (:tx0_hash, :tx1_hash)
                {where_source}
            GROUP BY tx_hash
        ) WHERE give_remaining = 0 OR get_remaining = 0
    """  # nosec B608  # noqa: S608

    cursor = db.cursor()
    cursor.execute(select_query, select_bindings)
    for order in cursor:
        update_data = {"status": "filled"}
        insert_update(
            db,
            "orders",
            "rowid",
            order["rowid"],
            update_data,
            "ORDER_FILLED",
            {"tx_hash": order["tx_hash"]},
        )


def update_order_match_status(db, id, status):
    update_data = {"status": status}
    # add `order_match_id` for backward compatibility
    insert_update(
        db, "order_matches", "id", id, update_data, "ORDER_MATCH_UPDATE", {"order_match_id": id}
    )


#####################
#       RPS         #
#####################

### SELECTS ###


def get_matched_not_expired_rps(db, tx0_hash, tx1_hash, expire_index):
    cursor = db.cursor()
    query = """
        SELECT * FROM (
            SELECT *, MAX(rowid) as rowid
            FROM rps
            WHERE tx_hash IN (?, ?)
            AND expire_index >= ?
            GROUP BY tx_hash
        ) WHERE status = ?
    """
    bindings = (tx0_hash, tx1_hash, expire_index, "matched")
    cursor.execute(query, bindings)
    return cursor.fetchall()


def get_already_matched_rps(db, tx_hash):
    cursor = db.cursor()
    query = """
        SELECT *, MAX(rowid) AS rowid
        FROM rps_matches
        WHERE tx0_hash = ? OR tx1_hash = ?
        GROUP BY id
        ORDER BY rowid
    """
    bindings = (tx_hash, tx_hash)
    cursor.execute(query, bindings)
    return cursor.fetchall()


def get_matching_rps(db, possible_moves, wager, source, already_matched_tx_hashes):
    cursor = db.cursor()
    bindings = (possible_moves, wager, source)
    already_matched_cond = ""
    if already_matched_tx_hashes:
        place_holders = ",".join(["?" for e in range(0, len(already_matched_tx_hashes))])
        already_matched_cond = f"""AND tx_hash NOT IN ({place_holders})"""
        bindings += tuple(already_matched_tx_hashes)
    bindings += ("open",)
    # no sql injection here
    query = f"""
        SELECT * FROM (
            SELECT *, MAX(rowid) FROM rps
            WHERE (possible_moves = ? AND wager = ? AND source != ? {already_matched_cond})
            GROUP BY tx_hash
        ) WHERE status = ?
        ORDER BY tx_index LIMIT 1
    """  # nosec B608  # noqa: S608
    cursor.execute(query, bindings)
    return cursor.fetchall()


def get_rps_to_expire(db, block_index):
    cursor = db.cursor()
    query = """
        SELECT * FROM (
            SELECT *, MAX(rowid)
            FROM rps
            WHERE expire_index = ? - 1
            GROUP BY tx_hash
        ) WHERE status = ?
        ORDER BY tx_index, tx_hash
    """
    bindings = (block_index, "open")
    cursor.execute(query, bindings)
    return cursor.fetchall()


def get_rps(db, tx_hash):
    cursor = db.cursor()
    query = """
        SELECT * FROM rps
        WHERE tx_hash = ?
        ORDER BY rowid DESC
        LIMIT 1
    """
    bindings = (tx_hash,)
    cursor.execute(query, bindings)
    return cursor.fetchall()


def get_rps_matches_to_expire(db, block_index):
    cursor = db.cursor()
    query = """
        SELECT * FROM (
            SELECT *, MAX(rowid) AS rowid
            FROM rps_matches
            WHERE match_expire_index < ?
            GROUP BY id
        ) WHERE status IN (?, ? , ?)
        ORDER BY rowid
    """
    bindings = (block_index, "pending", "pending and resolved", "resolved and pending")
    cursor.execute(query, bindings)
    return cursor.fetchall()


def get_rps_match(db, id):
    cursor = db.cursor()
    query = """
        SELECT * FROM rps_matches
        WHERE id = ?
        ORDER BY rowid
        DESC LIMIT 1
    """
    bindings = (id,)
    cursor.execute(query, bindings)
    return cursor.fetchall()


def get_rpsresolves(db, source=None, status=None, rps_match_id=None):
    cursor = db.cursor()
    where = []
    bindings = []
    if source is not None:
        where.append("source = ?")
        bindings.append(source)
    if status is not None:
        where.append("status = ?")
        bindings.append(status)
    if rps_match_id is not None:
        where.append("rps_match_id = ?")
        bindings.append(rps_match_id)
    # no sql injection here
    query = f"""SELECT * FROM rpsresolves WHERE ({" AND ".join(where)})"""  # nosec B608  # noqa: S608
    cursor.execute(query, tuple(bindings))
    return cursor.fetchall()


### UPDATES ###


def update_rps_match_status(db, id, status):
    update_data = {"status": status}
    insert_update(db, "rps_matches", "id", id, update_data, "RPS_MATCH_UPDATE")


def update_rps_status(db, tx_hash, status):
    update_data = {"status": status}
    insert_update(db, "rps", "tx_hash", tx_hash, update_data, "RPS_UPDATE")


#####################
#     SUPPLIES      #
#####################


# Ugly way to get holders but we want to preserve the order with the old query
# to not break checkpoints
def _get_holders(
    cursor, id_fields, hold_fields_1, hold_fields_2=None, exclude_empty_holders=False, table=None
):
    save_records = {}
    for record in cursor:
        id = " ".join([str(record[field]) for field in id_fields])
        if id not in save_records:
            save_records[id] = record
            continue
        if save_records[id]["rowid"] < record["rowid"]:
            save_records[id] = record
            continue
    holders = []
    for holder in save_records.values():
        if holder[hold_fields_1["address_quantity"]] > 0 or (
            exclude_empty_holders == False and holder[hold_fields_1["address_quantity"]] == 0  # noqa: E712
        ):
            holders.append(
                {
                    "address": holder[hold_fields_1["address"]],
                    "address_quantity": holder[hold_fields_1["address_quantity"]],
                    "escrow": holder[hold_fields_1["escrow"]]
                    if "escrow" in hold_fields_1
                    else None,
                    #'table': table # for debugging purposes
                }
            )
        if hold_fields_2 is not None:
            if holder[hold_fields_2["address_quantity"]] > 0 or (
                exclude_empty_holders == False and holder[hold_fields_2["address_quantity"]] == 0  # noqa: E712
            ):
                holders.append(
                    {
                        "address": holder[hold_fields_2["address"]],
                        "address_quantity": holder[hold_fields_2["address_quantity"]],
                        "escrow": holder[hold_fields_2["escrow"]]
                        if "escrow" in hold_fields_2
                        else None,
                        #'table': table # for debugging purposes
                    }
                )
    return holders


def holders(db, asset, exclude_empty_holders=False):
    """Return holders of the asset."""
    holders = []
    cursor = db.cursor()

    # Balances

    query = """
        SELECT *, rowid
        FROM balances
        WHERE asset = ?
    """
    bindings = (asset,)
    cursor.execute(query, bindings)
    holders += _get_holders(
        cursor,
        ["asset", "address"],
        {"address": "address", "address_quantity": "quantity"},
        exclude_empty_holders=exclude_empty_holders,
        table="balances",
    )

    # Funds escrowed in orders. (Protocol change.)
    query = """
        SELECT * FROM (
            SELECT *, MAX(rowid)
            FROM orders
            WHERE give_asset = ?
            GROUP BY tx_hash
        ) WHERE status = ?
        ORDER BY tx_index
    """
    bindings = (asset, "open")
    cursor.execute(query, bindings)
    holders += _get_holders(
        cursor,
        ["tx_hash"],
        {"address": "source", "address_quantity": "give_remaining", "escrow": "tx_hash"},
        # exclude_empty_holders=exclude_empty_holders,
        table="orders",
    )

    # Funds escrowed in pending order matches. (Protocol change.)
    query = """
        SELECT * FROM (
            SELECT *, MAX(rowid)
            FROM order_matches
            WHERE forward_asset = ?
            GROUP BY id
        ) WHERE status = ?
    """
    bindings = (asset, "pending")
    cursor.execute(query, bindings)
    holders += _get_holders(
        cursor,
        ["id"],
        {"address": "tx0_address", "address_quantity": "forward_quantity", "escrow": "id"},
        # exclude_empty_holders=exclude_empty_holders,
        table="order_matches1",
    )

    query = """
        SELECT * FROM (
            SELECT *, MAX(rowid) AS rowid
            FROM order_matches
            WHERE backward_asset = ?
        ) WHERE status = ?
        ORDER BY rowid
    """
    bindings = (asset, "pending")
    cursor.execute(query, bindings)
    holders += _get_holders(
        cursor,
        ["id"],
        {"address": "tx1_address", "address_quantity": "backward_quantity", "escrow": "id"},
        # exclude_empty_holders=exclude_empty_holders,
        table="order_matches2",
    )

    # Bets and RPS (and bet/rps matches) only escrow XCP.
    if asset == config.XCP:
        query = """
            SELECT * FROM (
                SELECT *, MAX(rowid)
                FROM bets
                GROUP BY tx_hash
            ) WHERE status = ?
            ORDER BY tx_index
        """
        bindings = ("open",)
        cursor.execute(query, bindings)
        holders += _get_holders(
            cursor,
            ["tx_hash"],
            {"address": "source", "address_quantity": "wager_remaining", "escrow": "tx_hash"},
            # exclude_empty_holders=exclude_empty_holders,
            table="bets",
        )

        query = """
            SELECT * FROM (
                SELECT *, MAX(rowid)
                FROM bet_matches
                GROUP BY id
            ) WHERE status = ?
        """
        bindings = ("pending",)
        cursor.execute(query, bindings)
        holders += _get_holders(
            cursor,
            ["id"],
            {"address": "tx0_address", "address_quantity": "forward_quantity", "escrow": "id"},
            {"address": "tx1_address", "address_quantity": "backward_quantity", "escrow": "id"},
            # exclude_empty_holders=exclude_empty_holders,
            table="bet_matches",
        )

        query = """
            SELECT * FROM (
                SELECT *, MAX(rowid)
                FROM rps
                GROUP BY tx_hash
            ) WHERE status = ?
            ORDER BY tx_index
        """
        bindings = ("open",)
        cursor.execute(query, bindings)
        holders += _get_holders(
            cursor,
            ["tx_hash"],
            {"address": "source", "address_quantity": "wager", "escrow": "tx_hash"},
            # exclude_empty_holders=exclude_empty_holders,
            table="rps",
        )

        query = """
            SELECT * FROM (
                SELECT *, MAX(rowid)
                FROM rps_matches
                GROUP BY id
            ) WHERE status IN (?, ?, ?)
        """
        bindings = ("pending", "pending and resolved", "resolved and pending")
        cursor.execute(query, bindings)
        holders += _get_holders(
            cursor,
            ["id"],
            {"address": "tx0_address", "address_quantity": "wager", "escrow": "id"},
            {"address": "tx1_address", "address_quantity": "wager", "escrow": "id"},
            # exclude_empty_holders=exclude_empty_holders,
            table="rps_matches",
        )

    if util.enabled("dispensers_in_holders"):
        # Funds escrowed in dispensers.
        query = """
            SELECT * FROM (
                SELECT *, MAX(rowid)
                FROM dispensers
                WHERE asset = ?
                GROUP BY source, asset
            ) WHERE status = ?
            ORDER BY tx_index
        """
        bindings = (asset, 0)
        cursor.execute(query, bindings)
        holders += _get_holders(
            cursor,
            ["tx_hash", "source", "asset", "satoshirate", "give_quantity"],
            {"address": "source", "address_quantity": "give_remaining"},
            # exclude_empty_holders=exclude_empty_holders,
            table="dispensers",
        )

    cursor.close()
    return holders


def get_asset_holders(db, asset: str):
    """
    Returns the holders of an asset
    :param str asset: The asset to return (e.g. ERYKAHPEPU)
    """
    asset_name = resolve_subasset_longname(db, asset)
    return holders(db, asset_name, True)


def get_asset_holder_count(db, asset):
    holders = get_asset_holders(db, asset)
    addresses = [holder["address"] for holder in holders]
    return len(set(addresses))


def xcp_created(db):
    """Return number of XCP created thus far."""
    cursor = db.cursor()
    query = """
        SELECT SUM(earned) AS total
        FROM burns
        WHERE (status = ?)
    """
    bindings = ("valid",)
    cursor.execute(query, bindings)
    total = list(cursor)[0]["total"] or 0
    cursor.close()
    return total


def xcp_destroyed(db):
    """Return number of XCP destroyed thus far."""
    cursor = db.cursor()
    # Destructions.
    query = """
        SELECT SUM(quantity) AS total
        FROM destructions
        WHERE (status = ? AND asset = ?)
    """
    bindings = ("valid", config.XCP)
    cursor.execute(query, bindings)
    destroyed_total = list(cursor)[0]["total"] or 0

    # Subtract issuance fees.
    query = """
        SELECT SUM(fee_paid) AS total
        FROM issuances
        WHERE status = ?
    """
    bindings = ("valid",)
    cursor.execute(query, bindings)
    issuance_fee_total = list(cursor)[0]["total"] or 0

    # Subtract dividend fees.
    query = """
        SELECT SUM(fee_paid) AS total
        FROM dividends
        WHERE status = ?
    """
    bindings = ("valid",)
    cursor.execute(query, bindings)
    dividend_fee_total = list(cursor)[0]["total"] or 0

    # Subtract sweep fees.
    query = """
        SELECT SUM(fee_paid) AS total
        FROM sweeps
        WHERE status = ?
    """
    bindings = ("valid",)
    cursor.execute(query, bindings)
    sweeps_fee_total = list(cursor)[0]["total"] or 0
    cursor.close()
    return destroyed_total + issuance_fee_total + dividend_fee_total + sweeps_fee_total


def xcp_supply(db):
    """Return the XCP supply."""
    return xcp_created(db) - xcp_destroyed(db)


def creations(db):
    """Return creations."""
    cursor = db.cursor()
    creations = {config.XCP: xcp_created(db)}
    query = """
        SELECT asset, SUM(quantity) AS created
        FROM issuances
        WHERE status = ?
        GROUP BY asset
    """
    bindings = ("valid",)
    cursor.execute(query, bindings)

    for issuance in cursor:
        asset = issuance["asset"]
        created = issuance["created"]
        creations[asset] = created

    cursor.close()
    return creations


def destructions(db):
    """Return destructions."""
    cursor = db.cursor()
    destructions = {config.XCP: xcp_destroyed(db)}
    query = """
        SELECT asset, SUM(quantity) AS destroyed
        FROM destructions
        WHERE (status = ? AND asset != ?)
        GROUP BY asset
    """
    bindings = ("valid", config.XCP)
    cursor.execute(query, bindings)

    for destruction in cursor:
        asset = destruction["asset"]
        destroyed = destruction["destroyed"]
        destructions[asset] = destroyed

    cursor.close()
    return destructions


def asset_issued_total(db, asset):
    """Return asset total issued."""
    cursor = db.cursor()
    query = """
        SELECT SUM(quantity) AS total
        FROM issuances
        WHERE (status = ? AND asset = ?)
    """
    bindings = ("valid", asset)
    cursor.execute(query, bindings)
    issued_total = list(cursor)[0]["total"] or 0
    cursor.close()
    return issued_total


def asset_destroyed_total(db, asset):
    """Return asset total destroyed."""
    cursor = db.cursor()
    query = """
        SELECT SUM(quantity) AS total
        FROM destructions
        WHERE (status = ? AND asset = ?)
    """
    bindings = ("valid", asset)
    cursor.execute(query, bindings)
    destroyed_total = list(cursor)[0]["total"] or 0
    cursor.close()
    return destroyed_total


def asset_supply(db, asset):
    """Return asset supply."""
    return asset_issued_total(db, asset) - asset_destroyed_total(db, asset)


def supplies(db):
    """Return supplies."""
    d1 = creations(db)
    d2 = destructions(db)
    return {key: d1[key] - d2.get(key, 0) for key in d1.keys()}


def held(db):  # TODO: Rename ?
    queries = [
        """
        SELECT asset, SUM(quantity) AS total FROM (
            SELECT address, asset, quantity, (address || asset) AS aa, MAX(rowid)
            FROM balances
            WHERE address IS NOT NULL
            GROUP BY aa
        ) GROUP BY asset
        """,
        """
        SELECT asset, SUM(quantity) AS total FROM (
            SELECT NULL, asset, quantity
            FROM balances
            WHERE address IS NULL
        ) GROUP BY asset
        """,
        """
        SELECT give_asset AS asset, SUM(give_remaining) AS total FROM (
            SELECT give_asset, give_remaining, status, MAX(rowid)
            FROM orders
            GROUP BY tx_hash
        ) WHERE status = 'open' GROUP BY asset
        """,
        """
        SELECT give_asset AS asset, SUM(give_remaining) AS total FROM (
            SELECT give_asset, give_remaining, status, MAX(rowid)
            FROM orders
            WHERE give_asset = 'XCP' AND get_asset = 'BTC'
            GROUP BY tx_hash
        ) WHERE status = 'filled' GROUP BY asset
        """,
        """
        SELECT forward_asset AS asset, SUM(forward_quantity) AS total FROM (
            SELECT forward_asset, forward_quantity, status, MAX(rowid)
            FROM order_matches
            GROUP BY id
        ) WHERE status = 'pending' GROUP BY asset
        """,
        """
        SELECT backward_asset AS asset, SUM(backward_quantity) AS total FROM (
            SELECT backward_asset, backward_quantity, status, MAX(rowid)
            FROM order_matches
            GROUP BY id
        ) WHERE status = 'pending' GROUP BY asset
        """,
        """
        SELECT 'XCP' AS asset, SUM(wager_remaining) AS total FROM (
            SELECT wager_remaining, status, MAX(rowid)
            FROM bets
            GROUP BY tx_hash
        ) WHERE status = 'open'
        """,
        """
        SELECT 'XCP' AS asset, SUM(forward_quantity) AS total FROM (
            SELECT forward_quantity, status, MAX(rowid)
            FROM bet_matches
            GROUP BY id
        ) WHERE status = 'pending'
        """,
        """
        SELECT 'XCP' AS asset, SUM(backward_quantity) AS total FROM (
            SELECT backward_quantity, status, MAX(rowid)
            FROM bet_matches
            GROUP BY id
        ) WHERE status = 'pending'
        """,
        """
        SELECT 'XCP' AS asset, SUM(wager) AS total FROM (
            SELECT wager, status, MAX(rowid)
            FROM rps
            GROUP BY tx_hash
        ) WHERE status = 'open'
        """,
        """
        SELECT 'XCP' AS asset, SUM(wager * 2) AS total FROM (
            SELECT wager, status, MAX(rowid)
            FROM rps_matches
            GROUP BY id
        ) WHERE status IN ('pending', 'pending and resolved', 'resolved and pending')
        """,
        """
        SELECT asset, SUM(give_remaining) AS total FROM (
            SELECT asset, give_remaining, status, MAX(rowid)
            FROM dispensers
            GROUP BY tx_hash
        ) WHERE status IN (0, 1, 11) GROUP BY asset
        """,
    ]
    # no sql injection here
    sql = (
        "SELECT asset, SUM(total) AS total FROM ("  # noqa: S608
        + " UNION ALL ".join(queries)
        + ") GROUP BY asset;"
    )  # nosec B608

    cursor = db.cursor()
    cursor.execute(sql)
    held = {}
    for row in cursor:
        asset = row["asset"]
        total = row["total"]
        held[asset] = total

    return held
