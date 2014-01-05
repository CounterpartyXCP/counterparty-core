#! /usr/bin/python3

class TryoutError (Exception):
    pass

class ConfigurationError (Exception):
    pass
class TXConstructionError(Exception):
    pass
class OverflowError(Exception):
    pass

class InputError(Exception):
    pass

class BitcoindError (Exception):
    pass
class DatabaseError (Exception):
    pass

class BitcoindRPCError (BitcoindError):
    pass

class DividendError (Exception):
    pass
class BroadcastError (Exception):
    pass
class FeedError (Exception):
    pass
class IssuanceError (Exception):
    pass

class UselessError (Exception):
    pass

class FeeError (Exception):
    pass
class BalanceError (Exception):
    pass
class AssetError (Exception):
    pass
class QuantityError(Exception):
    pass

class InvalidAddressError (Exception):
    pass
class VersionByteError (InvalidAddressError):
    pass

class CancelError (Exception):
    pass
class InvalidOrderMatchError (Exception):
    pass

class Base26Error (Exception):
    pass
class Base58Error (Exception):
    pass
class InvalidBase58Error (Base58Error):
    pass
class Base58ChecksumError (Base58Error):
    pass
# vim: tabstop=8 expandtab shiftwidth=4 softtabstop=4
