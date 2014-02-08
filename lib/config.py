import sys
import os
import hashlib

UNIT = 100000000        # The same across currencies.

UNITTEST_PREFIX = b'TESTXXXX'

# Versions
VERSION = 0.4
DB_VERSION_MAJOR = 6        # Major version changes the blocks or transactions table.
DB_VERSION_MINOR = 10        # Minor version changes just the parsing.
DB_VERSION = str(DB_VERSION_MAJOR) + '.' + str(DB_VERSION_MINOR)

# Bitcoin protocol
# DUST_SIZE = 5430      # OP_RETURN
DUST_SIZE = 5430 * 2    # Multi‐sig (TODO: This is just a guess.)
MIN_FEE = 10000         # Counterparty transactions are all under 1KB in size.
DATA_VALUE = 0

# Counterparty protocol
TXTYPE_FORMAT = '>I'

ISSUANCE_FEE = 5
TWO_WEEKS = 2 * 7 * 24 * 3600
MAX_EXPIRATION = 4 * 2016   # Two months

# SQLite3
MAX_INT = 2**63 - 1
