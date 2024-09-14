#!/usr/bin/env python3

import argparse
import json
import urllib

import rich
import sh
from termcolor import colored

WALLET_NAME = "xcpwallet"
COUNTERPARTY_SERVER = "http://localhost:24000"  # regtest
BITCOIN_HOST = "localhost"
BITCOIN_NETWORK = "regtest"  # mine block after sending tx
BITCOIN_RPC_USER = "rpc"
BITCOIN_RPC_PASSWORD = "rpc"  # noqa S105

bitcoin_cli = sh.bitcoin_cli.bake(
    f"-rpcuser={BITCOIN_RPC_USER}",
    f"-rpcpassword={BITCOIN_RPC_PASSWORD}",
    f"-rpcconnect={BITCOIN_HOST}",
)
if BITCOIN_NETWORK == "regtest":
    bitcoin_cli = bitcoin_cli.bake("-regtest")
if BITCOIN_NETWORK == "testnet":
    bitcoin_cli = bitcoin_cli.bake("-testnet")

bitcoin_wallet = bitcoin_cli.bake(f"-rpcwallet={WALLET_NAME}")


def api_call(route, params=None):
    params = params or {}
    params_in_url = []
    for key, value in params.items():
        if f"<{key}>" in route:
            route = route.replace(f"<{key}>", value)
            params_in_url.append(key)
    for key in params_in_url:
        del params[key]
    query_string = urllib.parse.urlencode(params)
    url = f"{COUNTERPARTY_SERVER}{route}?{query_string}"
    return json.loads(sh.curl(url).strip())


def get_default(arg):
    if "default" not in arg:
        return None
    if arg["required"]:
        return None
    if arg["type"] == "bool":
        return arg["default"] == "true"
    return arg["default"]


def get_action(arg):
    if arg["type"] == "bool" and not get_default(arg):
        return "store_true"
    return "store"


def add_command_parser(subparsers, route_info):
    route_parser = subparsers.add_parser(route_info["function"], help=route_info["description"])
    for arg in route_info["args"]:
        route_parser.add_argument(
            f"--{arg['name']}",
            action=get_action(arg),
            required=arg.get("required", False),
            default=get_default(arg),
            help=arg.get("description", ""),
        )
    return route_parser


def parse_args():
    parser = argparse.ArgumentParser(
        prog="xcpcli", description="A basic counterparty-server and Bitcoin Core client"
    )

    subparsers = parser.add_subparsers(dest="apicall", help="the API call to make")
    routes = api_call("/v2/routes")["result"]
    route_by_function = {}

    for route, route_info in routes.items():
        if not route.startswith("/v2/"):
            continue
        add_command_parser(subparsers, route_info)
        route_by_function[route_info["function"]] = route
        if route_info["function"].startswith("compose_"):
            route_info["function"] = route_info["function"].replace("compose_", "send_")
            route_info["description"] = route_info["description"].replace(
                "Composes a transaction", "Composes, signs and sends a transaction"
            )
            add_command_parser(subparsers, route_info)
            route_by_function[route_info["function"]] = route

    args = parser.parse_args()
    if not args.apicall:
        parser.print_help()
        raise Exception("Error: No API call specified", "red")

    route = route_by_function[args.apicall]

    sign_and_send = False
    if args.apicall.startswith("send_"):
        sign_and_send = True

    params = dict(vars(args))
    del params["apicall"]

    return route, params, sign_and_send


def execute_command():
    route, params, sign_and_send = parse_args()

    result = api_call(route, params)
    rich.print_json(json.dumps(result, indent=4))

    if sign_and_send:
        if "error" in result:
            print(colored(f"Error: {result['error']}", "red"))
            return
        print("Signing and sending transaction...")
        signed_transaction_json = bitcoin_wallet(
            "signrawtransactionwithwallet", result["result"]["rawtransaction"]
        ).strip()
        signed_transaction = json.loads(signed_transaction_json)["hex"]
        tx_hash = bitcoin_wallet("sendrawtransaction", signed_transaction, 0).strip()
        print(colored(f"Transaction sent: {tx_hash}", "green"))
        if BITCOIN_NETWORK == "regtest":
            reward_address = bitcoin_wallet("getnewaddress", WALLET_NAME, "bech32").strip()
            bitcoin_cli("generatetoaddress", 1, reward_address)
            print("Block mined")


if __name__ == "__main__":
    execute_command()
