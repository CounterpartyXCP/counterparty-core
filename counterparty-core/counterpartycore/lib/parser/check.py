import json
import logging

import requests

from counterpartycore.lib import config, exceptions, ledger
from counterpartycore.lib.ledger.currentstate import CurrentState
from counterpartycore.lib.messages.data import checkpoints
from counterpartycore.lib.utils import database
from counterpartycore.lib.utils.helpers import dhash_string

logger = logging.getLogger(config.LOGGER_NAME)


def consensus_hash(db, field, previous_consensus_hash, content):
    assert field in ("ledger_hash", "txlist_hash", "messages_hash", "migration_hash")

    cursor = db.cursor()
    block_index = CurrentState().current_block_index()

    # Initialise previous hash on first block.
    if block_index <= config.BLOCK_FIRST:
        assert not previous_consensus_hash
        previous_consensus_hash = dhash_string(checkpoints.CONSENSUS_HASH_SEED)

    # Get previous hash.
    if not previous_consensus_hash:
        try:
            previous_consensus_hash = list(
                cursor.execute("""SELECT * FROM blocks WHERE block_index = ?""", (block_index - 1,))
            )[0][field]
        except IndexError:
            previous_consensus_hash = None
        if not previous_consensus_hash:
            raise exceptions.ConsensusError(
                f"Empty previous {field} for block {block_index}. Please launch a `rollback`."
            )

    # Calculate current hash.
    if config.TESTNET3:
        consensus_hash_version = checkpoints.CONSENSUS_HASH_VERSION_TESTNET3
    elif config.TESTNET4:
        consensus_hash_version = checkpoints.CONSENSUS_HASH_VERSION_TESTNET4
    elif config.REGTEST:
        consensus_hash_version = checkpoints.CONSENSUS_HASH_VERSION_REGTEST
    else:
        consensus_hash_version = checkpoints.CONSENSUS_HASH_VERSION_MAINNET

    calculated_hash = dhash_string(
        previous_consensus_hash + f"{consensus_hash_version}{''.join(content)}"
    )

    # Verify hash (if already in database) or save hash (if not).
    # NOTE: do not enforce this for messages_hashes, those are more informational (for now at least)
    found_hash = (
        list(cursor.execute("""SELECT * FROM blocks WHERE block_index = ?""", (block_index,)))[0][
            field
        ]
        or None
    )
    if found_hash and field not in ["messages_hash", "ledger_hash"]:
        # Check against existing value.
        if calculated_hash != found_hash:
            raise exceptions.ConsensusError(
                f"Inconsistent {field} for block {block_index} (calculated {calculated_hash}, vs {found_hash} in database)."
            )

    # Check against checkpoints.
    if config.TESTNET3:
        network_checkpoints = checkpoints.CHECKPOINTS_TESTNET3
    elif config.TESTNET4:
        network_checkpoints = checkpoints.CHECKPOINTS_TESTNET4
    elif config.REGTEST:
        network_checkpoints = checkpoints.CHECKPOINTS_REGTEST
    else:
        network_checkpoints = checkpoints.CHECKPOINTS_MAINNET

    if (
        field not in ["messages_hash", "ledger_hash"]
        and block_index in network_checkpoints
        and network_checkpoints[block_index][field] != calculated_hash
    ):
        error_message = f"Incorrect {field} hash for block {block_index}.  Calculated {calculated_hash} but expected {network_checkpoints[block_index][field]}"
        raise exceptions.ConsensusError(error_message)

    return calculated_hash, found_hash


def asset_conservation(db, stop_event=None):
    logger.debug("Checking for conservation of assets.")
    with db:
        supplies = ledger.supplies.supplies(db)
        held = ledger.supplies.held(db)
        for asset in supplies.keys():
            if stop_event is not None and stop_event.is_set():
                logger.debug("Stop event received. Exiting asset conservation check...")
                return
            asset_issued = supplies[asset]
            asset_held = held[asset] if asset in held and held[asset] is not None else 0  # noqa: E711
            if asset_issued != asset_held:
                raise exceptions.SanityError(
                    f"{ledger.issuances.value_out(db, asset_issued, asset)} {asset} issued ≠ "
                    f"{ledger.issuances.value_out(db, asset_held, asset)} {asset} held"
                )
            logger.trace(
                "%s has been conserved (%s %s both issued and held)",
                asset,
                ledger.issuances.value_out(db, asset_issued, asset),
                asset,
            )
    logger.debug("All assets have been conserved.")


def check_change(protocol_change, change_name):
    # Check client version.
    passed = True
    if config.VERSION_MAJOR < protocol_change["minimum_version_major"]:
        passed = False
    elif config.VERSION_MAJOR == protocol_change["minimum_version_major"]:
        if config.VERSION_MINOR < protocol_change["minimum_version_minor"]:
            passed = False
        elif config.VERSION_MINOR == protocol_change["minimum_version_minor"]:
            if config.VERSION_REVISION < protocol_change["minimum_version_revision"]:
                passed = False

    if not passed:
        explanation = f"Your version of {config.APP_NAME} is v{config.VERSION_STRING}, but, "
        explanation += f"as of block {protocol_change['block_index']}, the minimum version is "
        explanation += f"v{protocol_change['minimum_version_major']}.{protocol_change['minimum_version_minor']}.{protocol_change['minimum_version_revision']}. "
        explanation += f"Reason: ' {change_name} '. Please upgrade to the latest version and restart the server."
        if CurrentState().current_block_index() >= protocol_change["block_index"]:
            raise exceptions.VersionUpdateRequiredError(explanation)
        logger.warning(explanation)


def software_version():
    if config.FORCE:
        return True
    logger.debug("Checking Counterparty version...")

    try:
        response = requests.get(
            config.PROTOCOL_CHANGES_URL, headers={"cache-control": "no-cache"}, timeout=10
        )
        versions = json.loads(response.text)
    except (
        requests.exceptions.ConnectionError,
        ConnectionRefusedError,
        ValueError,
        requests.exceptions.ReadTimeout,
        TimeoutError,
        json.decoder.JSONDecodeError,
    ) as e:
        logger.error(e, exc_info=True)
        raise exceptions.VersionCheckError(
            "Unable to check Counterparty version. Use --force to ignore verfication."
        ) from e

    for change_name in versions:
        protocol_change = versions[change_name]
        check_change(protocol_change, change_name)

    logger.debug("Version check passed.")
    return True


def check_database_version(db, upgrade_actions_callback, database_name):
    # Update version if new database.
    with database.LedgerDBConnectionPool().connection() as ledger_db:
        last_block_index = ledger.blocks.last_db_index(ledger_db)
    if last_block_index <= config.BLOCK_FIRST:
        logger.debug("New database detected. Updating database version.")
        database.update_version(db)
        return
    if config.FORCE:
        logger.debug("FORCE mode enabled. Skipping database version check.")
        return
    logger.debug("Checking Ledger database version...")

    database_version = database.get_config_value(db, "VERSION_STRING")
    if database_version != config.VERSION_STRING:
        upgrade_actions = config.UPGRADE_ACTIONS[config.NETWORK_NAME].get(config.VERSION_STRING, [])
        logger.info("Database version mismatch. Required actions: %s", upgrade_actions)
        upgrade_actions_callback(db, upgrade_actions)
        # refresh the current block index
        CurrentState().set_current_block_index(ledger.blocks.last_db_index(db))
        # update the database version
        database.update_version(db)
    else:
        logger.debug("%s database is up to date.", database_name)
