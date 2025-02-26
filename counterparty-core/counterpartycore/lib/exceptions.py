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


class BTCOnlyError(Exception):
    pass


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


class NoPriceError(Exception):
    pass


class RSFetchError(Exception):
    pass


class ElectrsError(Exception):
    pass


class BlockOutOfRange(Exception):
    pass


class InputError(Exception):
    pass


class AddressError(Exception):
    pass


class MultiSigAddressError(AddressError):
    pass


class VersionByteError(AddressError):
    pass


class Base58Error(AddressError):
    pass


class QuantityError(Exception):
    pass


class RPCError(Exception):
    pass


class APIError(Exception):
    pass


class BackendError(Exception):
    pass


class ConsensusError(Exception):
    pass


class SanityError(Exception):
    pass


class VersionError(Exception):
    def __init__(self, message, required_action, from_block_index=None):
        super(VersionError, self).__init__(message)
        self.required_action = required_action
        self.from_block_index = from_block_index


class VersionCheckError(Exception):
    pass


class VersionUpdateRequiredError(Exception):
    pass


class ConfigurationError(Exception):
    pass


class DebitError(Exception):
    pass


class CreditError(Exception):
    pass


class ServerNotReady(Exception):
    pass


class OrderError(Exception):
    pass
