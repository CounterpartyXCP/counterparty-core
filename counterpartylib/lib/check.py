import json
import requests
import logging
logger = logging.getLogger(__name__)
import warnings
import time
import sys

from counterpartylib.lib import config
from counterpartylib.lib import util
from counterpartylib.lib import exceptions
from counterpartylib.lib import backend
from counterpartylib.lib import database

CONSENSUS_HASH_SEED = 'We can only see a short distance ahead, but we can see plenty there that needs to be done.'

CONSENSUS_HASH_VERSION_MAINNET = 2
CHECKPOINTS_MAINNET = {
    config.BLOCK_FIRST_MAINNET: {'ledger_hash': '766ff0a9039521e3628a79fa669477ade241fc4c0ae541c3eae97f34b547b0b7', 'txlist_hash': '766ff0a9039521e3628a79fa669477ade241fc4c0ae541c3eae97f34b547b0b7'},
}

CONSENSUS_HASH_VERSION_TESTNET = 7
CHECKPOINTS_TESTNET = {
    config.BLOCK_FIRST_TESTNET: {'ledger_hash': '63f0fef31d02da85fa779e9a0e1b585b1a6a4e59e14564249e288e074e91c223', 'txlist_hash': '63f0fef31d02da85fa779e9a0e1b585b1a6a4e59e14564249e288e074e91c223'},
}

class ConsensusError(Exception):
    pass

def consensus_hash(db, field, previous_consensus_hash, content):
    cursor = db.cursor()
    block_index = util.CURRENT_BLOCK_INDEX

    # Initialise previous hash on first block.
    if block_index <= config.BLOCK_FIRST:
        assert not previous_consensus_hash
        previous_consensus_hash = util.dhash_string(CONSENSUS_HASH_SEED)

    # Get previous hash.
    if not previous_consensus_hash:
        try:
            previous_consensus_hash = list(cursor.execute('''SELECT * FROM blocks WHERE block_index = ?''', (block_index - 1,)))[0][field]
        except IndexError:
            previous_consensus_hash = None
        if not previous_consensus_hash:
            raise ConsensusError('Empty previous {} for block {}. Please launch a `reparse`.'.format(field, block_index))

    # Calculate current hash.
    consensus_hash_version = CONSENSUS_HASH_VERSION_TESTNET if config.TESTNET else CONSENSUS_HASH_VERSION_MAINNET
    calculated_hash = util.dhash_string(previous_consensus_hash + '{}{}'.format(consensus_hash_version, ''.join(content)))

    # Verify hash (if already in database) or save hash (if not).
    # NOTE: do not enforce this for messages_hashes, those are more informational (for now at least)
    found_hash = list(cursor.execute('''SELECT * FROM blocks WHERE block_index = ?''', (block_index,)))[0][field] or None
    if found_hash and field != 'messages_hash':
        # Check against existing value.
        if calculated_hash != found_hash:
            raise ConsensusError('Inconsistent {} for block {} (calculated {}, vs {} in database).'.format(
                field, block_index, calculated_hash, found_hash))
    else:
        # Save new hash.
        cursor.execute('''UPDATE blocks SET {} = ? WHERE block_index = ?'''.format(field), (calculated_hash, block_index))

    # Check against checkpoints.
    checkpoints = CHECKPOINTS_TESTNET if config.TESTNET else CHECKPOINTS_MAINNET
    if field != 'messages_hash' and block_index in checkpoints and checkpoints[block_index][field] != calculated_hash:
        raise ConsensusError('Incorrect {} hash for block {}.  Calculated {} but expected {}'.format(field, block_index, calculated_hash, checkpoints[block_index][field],))

    return calculated_hash, found_hash

class SanityError(Exception):
    pass

def asset_conservation(db):
    logger.debug('Checking for conservation of assets.')
    supplies = util.supplies(db)
    held = util.held(db)
    for asset in supplies.keys():
        asset_issued = supplies[asset]
        asset_held = held[asset] if asset in held and held[asset] != None else 0
        if asset_issued != asset_held:
            raise SanityError('{} {} issued ≠ {} {} held'.format(util.value_out(db, asset_issued, asset), asset, util.value_out(db, asset_held, asset), asset))
        logger.debug('{} has been conserved ({} {} both issued and held)'.format(asset, util.value_out(db, asset_issued, asset), asset))

class VersionError(Exception):
    pass
class VersionUpdateRequiredError(VersionError):
    pass

def check_change(protocol_change, change_name):

    # Check client version.
    passed = True
    if config.VERSION_MAJOR < protocol_change['minimum_version_major']:
        passed = False
    elif config.VERSION_MAJOR == protocol_change['minimum_version_major']:
        if config.VERSION_MINOR < protocol_change['minimum_version_minor']:
            passed = False
        elif config.VERSION_MINOR == protocol_change['minimum_version_minor']:
            if config.VERSION_REVISION < protocol_change['minimum_version_revision']:
                passed = False

    if not passed:
        explanation = 'Your version of {} is v{}, but, as of block {}, the minimum version is v{}.{}.{}. Reason: ‘{}’. Please upgrade to the latest version and restart the server.'.format(
            config.APP_NAME, config.VERSION_STRING, protocol_change['block_index'], protocol_change['minimum_version_major'], protocol_change['minimum_version_minor'],
            protocol_change['minimum_version_revision'], change_name)
        if util.CURRENT_BLOCK_INDEX >= protocol_change['block_index']:
            raise VersionUpdateRequiredError(explanation)
        else:
            warnings.warn(explanation)

def software_version():
    if config.FORCE:
        return
    logger.debug('Checking version.')

    try:
        host = 'https://www.monaparty.me/counterparty-lib/counterpartylib/protocol_changes.json'
        response = requests.get(host, headers={'cache-control': 'no-cache'})
        versions = json.loads(response.text)
    except (requests.exceptions.ConnectionError, ConnectionRefusedError, ValueError) as e:
        logger.warning('Unable to check version! ' + str(sys.exc_info()[1]))
        return

    for change_name in versions:
        protocol_change = versions[change_name]
        try:
            check_change(protocol_change, change_name)
        except VersionUpdateRequiredError as e:
            logger.error("Version Update Required", exc_info=sys.exc_info())
            sys.exit(config.EXITCODE_UPDATE_REQUIRED)

    logger.debug('Version check passed.')


class DatabaseVersionError(Exception):
    def __init__(self, message, reparse_block_index):
        super(DatabaseVersionError, self).__init__(message)
        self.reparse_block_index = reparse_block_index

def database_version(db):
    if config.FORCE:
        return
    logger.debug('Checking database version.')

    version_major, version_minor = database.version(db)
    if version_major != config.VERSION_MAJOR:
        # Rollback database if major version has changed.
        raise DatabaseVersionError('Client major version number mismatch ({} ≠ {}).'.format(version_major, config.VERSION_MAJOR), config.BLOCK_FIRST)
    elif version_minor != config.VERSION_MINOR:
        # Reparse all transactions if minor version has changed.
        raise DatabaseVersionError('Client minor version number mismatch ({} ≠ {}).'.format(version_minor, config.VERSION_MINOR), None)

# vim: tabstop=8 expandtab shiftwidth=4 softtabstop=4
