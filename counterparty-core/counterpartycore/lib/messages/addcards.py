# Type 92: add cards to a card fairminter, and/or lock its cards.
#
# The issuer of an open (or pending) card fairminter whose cards are not
# locked may append cards to it: they are numbered after the existing ones
# and take part in the draws resolved from the next block on. Setting
# `lock_cards` forbids any later addition, which minters can rely on (see
# `fairminter.validate_cards`).
import logging
import struct

import cbor2

from counterpartycore.lib import config, exceptions, ledger
from counterpartycore.lib.ledger.currentstate import CurrentState
from counterpartycore.lib.messages import fairminter as fairminter_mod
from counterpartycore.lib.parser import protocol

logger = logging.getLogger(config.LOGGER_NAME)

ID = 92


def validate(db, source, asset, cards=None, lock_cards=False, block_index=None):
    problems = []
    if not protocol.enabled("fairminter_cards", block_index=block_index):
        return ["addcards is not yet enabled"]
    if not isinstance(lock_cards, bool):
        problems.append("`lock_cards` must be a boolean.")
    if cards is None:
        cards = []
    if not isinstance(cards, (list, tuple)):
        return ["cards must be a list"]
    if len(cards) == 0 and not lock_cards:
        return ["nothing to do: no cards to add and lock_cards is false"]

    fairminter = ledger.issuances.get_fairminter_by_asset(db, asset)
    if not fairminter:
        return [f"fairminter not found for asset: `{asset}`"]
    if fairminter["source"] != source:
        problems.append(f"fairminter of `{asset}` is not owned by `{source}`")
    if fairminter["status"] not in ("open", "pending"):
        problems.append(f"fairminter is closed for asset: `{asset}`")
    existing_cards = ledger.issuances.get_fairminter_cards(db, fairminter)
    if not existing_cards:
        return problems + [f"fairminter of `{asset}` has no cards"]
    if fairminter["lock_cards"]:
        problems.append(f"cards of fairminter of `{asset}` are locked")
    if problems:
        return problems

    if cards:
        start_index = len(existing_cards) + 1
        existing_names = [card["asset_longname"].rsplit(".", 1)[1] for card in existing_cards]
        problems += fairminter_mod.validate_card_entries(cards, start_index, existing_names)
        if problems:
            return problems
        asset_name = fairminter["asset_longname"] or fairminter["asset"]
        card_problems, _remaining, _all_capped = fairminter_mod.validate_card_assets(
            db, source, asset_name, cards, start_index, block_index=block_index
        )
        problems += card_problems
    return problems


def compose(
    db,
    source: str,
    asset: str,
    cards: list = None,
    lock_cards: bool = False,
    skip_validation: bool = False,
):
    resolved_asset = ledger.issuances.resolve_subasset_longname(db, asset)
    problems = validate(
        db,
        source,
        resolved_asset,
        cards,
        lock_cards,
        block_index=CurrentState().current_block_index(),
    )
    if len(problems) > 0 and not skip_validation:
        raise exceptions.ComposeError(problems)

    data = struct.pack(config.SHORT_TXTYPE_FORMAT, ID)
    asset_id = ledger.issuances.generate_asset_id(resolved_asset)
    data += cbor2.dumps(
        [
            asset_id,
            fairminter_mod.pack_cards(cards or []),
            bool(lock_cards),
        ]
    )
    return (source, [], data)


def unpack(message, return_dict=False):
    try:
        asset_id, cards, lock_cards = cbor2.loads(message)
        asset = ledger.issuances.generate_asset_name(asset_id)
        lock_cards = bool(int(lock_cards))
    except Exception as e:  # pylint: disable=broad-exception-caught
        raise exceptions.UnpackError("could not unpack addcards") from e
    if return_dict:
        return {"asset": asset, "cards": cards, "lock_cards": lock_cards}
    return (asset, cards, lock_cards)


def parse(db, tx, message):
    try:
        asset, cards, lock_cards = unpack(message)
        problems = validate(
            db, tx["source"], asset, cards, lock_cards, block_index=tx["block_index"]
        )
    except exceptions.UnpackError as e:
        asset, cards, lock_cards = "", [], False
        problems = [str(e)]

    ledger.blocks.set_transaction_status(db, tx["tx_index"], not problems)
    if problems:
        logger.info("Addcards %s is invalid: %s", tx["tx_hash"], "; ".join(problems))
        return

    fairminter = ledger.issuances.get_fairminter_by_asset(db, asset)
    if cards:
        existing_cards = ledger.issuances.get_fairminter_cards(db, fairminter)
        fairminter_mod.open_fairminter_cards(
            db,
            tx,
            fairminter["tx_hash"],
            fairminter["asset_longname"] or fairminter["asset"],
            cards,
            start_index=len(existing_cards) + 1,
        )
    if lock_cards:
        ledger.issuances.update_fairminter(db, fairminter["tx_hash"], {"lock_cards": True})
        logger.info("Cards of fairminter %s locked by %s.", fairminter["tx_hash"], tx["source"])
