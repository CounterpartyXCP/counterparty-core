import datetime
import json
import os
import sys

import requests
import sh
import yaml
from counterpartycore.lib import database
from counterpartycore.lib.api import routes

CURR_DIR = os.path.dirname(os.path.realpath(__file__))
API_BLUEPRINT_FILE = os.path.join(CURR_DIR, "../../../../apiary.apib")
DREDD_FILE = os.path.join(CURR_DIR, "../../../../dredd.yml")
CACHE_FILE = os.path.join(CURR_DIR, "apidoc", "apicache.json")
API_ROOT = "http://localhost:24000"

USE_API_CACHE = True
API_CACHE = {}
if USE_API_CACHE and os.path.exists(CACHE_FILE):
    with open(CACHE_FILE, "r") as f:
        API_CACHE = json.load(f)


EVENT_LIST = [
    {
        "group": "Blocks and Transactions",
        "events": [
            "NEW_BLOCK",
            "NEW_TRANSACTION",
            "NEW_TRANSACTION_OUTPUT",
            "BLOCK_PARSED",
            "TRANSACTION_PARSED",
        ],
    },
    {
        "group": "Asset Movements",
        "events": [
            "DEBIT",
            "CREDIT",
            "ENHANCED_SEND",
            "MPMA_SEND",
            "SEND",
            "ASSET_TRANSFER",
            "SWEEP",
            "ASSET_DIVIDEND",
        ],
    },
    {
        "group": "Asset Creation and Destruction",
        "events": [
            "RESET_ISSUANCE",
            "ASSET_CREATION",
            "ASSET_ISSUANCE",
            "ASSET_DESTRUCTION",
        ],
    },
    {
        "group": "DEX",
        "events": [
            "OPEN_ORDER",
            "ORDER_MATCH",
            "ORDER_UPDATE",
            "ORDER_FILLED",
            "ORDER_MATCH_UPDATE",
            "BTC_PAY",
            "CANCEL_ORDER",
            "ORDER_EXPIRATION",
            "ORDER_MATCH_EXPIRATION",
        ],
    },
    {
        "group": "Dispenser",
        "events": [
            "OPEN_DISPENSER",
            "DISPENSER_UPDATE",
            "REFILL_DISPENSER",
            "DISPENSE",
        ],
    },
    {
        "group": "Broadcast",
        "events": [
            "BROADCAST",
        ],
    },
    {
        "group": "Fair Minting",
        "events": [
            "NEW_FAIRMINTER",
            "FAIRMINTER_UPDATE",
            "NEW_FAIRMINT",
        ],
    },
    {
        "group": "UTXO Support",
        "events": [
            "ATTACH_TO_UTXO",
            "DETACH_FROM_UTXO",
            "UTXO_MOVE",
        ],
    },
    # {
    #    "group": "Bets",
    #    "events": [
    #        "OPEN_BET",
    #        "BET_UPDATE",
    #        "BET_MATCH",
    #        "BET_MATCH_UPDATE",
    #        "BET_EXPIRATION",
    #        "BET_MATCH_EXPIRATION",
    #        "BET_MATCH_RESOLUTON",
    #        "CANCEL_BET",
    #    ],
    # },
    {
        "group": "Burns",
        "events": [
            "BURN",
        ],
    },
]


DREDD_CONFIG = {
    "loglevel": "error",
    "path": [],
    "blueprint": "apiary.apib",
    "endpoint": "http://127.0.0.1:24000",
    "only": [],
}


def get_example_output(path, args):
    print(f"args: {args}")
    url_keys = []
    for key, value in args.items():
        if f"{key}>" in path:
            path = path.replace(f"<{key}>", value)
            path = path.replace(f"<int:{key}>", value)
            path = path.replace(f"<path:{key}>", value)
            url_keys.append(key)
    for key in url_keys:
        args.pop(key)
    url = f"{API_ROOT}{path}"
    print(f"GET {url}")
    if "v2/" in path:
        args["verbose"] = "true"
    response = requests.get(url, params=args)  # noqa S113
    return response.json()


def include_in_dredd(group, path):
    if "/bet" in path:
        return False
    return True


def gen_groups_toc():
    groups = []
    for path, _route in routes.ROUTES.items():
        route_group = get_groupe_name(path)
        if route_group not in groups:
            groups.append(route_group)

    toc = ""
    for group in groups:
        toc += f"- [`{group}`](#/reference/{group})\n"
    return toc


def get_groupe_name(path):
    if "healthz" in path:
        return "Z-Pages"
    if "compose" in path:
        return "compose"
    if "v2/" in path:
        return path.split("/")[2]
    return "v1"


def gen_blueprint(db):
    md = ""
    dredd = DREDD_CONFIG.copy()
    current_group = None
    for path, route in routes.ROUTES.items():
        route_group = get_groupe_name(path)
        if route_group != current_group:
            current_group = route_group
            md += f"\n## Group {current_group.capitalize()}\n"

            group_doc_path = os.path.join(CURR_DIR, "apidoc", f"group-{current_group.lower()}.md")
            if os.path.exists(group_doc_path):
                with open(group_doc_path, "r") as f:
                    md += f.read()
            if current_group == "transactions":
                md += gen_unpack_doc(db)

        blueprint_path = (
            path.replace("<", "{").replace(">", "}").replace("int:", "").replace("path:", "")
        )
        title = " ".join([part.capitalize() for part in str(route["function"].__name__).split("_")])
        title = title.replace("Pubkeyhash", "PubKeyHash")
        title = title.replace("Mpma", "MPMA")
        title = title.replace("Btcpay", "BTCPay")
        title = title.strip()

        if include_in_dredd(current_group, blueprint_path):
            dredd_name = f"{current_group.capitalize()} > {title} > {title}"
            dredd["only"].append(dredd_name)

        md += f"\n### {title} "

        first_query_arg = True
        for arg in route["args"]:
            if f"{{{arg['name']}}}" in blueprint_path:
                continue
            else:
                prefix = "?" if first_query_arg else "&"
                first_query_arg = False
                blueprint_path += f"{{{prefix}{arg['name']}}}"
        md += f"[GET {blueprint_path}]\n\n"

        md += route["description"].strip()

        example_args = {}
        regtest_fixtures = generate_regtest_fixtures(db)

        if len(route["args"]) > 0:
            md += "\n\n+ Parameters\n"
            for arg in route["args"]:
                required = "required" if arg["required"] else "optional"
                description = arg.get("description", "")
                example_arg = ""
                if "(e.g. " in description:
                    desc_arr = description.split("(e.g. ")
                    description = desc_arr[0].replace("\n", " ").strip()
                    example_args[arg["name"]] = desc_arr[1].replace(")", "")

                    for key, value in regtest_fixtures.items():
                        example_args[arg["name"]] = example_args[arg["name"]].replace(
                            key, str(value)
                        )

                    example_arg = f": `{example_args[arg['name']]}`"
                elif arg["name"] == "verbose":
                    example_arg = ": `true`"
                md += f"    + {arg['name']}{example_arg} ({arg['type']}, {required}) - {description}\n"
                if not arg["required"]:
                    md += f"        + Default: `{arg.get('default', '')}`\n"
                if "members" in arg:
                    md += "        + Members\n"
                    for member in arg["members"]:
                        md += f"            + `{member}`\n"

        if (
            example_args != {} or len(route["args"]) == 1 or "healthz" in path
        ):  # min 1 for verbose arg
            if not USE_API_CACHE or path not in API_CACHE:
                example_output = get_example_output(path, example_args)
                API_CACHE[path] = example_output
            else:
                example_output = API_CACHE[path]
            example_output_json = json.dumps(example_output, indent=4)
            md += "\n+ Response 200 (application/json)\n\n"
            md += "    ```\n"
            for line in example_output_json.split("\n"):
                md += f"        {line}\n"
            md += "    ```\n"
    return md, dredd


def update_blueprint(db):
    md = ""
    with open(os.path.join(CURR_DIR, "apidoc", "blueprint-template.md"), "r") as f:
        md += f.read()

    blueprint, dredd = gen_blueprint(db)

    md = md.replace("<GROUP_TOC>", gen_groups_toc())
    md = md.replace("<EVENTS_DOC>", gen_events_doc())
    md = md.replace("<API_BLUEPRINT>", blueprint)

    md = (
        f"[//]: # (Generated by genapidoc.py on {datetime.datetime.now()}. Do not edit manually.)\n"
        + md
    )

    with open(API_BLUEPRINT_FILE, "w") as f:
        f.write(md)
        print(f"API documentation written to {API_BLUEPRINT_FILE}")

    with open(DREDD_FILE, "w") as f:
        yaml.dump(dredd, f)
        print(f"Dredd file written to {DREDD_FILE}")


def gen_events_doc():
    md = ""
    for event_group in EVENT_LIST:
        md += f"\n### {event_group['group']}\n"
        for event in event_group["events"]:
            md += f"\n#### `{event}`\n\n"
            path = f"/v2/events/{event}"
            if not USE_API_CACHE or path not in API_CACHE:
                example_output = get_example_output(path, {"limit": "1", "verbose": "true"})
                API_CACHE[path] = example_output
            else:
                example_output = API_CACHE[path]
            example_output_json = json.dumps(example_output, indent=4)
            md += "```\n"
            for line in example_output_json.split("\n"):
                md += f"{line}\n"
            md += "```\n"
    return md


def get_event_tx_hash(db, event_name):
    cursor = db.cursor()
    cursor.execute(
        "SELECT tx_hash FROM messages WHERE event=? ORDER BY rowid DESC LIMIT 1",
        (event_name,),
    )
    row = cursor.fetchone()
    return row["tx_hash"]


def gen_unpack_doc(db):
    message_type_names = [
        "broadcast",
        "btcpay",
        "cancel",
        "destroy",
        "dispenser",
        "dispense",
        "dividend",
        "issuance",
        "order",
        "enhanced_send",
        "mpma_send",
        "sweep",
        # "send",
        # "bet",
    ]
    message_type_tx_hash = {
        "cancel": get_event_tx_hash(db, "CANCEL_ORDER"),
        "dispenser": get_event_tx_hash(db, "OPEN_DISPENSER"),
        "enhanced_send": get_event_tx_hash(db, "ENHANCED_SEND"),
        "destroy": get_event_tx_hash(db, "ASSET_DESTRUCTION"),
        "dispense": get_event_tx_hash(db, "DISPENSE"),
        "issuance": get_event_tx_hash(db, "ASSET_CREATION"),
        "order": get_event_tx_hash(db, "OPEN_ORDER"),
        "mpma_send": get_event_tx_hash(db, "MPMA_SEND"),
        "broadcast": get_event_tx_hash(db, "BROADCAST"),
        "dividend": get_event_tx_hash(db, "ASSET_DIVIDEND"),
        "sweep": get_event_tx_hash(db, "SWEEP"),
        "btcpay": get_event_tx_hash(db, "BTC_PAY"),
        # "send": ,
        # "bet": ,
    }

    md = f"\nThere are {len(message_type_names)} types of transactions:\n\n"
    md += "\n".join([f"- `{message_name}`" for message_name in message_type_names])
    md += "\n\nHere is sample API output for each of these transactions:\n"

    for message_name in message_type_names:
        url = f"{API_ROOT}/v2/transactions/{message_type_tx_hash[message_name]}"
        args = {"verbose": "true"}
        print(url)
        response = requests.get(url, params=args)  # noqa S113
        result = response.json()
        md += f"\n**{message_name.capitalize()}**\n\n"
        md += "```\n"
        md += json.dumps(result, indent=4)
        md += "\n```\n"

    return md


def update_doc(db):
    update_blueprint(db)

    with open(CACHE_FILE, "w") as f:
        json.dump(API_CACHE, f, indent=4)
        print(f"Cache file written to {CACHE_FILE}")


def generate_regtest_fixtures(db):
    regtest_fixtures = {}
    cursor = db.cursor()

    # addresses
    cursor.execute("SELECT source FROM burns ORDER BY source")
    for i, row in enumerate(cursor.fetchall()):
        regtest_fixtures[f"$ADDRESS_{i + 1}"] = row["source"]

    # assets
    cursor.execute(
        "SELECT asset_name FROM assets WHERE asset_name not like 'A%' and asset_name not in ('BTC', 'XCP')"
    )
    for i, row in enumerate(cursor.fetchall()):
        regtest_fixtures[f"$ASSET_{i + 1}"] = row["asset_name"]

    # dispensers
    cursor.execute("SELECT tx_hash, asset FROM dispensers ORDER BY rowid")
    for i, row in enumerate(cursor.fetchall()):
        regtest_fixtures[f"$DISPENSER_TX_HASH_{i + 1}"] = row["tx_hash"]

    # last transaction
    cursor.execute("SELECT tx_hash, tx_index FROM transactions ORDER BY rowid DESC LIMIT 1")
    row = cursor.fetchone()
    regtest_fixtures["$LAST_TX_HASH"] = row["tx_hash"]
    regtest_fixtures["$LAST_TX_INDEX"] = row["tx_index"]

    # last block
    cursor.execute("SELECT block_hash, block_index FROM blocks ORDER BY rowid DESC LIMIT 1")
    row = cursor.fetchone()
    regtest_fixtures["$LAST_BLOCK_HASH"] = row["block_hash"]
    regtest_fixtures["$LAST_BLOCK_INDEX"] = row["block_index"]

    # last message
    cursor.execute("SELECT message_index FROM messages ORDER BY rowid DESC LIMIT 1")
    row = cursor.fetchone()
    regtest_fixtures["$LAST_EVENT_INDEX"] = row["message_index"]

    # blocks with sends
    cursor.execute("SELECT block_index FROM sends ORDER BY rowid DESC LIMIT 1")
    row = cursor.fetchone()
    regtest_fixtures["$LAST_SEND_BLOCK"] = row["block_index"]

    # transactions with sends
    cursor.execute("SELECT tx_hash FROM sends ORDER BY rowid DESC LIMIT 1")
    row = cursor.fetchone()
    regtest_fixtures["$LAST_SEND_TX_HASH"] = row["tx_hash"]

    # blocks with order expiration
    cursor.execute("SELECT block_index FROM order_expirations ORDER BY rowid DESC LIMIT 1")
    row = cursor.fetchone()
    regtest_fixtures["$LAST_ORDER_EXPIRATION_BLOCK"] = row["block_index"]

    # blocks with destructions
    cursor.execute("SELECT block_index FROM destructions ORDER BY rowid DESC LIMIT 1")
    row = cursor.fetchone()
    regtest_fixtures["$LAST_DESTRUCTION_BLOCK"] = row["block_index"]

    # block and tx with issuances
    cursor.execute("SELECT block_index, tx_hash FROM issuances ORDER BY rowid DESC LIMIT 1")
    row = cursor.fetchone()
    regtest_fixtures["$LAST_ISSUANCE_BLOCK"] = row["block_index"]
    regtest_fixtures["$LAST_ISSUANCE_TX_HASH"] = row["tx_hash"]

    # block and tx with dispenses
    cursor.execute("SELECT block_index, tx_hash FROM dispenses ORDER BY rowid DESC LIMIT 1")
    row = cursor.fetchone()
    regtest_fixtures["$LAST_DISPENSE_BLOCK"] = row["block_index"]
    regtest_fixtures["$LAST_DISPENSE_TX_HASH"] = row["tx_hash"]

    # block and tx with dividends
    cursor.execute("SELECT block_index, tx_hash FROM dividends ORDER BY rowid DESC LIMIT 1")
    row = cursor.fetchone()
    regtest_fixtures["$LAST_DIVIDEND_BLOCK"] = row["block_index"]
    regtest_fixtures["$LAST_DIVIDEND_TX_HASH"] = row["tx_hash"]

    # block and tx with orders
    cursor.execute("SELECT block_index, tx_hash FROM orders ORDER BY rowid DESC LIMIT 1")
    row = cursor.fetchone()
    regtest_fixtures["$LAST_ORDER_BLOCK"] = row["block_index"]
    regtest_fixtures["$LAST_ORDER_TX_HASH"] = row["tx_hash"]

    # block and tx with fairminter
    cursor.execute("SELECT block_index, tx_hash FROM fairminters ORDER BY rowid DESC LIMIT 1")
    row = cursor.fetchone()
    regtest_fixtures["$LAST_FAIRMINTER_BLOCK"] = row["block_index"]
    regtest_fixtures["$LAST_FAIRMINTER_TX_HASH"] = row["tx_hash"]

    # get utxo from bitcoin-cli
    utxo = json.loads(
        sh.bitcoin_cli(
            "-regtest", "listunspent", 0, 9999999, f'["{regtest_fixtures["$ADDRESS_1"]}"]'
        ).strip()
    )[0]
    txid = utxo["txid"]
    utxo = utxo["txid"] + ":" + str(utxo["vout"])

    regtest_fixtures["$UTXO_1_ADDRESS_1"] = utxo

    # get utxo with balance
    cursor.execute(
        "SELECT utxo FROM balances WHERE utxo IS NOT NULL AND quantity > 0 ORDER BY rowid DESC LIMIT 1"
    )
    row = cursor.fetchone()
    regtest_fixtures["$UTXO_WITH_BALANCE"] = row["utxo"]

    # rawtransaction
    regtest_fixtures["$RAW_TRANSACTION_1"] = sh.bitcoin_cli(
        "-regtest", "getrawtransaction", txid
    ).strip()

    # block and tx with sweeps
    cursor.execute("SELECT block_index, tx_hash FROM sweeps ORDER BY rowid DESC LIMIT 1")
    row = cursor.fetchone()
    regtest_fixtures["$LAST_SWEEP_BLOCK"] = row["block_index"]
    regtest_fixtures["$LAST_SWEEP_TX_HASH"] = row["tx_hash"]

    # block and tx with btcpay
    cursor.execute(
        "SELECT block_index, tx_hash, order_match_id FROM btcpays ORDER BY rowid DESC LIMIT 1"
    )
    row = cursor.fetchone()
    regtest_fixtures["$LAST_BTCPAY_BLOCK"] = row["block_index"]
    regtest_fixtures["$LAST_BTCPAY_TX_HASH"] = row["tx_hash"]
    regtest_fixtures["$ORDER_WITH_BTCPAY_HASH"] = row["order_match_id"].split("_")[0]

    # block and tx with broadcasts
    cursor.execute("SELECT block_index, tx_hash FROM broadcasts ORDER BY rowid DESC LIMIT 1")
    row = cursor.fetchone()
    regtest_fixtures["$LAST_BROADCAST_BLOCK"] = row["block_index"]
    regtest_fixtures["$LAST_BROADCAST_TX_HASH"] = row["tx_hash"]

    # block and tx with order_matches
    cursor.execute("SELECT block_index, id FROM order_matches ORDER BY rowid DESC LIMIT 1")
    row = cursor.fetchone()
    regtest_fixtures["$LAST_ORDER_MATCH_BLOCK"] = row["block_index"]
    regtest_fixtures["$LAST_ORDER_MATCH_ID"] = row["id"]
    regtest_fixtures["$ORDER_WITH_MATCH_HASH"] = row["id"].split("_")[0]

    # block with cancels
    cursor.execute("SELECT block_index FROM cancels ORDER BY rowid DESC LIMIT 1")
    row = cursor.fetchone()
    regtest_fixtures["$LAST_CANCEL_BLOCK"] = row["block_index"]

    # block with credits
    cursor.execute("SELECT block_index FROM credits ORDER BY rowid DESC LIMIT 1")
    row = cursor.fetchone()
    regtest_fixtures["$LAST_CREDIT_BLOCK"] = row["block_index"]

    # block with debits
    cursor.execute("SELECT block_index FROM debits ORDER BY rowid DESC LIMIT 1")
    row = cursor.fetchone()
    regtest_fixtures["$LAST_DEBIT_BLOCK"] = row["block_index"]

    # transactions with events
    cursor.execute(
        "SELECT tx_hash, block_index FROM messages WHERE event='CREDIT' ORDER BY rowid DESC LIMIT 1"
    )
    row = cursor.fetchone()
    regtest_fixtures["$LAST_EVENT_TX_HASH"] = row["tx_hash"]
    regtest_fixtures["$LAST_EVENT_BLOCK"] = row["block_index"]
    cursor.execute("SELECT tx_index FROM transactions WHERE tx_hash=?", (row["tx_hash"],))
    row = cursor.fetchone()
    regtest_fixtures["$LAST_EVENT_TX_INDEX"] = row["tx_index"]

    # transaction in mempool
    cursor.execute("SELECT tx_hash FROM mempool ORDER BY rowid DESC LIMIT 1")
    row = cursor.fetchone()
    regtest_fixtures["$LAST_MEMPOOL_TX_HASH"] = row["tx_hash"]

    return regtest_fixtures


if __name__ == "__main__":
    data_dir = sys.argv[1] if len(sys.argv) > 1 else "regtestnode"
    db = database.get_db_connection(f"{data_dir}/counterparty.db", read_only=True, check_wal=False)
    update_doc(db)
