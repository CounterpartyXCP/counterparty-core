class InvalidSignature(Exception):

    def __init__(self, rawtx):
        msg = "Invalid or incomplete signature for {0}"
        super(InvalidSignature, self).__init__(msg.format(rawtx))


class AssetMissmatch(Exception):

    def __init__(self, expected, found):
        msg = "Incorrect asset: expected {0} != {1} found!"
        super(AssetMissmatch, self).__init__(msg.format(expected, found))


class SourceMissmatch(Exception):

    def __init__(self, expected, found):
        msg = "Incorrect source address: expected {0} != {1} found!"
        super(SourceMissmatch, self).__init__(msg.format(expected, found))


class DestinationMissmatch(Exception):

    def __init__(self, expected, found):
        msg = "Incorrect destination address: expected {0} != {1} found!"
        super(DestinationMissmatch, self).__init__(msg.format(expected, found))


class AssetNotSupported(Exception):

    def __init__(self, asset):
        msg = "Asset {0} is not supported yet!"
        super(AssetNotSupported, self).__init__(msg.format(asset))


class AssetDoesNotExist(Exception):

    def __init__(self, asset):
        msg = "Asset {0} does not exist!"
        super(AssetDoesNotExist, self).__init__(msg.format(asset))


class NoRevokeSecretForCommit(Exception):

    def __init__(self, commit_script, script_revoke_secret_hash):
        msg = (
            "No revoke secret hash found!"
            " Commit script: {0}, Revoke secret hash: {1}"
        )
        super(NoRevokeSecretForCommit, self).__init__(msg.format(
            commit_script, script_revoke_secret_hash
        ))


class ChannelAlreadyUsed(Exception):

    def __init__(self, channel_address, transactions):
        msg = "Channel '{0}' already used: '{1}'"
        super(ChannelAlreadyUsed, self).__init__(msg.format(
            channel_address, transactions
        ))


class InsufficientFunds(Exception):

    def __init__(self, needed, available, address, asset):
        msg = "Needed funds '{0}', available '{1}' for {2}@{3}"
        super(InsufficientFunds, self).__init__(
            msg.format(needed, available, asset, address)
        )


class InvalidPubKey(Exception):

    def __init__(self, pubkey):
        msg = "Invalid pubkey: '{0}'"
        super(InvalidPubKey, self).__init__(msg.format(pubkey))


class InvalidHexData(Exception):

    def __init__(self, hexdata):
        msg = "Invalid hexdata: '{0}'"
        super(InvalidHexData, self).__init__(msg.format(hexdata))


class InvalidString(Exception):

    def __init__(self, x):
        msg = "Invalid string: '{0}'"
        super(InvalidString, self).__init__(msg.format(x))


class InvalidHash160(Exception):

    def __init__(self, x):
        msg = "Invalid hash160: '{0}'"
        super(InvalidHash160, self).__init__(msg.format(x))


class InvalidSequence(Exception):

    def __init__(self, x):
        msg = "Invalid sequence: '{0}'"
        super(InvalidSequence, self).__init__(msg.format(x))


class InvalidInteger(Exception):

    def __init__(self, x):
        msg = "Invalid integer: '{0}'"
        super(InvalidInteger, self).__init__(msg.format(x))


class InvalidList(Exception):

    def __init__(self, x):
        msg = "Invalid list: '{0}'"
        super(InvalidList, self).__init__(msg.format(x))


class InvalidQuantity(Exception):

    def __init__(self, x):
        msg = "Invalid quantity: '{0}'"
        super(InvalidQuantity, self).__init__(msg.format(x))


class InvalidTransferQuantity(Exception):

    def __init__(self, quantity, balance):
        msg = "Amount greater total: {0} > {1}"
        super(InvalidTransferQuantity, self).__init__(msg.format(
            quantity, balance
        ))


class InvalidUnsigned(Exception):

    def __init__(self, x):
        msg = "Invalid unsigned: '{0}'"
        super(InvalidUnsigned, self).__init__(msg.format(x))


class IncorrectPubKey(Exception):

    def __init__(self, found, expected):
        msg = "Incorrect pubkey: found '{0}' != '{1} expected!"
        super(IncorrectPubKey, self).__init__(msg.format(found, expected))


class IncorrectSpendSecretHash(Exception):

    def __init__(self, found, expected):
        msg = "Incorrect spend secret hash: found '{0}' != '{1} expected!"
        super(IncorrectSpendSecretHash, self).__init__(
            msg.format(found, expected)
        )
