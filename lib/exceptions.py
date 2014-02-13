#! /usr/bin/python3

class ConfigurationError (Exception):
    pass
class DatabaseError (Exception):
    pass
class VersionError (Exception):
    pass
class ClientVersionError (VersionError):
    pass
class DatabaseVersionError (VersionError):
    pass

class TransactionError(Exception):
    pass
class InputError(Exception):
    pass

class BitcoindError (Exception):
    pass
class BitcoindRPCError (BitcoindError):
    pass
class ZeroMQError (Exception):
    pass

class FeeError (Exception):
    pass
class BalanceError (Exception):
    pass
class QuantityError(Exception):
    pass

class InvalidAddressError (Exception):
    pass
class VersionByteError (InvalidAddressError):
    pass
class Base58Error (InvalidAddressError):
    pass
class InvalidBase58Error (Base58Error):
    pass
class Base58ChecksumError (Base58Error):
    pass

class AssetError (Exception):
    pass
class AssetNameError (AssetError):
    pass
class AssetIDError (AssetError):
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
class CallbackError (MessageError):
    pass

# vim: tabstop=8 expandtab shiftwidth=4 softtabstop=4
