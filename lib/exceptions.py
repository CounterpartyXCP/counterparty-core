#! /usr/bin/python3

# Exceptions
class BitcoinConfError(Exception):
    pass
class UselessError (Exception):
    pass
class InvalidAddressError (Exception):
    pass
class BalanceError (Exception):
    pass
class IssuanceError (Exception):
    pass
class InvalidDealError (Exception):
    pass
class Base58Error (Exception):
    pass
class InvalidBase58Error (Base58Error):
    pass
class Base58ChecksumError (Base58Error):
    pass

# Warnings
class DBVersionWarning (Exception):
    pass
class BitcoindBehindWarning (Exception):
    pass

# vim: tabstop=8 expandtab shiftwidth=4 softtabstop=4
