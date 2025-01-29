def test_consolidated_balances(state_db, ledger_db, apiv2_client):
    # balances
    sql_ledger = (
        "SELECT count(*) AS count FROM (SELECT *, MAX(rowid) FROM balances GROUP BY address, asset)"
    )
    sql_api = "SELECT count(*) AS count FROM balances"
    assert (
        ledger_db.execute(sql_ledger).fetchone()["count"]
        == state_db.execute(sql_api).fetchone()["count"]
    )

    ledger_balances = ledger_db.execute(
        "SELECT *, MAX(rowid) FROM balances GROUP BY address, asset ORDER BY asset, address"
    ).fetchall()
    api_balances = state_db.execute("SELECT * FROM balances ORDER BY asset, address").fetchall()
    assert len(ledger_balances) == len(api_balances)
    for ledger_balance, api_balance in zip(ledger_balances, api_balances):
        assert ledger_balance["address"] == api_balance["address"]
        assert ledger_balance["asset"] == api_balance["asset"]
        assert ledger_balance["quantity"] == api_balance["quantity"]
        if ledger_balance["quantity"] > 0 and ledger_balance["address"]:
            api_result = apiv2_client.get(
                f"/v2/addresses/{ledger_balance['address']}/balances/{ledger_balance['asset']}"
            ).json
            found = False
            for balance in api_result["result"]:
                if balance["quantity"] == ledger_balance["quantity"]:
                    found = True
                    break
            assert found


def test_consolidated_orders(state_db, ledger_db, apiv2_client):
    sql_ledger = "SELECT count(*) AS count FROM (SELECT *, MAX(rowid) FROM orders GROUP BY tx_hash)"
    sql_api = "SELECT count(*) AS count FROM orders"
    assert (
        ledger_db.execute(sql_ledger).fetchone()["count"]
        == state_db.execute(sql_api).fetchone()["count"]
    )

    ledger_orders = ledger_db.execute(
        "SELECT *, MAX(rowid) FROM orders GROUP BY tx_hash ORDER BY tx_hash"
    ).fetchall()
    for ledger_order in ledger_orders:
        api_order = state_db.execute(
            "SELECT * FROM orders WHERE tx_hash = ?", (ledger_order["tx_hash"],)
        ).fetchone()
        assert ledger_order["status"] == api_order["status"]
        assert ledger_order["give_asset"] == api_order["give_asset"]
        assert ledger_order["get_asset"] == api_order["get_asset"]
        assert ledger_order["get_remaining"] == api_order["get_remaining"]
        assert ledger_order["give_remaining"] == api_order["give_remaining"]
        assert ledger_order["source"] == api_order["source"]
        api_result = apiv2_client.get(f"/v2/orders/{ledger_order['tx_hash']}").json
        assert api_result["result"]["status"] == ledger_order["status"]
        assert api_result["result"]["give_asset"] == ledger_order["give_asset"]
        assert api_result["result"]["get_asset"] == ledger_order["get_asset"]
        assert api_result["result"]["get_remaining"] == ledger_order["get_remaining"]
        assert api_result["result"]["give_remaining"] == ledger_order["give_remaining"]
        assert api_result["result"]["source"] == ledger_order["source"]


def test_consolidated_order_matches(state_db, ledger_db, apiv2_client):
    sql_ledger = (
        "SELECT count(*) AS count FROM (SELECT *, MAX(rowid) FROM order_matches GROUP BY id)"
    )
    sql_api = "SELECT count(*) AS count FROM order_matches"
    assert (
        ledger_db.execute(sql_ledger).fetchone()["count"]
        == state_db.execute(sql_api).fetchone()["count"]
    )

    ledger_order_matches = ledger_db.execute(
        "SELECT *, MAX(rowid) FROM order_matches GROUP BY id ORDER BY id"
    ).fetchall()
    api_order_matches = state_db.execute("SELECT * FROM order_matches ORDER BY id").fetchall()
    assert len(ledger_order_matches) == len(api_order_matches)
    for ledger_order_match, api_order_match in zip(ledger_order_matches, api_order_matches):
        assert ledger_order_match["id"] == api_order_match["id"]
        assert ledger_order_match["status"] == api_order_match["status"]
        assert ledger_order_match["tx0_hash"] == api_order_match["tx0_hash"]
        assert ledger_order_match["tx1_hash"] == api_order_match["tx1_hash"]
        api_result = apiv2_client.get(f"/v2/orders/{api_order_match['tx0_hash']}/matches").json
        found = False
        for order_match in api_result["result"]:
            if order_match["id"] == ledger_order_match["id"]:
                assert ledger_order_match["status"] == order_match["status"]
                assert ledger_order_match["tx0_hash"] == order_match["tx0_hash"]
                assert ledger_order_match["tx1_hash"] == order_match["tx1_hash"]
                found = True
                break
        assert found


def test_consolidated_assets(state_db, ledger_db, apiv2_client):
    sql_ledger = "SELECT count(*) AS count FROM assets WHERE asset_name NOT IN ('XCP', 'BTC')"
    sql_api = "SELECT count(*) AS count FROM assets_info WHERE asset NOT IN ('XCP', 'BTC')"
    assert (
        ledger_db.execute(sql_ledger).fetchone()["count"]
        == state_db.execute(sql_api).fetchone()["count"]
    )

    ledger_assets_info = ledger_db.execute(
        "SELECT asset_name FROM assets WHERE asset_name NOT IN ('XCP', 'BTC') ORDER BY asset_name"
    ).fetchall()
    api_assets_info = state_db.execute(
        "SELECT asset FROM assets_info WHERE asset NOT IN ('XCP', 'BTC') ORDER BY asset"
    ).fetchall()
    assert len(ledger_assets_info) == len(api_assets_info)
    for ledger_asset_info, api_asset_info in zip(ledger_assets_info, api_assets_info):
        assert ledger_asset_info["asset_name"] == api_asset_info["asset"]
        api_result = apiv2_client.get(f"/v2/assets/{api_asset_info['asset']}").json
        assert api_result["result"]["asset"] == api_asset_info["asset"]
