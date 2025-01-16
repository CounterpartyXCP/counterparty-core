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
    last_block = ledger.ledger.get_last_block(db)
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
            "quantity": 100000000,
        },
        allow_unconfirmed_inputs=True,
        exact_fee=1000,
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
    return flask.Response(helpers.to_json(result), code, mimetype="application/json")


def check_server_health(db, check_type: str = "light"):
    """
    Health check route.
    :param check_type: Type of health check to perform. Options are 'light' and 'heavy' (e.g. light)
    """
    if not healthz(db, check_type):
        return {"status": "Unhealthy"}
    return {"status": "Healthy"}
