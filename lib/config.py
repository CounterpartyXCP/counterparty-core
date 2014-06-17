import sys
import os

"""Variables prefixed with `DEFAULT` should be able to be overridden by
configuration file and command‐line arguments."""

UNIT = 100000000        # The same across currencies.

# Versions
VERSION_MAJOR = 9
VERSION_MINOR = 26
VERSION_REVISION = 2
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

DEFAULT_RPC_PORT = 4000
DEFAULT_RPC_PORT_TESTNET = 14000

UNSPENDABLE_TESTNET = 'mvCounterpartyXXXXXXXXXXXXXXW24Hef'
UNSPENDABLE_MAINNET = '1CounterpartyXXXXXXXXXXXXXXXUWLpVr'

ADDRESSVERSION_TESTNET = b'\x6f'
ADDRESSVERSION_MAINNET = b'\x00'

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
DEFAULT_REGULAR_DUST_SIZE = 5430        # TODO: This is just a guess. I got it down to 5530 satoshis.
DEFAULT_MULTISIG_DUST_SIZE = 5430 * 2   # TODO: This is just a guess. I did it down to 1.4x. (Used for regular outputs in multi‐sig transactions, too.)
DEFAULT_OP_RETURN_VALUE = 0
DEFAULT_FEE_PER_KB = 20000              # Bitcoin Core default is 10000.

# UI defaults
DEFAULT_FEE_FRACTION_REQUIRED = .009   # 0.90%
DEFAULT_FEE_FRACTION_PROVIDED = .01    # 1.00%
