import json
import logging

import requests

from counterpartycore.lib import config, exceptions, ledger
from counterpartycore.lib.ledger.currentstate import CurrentState
from counterpartycore.lib.messages.data import checkpoints
from counterpartycore.lib.parser import protocol
from counterpartycore.lib.utils import database, hashcodec, protocolstatus
from counterpartycore.lib.utils.helpers import dhash_string

logger = logging.getLogger(config.LOGGER_NAME)


def _network_checkpoints():
    if config.TESTNET3:
        return checkpoints.CHECKPOINTS_TESTNET3
    if config.TESTNET4:
        return checkpoints.CHECKPOINTS_TESTNET4
    if config.REGTEST:
        return checkpoints.CHECKPOINTS_REGTEST
    if config.SIGNET:
        return checkpoints.CHECKPOINTS_SIGNET
    return checkpoints.CHECKPOINTS_MAINNET


def stored_checkpoints(db):
    """Reject inconsistent stored history before serving, including API-only mode.

    Check both enforced hashes at every applicable checkpoint in one read
    snapshot. A newly introduced checkpoint may be behind the existing tip and
    would never be visited by normal forward parsing. This checks stored hashes,
    not all historical transactions, and never repairs or rewrites the ledger.
    """
    checked = 0
    with db:
        cursor = db.cursor()
        try:
            # Fetched-but-unparsed blocks have neither hash. A partially missing
            # checkpoint hash must still be checked if the other hash exists.
            tip = cursor.execute(
                """SELECT MAX(block_index) AS block_index FROM blocks
                   WHERE block_index != ?
                     AND (ledger_hash IS NOT NULL OR txlist_hash IS NOT NULL)""",
                (config.MEMPOOL_BLOCK_INDEX,),
            ).fetchone()["block_index"]
            if tip is None:
                return 0
            for height, expected in sorted(_network_checkpoints().items()):
                if not config.BLOCK_FIRST <= height <= tip:
                    continue
                row = cursor.execute(
                    "SELECT ledger_hash, txlist_hash FROM blocks WHERE block_index = ?",
                    (height,),
                ).fetchone()
                for field in ("ledger_hash", "txlist_hash"):
                    value = row[field] if row else None
                    try:
                        actual = hashcodec.hash_from_db(value)
                    except TypeError:
                        actual = f"<invalid {type(value).__name__}>"
                    if actual != expected[field]:
                        raise exceptions.ConsensusError(
                            f"Stored {field} checkpoint mismatch at block {height}: "
                            f"found {str(actual)[:128]}, expected {expected[field]}. "
                            "Refusing to start the API with inconsistent ledger history. "
                            "Restore a verified ledger snapshot or use rollback/reparse "
                            "from a verified earlier point. A State DB refresh alone "
                            "does not repair ledger history."
                        )
                checked += 1
        finally:
            cursor.close()
    logger.info("Validated %d stored ledger checkpoints through block %d.", checked, tip)
    return checked


def consensus_hash(db, field, previous_consensus_hash, content):
    assert field in ("ledger_hash", "txlist_hash", "messages_hash"), "Invalid field"

    cursor = db.cursor()
    block_index = CurrentState().current_block_index()

    # Initialise previous hash on first block.
    if block_index <= config.BLOCK_FIRST:
        assert not previous_consensus_hash, "Previous consensus hash is not None"
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
    elif config.SIGNET:
        consensus_hash_version = checkpoints.CONSENSUS_HASH_VERSION_SIGNET
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
    if found_hash and field != "messages_hash":
        # Check against existing value.
        if calculated_hash != found_hash:
            raise exceptions.ConsensusError(
                f"Inconsistent {field} for block {block_index} (calculated {calculated_hash}, vs {found_hash} in database)."
            )

    # Check against checkpoints.
    network_checkpoints = _network_checkpoints()

    if (
        field != "messages_hash"
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


def software_version(*, enforce=True):
    if config.FORCE and enforce:
        return True
    logger.debug("Checking Counterparty version...")
    state = protocolstatus.current() or protocolstatus.ProtocolStatus()
    try:
        response = requests.get(
            config.PROTOCOL_CHANGES_URL, headers={"cache-control": "no-cache"}, timeout=10
        )
        response.raise_for_status()
        versions = json.loads(response.text)
        # Validate every applicable requirement before replacing the cache.
        requirements = []
        current_version = (config.VERSION_MAJOR, config.VERSION_MINOR, config.VERSION_REVISION)
        if not isinstance(versions, dict) or not versions:
            raise TypeError("Protocol manifest must be a non-empty object")
        for change_name, change in versions.items():
            major = change["minimum_version_major"]
            if type(major) is not int or major < 0:
                raise TypeError("Protocol minimum versions must be non-negative integers")
            # Parameter-only entries have major=0 and no other version fields.
            # Older major versions are already supported by this binary.
            if major < current_version[0]:
                continue
            version = [change[f"minimum_version_{part}"] for part in ("major", "minor", "revision")]
            if any(type(value) is not int or value < 0 for value in version):
                raise TypeError("Protocol minimum versions must be non-negative integers")
            if tuple(version) <= current_version:
                continue
            activation_height = change.get(
                protocol.network_block_index_name(), change["block_index"]
            )
            if type(activation_height) is not int or activation_height < 0:
                raise TypeError("Protocol activation heights must be non-negative integers")
            requirements.append(
                {
                    "change_name": change_name,
                    "version": version,
                    "activation_height": activation_height,
                }
            )
        height = CurrentState().current_block_index() or 0
        state.publish(requirements, height)
    except (
        requests.exceptions.RequestException,
        ConnectionRefusedError,
        TimeoutError,
        ValueError,
        KeyError,
        TypeError,
        AttributeError,
        exceptions.VersionCheckError,
    ) as e:
        try:
            state.unavailable()
        except exceptions.VersionCheckError:
            logger.error("Could not publish protocol metadata failure")
        raise exceptions.VersionCheckError(
            f"Unable to check Counterparty version from {config.PROTOCOL_CHANGES_URL}: {e}. "
            "Use --force to ignore verification."
        ) from e

    if enforce:
        state.require_supported(height)
        status = state.summary(height)
        if status["status"] == "upgrade_pending":
            logger.warning(
                "Upgrade to v%s before block %s (%s)",
                status["required_version"],
                status["activation_height"],
                status["change_name"],
            )
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
