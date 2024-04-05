import argparse
import logging
import multiprocessing
from logging import handlers as logging_handlers
from multiprocessing import Process

import flask
from flask import Flask, request
from flask_httpauth import HTTPBasicAuth

from counterpartylib import server
from counterpartylib.lib import (
    blocks,
    config,
    database,
    ledger,
)

multiprocessing.set_start_method("spawn", force=True)

logger = logging.getLogger(config.LOGGER_NAME)
app = Flask(__name__)
auth = HTTPBasicAuth()
db = None
api_process = None


ROUTES = {
    "/blocks": {
        "function": ledger.get_blocks,
        "args": [("last", None), ("limit", 10)],
    },
    "/blocks/<int:block_index>": {
        "function": ledger.get_block,
    },
    "/blocks/<int:block_index>/transactions": {
        "function": ledger.get_transactions_by_block,
    },
    "/blocks/<int:block_index>/events": {
        "function": ledger.get_messages,
    },
    "/addresses/<address>/balances": {
        "function": ledger.get_address_balances,
    },
    "/assets/<asset>": {
        "function": ledger.get_asset_info,
    },
    "/assets/<asset>/balances": {
        "function": ledger.get_asset_balances,
    },
    "/assets/<asset>/orders": {
        "function": ledger.get_orders_by_asset,
        "args": [("status", "open")],
    },
    "/orders/<tx_hash>": {
        "function": ledger.get_order,
    },
    "/orders/<tx_hash>/matches": {
        "function": ledger.get_order_matches_by_order,
        "args": [("status", "pending")],
    },
}


@auth.verify_password
def verify_password(username, password):
    return username == config.RPC_USER and password == config.RPC_PASSWORD


def init_api_access_log():
    """Initialize API logger."""
    werkzeug_loggers = (logging.getLogger("werkzeug"), app.logger)

    # Disable console logging...
    for werkzeug_logger in werkzeug_loggers:  # noqa: E741
        werkzeug_logger.setLevel(logging.CRITICAL)
        werkzeug_logger.propagate = False

    # Log to file, if configured...
    if config.API_LOG:
        handler = logging_handlers.RotatingFileHandler(
            config.API_LOG, "a", config.API_MAX_LOG_SIZE, config.API_MAX_LOG_COUNT
        )
        for werkzeug_logger in werkzeug_loggers:  # noqa: E741
            handler.setLevel(logging.DEBUG)
            werkzeug_logger.addHandler(handler)

    flask.cli.show_server_banner = lambda *args: None


def remove_rowids(query_result):
    """Remove the rowid field from the query result."""
    if isinstance(query_result, list):
        filtered_results = []
        for row in list(query_result):
            if "rowid" in row:
                del row["rowid"]
            if "MAX(rowid)" in row:
                del row["MAX(rowid)"]
            filtered_results.append(row)
        return filtered_results
    filtered_results = query_result
    if "rowid" in filtered_results:
        del filtered_results["rowid"]
    if "MAX(rowid)" in filtered_results:
        del filtered_results["MAX(rowid)"]
    return filtered_results


@auth.login_required
def handle_route(**kwargs):
    route = ROUTES.get(str(request.url_rule.rule))
    function_args = dict(kwargs)
    if "args" in route:
        for arg in route["args"]:
            function_args[arg[0]] = request.args.get(arg[0], arg[1])
    result = route["function"](db, **function_args)
    return remove_rowids(result)


def run_api_server(args):
    global db  # noqa: PLW0603
    # Initialise log and config
    server.initialise_log_and_config(argparse.Namespace(**args))
    init_api_access_log()
    # Connect to the database
    db = database.get_connection(read_only=True)
    # Get the last block index
    ledger.CURRENT_BLOCK_INDEX = blocks.last_db_index(db)
    # Add routes
    for path in ROUTES.keys():
        app.add_url_rule(path, view_func=handle_route)
    # Start the API server
    app.run(host=config.RPC_HOST, port=config.RPC_PORT, debug=False)


def start(args):
    api_process = Process(target=run_api_server, args=(vars(args),))
    api_process.start()
    return api_process


def stop():
    if api_process and api_process.is_alive():
        api_process.terminate()
