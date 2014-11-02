import sys
import os

"""Variables prefixed with `DEFAULT` should be able to be overridden by
configuration file and command‐line arguments."""

UNIT = 100000000        # The same across assets.


# Versions
VERSION_MAJOR = 9
VERSION_MINOR = 45
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

BLOCK_FIRST_TESTNET_TESTCOIN = 154908
BURN_START_TESTNET_TESTCOIN = 154908
BURN_END_TESTNET_TESTCOIN = 4017708     # Fifty years, at ten minutes per block.

BLOCK_FIRST_TESTNET = 154908
BURN_START_TESTNET = 154908
BURN_END_TESTNET = 4017708              # Fifty years, at ten minutes per block.

BLOCK_FIRST_MAINNET_TESTCOIN = 278270
BURN_START_MAINNET_TESTCOIN = 278310
BURN_END_MAINNET_TESTCOIN = 2500000     # A long time.

BLOCK_FIRST_MAINNET = 278270
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
CONSENSUS_HASH_VERSION = 2

# (ledger_hash, txlist_hash)
CHECKPOINTS_MAINNET = {
    BLOCK_FIRST_MAINNET: ('766ff0a9039521e3628a79fa669477ade241fc4c0ae541c3eae97f34b547b0b7', '766ff0a9039521e3628a79fa669477ade241fc4c0ae541c3eae97f34b547b0b7'),
    280000: ('265719e2770d5a6994f6fe49839069183cd842ee14f56c2b870e56641e8a8725', 'a59b33b4633649db4f14586af47e258ed9b8884dbb7aa308fb1f49a653ee60f4'),
    290000: ('4612ed7034474b4ff1727eb0e216d533ebe7ac755fb015e0f9a170c063f3e84c', 'c15423c849fd360d38cbd6c6c3ea37a07fece723da92353f3056facc2676d9e7'),
    300000: ('9a3dd4949780404d61e5ca1929f94a43f08eb0fa19ccb4b5d6a61cafd7943199', 'efa02dbdcc4158a598e3b476ece5ba9cc8d26f3abc8ac3777ac6dde0f0afc7e6'),
    310000: ('45e43d5cc77ea01129df01d7f55b0c89b2d4e18cd3d626fd92f30bfb37a85f4d', '83cdcf75833d828ded09979b601fde87e2fdb0f5eb1cc6ab5d2042b7ec85f90e'),
    320000: ('91c1d33626669e8098bc762b1a9e3f616884e4d1cadda4881062c92b0d3d3e98', '761793042d8e7c80e14a16c15bb9d40e237c468a87c207a59730b616bdfde7d4')
}

CHECKPOINTS_TESTNET = {
    BLOCK_FIRST_TESTNET: ('766ff0a9039521e3628a79fa669477ade241fc4c0ae541c3eae97f34b547b0b7', '766ff0a9039521e3628a79fa669477ade241fc4c0ae541c3eae97f34b547b0b7'),
    160000: ('3011bf438695867599a69d5abc8194e3c72cbe338cfb5ad76c31213b511e3569', '9194e3faa4539577f43628744c3c60a5b3047d93b6e577d3a4bec86953eb1600'),
    180000: ('bb2e422604ee07cca333e21b7a26b5a44962bde0617d19e4a2a363a6c6767b18', '6586b880681a94209daf5ca8d9d8e650e733343424bd158547b596beecfc9e34'),
    200000: ('9eda3189c86e592f68f44b3bfdb7ee48c163318178b50794cfa1b01907f92aa9', 'd17d8af90b8c260a755d485eebc12ce073b6da55a6c5517c87c43c588899e283'),
    250000: ('41f54d6681ddb132c98911539ebac708443fd9d5183b56cb879ca577f4f4fc3d', '8c0abec60490ddb955f2b788457af94337e579662d83913f8daf87d6d127e16a'),
    300000: ('0d060be6ecbd59ea9ba5c5619a82359e3d5fac0ccf4194611cbceedbd24b0aa4', 'a2c04b4ab74c2e1944418d18716d2fde61223e29eb2f08e4d12a3ce21586322c')
}

FIRST_MULTISIG_BLOCK_TESTNET = 303000
