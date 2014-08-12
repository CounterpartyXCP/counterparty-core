import sys
import os

"""Variables prefixed with `DEFAULT` should be able to be overridden by
configuration file and command‐line arguments."""

UNIT = 100000000        # The same across assets.


# Versions
VERSION_MAJOR = 9
VERSION_MINOR = 39
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
BTC = 'DOGE'
XCP = 'XDP'

BTC_NAME = 'Dogecoin'
BTC_CLIENT = 'dogecoind'
XCP_NAME = 'Dogeparty'
XCP_CLIENT = 'dogepartyd'

DEFAULT_RPC_PORT_TESTNET = 15000
DEFAULT_RPC_PORT = 5000

DEFAULT_BACKEND_RPC_PORT_TESTNET = 44555
DEFAULT_BACKEND_RPC_PORT = 22555

UNSPENDABLE_TESTNET = 'ndogepartyxxxxxxxxxxxxxxxxxxwpsZCH'
UNSPENDABLE_MAINNET = 'DDogepartyxxxxxxxxxxxxxxxxxxw1dfzr'

ADDRESSVERSION_TESTNET = b'q'
# PRIVATEKEY_VERSION_TESTNET =
ADDRESSVERSION_MAINNET = b'\x1e'
# PRIVATEKEY_VERSION_MAINNET =
MAGIC_BYTES_TESTNET = b'\xfa\xbf\xb5\xda'   # For bip-0010
MAGIC_BYTES_MAINNET = b'\xf9\xbe\xb4\xd9'   # For bip-0010

WIF_PREFIX_TESTNET = b'\xf1'
WIF_PREFIX_MAINNET = b'\x9e'

BLOCK_FIRST_TESTNET_TESTCOIN = 124678
BURN_START_TESTNET_TESTCOIN = 124678
BURN_END_TESTNET_TESTCOIN = 2500000     # Fifty years, at ten minutes per block.

BLOCK_FIRST_TESTNET = BLOCK_FIRST_TESTNET_TESTCOIN
BURN_START_TESTNET =  BURN_START_TESTNET_TESTCOIN
BURN_END_TESTNET = 2500000              # Fifty years, at ten minutes per block.

BLOCK_FIRST_MAINNET_TESTCOIN = 187971
BURN_START_MAINNET_TESTCOIN = 187971
BURN_END_MAINNET_TESTCOIN = 2500000     # A long time.

BLOCK_FIRST_MAINNET = BLOCK_FIRST_MAINNET_TESTCOIN
BURN_START_MAINNET = BURN_START_MAINNET_TESTCOIN
BURN_END_MAINNET = 2500000

MAX_BURN_BY_ADDRESS = 5000000 * UNIT 	# 5M DOGE.
BURN_MULTIPLIER = .001 				        # from 1.5 to 1 XDP per 1000 DOGE.

# Protocol defaults
# NOTE: If the DUST_SIZE constants are changed, they MUST also be changed in counterblockd/lib/config.py as well
DEFAULT_REGULAR_DUST_SIZE = UNIT 		  # 1 DOGE; there is not dust limit in Dogecoin, but every txout < 1 DOGE, cost 1 DOGE in fee
DEFAULT_MULTISIG_DUST_SIZE = UNIT * 2 # 2 DOGE.
DEFAULT_OP_RETURN_VALUE = 0 			    # 0 DOGE.
DEFAULT_FEE_PER_KB = UNIT             # 1 DOGE.


# UI defaults
DEFAULT_FEE_FRACTION_REQUIRED = .009   # 0.90%
DEFAULT_FEE_FRACTION_PROVIDED = .01    # 1.00%
