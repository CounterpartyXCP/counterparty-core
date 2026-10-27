"""Ledger queries for fairboosters (see `messages/fairbooster.py`)."""

from counterpartycore.lib.ledger.events import insert_update
from counterpartycore.lib.utils import database


def get_fairbooster(db, asset):
    """The current state of the fairbooster whose asset is `asset`, or None."""
    asset_index = database.asset_index_from_name(db, asset)
    if asset_index is None:
        return None
    cursor = db.cursor()
    cursor.execute(
        """
        SELECT * FROM fairboosters
        WHERE asset = ?
        ORDER BY rowid DESC LIMIT 1
        """,
        (asset_index,),
    )
    return cursor.fetchone()


def is_fairbooster_asset(db, asset):
    return get_fairbooster(db, asset) is not None


def update_fairbooster(db, tx_hash, update_data):
    insert_update(db, "fairboosters", "tx_hash", tx_hash, update_data, "FAIRBOOSTER_UPDATE")


def get_fairbooster_cards(db, asset):
    """The cards of the fairbooster `asset`, in the order they were added."""
    cursor = db.cursor()
    cursor.execute(
        """
        SELECT * FROM fairbooster_cards
        WHERE fairbooster = ?
        ORDER BY rowid
        """,
        (database.asset_index_from_name(db, asset),),
    )
    return cursor.fetchall()


def get_drawn_cards(db, asset):
    """`{card_id: copies drawn}` for the fairbooster `asset`, read from the
    last draw of each card (its `copy_number` only grows): one index lookup
    per card, whatever the number of draws."""
    cursor = db.cursor()
    cursor.execute(
        """
        SELECT d.card_id, d.copy_number
        FROM fairbooster_cards c
        JOIN fairbooster_draws d ON d.rowid = (
            SELECT rowid FROM fairbooster_draws
            WHERE fairbooster = c.fairbooster AND card_id = c.card_id
            ORDER BY copy_number DESC LIMIT 1
        )
        WHERE c.fairbooster = ?
        """,
        (database.asset_index_from_name(db, asset),),
    )
    return {row["card_id"]: row["copy_number"] for row in cursor.fetchall()}


def get_card_supply(db, asset):
    """The number of copies of the cards of the fairbooster `asset`, None when
    one card is unlimited. `fairbooster.validate_cards` keeps the sum within
    `config.MAX_INT`."""
    cursor = db.cursor()
    cursor.execute(
        """
        SELECT MIN(max_supply) AS min_supply, SUM(max_supply) AS supply
        FROM fairbooster_cards
        WHERE fairbooster = ?
        """,
        (database.asset_index_from_name(db, asset),),
    )
    row = cursor.fetchone()
    if row["min_supply"] is None or row["min_supply"] == 0:
        return None
    return row["supply"]


def get_purchases_to_draw(db, block_index):
    """The valid purchases of `block_index`, in transaction order, with the
    card image URL each one keeps."""
    cursor = db.cursor()
    cursor.execute(
        """
        SELECT * FROM fairbooster_purchases
        WHERE block_index = ? AND status = ?
        ORDER BY tx_index
        """,
        (block_index, "valid"),
    )
    return cursor.fetchall()
