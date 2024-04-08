import logging

import flask
from counterparylib.lib import backend, config, exceptions, ledger, transaction

logger = logging.getLogger(config.LOGGER_NAME)


def check_last_parsed_block(blockcount):
    f"""Checks {config.XCP_NAME} database to see if is caught up with backend."""  # noqa: B021
    if ledger.CURRENT_BLOCK_INDEX + 1 < blockcount:
        raise exceptions.DatabaseError(f"{config.XCP_NAME} database is behind backend.")
    logger.debug("Database state check passed.")
    return


def healthz(db, check_type="heavy"):
    try:
        if check_type == "light":
            logger.debug("Performing light healthz check.")
            latest_block_index = backend.getblockcount()
            check_last_parsed_block(latest_block_index)
        else:
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
    except Exception:
        return False
    return True


def handle_healthz_route(db, check="heavy"):
    msg, code = "Healthy", 200
    if not healthz(db, check):
        msg, code = "Unhealthy", 503
    return flask.Response(msg, code, mimetype="application/json")
