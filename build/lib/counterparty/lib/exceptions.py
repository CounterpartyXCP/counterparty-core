#! /usr/bin/python3

class DatabaseError (Exception):
    pass

class TransactionError(Exception):
    pass

class VersionByteError (Exception):
    pass

class Base58Error (Exception):
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
class ComposeError (MessageError):
    pass
class UnpackError (MessageError):
    pass
class ValidateError(MessageError):
    pass
class DecodeError(MessageError):
    pass
class BTCOnlyError(MessageError):
    pass

class BalanceError (Exception):
    pass

# vim: tabstop=8 expandtab shiftwidth=4 softtabstop=4
