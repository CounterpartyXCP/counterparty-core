import decimal
import inspect
import json
import logging
import time
from logging import handlers as logging_handlers

import flask
from counterpartycore.lib import backend, config, exceptions, ledger, transaction
from docstring_parser import parse as parse_docstring

D = decimal.Decimal
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


def divide(value1, value2):
    decimal.getcontext().prec = 8
    return D(value1) / D(value2)


def inject_issuance(db, result):
    # let's work with a list
    result_list = result
    result_is_dict = False
    if isinstance(result, dict):
        result_list = [result]
        result_is_dict = True

    # gather asset list
    asset_list = []
    for result_item in result_list:
        if "asset_longname" in result_item:
            continue
        item = result_item
        if "params" in item:
            item = item["params"]
        for field_name in ["asset", "give_asset", "get_asset"]:
            if field_name in item:
                if item[field_name] not in asset_list:
                    asset_list.append(item[field_name])

    # get asset issuances
    issuance_by_asset = ledger.get_assets_last_issuance(db, asset_list)

    # inject issuance
    for result_item in result_list:
        item = result_item
        if "params" in item:
            item = item["params"]
        for field_name in ["asset", "give_asset", "get_asset"]:
            if field_name in item and item[field_name] in issuance_by_asset:
                item[field_name + "_issuance"] = issuance_by_asset[item[field_name]]

    if result_is_dict:
        return result_list[0]
    return result


def inject_normalized_quantities(result):
    # let's work with a list
    result_list = result
    result_is_dict = False
    if isinstance(result, dict):
        result_list = [result]
        result_is_dict = True

    # inject normalized quantities
    for result_item in result_list:
        item = result_item
        for field_name in [
            "quantity",
            "give_quantity",
            "get_quantity",
            "get_remaining",
            "give_remaining",
            "escrow_quantity",
            "dispense_quantity",
        ]:
            if "params" in item:
                item = item["params"]
            if "dispenser" in item:
                item = result_item["dispenser"]
                # item["asset_issuance"] = result_item["asset_issuance"]
            if field_name not in item:
                continue
            issuance_field_name = (
                field_name.replace("quantity", "asset").replace("remaining", "asset") + "_issuance"
            )
            if issuance_field_name not in item:
                issuance_field_name = "asset_issuance"
            if issuance_field_name not in item and issuance_field_name not in result_item:
                continue
            if issuance_field_name not in item:
                is_divisible = result_item[issuance_field_name]["divisible"]
            else:
                is_divisible = item[issuance_field_name]["divisible"]
            item[field_name + "_normalized"] = (
                divide(item[field_name], 10**8) if is_divisible else str(item[field_name])
            )
        if "get_quantity" in item and "give_quantity" in item and "market_dir" in item:
            if item["market_dir"] == "SELL":
                item["market_price"] = divide(
                    item["get_quantity_normalized"], item["give_quantity_normalized"]
                )
            else:
                item["market_price"] = divide(
                    item["give_quantity_normalized"], item["get_quantity_normalized"]
                )

    if result_is_dict:
        return result_list[0]
    return result


def inject_dispensers(db, result):
    # let's work with a list
    result_list = result
    result_is_dict = False
    if isinstance(result, dict):
        result_list = [result]
        result_is_dict = True

    # gather dispenser list
    dispenser_list = []
    for result_item in result_list:
        if "dispenser_tx_hash" in result_item:
            if result_item["dispenser_tx_hash"] not in dispenser_list:
                dispenser_list.append(result_item["dispenser_tx_hash"])

    # get dispenser info
    dispenser_info = ledger.get_dispensers_info(db, dispenser_list)

    # inject dispenser info
    for result_item in result_list:
        if (
            "dispenser_tx_hash" in result_item
            and result_item["dispenser_tx_hash"] in dispenser_info
        ):
            result_item["dispenser"] = dispenser_info[result_item["dispenser_tx_hash"]]

    if result_is_dict:
        return result_list[0]
    return result
