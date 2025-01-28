from counterpartycore.lib import config
from counterpartycore.lib.api import composer
from counterpartycore.lib.api.routes import ALL_ROUTES


def test_apiserver_root(apiv2_client, current_block_index):
    response = apiv2_client.get("/v2")
    assert response.status_code == 200
    assert response.json == {
        "result": {
            "server_ready": True,
            "network": "regtest",
            "version": config.VERSION_STRING,
            "backend_height": current_block_index,
            "counterparty_height": current_block_index,
            "documentation": "https://counterpartycore.docs.apiary.io/",
            "routes": "http://localhost/v2/routes",
            "blueprint": "https://raw.githubusercontent.com/CounterpartyXCP/counterparty-core/refs/heads/master/apiary.apib",
        }
    }


def prepare_routes(ledger_db, current_block_index, defaults, route):
    if route in [
        "/v2/transactions/<tx_hash>/info",
    ]:
        return None

    last_block = ledger_db.execute(
        "SELECT block_hash FROM blocks WHERE block_index = ? ORDER BY block_index DESC LIMIT 1",
        (current_block_index,),
    ).fetchone()
    last_tx = ledger_db.execute(
        "SELECT tx_hash, tx_index FROM transactions ORDER BY rowid DESC LIMIT 1"
    ).fetchone()
    utxo_with_balance = ledger_db.execute(
        "SELECT * FROM balances WHERE utxo IS NOT null AND quantity > 0 ORDER BY rowid DESC LIMIT 1"
    ).fetchone()
    asset, asset1, asset2 = "XCP", "XCP", "DIVISIBLE"

    rawtransaction = composer.compose_transaction(
        ledger_db,
        "attach",
        {
            "source": defaults["addresses"][0],
            "asset": "XCP",
            "quantity": 10,
        },
        {},
    )["rawtransaction"]
    print(rawtransaction)

    new_routes = route.replace("<int:block_index>", str(current_block_index))
    new_routes = new_routes.replace("<block_hash>", last_block["block_hash"])
    new_routes = new_routes.replace("<tx_hash>", last_tx["tx_hash"])
    new_routes = new_routes.replace("<int:tx_index>", str(last_tx["tx_index"]))
    new_routes = new_routes.replace("<asset>", asset)
    new_routes = new_routes.replace("<asset1>", asset1)
    new_routes = new_routes.replace("<asset2>", asset2)
    new_routes = new_routes.replace("<address>", defaults["addresses"][0])
    new_routes = new_routes.replace("<utxo>", utxo_with_balance["utxo"])

    if new_routes == "/v2/transactions/info":
        new_routes = new_routes + "?rawtransaction=" + rawtransaction

    return new_routes


def test_all_routes(apiv2_client, ledger_db, current_block_index, defaults):
    routes = list(ALL_ROUTES.keys())

    for route in routes:
        final_route = prepare_routes(ledger_db, current_block_index, defaults, route)
        print("ROUTE", final_route)
        if final_route is not None:
            response = apiv2_client.get(final_route)
            assert response.status_code == 200
