import argparse
import logging
import multiprocessing
from logging import handlers as logging_handlers
from multiprocessing import Process

import flask
from flask import Flask, request

from counterpartylib import server
from counterpartylib.lib import (
    config,
    database,
    ledger,
)

multiprocessing.set_start_method("spawn", force=True)

logger = logging.getLogger(config.LOGGER_NAME)
app = Flask(__name__)
db = None
api_process = None


def init_api_access_log(app):
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
    filtered_results = []
    for row in list(query_result):
        if "rowid" in row:
            del row["rowid"]
        if "MAX(rowid)" in row:
            del row["MAX(rowid)"]
        filtered_results.append(row)
    return filtered_results


@app.route("/addresses/<address>/balances", methods=["GET"])
def handle_address_balances(address):
    return remove_rowids(ledger.get_address_balances(db, address))


@app.route("/assets/<asset>/balances", methods=["GET"])
def handle_asset_balances(asset):
    return remove_rowids(ledger.get_asset_balances(db, asset))


# @app.route("/assets/<asset>/", methods=["GET"])
# def handle_asset_info(asset):
#    return remove_rowids(get_asset_info(asset=asset))


@app.route("/assets/<asset>/orders", methods=["GET"])
def handle_asset_orders(asset):
    status = request.args.get("status", "open")
    return remove_rowids(ledger.get_orders_by_asset(db, asset, status))


@app.route("/orders/<tx_hash>", methods=["GET"])
def handle_order_info(tx_hash):
    return remove_rowids(ledger.get_order(db, tx_hash))


@app.route("/orders/<tx_hash>/matches", methods=["GET"])
def handle_order_matches(tx_hash):
    status = request.args.get("status", "pending")
    return remove_rowids(ledger.get_order_matches_by_order(db, tx_hash, status))


def run_api_server(args):
    global db  # noqa: PLW0603
    # Initialise log and config
    server.initialise_log_and_config(argparse.Namespace(**args))
    init_api_access_log(app)
    # Connect to the database
    db = database.get_connection(read_only=True)
    # Start the API server
    app.run(host=config.RPC_HOST, port=config.RPC_PORT, debug=False)
    print(f"REST API started at {config.RPC_HOST}:{config.RPC_PORT}")


def start(args):
    api_process = Process(target=run_api_server, args=(vars(args),))
    api_process.start()


def stop():
    if api_process and api_process.is_alive():
        api_process.terminate()
    print(f"REST API stopped at {config.RPC_HOST}:{config.RPC_PORT}")
