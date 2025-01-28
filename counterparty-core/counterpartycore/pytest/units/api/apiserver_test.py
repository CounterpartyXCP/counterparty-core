from counterpartycore.lib import config
from counterpartycore.lib.api import apiwatcher, composer
from counterpartycore.lib.api.routes import ALL_ROUTES
from counterpartycore.lib.messages import dividend, sweep


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


def prepare_url(db, current_block_index, defaults, rawtransaction, route):
    if route in ["/v2/transactions/<tx_hash>/info", "/", "/v1/", "/api/", "/rpc/"]:
        return None
    if route.startswith("/v2/bitcoin/"):
        return None
    if "/compose/" in route:
        return None

    last_block = db.execute(
        "SELECT block_hash FROM blocks WHERE block_index = ? ORDER BY block_index DESC LIMIT 1",
        (current_block_index,),
    ).fetchone()
    last_tx = db.execute(
        "SELECT tx_hash, tx_index FROM transactions ORDER BY rowid DESC LIMIT 1"
    ).fetchone()
    utxo_with_balance = db.execute(
        "SELECT * FROM balances WHERE utxo IS NOT null AND quantity > 0 ORDER BY rowid DESC LIMIT 1"
    ).fetchone()
    last_dispenser = db.execute("SELECT * FROM dispensers ORDER BY rowid DESC LIMIT 1").fetchone()
    last_order = db.execute("SELECT * FROM orders ORDER BY rowid DESC LIMIT 1").fetchone()
    last_bet = db.execute("SELECT * FROM bets ORDER BY rowid DESC LIMIT 1").fetchone()
    last_dividend = db.execute("SELECT * FROM dividends ORDER BY rowid DESC LIMIT 1").fetchone()
    last_event = db.execute("SELECT * FROM messages ORDER BY rowid DESC LIMIT 1").fetchone()
    last_issuance = db.execute("SELECT * FROM issuances ORDER BY rowid DESC LIMIT 1").fetchone()
    last_sweep = db.execute("SELECT * FROM sweeps ORDER BY rowid DESC LIMIT 1").fetchone()
    last_broadcast = db.execute("SELECT * FROM broadcasts ORDER BY rowid DESC LIMIT 1").fetchone()
    last_fairminter = db.execute("SELECT * FROM fairminters ORDER BY rowid DESC LIMIT 1").fetchone()
    last_fairmint = db.execute("SELECT * FROM fairmints ORDER BY rowid DESC LIMIT 1").fetchone()

    asset, asset1, asset2 = "XCP", "XCP", "DIVISIBLE"
    datahex = "00000014000000a25be34b66000000174876e800010000000000000000000f446976697369626c65206173736574"

    url = route.replace("<int:block_index>", str(current_block_index))
    url = url.replace("<block_hash>", last_block["block_hash"])
    url = url.replace("<order_hash>", last_order["tx_hash"])
    url = url.replace("<dispenser_hash>", last_dispenser["tx_hash"])
    url = url.replace("<bet_hash>", last_bet["tx_hash"])
    url = url.replace("<dividend_hash>", last_dividend["tx_hash"])
    url = url.replace("<int:tx_index>", str(last_tx["tx_index"]))
    url = url.replace("<int:event_index>", str(last_event["message_index"]))
    url = url.replace("<event>", str(last_event["event"]))
    url = url.replace("<asset>", asset)
    url = url.replace("<asset1>", asset1)
    url = url.replace("<asset2>", asset2)
    url = url.replace("<address>", defaults["addresses"][5])
    url = url.replace("<utxo>", utxo_with_balance["utxo"])

    if url.startswith("/v2/issuances/"):
        url = url.replace("<tx_hash>", last_issuance["tx_hash"])
    elif url.startswith("/v2/sweeps/"):
        url = url.replace("<tx_hash>", last_sweep["tx_hash"])
    elif url.startswith("/v2/broadcasts/"):
        url = url.replace("<tx_hash>", last_broadcast["tx_hash"])
    elif url.startswith("/v2/fairminters/"):
        url = url.replace("<tx_hash>", last_fairminter["tx_hash"])
    elif url.startswith("/v2/fairmints/"):
        url = url.replace("<tx_hash>", last_fairmint["tx_hash"])
    else:
        url = url.replace("<tx_hash>", last_tx["tx_hash"])

    if url == "/v2/transactions/info":
        url = url + "?rawtransaction=" + rawtransaction
    elif url == "/v2/transactions/unpack":
        url = url + "?datahex=" + datahex
    elif url in [
        "/v2/addresses/balances",
        "/v2/addresses/transactions",
        "/v2/addresses/events",
        "/v2/addresses/mempool",
    ]:
        url = url + "?addresses=" + defaults["addresses"][0]
    elif url == "/v2/utxos/withbalances":
        url = url + "?utxos=" + utxo_with_balance["utxo"]

    chr = "&" if "?" in url else "?"
    url = url + chr + "verbose=true"

    return url


def test_all_routes(
    apiv2_client, ledger_db, state_db, current_block_index, defaults, blockchain_mock
):
    # Ass some missing transactions in ledger_db
    tx = blockchain_mock.dummy_tx(ledger_db, defaults["addresses"][0])
    dividend.parse(
        ledger_db,
        tx,
        b"\x00\x00\x00\x00\x05\xf5\xe1\x00\x00\x00\x00\xa2[\xe3Kf\x00\x00\x00\x00\x00\x00\x00\x01",
    )
    tx = blockchain_mock.dummy_tx(ledger_db, defaults["addresses"][0])
    message = b"o\x9c\x8d\x1fT\x05E\x1d\xe6\x07\x0b\xf1\xdb\x86\xabj\xcc\xb4\x95\xb6%\x01"
    sweep.parse(ledger_db, tx, message)
    apiwatcher.catch_up(ledger_db, state_db)

    rawtransaction = composer.compose_transaction(
        ledger_db,
        "attach",
        {
            "source": defaults["addresses"][0],
            "asset": "XCP",
            "quantity": 10,
        },
        {"validate": False},
    )["rawtransaction"]

    routes = list(ALL_ROUTES.keys())
    for route in routes:
        url = prepare_url(ledger_db, current_block_index, defaults, rawtransaction, route)
        if url is not None:
            response = apiv2_client.get(url)
            assert response.status_code == 200
