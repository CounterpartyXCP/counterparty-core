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
class UnpackException(Exception):
    pass

class BitcoindError (Exception):
    pass
class BitcoindRPCError (BitcoindError):
    pass

class DatabaseError (Exception):
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

class MessageError (Exception):
    pass
class BurnError (MessageError):
    pass
class SendError (MessageError):
    pass
class OrderError (MessageError):
    pass
class BroadcastError (MessageError):
    pass
class BetError (MessageError):
    pass
class IssuanceError (MessageError):
    pass
class DividendError (MessageError):
    pass
class BTCPayError (MessageError):
    pass
class CancelError (MessageError):
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
