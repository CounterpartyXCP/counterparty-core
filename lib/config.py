import sys
import os

"""Variables prefixed with `DEFAULT` should be able to be overridden by
configuration file and command‐line arguments."""

UNIT = 100000000        # The same across assets.


# Versions
VERSION_MAJOR = 9
VERSION_MINOR = 47
VERSION_REVISION = 0
VERSION_STRING = str(VERSION_MAJOR) + '.' + str(VERSION_MINOR) + '.' + str(VERSION_REVISION)


# Counterparty protocol
TXTYPE_FORMAT = '>I'

TWO_WEEKS = 2 * 7 * 24 * 3600
MAX_EXPIRATION = 4 * 2016   # Two months

MEMPOOL_BLOCK_HASH = 'mempool'
MEMPOOL_BLOCK_INDEX = 9999999


# SQLite3
MAX_INT = 2**63 - 1


# Bitcoin Core
OP_RETURN_MAX_SIZE = 40 # bytes


# Currency agnosticism
BTC = 'BTC'
XCP = 'XCP'

BTC_NAME = 'Bitcoin'
BTC_CLIENT = 'bitcoind'
XCP_NAME = 'Counterparty'
XCP_CLIENT = 'counterpartyd'

DEFAULT_RPC_PORT_TESTNET = 14000
DEFAULT_RPC_PORT = 4000

DEFAULT_BACKEND_RPC_PORT_TESTNET = 18332
DEFAULT_BACKEND_RPC_PORT = 8332

UNSPENDABLE_TESTNET = 'mvCounterpartyXXXXXXXXXXXXXXW24Hef'
UNSPENDABLE_MAINNET = '1CounterpartyXXXXXXXXXXXXXXXUWLpVr'

ADDRESSVERSION_TESTNET = b'\x6f'
PRIVATEKEY_VERSION_TESTNET = b'\xef'
ADDRESSVERSION_MAINNET = b'\x00'
PRIVATEKEY_VERSION_MAINNET = b'\x80'
MAGIC_BYTES_TESTNET = b'\xfa\xbf\xb5\xda'   # For bip-0010
MAGIC_BYTES_MAINNET = b'\xf9\xbe\xb4\xd9'   # For bip-0010

BLOCK_FIRST_TESTNET_TESTCOIN = 281000
BURN_START_TESTNET_TESTCOIN = 281000
BURN_END_TESTNET_TESTCOIN = 4017708     # Fifty years, at ten minutes per block.

BLOCK_FIRST_TESTNET = 281000
BLOCK_FIRST_TESTNET_HASH = '000000009b9b5b55cad5308c984478100342055668cd54a5bace15d960122b94'
BURN_START_TESTNET = 281000
BURN_END_TESTNET = 4017708              # Fifty years, at ten minutes per block.

BLOCK_FIRST_MAINNET_TESTCOIN = 278270
BURN_START_MAINNET_TESTCOIN = 278310
BURN_END_MAINNET_TESTCOIN = 2500000     # A long time.

BLOCK_FIRST_MAINNET = 278270
BLOCK_FIRST_MAINNET_HASH = '00000000000000017bac9a8e85660ad348050c789922d5f8fe544d473368be1a'
BURN_START_MAINNET = 278310
BURN_END_MAINNET = 283810


# Protocol defaults
# NOTE: If the DUST_SIZE constants are changed, they MUST also be changed in counterblockd/lib/config.py as well
    # TODO: This should be updated, given their new configurability.
# TODO: The dust values should be lowered by 90%, once transactions with smaller outputs start confirming faster: <https://github.com/mastercoin-MSC/spec/issues/192>
DEFAULT_REGULAR_DUST_SIZE = 5430         # TODO: This is just a guess. I got it down to 5530 satoshis.
DEFAULT_MULTISIG_DUST_SIZE = 7800        # <https://bitcointalk.org/index.php?topic=528023.msg7469941#msg7469941>
DEFAULT_OP_RETURN_VALUE = 0
DEFAULT_FEE_PER_KB = 10000                # Bitcoin Core default is 10000.  # TODO: Lower 10x later, too.


# UI defaults
DEFAULT_FEE_FRACTION_REQUIRED = .009   # 0.90%
DEFAULT_FEE_FRACTION_PROVIDED = .01    # 1.00%


# Custom exit codes
EXITCODE_UPDATE_REQUIRED = 5

CONSENSUS_HASH_SEED = 'We can only see a short distance ahead, but we can see plenty there that needs to be done.'

CONSENSUS_HASH_VERSION_MAINNET = 2
CHECKPOINTS_MAINNET = {
    BLOCK_FIRST_MAINNET: {'ledger_hash': '766ff0a9039521e3628a79fa669477ade241fc4c0ae541c3eae97f34b547b0b7', 'txlist_hash': '766ff0a9039521e3628a79fa669477ade241fc4c0ae541c3eae97f34b547b0b7'},
    280000: {'ledger_hash': '265719e2770d5a6994f6fe49839069183cd842ee14f56c2b870e56641e8a8725', 'txlist_hash': 'a59b33b4633649db4f14586af47e258ed9b8884dbb7aa308fb1f49a653ee60f4'},
    290000: {'ledger_hash': '4612ed7034474b4ff1727eb0e216d533ebe7ac755fb015e0f9a170c063f3e84c', 'txlist_hash': 'c15423c849fd360d38cbd6c6c3ea37a07fece723da92353f3056facc2676d9e7'},
    300000: {'ledger_hash': '9a3dd4949780404d61e5ca1929f94a43f08eb0fa19ccb4b5d6a61cafd7943199', 'txlist_hash': 'efa02dbdcc4158a598e3b476ece5ba9cc8d26f3abc8ac3777ac6dde0f0afc7e6'},
    310000: {'ledger_hash': '45e43d5cc77ea01129df01d7f55b0c89b2d4e18cd3d626fd92f30bfb37a85f4d', 'txlist_hash': '83cdcf75833d828ded09979b601fde87e2fdb0f5eb1cc6ab5d2042b7ec85f90e'},
    320000: {'ledger_hash': '91c1d33626669e8098bc762b1a9e3f616884e4d1cadda4881062c92b0d3d3e98', 'txlist_hash': '761793042d8e7c80e14a16c15bb9d40e237c468a87c207a59730b616bdfde7d4'},
    330000: {'ledger_hash': 'dd56aa97e5ca15841407f383ce1d7814536a594d7cfffcb4cf60bee8b362065a', 'txlist_hash': '3c45b4377a99e020550a198daa45c378c488a72ba199b53deb90b320d55a897b'}
}

CONSENSUS_HASH_VERSION_TESTNET = 3
CHECKPOINTS_TESTNET = {
    BLOCK_FIRST_TESTNET: {'ledger_hash': 'df480d3a2c138df0cd631670ed9b7c874079b2c0cb077645871769ad6718ad19', 'txlist_hash': 'df480d3a2c138df0cd631670ed9b7c874079b2c0cb077645871769ad6718ad19'},
    160000: {'ledger_hash': '08a11ed6d211992f6e8788e1ce4a1c8bdf3691ca72c77c3fde8c4362b7b650ea', 'txlist_hash': 'f631650deecda6e38582b70f0f326f1bb80e48a7b191c7fa580a0bc01640fa44'},
    180000: {'ledger_hash': '25b067067ee4730556bd3014144a15a52957ab3a03e781c2dee1d26d04f0813d', 'txlist_hash': '3842631281d672efa3ea06baab186f7a89aa5f88f89280f8d03bab2ac8bb82e4'},
    200000: {'ledger_hash': '192b46977a96150145421635e2d325a51f43f095ce4c5f7b5a91ff910f57094c', 'txlist_hash': '453c54a6d9643eced4611814cf8a8bdd97c7b8ef2f830752f47b3bddbd1e0651'},
    250000: {'ledger_hash': 'a2a3d1c118cc253f5986be076215fb0fc76277a1b8369c64db1466651d800db3', 'txlist_hash': '4e32e227d6abc46948e4d2d1bb9c9e1a6b7c7a700041c44e289072ff744f9429'},
    300000: {'ledger_hash': 'd530cbf2251016b211a36d09da8a1f68a23736d435a56add3e208d848cbb61ba', 'txlist_hash': '0dad3d3d7672af7b91390e0aa8cd169b7d63906e4b4740df40c05a52dfd079d5'}
}
