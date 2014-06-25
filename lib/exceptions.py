#! /usr/bin/python3

class SanityError (Exception):
    pass

class ConfigurationError (Exception):
    pass
class DatabaseError (Exception):
    pass
class VersionError (Exception):
    pass

class TransactionError(Exception):
    pass
class InputError(Exception):
    pass

class RPCError (Exception):
    pass

class BitcoindError (Exception):
    pass
class BitcoindRPCError (BitcoindError):
    pass
class InsightError (Exception):
    pass

class AltcoinSupportError (Exception):
    pass

class FeeError (Exception):
    pass
class BalanceError (Exception):
    pass
class QuantityError(Exception):
    pass

class AddressError (Exception):
    pass
class VersionByteError (AddressError):
    pass
class Base58Error (AddressError):
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
class RpsError (MessageError):
    pass

# vim: tabstop=8 expandtab shiftwidth=4 softtabstop=4
