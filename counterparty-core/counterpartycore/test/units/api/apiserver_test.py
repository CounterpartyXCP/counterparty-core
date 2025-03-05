from counterpartycore.lib import config, ledger
from counterpartycore.lib.api import apiserver, apiwatcher, composer
from counterpartycore.lib.api.routes import ALL_ROUTES
from counterpartycore.lib.messages import dispense, dividend, sweep
from counterpartycore.lib.parser import blocks
from counterpartycore.test.mocks.counterpartydbs import ProtocolChangesDisabled


def test_apiserver_root(apiv2_client, current_block_index):
    response = apiv2_client.get("/v2")
    assert response.status_code == 200
    assert response.json == {
        "result": {
            "server_ready": True,
            "network": "regtest",
            "version": config.VERSION_STRING,
            "backend_height": ledger.currentstate.CurrentState().current_backend_height(),
            "counterparty_height": current_block_index,
            "ledger_state": "Starting",
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
    if "/dispenses/" in route:
        return None

    last_block = db.execute(
        "SELECT block_hash FROM blocks WHERE block_index = ? ORDER BY block_index DESC LIMIT 1",
        (current_block_index,),
    ).fetchone()
    last_tx = db.execute(
        "SELECT tx_hash, tx_index, block_index FROM transactions ORDER BY rowid DESC LIMIT 1"
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

    url = route.replace("<int:block_index>", str(last_tx["block_index"]))
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
    _source, _destination, data = sweep.compose(
        ledger_db, defaults["addresses"][0], defaults["addresses"][1], 1, None, False
    )
    message = data[1:]
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
            assert "result" in response.json
            result = response.json["result"]
            assert isinstance(result, dict) or isinstance(result, list)


def test_new_get_balances_vs_old(apiv1_client, apiv2_client):
    asset = "XCP"
    url = f"/v2/assets/{asset}/balances"
    new_balances = apiv2_client.get(url).json["result"]  # noqa: S113

    old_balance = apiv1_client(
        "get_balances",
        {
            "filters": [
                {"field": "asset", "op": "==", "value": asset},
                {"field": "quantity", "op": "!=", "value": 0},
            ],
        },
    ).json["result"]

    new_balances = sorted(
        new_balances, key=lambda x: (x["address"] or x["utxo"], x["asset"], x["quantity"])
    )
    old_balance = sorted(
        old_balance, key=lambda x: (x["address"] or x["utxo"], x["asset"], x["quantity"])
    )
    assert len(new_balances) == len(old_balance)
    for new_balance, old_balance in zip(new_balances, old_balance):  # noqa: B020
        assert new_balance["address"] == old_balance["address"]
        assert new_balance["utxo"] == old_balance["utxo"]
        assert new_balance["asset"] == old_balance["asset"]
        assert new_balance["quantity"] == old_balance["quantity"]


def test_new_get_asset_info(apiv2_client):
    url = "/v2/assets/NODIVISIBLE"
    result = apiv2_client.get(url).json["result"]

    assert result == {
        "asset": "NODIVISIBLE",
        "asset_longname": None,
        "description": "No divisible asset",
        "description_locked": False,
        "divisible": False,
        "issuer": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc",
        "locked": False,
        "first_issuance_block_index": 104,
        "last_issuance_block_index": 104,
        "asset_id": "1911882621324134",
        "owner": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc",
        "supply": 1000,
    }


def test_invalid_hash(apiv2_client):
    tx_hash = "65e649d58b95602b04172375dbd86783b7379e455a2bc801338d9299d10425a"
    url = f"/v2/orders/{tx_hash}/matches"
    result = apiv2_client.get(url).json
    assert (
        result["error"]
        == "Invalid transaction hash: 65e649d58b95602b04172375dbd86783b7379e455a2bc801338d9299d10425a"
    )


def test_get_dispense(ledger_db, apiv2_client, blockchain_mock, defaults):
    tx = blockchain_mock.dummy_tx(
        ledger_db, defaults["addresses"][0], defaults["addresses"][5], btc_amount=100
    )
    print("Parsing dispense")
    with ProtocolChangesDisabled(["multiple_dispenses"]):
        dispense.parse(ledger_db, tx)

    dispenses = ledger_db.execute("SELECT * FROM dispenses ORDER BY rowid DESC LIMIT 1").fetchone()
    url = f"/v2/dispenses/{dispenses['tx_hash']}"
    result = apiv2_client.get(url).json

    assert result["result"] == {
        "tx_index": dispenses["tx_index"],
        "dispense_index": 1,
        "tx_hash": dispenses["tx_hash"],
        "block_index": 1225,
        "source": defaults["addresses"][5],
        "destination": defaults["addresses"][0],
        "asset": "XCP",
        "dispense_quantity": 100,
        "dispenser_tx_hash": dispenses["dispenser_tx_hash"],
        "btc_amount": 100,
    }


def test_check_database_version(state_db, ledger_db, test_helpers, caplog, monkeypatch):
    config.UPGRADE_ACTIONS["regtest"] = {
        "10.9.1": [("refresh_state_db",), ("reparse", 100), ("rollback", 100)],
    }

    block_first = config.BLOCK_FIRST
    config.BLOCK_FIRST = ledger.blocks.last_db_index(ledger_db)
    with test_helpers.capture_log(caplog, "New database detected. Updating database version."):
        apiserver.check_database_version(state_db)
    config.BLOCK_FIRST = block_first

    config.FORCE = True
    with test_helpers.capture_log(caplog, "FORCE mode enabled. Skipping database version check."):
        apiserver.check_database_version(state_db)
    config.FORCE = False

    version_string = config.VERSION_STRING
    state_db.execute("UPDATE config SET value = '9.0.0' WHERE name = 'VERSION_STRING'")
    config.VERSION_STRING = "9.0.0"
    with test_helpers.capture_log(caplog, "State database is up to date."):
        apiserver.check_database_version(state_db)

    config.VERSION_STRING = "10.9.1"

    def rollback_mock(db, block_index):
        apiserver.logger.info("Rolling back to block %s", block_index)

    def refresh_mock(db):
        apiserver.logger.info("Refreshing state database")

    monkeypatch.setattr("counterpartycore.lib.api.dbbuilder.rollback_state_db", rollback_mock)
    monkeypatch.setattr("counterpartycore.lib.api.dbbuilder.refresh_state_db", refresh_mock)

    with test_helpers.capture_log(
        caplog,
        [
            "Required actions: [('refresh_state_db',), ('reparse', 100), ('rollback', 100)]",
            "Refreshing state database",
            "Rolling back to block 100",
            "Database version number updated.",
        ],
    ):
        apiserver.check_database_version(state_db)

    config.VERSION_STRING = version_string


def test_show_unconfirmed(apiv2_client, ledger_db):
    url = "/v2/transactions?show_unconfirmed=true&limit=1"
    result = apiv2_client.get(url).json["result"]
    assert result[0]["confirmed"]

    url = "/v2/transactions?limit=1"
    result = apiv2_client.get(url).json["result"]
    assert "confirmed" not in result[0]

    ledger_db.execute(
        """INSERT INTO mempool_transactions VALUES(
            :tx_index, :tx_hash, :block_index, :block_hash, :block_time, :source, :destination, :btc_amount, :fee,
            :data, :supported, :utxos_info, :transaction_type
        )""",
        {
            "tx_index": 9999999,
            "tx_hash": "tx_hash",
            "block_index": 9999999,
            "block_hash": "mempool",
            "block_time": 9999999,
            "source": "source",
            "destination": "destination",
            "btc_amount": 9999999,
            "fee": 0,
            "data": b"",
            "supported": True,
            "utxos_info": "",
            "transaction_type": "send",
        },
    )

    url = "/v2/transactions?show_unconfirmed=true&limit=1"
    result = apiv2_client.get(url).json["result"]
    assert not result[0]["confirmed"]


def test_ledger_state(apiv2_client, current_block_index, ledger_db):
    blocks.rollback(ledger_db, current_block_index - 10)
    response = apiv2_client.get("/v2")
    assert response.status_code == 200
    assert response.json == {
        "result": {
            "server_ready": True,
            "network": "regtest",
            "version": config.VERSION_STRING,
            "backend_height": ledger.currentstate.CurrentState().current_backend_height(),
            "counterparty_height": current_block_index,
            "ledger_state": "Rolling Back",
            "documentation": "https://counterpartycore.docs.apiary.io/",
            "routes": "http://localhost/v2/routes",
            "blueprint": "https://raw.githubusercontent.com/CounterpartyXCP/counterparty-core/refs/heads/master/apiary.apib",
        }
    }

    blocks.reparse(ledger_db, current_block_index - 20)
    response = apiv2_client.get("/v2")
    assert response.status_code == 200
    assert response.json == {
        "result": {
            "server_ready": True,
            "network": "regtest",
            "version": config.VERSION_STRING,
            "backend_height": ledger.currentstate.CurrentState().current_backend_height(),
            "counterparty_height": current_block_index,
            "ledger_state": "Reparsing",
            "documentation": "https://counterpartycore.docs.apiary.io/",
            "routes": "http://localhost/v2/routes",
            "blueprint": "https://raw.githubusercontent.com/CounterpartyXCP/counterparty-core/refs/heads/master/apiary.apib",
        }
    }


def test_get_transactions(apiv2_client, monkeypatch):
    url = "/v2/transactions?limit=1&verbose=true"
    result = apiv2_client.get(url).json["result"]
    assert len(result) == 1
    assert "unpacked_data" in result[0]
    assert "message_data" in result[0]["unpacked_data"]

    def unpack_mock(*args):
        raise Exception("Unpack error")

    monkeypatch.setattr("counterpartycore.lib.api.compose.unpack", unpack_mock)
    result = apiv2_client.get(url).json["result"]
    assert len(result) == 1
    assert "unpacked_data" in result[0]
    assert "error" in result[0]["unpacked_data"]
    assert result[0]["unpacked_data"]["error"] == "Could not unpack data"


def test_get_all_transactions_verbose(apiv2_client):
    url = "/v2/transactions?verbose=true&show_unconfirmed=true"
    result = apiv2_client.get(url).json["result"]
    for tx in result:
        assert "unpacked_data" in tx
        assert "message_data" in tx["unpacked_data"]
