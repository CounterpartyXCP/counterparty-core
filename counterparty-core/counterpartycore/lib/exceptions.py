#! /usr/bin/python3


class DatabaseError(Exception):
    pass


class WALFileFoundError(Exception):
    pass


class TransactionError(Exception):
    pass


class ParseTransactionError(Exception):
    pass


class AssetError(Exception):
    pass


class AssetNameError(AssetError):
    pass


class AssetIDError(AssetError):
    pass


class MessageError(Exception):
    pass


class ComposeError(MessageError):
    pass


class UnpackError(MessageError):
    pass


class ValidateError(MessageError):
    pass


class DecodeError(MessageError):
    pass


class PushDataDecodeError(DecodeError):
    pass


class BTCOnlyError(MessageError):
    def __init__(self, msg, decoded_tx=None):
        super(BTCOnlyError, self).__init__(msg)
        self.decoded_tx = decoded_tx


class BalanceError(Exception):
    pass


class EncodingError(Exception):
    pass


class OptionsError(Exception):
    pass


class UnknownTable(Exception):
    pass


class UnknownField(Exception):
    pass


class InvalidVersion(Exception):
    pass


class ComposeTransactionError(Exception):
    pass


class InvalidArgument(Exception):
    pass


class MempoolError(Exception):
    pass


class BlockNotFoundError(Exception):
    pass


class BitcoindRPCError(Exception):
    pass


class UnknownPubKeyError(Exception):
    pass


class JSONRPCInvalidRequest(Exception):
    pass


class BitcoindZMQError(Exception):
    pass


class APIWatcherError(Exception):
    pass


class SerializationError(Exception):
    pass


class NoEventToParse(Exception):
    pass


class InvalidUTXOError(Exception):
    pass


class NoDispenserError(Exception):
    pass
