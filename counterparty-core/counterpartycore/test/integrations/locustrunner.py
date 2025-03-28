import os
import random
import urllib.parse

import gevent
import locust
from counterpartycore.lib.api.routes import ALL_ROUTES
from counterpartycore.lib.utils import database


def generate_mainnet_fixtures(db_file):
    db = database.get_db_connection(db_file, read_only=True)

    class MainnetFixtures:
        last_block = db.execute(
            "SELECT block_hash FROM blocks ORDER BY block_index DESC LIMIT 1"
        ).fetchone()
        last_tx = db.execute(
            "SELECT tx_hash, tx_index, block_index FROM transactions ORDER BY rowid DESC LIMIT 1"
        ).fetchone()
        utxo_with_balance = db.execute(
            "SELECT * FROM balances WHERE utxo IS NOT null AND quantity > 0 ORDER BY rowid DESC LIMIT 1"
        ).fetchone()
        last_dispenser = db.execute(
            "SELECT * FROM dispensers ORDER BY rowid DESC LIMIT 1"
        ).fetchone()
        last_dispense = db.execute("SELECT * FROM dispenses ORDER BY rowid DESC LIMIT 1").fetchone()
        last_order = db.execute("SELECT * FROM orders ORDER BY rowid DESC LIMIT 1").fetchone()
        last_bet = db.execute("SELECT * FROM bets ORDER BY rowid DESC LIMIT 1").fetchone()
        last_dividend = db.execute("SELECT * FROM dividends ORDER BY rowid DESC LIMIT 1").fetchone()
        last_event = db.execute("SELECT * FROM messages ORDER BY rowid DESC LIMIT 1").fetchone()
        last_issuance = db.execute("SELECT * FROM issuances ORDER BY rowid DESC LIMIT 1").fetchone()
        last_sweep = db.execute("SELECT * FROM sweeps ORDER BY rowid DESC LIMIT 1").fetchone()
        last_broadcast = db.execute(
            "SELECT * FROM broadcasts ORDER BY rowid DESC LIMIT 1"
        ).fetchone()
        last_fairminter = db.execute(
            "SELECT * FROM fairminters ORDER BY rowid DESC LIMIT 1"
        ).fetchone()
        last_fairmint = db.execute("SELECT * FROM fairmints ORDER BY rowid DESC LIMIT 1").fetchone()
        asset, asset1, asset2 = "XCP", "PEPECASH", "FAIREST"
        datahex = "00000014000000a25be34b66000000174876e800010000000000000000000f446976697369626c65206173736574"
        jdog_address = "1JDogZS6tQcSxwfxhv6XKKjcyicYA4Feev"
        jdog_tx_hash = "032d29f789f7fc0aa8d268431a02001a0d4ee9dc42ca4b21de26b912f101271c"
        raw_transaction = "0100000001b43530bc300f44a078bae943cb6ad3add44111ce2f815dad1deb921c912462d9020000008b483045022100849a06573b994a95b239cbaadf8cd266bdc5fc64535be43bcb786e29b515089502200a6fd9876ef888b67f1097928f7386f55e775b5812eb9ba22609abfdfe8d3f2f01410426156245525daa71f2e84a40797bcf28099a2c508662a8a33324a703597b9aa2661a79a82ffb4caaa9b15f4094622fbfa85f8b9dc7381f991f5a265421391cc3ffffffff020000000000000000436a4145b0b98d99423f507895e7dbdf4b7973f7bd422984872c56c241007de56d991ce1c74270f773cf03896f4a50ee0df5eb153571ce2a767f51c7c9d7569bad277e9da9a78200000000001976a914bce6191bf2fd5981313cae869e9fafe164f7dbaf88ac00000000"
        compose_args = {
            "/v2/addresses/<address>/compose/bet": {
                "feed_address": "1JDogZS6tQcSxwfxhv6XKKjcyicYA4Feev",
                "bet_type": 3,
                "deadline": 1388000200,
                "wager_quantity": 10,
                "counterwager_quantity": 10,
                "target_value": 0,
                "leverage": 5040,
                "expiration": 1000,
            },
            "/v2/addresses/<address>/compose/broadcast": {
                "timestamp": 1388000002,
                "value": 1,
                "fee_fraction": 0.05,
                "text": "Load Test",
            },
            "/v2/addresses/<address>/compose/btcpay": None,
            "/v2/addresses/<address>/compose/burn": None,
            "/v2/addresses/<address>/compose/cancel": None,
            "/v2/addresses/<address>/compose/destroy": {
                "asset": "XCP",
                "quantity": 1,
                "tag": "string",
            },
            "/v2/addresses/<address>/compose/dispenser": {
                "asset": "XCP",
                "give_quantity": 100,
                "escrow_quantity": 100,
                "mainchainrate": 100,
                "status": 0,
            },
            "/v2/addresses/<address>/compose/dividend": {
                "quantity_per_unit": 1,
                "asset": "A4931122120200000000",
                "dividend_asset": "XCP",
            },
            "/v2/addresses/<address>/compose/dividend/estimatexcpfees": {
                "quantity_per_unit": 1,
                "asset": "A4931122120200000000",
                "dividend_asset": "XCP",
            },
            "/v2/addresses/<address>/compose/issuance": {
                "asset": "DAVASABLE",
                "quantity": 10000000000,
                "transfer_destination": None,
                "divisible": True,
                "lock": None,
                "reset": None,
                "description": "Divisible asset",
            },
            "/v2/addresses/<address>/compose/mpma": {
                "assets": "XCP,A4931122120200000000",
                "destinations": "1CounterpartyXXXXXXXXXXXXXXXUWLpVr,1CounterpartyXXXXXXXXXXXXXXXUWLpVr",
                "quantities": "1,1",
            },
            "/v2/addresses/<address>/compose/order": {
                "give_asset": "XCP",
                "give_quantity": 1,
                "get_asset": "A4931122120200000000",
                "get_quantity": 1,
                "expiration": 2000,
                "fee_required": 0,
            },
            "/v2/addresses/<address>/compose/send": {
                "asset": "XCP",
                "quantity": 100,
                "destination": "1CounterpartyXXXXXXXXXXXXXXXUWLpVr",
            },
            "/v2/addresses/<address>/compose/sweep": {
                "destination": "1CounterpartyXXXXXXXXXXXXXXXUWLpVr",
                "flags": 7,
                "memo": "aa",
            },
            "/v2/addresses/<address>/compose/sweep/estimatexcpfees": {
                "destination": "1CounterpartyXXXXXXXXXXXXXXXUWLpVr",
                "flags": 7,
                "memo": "aa",
            },
            "/v2/addresses/<address>/compose/dispense": {
                "dispenser": last_dispenser["source"],
                "quantity": 1,
            },
            "/v2/addresses/<address>/compose/fairminter": {
                "asset": "LOADTEST",
                "max_mint_per_tx": 100,
            },
            "/v2/addresses/<address>/compose/fairmint": {
                "asset": last_fairminter["asset"],
            },
            "/v2/addresses/<address>/compose/attach": {
                "asset": "XCP",
                "quantity": 100,
            },
            "/v2/addresses/<address>/compose/attach/estimatexcpfees": {},
            "/v2/utxos/<utxo>/compose/detach": {},
            "/v2/utxos/<utxo>/compose/movetoutxo": {
                "destination": "1JDogZS6tQcSxwfxhv6XKKjcyicYA4Feev",
                "inputs_set": f"{utxo_with_balance['utxo']}:10000",
            },
        }
        compose_common_args = {
            "validate": "false",
            "pubkeys": "0426156245525daa71f2e84a40797bcf28099a2c508662a8a33324a703597b9aa2661a79a82ffb4caaa9b15f4094622fbfa85f8b9dc7381f991f5a265421391cc3",
            "exact_fee": 0,
            "disable_utxo_locks": "true",
        }

    db.close()
    return MainnetFixtures


def random_offset():
    return random.randint(1, 10000)  # noqa S311  # Example of random range


def random_limit():
    return random.randint(1, 1000)  # noqa S311


def random_verbose():
    return random.choice(["true", "false"])  # noqa S311


def random_params():
    return "&".join(
        [
            urllib.parse.urlencode({"offset": random_offset()}),
            urllib.parse.urlencode({"limit": random_limit()}),
            urllib.parse.urlencode({"verbose": random_verbose()}),
        ]
    )


def prepare_url(route, MainnetFixtures):
    # exclude broadcast signed tx and API v1
    if route in ["/v2/bitcoin/transactions", "/", "/v1/", "/api/", "/rpc/"]:
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

    if url == "/v2/transactions/<tx_hash>/info":
        url = url.replace("<tx_hash>", MainnetFixtures.jdog_tx_hash)
    elif url.startswith("/v2/issuances/"):
        url = url.replace("<tx_hash>", MainnetFixtures.last_issuance["tx_hash"])
    elif url.startswith("/v2/sweeps/"):
        url = url.replace("<tx_hash>", MainnetFixtures.last_sweep["tx_hash"])
    elif url.startswith("/v2/broadcasts/"):
        url = url.replace("<tx_hash>", MainnetFixtures.last_broadcast["tx_hash"])
    elif url.startswith("/v2/fairminters/"):
        url = url.replace("<tx_hash>", MainnetFixtures.last_fairminter["tx_hash"])
    elif url.startswith("/v2/fairmints/"):
        url = url.replace("<tx_hash>", MainnetFixtures.last_fairmint["tx_hash"])
    elif url.startswith("/v2/dispenses/"):
        url = url.replace("<tx_hash>", MainnetFixtures.last_dispense["tx_hash"])
    else:
        url = url.replace("<tx_hash>", MainnetFixtures.last_tx["tx_hash"])

    if url == "/v2/transactions/info":
        url = url + "?rawtransaction=" + MainnetFixtures.raw_transaction
    elif url == "/v2/bitcoin/transactions/decode":
        url = url + "?rawtx=" + MainnetFixtures.raw_transaction
    elif url == "/v2/transactions/unpack":
        url = url + "?datahex=" + MainnetFixtures.datahex
    elif url in [
        "/v2/addresses/balances",
        "/v2/addresses/transactions",
        "/v2/addresses/events",
        "/v2/addresses/mempool",
        "/v2/bitcoin/addresses/utxos",
    ]:
        url = url + "?addresses=" + MainnetFixtures.jdog_address
    elif url == "/v2/utxos/withbalances":
        url = url + "?utxos=" + MainnetFixtures.utxo_with_balance["utxo"]

    if "/compose/" in route:
        if MainnetFixtures.compose_args.get(route):
            params = MainnetFixtures.compose_args[route] | MainnetFixtures.compose_common_args
            query_string = []
            for key, value in params.items():
                if not isinstance(value, list):
                    query_string.append(urllib.parse.urlencode({key: value}))
                else:
                    for i in range(len(value)):
                        query_string.append(urllib.parse.urlencode({key: value[i]}))
            query_string = "&".join(query_string)
            url = url + "?" + query_string
        else:
            return None

    chr = "&" if "?" in url else "?"
    url = url + chr + random_params()

    return url


def generate_random_url(MainnetFixtures):
    while True:
        url = prepare_url(random.choice(list(ALL_ROUTES.keys())), MainnetFixtures)  # noqa S311
        if url:
            return url


class CounterpartyCoreUser(locust.HttpUser):
    host = "http://localhost:4000"  # Counterparty API URL
    wait_time = locust.between(0.5, 1)
    network_timeout = 15.0
    connection_timeout = 15.0
    MainnetFixtures = None

    @locust.task
    def get_random_url(self):
        headers = {"Content-Type": "application/json"}
        self.client.get(generate_random_url(CounterpartyCoreUser.MainnetFixtures), headers=headers)


def run_locust(db_file, duration=300, wait_time=None, user_count=4, stats_printer=True):
    CounterpartyCoreUser.MainnetFixtures = generate_mainnet_fixtures(db_file)
    CounterpartyCoreUser.wait_time = wait_time or locust.between(0.5, 1)

    locust.log.setup_logging("INFO")

    spawn_rate = 2
    test_duration = 60 * 5  # 5 minutes

    env = locust.env.Environment(user_classes=[CounterpartyCoreUser])
    env.create_local_runner()

    try:
        web_ui = env.create_web_ui("127.0.0.1", 8089)

        # start a greenlet that periodically outputs the current stats
        if stats_printer:
            gevent.spawn(locust.stats.stats_printer(env.stats))
        # start a greenlet that save current stats to history
        gevent.spawn(locust.stats.stats_history, env.runner)
        # start the test
        env.runner.start(user_count, spawn_rate=spawn_rate)
        # in test_duration seconds stop the runner
        if duration:
            gevent.spawn_later(test_duration, lambda: env.runner.quit())

        env.runner.greenlet.join()
    except KeyboardInterrupt:
        pass
    finally:
        if duration is None:
            env.runner.quit()
        web_ui.stop()

    return env


if __name__ == "__main__":
    run_locust(
        os.path.expanduser("~/.local/share/counterparty/counterparty.db"),
        duration=None,
        wait_time=locust.between(0.3, 0.6),
        user_count=3,
        stats_printer=False,
    )
