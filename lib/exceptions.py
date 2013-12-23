#! /usr/bin/python3

# Exceptions
class TXConstructionError(Exception):
    pass
class OverflowError(Exception):
    pass
class BitcoindRPCError (Exception):
    pass
class DividendError (Exception):
    pass
class FeedError (Exception):
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

# vim: tabstop=8 expandtab shiftwidth=4 softtabstop=4
