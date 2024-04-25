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
API_ROOT = "http://api:api@localhost:10009"


@pytest.mark.usefixtures("api_server_v2")
def test_api_v2(request):
    block_index = 310491
    address = ADDR[0]
    asset = "NODIVISIBLE"
    tx_hash = "74db175c4669a3d3a59e3fcddce9e97fcd7d12c35b58ef31845a1b20a1739498"
    order_hash = "74db175c4669a3d3a59e3fcddce9e97fcd7d12c35b58ef31845a1b20a1739498"
    bet_hash = "e566ab052d414d2c9b9d6ffc643bc5d2b31d80976dffe7acceaf2576246f9e42"
    dispenser_hash = "74db175c4669a3d3a59e3fcddce9e97fcd7d12c35b58ef31845a1b20a1739498"
    event = "CREDIT"
    event_index = 10
    exclude_routes = ["compose", "unpack", "info", "mempool", "healthz", "backend"]
    results = {}
    fixtures = {}
    with open(API_V2_FIXTURES, "r") as f:
        fixtures = json.load(f)

    for route in routes.ROUTES:
        if any([exclude in route for exclude in exclude_routes]):
            continue

        url = f"{API_ROOT}{route}"
        url = url.replace("<int:block_index>", str(block_index))
        url = url.replace("<address>", address)
        url = url.replace("<asset>", asset)
        url = url.replace("<event>", event)
        url = url.replace("<int:event_index>", str(event_index))
        url = url.replace("<order_hash>", order_hash)
        url = url.replace("<bet_hash>", bet_hash)
        url = url.replace("<dispenser_hash>", dispenser_hash)
        url = url.replace("<tx_hash>", tx_hash)
        if route.startswith("/events"):
            url += "?limit=5"
        print(url)
        result = requests.get(url)  # noqa: S113
        results[url] = result.json()
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
    url = f"{API_ROOT}/transactions/unpack"

    for data in datas:
        result = requests.get(url, params={"datahex": data["datahex"]})  # noqa: S113
        assert result.status_code == 200
        assert result.json()["result"] == data["result"]


@pytest.mark.usefixtures("api_server_v2")
def test_new_get_balances_by_address():
    alice = ADDR[0]
    url = f"{API_ROOT}/addresses/{alice}/balances"
    result = requests.get(url)  # noqa: S113
    assert result.json()["result"] == [
        {
            "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc",
            "asset": "A95428956661682277",
            "quantity": 100000000,
        },
        {
            "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc",
            "asset": "CALLABLE",
            "quantity": 1000,
        },
        {
            "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc",
            "asset": "DIVISIBLE",
            "quantity": 98800000000,
        },
        {
            "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc",
            "asset": "LOCKED",
            "quantity": 1000,
        },
        {
            "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc",
            "asset": "MAXI",
            "quantity": 9223372036854775807,
        },
        {
            "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc",
            "asset": "NODIVISIBLE",
            "quantity": 985,
        },
        {
            "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc",
            "asset": "PARENT",
            "quantity": 100000000,
        },
        {
            "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc",
            "asset": "XCP",
            "quantity": 91875000000,
        },
    ]


@pytest.mark.usefixtures("api_server_v2")
def test_new_get_balances_by_asset():
    asset = "XCP"
    url = f"{API_ROOT}/assets/{asset}/balances"
    result = requests.get(url)  # noqa: S113
    assert result.json()["result"] == [
        {
            "address": "1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2",
            "asset": "XCP",
            "quantity": 300000000,
        },
        {
            "address": "2MyJHMUenMWonC35Yi6PHC7i2tkS7PuomCy",
            "asset": "XCP",
            "quantity": 46449548498,
        },
        {
            "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc",
            "asset": "XCP",
            "quantity": 91875000000,
        },
        {
            "address": "mqPCfvqTfYctXMUfmniXeG2nyaN8w6tPmj",
            "asset": "XCP",
            "quantity": 92945878046,
        },
        {
            "address": "mrPk7hTeZWjjSCrMTC2ET4SAUThQt7C4uK",
            "asset": "XCP",
            "quantity": 14999857,
        },
        {
            "address": "mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns",
            "asset": "XCP",
            "quantity": 99999990,
        },
        {
            "address": "munimLLHjPhGeSU5rYB2HN79LJa8bRZr5b",
            "asset": "XCP",
            "quantity": 92999130360,
        },
        {
            "address": "mwtPsLQxW9xpm7gdLmwWvJK5ABdPUVJm42",
            "asset": "XCP",
            "quantity": 92949122099,
        },
        {
            "address": "myAtcJEHAsDLbTkai6ipWDZeeL7VkxXsiM",
            "asset": "XCP",
            "quantity": 92999138812,
        },
        {
            "address": "tb1qw508d6qejxtdg4y5r3zarvary0c5xw7kxpjzsx",
            "asset": "XCP",
            "quantity": 92999030129,
        },
    ]


@pytest.mark.usefixtures("api_server")
@pytest.mark.usefixtures("api_server_v2")
def test_new_get_balances_vs_old():
    asset = "XCP"
    url = f"{API_ROOT}/assets/{asset}/balances"
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
    new_balances = sorted(new_balances, key=lambda x: (x["address"], x["asset"], x["quantity"]))
    old_balance = sorted(old_balance, key=lambda x: (x["address"], x["asset"], x["quantity"]))
    assert len(new_balances) == len(old_balance)
    for new_balance, old_balance in zip(new_balances, old_balance):  # noqa: B020
        assert new_balance["address"] == old_balance["address"]
        assert new_balance["asset"] == old_balance["asset"]
        assert new_balance["quantity"] == old_balance["quantity"]


@pytest.mark.usefixtures("api_server_v2")
def test_new_get_asset_info():
    asset = "NODIVISIBLE"
    url = f"{API_ROOT}/assets/{asset}"
    result = requests.get(url)  # noqa: S113

    assert result.json()["result"] == {
        "asset": "NODIVISIBLE",
        "asset_longname": None,
        "description": "No divisible asset",
        "divisible": False,
        "issuer": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc",
        "locked": False,
        "owner": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc",
        "supply": 1000,
        "holder_count": 3,
    }


@pytest.mark.usefixtures("api_server_v2")
def test_new_get_asset_orders():
    asset = "XCP"
    url = f"{API_ROOT}/assets/{asset}/orders"
    result = requests.get(url).json()["result"]  # noqa: S113
    assert len(result) == 6
    assert result[0] == {
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
    }


@pytest.mark.usefixtures("api_server_v2")
def test_new_get_order_info():
    tx_hash = "1899b2e6ec36ba4bc9d035e6640b0a62b08c3a147c77c89183a77d9ed9081b3a"
    url = f"{API_ROOT}/orders/{tx_hash}"
    result = requests.get(url).json()["result"]  # noqa: S113
    assert result[0] == {
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
    }


@pytest.mark.usefixtures("api_server_v2")
def test_new_get_order_matches():
    tx_hash = "74db175c4669a3d3a59e3fcddce9e97fcd7d12c35b58ef31845a1b20a1739498"
    url = f"{API_ROOT}/orders/{tx_hash}/matches"
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
        "block_index": 310492,
        "tx0_expiration": 2000,
        "tx1_expiration": 2000,
        "match_expire_index": 310512,
        "fee_paid": 7200,
        "status": "pending",
    }
