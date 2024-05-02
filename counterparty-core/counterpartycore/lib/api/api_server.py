import argparse
import logging
import multiprocessing
import time
import traceback
from collections import OrderedDict
from multiprocessing import Process
from threading import Timer

import flask
from counterpartycore import server
from counterpartycore.lib import (
    blocks,
    config,
    database,
    exceptions,
    ledger,
    transaction,
)
from counterpartycore.lib.api.routes import ROUTES
from counterpartycore.lib.api.util import (
    function_needs_db,
    get_backend_height,
    init_api_access_log,
    inject_dispensers,
    inject_issuance,
    inject_normalized_quantities,
    remove_rowids,
    to_json,
)
from flask import Flask, request
from flask import g as flask_globals
from flask_cors import CORS
from flask_httpauth import HTTPBasicAuth
from werkzeug.serving import make_server

multiprocessing.set_start_method("spawn", force=True)

logger = logging.getLogger(config.LOGGER_NAME)
auth = HTTPBasicAuth()

BACKEND_HEIGHT = None
CURRENT_BLOCK_TIME = None
REFRESH_BACKEND_HEIGHT_INTERVAL = 10
BACKEND_HEIGHT_TIMER = None
BLOCK_CACHE = OrderedDict()
MAX_BLOCK_CACHE_SIZE = 1000


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
    routes = []
    for path, route in ROUTES.items():
        routes.append(
            {
                "path": path,
                "args": route.get("args", []),
                "description": route.get("description", ""),
            }
        )
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


def is_server_ready():
    if BACKEND_HEIGHT is None:
        return False
    if ledger.CURRENT_BLOCK_INDEX >= BACKEND_HEIGHT - 1:
        return True
    if time.time() - CURRENT_BLOCK_TIME < 60:
        return True
    return False


def is_cachable(rule):
    if rule.startswith("/blocks"):
        return True
    if rule.startswith("/transactions"):
        return True
    if rule.startswith("/backend"):
        return True
    return False


def return_result_if_not_ready(rule):
    return is_cachable(rule) or rule == "/"


def return_result(http_code, result=None, error=None):
    assert result is None or error is None
    api_result = {}
    if result is not None:
        api_result["result"] = result
    if error is not None:
        api_result["error"] = error
    response = flask.make_response(to_json(api_result), http_code)
    response.headers["X-COUNTERPARTY-HEIGHT"] = ledger.CURRENT_BLOCK_INDEX
    response.headers["X-COUNTERPARTY-READY"] = is_server_ready()
    response.headers["X-BITCOIN-HEIGHT"] = BACKEND_HEIGHT
    response.headers["Content-Type"] = "application/json"
    return response


def prepare_args(route, **kwargs):
    function_args = dict(kwargs)
    # inject args from request.args
    for arg in route["args"]:
        arg_name = arg["name"]
        if arg_name == "verbose":
            continue
        if arg_name in function_args:
            continue
        str_arg = request.args.get(arg_name)

        if str_arg is None and arg["required"]:
            raise ValueError(f"Missing required parameter: {arg_name}")

        if str_arg is None:
            function_args[arg_name] = arg["default"]
        elif arg["type"] == "bool":
            function_args[arg_name] = str_arg.lower() in ["true", "1"]
        elif arg["type"] == "int":
            try:
                function_args[arg_name] = int(str_arg)
            except ValueError as e:
                raise ValueError(f"Invalid integer: {arg_name}") from e
        elif arg["type"] == "float":
            try:
                function_args[arg_name] = float(str_arg)
            except ValueError as e:
                raise ValueError(f"Invalid float: {arg_name}") from e
        else:
            function_args[arg_name] = str_arg
    return function_args


def execute_api_function(db, route, function_args):
    # cache everything for one block
    cache_key = f"{ledger.CURRENT_BLOCK_INDEX}:{request.url}"
    # except for blocks and transactions cached forever
    if request.path.startswith("/blocks/") or request.path.startswith("/transactions/"):
        cache_key = request.url

    if cache_key in BLOCK_CACHE:
        result = BLOCK_CACHE[cache_key]
    else:
        if function_needs_db(route["function"]):
            result = route["function"](db, **function_args)
        else:
            result = route["function"](**function_args)
        BLOCK_CACHE[cache_key] = result
        if len(BLOCK_CACHE) > MAX_BLOCK_CACHE_SIZE:
            BLOCK_CACHE.popitem(last=False)

    return result


def inject_details(db, result):
    result = inject_dispensers(db, result)
    result = inject_issuance(db, result)
    result = inject_normalized_quantities(result)
    return result


@auth.login_required
def handle_route(**kwargs):
    if BACKEND_HEIGHT is None:
        return return_result(503, error="Backend still not ready. Please retry later.")
    db = get_db()

    # update the current block index
    global CURRENT_BLOCK_TIME  # noqa F811
    last_block = ledger.get_last_block(db)
    if last_block:
        ledger.CURRENT_BLOCK_INDEX = last_block["block_index"]
        CURRENT_BLOCK_TIME = last_block["block_time"]
    else:
        ledger.CURRENT_BLOCK_INDEX = 0
        CURRENT_BLOCK_TIME = 0

    rule = str(request.url_rule.rule)

    # check if server must be ready
    if not is_server_ready() and not return_result_if_not_ready(rule):
        return return_result(503, error="Counterparty not ready")

    if rule == "/":
        return return_result(200, result=api_root())

    route = ROUTES.get(rule)

    # parse args
    try:
        function_args = prepare_args(route, **kwargs)
    except ValueError as e:
        return return_result(400, error=str(e))

    # call the function
    try:
        result = execute_api_function(db, route, function_args)
    except (exceptions.ComposeError, exceptions.UnpackError) as e:
        return return_result(503, error=str(e))
    except Exception as e:
        logger.exception("Error in API: %s", e)
        traceback.print_exc()
        return return_result(503, error="Unknwon error")

    # clean up and return the result
    if result is None:
        return return_result(404, error="Not found")
    result = remove_rowids(result)

    # inject details
    verbose = request.args.get("verbose", "False")
    if verbose.lower() in ["true", "1"]:
        result = inject_details(db, result)

    return return_result(200, result=result)


def run_api_server(args):
    app = Flask(config.APP_NAME)
    # Initialise log and config
    server.initialise_log_and_config(argparse.Namespace(**args))
    transaction.initialise()
    with app.app_context():
        if not config.API_NO_ALLOW_CORS:
            CORS(app)
        # Initialise the API access log
        init_api_access_log(app)
        # Get the last block index
        ledger.CURRENT_BLOCK_INDEX = blocks.last_db_index(get_db())
        # Add routes
        app.add_url_rule("/", view_func=handle_route)
        for path in ROUTES:
            app.add_url_rule(path, view_func=handle_route)
        # run the scheduler to refresh the backend height
        # `no_refresh_backend_height` used only for testing. TODO: find a way to mock it
        if "no_refresh_backend_height" not in args or not args["no_refresh_backend_height"]:
            refresh_backend_height(start=True)
        else:
            global BACKEND_HEIGHT  # noqa F811
            BACKEND_HEIGHT = 0
    try:
        # Init the HTTP Server.
        werkzeug_server = make_server(config.API_HOST, config.API_PORT, app, threaded=True)
        app.app_context().push()
        # Run app server (blocking)
        werkzeug_server.serve_forever()
    finally:
        werkzeug_server.shutdown()
        # ensure timer is cancelled
        if BACKEND_HEIGHT_TIMER:
            BACKEND_HEIGHT_TIMER.cancel()


def refresh_backend_height(start=False):
    global BACKEND_HEIGHT, BACKEND_HEIGHT_TIMER  # noqa F811
    if not start:
        BACKEND_HEIGHT = get_backend_height()
    else:
        # starting the timer is not blocking in case of Addrindexrs is not ready
        BACKEND_HEIGHT_TIMER = Timer(0.5, refresh_backend_height)
        BACKEND_HEIGHT_TIMER.start()
        return
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
        logger.info("Stopping API server v2...")
        if self.process and self.process.is_alive():
            self.process.terminate()
        self.process = None
