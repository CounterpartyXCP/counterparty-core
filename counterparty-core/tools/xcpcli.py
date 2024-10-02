#!/usr/bin/env python3

import argparse
import json
import sys
import urllib

import rich
import sh
from termcolor import colored

DEFAULT_CONFIG = {
    "wallet": "xcpwallet",
    "server": "http://localhost:24000",  # regtest
    "rpcconnect": "localhost",
    "network": "regtest",  # mine block after sending tx
    "rpcuser": "rpc",
    "rpcpassword": "rpc",  # noqa S105
}
CONFIG = DEFAULT_CONFIG


def bake_bitcoin_clients():
    bitcoin_cli = sh.bitcoin_cli.bake(
        f"-rpcuser={CONFIG['rpcuser']}",
        f"-rpcpassword={CONFIG['rpcpassword']}",
        f"-rpcconnect={CONFIG['rpcconnect']}",
    )
    if CONFIG["network"] == "regtest":
        bitcoin_cli = bitcoin_cli.bake("-regtest")
    if CONFIG["network"] == "testnet":
        bitcoin_cli = bitcoin_cli.bake("-testnet")
    bitcoin_wallet = bitcoin_cli.bake(f"-rpcwallet={CONFIG['wallet']}")
    return bitcoin_cli, bitcoin_wallet


class XCPCliError(Exception):
    pass


def check_curl_is_installed():
    try:
        sh.curl("--version")
    except sh.CommandNotFound as e:
        raise XCPCliError("Error: curl is required") from e


def check_bitcoin_cli_is_installed():
    try:
        bitcoin_cli, _bitcoin_wallet = bake_bitcoin_clients()
        bitcoin_cli("--version")
    except sh.CommandNotFound as e:
        raise XCPCliError("Error: bitcoin-cli is required") from e


def cprint(text, style=None):
    print(colored(text, style))


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
    url = f"{CONFIG['server']}{route}?{query_string}"
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


class ArgumentParser(argparse.ArgumentParser):
    def error(self, message):
        raise argparse.ArgumentError(None, message)


def get_parser(add_help=True, exit_on_error=True):
    prog = "xcpcli"
    description = "A basic counterparty-server and Bitcoin Core client"
    if exit_on_error:
        parser = argparse.ArgumentParser(prog=prog, description=description, add_help=add_help)
    else:
        parser = ArgumentParser(prog=prog, description=description, add_help=add_help)
    parser.add_argument(
        "--server", default=DEFAULT_CONFIG["server"], help="Counterparty server URL"
    )
    parser.add_argument(
        "--network",
        default=DEFAULT_CONFIG["network"],
        choices=["mainnet", "testnet", "regtest"],
        help="Bitcoin network",
    )
    parser.add_argument("--rpcuser", default=DEFAULT_CONFIG["rpcuser"], help="Bitcoin RPC user")
    parser.add_argument(
        "--rpcpassword", default=DEFAULT_CONFIG["rpcpassword"], help="Bitcoin RPC password"
    )
    parser.add_argument(
        "--rpcconnect", default=DEFAULT_CONFIG["rpcconnect"], help="Bitcoin RPC host"
    )
    parser.add_argument("--wallet", default=DEFAULT_CONFIG["wallet"], help="Bitcoin wallet name")
    return parser


def parse_args():
    global CONFIG  # noqa PLW0603

    parser = get_parser(add_help=False, exit_on_error=False)
    parser.add_argument("-h", "--help", action="store_true", help="show this help message and exit")

    try:
        options = parser.parse_known_args(sys.argv[1:])
        CONFIG = dict(vars(options[0]))
    except argparse.ArgumentError:
        pass

    routes = api_call("/v2/routes")["result"]
    route_by_function = {}

    parser = get_parser()
    subparsers = parser.add_subparsers(dest="apicall", help="the API call to make")
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
        raise Exception("Error: No command specified", "red")

    route = route_by_function[args.apicall]

    sign_and_send = False
    if args.apicall.startswith("send_"):
        sign_and_send = True

    params = dict(vars(args))
    del params["apicall"]

    return route, params, sign_and_send


def sign_and_send_transaction(result):
    if "error" in result:
        cprint(f"Error: {result['error']}", "red")
        return
    check_bitcoin_cli_is_installed()
    bitcoin_cli, bitcoin_wallet = bake_bitcoin_clients()
    rawtransaction = result["result"].get("rawtransaction") or result["result"].get(
        "unsigned_pretx_hex"
    )
    signed_transaction_json = bitcoin_wallet("signrawtransactionwithwallet", rawtransaction).strip()
    signed_transaction = json.loads(signed_transaction_json)["hex"]
    tx_hash = bitcoin_wallet("sendrawtransaction", signed_transaction, 0).strip()
    cprint(f"Transaction sent: {tx_hash}", "green")
    if CONFIG["network"] == "regtest":
        reward_address = bitcoin_wallet("getnewaddress", CONFIG["wallet"], "bech32").strip()
        bitcoin_cli("generatetoaddress", 1, reward_address)


def execute_command():
    check_curl_is_installed()
    route, params, sign_and_send = parse_args()

    result = api_call(route, params)
    rich.print_json(json.dumps(result, indent=4))

    if sign_and_send:
        sign_and_send_transaction(result)


if __name__ == "__main__":
    try:
        execute_command()
    except Exception as e:
        cprint(e, "red")
        exit(1)
