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
    280000: {'ledger_hash': '265719e2770d5a6994f6fe49839069183cd842ee14f56c2b870e56641e8a8725', 'txlist_hash': 'a59b33b4633649db4f14586af47e258ed9b8884dbb7aa308fb1f49a653ee60f4'},
    290000: {'ledger_hash': '4612ed7034474b4ff1727eb0e216d533ebe7ac755fb015e0f9a170c063f3e84c', 'txlist_hash': 'c15423c849fd360d38cbd6c6c3ea37a07fece723da92353f3056facc2676d9e7'},
    300000: {'ledger_hash': '9a3dd4949780404d61e5ca1929f94a43f08eb0fa19ccb4b5d6a61cafd7943199', 'txlist_hash': 'efa02dbdcc4158a598e3b476ece5ba9cc8d26f3abc8ac3777ac6dde0f0afc7e6'},
    310000: {'ledger_hash': '45e43d5cc77ea01129df01d7f55b0c89b2d4e18cd3d626fd92f30bfb37a85f4d', 'txlist_hash': '83cdcf75833d828ded09979b601fde87e2fdb0f5eb1cc6ab5d2042b7ec85f90e'},
    320000: {'ledger_hash': '91c1d33626669e8098bc762b1a9e3f616884e4d1cadda4881062c92b0d3d3e98', 'txlist_hash': '761793042d8e7c80e14a16c15bb9d40e237c468a87c207a59730b616bdfde7d4'},
    330000: {'ledger_hash': 'dd56aa97e5ca15841407f383ce1d7814536a594d7cfffcb4cf60bee8b362065a', 'txlist_hash': '3c45b4377a99e020550a198daa45c378c488a72ba199b53deb90b320d55a897b'},
    334000: {'ledger_hash': '24c4fa4097106031267439eb9fbe8ce2a18560169c67726652b608908c1ca9bb', 'txlist_hash': '764ca9e8d3b9546d1c4ff441a39594548989f60daefc6f28e046996e76a273bf'},
    335000: {'ledger_hash': 'e57c9d606a615e7e09bf99148596dd28e64b25cd8b081e226d535a64c1ed08d1', 'txlist_hash': '437d9507185b5e193627edf4998aad2264755af8d13dd3948ce119b32dd50ce2'},
    336000: {'ledger_hash': '1329ff5b80d034b64f6ea3481b7c7176437a8837b2a7cb7b8a265fdd1397572d', 'txlist_hash': '33eb8cacd4c750f8132d81e8e43ca13bd565f1734d7d182346364847414da52f'},
    337000: {'ledger_hash': '607e6a93e8d97cefea9bd55384898ee90c8477ded8a46017f2294feedbc83409', 'txlist_hash': '20b535a55abcc902ca70c19dd648cbe5149af8b4a4157b94f41b71fc422d428e'},
    338000: {'ledger_hash': 'f043914c71e4b711abb1c1002767b9a4e7d605e249facaaf7a2046b0e9741204', 'txlist_hash': 'fa2c3f7f76345278271ed5ec391d582858e10b1f154d9b44e5a1f4896400ee46'},
    339000: {'ledger_hash': '49f7240bc90ebc2f242dd599c7d2c427b9d2ac844992131e6e862b638ae4393a', 'txlist_hash': 'c1e3b497c054dcf67ddd0dc223e8b8a6e09a1a05bacb9fef5c03e48bd01e64e7'},
    340000: {'ledger_hash': '255760e2abfb79fdd76b65759f1590f582c1747f3eeccc4b2ae37d23e30e0729', 'txlist_hash': '8502004bb63e699b243ac8af072d704c69b817905e74787c2031af971e8cd87c'},
    341000: {'ledger_hash': '1369cba3909e564d2e725879a8b2cd987df075db121d1d421c8ce16b65f4bf04', 'txlist_hash': 'd217d0bed190cb27f58fcb96b255f8006bc4b9ed739e1bb08507201c49c426c8'},
    342000: {'ledger_hash': '9e7e9b8620717189ccea697ff2f84fe71bc4ae8d991481ff235164d72a9e6e4f', 'txlist_hash': 'adf75d023760101b2b337f6359dd811b12521c83837eb3f7db3bbfd0b095aa54'},
    343000: {'ledger_hash': 'aa47312ebe94b35504bec6c74713e404e5f36854e0836839344d13debe50558c', 'txlist_hash': '6bdbbc96364b3c92cea132fe66a0925f9445a249f7062326bdcc4ad4711f0c01'},
    344000: {'ledger_hash': '40187263aa96d1362bf7b19c8ba0fff7f0c0f3eb132a40fc90601b5926c7e6e3', 'txlist_hash': '98da8efe705c4b54275bfd25f816a7e7a4ff1f67647e17d7a0aaa2a3fef8bda0'},
    345000: {'ledger_hash': 'e4a1e1be4beea63d9740ca166b75bb4e3ffa2af33e1fe282e5b09c4952a7448c', 'txlist_hash': '777f163eaa5ad79dcb738871d4318a0699defec469d8afe91ab6277ff8d3e8b8'},
    350000: {'ledger_hash': '6a67e9f2e9d07e7bb3277cf9c24f84c857ed1b8fff4a37e589cd56ade276dd95', 'txlist_hash': '96bcbdbce74b782a845d4fda699846d2d3744044c2870a413c018642b8c7c3bf'},
    355000: {'ledger_hash': 'a84b17992217c7845e133a8597dac84eba1ee8c48bcc7f74bcf512837120f463', 'txlist_hash': '210d96b42644432b9e1a3433a29af9acb3bad212b67a7ae1dbc011a11b04bc24'},
    360000: {'ledger_hash': 'ddca07ea43b336b703fb8ebab6c0dc30582eb360d6f0eb0446e1fe58b53dee0a', 'txlist_hash': '31d0ff3e3782cf9464081829c5595b3de5ac477290dc069d98672f3f552767f8'},
    365000: {'ledger_hash': '2d55b126cca3eca15c07b5da683988f9e01d7346d2ca430e940fd7c07ce84fd7', 'txlist_hash': '7988a823cc1e3234953cc87d261d3c1fede8493d0a31b103357eb23cc7dc2eda'},
    366000: {'ledger_hash': '64ce274df2784f9ca88a8d7071613ec6527e506ec31cd434eca64c6a3345a6b7', 'txlist_hash': '0d4374da6100e279b24f4ba4a2d6afbfc4fb0fc2d312330a515806e8c5f49404'} 
}

CONSENSUS_HASH_VERSION_TESTNET = 6
CHECKPOINTS_TESTNET = {
    config.BLOCK_FIRST_TESTNET: {'ledger_hash': '3e2cd73017159fdc874453f227e9d0dc4dabba6d10e03458f3399f1d340c4ad1', 'txlist_hash': '3e2cd73017159fdc874453f227e9d0dc4dabba6d10e03458f3399f1d340c4ad1'},
    313000: {'ledger_hash': 'f9aa095bef80a768c68912e387268c14a2d16ced915a71d9f0c58fbf8d9554ef', 'txlist_hash': '4e0a83016b0e51df3fb905755f3ff82ae160fa1d0dce63375cf71d594d14d054'},
    316000: {'ledger_hash': 'eede57604aab218b5d94c087cc5d1b3b1c3ad92b8d583cc73a249cd31865ab73', 'txlist_hash': '988e569c0452a21efc8f3d2a2553cb7122aa574e3658c67f195262699df76c39'},
    319000: {'ledger_hash': '08145b9709f74c3faf7186884b76ace877349571870d8d40a4a185c7bdff31a6', 'txlist_hash': 'a635c17858960679b8a5787648f59f08de5fa6b362c45a66125e6bc55705a6f4'},
    322000: {'ledger_hash': 'a029da7e7f25721dd111f3fb3a3791074aaf276a26c4ef5858a0ddfc82360938', 'txlist_hash': '7da60d3080a3a74027be619106e1b9c3f963880344c26a5f93f13bc48b8a76e9'},
    325000: {'ledger_hash': '94a5d06bf7c815fac477b075893d8bb5aaabdf2a6e28ca77274bbcafaefa874e', 'txlist_hash': '2db52b2b1dae5132f14e65a97c8c95a5375630916f5129eaa9057efabd18e808'},
    329000: {'ledger_hash': 'e4f5f8c330e8d2f515d2cfef92759aef7f92dd397df5869d9ffcfe2749b45c5c', 'txlist_hash': 'c002aada68aae93cd2670d04317caf7de6a7935d8f8b71d4044e359804108d00'},
    350000: {'ledger_hash': '03000561ca9871223836a214ec1200fb035b70388fbd108bb9351d891844cd9e', 'txlist_hash': '0716337ad4b354823aab46e46f316161adab4fc083f315d4b2c2e7c7b17e0a67'},
    400000: {'ledger_hash': '7a1bbf50517d098afbb3ecdc77d41f8bd35555e0937a71c2a2b1a4d072416f4e', 'txlist_hash': 'e28fbecaac4d82ed1d9a8eb2a4a43ab9b2b32c1ca8ce20ca300cc8848a690966'},
    450000: {'ledger_hash': 'ce34985ad5400195edc90a5cd50aaa07c3fb746b663aafefb4ff3bb5990fa837', 'txlist_hash': '1667c7a08471cffcccb55056a8e080d0141486b430b673bee5b7cda54ee2387c'},
    500000: {'ledger_hash': '703632461af220490f6f9cb006a4741ed07d54dd8d5f0da81297308934745819', 'txlist_hash': '5f32a0d9c49c7788ce0f154c72e9e227c42f7d1ab8a2ff5031701fd46c15eec5'}
}

class ConsensusError(Exception):
    pass

def consensus_hash(db, field, previous_consensus_hash, content):
    cursor = db.cursor()
    block_index = util.CURRENT_BLOCK_INDEX

    # Initialise previous hash on first block.
    if block_index == config.BLOCK_FIRST:
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
        host = 'https://counterpartyxcp.github.io/counterparty-lib/counterpartylib/protocol_changes.json'
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
