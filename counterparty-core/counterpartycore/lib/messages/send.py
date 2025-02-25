import logging

from counterpartycore.lib import config, exceptions
from counterpartycore.lib.messages.versions import enhancedsend, mpma, send1
from counterpartycore.lib.parser import protocol
from counterpartycore.lib.utils import helpers

ID = send1.ID

logger = logging.getLogger(config.LOGGER_NAME)


def unpack(db, message):
    return send1.unpack(db, message)


def validate(db, destination, asset, quantity):
    return send1.validate(db, destination, asset, quantity)


def compose(
    db,
    source: str,
    destination: str,
    asset: str,
    quantity: int,
    memo: str = None,
    memo_is_hex: bool = False,
    use_enhanced_send: bool = None,
    skip_validation: bool = False,
    no_dispense: bool = False,
):
    # special case - enhanced_send replaces send by default when it is enabled
    #   but it can be explicitly disabled with an API parameter
    if protocol.enabled("enhanced_sends"):
        # Another special case, if destination, asset and quantity are arrays, it's an MPMA send
        if isinstance(destination, list) and isinstance(asset, list) and isinstance(quantity, list):
            if protocol.enabled("mpma_sends"):
                if len(destination) == len(asset) and len(asset) == len(quantity):
                    # Sending memos in a MPMA message can be done by several approaches:
                    # 1. Send a list of memos, there must be one for each send and they correspond to the sends by index
                    #   - In this case memo_is_hex should be a list with the same cardinality
                    # 2. Send a dict with the message specific memos and the message wide memo (same for the hex specifier):
                    #   - Each dict should have 2 members:
                    #     + list: same as case (1). An array that specifies the memo for each send
                    #     + msg_wide: the memo for the whole message. This memo will be used for sends that don't have a memo specified. Same as in (3)
                    # 3. Send one memo (either bytes or string) and True/False in memo_is_hex. This will be interpreted as a message wide memo.
                    if len(destination) > config.MPMA_LIMIT:
                        raise exceptions.ComposeError(
                            "mpma sends have a maximum of " + str(config.MPMA_LIMIT) + " sends"
                        )

                    if isinstance(memo, list) and isinstance(memo_is_hex, list):
                        # (1) implemented here
                        if len(memo) != len(memo_is_hex):
                            raise exceptions.ComposeError(
                                "memo and memo_is_hex lists should have the same length"
                            )
                        elif len(memo) != len(destination):
                            raise exceptions.ComposeError(
                                "memo/memo_is_hex lists should have the same length as sends"
                            )

                        return mpma.compose(
                            db,
                            source,
                            helpers.flat(zip(asset, destination, quantity, memo, memo_is_hex)),
                            None,
                            None,
                            skip_validation,
                        )
                    elif isinstance(memo, dict) and isinstance(memo_is_hex, dict):
                        # (2) implemented here
                        if not (
                            "list" in memo
                            and "list" in memo_is_hex
                            and "msg_wide" in memo
                            and "msg_wide" in memo_is_hex
                        ):
                            raise exceptions.ComposeError(
                                'when specifying memo/memo_is_hex as a dict, they must contain keys "list" and "msg_wide"'
                            )
                        elif len(memo["list"]) != len(memo_is_hex["list"]):
                            raise exceptions.ComposeError(
                                "length of memo.list and memo_is_hex.list must be equal"
                            )
                        elif len(memo["list"]) != len(destination):
                            raise exceptions.ComposeError(
                                "length of memo.list/memo_is_hex.list must be equal to the amount of sends"
                            )

                        return mpma.compose(
                            db,
                            source,
                            helpers.flat(
                                zip(asset, destination, quantity, memo["list"], memo_is_hex["list"])
                            ),
                            memo["msg_wide"],
                            memo_is_hex["msg_wide"],
                            skip_validation,
                        )
                    else:
                        # (3) the default case
                        return mpma.compose(
                            db,
                            source,
                            helpers.flat(zip(asset, destination, quantity)),
                            memo,
                            memo_is_hex,
                            skip_validation,
                        )
                else:
                    raise exceptions.ComposeError(
                        "destination, asset and quantity arrays must have the same amount of elements"
                    )
            else:
                raise exceptions.ComposeError("mpma sends are not enabled")
        elif use_enhanced_send is None or use_enhanced_send == True:  # noqa: E712
            return enhancedsend.compose(
                db,
                source,
                destination,
                asset,
                quantity,
                memo,
                memo_is_hex,
                skip_validation,
                no_dispense,
            )
    elif memo is not None or use_enhanced_send == True:  # noqa: E712
        raise exceptions.ComposeError("enhanced sends are not enabled")

    return send1.compose(db, source, destination, asset, quantity, skip_validation, no_dispense)


def parse(db, tx, message):  # TODO: *args
    return send1.parse(db, tx, message)
