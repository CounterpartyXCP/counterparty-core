import sys
import os
import hashlib

UNIT = 100000000        # The same across currencies.

UNITTEST_PREFIX = b'TESTXXXX'

# Versions
CLIENT_VERSION_MAJOR = 6
CLIENT_VERSION_MINOR = 4
CLIENT_VERSION = float(str(CLIENT_VERSION_MAJOR) + '.' + str(CLIENT_VERSION_MINOR))
DB_VERSION_MAJOR = 9        # Major version changes the blocks or transactions table.
DB_VERSION_MINOR = 5        # Minor version changes just the parsing.
DB_VERSION = float(str(DB_VERSION_MAJOR) + '.' + str(DB_VERSION_MINOR))

# Bitcoin protocol
MULTISIG = True
REGULAR_DUST_SIZE = 5430        # TODO: This is just a guess. I got it down to 5530 satoshis.
OP_RETURN_VALUE = 0
MULTISIG_DUST_SIZE = 5430 * 2   # TODO: This is just a guess. I did it down to 1.4x. (Used for regular outputs in multi‐sig transactions, too.)
MIN_FEE = 10000                 # Counterparty transactions are all under 1KB in size.

# Counterparty protocol
TXTYPE_FORMAT = '>I'

ISSUANCE_FEE = 5
TWO_WEEKS = 2 * 7 * 24 * 3600
MAX_EXPIRATION = 4 * 2016   # Two months

# SQLite3
MAX_INT = 2**63 - 1

# Order fees
FEE_FRACTION_REQUIRED_DEFAULT = .0095  # 0.95%
FEE_FRACTION_PROVIDED_DEFAULT = .01    # 1.00%
