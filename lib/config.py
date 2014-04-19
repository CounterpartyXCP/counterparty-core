import sys
import os
import hashlib

UNIT = 100000000        # The same across currencies.

UNITTEST_PREFIX = b'TESTXXXX'

# Versions
VERSION_MAJOR = 9
VERSION_MINOR = 16
VERSION_STRING = str(VERSION_MAJOR) + '.' + str(VERSION_MINOR)

# Bitcoin protocol
MULTISIG = True
REGULAR_DUST_SIZE = 5430        # TODO: This is just a guess. I got it down to 5530 satoshis.
OP_RETURN_VALUE = 0
MULTISIG_DUST_SIZE = 5430 * 2   # TODO: This is just a guess. I did it down to 1.4x. (Used for regular outputs in multi‐sig transactions, too.)
FEE_PER_KB = 20000              # Bitcoin Core default is 10000.

# Counterparty protocol
TXTYPE_FORMAT = '>I'

TWO_WEEKS = 2 * 7 * 24 * 3600
MAX_EXPIRATION = 4 * 2016   # Two months

# SQLite3
MAX_INT = 2**63 - 1

# Order fees
FEE_FRACTION_REQUIRED_DEFAULT = .009   # 0.90%
FEE_FRACTION_PROVIDED_DEFAULT = .01    # 1.00%
