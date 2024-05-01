import decimal
import inspect
import json
import logging
import time
from logging import handlers as logging_handlers

import flask
from counterpartycore.lib import backend, config, exceptions, ledger, transaction
from docstring_parser import parse as parse_docstring

logger = logging.getLogger(config.LOGGER_NAME)


def check_last_parsed_block(db, blockcount):
    """Checks database to see if is caught up with backend."""
    last_block = ledger.get_last_block(db)
    if time.time() - last_block["block_time"] < 60:
        return
    if ledger.CURRENT_BLOCK_INDEX + 1 < blockcount:
        raise exceptions.DatabaseError(f"{config.XCP_NAME} database is behind backend.")
    logger.debug("Database state check passed.")


def healthz_light(db):
    logger.debug("Performing light healthz check.")
    latest_block_index = backend.getblockcount()
    check_last_parsed_block(db, latest_block_index)


def healthz_heavy(db):
    logger.debug("Performing heavy healthz check.")
    transaction.compose_transaction(
        db,
        name="send",
        params={
            "source": config.UNSPENDABLE,
            "destination": config.UNSPENDABLE,
            "asset": config.XCP,
            "quantity": 100000000,
        },
        allow_unconfirmed_inputs=True,
        fee=1000,
    )


def healthz(db, check_type: str = "heavy"):
    try:
        if check_type == "light":
            healthz_light(db)
        else:
            healthz_light(db)
            healthz_heavy(db)
    except Exception as e:
        logger.error(f"Health check failed: {e}")
        return False
    return True


def handle_healthz_route(db, check_type: str = "heavy"):
    """
    Health check route.
    :param check_type: Type of health check to perform. Options are 'light' and 'heavy' (e.g. light)
    """
    msg, code = "Healthy", 200
    if not healthz(db, check_type):
        msg, code = "Unhealthy", 503
    result = {"result": msg, "success": code == 200}
    if code != 200:
        result["error"] = msg
    return flask.Response(to_json(result), code, mimetype="application/json")


def check_server_health(db, check_type: str = "heavy"):
    """
    Health check route.
    :param check_type: Type of health check to perform. Options are 'light' and 'heavy' (e.g. light)
    """
    if not healthz(db, check_type):
        return {"status": "Unhealthy"}
    return {"status": "Healthy"}


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
    if isinstance(query_result, dict):
        filtered_results = query_result
        if "rowid" in filtered_results:
            del filtered_results["rowid"]
        if "MAX(rowid)" in filtered_results:
            del filtered_results["MAX(rowid)"]
        return filtered_results
    return query_result


def getrawtransactions(tx_hashes, verbose=False, skip_missing=False, _retry=0):
    txhash_list = tx_hashes.split(",")
    return backend.getrawtransaction_batch(txhash_list, verbose, skip_missing, _retry)


def pubkeyhash_to_pubkey(address: str, provided_pubkeys: str = None):
    """
    Get pubkey for an address.
    :param address: Address to get pubkey for. (e.g. 14TjwxgnuqgB4HcDcSZk2m7WKwcGVYxRjS)
    :param provided_pubkeys: Comma separated list of provided pubkeys.
    """
    if provided_pubkeys:
        provided_pubkeys_list = provided_pubkeys.split(",")
    else:
        provided_pubkeys_list = None
    return backend.pubkeyhash_to_pubkey(address, provided_pubkeys=provided_pubkeys_list)


def get_transaction(tx_hash: str, format: str = "json"):
    """
    Get a transaction from the blockchain
    :param tx_hash: The transaction hash (e.g. 3190047bf2320bdcd0fade655ae49be309519d151330aa478573815229cc0018)
    :param format: Whether to return JSON output or raw hex (e.g. hex)
    """
    return backend.getrawtransaction(tx_hash, verbose=(format == "json"))


def get_backend_height():
    block_count = backend.getblockcount()
    blocks_behind = backend.getindexblocksbehind()
    return block_count + blocks_behind


def init_api_access_log(flask_app):
    """Initialize API logger."""
    flask_app.logger.removeHandler(flask.logging.default_handler)
    flask_app.logger.setLevel(logging.DEBUG)
    werkzeug_logger = logging.getLogger("werkzeug")
    while len(werkzeug_logger.handlers) > 0:
        werkzeug_logger.removeHandler(werkzeug_logger.handlers[0])

    # Log to file, if configured...
    if config.API_LOG:
        handler = logging_handlers.RotatingFileHandler(
            config.API_LOG, "a", config.API_MAX_LOG_SIZE, config.API_MAX_LOG_COUNT
        )
        handler.propagate = False
        handler.setLevel(logging.DEBUG)
        flask_app.logger.addHandler(handler)
        werkzeug_logger.addHandler(handler)

    flask.cli.show_server_banner = lambda *args: None


def get_args_description(function):
    docstring = parse_docstring(function.__doc__)
    args = {}
    for param in docstring.params:
        args[param.arg_name] = param.description
    return args


def function_needs_db(function):
    return "db" in inspect.signature(function).parameters


def prepare_route_args(function):
    args = []
    function_args = inspect.signature(function).parameters
    args_description = get_args_description(function)
    for arg_name, arg in function_args.items():
        if arg_name == "construct_args":
            for carg_name, carg_info in transaction.COMPOSE_COMMONS_ARGS.items():
                args.append(
                    {
                        "name": carg_name,
                        "type": carg_info[0].__name__,
                        "default": carg_info[1],
                        "description": carg_info[2],
                        "required": False,
                    }
                )
            continue
        annotation = arg.annotation
        if annotation is inspect.Parameter.empty:
            continue
        route_arg = {"name": arg_name}
        default = arg.default
        if default is not inspect.Parameter.empty:
            route_arg["default"] = default
            route_arg["required"] = False
        else:
            route_arg["required"] = True
        route_arg["type"] = arg.annotation.__name__
        if arg_name in args_description:
            route_arg["description"] = args_description[arg_name]
        args.append(route_arg)
    return args


def get_function_description(function):
    docstring = parse_docstring(function.__doc__)
    return docstring.description


def prepare_routes(routes):
    prepared_routes = {}
    for route, function in routes.items():
        prepared_routes[route] = {
            "function": function,
            "description": get_function_description(function),
            "args": prepare_route_args(function),
        }
    return prepared_routes


class ApiJsonEncoder(json.JSONEncoder):
    def default(self, o):
        if isinstance(o, decimal.Decimal):
            return str(o)
        if isinstance(o, bytes):
            return o.hex()
        return super().default(o)


def to_json(obj, indent=None):
    return json.dumps(obj, cls=ApiJsonEncoder, indent=indent)
