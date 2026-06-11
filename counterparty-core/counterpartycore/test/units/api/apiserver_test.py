from unittest.mock import Mock

import pytest
from counterpartycore.lib import config, ledger
from counterpartycore.lib.api import apiserver, apiwatcher, composer
from counterpartycore.lib.api.routes import ALL_ROUTES, ROUTES
from counterpartycore.lib.messages import dispense, dividend, sweep
from counterpartycore.lib.parser import blocks
from counterpartycore.lib.utils import helpers
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
            "current_commit": helpers.get_current_commit_hash(),
        }
    }


def _sort_arg(route):
    return next((arg for arg in ROUTES[route]["args"] if arg["name"] == "sort"), None)


def test_routes_document_sort_fields():
    orders_sort_arg = _sort_arg("/v2/orders")

    assert orders_sort_arg["supported_values"] == [
        "block_index",
        "give_asset",
        "give_quantity",
        "get_asset",
        "get_quantity",
        "expiration",
        "give_price",
        "get_price",
    ]
    assert "Sortable fields:" in orders_sort_arg["description"]


def test_routes_document_sort_fields_match_query_table():
    # Routes whose query table differs from their route category must document
    # the fields of the table actually queried, not the category's fields.
    cases = {
        "/v2/order_matches": [
            "block_index",
            "forward_asset",
            "forward_quantity",
            "backward_asset",
            "backward_quantity",
            "match_expire_index",
        ],
        "/v2/dispenses": [
            "block_index",
            "asset",
            "dispense_quantity",
            "btc_amount",
        ],
        "/v2/pool_matches": [
            "block_index",
            "forward_quantity",
            "backward_quantity",
        ],
        # Previously undocumented: category "assets" is not a sort table key.
        "/v2/issuances": [
            "block_index",
            "asset",
            "asset_longname",
            "quantity",
            "fee_paid",
        ],
    }
    for route, expected in cases.items():
        sort_arg = _sort_arg(route)
        assert sort_arg is not None, route
        assert sort_arg["supported_values"] == expected, route
        assert "Sortable fields:" in sort_arg["description"], route


def test_routes_do_not_expose_unsupported_sort():
    # get_balances_by_addresses builds its own SQL and cannot honour `sort`
    # (its result is grouped/aggregated), so the route must not expose it at all.
    assert _sort_arg("/v2/addresses/balances") is None


def get_route_args(route, name):
    return [arg for arg in ROUTES[route]["args"] if arg["name"] == name]


def test_routes_only_document_available_verbose_args():
    assert get_route_args("/v2/transactions", "verbose")
    assert get_route_args("/v2/orders", "verbose")

    assert not get_route_args("/v2/routes", "verbose")
    assert not get_route_args("/v2/healthz", "verbose")
    assert not get_route_args("/healthz", "verbose")
    assert not get_route_args("/v2/bitcoin/getmempoolinfo", "verbose")
    assert not get_route_args("/v2/addresses/<address>/compose/dividend/estimatexcpfees", "verbose")

    compose_verbose_args = get_route_args("/v2/addresses/<address>/compose/send", "verbose")
    assert len(compose_verbose_args) == 1
    assert compose_verbose_args[0]["category"] == "secondary"


def test_routes_only_document_available_show_unconfirmed_args():
    assert get_route_args("/v2/transactions", "show_unconfirmed")
    assert get_route_args("/v2/blocks/<int:block_index>/transactions", "show_unconfirmed")

    assert not get_route_args("/v2/transactions/counts", "show_unconfirmed")
    assert not get_route_args("/v2/routes", "show_unconfirmed")


def prepare_url(db, current_block_index, defaults, rawtransaction, route):
    if route in ["/v2/transactions/<tx_hash>/info", "/", "/v1/", "/api/", "/rpc/"]:
        return None
    if route.startswith("/v2/bitcoin/"):
        return None
    if "/compose/" in route:
        return None
    if "/dispenses/" in route:
        return None
    if "/quote/" in route:
        return None
    if "/pools/" in route or route == "/v2/pools":
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
    for new_balance, old_balance in zip(new_balances, old_balance, strict=True):  # noqa: B020
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
        "mime_type": "text/plain",
    }


def test_get_address_dispensers_by_source_and_origin(state_db, apiv2_client, defaults):
    source_address = defaults["addresses"][0]
    origin_address = defaults["addresses"][1]
    state_db.execute(
        "INSERT INTO assets_info (asset, divisible) VALUES (?, ?)",
        ("ORIGINAPI", False),
    )
    for tx_index, tx_hash, source, origin in [
        (9201, "f" * 64, source_address, origin_address),
        (9202, "1" * 64, origin_address, origin_address),
        (9203, "2" * 64, source_address, defaults["addresses"][2]),
    ]:
        state_db.execute(
            """
            INSERT INTO dispensers (
                tx_index, tx_hash, block_index, source, asset, give_quantity,
                escrow_quantity, satoshirate, status, give_remaining, origin,
                dispense_count
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            """,
            (
                tx_index,
                tx_hash,
                tx_index,
                source,
                "ORIGINAPI",
                1,
                1,
                100,
                0,
                1,
                origin,
                0,
            ),
        )

    source_response = apiv2_client.get(
        f"/v2/addresses/{source_address}/dispensers/source?sort=block_index:asc"
    )
    origin_response = apiv2_client.get(
        f"/v2/addresses/{origin_address}/dispensers/origin?sort=block_index:asc"
    )

    assert source_response.status_code == 200
    assert origin_response.status_code == 200
    assert [row["tx_hash"] for row in source_response.json["result"]] == ["f" * 64, "2" * 64]
    assert [row["tx_hash"] for row in origin_response.json["result"]] == ["f" * 64, "1" * 64]


def test_get_asset_by_longname_case_insensitive(state_db, apiv2_client):
    """Test that asset lookup by longname is case-insensitive (uses COLLATE NOCASE)."""
    # Insert a test asset with mixed-case longname directly into state_db
    cursor = state_db.cursor()
    cursor.execute(
        """
        INSERT INTO assets_info (asset, asset_id, asset_longname, divisible, supply, description, issuer, owner, first_issuance_block_index, last_issuance_block_index)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        """,
        (
            "A12345678901234567",  # numeric asset name
            "12345678901234567",
            "PARENT.MixedCaseChild",  # mixed-case longname
            True,
            100,
            "Test subasset",
            "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc",
            "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc",
            100,
            100,
        ),
    )

    # Query with UPPERCASE longname - should still find the asset
    url = "/v2/assets/PARENT.MIXEDCASECHILD"
    result = apiv2_client.get(url).json["result"]

    assert result is not None, "Asset should be found with case-insensitive lookup"
    assert result["asset_longname"] == "PARENT.MixedCaseChild"
    assert result["description"] == "Test subasset"


def test_invalid_hash(apiv2_client):
    tx_hash = "65e649d58b95602b04172375dbd86783b7379e455a2bc801338d9299d10425a"
    url = f"/v2/orders/{tx_hash}/matches"
    result = apiv2_client.get(url).json
    assert (
        result["error"]
        == "Invalid transaction hash: 65e649d58b95602b04172375dbd86783b7379e455a2bc801338d9299d10425a"
    )


def test_get_dispense(ledger_db, apiv2_client, blockchain_mock, defaults, current_block_index):
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
        "block_index": dispenses["block_index"],
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
            "current_commit": helpers.get_current_commit_hash(),
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
            "current_commit": helpers.get_current_commit_hash(),
        }
    }


def test_api_cache_control_headers(apiv2_client, monkeypatch):
    monkeypatch.setattr(config, "DISABLE_API_CACHE", False)

    response = apiv2_client.get("/v2/blocks")
    assert response.status_code == 200
    assert response.headers["Cache-Control"] == "public, max-age=60"

    response = apiv2_client.get("/v2/transactions?show_unconfirmed=true&limit=1")
    assert response.status_code == 200
    assert response.headers["Cache-Control"] == "no-store"

    response = apiv2_client.get("/v2/healthz")
    assert response.status_code == 200
    assert response.headers["Cache-Control"] == "no-store"

    response = apiv2_client.get("/v2/transactions?limit=0")
    assert response.status_code == 400
    assert response.headers["Cache-Control"] == "no-store"


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


def test_sentry_context_includes_http_error_returned_to_user(apiv2_client, monkeypatch):
    class FakeSentryScope:
        def __init__(self):
            self.contexts = {}

        def __enter__(self):
            return self

        def __exit__(self, _exc_type, _exc_value, _traceback):
            return False

        def set_transaction_name(self, _name):
            pass

        def set_context(self, name, data):
            self.contexts[name] = data

    scope = FakeSentryScope()
    captured = []

    def execute_api_function_mock(_rule, _route, _function_args):
        raise RuntimeError("boom")

    def capture_exception_mock(error):
        captured.append(error)
        assert scope.contexts["api_response"] == {
            "status_code": 503,
            "error": "Unknown error",
            "method": "GET",
            "path": "/v2/transactions",
        }

    monkeypatch.setattr(apiserver, "configure_sentry_scope", lambda: scope)
    monkeypatch.setattr(apiserver, "execute_api_function", execute_api_function_mock)
    monkeypatch.setattr(apiserver, "capture_exception", capture_exception_mock)

    response = apiv2_client.get("/v2/transactions?limit=1")

    assert response.status_code == 503
    assert response.json["error"] == "Unknown error"
    assert len(captured) == 1
    assert isinstance(captured[0], RuntimeError)


def test_sentry_context_includes_outer_http_error_returned_to_user(apiv2_client, monkeypatch):
    class FakeSentryScope:
        def __init__(self):
            self.contexts = {}

        def __enter__(self):
            return self

        def __exit__(self, _exc_type, _exc_value, _traceback):
            return False

        def set_transaction_name(self, _name):
            pass

        def set_context(self, name, data):
            self.contexts[name] = data

    scope = FakeSentryScope()
    captured = []

    def capture_exception_mock(error):
        captured.append(error)
        assert scope.contexts["api_response"] == {
            "status_code": 500,
            "error": "Internal server error",
            "method": "GET",
            "path": "/v2/transactions",
        }

    monkeypatch.setattr(apiserver, "configure_sentry_scope", lambda: scope)
    monkeypatch.setattr(apiserver, "capture_exception", capture_exception_mock)
    monkeypatch.setattr(
        apiserver.verbose,
        "clean_api_result",
        lambda _result: (_ for _ in ()).throw(RuntimeError("post-processing failed")),
    )

    response = apiv2_client.get("/v2/transactions?limit=1")

    assert response.status_code == 500
    assert response.json["error"] == "Internal server error"
    assert len(captured) == 1
    assert isinstance(captured[0], RuntimeError)


def test_rejects_unknown_query_parameters(apiv2_client):
    response = apiv2_client.get("/v2/transactions?limit=1&unknown_param=1&another_bad=2")

    assert response.status_code == 400
    assert response.json["error"] == "Unrecognized parameter(s): another_bad, unknown_param"


def test_verbose_query_parameter_is_still_allowed(apiv2_client):
    response = apiv2_client.get("/v2/transactions?limit=1&verbose=true")

    assert response.status_code == 200
    assert "unpacked_data" in response.json["result"][0]


def test_get_all_transactions_verbose(apiv2_client):
    url = "/v2/transactions?verbose=true&show_unconfirmed=true"
    result = apiv2_client.get(url).json["result"]
    for tx in result:
        assert "unpacked_data" in tx
        assert "message_data" in tx["unpacked_data"]


def test_get_address_options(apiv2_client, defaults):
    result = apiv2_client.get(f"/v2/addresses/{defaults['addresses'][4]}").json["result"]
    assert result == {
        "address": defaults["addresses"][4],
        "options": 0,
        "block_index": None,
    }

    result = apiv2_client.get(f"/v2/addresses/{defaults['addresses'][4]}/options").json["result"]
    assert result == {
        "address": defaults["addresses"][4],
        "options": 0,
        "block_index": None,
    }


def test_get_balances_by_addresses(apiv2_client, defaults):
    url = f"/v2/addresses/balances?addresses={defaults['addresses'][0]}&verbose=true"
    result = apiv2_client.get(url).json["result"]

    assert result[0]["asset"] == "A95428956773044873"
    assert result[1]["asset"] == "A95428959342453541"
    assert result[2]["asset"] == "CALLABLE"
    assert result[3]["asset"] == "DIVISIBLE"
    assert result[4]["asset"] == "FREEFAIRMIN"
    assert result[5]["asset"] == "LOCKED"
    assert result[6]["asset"] == "MAXI"
    assert result[7]["asset"] == "NODIVISIBLE"
    assert result[8]["asset"] == "PARENT"
    assert result[9]["asset"] == "POOLASSETA"
    assert result[10]["asset"] == "POOLASSETB"
    assert result[11]["asset"] == "RAIDFAIRMIN"
    assert result[12]["asset"] == "TAIDFAIRMIN"
    assert result[13]["asset"] == "XCP"

    for balance in result[9]["addresses"]:
        assert (
            balance["address"] == defaults["addresses"][0]
            or balance["utxo_address"] == defaults["addresses"][0]
        )

    url = f"/v2/addresses/balances?addresses={defaults['addresses'][0]}&verbose=true&asset=A95428959342453541"
    result = apiv2_client.get(url).json["result"]
    assert len(result) == 1
    assert result[0]["asset"] == "A95428959342453541"
    for balance in result[0]["addresses"]:
        assert (
            balance["address"] == defaults["addresses"][0]
            or balance["utxo_address"] == defaults["addresses"][0]
        )

    url = f"/v2/addresses/balances?addresses={defaults['addresses'][0]}&verbose=true&asset=NODIVISIBLE"
    result = apiv2_client.get(url).json["result"]
    assert len(result) == 1
    assert result[0]["asset"] == "NODIVISIBLE"
    for balance in result[0]["addresses"]:
        assert (
            balance["address"] == defaults["addresses"][0]
            or balance["utxo_address"] == defaults["addresses"][0]
        )

    url = f"/v2/addresses/balances?addresses={defaults['addresses'][0]}&verbose=true&asset=A95428959342453541&type=address"
    result = apiv2_client.get(url).json["result"]
    assert len(result) == 1
    assert result[0]["asset"] == "A95428959342453541"
    for balance in result[0]["addresses"]:
        assert balance["address"] == defaults["addresses"][0]

    url = f"/v2/addresses/balances?addresses={defaults['addresses'][0]}&verbose=true&asset=A95428959342453541&type=utxo"
    result = apiv2_client.get(url).json["result"]
    assert len(result) == 0

    url = f"/v2/addresses/{defaults['addresses'][0]}/balances/PARENT.already.issued?verbose=true"
    result = apiv2_client.get(url).json["result"]
    assert len(result) > 0
    assert result[0]["asset"] == "A95428959342453541"
    assert result[0]["asset_longname"] == "PARENT.already.issued"

    url = "/v2/assets/PARENT.already.issued/balances?verbose=true"
    result = apiv2_client.get(url).json["result"]
    assert len(result) > 0
    assert result[0]["asset"] == "A95428959342453541"
    assert result[0]["asset_longname"] == "PARENT.already.issued"


def test_get_transactions_valid(apiv2_client, monkeypatch):
    url = "/v2/transactions"
    result = apiv2_client.get(url).json["result"]

    for tx in result:
        assert tx["valid"]

    url = "/v2/transactions?valid=false"
    result = apiv2_client.get(url).json["result"]
    assert len(result) == 0

    url = "/v2/transactions?show_unconfirmed=true"
    result = apiv2_client.get(url).json["result"]

    for tx in result:
        assert tx["valid"]

    url = "/v2/transactions?valid=false&show_unconfirmed=true"
    result = apiv2_client.get(url).json["result"]
    assert len(result) == 0


def test_transaction_valid_flag_without_verbose(apiv2_client, ledger_db):
    last_tx = ledger_db.execute(
        "SELECT tx_index, block_index, block_hash, block_time FROM transactions ORDER BY tx_index DESC LIMIT 1"
    ).fetchone()
    tx_index = last_tx["tx_index"] + 1
    tx_hash = "f" * 64
    ledger_db.execute(
        """
        INSERT INTO transactions(
            tx_index, tx_hash, block_index, block_hash, block_time, source, destination,
            btc_amount, fee, data, supported, utxos_info, transaction_type
        )
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        """,
        (
            tx_index,
            tx_hash,
            last_tx["block_index"],
            last_tx["block_hash"],
            last_tx["block_time"],
            "source",
            "",
            0,
            0,
            b"\x0c",
            True,
            "",
            "send",
        ),
    )
    ledger.blocks.set_transaction_status(ledger_db, tx_index, False)
    ledger_db.execute("PRAGMA wal_checkpoint(TRUNCATE)")
    apiserver.LedgerDBConnectionPool().close()
    apiserver.BLOCK_CACHE.clear()

    result = apiv2_client.get(f"/v2/transactions/{tx_hash}").json["result"]
    assert result["valid"] is False
    assert "unpacked_data" not in result

    result = apiv2_client.get("/v2/transactions?valid=false&limit=1").json["result"]
    assert result[0]["valid"] is False


def test_order_prices(apiv2_client, defaults):
    url = "/v2/assets/NODIVISIBLE/orders"
    result = apiv2_client.get(url).json["result"]
    assert result[0]["give_price"] == 100000000
    assert result[0]["get_price"] == 0.00000001

    url = "/v2/assets/DIVISIBLE/orders"
    result = apiv2_client.get(url).json["result"]
    assert result[0]["give_price"] == 1
    assert result[0]["get_price"] == 1


def test_issuances_boolean_fields(apiv2_client):
    url = "/v2/issuances?verbose=true"
    result = apiv2_client.get(url).json["result"]
    assert isinstance(result[0]["divisible"], bool)
    assert isinstance(result[0]["locked"], bool)
    assert isinstance(result[0]["reset"], bool)
    assert isinstance(result[0]["callable"], bool)
    assert result[0]["divisible"]
    assert not result[0]["locked"]
    assert not result[0]["reset"]
    assert not result[0]["callable"]

    assert isinstance(result[1]["divisible"], bool)
    assert isinstance(result[1]["locked"], bool)
    assert isinstance(result[1]["reset"], bool)
    assert isinstance(result[1]["callable"], bool)
    assert result[1]["divisible"]
    assert not result[1]["locked"]
    assert not result[1]["reset"]
    assert not result[1]["callable"]


def test_get_balances_by_addresses_pagination(apiv2_client, defaults):
    # Test basic functionality
    addresses = f"{defaults['addresses'][0]},{defaults['addresses'][1]}"
    url = f"/v2/addresses/balances?addresses={addresses}&verbose=true"
    response = apiv2_client.get(url)
    assert response.status_code == 200
    result = response.json["result"]
    assert len(result) > 0
    assert "next_cursor" in response.json
    assert "result_count" in response.json

    # Test pagination with limit
    url_paginated = f"/v2/addresses/balances?addresses={addresses}&limit=3&verbose=true"
    response_paginated = apiv2_client.get(url_paginated)
    assert response_paginated.status_code == 200
    paginated_result = response_paginated.json["result"]
    assert len(paginated_result) == 3
    assert response_paginated.json["next_cursor"] is not None

    # Test pagination with cursor
    cursor = response_paginated.json["next_cursor"]
    url_cursor = (
        f"/v2/addresses/balances?addresses={addresses}&limit=3&cursor={cursor}&verbose=true"
    )
    response_cursor = apiv2_client.get(url_cursor)
    assert response_cursor.status_code == 200
    cursor_result = response_cursor.json["result"]
    assert len(cursor_result) > 0
    # First asset should be >= cursor asset
    assert cursor_result[0]["asset"] >= cursor

    # Test asset filtering
    url_asset = f"/v2/addresses/balances?addresses={addresses}&asset=XCP&verbose=true"
    response_asset = apiv2_client.get(url_asset)
    assert response_asset.status_code == 200
    asset_result = response_asset.json["result"]
    assert len(asset_result) == 1
    assert asset_result[0]["asset"] == "XCP"
    assert response_asset.json["next_cursor"] is None
    assert response_asset.json["result_count"] == 1

    # Test that next_cursor is None when using sort (cursor is ignored with sort)
    # Using /v2/orders which uses select_rows with sort support
    # First verify that without sort, we get a next_cursor when there are more results
    url_no_sort = "/v2/orders?limit=1"
    response_no_sort = apiv2_client.get(url_no_sort)
    assert response_no_sort.status_code == 200
    assert response_no_sort.json["result_count"] > 1  # fixtures have 7 orders
    assert response_no_sort.json["next_cursor"] is not None
    # Now verify that with sort, next_cursor is None to avoid infinite loops
    url_sorted = "/v2/orders?limit=1&sort=expiration:desc"
    response_sorted = apiv2_client.get(url_sorted)
    assert response_sorted.status_code == 200
    assert response_sorted.json["next_cursor"] is None


def redirect_to_api_v1():
    pass


def dummy_function():
    pass


@pytest.mark.parametrize(
    "test_case,method,path,url,rule,route,result,cache_disabled,expected",
    [
        (
            "cache_disabled",
            "GET",
            "/v2/blocks",
            "http://localhost/v2/blocks",
            "/v2/blocks",
            {"function": dummy_function},
            {"data": "test"},
            True,
            False,
        ),
        (
            "post_method",
            "POST",
            "/v2/blocks",
            "http://localhost/v2/blocks",
            "/v2/blocks",
            {"function": dummy_function},
            {"data": "test"},
            False,
            False,
        ),
        (
            "compose_endpoint",
            "GET",
            "/v2/compose/send",
            "http://localhost/v2/compose/send",
            "/v2/compose/send",
            {"function": dummy_function},
            {"data": "test"},
            False,
            False,
        ),
        (
            "mempool_in_rule",
            "GET",
            "/v2/mempool",
            "http://localhost/v2/mempool",
            "/v2/mempool/",
            {"function": dummy_function},
            {"data": "test"},
            False,
            False,
        ),
        (
            "healthz_endpoint",
            "GET",
            "/healthz",
            "http://localhost/healthz",
            "/healthz",
            {"function": dummy_function},
            {"data": "test"},
            False,
            False,
        ),
        (
            "none_result",
            "GET",
            "/v2/blocks",
            "http://localhost/v2/blocks",
            "/v2/blocks",
            {"function": dummy_function},
            None,
            False,
            False,
        ),
        (
            "redirect_to_api_v1",
            "GET",
            "/v1/something",
            "http://localhost/v1/something",
            "/v1/something",
            {"function": redirect_to_api_v1},
            {"data": "test"},
            False,
            False,
        ),
        (
            "mempool_path",
            "GET",
            "/v2/mempool/transactions",
            "http://localhost/v2/mempool/transactions",
            "/v2/mempool/transactions",
            {"function": dummy_function},
            {"data": "test"},
            False,
            False,
        ),
        (
            "addresses_mempool",
            "GET",
            "/v2/addresses/mempool",
            "http://localhost/v2/addresses/mempool",
            "/v2/addresses/mempool",
            {"function": dummy_function},
            {"data": "test"},
            False,
            False,
        ),
        (
            "show_unconfirmed",
            "GET",
            "/v2/transactions",
            "http://localhost/v2/transactions?show_unconfirmed=true",
            "/v2/transactions",
            {"function": dummy_function},
            {"data": "test"},
            False,
            False,
        ),
        (
            "valid_case",
            "GET",
            "/v2/blocks",
            "http://localhost/v2/blocks",
            "/v2/blocks",
            {"function": dummy_function},
            {"data": "test"},
            False,
            True,
        ),
        (
            "route_none",
            "GET",
            "/v2/blocks",
            "http://localhost/v2/blocks",
            "/v2/blocks",
            None,
            {"data": "test"},
            False,
            True,
        ),
    ],
)
def test_is_cachable(
    monkeypatch, test_case, method, path, url, rule, route, result, cache_disabled, expected
):
    """Test is_cachable with various scenarios"""
    monkeypatch.setattr("counterpartycore.lib.config.DISABLE_API_CACHE", cache_disabled)

    mock_request = Mock(method=method, path=path, url=url)
    monkeypatch.setattr("counterpartycore.lib.api.apiserver.request", mock_request)

    actual = apiserver.is_cachable(rule, route=route, result=result)
    assert actual == expected, f"Test case '{test_case}' failed"


def test_limit_param_capped_to_api_limit_rows(apiv2_client, monkeypatch):
    """Limit is capped to config.API_LIMIT_ROWS when caller asks for more."""
    monkeypatch.setattr(config, "API_LIMIT_ROWS", 5)

    response = apiv2_client.get("/v2/transactions?limit=99999")
    assert response.status_code == 200
    assert len(response.json["result"]) <= 5


def test_limit_param_zero_rejected(apiv2_client):
    """A limit of 0 must be rejected with a clear error."""
    response = apiv2_client.get("/v2/transactions?limit=0")
    assert response.status_code != 200 or "error" in response.json


def test_limit_param_negative_rejected(apiv2_client):
    """A negative limit must be rejected."""
    response = apiv2_client.get("/v2/transactions?limit=-1")
    assert response.status_code != 200 or "error" in response.json


def test_invalid_enum_param_rejected(apiv2_client, defaults):
    """Literal/enum route arguments must reject unsupported values before query execution."""
    response = apiv2_client.get("/v2/orders?status=invalid-status")
    assert response.status_code == 400
    assert "Invalid value for status" in response.json["error"]

    response = apiv2_client.get("/v2/orders?status=open,invalid-status")
    assert response.status_code == 400
    assert "Invalid value for status" in response.json["error"]

    response = apiv2_client.get(
        f"/v2/addresses/balances?addresses={defaults['addresses'][0]}&type=invalid-type"
    )
    assert response.status_code == 400
    assert "Invalid value for type" in response.json["error"]

    response = apiv2_client.get(
        f"/v2/addresses/balances?addresses={defaults['addresses'][0]}&type=address,utxo"
    )
    assert response.status_code == 400
    assert "Invalid value for type" in response.json["error"]


def test_valid_csv_enum_param_accepted(apiv2_client):
    """Enum routes that already support comma-separated filters must keep accepting them."""
    response = apiv2_client.get("/v2/orders?status=open,filled")
    assert response.status_code == 200
    assert "result" in response.json

    response = apiv2_client.get("/v2/transactions?type=send,order")
    assert response.status_code == 200
    assert "result" in response.json

    response = apiv2_client.get("/v2/dispensers?status=0")
    assert response.status_code == 200
    assert "result" in response.json


def test_limit_param_unlimited_when_zero(apiv2_client, monkeypatch):
    """When config.API_LIMIT_ROWS == 0 the cap is disabled."""
    monkeypatch.setattr(config, "API_LIMIT_ROWS", 0)

    response = apiv2_client.get("/v2/transactions?limit=10")
    assert response.status_code == 200
