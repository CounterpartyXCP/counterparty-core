import logging

import flask
from counterpartylib.lib import backend, config, exceptions, ledger, transaction

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


def pubkeyhash_to_pubkey(address, provided_pubkeys=None):
    if provided_pubkeys:
        provided_pubkeys_list = provided_pubkeys.split(",")
    else:
        provided_pubkeys_list = None
    return backend.pubkeyhash_to_pubkey(address, provided_pubkeys=provided_pubkeys_list)


def get_backend_height():
    block_count = backend.getblockcount()
    blocks_behind = backend.getindexblocksbehind()
    return block_count + blocks_behind
