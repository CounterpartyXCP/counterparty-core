from counterpartycore.lib import ledger


def get_blocks(db, cursor: int = None, limit: int = 10):
    """
    Returns the list of the last ten blocks
    :param int cursor: The index of the most recent block to return (e.g. 840000)
    :param int limit: The number of blocks to return (e.g. 2)
    """
    return ledger.select_rows(
        db, "blocks", cursor_field="block_index", last_cursor=cursor, limit=limit
    )


def get_block_by_height(db, block_index: int):
    """
    Return the information of a block
    :param int block_index: The index of the block to return (e.g. 840464)
    """
    return ledger.select_row(db, "blocks", where={"block_index": block_index})


def get_transactions_by_block(db, block_index: int, cursor: int = None, limit: int = 10):
    """
    Returns the transactions of a block
    :param int block_index: The index of the block to return (e.g. 840464)
    :param int cursor: The last transaction index to return (e.g. 10665092)
    :param int limit: The maximum number of transactions to return (e.g. 5)
    """
    return ledger.select_rows(
        db,
        "transactions",
        where={"block_index": block_index},
        cursor_field="tx_index",
        last_cursor=cursor,
        limit=limit,
    )


def get_all_events(db, cursor: int = None, limit: int = 100):
    """
    Returns all events
    :param int cursor: The last event index to return (e.g. 10665092)
    :param int limit: The maximum number of events to return (e.g. 5)
    """
    return ledger.select_rows(
        db,
        "events",
        cursor_field="message_index",
        last_cursor=cursor,
        limit=limit,
        select="message_index AS event_index, event, bindings AS params, tx_hash, block_index, timestamp",
    )


def get_events_by_block(db, block_index: int, cursor: int = None, limit: int = 100):
    """
    Returns the events of a block
    :param int block_index: The index of the block to return (e.g. 840464)
    :param int cursor: The last event index to return (e.g. 10665092)
    :param int limit: The maximum number of events to return (e.g. 5)
    """
    return ledger.select_rows(
        db,
        "events",
        where={"block_index": block_index},
        cursor_field="message_index",
        last_cursor=cursor,
        limit=limit,
        select="message_index AS event_index, event, bindings AS params, tx_hash",
    )


def get_events_by_transaction_hash(db, tx_hash: str, cursor: int = None, limit: int = 100):
    """
    Returns the events of a transaction
    :param str tx_hash: The hash of the transaction to return (e.g. 84b34b19d971adc2ad2dc6bfc5065ca976db1488f207df4887da976fbf2fd040)
    :param int cursor: The last event index to return (e.g. 10665092)
    :param int limit: The maximum number of events to return (e.g. 5)
    """
    return ledger.select_rows(
        db,
        "events",
        where={"tx_hash": tx_hash},
        cursor_field="message_index",
        last_cursor=cursor,
        limit=limit,
        select="message_index AS event_index, event, bindings AS params, tx_hash, block_index, timestamp",
    )


def get_events_by_transaction_hash_and_event(
    db, tx_hash: str, event: str, cursor: int = None, limit: int = 100
):
    """
    Returns the events of a transaction
    :param str tx_hash: The hash of the transaction to return (e.g. 84b34b19d971adc2ad2dc6bfc5065ca976db1488f207df4887da976fbf2fd040)
    :param str event: The event to filter by (e.g. CREDIT)
    :param int cursor: The last event index to return (e.g. 10665092)
    :param int limit: The maximum number of events to return (e.g. 5)
    """
    return ledger.select_rows(
        db,
        "events",
        where={"tx_hash": tx_hash, "event": event},
        cursor_field="message_index",
        last_cursor=cursor,
        limit=limit,
        select="message_index AS event_index, event, bindings AS params, tx_hash, block_index, timestamp",
    )


def get_events_by_transaction_index(db, tx_index: int, cursor: int = None, limit: int = 100):
    """
    Returns the events of a transaction
    :param str tx_index: The index of the transaction to return (e.g. 1000)
    :param int cursor: The last event index to return (e.g. 10665092)
    :param int limit: The maximum number of events to return (e.g. 5)
    """
    tx = ledger.select_row(db, "transactions", where={"tx_index": tx_index})
    if tx:
        return get_events_by_transaction_hash(db, tx["tx_hash"], cursor=cursor, limit=limit)
    return None


def get_events_by_transaction_index_and_event(
    db, tx_index: int, event: str, cursor: int = None, limit: int = 100
):
    """
    Returns the events of a transaction
    :param str tx_index: The index of the transaction to return (e.g. 1000)
    :param str event: The event to filter by (e.g. CREDIT)
    :param int cursor: The last event index to return (e.g. 10665092)
    :param int limit: The maximum number of events to return (e.g. 5)
    """
    tx = ledger.select_row(db, "transactions", where={"tx_index": tx_index})
    if tx:
        return get_events_by_transaction_hash_and_event(
            db, tx["tx_hash"], event, cursor=cursor, limit=limit
        )
    return None


def get_events_by_block_and_event(
    db, block_index: int, event: str, cursor: int = None, limit: int = 100
):
    """
    Returns the events of a block filtered by event
    :param int block_index: The index of the block to return (e.g. 840464)
    :param str event: The event to filter by (e.g. CREDIT)
    :param int cursor: The last event index to return (e.g. 10665092)
    :param int limit: The maximum number of events to return (e.g. 5)
    """
    if event == "count":
        return get_event_counts_by_block(db, block_index=block_index)
    return ledger.select_rows(
        db,
        "events",
        where={"block_index": block_index, "event": event},
        cursor_field="message_index",
        last_cursor=cursor,
        limit=limit,
        select="message_index AS event_index, event, bindings AS params, tx_hash",
    )


def get_event_by_index(db, event_index: int):
    """
    Returns the event of an index
    :param int event_index: The index of the event to return (e.g. 10665092)
    """
    return ledger.select_row(
        db,
        "events",
        where={"message_index": event_index},
        select="message_index AS event_index, event, bindings AS params, tx_hash, block_index, timestamp",
    )


def get_events_by_name(db, event: str, cursor: int = None, limit: int = 100):
    """
    Returns the events filtered by event name
    :param str event: The event to return (e.g. CREDIT)
    :param int cursor: The last event index to return (e.g. 10665092)
    :param int limit: The maximum number of events to return (e.g. 5)
    """
    return ledger.select_rows(
        db,
        "events",
        where={"event": event},
        cursor_field="message_index",
        last_cursor=cursor,
        limit=limit,
        select="message_index AS event_index, event, bindings AS params, tx_hash, block_index, timestamp",
    )


def get_all_mempool_events(db, cursor: int = None, limit: int = 100):
    """
    Returns all mempool events
    :param int cursor: The last event index to return
    :param int limit: The maximum number of events to return
    """
    return ledger.select_rows(db, "mempool", last_cursor=cursor, limit=limit)


def get_mempool_events_by_name(db, event: str, cursor: int = None, limit: int = 100):
    """
    Returns the mempool events filtered by event name
    :param str event: The event to return (e.g. OPEN_ORDER)
    :param int cursor: The last event index to return
    :param int limit: The maximum number of events to return
    """
    return ledger.select_rows(
        db, "mempool", where={"event": event}, last_cursor=cursor, limit=limit
    )


def get_mempool_events_by_tx_hash(db, tx_hash: str, cursor: int = None, limit: int = 100):
    """
    Returns the mempool events filtered by transaction hash
    :param str tx_hash: The hash of the transaction to return (e.g. 84b34b19d971adc2ad2dc6bfc5065ca976db1488f207df4887da976fbf2fd040)
    :param int cursor: The last event index to return
    :param int limit: The maximum number of events to return
    """
    return ledger.select_rows(
        db, "mempool", where={"tx_hash": tx_hash}, last_cursor=cursor, limit=limit
    )


def get_event_counts_by_block(db, block_index: int):
    """
    Returns the event counts of a block
    :param int block_index: The index of the block to return (e.g. 840464)
    """
    return ledger.get_events_counts(db, block_index=block_index)


def get_all_events_counts(db):
    """
    Returns the event counts of all blocks
    """
    return ledger.get_events_counts(db)


def get_credits_by_block(db, block_index: int, cursor: int = None, limit: int = 100):
    """
    Returns the credits of a block
    :param int block_index: The index of the block to return (e.g. 840464)
    :param int cursor: The last credit index to return
    :param int limit: The maximum number of events to return
    """
    return ledger.select_rows(
        db, "credits", where={"block_index": block_index}, cursor=cursor, limit=limit
    )


def get_credits_by_address(db, address: str, cursor: int = None, limit: int = 100):
    """
    Returns the credits of an address
    :param str address: The address to return (e.g. 1C3uGcoSGzKVgFqyZ3kM2DBq9CYttTMAVs)
    :param int cursor: The last index of the credits to return
    :param int limit: The maximum number of credits to return
    """
    return ledger.select_rows(db, "credits", where={"address": address}, cursor=cursor, limit=limit)


def get_credits_by_asset(db, asset: str, cursor: int = None, limit: int = 100):
    """
    Returns the credits of an asset
    :param str asset: The asset to return (e.g. UNNEGOTIABLE)
    :param int cursor: The last index of the credits to return
    :param int limit: The maximum number of credits to return
    """
    return ledger.select_rows(db, "credits", where={"asset": asset}, cursor=cursor, limit=limit)


def get_debits_by_block(db, block_index: int, cursor: int = None, limit: int = 100):
    """
    Returns the debits of a block
    :param int block_index: The index of the block to return (e.g. 840464)
    :param int cursor: The last index of the debits to return
    :param int limit: The maximum number of debits to return
    """
    return ledger.select_rows(
        db, "debits", where={"block_index": block_index}, cursor=cursor, limit=limit
    )


def get_debits_by_address(db, address: str, cursor: int = None, limit: int = 100):
    """
    Returns the debits of an address
    :param str address: The address to return (e.g. bc1q7787j6msqczs58asdtetchl3zwe8ruj57p9r9y)
    :param int cursor: The last index of the debits to return
    :param int limit: The maximum number of debits to return
    """
    return ledger.select_rows(db, "debits", where={"address": address}, cursor=cursor, limit=limit)


def get_debits_by_asset(db, asset: str, cursor: int = None, limit: int = 100):
    """
    Returns the debits of an asset
    :param str asset: The asset to return (e.g. XCP)
    :param int cursor: The last index of the debits to return
    :param int limit: The maximum number of debits to return
    """
    return ledger.select_rows(db, "debits", where={"asset": asset}, cursor=cursor, limit=limit)


def get_sends_by_block(db, block_index: int, cursor: int = None, limit: int = 100):
    """
    Returns the sends of a block
    :param int block_index: The index of the block to return (e.g. 840459)
    :param int cursor: The last index of the debits to return
    :param int limit: The maximum number of debits to return
    """
    return ledger.select_rows(
        db, "sends", where={"block_index": block_index}, cursor=cursor, limit=limit
    )


def get_sends_by_asset(db, asset: str, cursor: int = None, limit: int = 100):
    """
    Returns the sends of an asset
    :param str asset: The asset to return (e.g. XCP)
    :param int cursor: The last index of the debits to return
    :param int limit: The maximum number of debits to return
    """
    return ledger.select_rows(db, "sends", where={"asset": asset}, cursor=cursor, limit=limit)


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


def get_cancels(db, block_index: int, cursor: int = None, limit: int = 100):
    """
    Returns the cancels of a block
    :param int block_index: The index of the block to return (e.g. 839746)
    :param int cursor: The last index of the cancels to return
    :param int limit: The maximum number of cancels to return
    """
    return ledger.select_rows(
        db, "cancels", where={"block_index": block_index}, cursor=cursor, limit=limit
    )


def get_destructions(db, block_index: int, cursor: int = None, limit: int = 100):
    """
    Returns the destructions of a block
    :param int block_index: The index of the block to return (e.g. 839988)
    :param int cursor: The last index of the destructions to return
    :param int limit: The maximum number of destructions to return
    """
    return ledger.select_rows(
        db, "destructions", where={"block_index": block_index}, cursor=cursor, limit=limit
    )


def get_issuances_by_block(db, block_index: int, cursor: int = None, limit: int = 100):
    """
    Returns the issuances of a block
    :param int block_index: The index of the block to return (e.g. 840464)
    :param int cursor: The last index of the issuances to return
    :param int limit: The maximum number of issuances to return
    """
    return ledger.select_rows(
        db, "issuances", where={"block_index": block_index}, cursor=cursor, limit=limit
    )


def get_issuances_by_asset(db, asset: str, cursor: int = None, limit: int = 100):
    """
    Returns the issuances of an asset
    :param str asset: The asset to return (e.g. UNNEGOTIABLE)
    :param int cursor: The last index of the issuances to return
    :param int limit: The maximum number of issuances to return
    """
    return ledger.select_rows(db, "issuances", where={"asset": asset}, cursor=cursor, limit=limit)


def get_dispenses_by_block(db, block_index: int, cursor: int = None, limit: int = 100):
    """
    Returns the dispenses of a block
    :param int block_index: The index of the block to return (e.g. 840322)
    :param int cursor: The last index of the dispenses to return
    :param int limit: The maximum number of dispenses to return
    """
    return ledger.select_rows(
        db, "dispenses", where={"block_index": block_index}, cursor=cursor, limit=limit
    )


def get_dispenses_by_dispenser(db, dispenser_hash: str, cursor: int = None, limit: int = 100):
    """
    Returns the dispenses of a dispenser
    :param str dispenser_hash: The hash of the dispenser to return (e.g. 753787004d6e93e71f6e0aa1e0932cc74457d12276d53856424b2e4088cc542a)
    :param int cursor: The last index of the dispenses to return
    :param int limit: The maximum number of dispenses to return
    """
    return ledger.select_rows(
        db, "dispenses", where={"dispenser_tx_hash": dispenser_hash}, cursor=cursor, limit=limit
    )


def get_dispenses_by_source(db, address: str, cursor: int = None, limit: int = 100):
    """
    Returns the dispenses of a source
    :param str address: The address to return (e.g. bc1qlzkcy8c5fa6y6xvd8zn4axnvmhndfhku3hmdpz)
    :param int cursor: The last index of the dispenses to return
    :param int limit: The maximum number of dispenses to return
    """
    return ledger.select_rows(
        db, "dispenses", where={"source": address}, cursor=cursor, limit=limit
    )


def get_dispenses_by_destination(db, address: str, cursor: int = None, limit: int = 100):
    """
    Returns the dispenses of a destination
    :param str address: The address to return (e.g. bc1qlzkcy8c5fa6y6xvd8zn4axnvmhndfhku3hmdpz)
    :param int cursor: The last index of the dispenses to return
    :param int limit: The maximum number of dispenses to return
    """
    return ledger.select_rows(
        db, "dispenses", where={"destination": address}, cursor=cursor, limit=limit
    )


def get_dispenses_by_asset(db, asset: str, cursor: int = None, limit: int = 100):
    """
    Returns the dispenses of an asset
    :param str asset: The asset to return (e.g. ERYKAHPEPU)
    :param int cursor: The last index of the dispenses to return
    :param int limit: The maximum number of dispenses to return
    """
    return ledger.select_rows(db, "dispenses", where={"asset": asset}, cursor=cursor, limit=limit)


def get_dispenses_by_source_and_asset(
    db, address: str, asset: str, cursor: int = None, limit: int = 100
):
    """
    Returns the dispenses of an address and an asset
    :param str address: The address to return (e.g. bc1qlzkcy8c5fa6y6xvd8zn4axnvmhndfhku3hmdpz)
    :param str asset: The asset to return (e.g. ERYKAHPEPU)
    :param int cursor: The last index of the dispenses to return
    :param int limit: The maximum number of dispenses to return
    """
    return ledger.select_rows(
        db, "dispenses", where={"source": address, "asset": asset}, cursor=cursor, limit=limit
    )


def get_dispenses_by_destination_and_asset(
    db, address: str, asset: str, cursor: int = None, limit: int = 100
):
    """
    Returns the dispenses of an address and an asset
    :param str address: The address to return (e.g. bc1qlzkcy8c5fa6y6xvd8zn4axnvmhndfhku3hmdpz)
    :param str asset: The asset to return (e.g. ERYKAHPEPU)
    :param int cursor: The last index of the dispenses to return
    :param int limit: The maximum number of dispenses to return
    """
    return ledger.select_rows(
        db, "dispenses", where={"destination": address, "asset": asset}, cursor=cursor, limit=limit
    )


def get_sweeps_by_block(db, block_index: int, cursor: int = None, limit: int = 100):
    """
    Returns the sweeps of a block
    :param int block_index: The index of the block to return (e.g. 836519)
    :param int cursor: The last index of the sweeps to return
    :param int limit: The maximum number of sweeps to return
    """
    return ledger.select_rows(
        db, "sweeps", where={"block_index": block_index}, cursor=cursor, limit=limit
    )


def get_sweeps_by_address(db, address: str, cursor: int = None, limit: int = 100):
    """
    Returns the sweeps of an address
    :param str address: The address to return (e.g. 18szqTVJUWwYrtRHq98Wn4DhCGGiy3jZ87)
    :param int cursor: The last index of the sweeps to return
    :param int limit: The maximum number of sweeps to return
    """
    return ledger.select_rows(db, "sweeps", where={"address": address}, cursor=cursor, limit=limit)


def get_address_balances(db, address: str, cursor: int = None, limit: int = 100):
    """
    Returns the balances of an address
    :param str address: The address to return (e.g. 1C3uGcoSGzKVgFqyZ3kM2DBq9CYttTMAVs)
    :param int cursor: The last index of the balances to return
    :param int limit: The maximum number of balances to return
    """
    return ledger.select_rows(
        db,
        "balances",
        where={"address": address},
        cursor=cursor,
        limit=limit,
        select="address, asset, quantity, MAX(rowid) AS rowid",
        group_by="address, asset",
    )


def get_balance_by_address_and_asset(db, address: str, asset: str):
    """
    Returns the balance of an address and asset
    :param str address: The address to return (e.g. 1C3uGcoSGzKVgFqyZ3kM2DBq9CYttTMAVs)
    :param str asset: The asset to return (e.g. XCP)
    """
    return ledger.select_row(
        db,
        "balances",
        where={"address": address, "asset": asset},
    )


def get_bet_by_feed(db, address: str, status: str = "open"):
    """
    Returns the bets of a feed
    :param str address: The address of the feed (e.g. 1QKEpuxEmdp428KEBSDZAKL46noSXWJBkk)
    :param str status: The status of the bet (e.g. filled)
    """
    return ledger.get_bet_by_feed(db, address=address, status=status)


def get_broadcasts_by_source(
    db, address: str, status: str = "valid", cursor: int = None, limit: int = 100
):
    """
    Returns the broadcasts of a source
    :param str address: The address to return (e.g. 1QKEpuxEmdp428KEBSDZAKL46noSXWJBkk)
    :param str status: The status of the broadcasts to return (e.g. valid)
    :param int cursor: The last index of the broadcasts to return
    :param int limit: The maximum number of broadcasts to return
    """
    return ledger.select_rows(
        db,
        "broadcasts",
        where={"source": address, "status": status},
        cursor_field="tx_index",
        last_cursor=cursor,
        limit=limit,
    )


def get_burns_by_address(db, address: str, cursor: int = None, limit: int = 100):
    """
    Returns the burns of an address
    :param str address: The address to return (e.g. 1HVgrYx3U258KwvBEvuG7R8ss1RN2Z9J1W)
    :param int cursor: The last index of the burns to return
    :param int limit: The maximum number of burns to return
    """
    return ledger.select_rows(db, "burns", where={"source": address}, cursor=cursor, limit=limit)


def get_send_by_address(db, address: str, cursor: int = None, limit: int = 100):
    """
    Returns the sends of an address
    :param str address: The address to return (e.g. 1HVgrYx3U258KwvBEvuG7R8ss1RN2Z9J1W)
    :param int cursor: The last index of the sends to return
    :param int limit: The maximum number of sends to return
    """
    return ledger.select_rows(db, "sends", where={"source": address}, cursor=cursor, limit=limit)


def get_send_by_address_and_asset(
    db, address: str, asset: str, cursor: int = None, limit: int = 100
):
    """
    Returns the sends of an address and asset
    :param str address: The address to return (e.g. 1HVgrYx3U258KwvBEvuG7R8ss1RN2Z9J1W)
    :param str asset: The asset to return (e.g. XCP)
    :param int cursor: The last index of the sends to return
    :param int limit: The maximum number of sends to return
    """
    return ledger.select_rows(
        db, "sends", where={"source": address, "asset": asset}, cursor=cursor, limit=limit
    )


def get_receive_by_address(db, address: str, cursor: int = None, limit: int = 100):
    """
    Returns the receives of an address
    :param str address: The address to return (e.g. 1C3uGcoSGzKVgFqyZ3kM2DBq9CYttTMAVs)
    :param int cursor: The last index of the sends to return
    :param int limit: The maximum number of sends to return
    """
    return ledger.select_rows(
        db, "sends", where={"destination": address}, cursor=cursor, limit=limit
    )


def get_receive_by_address_and_asset(
    db, address: str, asset: str, cursor: int = None, limit: int = 100
):
    """
    Returns the receives of an address and asset
    :param str address: The address to return (e.g. 1C3uGcoSGzKVgFqyZ3kM2DBq9CYttTMAVs)
    :param str asset: The asset to return (e.g. XCP)
    :param int cursor: The last index of the sends to return
    :param int limit: The maximum number of sends to return
    """
    return ledger.select_rows(
        db, "sends", where={"destination": address, "asset": asset}, cursor=cursor, limit=limit
    )


def get_dispensers_by_address(db, address: str, status: int = 0):
    """
    Returns the dispensers of an address
    :param str address: The address to return (e.g. bc1qlzkcy8c5fa6y6xvd8zn4axnvmhndfhku3hmdpz)
    """
    return ledger.get_dispensers(db, address=address, status=status)


def get_dispensers_by_asset(db, asset: str, status: int = 0):
    """
    Returns the dispensers of an asset
    :param str asset: The asset to return (e.g. ERYKAHPEPU)
    """
    return ledger.get_dispensers(db, asset=asset, status=status)


def get_dispensers_by_address_and_asset(db, address: str, asset: str, status: int = 0):
    """
    Returns the dispensers of an address and an asset
    :param str address: The address to return (e.g. bc1qlzkcy8c5fa6y6xvd8zn4axnvmhndfhku3hmdpz)
    :param str asset: The asset to return (e.g. ERYKAHPEPU)
    """
    return ledger.get_dispensers(db, address=address, asset=asset, status=status)


def get_asset_info(db, asset: str):
    """
    Returns the asset information
    :param str asset: The asset to return (e.g. UNNEGOTIABLE)
    """
    return ledger.get_asset_info(db, asset=asset)


def get_valid_assets(db, cursor: int = None, limit: int = 100):
    """
    Returns the valid assets
    :param int offset: The offset of the assets to return (e.g. 0)
    :param int limit: The limit of the assets to return (e.g. 5)
    :param int cursor: The last index of the assets to return
    :param int limit: The maximum number of assets to return
    """
    return ledger.select_rows(
        db,
        "issuances",
        where={"status": "valid"},
        cursor_field="asset",
        group_by="asset",
        order="ASC",
        select="asset, asset_longname",
        cursor=cursor,
        limit=limit,
    )


def get_dividends(db, asset: str, cursor: int = None, limit: int = 100):
    """
    Returns the dividends of an asset
    :param str asset: The asset to return (e.g. GMONEYPEPE)
    :param int cursor: The last index of the assets to return
    :param int limit: The maximum number of assets to return
    """
    return ledger.select_rows(
        db,
        "dividends",
        where={"asset": asset, "status": "valid"},
        cursor=cursor,
        limit=limit,
    )


def get_asset_balances(db, asset: str, cursor: int = None, limit: int = 100):
    """
    Returns the asset balances
    :param str asset: The asset to return (e.g. UNNEGOTIABLE)
    :param int cursor: The last index of the balances to return
    :param int limit: The maximum number of balances to return
    """
    return ledger.select_rows(
        db,
        "balances",
        where={"asset": asset, "quantity__gt": 0},
        cursor_field="address",
        select="address, asset, quantity, MAX(rowid) AS rowid",
        group_by="address",
        order="ASC",
        cursor=cursor,
        limit=limit,
    )


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


def get_asset_holders(db, asset: str):
    """
    Returns the holders of an asset
    :param str asset: The asset to return (e.g. ERYKAHPEPU)
    """
    return ledger.get_asset_holders(db, asset=asset)


def get_order(db, order_hash: str):
    """
    Returns the information of an order
    :param str order_hash: The hash of the transaction that created the order (e.g. 23f68fdf934e81144cca31ce8ef69062d553c521321a039166e7ba99aede0776)
    """
    return ledger.get_order(db, order_hash=order_hash)


def get_order_matches_by_order(
    db, order_hash: str, status: str = "pending", cursor: int = None, limit: int = 100
):
    """
    Returns the order matches of an order
    :param str order_hash: The hash of the transaction that created the order (e.g. 5461e6f99a37a7167428b4a720a52052cd9afed43905f818f5d7d4f56abd0947)
    :param str status: The status of the order matches to return (e.g. completed)
    :param int cursor: The last index of the order matches to return
    :param int limit: The maximum number of order matches to return
    """
    return ledger.select_rows(
        db,
        "order_matches",
        where=[{"tx0_hash": order_hash}, {"tx1_hash": order_hash}],  # tx0_hash = ? OR tx1_hash = ?
        select="*, MAX(rowid) AS rowid",
        group_by="id",
        wrap_where={"status": status},
        cursor=cursor,
        limit=limit,
    )


def get_btcpays_by_order(db, order_hash: str, cursor: int = None, limit: int = 100):
    """
    Returns the BTC pays of an order
    :param str order_hash: The hash of the transaction that created the order (e.g. 299b5b648f54eacb839f3487232d49aea373cdd681b706d4cc0b5e0b03688db4)
    :param int cursor: The last index of the resolutions to return
    :param int limit: The maximum number of resolutions to return
    """
    return ledger.select_rows(
        db, "btcpays", where={"order_match_id__like": f"%{order_hash}%"}, cursor=cursor, limit=limit
    )


def get_bet(db, bet_hash: str):
    """
    Returns the information of a bet
    :param str bet_hash: The hash of the transaction that created the bet (e.g. 5d097b4729cb74d927b4458d365beb811a26fcee7f8712f049ecbe780eb496ed)
    """
    return ledger.select_row(
        db,
        "bets",
        where={"tx_hash": bet_hash},
    )


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


def get_resolutions_by_bet(db, bet_hash: str, cursor: int = None, limit: int = 100):
    """
    Returns the resolutions of a bet
    :param str bet_hash: The hash of the transaction that created the bet (e.g. 36bbbb7dbd85054dac140a8ad8204eda2ee859545528bd2a9da69ad77c277ace)
    :param int cursor: The last index of the resolutions to return
    :param int limit: The maximum number of resolutions to return
    """
    return ledger.select_rows(
        db,
        "bet_match_resolutions",
        where={"bet_match_id__like": f"%{bet_hash}%"},
        cursor=cursor,
        limit=limit,
    )


def get_all_burns(db, status: str = "valid", cursor: int = None, limit: int = 100):
    """
    Returns the burns
    :param str status: The status of the burns to return (e.g. valid)
    :param int cursor: The last index of the burns to return
    :param int limit: The maximum number of burns to return
    """
    return ledger.select_rows(db, "burns", where={"status": status}, cursor=cursor, limit=limit)


def get_dispenser_info_by_hash(db, dispenser_hash: str):
    """
    Returns the dispenser information by tx_hash
    :param str dispenser_hash: The hash of the dispenser to return (e.g. 753787004d6e93e71f6e0aa1e0932cc74457d12276d53856424b2e4088cc542a)
    """
    return ledger.select_row(
        db,
        "dispensers",
        where={"tx_hash": dispenser_hash},
    )
