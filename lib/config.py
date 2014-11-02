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

CHECKPOINTS_MAINNET = {
    BLOCK_FIRST_MAINNET: {'ledger_hash': '538b3c4512b8f85d7f5d1d44bcad36a86dcf7d735610dcd17ff906ff74c914ab', 'txlist_hash': '538b3c4512b8f85d7f5d1d44bcad36a86dcf7d735610dcd17ff906ff74c914ab'},
    280000: {'ledger_hash': '44171ad53b349a46ca167580f59b5e65f74597877f2f9e61aba1797811e5954e', 'txlist_hash': '237f1c6720441cd6d69317e7d76a1118685022089012625e8525dcf550895cdf'},
    290000: {'ledger_hash': 'c987289fc47ef649c6fb5e4e45647c7502f730ef2ef564e3dd44fef696690df3', 'txlist_hash': '2efd2b8e20195fe449a37e5ec6d29d64cd0e5ac3753940297c3e10a836019a2d'},
    300000: {'ledger_hash': '1d94241b77dc25f197f6cd7aff8a18e8869f070c4a9180ded2197cd8f309c69a', 'txlist_hash': 'cfdbf17284004236716a63aa1c004bce49a37a981b7a02f86974b38b6c51371c'},
    310000: {'ledger_hash': '6d254126f9ba47eb4093ac612e0246ada5cfeba65d40091ce971f692da4d7cea', 'txlist_hash': 'd0a99452028ce6ab7f2b9cde8ddc9e29802c186818ff437fdf7954300c8857d1'},
    320000: {'ledger_hash': 'eca94d1e86a5a1c027b04b958fbc0d79f4d3f38bbafb78f5f53e0041e3b477cd', 'txlist_hash': 'cae07bc13b10de2611d9cdd444e398f6868a0536c8d34bb3adbd7ee43eb84031'}
}

CHECKPOINTS_TESTNET = {
    BLOCK_FIRST_TESTNET: {'ledger_hash': '538b3c4512b8f85d7f5d1d44bcad36a86dcf7d735610dcd17ff906ff74c914ab', 'txlist_hash': '538b3c4512b8f85d7f5d1d44bcad36a86dcf7d735610dcd17ff906ff74c914ab'},
    160000: {'ledger_hash': 'a9e226d9034bbf890e45b58bdf806a812b74efbe5e4645458780d3b12994e1b2', 'txlist_hash': '7d6cbcfc9a910693e0effb4c3295bce26a6aa35fa95433bf28d4752b716e1bd9'},
    180000: {'ledger_hash': 'e45dd29fca891633a4ff3eb1a3437544bacf0100a7916e300cbaa192c26e1f3b', 'txlist_hash': '114f419b00298effbf3877fdfaf9f11e3142dc0fe9e869e1e8e0e0a427fa867a'},
    200000: {'ledger_hash': '09715be67a24cf4173d29bbc8e734f1ccb80cea5b108c672ed4398fc0dbfefe3', 'txlist_hash': 'f220a7802b00faa13af4ed87712f381e32b64685f907e2ae272e3e6287a79191'},
    250000: {'ledger_hash': '233cbfcfc2826b23027d77295efab1264762017d0bc54ea856c7d727afcb2559', 'txlist_hash': '694b3dbfab00329df34434fa376bcc87f9e670a8b015600f0384195e30cbe742'},
    300000: {'ledger_hash': '832bd9342448453f27b765c60aacb0c89b4e2779db394c49db3abf2d38df594a', 'txlist_hash': 'fd66973e15540adf84fec68d3acb4fe4c3dd529646993dc1d007972a160b18ec'}
}

FIRST_MULTISIG_BLOCK_TESTNET = 303000
