import logging
import time

import flask

from counterpartycore.lib import (
    config,
    exceptions,
    ledger,
)
from counterpartycore.lib.api import composer
from counterpartycore.lib.ledger.currentstate import CurrentState
from counterpartycore.lib.utils import helpers

logger = logging.getLogger(config.LOGGER_NAME)


def check_last_parsed_block(db, blockcount):
    """Checks database to see if is caught up with backend."""
    last_block = ledger.blocks.get_last_block(db)
    if last_block is None:
        raise exceptions.DatabaseError(
            f"{config.XCP_NAME} database is behind backend."
        )  # No blocks in the database
    if time.time() - last_block["block_time"] < 60:
        return
    if CurrentState().current_block_index() + 1 < blockcount:
        raise exceptions.DatabaseError(f"{config.XCP_NAME} database is behind backend.")
    logger.trace("API Server - Database state check passed.")


def healthz_light(db):
    # Use the cached backend block count (kept fresh in shared memory by the BackendHeight
    # thread) instead of a live `getblockcount` RPC. The RPC is an unbounded dependency call
    # that, in the request path, could amplify an overload (issue #3460). When the value is not
    # yet known (pre-startup / API-only), fall back to the last parsed block so the check passes
    # rather than making a blocking network call.
    latest_block_index = CurrentState().current_block_count()
    if not latest_block_index:
        latest_block_index = CurrentState().current_block_index() or 0
    check_last_parsed_block(db, latest_block_index)


def healthz_heavy(db):
    composer.compose_transaction(
        db,
        name="send",
        params={
            "source": config.UNSPENDABLE,
            "destination": config.UNSPENDABLE,
            "asset": config.XCP,
            "quantity": 600,
        },
        construct_parameters={
            "validate": False,
            "allow_unconfirmed_inputs": True,
            "exact_fee": 300,
            "inputs_set": "15d26ce17ef81cf6a12bf5fc0a62940eda3c1f82bd14adcc1e7b668fa3b67487:0:600:76a914818895f3dc2c178629d3d2d8fa3ec4a3f817982188ac",
        },
    )


def healthz(db, check_type: str = "light"):
    try:
        if check_type == "heavy":
            healthz_light(db)
            healthz_heavy(db)
        else:
            healthz_light(db)
    except Exception as e:  # pylint: disable=broad-except
        logger.exception(e)
        logger.error("Health check failed: %s", e)
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
    return flask.Response(helpers.to_json(result), code, mimetype="application/json")


def check_server_health(db, check_type: str = "light"):
    """
    Health check route.
    :param check_type: Type of health check to perform. Options are 'light' and 'heavy' (e.g. light)
    """
    if not healthz(db, check_type):
        return {"status": "Unhealthy"}
    return {"status": "Healthy"}


def rate_limited():
    """
    Returns a 429 rate limit error response.
    Used as a target for Cloud Armor rate limiting rules.
    """
    # Handle CORS preflight
    if flask.request.method == "OPTIONS":
        response = flask.Response("", 204)
    else:
        result = {"error": "rate_limit_exceeded"}
        response = flask.Response(helpers.to_json(result), 429, mimetype="application/json")
    response.headers["Access-Control-Allow-Origin"] = "*"
    response.headers["Access-Control-Allow-Headers"] = "*"
    response.headers["Access-Control-Allow-Methods"] = "*"
    return response
