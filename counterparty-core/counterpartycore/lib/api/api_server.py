import argparse
import logging
import multiprocessing
import time
from collections import OrderedDict
from multiprocessing import Process, Value, current_process
from threading import Thread, Timer

import flask
import requests
from counterpartycore import server
from counterpartycore.lib import (
    config,
    exceptions,
    ledger,
    sentry,
    transaction,
    util,
)
from counterpartycore.lib.api import queries
from counterpartycore.lib.api.routes import ROUTES
from counterpartycore.lib.api.util import (
    function_needs_db,
    get_backend_height,
    init_api_access_log,
    inject_details,
    remove_rowids,
    to_json,
)
from counterpartycore.lib.database import DBConnectionPool
from flask import Flask, request
from flask_cors import CORS
from flask_httpauth import HTTPBasicAuth
from sentry_sdk import capture_exception
from sentry_sdk import configure_scope as configure_sentry_scope
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


@auth.verify_password
def verify_password(username, password):
    if config.API_PASSWORD is None:
        return True
    return username == config.API_USER and password == config.API_PASSWORD


def api_root():
    with DBConnectionPool().connection() as db:
        counterparty_height = ledger.last_db_index(db)
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
    if util.CURRENT_BLOCK_INDEX >= BACKEND_HEIGHT - 1:
        return True
    if time.time() - CURRENT_BLOCK_TIME < 60:
        return True
    return False


def is_cachable(rule):
    if rule.startswith("/v2/blocks"):
        return True
    if rule.startswith("/v2/transactions"):
        return True
    if rule.startswith("/v2/backend"):
        return True
    return False


def return_result_if_not_ready(rule):
    return (
        is_cachable(rule)
        or rule == "/v2/"
        or rule == "/"
        or rule.startswith("/v1")
        or rule.startswith("/rpc")
    )


def return_result(
    http_code,
    result=None,
    error=None,
    next_cursor=None,
    result_count=None,
    start_time=None,
    query_args=None,
):
    assert result is None or error is None
    api_result = {}
    if result is not None:
        api_result["result"] = result
        if isinstance(result, list):
            api_result["next_cursor"] = next_cursor
            api_result["result_count"] = result_count
    if error is not None:
        api_result["error"] = error
    response = flask.make_response(to_json(api_result), http_code)
    response.headers["X-COUNTERPARTY-HEIGHT"] = util.CURRENT_BLOCK_INDEX
    response.headers["X-COUNTERPARTY-READY"] = is_server_ready()
    response.headers["X-BITCOIN-HEIGHT"] = BACKEND_HEIGHT
    response.headers["Content-Type"] = "application/json"

    if http_code != 404:
        rule = str(request.url_rule.rule)
        if rule == "/v2/":
            query_name = "API Root"
        else:
            route = ROUTES.get(rule)
            query_name = " ".join(
                [part.capitalize() for part in str(route["function"].__name__).split("_")]
            )
    else:
        query_name = request.path
    if query_args:
        query_args_str = " ".join([f"{k}={v}" for k, v in query_args.items()])
        query_name += f" ({query_args_str})"
    message = f"API Request - {query_name} - Response {http_code}"
    if error:
        message += f" ({error})"
    if start_time:
        message += f" - {int((time.time() - start_time) * 1000)}ms"
    logger.debug(message)

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
        if str_arg is not None and str_arg.lower() == "none":
            str_arg = None
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

    for key in function_args:
        if key in ["asset", "assets", "get_asset", "give_asset"]:
            function_args[key] = function_args[key].upper()

    return function_args


def execute_api_function(db, route, function_args):
    # cache everything for one block
    cache_key = f"{util.CURRENT_BLOCK_INDEX}:{request.url}"
    # except for blocks and transactions cached forever
    if request.path.startswith("/v2/blocks/") or request.path.startswith("/v2/transactions/"):
        cache_key = request.url

    if cache_key in BLOCK_CACHE:
        result = BLOCK_CACHE[cache_key]
    else:
        if function_needs_db(route["function"]):
            result = route["function"](db, **function_args)
        else:
            result = route["function"](**function_args)
        # don't cache API v1 and mempool queries
        if route["function"].__name__ != "redirect_to_api_v1" and not request.path.startswith(
            "/v2/mempool/"
        ):
            BLOCK_CACHE[cache_key] = result
            if len(BLOCK_CACHE) > MAX_BLOCK_CACHE_SIZE:
                BLOCK_CACHE.popitem(last=False)

    return result


def get_transaction_name(rule):
    if rule == "/v2/":
        return "APIRoot"
    if rule == "/healthz":
        return "healthcheck"
    return "".join([part.capitalize() for part in ROUTES[rule]["function"].__name__.split("_")])


@auth.login_required
def handle_route(**kwargs):
    start_time = time.time()
    query_args = request.args.to_dict() | kwargs

    if BACKEND_HEIGHT is None:
        return return_result(
            503,
            error="Backend still not ready. Please try again later.",
            start_time=start_time,
            query_args=query_args,
        )

    # update the current block index
    global CURRENT_BLOCK_TIME  # noqa F811
    with DBConnectionPool().connection() as db:
        last_block = ledger.get_last_block(db)
    if last_block:
        util.CURRENT_BLOCK_INDEX = last_block["block_index"]
        CURRENT_BLOCK_TIME = last_block["block_time"]
    else:
        util.CURRENT_BLOCK_INDEX = 0
        CURRENT_BLOCK_TIME = 0

    rule = str(request.url_rule.rule)

    with configure_sentry_scope() as scope:
        scope.set_transaction_name(get_transaction_name(rule))

    # check if server must be ready
    if not is_server_ready() and not return_result_if_not_ready(rule):
        return return_result(
            503, error="Counterparty not ready", start_time=start_time, query_args=query_args
        )

    if rule == "/v2/":
        return return_result(200, result=api_root(), start_time=start_time, query_args=query_args)

    route = ROUTES.get(rule)

    # parse args
    try:
        function_args = prepare_args(route, **kwargs)
    except ValueError as e:
        return return_result(400, error=str(e), start_time=start_time, query_args=query_args)

    # call the function
    try:
        with DBConnectionPool().connection() as db:
            result = execute_api_function(db, route, function_args)
    except (exceptions.ComposeError, exceptions.UnpackError) as e:
        return return_result(503, error=str(e), start_time=start_time, query_args=query_args)
    except (
        exceptions.JSONRPCInvalidRequest,
        exceptions.TransactionError,
        exceptions.BalanceError,
        exceptions.UnknownPubKeyError,
        exceptions.AssetNameError,
    ) as e:
        return return_result(400, error=str(e), start_time=start_time, query_args=query_args)
    except Exception as e:
        capture_exception(e)
        logger.error("Error in API: %s", e)
        # traceback.print_exc()
        return return_result(
            503, error="Unknown error", start_time=start_time, query_args=query_args
        )

    if isinstance(result, requests.Response):
        return result.content, result.status_code, result.headers.items()

    # clean up and return the result
    if result is None:
        return return_result(404, error="Not found", start_time=start_time, query_args=query_args)

    next_cursor = None
    result_count = None
    if isinstance(result, queries.QueryResult):
        next_cursor = result.next_cursor
        result_count = result.result_count
        result = result.result

    result = remove_rowids(result)

    # inject details
    verbose = request.args.get("verbose", "False")
    if verbose.lower() in ["true", "1"]:
        result = inject_details(db, result)

    return return_result(
        200,
        result=result,
        next_cursor=next_cursor,
        result_count=result_count,
        start_time=start_time,
        query_args=query_args,
    )


def handle_not_found(error):
    return return_result(404, error="Not found")


def run_api_server(args, interruped_value):
    sentry.init()
    # Initialise log and config
    server.initialise_log_and_config(argparse.Namespace(**args))
    logger.info("Starting API Server.")
    app = Flask(config.APP_NAME)
    transaction.initialise()
    with app.app_context():
        if not config.API_NO_ALLOW_CORS:
            CORS(app)
        # Initialise the API access log
        init_api_access_log(app)
        # Get the last block index
        with DBConnectionPool().connection() as db:
            util.CURRENT_BLOCK_INDEX = ledger.last_db_index(db)
        # Add routes
        app.add_url_rule("/v2/", view_func=handle_route, strict_slashes=False)
        for path in ROUTES:
            methods = ["GET"]
            if path == "/v2/bitcoin/transactions":
                methods = ["POST"]
            if not path.startswith("/v2/"):
                methods = ["GET", "POST"]
            app.add_url_rule(path, view_func=handle_route, methods=methods, strict_slashes=False)
        app.register_error_handler(404, handle_not_found)
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
        ParentProcessChecker(interruped_value, current_process(), werkzeug_server).start()
        app.app_context().push()
        # Run app server (blocking)
        werkzeug_server.serve_forever()
    except KeyboardInterrupt:
        logger.trace("Keyboard Interrupt")
    finally:
        logger.trace("Shutting down API server...")
        werkzeug_server.shutdown()
        # ensure timer is cancelled
        if BACKEND_HEIGHT_TIMER:
            BACKEND_HEIGHT_TIMER.cancel()
        DBConnectionPool().close()


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


class ParentProcessChecker(Thread):
    def __init__(self, interruped_value, parent_process, werkzeug_server):
        super().__init__()
        self.interruped_value = interruped_value
        self.parent_process = parent_process
        self.werkzeug_server = werkzeug_server

    def run(self):
        try:
            while True:
                if self.interruped_value.value == 0:
                    time.sleep(0.01)
                else:
                    logger.trace("Parent process is dead. Exiting...")
                    break
            self.werkzeug_server.shutdown()
        except KeyboardInterrupt:
            pass


INTERRUPTED = Value("I", 0)


class APIServer(object):
    def __init__(self):
        self.process = None

    def start(self, args):
        if self.process is not None:
            raise Exception("API server is already running")
        self.process = Process(target=run_api_server, args=(vars(args), INTERRUPTED))
        self.process.start()
        return self.process

    def stop(self):
        global INTERRUPTED  # noqa F811
        INTERRUPTED.value = 1
