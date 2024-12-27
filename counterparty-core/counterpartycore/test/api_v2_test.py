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
    tx_hash = "b37d91f0a3451e89035a780c7f0e84ed135d4dd4cd39227cda35ac6da0d3f10e"
    order_hash = "6d55dc8fe1555cb48b66c764e1d7dcc76bd1792673d09bf4168051dcb6d76efb"
    bet_hash = "8a1916be67d8429e52405ef4016f2d70e5ee19a3bc808bc179f6965bcd6ea610"
    dispenser_hash = "4c0f6bf88e269d5ec199b70afbaa69743d244ccc9bc86e40f53e7960f5789807"
    block_hash = "8b3bef249cb3b0fa23a4936c1249b6bd41daeadc848c8d2e409ea1cbc10adfe7"
    dividend_hash = "42ae2fd7f3a18f84334bc37aa88283e79d6bff0b234dbf97e788695957d75518"
    issuance_hash = "cfdead7d6e10e46efac32f1956f2147d633f2c672ad43f6bb6c49a00d6916832"
    broadcast_hash = "8650f4bac622845318dfd24d5737ac9290e3d8f1799d5806ba6456a9bb8dea25"
    minter_hash = "1d7b6345d81e23a345a5befb51def7cfb3c83875f0be4e824e1ec96f01d498db"
    mint_hash = "74420251573a1e6034f6194022abcfc1f3390ef34fed7cdcd7e82aa22cce8efe"
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
    print(json.dumps(result.json()["result"], indent=4))

    expected_result = [
        {
            "address": None,
            "asset": "DIVISIBLE",
            "asset_longname": None,
            "quantity": 1,
            "utxo": "2af07370ebad31d56c841b4662d11e1e75f8a2b8f16d171ab071a28c00d883ab:0",
            "utxo_address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc",
        },
        {
            "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc",
            "asset": "DIVISIBLE",
            "asset_longname": None,
            "quantity": 98799999999,
            "utxo": None,
            "utxo_address": None,
        },
        {
            "address": None,
            "asset": "XCP",
            "asset_longname": None,
            "quantity": 100,
            "utxo": "6657beb41d0ab2cedd399331dd1cae65c0bc19ee07c1695859b5725ad7344969:0",
            "utxo_address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc",
        },
        {
            "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc",
            "asset": "XCP",
            "asset_longname": None,
            "quantity": 91674999900,
            "utxo": None,
            "utxo_address": None,
        },
        {
            "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc",
            "asset": "RAIDFAIRMIN",
            "asset_longname": None,
            "quantity": 20,
            "utxo": None,
            "utxo_address": None,
        },
        {
            "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc",
            "asset": "FREEFAIRMIN",
            "asset_longname": None,
            "quantity": 10,
            "utxo": None,
            "utxo_address": None,
        },
        {
            "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc",
            "asset": "A95428956661682277",
            "asset_longname": "PARENT.already.issued",
            "quantity": 100000000,
            "utxo": None,
            "utxo_address": None,
        },
        {
            "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc",
            "asset": "PARENT",
            "asset_longname": None,
            "quantity": 100000000,
            "utxo": None,
            "utxo_address": None,
        },
        {
            "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc",
            "asset": "MAXI",
            "asset_longname": None,
            "quantity": 9223372036854775807,
            "utxo": None,
            "utxo_address": None,
        },
        {
            "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc",
            "asset": "NODIVISIBLE",
            "asset_longname": None,
            "quantity": 985,
            "utxo": None,
            "utxo_address": None,
        },
        {
            "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc",
            "asset": "LOCKED",
            "asset_longname": None,
            "quantity": 1000,
            "utxo": None,
            "utxo_address": None,
        },
        {
            "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc",
            "asset": "CALLABLE",
            "asset_longname": None,
            "quantity": 1000,
            "utxo": None,
            "utxo_address": None,
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
            "address": "1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2",
            "utxo": None,
            "utxo_address": None,
            "asset": "XCP",
            "asset_longname": None,
            "quantity": 300000000,
        },
        {
            "address": "mrPk7hTeZWjjSCrMTC2ET4SAUThQt7C4uK",
            "utxo": None,
            "utxo_address": None,
            "asset": "XCP",
            "asset_longname": None,
            "quantity": 14999857,
        },
        {
            "address": "2MyJHMUenMWonC35Yi6PHC7i2tkS7PuomCy",
            "utxo": None,
            "utxo_address": None,
            "asset": "XCP",
            "asset_longname": None,
            "quantity": 46449548498,
        },
        {
            "address": "mwtPsLQxW9xpm7gdLmwWvJK5ABdPUVJm42",
            "utxo": None,
            "utxo_address": None,
            "asset": "XCP",
            "asset_longname": None,
            "quantity": 92949122099,
        },
        {
            "address": "tb1qw508d6qejxtdg4y5r3zarvary0c5xw7kxpjzsx",
            "utxo": None,
            "utxo_address": None,
            "asset": "XCP",
            "asset_longname": None,
            "quantity": 92999030129,
        },
        {
            "address": "mqPCfvqTfYctXMUfmniXeG2nyaN8w6tPmj",
            "utxo": None,
            "utxo_address": None,
            "asset": "XCP",
            "asset_longname": None,
            "quantity": 92945878046,
        },
        {
            "address": "mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns",
            "utxo": None,
            "utxo_address": None,
            "asset": "XCP",
            "asset_longname": None,
            "quantity": 99999990,
        },
        {
            "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc",
            "utxo": None,
            "utxo_address": None,
            "asset": "XCP",
            "asset_longname": None,
            "quantity": 91674999900,
        },
        {
            "address": None,
            "utxo": "6657beb41d0ab2cedd399331dd1cae65c0bc19ee07c1695859b5725ad7344969:0",
            "utxo_address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc",
            "asset": "XCP",
            "asset_longname": None,
            "quantity": 100,
        },
        {
            "address": "munimLLHjPhGeSU5rYB2HN79LJa8bRZr5b",
            "utxo": None,
            "utxo_address": None,
            "asset": "XCP",
            "asset_longname": None,
            "quantity": 92949130360,
        },
        {
            "address": "myAtcJEHAsDLbTkai6ipWDZeeL7VkxXsiM",
            "utxo": None,
            "utxo_address": None,
            "asset": "XCP",
            "asset_longname": None,
            "quantity": 92999138821,
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
        "tx_hash": "594789e471862d08d5bcd8f58ee70cb235589103da8beceb628a2e18f6398760",
        "block_index": 310492,
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
        "fee_provided": 597,
        "fee_provided_remaining": 597,
        "status": "open",
        "get_price": 0.008,
        "give_price": 125.0,
    }


@pytest.mark.usefixtures("api_server_v2")
def test_new_get_order_info():
    tx_hash = "ce4828b474d96ed877b1d02d13357041cd4a1f26e3a7f3da23a2ec17fc818490"
    url = f"{API_ROOT}/v2/orders/{tx_hash}"
    result = requests.get(url).json()["result"]  # noqa: S113
    assert result == {
        "tx_index": 11,
        "tx_hash": "ce4828b474d96ed877b1d02d13357041cd4a1f26e3a7f3da23a2ec17fc818490",
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
        "forward_price": 0.008,
        "forward_quantity": 100000000,
        "backward_asset": "BTC",
        "backward_price": 125.0,
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
