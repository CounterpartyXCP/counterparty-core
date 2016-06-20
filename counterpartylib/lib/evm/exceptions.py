class EVMException(Exception):
    pass


class UnknownParentException(EVMException):
    pass


class VerificationFailed(EVMException):
    pass


class InvalidTransaction(EVMException):
    pass


class UnsignedTransaction(InvalidTransaction):
    pass


class InvalidNonce(InvalidTransaction):
    pass


class InsufficientBalance(InvalidTransaction):
    pass


class InsufficientStartGas(InvalidTransaction):
    pass


class BlockGasLimitReached(InvalidTransaction):
    pass


class GasPriceTooLow(InvalidTransaction):
    pass


class ContractError(EVMException):
    pass


class SnapshotRequired(EVMException):
    pass


class SnapshotAlreadyFinished(EVMException):
    pass


class SnapshotNotFinished(EVMException):
    pass
