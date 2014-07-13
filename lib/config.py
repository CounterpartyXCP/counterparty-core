import sys
import os

"""Variables prefixed with `DEFAULT` should be able to be overridden by
configuration file and command‐line arguments."""

UNIT = 100000000        # The same across assets.


# Versions
VERSION_MAJOR = 9
VERSION_MINOR = 31
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
# PRIVATEKEY_VERSION_TESTNET =
ADDRESSVERSION_MAINNET = b'\x00'
# PRIVATEKEY_VERSION_MAINNET =
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
