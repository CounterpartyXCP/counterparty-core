#! /usr/bin/python3

class DatabaseError (Exception):
    pass

class TransactionError(Exception):
    pass

class BitcoindError (Exception):
    pass

class AddressError (Exception):
    pass

class AssetError (Exception):
    pass



class MessageError (Exception):
    pass
class UnpackError (MessageError):
    pass
class ValidateError(MessageError):
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
