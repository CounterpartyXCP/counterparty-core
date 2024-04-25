import json
import os
import sys

import requests
from counterpartycore import server

CURR_DIR = os.path.dirname(os.path.realpath(__file__))
API_DOC_FILE = os.path.join(CURR_DIR, "../../../Documentation/docs/advanced/api-v2/rest.md")
API_BLUEPRINT_FILE = os.path.join(CURR_DIR, "../counterparty-core.apib")
CACHE_FILE = os.path.join(CURR_DIR, "apicache.json")
API_ROOT = "http://api:api@localhost:4000"
USE_API_CACHE = True

TARGET_FILE = API_DOC_FILE
TARGET = "docusaurus"

if len(sys.argv) and sys.argv[1] == "blueprint":
    TARGET_FILE = API_BLUEPRINT_FILE
    TARGET = "apiary"


def get_example_output(path, args):
    url_keys = []
    for key, value in args.items():
        if f"{key}>" in path:
            path = path.replace(f"<{key}>", value)
            path = path.replace(f"<int:{key}>", value)
            url_keys.append(key)
    for key in url_keys:
        args.pop(key)
    url = f"{API_ROOT}{path}"
    print(f"GET {url}")
    response = requests.get(url, params=args)  # noqa S113
    return response.json()


root_path = "`/`" if TARGET == "docusaurus" else "/"

if TARGET == "docusaurus":
    md = """---
title: REST API V2
---

"""
else:
    md = ""

md += """FORMAT: 1A
HOST: https://api.counterparty.io

# Counterparty Core API

The Counterparty Core API is the recommended (and only supported) way to query the state of a Counterparty node. 

API routes are divided into 11 groups:

- [`/blocks`](#group-blocks)
- [`/transactions`](#group-transactions)
- [`/addresses`](#group-addresses)
- [`/assets`](#group-assets)
- [`/orders`](#group-orders)
- [`/bets`](#group-bets)
- [`/dispensers`](#group-dispensers)
- [`/burns`](#group-burns)
- [`/events`](#group-events)
- [`/mempool`](#group-mempool)
- [`/backend`](#group-backend)

Notes:

- When the server is not ready, that is to say when all the blocks are not yet parsed, all routes return a 503 error except those in the `/blocks`, `/transactions` and `/backend` groups which always return a result.

- All API responses contain the following 3 headers:

    * `X-COUNTERPARTY-HEIGHT` contains the last block parsed by Counterparty
    * `X-BACKEND-HEIGHT` contains the last block known to Bitcoin Core
    * `X-COUNTERPARTY-READY` contains true if `X-COUNTERPARTY-HEIGHT` >= `X-BACKEND-HEIGHT` - 1

- All API responses follow the following format:

    ```
    {
        "error": <error_messsage_if_success_is_false>,
        "result": <result_of_the_query_if_success_is_true>
    }
    ```

- Routes in the `/backend` group serve as a proxy to make requests to AddrindexRS.

## Root Path

### Get Server Info [GET {root_path}]

Returns server information and the list of documented routes in JSON format.

+ Response 200 (application/json)

    ```
    {
        "server_ready": true,
        "network": "mainnet",
        "version": "10.1.1",
        "backend_height": 840796,
        "counterparty_height": 840796,
        "routes": [
            <API Documentation in JSON>
        ]
    }
    ```

"""
md = md.replace("{root_path}", root_path)

cache = {}
if USE_API_CACHE and os.path.exists(CACHE_FILE):
    with open(CACHE_FILE, "r") as f:
        cache = json.load(f)

current_group = None
for path, route in server.routes.ROUTES.items():
    route_group = path.split("/")[1]
    if route_group != current_group:
        current_group = route_group
        md += f"\n## Group {current_group.capitalize()}\n"
    blueprint_path = path.replace("<", "{").replace(">", "}").replace("int:", "")

    title = " ".join([part.capitalize() for part in str(route["function"].__name__).split("_")])
    md += f"\n### {title} "
    if TARGET == "docusaurus":
        md += f"[GET `{blueprint_path}`]\n\n"
    else:
        for arg in route["args"]:
            if f"{{{arg['name']}}}" in blueprint_path:
                continue
            else:
                blueprint_path += f"{{?{arg['name']}}}"
        md += f"[GET {blueprint_path}]\n\n"

    md += route["description"]

    example_args = {}
    if len(route["args"]) > 0:
        md += "\n\n+ Parameters\n"
        for arg in route["args"]:
            required = "required" if arg["required"] else "optional"
            description = arg.get("description", "")
            example_arg = ""
            if "(e.g. " in description:
                desc_arr = description.split("(e.g. ")
                description = desc_arr[0].replace("\n", " ")
                example_args[arg["name"]] = desc_arr[1].replace(")", "")
                example_arg = f": `{example_args[arg['name']]}`"
            md += f"    + {arg['name']}{example_arg} ({arg['type']}, {required}) - {description}\n"
            if not arg["required"]:
                md += f"        + Default: `{arg.get('default', '')}`\n"

    if example_args != {} or route["args"] == []:
        if not USE_API_CACHE or path not in cache:
            example_output = get_example_output(path, example_args)
            cache[path] = example_output
        else:
            example_output = cache[path]
        example_output_json = json.dumps(example_output, indent=4)
        md += "\n+ Response 200 (application/json)\n\n"
        md += "    ```\n"
        for line in example_output_json.split("\n"):
            md += f"        {line}\n"
        md += "    ```\n"

with open(CACHE_FILE, "w") as f:
    json.dump(cache, f, indent=4)

with open(TARGET_FILE, "w") as f:
    f.write(md)
    print(f"API documentation written to {TARGET_FILE}")
