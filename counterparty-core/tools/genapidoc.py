import datetime
import json
import os

import requests
import yaml
from counterpartycore.lib.api import routes

CURR_DIR = os.path.dirname(os.path.realpath(__file__))
API_DOC_FILE = os.path.join(CURR_DIR, "../../../Documentation/docs/advanced/api-v2/node-api.md")
API_BLUEPRINT_FILE = os.path.join(CURR_DIR, "../../apiary.apib")
DREDD_FILE = os.path.join(CURR_DIR, "../../dredd.yml")
CACHE_FILE = os.path.join(CURR_DIR, "apidoc", "apicache.json")
API_ROOT = "http://localhost:4000"

USE_API_CACHE = True
API_CACHE = {}
if USE_API_CACHE and os.path.exists(CACHE_FILE):
    with open(CACHE_FILE, "r") as f:
        API_CACHE = json.load(f)


GROUPS = [
    "/blocks",
    "/transactions",
    "/addresses",
    "/compose",
    "/assets",
    "/orders",
    "/bets",
    "/dispensers",
    "/burns",
    "/events",
    "/mempool",
    "/bitcoin",
    "/v1",
]

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
        "group": "Bets",
        "events": [
            "OPEN_BET",
            "BET_UPDATE",
            "BET_MATCH",
            "BET_MATCH_UPDATE",
            "BET_EXPIRATION",
            "BET_MATCH_EXPIRATION",
            "BET_MATCH_RESOLUTON",
            "CANCEL_BET",
        ],
    },
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
    "endpoint": "http://127.0.0.1:4000",
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
    if group in ["Compose", "bitcoin", "mempool"]:
        return False
    if path in ["/events/counts"]:
        return False
    return True


def gen_groups_toc(target):
    toc = ""
    for group in GROUPS:
        if target == "docusaurus":
            toc += f"- [`{group}`](#group-{group[1:]})\n"
        else:
            toc += f"- [`{group}`](#/reference{group})\n"
    return toc


def gen_blueprint(target):
    md = ""
    dredd = DREDD_CONFIG.copy()
    current_group = None
    for path, route in routes.ROUTES.items():
        path_parts = path.split("/")
        if "healthz" in path:
            route_group = "Z-Pages"
        elif path_parts[1] == "v2":
            route_group = path.split("/")[2]
        else:
            route_group = "v1"
        if "compose" in path:
            route_group = "Compose"
        if route_group != current_group:
            current_group = route_group
            md += f"\n## Group {current_group.capitalize()}\n"

            group_doc_path = os.path.join(CURR_DIR, "apidoc", f"group-{current_group.lower()}.md")
            if os.path.exists(group_doc_path):
                with open(group_doc_path, "r") as f:
                    md += f.read()

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
        if target == "docusaurus":
            md += f"[GET `{blueprint_path}`]\n\n"
        else:
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
                    example_arg = f": `{example_args[arg['name']]}`"
                elif arg["name"] == "verbose":
                    example_arg = ": `true`"
                md += f"    + {arg['name']}{example_arg} ({arg['type']}, {required}) - {description}\n"
                if not arg["required"]:
                    md += f"        + Default: `{arg.get('default', '')}`\n"

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


def get_route_path(target):
    if target == "docusaurus":
        return "`/v2/`"
    return "/v2/"


def get_header(target):
    if target == "docusaurus":
        return """---
title: API v2
---

"""
    return ""


def update_blueprint(target, save_dredd=False):
    md = get_header(target)
    with open(os.path.join(CURR_DIR, "apidoc", "blueprint-template.md"), "r") as f:
        md += f.read()

    blueprint, dredd = gen_blueprint(target)

    md = md.replace("<GROUP_TOC>", gen_groups_toc(target))
    md = md.replace("<EVENTS_DOC>", gen_events_doc())
    md = md.replace("<ROOT_PATH>", get_route_path(target))
    md = md.replace("<API_BLUEPRINT>", blueprint)

    md = (
        f"[//]: # (Generated by genapidoc.py on {datetime.datetime.now()}. Do not edit manually.)\n"
        + md
    )

    target_file = API_DOC_FILE
    if target == "apiary":
        target_file = API_BLUEPRINT_FILE
    with open(target_file, "w") as f:
        f.write(md)
        print(f"API documentation written to {target_file}")

    if save_dredd:
        with open(DREDD_FILE, "w") as f:
            yaml.dump(dredd, f)
            print(f"Dredd file written to {DREDD_FILE}")


def gen_events_doc():
    md = ""
    for event_group in EVENT_LIST:
        md += f"\n#### {event_group['group']}\n"
        for event in event_group["events"]:
            md += f"\n##### `{event}`\n\n"
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


def update_doc():
    update_blueprint("apiary")
    update_blueprint("docusaurus", save_dredd=True)

    with open(CACHE_FILE, "w") as f:
        json.dump(API_CACHE, f, indent=4)
        print(f"Cache file written to {CACHE_FILE}")


update_doc()
