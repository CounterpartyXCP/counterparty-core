import json
import os
import sys

import requests
from counterpartycore import server

CURR_DIR = os.path.dirname(os.path.realpath(__file__))
API_DOC_FILE = os.path.join(CURR_DIR, "../../../Documentation/docs/advanced/api-v2/rest.md")
API_BLUEPRINT_FILE = os.path.join(CURR_DIR, "../../apiary.apib")
CACHE_FILE = os.path.join(CURR_DIR, "apicache.json")
API_ROOT = "http://api:api@localhost:4000"
USE_API_CACHE = True

TARGET_FILE = API_DOC_FILE
TARGET = "docusaurus"

if len(sys.argv) > 1 and sys.argv[1] == "blueprint":
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
]

GROUP_DOCS = {
    "Compose": """

**Notes about optional parameter `encoding`.**

By default the default value of the `encoding` parameter detailed above is `auto`, which means that `counterparty-server` automatically determines the best way to encode the Counterparty protocol data into a new transaction. If you know what you are doing and would like to explicitly specify an encoding:

- To return the transaction as an **OP_RETURN** transaction, specify `opreturn` for the `encoding` parameter.
   - **OP_RETURN** transactions cannot have more than 80 bytes of data. If you force OP_RETURN encoding and your transaction would have more than this amount, an exception will be generated.
- To return the transaction as a **multisig** transaction, specify `multisig` for the `encoding` parameter.
    - `pubkey` should be set to the hex-encoded public key of the source address.
    - Note that with the newest versions of Bitcoin (0.12.1 onward), bare multisig encoding does not reliably propagate. More information on this is documented [here](https://github.com/rubensayshi/counterparty-core/pull/9).
- To return the transaction as a **pubkeyhash** transaction, specify `pubkeyhash` for the `encoding` parameter.
    - `pubkey` should be set to the hex-encoded public key of the source address.
- To return the transaction as a 2 part **P2SH** transaction, specify `P2SH` for the encoding parameter.
    - First call the `create_` method with the `encoding` set to `P2SH`.
    - Sign the transaction as usual and broadcast it. It's recommended but not required to wait the transaction to confirm as malleability is an issue here (P2SH isn't yet supported on segwit addresses).
    - The resulting `txid` must be passed again on an identic call to the `create_` method, but now passing an additional parameter `p2sh_pretx_txid` with the value of the previous transaction's id.
    - The resulting transaction is a `P2SH` encoded message, using the redeem script on the transaction inputs as data carrying mechanism.
    - Sign the transaction following the `Bitcoinjs-lib on javascript, signing a P2SH redeeming transaction` section
    - **NOTE**: Don't leave pretxs hanging without transmitting the second transaction as this pollutes the UTXO set and risks making bitcoin harder to run on low spec nodes.

"""
}


def gen_groups_toc():
    toc = ""
    for group in GROUPS:
        if TARGET == "docusaurus":
            toc += f"- [`{group}`](#group-{group[1:]})\n"
        else:
            toc += f"- [`{group}`](#/reference{group})\n"
    return toc


if TARGET == "docusaurus":
    md = """---
title: ReST API V2
---

"""
else:
    md = ""

md += """FORMAT: 1A
HOST: https://api.counterparty.io

# Counterparty Core API

The Counterparty Core API is the recommended (and only supported) way to query the state of a Counterparty node. 

API routes are divided into 11 groups:
"""

md += gen_groups_toc()

md += """
Notes:

- When the server is not ready, that is to say when all the blocks are not yet parsed, all routes return a 503 error except `/` and those in the `/blocks`, `/transactions` and `/backend` groups which always return a result.

- All API responses contain the following 3 headers:

    * `X-COUNTERPARTY-HEIGHT` contains the last block parsed by Counterparty
    * `X-BITCOIN-HEIGHT` contains the last block known to Bitcoin Core
    * `X-COUNTERPARTY-READY` contains true if `X-COUNTERPARTY-HEIGHT` >= `X-BITCOIN-HEIGHT` - 1

- All API responses follow the following format:

    ``
    {
        "error": <error_messsage_if_success_is_false>,
        "result": <result_of_the_query_if_success_is_true>
    }
    ``

- Routes in the `/bitcoin` group serve as a proxy to make requests to Bitcoin Core.

# Counterparty API Root [{root_path}]

### Get Server Info [GET]

Returns server information and the list of documented routes in JSON format.

+ Response 200 (application/json)

    ``
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
    ``

"""
md = md.replace("{root_path}", root_path)

cache = {}
if USE_API_CACHE and os.path.exists(CACHE_FILE):
    with open(CACHE_FILE, "r") as f:
        cache = json.load(f)

current_group = None
for path, route in server.routes.ROUTES.items():
    route_group = path.split("/")[1]
    if "compose" in path:
        route_group = "Compose"
    if route_group != current_group:
        current_group = route_group
        if current_group == "healthz":
            current_group = "Z-Pages"
        md += f"\n## Group {current_group.capitalize()}\n"

    if current_group in GROUP_DOCS:
        md += GROUP_DOCS[current_group]

    blueprint_path = path.replace("<", "{").replace(">", "}").replace("int:", "")
    title = " ".join([part.capitalize() for part in str(route["function"].__name__).split("_")])
    title = title.replace("Pubkeyhash", "PubKeyHash")
    title = title.replace("Mpma", "MPMA")
    title = title.replace("Btcpay", "BTCPay")
    md += f"\n### {title.strip()} "
    if TARGET == "docusaurus":
        md += f"[GET `{blueprint_path}`]\n\n"
    else:
        for arg in route["args"]:
            if f"{{{arg['name']}}}" in blueprint_path:
                continue
            else:
                blueprint_path += f"{{?{arg['name']}}}"
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
        md += "    ``\n"
        for line in example_output_json.split("\n"):
            md += f"        {line}\n"
        md += "    ``\n"

with open(CACHE_FILE, "w") as f:
    json.dump(cache, f, indent=4)

with open(TARGET_FILE, "w") as f:
    f.write(md)
    print(f"API documentation written to {TARGET_FILE}")
