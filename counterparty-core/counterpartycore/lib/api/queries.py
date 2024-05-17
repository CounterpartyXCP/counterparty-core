from counterpartycore.lib import exceptions, ledger


def get_blocks(db, last: int = None, limit: int = 10):
    """
    Returns the list of the last ten blocks
    :param int last: The index of the most recent block to return (e.g. 840000)
    :param int limit: The number of blocks to return (e.g. 2)
    """
    return ledger.get_blocks(db, last=last, limit=limit)


def get_block_by_height(db, block_index: int):
    """
    Return the information of a block
    :param int block_index: The index of the block to return (e.g. 840464)
    """
    return ledger.get_block(db, block_index=block_index)


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


def get_all_events(db, last: int = None, limit: int = 100):
    """
    Returns all events
    :param int last: The last event index to return (e.g. 10665092)
    :param int limit: The maximum number of events to return (e.g. 5)
    """
    return ledger.get_events(db, last=last, limit=limit)


def get_events_by_block(db, block_index: int, last: int = None, limit: int = 100):
    """
    Returns the events of a block
    :param int block_index: The index of the block to return (e.g. 840464)
    :param int last: The last event index to return (e.g. 10665092)
    :param int limit: The maximum number of events to return (e.g. 5)
    """
    return ledger.get_events(db, block_index=block_index, last=last, limit=limit)


def get_events_by_transaction_hash(db, tx_hash: str, last: int = None, limit: int = 100):
    """
    Returns the events of a transaction
    :param str tx_hash: The hash of the transaction to return (e.g. 84b34b19d971adc2ad2dc6bfc5065ca976db1488f207df4887da976fbf2fd040)
    :param int last: The last event index to return (e.g. 10665092)
    :param int limit: The maximum number of events to return (e.g. 5)
    """
    return ledger.get_events(db, tx_hash=tx_hash, last=last, limit=limit)


def get_events_by_transaction_hash_and_event(
    db, tx_hash: str, event: str, last: int = None, limit: int = 100
):
    """
    Returns the events of a transaction
    :param str tx_hash: The hash of the transaction to return (e.g. 84b34b19d971adc2ad2dc6bfc5065ca976db1488f207df4887da976fbf2fd040)
    :param str event: The event to filter by (e.g. CREDIT)
    :param int last: The last event index to return (e.g. 10665092)
    :param int limit: The maximum number of events to return (e.g. 5)
    """
    return ledger.get_events(db, tx_hash=tx_hash, event=event, last=last, limit=limit)


def get_events_by_transaction_index(db, tx_index: int, last: int = None, limit: int = 100):
    """
    Returns the events of a transaction
    :param str tx_index: The index of the transaction to return (e.g. 1000)
    :param int last: The last event index to return (e.g. 10665092)
    :param int limit: The maximum number of events to return (e.g. 5)
    """
    txs = ledger.get_transactions(db, tx_index=tx_index)
    if txs:
        tx = txs[0]
        return ledger.get_events(db, tx_hash=tx["tx_hash"], last=last, limit=limit)
    return None


def get_events_by_transaction_index_and_event(
    db, tx_index: int, event: str, last: int = None, limit: int = 100
):
    """
    Returns the events of a transaction
    :param str tx_index: The index of the transaction to return (e.g. 1000)
    :param str event: The event to filter by (e.g. CREDIT)
    :param int last: The last event index to return (e.g. 10665092)
    :param int limit: The maximum number of events to return (e.g. 5)
    """
    txs = ledger.get_transactions(db, tx_index=tx_index)
    if txs:
        tx = txs[0]
        return ledger.get_events(db, tx_hash=tx["tx_hash"], event=event, last=last, limit=limit)
    return None


def get_events_by_block_and_event(
    db, block_index: int, event: str, last: int = None, limit: int = 100
):
    """
    Returns the events of a block filtered by event
    :param int block_index: The index of the block to return (e.g. 840464)
    :param str event: The event to filter by (e.g. CREDIT)
    :param int last: The last event index to return (e.g. 10665092)
    :param int limit: The maximum number of events to return (e.g. 5)
    """
    if event == "count":
        return ledger.get_event_counts_by_block(db, block_index=block_index)
    return ledger.get_events(db, block_index=block_index, event=event, last=last, limit=limit)


def get_event_by_index(db, event_index: int):
    """
    Returns the event of an index
    :param int event_index: The index of the event to return (e.g. 10665092)
    """
    return ledger.get_events(db, event_index=event_index)


def get_events_by_name(db, event: str, last: int = None, limit: int = 100):
    """
    Returns the events filtered by event name
    :param str event: The event to return (e.g. CREDIT)
    :param int last: The last event index to return (e.g. 10665092)
    :param int limit: The maximum number of events to return (e.g. 5)
    """
    return ledger.get_events(db, event=event, last=last, limit=limit)


def get_all_mempool_events(db):
    """
    Returns all mempool events
    """
    return ledger.get_mempool_events(db)


def get_mempool_events_by_name(db, event: str):
    """
    Returns the mempool events filtered by event name
    :param str event: The event to return (e.g. OPEN_ORDER)
    """
    return ledger.get_mempool_events(db, event_name=event)


def get_mempool_events_by_tx_hash(db, tx_hash: str):
    """
    Returns the mempool events filtered by transaction hash
    :param str tx_hash: The hash of the transaction to return (e.g. 84b34b19d971adc2ad2dc6bfc5065ca976db1488f207df4887da976fbf2fd040)
    """
    return ledger.get_mempool_events(db, tx_hash=tx_hash)


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


def get_credits_by_block(db, block_index: int):
    """
    Returns the credits of a block
    :param int block_index: The index of the block to return (e.g. 840464)
    """
    return ledger.get_credits(db, block_index=block_index)


def get_credits_by_address(db, address: str, limit: int = 100, offset: int = 0):
    """
    Returns the credits of an address
    :param str address: The address to return (e.g. 1C3uGcoSGzKVgFqyZ3kM2DBq9CYttTMAVs)
    :param int limit: The maximum number of credits to return (e.g. 5)
    :param int offset: The offset of the credits to return (e.g. 0)
    """
    return ledger.get_credits(db, address=address, limit=limit, offset=offset)


def get_credits_by_asset(db, asset: str, limit: int = 100, offset: int = 0):
    """
    Returns the credits of an asset
    :param str asset: The asset to return (e.g. UNNEGOTIABLE)
    :param int limit: The maximum number of credits to return (e.g. 5)
    :param int offset: The offset of the credits to return (e.g. 0)
    """
    return ledger.get_credits(db, asset=asset, limit=limit, offset=offset)


def get_debits_by_block(db, block_index: int):
    """
    Returns the debits of a block
    :param int block_index: The index of the block to return (e.g. 840464)
    """
    return ledger.get_debits(db, block_index=block_index)


def get_debits_by_address(db, address: str, limit: int = 100, offset: int = 0):
    """
    Returns the debits of an address
    :param str address: The address to return (e.g. bc1q7787j6msqczs58asdtetchl3zwe8ruj57p9r9y)
    :param int limit: The maximum number of debits to return (e.g. 5)
    :param int offset: The offset of the debits to return (e.g. 0)
    """
    return ledger.get_debits(db, address=address, limit=limit, offset=offset)


def get_debits_by_asset(db, asset: str, limit: int = 100, offset: int = 0):
    """
    Returns the debits of an asset
    :param str asset: The asset to return (e.g. XCP)
    :param int limit: The maximum number of debits to return (e.g. 5)
    :param int offset: The offset of the debits to return (e.g. 0)
    """
    return ledger.get_debits(db, asset=asset, limit=limit, offset=offset)


def get_sends_by_block(db, block_index: int, limit: int = 100, offset: int = 0):
    """
    Returns the sends of a block
    :param int block_index: The index of the block to return (e.g. 840459)
    :param int limit: The maximum number of sends to return (e.g. 5)
    :param int offset: The offset of the sends to return (e.g. 0)
    """
    return ledger.get_sends_or_receives(db, block_index=block_index, limit=limit, offset=offset)


def get_sends_by_asset(db, asset: str, limit: int = 100, offset: int = 0):
    """
    Returns the sends of an asset
    :param str asset: The asset to return (e.g. XCP)
    :param int limit: The maximum number of sends to return (e.g. 5)
    :param int offset: The offset of the sends to return (e.g. 0)
    """
    return ledger.get_sends_or_receives(db, asset=asset, limit=limit, offset=offset)


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


def get_issuances_by_block(db, block_index: int):
    """
    Returns the issuances of a block
    :param int block_index: The index of the block to return (e.g. 840464)
    """
    return ledger.get_issuances(db, block_index=block_index)


def get_issuances_by_asset(db, asset: str):
    """
    Returns the issuances of an asset
    :param str asset: The asset to return (e.g. UNNEGOTIABLE)
    """
    return ledger.get_issuances(db, asset=asset)


def get_dispenses_by_block(db, block_index: int):
    """
    Returns the dispenses of a block
    :param int block_index: The index of the block to return (e.g. 840322)
    """
    return ledger.get_dispenses(db, block_index=block_index)


def get_dispenses_by_dispenser(db, dispenser_hash: str):
    """
    Returns the dispenses of a dispenser
    :param str dispenser_hash: The hash of the dispenser to return (e.g. 753787004d6e93e71f6e0aa1e0932cc74457d12276d53856424b2e4088cc542a)
    """
    return ledger.get_dispenses(db, dispenser_tx_hash=dispenser_hash)


def get_dispenses_by_source(db, address: str):
    """
    Returns the dispenses of a source
    :param str address: The address to return (e.g. bc1qlzkcy8c5fa6y6xvd8zn4axnvmhndfhku3hmdpz)
    """
    return ledger.get_dispenses(db, source=address)


def get_dispenses_by_destination(db, address: str):
    """
    Returns the dispenses of a destination
    :param str address: The address to return (e.g. bc1qlzkcy8c5fa6y6xvd8zn4axnvmhndfhku3hmdpz)
    """
    return ledger.get_dispenses(db, destination=address)


def get_dispenses_by_asset(db, asset: str):
    """
    Returns the dispenses of an asset
    :param str asset: The asset to return (e.g. ERYKAHPEPU)
    """
    return ledger.get_dispenses(db, asset=asset)


def get_dispenses_by_source_and_asset(db, address: str, asset: str):
    """
    Returns the dispenses of an address and an asset
    :param str address: The address to return (e.g. bc1qlzkcy8c5fa6y6xvd8zn4axnvmhndfhku3hmdpz)
    :param str asset: The asset to return (e.g. ERYKAHPEPU)
    """
    return ledger.get_dispenses(db, source=address, asset=asset)


def get_dispenses_by_destination_and_asset(db, address: str, asset: str):
    """
    Returns the dispenses of an address and an asset
    :param str address: The address to return (e.g. bc1qlzkcy8c5fa6y6xvd8zn4axnvmhndfhku3hmdpz)
    :param str asset: The asset to return (e.g. ERYKAHPEPU)
    """
    return ledger.get_dispenses(db, destination=address, asset=asset)


def get_sweeps_by_block(db, block_index: int):
    """
    Returns the sweeps of a block
    :param int block_index: The index of the block to return (e.g. 836519)
    """
    return ledger.get_sweeps(db, block_index=block_index)


def get_sweeps_by_address(db, address: str):
    """
    Returns the sweeps of an address
    :param str address: The address to return (e.g. 18szqTVJUWwYrtRHq98Wn4DhCGGiy3jZ87)
    """
    return ledger.get_sweeps(db, address=address)


def get_address_balances(db, address: str):
    """
    Returns the balances of an address
    :param str address: The address to return (e.g. 1C3uGcoSGzKVgFqyZ3kM2DBq9CYttTMAVs)
    """
    return ledger.get_address_balances(db, address=address)


def get_balance_by_address_and_asset(db, address: str, asset: str):
    """
    Returns the balance of an address and asset
    :param str address: The address to return (e.g. 1C3uGcoSGzKVgFqyZ3kM2DBq9CYttTMAVs)
    :param str asset: The asset to return (e.g. XCP)
    """
    return {
        "address": address,
        "asset": asset,
        "quantity": ledger.get_balance(db, address, asset),
    }


def get_bet_by_feed(db, address: str, status: str = "open"):
    """
    Returns the bets of a feed
    :param str address: The address of the feed (e.g. 1QKEpuxEmdp428KEBSDZAKL46noSXWJBkk)
    :param str status: The status of the bet (e.g. filled)
    """
    return ledger.get_bet_by_feed(db, address=address, status=status)


def get_broadcasts_by_source(db, address: str, status: str = "valid", order_by: str = "DESC"):
    """
    Returns the broadcasts of a source
    :param str address: The address to return (e.g. 1QKEpuxEmdp428KEBSDZAKL46noSXWJBkk)
    :param str status: The status of the broadcasts to return (e.g. valid)
    :param str order_by: The order of the broadcasts to return (e.g. ASC)
    """
    return ledger.get_broadcasts_by_source(db, address=address, status=status, order_by=order_by)


def get_burns_by_address(db, address: str):
    """
    Returns the burns of an address
    :param str address: The address to return (e.g. 1HVgrYx3U258KwvBEvuG7R8ss1RN2Z9J1W)
    """
    return ledger.get_burns(db, address=address)


def get_send_by_address(db, address: str, limit: int = 100, offset: int = 0):
    """
    Returns the sends of an address
    :param str address: The address to return (e.g. 1HVgrYx3U258KwvBEvuG7R8ss1RN2Z9J1W)
    :param int limit: The maximum number of sends to return (e.g. 5)
    :param int offset: The offset of the sends to return (e.g. 0)
    """
    return ledger.get_sends(db, address=address, limit=limit, offset=offset)


def get_send_by_address_and_asset(db, address: str, asset: str):
    """
    Returns the sends of an address and asset
    :param str address: The address to return (e.g. 1HVgrYx3U258KwvBEvuG7R8ss1RN2Z9J1W)
    :param str asset: The asset to return (e.g. XCP)
    """
    return ledger.get_sends(db, address=address, asset=asset)


def get_receive_by_address(db, address: str, limit: int = 100, offset: int = 0):
    """
    Returns the receives of an address
    :param str address: The address to return (e.g. 1C3uGcoSGzKVgFqyZ3kM2DBq9CYttTMAVs)
    :param int limit: The maximum number of receives to return (e.g. 5)
    :param int offset: The offset of the receives to return (e.g. 0)
    """
    return ledger.get_receives(db, address=address, limit=limit, offset=offset)


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
    return ledger.get_receives(db, address=address, asset=asset, limit=limit, offset=offset)


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


def get_asset_balances(db, asset: str, exclude_zero_balances: bool = True):
    """
    Returns the asset balances
    :param str asset: The asset to return (e.g. UNNEGOTIABLE)
    :param bool exclude_zero_balances: Whether to exclude zero balances (e.g. True)
    """
    return ledger.get_asset_balances(db, asset=asset, exclude_zero_balances=exclude_zero_balances)


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


def get_bet(db, bet_hash: str):
    """
    Returns the information of a bet
    :param str bet_hash: The hash of the transaction that created the bet (e.g. 5d097b4729cb74d927b4458d365beb811a26fcee7f8712f049ecbe780eb496ed)
    """
    return ledger.get_bet(db, bet_hash=bet_hash)


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


def get_dispenser_info_by_hash(db, dispenser_hash: str):
    """
    Returns the dispenser information by tx_hash
    :param str dispenser_hash: The hash of the dispenser to return (e.g. 753787004d6e93e71f6e0aa1e0932cc74457d12276d53856424b2e4088cc542a)
    """
    return ledger.get_dispenser_info(db, tx_hash=dispenser_hash)
