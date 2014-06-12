import sys
import os

UNIT = 100000000        # The same across currencies.

UNITTEST_PREFIX = b'TESTXXXX'

# Versions
VERSION_MAJOR = 9
VERSION_MINOR = 24
VERSION_REVISION = 2
VERSION_STRING = str(VERSION_MAJOR) + '.' + str(VERSION_MINOR) + '.' + str(VERSION_REVISION)

# Bitcoin protocol
# NOTE: If the DUST_SIZE constants are changed, they MUST also be changed in counterblockd/lib/config.py as well
MULTISIG = True
REGULAR_DUST_SIZE = 5430        # TODO: This is just a guess. I got it down to 5530 satoshis.
MULTISIG_DUST_SIZE = 5430 * 2   # TODO: This is just a guess. I did it down to 1.4x. (Used for regular outputs in multi‐sig transactions, too.)
OP_RETURN_VALUE = 0
FEE_PER_KB = 20000              # Bitcoin Core default is 10000.

# Counterparty protocol
TXTYPE_FORMAT = '>I'

TWO_WEEKS = 2 * 7 * 24 * 3600
MAX_EXPIRATION = 4 * 2016   # Two months

# SQLite3
MAX_INT = 2**63 - 1

# Order fees (UI)
FEE_FRACTION_REQUIRED_DEFAULT = .009   # 0.90%
FEE_FRACTION_PROVIDED_DEFAULT = .01    # 1.00%
