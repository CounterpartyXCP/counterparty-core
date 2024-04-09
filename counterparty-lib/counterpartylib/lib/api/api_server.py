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
    return username == config.API_USER and password == config.API_PASSWORD


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


def inject_headers(result):
    server_ready = ledger.CURRENT_BLOCK_INDEX >= BACKEND_HEIGHT
    http_code = 200 if server_ready else config.API_NOT_READY_HTTP_CODE
    response = flask.make_response(flask.jsonify(result), http_code)
    if not config.API_NO_ALLOW_CORS:
        response.headers["Access-Control-Allow-Origin"] = "*"
        response.headers["Access-Control-Allow-Methods"] = "GET, POST, OPTIONS"
        response.headers["Access-Control-Allow-Headers"] = (
            "DNT,X-Mx-ReqToken,Keep-Alive,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type,Authorization"
        )
    response.headers["X-COUNTERPARTY-HEIGHT"] = ledger.CURRENT_BLOCK_INDEX
    response.headers["X-COUNTERPARTY-READY"] = ledger.CURRENT_BLOCK_INDEX >= BACKEND_HEIGHT
    response.headers["X-BACKEND-HEIGHT"] = BACKEND_HEIGHT
    return response


@auth.login_required
def handle_route(**kwargs):
    db = get_db()
    # update the current block index
    ledger.CURRENT_BLOCK_INDEX = blocks.last_db_index(db)
    rule = str(request.url_rule.rule)
    if rule == "/":
        result = api_root()
    else:
        route = ROUTES.get(rule)
        function_args = dict(kwargs)
        if "pass_all_args" in route and route["pass_all_args"]:
            function_args = request.args | function_args
        elif "args" in route:
            for arg in route["args"]:
                function_args[arg[0]] = request.args.get(arg[0], arg[1])
        result = route["function"](db, **function_args)
        result = remove_rowids(result)
    return inject_headers(result)


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
        app.add_url_rule("/", view_func=handle_route)
        for path in ROUTES.keys():
            app.add_url_rule(path, view_func=handle_route)
        # run the scheduler to refresh the backend height
        # `no_refresh_backend_height` used only for testing. TODO: find a way to mock it
        if "no_refresh_backend_height" not in args or not args["no_refresh_backend_height"]:
            refresh_backend_height()
    try:
        # Start the API server
        app.run(host=config.API_HOST, port=config.API_PORT, debug=False)
    finally:
        pass
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
