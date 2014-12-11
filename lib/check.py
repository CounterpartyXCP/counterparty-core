import json
import requests
import logging
import warnings

from lib import (config, util, exceptions)

CONSENSUS_HASH_SEED = 'We can only see a short distance ahead, but we can see plenty there that needs to be done.'

CONSENSUS_HASH_VERSION_MAINNET = 2
CHECKPOINTS_MAINNET = {
    config.BLOCK_FIRST_MAINNET: {'ledger_hash': '766ff0a9039521e3628a79fa669477ade241fc4c0ae541c3eae97f34b547b0b7', 'txlist_hash': '766ff0a9039521e3628a79fa669477ade241fc4c0ae541c3eae97f34b547b0b7'},
    280000: {'ledger_hash': '265719e2770d5a6994f6fe49839069183cd842ee14f56c2b870e56641e8a8725', 'txlist_hash': 'a59b33b4633649db4f14586af47e258ed9b8884dbb7aa308fb1f49a653ee60f4'},
    290000: {'ledger_hash': '4612ed7034474b4ff1727eb0e216d533ebe7ac755fb015e0f9a170c063f3e84c', 'txlist_hash': 'c15423c849fd360d38cbd6c6c3ea37a07fece723da92353f3056facc2676d9e7'},
    300000: {'ledger_hash': '9a3dd4949780404d61e5ca1929f94a43f08eb0fa19ccb4b5d6a61cafd7943199', 'txlist_hash': 'efa02dbdcc4158a598e3b476ece5ba9cc8d26f3abc8ac3777ac6dde0f0afc7e6'},
    310000: {'ledger_hash': '45e43d5cc77ea01129df01d7f55b0c89b2d4e18cd3d626fd92f30bfb37a85f4d', 'txlist_hash': '83cdcf75833d828ded09979b601fde87e2fdb0f5eb1cc6ab5d2042b7ec85f90e'},
    320000: {'ledger_hash': '91c1d33626669e8098bc762b1a9e3f616884e4d1cadda4881062c92b0d3d3e98', 'txlist_hash': '761793042d8e7c80e14a16c15bb9d40e237c468a87c207a59730b616bdfde7d4'},
    330000: {'ledger_hash': 'dd56aa97e5ca15841407f383ce1d7814536a594d7cfffcb4cf60bee8b362065a', 'txlist_hash': '3c45b4377a99e020550a198daa45c378c488a72ba199b53deb90b320d55a897b'}
}

CONSENSUS_HASH_VERSION_TESTNET = 5
CHECKPOINTS_TESTNET = {
    config.BLOCK_FIRST_TESTNET: {'ledger_hash': '907a4d21c9d6972a12a701c82975f2e23facc12c8e5e0f12846d1944d04e2081', 'txlist_hash': '907a4d21c9d6972a12a701c82975f2e23facc12c8e5e0f12846d1944d04e2081'},
    312000: {'ledger_hash': '3698b6a7abec4088822a4871d695cccacb0b8d82650157f2714e4be120289d4a', 'txlist_hash': '4160ed1fef8492221e1c4daddd6a6720211f786d67869f40017234ccada652e4'}
}


class ConsensusError (Exception): pass
def consensus_hash (db, block_index, field, previous_consensus_hash, content):
    cursor = db.cursor()

    # Initialise previous hash on first block.
    if block_index == config.BLOCK_FIRST:
        assert not previous_consensus_hash
        previous_consensus_hash = util.dhash_string(CONSENSUS_HASH_SEED)

    # Get previous hash.
    if not previous_consensus_hash:
        previous_consensus_hash = list(cursor.execute('''SELECT * FROM blocks WHERE block_index = ?''', (block_index - 1,)))[0][field]
        if not previous_consensus_hash:
            raise ConsensusError('Empty previous {} for block {}. Please launch a `reparse`.'.format(field, block_index))

    # Calculate current hash.
    version = CONSENSUS_HASH_VERSION_TESTNET if config.TESTNET else CONSENSUS_HASH_VERSION_MAINNET
    calculated_hash = util.dhash_string(previous_consensus_hash + '{}{}'.format(version, ''.join(content)))

    # Verify hash (if already in database) or save hash (if not).
    found_hash = list(cursor.execute('''SELECT * FROM blocks WHERE block_index = ?''', (block_index,)))[0][field]
    if found_hash:
        # Check against existing value.
        if calculated_hash != found_hash:
            raise ConsensusError('Inconsistent {} for block {}.'.format(field, block_index))
    else:
        # Save new hash.
        cursor.execute('''UPDATE blocks SET {} = ? WHERE block_index = ?'''.format(field), (calculated_hash, block_index))

    # Check against checkpoints.
    checkpoints = CHECKPOINTS_TESTNET if config.TESTNET else CHECKPOINTS_MAINNET
    if block_index in checkpoints and checkpoints[block_index][field] != calculated_hash:
        raise ConsensusError('Incorrect {} for block {}.'.format(field, block_index))

    return calculated_hash

class SanityError (Exception): pass
def asset_conservation (db):
    logging.debug('Status: Checking for conservation of assets.')
    supplies = util.supplies(db)
    for asset in supplies.keys():
        issued = supplies[asset]
        held = sum([holder['address_quantity'] for holder in util.holders(db, asset)])
        if held != issued:
            raise SanityError('{} {} issued ≠ {} {} held'.format(util.value_out(db, issued, asset), asset, util.value_out(db, held, asset), asset))
        logging.debug('Status: {} has been conserved ({} {} both issued and held)'.format(asset, util.value_out(db, issued, asset), asset))

class VersionError (Exception): pass
class VersionUpdateRequiredError (VersionError): pass
def check_change(protocol_change):

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
        explanation = 'Your version of counterpartyd is v{}, but, as of block {}, the minimum version is v{}.{}.{}. Reason: ‘{}’. Please upgrade to the latest version and restart the server.'.format(
            config.VERSION_STRING, protocol_change['block_index'], protocol_change['minimum_version_major'], protocol_change['minimum_version_minor'],
            protocol_change['minimum_version_revision'], change_name)
        if block_index >= protocol_change['block_index']:
            raise VersionUpdateRequiredError(explanation)
        else:
            warnings.warn(explanation)

def version (block_index):
    try:
        host = 'https://counterpartyxcp.github.io/counterpartyd/version.json'
        response = requests.get(host, headers={'cache-control': 'no-cache'})
        versions = json.loads(response.text)
    except Exception as e:
        raise VersionError('Unable to check version. How’s your Internet access?')

    # TODO: The first branch is for backwards‐compatibility and can be removed
    # once these changes are pushed to `master`.
    if 'minimum_version_major' in versions.keys():
        protocol_change = versions
        check_change(protocol_change)
    else:
        for change_name in versions:
            protocol_change = versions[change_name]
            check_change(protocol_change)

    logging.debug('Status: Version check passed.')
    return

def backend (db):
    """Checks blocktime of last block to see if {} Core is running behind.""".format(config.BTC_NAME)
    block_count = get_block_count()
    block_hash = get_block_hash(block_count)
    block = get_block(block_hash)
    time_behind = time.time() - block['time']   # TODO: Block times are not very reliable.
    if time_behind > 60 * 60 * 2:   # Two hours.
        raise util.BitcoindError('Bitcoind is running about {} seconds behind.'.format(round(time_behind)))

def database (db, blockcount):
    """Checks {} database to see if the {} server has caught up with Bitcoind.""".format(config.XCP_NAME, config.XCP_CLIENT)
    if util.last_block(db)['block_index'] + 1 < blockcount:
        raise exceptions.DatabaseError('{} database is behind Bitcoind. Is the {} server running?'.format(config.XCP_NAME, config.XCP_CLIENT))
    return

# vim: tabstop=8 expandtab shiftwidth=4 softtabstop=4
