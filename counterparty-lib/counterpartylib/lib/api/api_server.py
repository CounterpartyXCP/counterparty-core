import argparse
import logging
import multiprocessing
from logging import handlers as logging_handlers
from multiprocessing import Process
from threading import Timer

import flask
from counterpartylib import server
from counterpartylib.lib import (
    blocks,
    config,
    database,
    ledger,
)
from counterpartylib.lib.api.routes import ROUTES
from counterpartylib.lib.api.util import get_backend_height, remove_rowids
from flask import Flask, request
from flask import g as flask_globals
from flask_httpauth import HTTPBasicAuth

multiprocessing.set_start_method("spawn", force=True)

logger = logging.getLogger(config.LOGGER_NAME)
auth = HTTPBasicAuth()

BACKEND_HEIGHT = 0
REFRESH_BACKEND_HEIGHT_INTERVAL = 10
BACKEND_HEIGHT_TIMER = None


def init_api_access_log():
    """Initialize API logger."""
    werkzeug_loggers = (logging.getLogger("werkzeug"), flask.current_app.logger)

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


def get_db():
    """Get the database connection."""
    if not hasattr(flask_globals, "db"):
        flask_globals.db = database.get_connection(read_only=True)
    return flask_globals.db


@auth.verify_password
def verify_password(username, password):
    return username == config.RPC_USER and password == config.RPC_PASSWORD


@auth.login_required
def api_root():
    counterparty_height = blocks.last_db_index(get_db())
    routes = list(ROUTES.keys())
    network = "mainnet"
    if config.TESTNET:
        network = "testnet"
    elif config.REGTEST:
        network = "regtest"
    elif config.TESTCOIN:
        network = "testcoin"
    return {
        "server_ready": counterparty_height >= BACKEND_HEIGHT,
        "network": network,
        "version": config.VERSION_STRING,
        "backend_height": BACKEND_HEIGHT,
        "counterparty_height": counterparty_height,
        "routes": routes,
    }


@auth.login_required
def handle_route(**kwargs):
    route = ROUTES.get(str(request.url_rule.rule))
    function_args = dict(kwargs)
    if "pass_all_args" in route and route["pass_all_args"]:
        function_args = request.args | function_args
    elif "args" in route:
        for arg in route["args"]:
            function_args[arg[0]] = request.args.get(arg[0], arg[1])
    result = route["function"](get_db(), **function_args)
    return remove_rowids(result)


def run_api_server(args):
    app = Flask(config.APP_NAME)
    # Initialise log and config
    server.initialise_log_and_config(argparse.Namespace(**args))
    with app.app_context():
        # Initialise the API access log
        init_api_access_log()
        # Get the last block index
        ledger.CURRENT_BLOCK_INDEX = blocks.last_db_index(get_db())
        # Add routes
        app.route("/")(api_root)
        for path in ROUTES.keys():
            app.add_url_rule(path, view_func=handle_route)
        # run the scheduler to refresh the backend height
        refresh_backend_height()
    # Start the API server
    try:
        app.run(host=config.RPC_HOST, port=config.RPC_PORT, debug=False)
    finally:
        # ensure timer is cancelled
        if BACKEND_HEIGHT_TIMER:
            BACKEND_HEIGHT_TIMER.cancel()


def refresh_backend_height():
    global BACKEND_HEIGHT, BACKEND_HEIGHT_TIMER  # noqa F811
    BACKEND_HEIGHT = get_backend_height()
    if BACKEND_HEIGHT_TIMER:
        BACKEND_HEIGHT_TIMER.cancel()
    BACKEND_HEIGHT_TIMER = Timer(REFRESH_BACKEND_HEIGHT_INTERVAL, refresh_backend_height)
    BACKEND_HEIGHT_TIMER.start()


class APIServer(object):
    def __init__(self):
        self.process = None

    def start(self, args):
        if self.process is not None:
            raise Exception("API server is already running")
        self.process = Process(target=run_api_server, args=(vars(args),))
        self.process.start()
        return self.process

    def stop(self):
        if self.process and self.process.is_alive():
            self.process.terminate()
        self.process = None
