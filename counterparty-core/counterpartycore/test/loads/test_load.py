import os
import random

import gevent
import locust
from counterpartycore.lib.api.routes import ALL_ROUTES
from counterpartycore.lib.utils import database

DB = database.get_db_connection(
    os.path.expanduser("~/.local/share/counterparty/counterparty.db"), read_only=True
)


class MainnetFixtures:
    last_block = DB.execute(
        "SELECT block_hash FROM blocks ORDER BY block_index DESC LIMIT 1"
    ).fetchone()
    last_tx = DB.execute(
        "SELECT tx_hash, tx_index, block_index FROM transactions ORDER BY rowid DESC LIMIT 1"
    ).fetchone()
    utxo_with_balance = DB.execute(
        "SELECT * FROM balances WHERE utxo IS NOT null AND quantity > 0 ORDER BY rowid DESC LIMIT 1"
    ).fetchone()
    last_dispenser = DB.execute("SELECT * FROM dispensers ORDER BY rowid DESC LIMIT 1").fetchone()
    last_order = DB.execute("SELECT * FROM orders ORDER BY rowid DESC LIMIT 1").fetchone()
    last_bet = DB.execute("SELECT * FROM bets ORDER BY rowid DESC LIMIT 1").fetchone()
    last_dividend = DB.execute("SELECT * FROM dividends ORDER BY rowid DESC LIMIT 1").fetchone()
    last_event = DB.execute("SELECT * FROM messages ORDER BY rowid DESC LIMIT 1").fetchone()
    last_issuance = DB.execute("SELECT * FROM issuances ORDER BY rowid DESC LIMIT 1").fetchone()
    last_sweep = DB.execute("SELECT * FROM sweeps ORDER BY rowid DESC LIMIT 1").fetchone()
    last_broadcast = DB.execute("SELECT * FROM broadcasts ORDER BY rowid DESC LIMIT 1").fetchone()
    last_fairminter = DB.execute("SELECT * FROM fairminters ORDER BY rowid DESC LIMIT 1").fetchone()
    last_fairmint = DB.execute("SELECT * FROM fairmints ORDER BY rowid DESC LIMIT 1").fetchone()
    asset, asset1, asset2 = "XCP", "PEPECASH", "FAIREST"
    datahex = "00000014000000a25be34b66000000174876e800010000000000000000000f446976697369626c65206173736574"
    jdog_address = "1JDogZS6tQcSxwfxhv6XKKjcyicYA4Feev"
    # 032d29f789f7fc0aa8d268431a02001a0d4ee9dc42ca4b21de26b912f101271c
    raw_transaction = "0100000001b43530bc300f44a078bae943cb6ad3add44111ce2f815dad1deb921c912462d9020000008b483045022100849a06573b994a95b239cbaadf8cd266bdc5fc64535be43bcb786e29b515089502200a6fd9876ef888b67f1097928f7386f55e775b5812eb9ba22609abfdfe8d3f2f01410426156245525daa71f2e84a40797bcf28099a2c508662a8a33324a703597b9aa2661a79a82ffb4caaa9b15f4094622fbfa85f8b9dc7381f991f5a265421391cc3ffffffff020000000000000000436a4145b0b98d99423f507895e7dbdf4b7973f7bd422984872c56c241007de56d991ce1c74270f773cf03896f4a50ee0df5eb153571ce2a767f51c7c9d7569bad277e9da9a78200000000001976a914bce6191bf2fd5981313cae869e9fafe164f7dbaf88ac00000000"


DB.close()


def prepare_url(route):
    if route in ["/v2/transactions/<tx_hash>/info", "/", "/v1/", "/api/", "/rpc/"]:
        return None
    if route.startswith("/v2/bitcoin/"):
        return None
    if "/compose/" in route:
        return None
    if "/dispenses/" in route:
        return None

    url = route.replace("<int:block_index>", str(MainnetFixtures.last_tx["block_index"]))
    url = url.replace("<block_hash>", MainnetFixtures.last_block["block_hash"])
    url = url.replace("<order_hash>", MainnetFixtures.last_order["tx_hash"])
    url = url.replace("<dispenser_hash>", MainnetFixtures.last_dispenser["tx_hash"])
    url = url.replace("<bet_hash>", MainnetFixtures.last_bet["tx_hash"])
    url = url.replace("<dividend_hash>", MainnetFixtures.last_dividend["tx_hash"])
    url = url.replace("<int:tx_index>", str(MainnetFixtures.last_tx["tx_index"]))
    url = url.replace("<int:event_index>", str(MainnetFixtures.last_event["message_index"]))
    url = url.replace("<event>", str(MainnetFixtures.last_event["event"]))
    url = url.replace("<asset>", MainnetFixtures.asset)
    url = url.replace("<asset1>", MainnetFixtures.asset1)
    url = url.replace("<asset2>", MainnetFixtures.asset2)
    url = url.replace("<address>", MainnetFixtures.jdog_address)
    url = url.replace("<utxo>", MainnetFixtures.utxo_with_balance["utxo"])

    if url.startswith("/v2/issuances/"):
        url = url.replace("<tx_hash>", MainnetFixtures.last_issuance["tx_hash"])
    elif url.startswith("/v2/sweeps/"):
        url = url.replace("<tx_hash>", MainnetFixtures.last_sweep["tx_hash"])
    elif url.startswith("/v2/broadcasts/"):
        url = url.replace("<tx_hash>", MainnetFixtures.last_broadcast["tx_hash"])
    elif url.startswith("/v2/fairminters/"):
        url = url.replace("<tx_hash>", MainnetFixtures.last_fairminter["tx_hash"])
    elif url.startswith("/v2/fairmints/"):
        url = url.replace("<tx_hash>", MainnetFixtures.last_fairmint["tx_hash"])
    else:
        url = url.replace("<tx_hash>", MainnetFixtures.last_tx["tx_hash"])

    if url == "/v2/transactions/info":
        url = url + "?rawtransaction=" + MainnetFixtures.raw_transaction
    elif url == "/v2/transactions/unpack":
        url = url + "?datahex=" + MainnetFixtures.datahex
    elif url in [
        "/v2/addresses/balances",
        "/v2/addresses/transactions",
        "/v2/addresses/events",
        "/v2/addresses/mempool",
    ]:
        url = url + "?addresses=" + MainnetFixtures.jdog_address
    elif url == "/v2/utxos/withbalances":
        url = url + "?utxos=" + MainnetFixtures.utxo_with_balance["utxo"]

    chr = "&" if "?" in url else "?"
    url = url + chr + "verbose=true"

    return url


def generate_random_url():
    while True:
        url = prepare_url(random.choice(list(ALL_ROUTES.keys())))  # noqa S311
        if url:
            return url


class CounterpartyCoreUser(locust.HttpUser):
    host = "http://localhost:4000"  # Counterparty API URL
    wait_time = locust.between(0.3, 0.6)

    @locust.task
    def get_random_url(self):
        headers = {"Content-Type": "application/json"}
        self.client.get(generate_random_url(), headers=headers)


def test_load():
    locust.log.setup_logging("INFO")

    user_count = 5
    spawn_rate = 2
    test_duration = 60

    env = locust.env.Environment(user_classes=[CounterpartyCoreUser])
    env.create_local_runner()

    # start a greenlet that periodically outputs the current stats
    gevent.spawn(locust.stats.stats_printer(env.stats))
    # start a greenlet that save current stats to history
    gevent.spawn(locust.stats.stats_history, env.runner)
    # start the test
    env.runner.start(user_count, spawn_rate=spawn_rate)
    # in test_duration seconds stop the runner
    gevent.spawn_later(test_duration, lambda: env.runner.quit())
    env.runner.greenlet.join()

    assert env.stats.total.avg_response_time < 120  # ms
    assert env.stats.total.num_failures == 0
    assert env.stats.total.get_response_time_percentile(0.95) < 500  # ms
