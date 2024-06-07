import decimal
import inspect
import json
import logging
import time
import typing
from logging import handlers as logging_handlers

import flask
import requests
import werkzeug
from counterpartycore.lib import backend, config, exceptions, ledger, transaction, util
from docstring_parser import parse as parse_docstring

D = decimal.Decimal
logger = logging.getLogger(config.LOGGER_NAME)


def check_last_parsed_block(db, blockcount):
    """Checks database to see if is caught up with backend."""
    last_block = ledger.get_last_block(db)
    if time.time() - last_block["block_time"] < 60:
        return
    if util.CURRENT_BLOCK_INDEX + 1 < blockcount:
        raise exceptions.DatabaseError(f"{config.XCP_NAME} database is behind backend.")
    logger.trace("API Server - Database state check passed.")


def healthz_light(db):
    latest_block_index = backend.bitcoind.getblockcount()
    check_last_parsed_block(db, latest_block_index)


def healthz_heavy(db):
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


def healthz(db, check_type: str = "light"):
    try:
        if check_type == "heavy":
            healthz_light(db)
            healthz_heavy(db)
        else:
            healthz_light(db)
    except Exception as e:
        # logger.exception(e)
        logger.error(f"Health check failed: {e}")
        return False
    return True


def handle_healthz_route(db, check_type: str = "light"):
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


def check_server_health(db, check_type: str = "light"):
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
    return transaction.pubkeyhash_to_pubkey(address, provided_pubkeys=provided_pubkeys_list)


def get_transaction(tx_hash: str, format: str = "json"):
    """
    Get a transaction from the blockchain
    :param tx_hash: The transaction hash (e.g. 3190047bf2320bdcd0fade655ae49be309519d151330aa478573815229cc0018)
    :param format: Whether to return JSON output or raw hex (e.g. hex)
    """
    return backend.bitcoind.getrawtransaction(tx_hash, verbose=format == "json")


def get_oldest_transaction_by_address(address: str, block_index: int = None):
    """
    Get the oldest transaction for an address.
    :param address: The address to search for. (e.g. 14TjwxgnuqgB4HcDcSZk2m7WKwcGVYxRjS)
    :param block_index: The block index to search from.
    """
    return backend.addrindexrs.get_oldest_tx(
        address, block_index=block_index or util.CURRENT_BLOCK_INDEX
    )


def get_backend_height():
    block_count = backend.bitcoind.getblockcount()
    blocks_behind = backend.bitcoind.get_blocks_behind()
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
        if route_arg["type"] == "Literal":
            route_arg["type"] = "enum[str]"
            route_arg["members"] = list(typing.get_args(annotation))
        if arg_name in args_description:
            route_arg["description"] = args_description[arg_name]
        args.append(route_arg)
    if not function.__name__.endswith("_v1"):
        args.append(
            {
                "name": "verbose",
                "type": "bool",
                "default": "false",
                "description": "Include asset and dispenser info and normalized quantities in the response.",
                "required": False,
            }
        )
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


def inject_issuances_and_block_times(db, result):
    # let's work with a list
    result_list = result
    result_is_dict = False
    if isinstance(result, dict):
        result_list = [result]
        result_is_dict = True

    asset_fields = ["asset", "give_asset", "get_asset", "dividend_asset"]

    # gather asset list and block indexes
    asset_list = []
    block_indexes = []
    for result_item in result_list:
        for field_name in [
            "block_index",
            "first_issuance_block_index",
            "last_issuance_block_index",
        ]:
            if field_name in result_item:
                result_item[field_name] = int(result_item[field_name])
            if "params" in result_item and field_name in result_item["params"]:
                result_item["params"][field_name] = int(result_item["params"][field_name])
            if field_name in result_item and result_item[field_name] not in block_indexes:
                block_indexes.append(result_item[field_name])
            if (
                "params" in result_item
                and field_name in result_item["params"]
                and result_item["params"][field_name] not in block_indexes
            ):
                block_indexes.append(result_item["params"][field_name])

        if "asset_longname" in result_item and "description" in result_item:
            continue
        item = result_item
        if "params" in item:
            item = item["params"]
        for field_name in asset_fields:
            if field_name in item:
                if item[field_name] not in asset_list:
                    asset_list.append(item[field_name])

    # get asset issuances
    issuance_by_asset = ledger.get_assets_last_issuance(db, asset_list)

    # get block_time for each block_index
    block_times = ledger.get_blocks_time(db, block_indexes)

    # inject issuance and block_time
    for result_item in result_list:
        item = result_item
        for field_name in [
            "block_index",
            "first_issuance_block_index",
            "last_issuance_block_index",
        ]:
            field_name_time = field_name.replace("index", "time")
            if field_name in item:
                item[field_name_time] = block_times[item[field_name]]
            if "params" in item and field_name in item["params"]:
                item["params"][field_name_time] = block_times[item["params"][field_name]]
        if "params" in item:
            item = item["params"]
        for field_name in asset_fields:
            if field_name in item and item[field_name] in issuance_by_asset:
                item[field_name + "_info"] = issuance_by_asset[item[field_name]]

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

    asset_fields = [
        "quantity",
        "give_quantity",
        "get_quantity",
        "get_remaining",
        "give_remaining",
        "escrow_quantity",
        "dispense_quantity",
        "quantity_per_unit",
    ]
    divisible_fields = [
        "satoshirate",
        "burned",
        "earned",
        "btc_amount",
        "fee_paid",
        "fee_provided",
        "fee_required",
        "fee_required_remaining",
        "fee_provided_remaining",
        "fee_fraction_int",
    ]
    quantity_fields = asset_fields + divisible_fields

    # inject normalized quantities
    for result_item in result_list:
        item = result_item.copy()
        for field_name in quantity_fields:
            if "params" in item:
                item = item["params"]
            if "dispenser" in item and field_name != "dispense_quantity":
                item = result_item["dispenser"]
            if field_name not in item:
                item = result_item
                continue

            is_divisible = True
            if field_name not in divisible_fields:
                if field_name == "quantity_per_unit":
                    issuance_field_name = "dividend_asset_info"
                else:
                    issuance_field_name = (
                        field_name.replace("quantity", "asset").replace("remaining", "asset")
                        + "_info"
                    )
                if issuance_field_name not in item:
                    issuance_field_name = "asset_info"
                if issuance_field_name not in item and issuance_field_name not in result_item:
                    item = result_item
                    continue
                if issuance_field_name not in item:
                    is_divisible = result_item[issuance_field_name]["divisible"]
                else:
                    is_divisible = item[issuance_field_name]["divisible"]

            if item[field_name] is not None:
                item[field_name + "_normalized"] = (
                    divide(item[field_name], 10**8) if is_divisible else str(item[field_name])
                )
            item = result_item

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


def inject_details(db, result):
    result = inject_dispensers(db, result)
    result = inject_issuances_and_block_times(db, result)
    result = inject_normalized_quantities(result)
    return result


def redirect_to_rpc_v1():
    """
    Redirect to the RPC API v1.
    """
    query_params = {
        "headers": flask.request.headers,
        "auth": (config.RPC_USER, config.RPC_PASSWORD),
    }
    url = f"http://localhost:{config.RPC_PORT}/"
    if flask.request.query_string:
        url += f"?{flask.request.query_string}"
    request_function = getattr(requests, flask.request.method.lower())
    if flask.request.method == "POST":
        try:
            query_params["json"] = flask.request.json
        except werkzeug.exceptions.UnsupportedMediaType as e:
            raise exceptions.JSONRPCInvalidRequest("Invalid JSON-RPC 2.0 request format") from e
    return request_function(url, **query_params)
