#! /usr/bin/python3

class DatabaseError (Exception):
    pass

class TransactionError(Exception):
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
class ValidateAssetError(AssetError):
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

# vim: tabstop=8 expandtab shiftwidth=4 softtabstop=4
