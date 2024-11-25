import json
import tempfile

import pytest
import requests

from counterpartycore.lib import util
from counterpartycore.lib.api import routes

# this is require near the top to do setup of the test suite
from counterpartycore.test import (
    conftest,  # noqa: F401
)
from counterpartycore.test.fixtures.params import ADDR
from counterpartycore.test.util_test import CURR_DIR

FIXTURE_SQL_FILE = CURR_DIR + "/fixtures/scenarios/unittest_fixture.sql"
FIXTURE_DB = tempfile.gettempdir() + "/fixtures.unittest_fixture.db"
API_V2_FIXTURES = CURR_DIR + "/fixtures/api_v2_fixtures.json"
API_ROOT = "http://localhost:10009"


@pytest.mark.usefixtures("api_server_v2")
def test_api_v2(request):
    block_index = 310491
    address = "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc"
    asset = "NODIVISIBLE"
    asset1 = asset
    asset2 = "XCP"
    tx_hash = "74db175c4669a3d3a59e3fcddce9e97fcd7d12c35b58ef31845a1b20a1739498"
    order_hash = "74db175c4669a3d3a59e3fcddce9e97fcd7d12c35b58ef31845a1b20a1739498"
    bet_hash = "2a2169991597036b6dad687ea1feffd55465a204466f40c35cbba811cb3109b1"
    dispenser_hash = "9834219d2825b4d85ca7ee0d75a5372d9d42ce75eb9144951fca1af5a25915ec"
    block_hash = "54aeaf47d5387964e2d51617bf3af50520a0449410e0d096cf8c2aa9dad5550b"
    dividend_hash = "42ae2fd7f3a18f84334bc37aa88283e79d6bff0b234dbf97e788695957d75518"
    issuance_hash = "0abfce2662c05852fd8b181a60900678643cedad47b23a853b8c4eda82cb2cbf"
    broadcast_hash = "7c437705c315212315c85c0b8ba09d358679c91be20b54f30929c5a6052426af"
    minter_hash = "83b96c0f72fea31403567852f2bdb4840ffdf18bda2e82df4f27aad633830e29"
    mint_hash = "ba6c7582f5c1e39bed32074c16f54ab338c79d0eefd3c8a7ba1f949e2febcd18"
    event = "CREDIT"
    event_index = 10
    tx_index = 2
    exclude_routes = [
        "compose",
        "unpack",
        "info",
        "mempool",
        "healthz",
        "bitcoin",
        "v1",
        "rpc",
        "api",
        "fairminters",  # TEMPORARY
    ]
    results = {}
    fixtures = {}
    with open(API_V2_FIXTURES, "r") as f:
        fixtures = json.load(f)

    for route in routes.ROUTES:
        # TODO: add dividends in fixtures
        if route == "/" or route == "/<path:subpath>" or "<dividend_hash>" in route:
            continue
        if any([exclude in route for exclude in exclude_routes]):
            continue

        url = f"{API_ROOT}{route}"
        url = url.replace("<int:block_index>", str(block_index))
        url = url.replace("<int:tx_index>", str(tx_index))
        if "/dispensers/" in route:
            url = url.replace("<asset>", "XCP")
            url = url.replace("<address>", "munimLLHjPhGeSU5rYB2HN79LJa8bRZr5b")
        else:
            url = (
                url.replace("<asset>", asset)
                .replace("<asset1>", asset1)
                .replace("<asset2>", asset2)
            )
            url = url.replace("<address>", address)
        url = url.replace("<event>", event)
        url = url.replace("<int:event_index>", str(event_index))
        url = url.replace("<order_hash>", order_hash)
        url = url.replace("<bet_hash>", bet_hash)
        url = url.replace("<dispenser_hash>", dispenser_hash)
        if "issuances" in url:
            url = url.replace("<tx_hash>", issuance_hash)
        if "broadcasts" in url:
            url = url.replace("<tx_hash>", broadcast_hash)
        if "fairminters" in url:
            url = url.replace("<tx_hash>", minter_hash)
        if "fairmints":
            url = url.replace("<tx_hash>", mint_hash)
        url = url.replace("<tx_hash>", tx_hash)
        url = url.replace("<block_hash>", block_hash)
        url = url.replace("<dividend_hash>", dividend_hash)
        if route.startswith("/v2/events"):
            url += "?limit=5&verbose=true"
        elif (
            route.startswith("/v2/addresses/balances")
            or route.startswith("/v2/addresses/transactions")
            or route.startswith("/v2/addresses/events")
            or route.startswith("/v2/addresses/mempool")
        ):
            url += "?verbose=true&limit=6&addresses=" + ADDR[0] + "," + ADDR[1]
        elif route.startswith("/v2/utxos/withbalances"):
            url += "?verbose=true&utxos=" + tx_hash + ":0," + order_hash + ":0"
        else:
            url += "?verbose=true"
        print(url)
        options_result = requests.options(url)  # noqa: S113
        assert options_result.status_code == 204
        print(options_result.headers)
        assert options_result.headers["Access-Control-Allow-Origin"] == "*"
        assert options_result.headers["Access-Control-Allow-Headers"] == "*"
        assert options_result.headers["Access-Control-Allow-Methods"] == "*"

        result = requests.get(url)  # noqa: S113
        print(result)
        results[url] = result.json()
        print(result.json())
        assert result.status_code == 200
        if not request.config.getoption("saveapifixtures"):
            assert results[url] == fixtures[url]

    if request.config.getoption("saveapifixtures"):
        with open(API_V2_FIXTURES, "w") as f:
            f.write(json.dumps(results, indent=4))


@pytest.mark.usefixtures("api_server_v2")
def test_api_v2_unpack(request, server_db):
    with open(CURR_DIR + "/fixtures/api_v2_unpack_fixtures.json", "r") as f:
        datas = json.load(f)
    url = f"{API_ROOT}/v2/transactions/unpack"

    for data in datas:
        result = requests.get(url, params={"datahex": data["datahex"]})  # noqa: S113
        assert result.status_code == 200
        assert result.json()["result"] == data["result"]


@pytest.mark.usefixtures("api_server_v2")
def test_new_get_balances_by_address():
    alice = ADDR[0]
    url = f"{API_ROOT}/v2/addresses/{alice}/balances"
    result = requests.get(url)  # noqa: S113

    # import json
    # print(json.dumps(result.json()["result"], indent=4))

    expected_result = [
        {
            "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc",
            "asset": "XCP",
            "quantity": 91674999900,
            "utxo": None,
            "utxo_address": None,
        },
        {
            "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc",
            "asset": "RAIDFAIRMIN",
            "quantity": 20,
            "utxo": None,
            "utxo_address": None,
        },
        {
            "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc",
            "asset": "PARENT",
            "quantity": 100000000,
            "utxo": None,
            "utxo_address": None,
        },
        {
            "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc",
            "asset": "NODIVISIBLE",
            "quantity": 985,
            "utxo": None,
            "utxo_address": None,
        },
        {
            "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc",
            "asset": "MAXI",
            "quantity": 9223372036854775807,
            "utxo": None,
            "utxo_address": None,
        },
        {
            "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc",
            "asset": "LOCKED",
            "quantity": 1000,
            "utxo": None,
            "utxo_address": None,
        },
        {
            "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc",
            "asset": "FREEFAIRMIN",
            "quantity": 10,
            "utxo": None,
            "utxo_address": None,
        },
        {
            "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc",
            "asset": "DIVISIBLE",
            "quantity": 98799999999,
            "utxo": None,
            "utxo_address": None,
        },
        {
            "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc",
            "asset": "CALLABLE",
            "quantity": 1000,
            "utxo": None,
            "utxo_address": None,
        },
        {
            "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc",
            "asset": "A95428956661682277",
            "quantity": 100000000,
            "utxo": None,
            "utxo_address": None,
        },
        {
            "address": None,
            "asset": "XCP",
            "quantity": 100,
            "utxo": "e219be68972de7df99122a0213d7be2f597c14fa48b55457a81641583099fea4:0",
            "utxo_address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc",
        },
        {
            "address": None,
            "asset": "DIVISIBLE",
            "quantity": 1,
            "utxo": "74501a157028760383ae4a8f79f6bce9ef64e60e883ac3285bc239a907c2b42c:0",
            "utxo_address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc",
        },
    ]
    for balance in result.json()["result"]:
        assert balance in expected_result


@pytest.mark.usefixtures("api_server_v2")
def test_new_get_balances_by_asset():
    asset = "XCP"
    url = f"{API_ROOT}/v2/assets/{asset}/balances"
    result = requests.get(url)  # noqa: S113
    import json

    print(json.dumps(result.json()["result"], indent=4))
    expected_result = [
        {
            "address": None,
            "utxo": "e219be68972de7df99122a0213d7be2f597c14fa48b55457a81641583099fea4:0",
            "utxo_address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc",
            "asset": "XCP",
            "quantity": 100,
        },
        {
            "address": "1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2",
            "utxo": None,
            "utxo_address": None,
            "asset": "XCP",
            "quantity": 300000000,
        },
        {
            "address": "2MyJHMUenMWonC35Yi6PHC7i2tkS7PuomCy",
            "utxo": None,
            "utxo_address": None,
            "asset": "XCP",
            "quantity": 46449548498,
        },
        {
            "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc",
            "utxo": None,
            "utxo_address": None,
            "asset": "XCP",
            "quantity": 91674999900,
        },
        {
            "address": "mqPCfvqTfYctXMUfmniXeG2nyaN8w6tPmj",
            "utxo": None,
            "utxo_address": None,
            "asset": "XCP",
            "quantity": 92945878046,
        },
        {
            "address": "mrPk7hTeZWjjSCrMTC2ET4SAUThQt7C4uK",
            "utxo": None,
            "utxo_address": None,
            "asset": "XCP",
            "quantity": 14999857,
        },
        {
            "address": "mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns",
            "utxo": None,
            "utxo_address": None,
            "asset": "XCP",
            "quantity": 99999990,
        },
        {
            "address": "munimLLHjPhGeSU5rYB2HN79LJa8bRZr5b",
            "utxo": None,
            "utxo_address": None,
            "asset": "XCP",
            "quantity": 92949130360,
        },
        {
            "address": "mwtPsLQxW9xpm7gdLmwWvJK5ABdPUVJm42",
            "utxo": None,
            "utxo_address": None,
            "asset": "XCP",
            "quantity": 92949122099,
        },
        {
            "address": "myAtcJEHAsDLbTkai6ipWDZeeL7VkxXsiM",
            "utxo": None,
            "utxo_address": None,
            "asset": "XCP",
            "quantity": 92999138821,
        },
        {
            "address": "tb1qw508d6qejxtdg4y5r3zarvary0c5xw7kxpjzsx",
            "utxo": None,
            "utxo_address": None,
            "asset": "XCP",
            "quantity": 92999030129,
        },
    ]
    for balance in result.json()["result"]:
        assert balance in expected_result


@pytest.mark.usefixtures("api_server")
@pytest.mark.usefixtures("api_server_v2")
def test_new_get_balances_vs_old():
    asset = "XCP"
    url = f"{API_ROOT}/v2/assets/{asset}/balances"
    new_balances = requests.get(url).json()["result"]  # noqa: S113
    old_balance = util.api(
        "get_balances",
        {
            "filters": [
                {"field": "asset", "op": "==", "value": asset},
                {"field": "quantity", "op": "!=", "value": 0},
            ],
        },
    )
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


@pytest.mark.usefixtures("api_server_v2")
def test_new_get_asset_info():
    asset = "NODIVISIBLE"
    url = f"{API_ROOT}/v2/assets/{asset}"
    result = requests.get(url)  # noqa: S113

    assert result.json()["result"] == {
        "asset": "NODIVISIBLE",
        "asset_longname": None,
        "description": "No divisible asset",
        "description_locked": False,
        "divisible": False,
        "issuer": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc",
        "locked": False,
        "first_issuance_block_index": 310002,
        "last_issuance_block_index": 310002,
        "asset_id": "1911882621324134",
        "owner": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc",
        "supply": 1000,
    }


@pytest.mark.usefixtures("api_server_v2")
def test_new_get_asset_orders():
    asset = "XCP"
    url = f"{API_ROOT}/v2/assets/{asset}/orders"
    result = requests.get(url).json()["result"]  # noqa: S113
    assert len(result) == 6
    assert result[0] == {
        "tx_index": 493,
        "tx_hash": "1b294dd8592e76899b1c106782e4c96e63114abd8e3fa09ab6d2d52496b5bf81",
        "block_index": 310513,
        "source": "mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns",
        "give_asset": "BTC",
        "give_quantity": 800000,
        "give_remaining": 800000,
        "get_asset": "XCP",
        "get_quantity": 100000000,
        "get_remaining": 100000000,
        "expiration": 2000,
        "expire_index": 312492,
        "fee_required": 0,
        "fee_required_remaining": 0,
        "fee_provided": 1000000,
        "fee_provided_remaining": 992800,
        "status": "open",
        "get_price": 0.008,
        "give_price": 125.0,
    }


@pytest.mark.usefixtures("api_server_v2")
def test_new_get_order_info():
    tx_hash = "1899b2e6ec36ba4bc9d035e6640b0a62b08c3a147c77c89183a77d9ed9081b3a"
    url = f"{API_ROOT}/v2/orders/{tx_hash}"
    result = requests.get(url).json()["result"]  # noqa: S113
    assert result == {
        "tx_index": 11,
        "tx_hash": "1899b2e6ec36ba4bc9d035e6640b0a62b08c3a147c77c89183a77d9ed9081b3a",
        "block_index": 310010,
        "source": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc",
        "give_asset": "XCP",
        "give_quantity": 100000000,
        "give_remaining": 100000000,
        "get_asset": "BTC",
        "get_quantity": 1000000,
        "get_remaining": 1000000,
        "expiration": 2000,
        "expire_index": 312010,
        "fee_required": 900000,
        "fee_required_remaining": 900000,
        "fee_provided": 6800,
        "fee_provided_remaining": 6800,
        "status": "open",
        "get_price": 100.0,
        "give_price": 0.01,
    }


@pytest.mark.usefixtures("api_server_v2")
def test_new_get_order_matches():
    tx_hash = "74db175c4669a3d3a59e3fcddce9e97fcd7d12c35b58ef31845a1b20a1739498"
    url = f"{API_ROOT}/v2/orders/{tx_hash}/matches"
    result = requests.get(url).json()["result"]  # noqa: S113
    assert result[0] == {
        "id": "74db175c4669a3d3a59e3fcddce9e97fcd7d12c35b58ef31845a1b20a1739498_1b294dd8592e76899b1c106782e4c96e63114abd8e3fa09ab6d2d52496b5bf81",
        "tx0_index": 492,
        "tx0_hash": "74db175c4669a3d3a59e3fcddce9e97fcd7d12c35b58ef31845a1b20a1739498",
        "tx0_address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc",
        "tx1_index": 493,
        "tx1_hash": "1b294dd8592e76899b1c106782e4c96e63114abd8e3fa09ab6d2d52496b5bf81",
        "tx1_address": "mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns",
        "forward_asset": "XCP",
        "forward_quantity": 100000000,
        "backward_asset": "BTC",
        "backward_quantity": 800000,
        "tx0_block_index": 310491,
        "tx1_block_index": 310492,
        "block_index": 310513,
        "tx0_expiration": 2000,
        "tx1_expiration": 2000,
        "match_expire_index": 310512,
        "fee_paid": 7200,
        "status": "expired",
    }


@pytest.mark.usefixtures("api_server_v2")
def test_asset_dispensers():
    asset = "XCP"

    url = f"{API_ROOT}/v2/assets/{asset}/dispensers?status=1"
    result = requests.get(url)  # noqa: S113
    assert result.json()["result"] == []

    url = f"{API_ROOT}/v2/assets/{asset}/dispensers?status=0"
    result = requests.get(url)  # noqa: S113
    assert result.json()["result"] == [
        {
            "tx_index": 108,
            "tx_hash": "9834219d2825b4d85ca7ee0d75a5372d9d42ce75eb9144951fca1af5a25915ec",
            "block_index": 310107,
            "source": "munimLLHjPhGeSU5rYB2HN79LJa8bRZr5b",
            "asset": "XCP",
            "give_quantity": 100,
            "escrow_quantity": 100,
            "satoshirate": 100,
            "status": 0,
            "give_remaining": 100,
            "oracle_address": None,
            "last_status_tx_hash": None,
            "origin": "munimLLHjPhGeSU5rYB2HN79LJa8bRZr5b",
            "price": 1.0,
            "dispense_count": 0,
            "last_status_tx_source": None,
            "close_block_index": None,
        }
    ]

    asset = "TESTDISP"

    url = f"{API_ROOT}/v2/assets/{asset}/dispensers?status=1"
    result = requests.get(url)  # noqa: S113
    assert result.json()["result"] == []

    url = f"{API_ROOT}/v2/assets/{asset}/dispensers?status=0"
    result = requests.get(url)  # noqa: S113
    assert result.json()["result"] == [
        {
            "tx_index": 511,
            "tx_hash": "af67f6762d4b00b4bf5fb93a9d556e007a147aa80fbf6a84410df05a0182da9e",
            "block_index": 310510,
            "source": "munimLLHjPhGeSU5rYB2HN79LJa8bRZr5b",
            "asset": "TESTDISP",
            "give_quantity": 100,
            "escrow_quantity": 100,
            "satoshirate": 100,
            "status": 0,
            "give_remaining": 100,
            "oracle_address": None,
            "last_status_tx_hash": None,
            "origin": "munimLLHjPhGeSU5rYB2HN79LJa8bRZr5b",
            "price": 1.0,
            "dispense_count": 0,
            "last_status_tx_source": None,
            "close_block_index": None,
        }
    ]
