from counterpartycore.lib import config
from counterpartycore.lib.ledger import caches


def test_asset_cache(ledger_db, defaults):
    ledger_db.execute(
        """
        INSERT INTO destructions (asset, quantity, source, status) 
        VALUES ('foobar', 1000, ?, 'valid')
        """,
        (defaults["addresses"][0],),
    )

    caches.AssetCache(ledger_db).add_issuance(
        {
            "rowid": 1,
            "asset": "foobar",
            "asset_longname": "longfoobar",
            "quantity": 1000,
        }
    )
    assert caches.AssetCache().assets_total_issued["foobar"] == 1000

    caches.AssetCache().add_issuance(
        {
            "asset": "foobar",
            "asset_longname": "longfoobar",
            "quantity": 1000,
        }
    )
    assert caches.AssetCache().assets_total_issued["foobar"] == 2000

    assert caches.AssetCache().assets_total_destroyed["foobar"] == 1000

    caches.AssetCache().add_destroyed(
        {
            "asset": "foobar",
            "asset_longname": "longfoobar",
            "quantity": 500,
        }
    )
    assert caches.AssetCache().assets_total_destroyed["foobar"] == 1500

    caches.AssetCache().add_destroyed(
        {
            "rowid": 1,
            "asset": "foobaz",
            "asset_longname": "longfoobar",
            "quantity": 500,
        }
    )
    assert caches.AssetCache().assets_total_destroyed["foobaz"] == 500


def test_orders_cache(ledger_db):
    orders_count_1 = (
        caches.OrdersCache(ledger_db)
        .cache_db.execute("SELECT COUNT(*) AS count FROM orders")
        .fetchone()["count"]
    )

    caches.OrdersCache(ledger_db).insert_order({"block_index": config.MEMPOOL_BLOCK_INDEX})

    orders_count_2 = (
        caches.OrdersCache(ledger_db)
        .cache_db.execute("SELECT COUNT(*) AS count FROM orders")
        .fetchone()["count"]
    )
    assert orders_count_1 == orders_count_2

    open_orders = (
        caches.OrdersCache(ledger_db)
        .cache_db.execute("SELECT * FROM orders WHERE status = 'open'")
        .fetchall()
    )
    import json

    print(json.dumps(open_orders, indent=4))

    order_1 = open_orders[0]

    caches.OrdersCache(ledger_db).update_order(
        order_1["tx_hash"],
        {
            "status": "expired",
        },
    )
    orders_count_3 = (
        caches.OrdersCache(ledger_db)
        .cache_db.execute("SELECT COUNT(*) AS count FROM orders")
        .fetchone()["count"]
    )
    assert orders_count_1 == orders_count_3 + 1

    matchings = caches.OrdersCache(ledger_db).get_matching_orders(
        order_1["tx_hash"],
        give_asset=order_1["give_asset"],
        get_asset=order_1["get_asset"],
    )
    assert matchings[0]["get_asset"] == order_1["give_asset"]
    assert matchings[0]["give_asset"] == order_1["get_asset"]


def test_utxo_cache(ledger_db):
    caches.UTXOBalancesCache(ledger_db).add_balance("utxo1")
    assert caches.UTXOBalancesCache().has_balance("utxo1")
    caches.UTXOBalancesCache(ledger_db).remove_balance("utxo1")
    assert not caches.UTXOBalancesCache().has_balance("utxo1")
