#! /usr/bin/env python3

import argparse
import getpass
import logging
import os
import sys
from decimal import Decimal as D

from counterpartylib.lib import log

logger = logging.getLogger(__name__)

from counterpartylib.lib import config, script  # noqa: E402
from counterpartylib.lib.exceptions import TransactionError  # noqa: E402
from counterpartylib.lib.log import isodt  # noqa: E402, F401
from counterpartylib.lib.util import BET_TYPE_NAME, make_id  # noqa: E402, F401

from counterpartycli import APP_VERSION, clientapi, console, messages, util, wallet  # noqa: E402
from counterpartycli.setup import generate_config_files  # noqa: E402
from counterpartycli.util import add_config_arguments, read_config_file  # noqa: E402

APP_NAME = "counterparty-client"

CONFIG_ARGS = [
    [
        ("-v", "--verbose"),
        {
            "dest": "verbose",
            "action": "store_true",
            "help": "sets log level to DEBUG instead of WARNING",
        },
    ],
    [
        ("--testnet",),
        {
            "action": "store_true",
            "default": False,
            "help": f"use {config.BTC_NAME} testnet addresses and block numbers",
        },
    ],
    [
        ("--testcoin",),
        {
            "action": "store_true",
            "default": False,
            "help": f"use the test {config.XCP_NAME} network on every blockchain",
        },
    ],
    [
        ("--regtest",),
        {
            "action": "store_true",
            "default": False,
            "help": f"use {config.BTC_NAME} regtest addresses and block numbers",
        },
    ],
    [
        ("--customnet",),
        {
            "default": "",
            "help": "use a custom network (specify as UNSPENDABLE_ADDRESS|ADDRESSVERSION|P2SH_ADDRESSVERSION with version bytes in HH hex format)",
        },
    ],
    [
        ("--counterparty-rpc-connect",),
        {"default": "localhost", "help": "the hostname or IP of the Counterparty JSON-RPC server"},
    ],
    [
        ("--counterparty-rpc-port",),
        {"type": int, "help": "the port of the Counterparty JSON-RPC server"},
    ],
    [
        ("--counterparty-rpc-user",),
        {"default": "rpc", "help": "the username for the Counterparty JSON-RPC server"},
    ],
    [
        ("--counterparty-rpc-password",),
        {"help": "the password for the Counterparty JSON-RPC server"},
    ],
    [
        ("--counterparty-rpc-ssl",),
        {
            "default": False,
            "action": "store_true",
            "help": "use SSL to connect to the Counterparty server (default: false)",
        },
    ],
    [
        ("--counterparty-rpc-ssl-verify",),
        {
            "default": False,
            "action": "store_true",
            "help": "verify SSL certificate of the Counterparty server; disallow use of self‐signed certificates (default: false)",
        },
    ],
    [("--wallet-name",), {"default": "bitcoincore", "help": "the wallet name to connect to"}],
    [
        ("--wallet-connect",),
        {"default": "localhost", "help": "the hostname or IP of the wallet server"},
    ],
    [("--wallet-port",), {"type": int, "help": "the wallet port to connect to"}],
    [
        ("--wallet-user",),
        {"default": "rpc", "help": "the username used to communicate with wallet"},
    ],
    [("--wallet-password",), {"help": "the password used to communicate with wallet"}],
    [
        ("--wallet-ssl",),
        {
            "action": "store_true",
            "default": False,
            "help": "use SSL to connect to wallet (default: false)",
        },
    ],
    [
        ("--wallet-ssl-verify",),
        {
            "action": "store_true",
            "default": False,
            "help": "verify SSL certificate of wallet; disallow use of self‐signed certificates (default: false)",
        },
    ],
    [
        ("--json-output",),
        {"action": "store_true", "default": False, "help": "display result in json format"},
    ],
    [
        ("--unconfirmed",),
        {
            "action": "store_true",
            "default": False,
            "help": "allow the spending of unconfirmed transaction outputs",
        },
    ],
    [("--encoding",), {"default": "auto", "type": str, "help": "data encoding method"}],
    [
        ("--fee-per-kb",),
        {
            "type": D,
            "default": D(config.DEFAULT_FEE_PER_KB / config.UNIT),
            "help": f"fee per kilobyte, in {config.BTC}",
        },
    ],
    [
        ("--regular-dust-size",),
        {
            "type": D,
            "default": D(config.DEFAULT_REGULAR_DUST_SIZE / config.UNIT),
            "help": f"value for dust Pay‐to‐Pubkey‐Hash outputs, in {config.BTC}",
        },
    ],
    [
        ("--multisig-dust-size",),
        {
            "type": D,
            "default": D(config.DEFAULT_MULTISIG_DUST_SIZE / config.UNIT),
            "help": f"for dust OP_CHECKMULTISIG outputs, in {config.BTC}",
        },
    ],
    [
        ("--op-return-value",),
        {
            "type": D,
            "default": D(config.DEFAULT_OP_RETURN_VALUE / config.UNIT),
            "help": f"value for OP_RETURN outputs, in {config.BTC}",
        },
    ],
    [
        ("--unsigned",),
        {
            "action": "store_true",
            "default": False,
            "help": "print out unsigned hex of transaction; do not sign or broadcast",
        },
    ],
    [
        ("--disable-utxo-locks",),
        {"action": "store_true", "default": False, "help": "disable locking of UTXOs being spend"},
    ],
    [("--dust-return-pubkey",), {"help": "pubkey for dust outputs (required for P2SH)"}],
    [
        ("--requests-timeout",),
        {
            "type": int,
            "default": clientapi.DEFAULT_REQUESTS_TIMEOUT,
            "help": "timeout value (in seconds) used for all HTTP requests (default: 5)",
        },
    ],
]


def main():
    if os.name == "nt":
        from counterpartylib.lib import util_windows

        # patch up cmd.exe's "challenged" (i.e. broken/non-existent) UTF-8 logging
        util_windows.fix_win32_unicode()

    # Post installation tasks
    generate_config_files()

    # Parse command-line arguments.
    parser = argparse.ArgumentParser(
        prog=APP_NAME, description="Counterparty CLI for counterparty-server", add_help=False
    )
    parser.add_argument(
        "-h", "--help", dest="help", action="store_true", help="show this help message and exit"
    )
    parser.add_argument(
        "-V",
        "--version",
        action="version",
        version=f"{APP_NAME} v{APP_VERSION}; counterparty-lib v{config.VERSION_STRING}",
    )
    parser.add_argument("--config-file", help="the location of the configuration file")

    cmd_args = parser.parse_known_args()[0]
    config_file_path = getattr(cmd_args, "config_file", None)
    configfile = read_config_file("client.conf", config_file_path)

    add_config_arguments(parser, CONFIG_ARGS, configfile, add_default=True)

    subparsers = parser.add_subparsers(dest="action", help="the action to be taken")

    parser_send = subparsers.add_parser("send", help="create and broadcast a *send* message")
    parser_send.add_argument("--source", required=True, help="the source address")
    parser_send.add_argument("--destination", required=True, help="the destination address")
    parser_send.add_argument("--quantity", required=True, help="the quantity of ASSET to send")
    parser_send.add_argument(
        "--asset", required=True, help="the ASSET of which you would like to send QUANTITY"
    )
    parser_send.add_argument("--memo", help="A transaction memo attached to this send")
    parser_send.add_argument(
        "--memo-is-hex",
        action="store_true",
        default=False,
        help="Whether to interpret memo as a hexadecimal value",
    )
    parser_send.add_argument(
        "--no-use-enhanced-send",
        action="store_false",
        dest="use_enhanced_send",
        default=True,
        help="If set to false, compose a non-enhanced send with a bitcoin dust output",
    )
    parser_send.add_argument("--fee", help=f"the exact {config.BTC} fee to be paid to miners")

    parser_sweep = subparsers.add_parser("sweep", help="create and broadcast a *sweep* message")
    parser_sweep.add_argument("--source", required=True, help="the source address")
    parser_sweep.add_argument("--destination", required=True, help="the destination address")
    parser_sweep.add_argument(
        "--flags",
        default=1,
        help="the ORed flags for this sweep. 1 for balance sweep, 2 for ownership sweep, 4 for memo as hex. E.G. flag=7 sends all assets, transfer all ownerships and encodes the memo as hex. default=1",
    )
    parser_sweep.add_argument("--memo", help="A transaction memo attached to this send")
    parser_sweep.add_argument("--fee", help=f"the exact {config.BTC} fee to be paid to miners")

    parser_dispenser = subparsers.add_parser("dispenser", help="create and broadcast a *dispenser*")
    parser_dispenser.add_argument("--source", required=True, help="the source address")
    parser_dispenser.add_argument(
        "--asset", required=True, help="the ASSET of which you would like to dispense GIVE_QUANTITY"
    )
    parser_dispenser.add_argument(
        "--mainchainrate",
        required=True,
        help=f"the quantity of {config.BTC} (decimal) this dispenser must receive to send the GIVEN_QUANTITY of the ASSET",
    )
    parser_dispenser.add_argument(
        "--give-quantity",
        required=True,
        help=f"the quantity of ASSET that you are giving for each MAINCHAINRATE of {config.BTC} received",
    )
    parser_dispenser.add_argument(
        "--escrow-quantity",
        required=True,
        help="the quantity of ASSET that you are escrowing for this dispenser",
    )
    parser_dispenser.add_argument(
        "--status",
        default=0,
        help="the status for the dispenser: 0. to open the dispenser (or replenish a drained one). 10. to close the dispenser. Default 0.",
    )
    parser_dispenser.add_argument("--fee", help=f"the exact {config.BTC} fee to be paid to miners")
    parser_dispenser.add_argument(
        "--open-address", help="an empty address to open the dispenser on"
    )

    parser_order = subparsers.add_parser("order", help="create and broadcast an *order* message")
    parser_order.add_argument("--source", required=True, help="the source address")
    parser_order.add_argument(
        "--get-quantity",
        required=True,
        help="the quantity of GET_ASSET that you would like to receive",
    )
    parser_order.add_argument(
        "--get-asset", required=True, help="the asset that you would like to buy"
    )
    parser_order.add_argument(
        "--give-quantity",
        required=True,
        help="the quantity of GIVE_ASSET that you are willing to give",
    )
    parser_order.add_argument(
        "--give-asset", required=True, help="the asset that you would like to sell"
    )
    parser_order.add_argument(
        "--expiration",
        type=int,
        required=True,
        help="the number of blocks for which the order should be valid",
    )
    parser_order.add_argument(
        "--fee-fraction-required",
        default=config.DEFAULT_FEE_FRACTION_REQUIRED,
        help=f"the miners’ fee required for an order to match this one, as a fraction of the {config.BTC} to be bought",
    )
    parser_order_fees = parser_order.add_mutually_exclusive_group()
    parser_order_fees.add_argument(
        "--fee-fraction-provided",
        default=config.DEFAULT_FEE_FRACTION_PROVIDED,
        help=f"the miners’ fee provided, as a fraction of the {config.BTC} to be sold",
    )
    parser_order_fees.add_argument("--fee", help=f"the exact {config.BTC} fee to be paid to miners")

    parser_btcpay = subparsers.add_parser(
        f"{config.BTC}pay".lower(),
        help=f"create and broadcast a *{config.BTC}pay* message, to settle an Order Match for which you owe {config.BTC}",
    )
    parser_btcpay.add_argument("--source", required=True, help="the source address")
    parser_btcpay.add_argument(
        "--order-match-id",
        required=True,
        help="the concatenation of the hashes of the two transactions which compose the order match",
    )
    parser_btcpay.add_argument("--fee", help=f"the exact {config.BTC} fee to be paid to miners")

    parser_issuance = subparsers.add_parser(
        "issuance",
        help="issue a new asset, issue more of an existing asset or transfer the ownership of an asset",
    )
    parser_issuance.add_argument("--source", required=True, help="the source address")
    parser_issuance.add_argument(
        "--transfer-destination", help="for transfer of ownership of asset issuance rights"
    )
    parser_issuance.add_argument("--quantity", default=0, help="the quantity of ASSET to be issued")
    parser_issuance.add_argument(
        "--asset", required=True, help="the name of the asset to be issued (if it’s available)"
    )
    parser_issuance.add_argument(
        "--divisible",
        action="store_true",
        help="whether or not the asset is divisible (must agree with previous issuances)",
    )
    parser_issuance.add_argument(
        "--description",
        type=str,
        required=True,
        help="a description of the asset (set to ‘LOCK’ to lock against further issuances with non‐zero quantitys)",
    )
    parser_issuance.add_argument("--fee", help=f"the exact {config.BTC} fee to be paid to miners")

    parser_broadcast = subparsers.add_parser(
        "broadcast", help="broadcast textual and numerical information to the network"
    )
    parser_broadcast.add_argument("--source", required=True, help="the source address")
    parser_broadcast.add_argument(
        "--text",
        type=str,
        required=True,
        help="the textual part of the broadcast (set to ‘LOCK’ to lock feed)",
    )
    parser_broadcast.add_argument(
        "--value", type=float, default=-1, help="numerical value of the broadcast"
    )
    parser_broadcast.add_argument(
        "--fee-fraction",
        default=0,
        help="the fraction of bets on this feed that go to its operator",
    )
    parser_broadcast.add_argument("--fee", help=f"the exact {config.BTC} fee to be paid to miners")

    parser_bet = subparsers.add_parser("bet", help="offer to make a bet on the value of a feed")
    parser_bet.add_argument("--source", required=True, help="the source address")
    parser_bet.add_argument(
        "--feed-address", required=True, help="the address which publishes the feed to bet on"
    )
    parser_bet.add_argument(
        "--bet-type",
        choices=list(BET_TYPE_NAME.values()),
        required=True,
        help=f"choices: {list(BET_TYPE_NAME.values())}",
    )
    parser_bet.add_argument(
        "--deadline",
        required=True,
        help="the date and time at which the bet should be decided/settled",
    )
    parser_bet.add_argument("--wager", required=True, help="the quantity of XCP to wager")
    parser_bet.add_argument(
        "--counterwager",
        required=True,
        help="the minimum quantity of XCP to be wagered by the user to bet against you, if he were to accept the whole thing",
    )
    parser_bet.add_argument(
        "--target-value", default=0.0, help="target value for Equal/NotEqual bet"
    )
    parser_bet.add_argument(
        "--leverage", type=int, default=5040, help="leverage, as a fraction of 5040"
    )
    parser_bet.add_argument(
        "--expiration",
        type=int,
        required=True,
        help="the number of blocks for which the bet should be valid",
    )
    parser_bet.add_argument("--fee", help=f"the exact {config.BTC} fee to be paid to miners")

    parser_dividend = subparsers.add_parser(
        "dividend",
        help="pay dividends to the holders of an asset (in proportion to their stake in it)",
    )
    parser_dividend.add_argument("--source", required=True, help="the source address")
    parser_dividend.add_argument(
        "--quantity-per-unit",
        required=True,
        help="the quantity of XCP to be paid per whole unit held of ASSET",
    )
    parser_dividend.add_argument("--asset", required=True, help="the asset to which pay dividends")
    parser_dividend.add_argument(
        "--dividend-asset", required=True, help="asset in which to pay the dividends"
    )
    parser_dividend.add_argument("--fee", help=f"the exact {config.BTC} fee to be paid to miners")

    parser_burn = subparsers.add_parser(
        "burn", help="destroy {} to earn XCP, during an initial period of time"
    )
    parser_burn.add_argument("--source", required=True, help="the source address")
    parser_burn.add_argument(
        "--quantity", required=True, help=f"quantity of {config.BTC} to be burned"
    )
    parser_burn.add_argument("--fee", help=f"the exact {config.BTC} fee to be paid to miners")

    parser_cancel = subparsers.add_parser("cancel", help="cancel an open order or bet you created")
    parser_cancel.add_argument("--source", required=True, help="the source address")
    parser_cancel.add_argument(
        "--offer-hash", required=True, help="the transaction hash of the order or bet"
    )
    parser_cancel.add_argument("--fee", help=f"the exact {config.BTC} fee to be paid to miners")

    parser_publish = subparsers.add_parser(
        "publish", help="publish contract code in the blockchain"
    )
    parser_publish.add_argument("--source", required=True, help="the source address")
    parser_publish.add_argument("--gasprice", required=True, type=int, help="the price of gas")
    parser_publish.add_argument(
        "--startgas",
        required=True,
        type=int,
        help=f"the maximum quantity of {config.XCP} to be used to pay for the execution (satoshis)",
    )
    parser_publish.add_argument(
        "--endowment",
        required=True,
        type=int,
        help=f"quantity of {config.XCP} to be transfered to the contract (satoshis)",
    )
    parser_publish.add_argument(
        "--code-hex",
        required=True,
        type=str,
        help="the hex‐encoded contract (returned by `serpent compile`)",
    )
    parser_publish.add_argument("--fee", help=f"the exact {config.BTC} fee to be paid to miners")

    parser_execute = subparsers.add_parser(
        "execute", help="execute contract code in the blockchain"
    )
    parser_execute.add_argument("--source", required=True, help="the source address")
    parser_execute.add_argument(
        "--contract-id", required=True, help="the contract ID of the contract to be executed"
    )
    parser_execute.add_argument("--gasprice", required=True, type=int, help="the price of gas")
    parser_execute.add_argument(
        "--startgas",
        required=True,
        type=int,
        help=f"the maximum quantity of {config.XCP} to be used to pay for the execution (satoshis)",
    )
    parser_execute.add_argument(
        "--value",
        required=True,
        type=int,
        help=f"quantity of {config.XCP} to be transfered to the contract (satoshis)",
    )
    parser_execute.add_argument(
        "--payload-hex",
        required=True,
        type=str,
        help="data to be provided to the contract (returned by `serpent encode_datalist`)",
    )
    parser_execute.add_argument("--fee", help=f"the exact {config.BTC} fee to be paid to miners")

    parser_destroy = subparsers.add_parser(
        "destroy", help="destroy a quantity of a Counterparty asset"
    )
    parser_destroy.add_argument("--source", required=True, help="the source address")
    parser_destroy.add_argument(
        "--asset", required=True, help="the ASSET of which you would like to destroy QUANTITY"
    )
    parser_destroy.add_argument(
        "--quantity", required=True, help="the quantity of ASSET to destroy"
    )
    parser_destroy.add_argument("--tag", default="", help="tag")
    parser_destroy.add_argument("--fee", help=f"the exact {config.BTC} fee to be paid to miners")

    parser_address = subparsers.add_parser(
        "balances", help=f"display the balances of a {config.XCP_NAME} address"
    )
    parser_address.add_argument("address", help="the address you are interested in")

    parser_asset = subparsers.add_parser(
        "asset", help=f"display the basic properties of a {config.XCP_NAME} asset"
    )
    parser_asset.add_argument("asset", help="the asset you are interested in")

    parser_wallet = subparsers.add_parser(  # noqa: F841
        "wallet",
        help=f"list the addresses in your backend wallet along with their balances in all {config.XCP_NAME} assets",
    )

    parser_pending = subparsers.add_parser(  # noqa: F841
        "pending", help=f"list pending order matches awaiting {config.BTC}payment from you"
    )

    parser_getrows = subparsers.add_parser("getrows", help="get rows from a Counterparty table")
    parser_getrows.add_argument("--table", required=True, help="table name")
    parser_getrows.add_argument(
        "--filter", nargs=3, action="append", help="filters to get specific rows"
    )
    parser_getrows.add_argument(
        "--filter-op", choices=["AND", "OR"], help="operator uses to combine filters", default="AND"
    )
    parser_getrows.add_argument("--order-by", help="field used to order results")
    parser_getrows.add_argument(
        "--order-dir", choices=["ASC", "DESC"], help="direction used to order results"
    )
    parser_getrows.add_argument(
        "--start-block", help="return only rows with block_index greater than start-block"
    )
    parser_getrows.add_argument(
        "--end-block", help="return only rows with block_index lower than end-block"
    )
    parser_getrows.add_argument("--status", help="return only rows with the specified status")
    parser_getrows.add_argument("--limit", help="number of rows to return", default=100)
    parser_getrows.add_argument("--offset", help="number of rows to skip", default=0)

    parser_getrunninginfo = subparsers.add_parser(  # noqa: F841
        "getinfo", help="get the current state of the server"
    )

    parser_get_tx_info = subparsers.add_parser("get_tx_info", help="display info of a raw TX")
    parser_get_tx_info.add_argument("tx_hex", help="the raw TX")

    args = parser.parse_args()

    # Logging
    log.set_up(verbose=args.verbose)
    logger.propagate = False

    logger.info(f"Running v{APP_VERSION} of {APP_NAME}.")

    # Help message
    if args.help:
        parser.print_help()
        sys.exit()

    # Configuration
    clientapi.initialize(
        testnet=args.testnet,
        testcoin=args.testcoin,
        regtest=args.regtest,
        customnet=args.customnet,
        counterparty_rpc_connect=args.counterparty_rpc_connect,
        counterparty_rpc_port=args.counterparty_rpc_port,
        counterparty_rpc_user=args.counterparty_rpc_user,
        counterparty_rpc_password=args.counterparty_rpc_password,
        counterparty_rpc_ssl=args.counterparty_rpc_ssl,
        counterparty_rpc_ssl_verify=args.counterparty_rpc_ssl_verify,
        wallet_name=args.wallet_name,
        wallet_connect=args.wallet_connect,
        wallet_port=args.wallet_port,
        wallet_user=args.wallet_user,
        wallet_password=args.wallet_password,
        wallet_ssl=args.wallet_ssl,
        wallet_ssl_verify=args.wallet_ssl_verify,
        requests_timeout=args.requests_timeout,
    )

    # MESSAGE CREATION
    if args.action in list(messages.MESSAGE_PARAMS.keys()):
        unsigned_hex = messages.compose(args.action, args)
        logger.info(f"Transaction (unsigned): {unsigned_hex}")
        if not args.unsigned:
            if script.is_multisig(args.source):
                logger.info("Multi‐signature transactions are signed and broadcasted manually.")

            elif input("Sign and broadcast? (y/N) ") == "y":
                if wallet.is_mine(args.source):
                    if wallet.is_locked():
                        passphrase = getpass.getpass("Enter your wallet passhrase: ")
                        logger.info("Unlocking wallet for 60 (more) seconds.")
                        wallet.unlock(passphrase)
                    signed_tx_hex = wallet.sign_raw_transaction(unsigned_hex)
                else:
                    private_key_wif = input(
                        f"Source address not in wallet. Please enter the private key in WIF format for {args.source}:"
                    )
                    if not private_key_wif:
                        raise TransactionError("invalid private key")
                    signed_tx_hex = wallet.sign_raw_transaction(
                        unsigned_hex, private_key_wif=private_key_wif
                    )

                logger.info(f"Transaction (signed): {signed_tx_hex}")
                tx_hash = wallet.send_raw_transaction(signed_tx_hex)
                logger.info(f"Hash of transaction (broadcasted): {tx_hash}")

    # VIEWING
    elif args.action in [
        "balances",
        "asset",
        "wallet",
        "pending",
        "getinfo",
        "getrows",
        "get_tx_info",
    ]:
        view = console.get_view(args.action, args)
        print_method = getattr(console, f"print_{args.action}", None)
        if args.json_output or print_method is None:
            util.json_print(view)
        else:
            print_method(view)

    else:
        parser.print_help()


# vim: tabstop=8 expandtab shiftwidth=4 softtabstop=4
