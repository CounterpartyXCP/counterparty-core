import logging
import time

import flask

from counterpartycore.lib import (
    backend,
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
    latest_block_index = backend.bitcoind.getblockcount()
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
