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
    """`{card_id: (copies drawn, highest serial)}` for the fairbooster `asset`."""
    cursor = db.cursor()
    cursor.execute(
        """
        SELECT card_id, COUNT(*) AS drawn, MAX(serial) AS last_serial
        FROM fairbooster_draws
        WHERE fairbooster = ?
        GROUP BY card_id
        """,
        (database.asset_index_from_name(db, asset),),
    )
    return {row["card_id"]: (row["drawn"], row["last_serial"]) for row in cursor.fetchall()}


def get_pending_card_count(db, asset, block_index):
    """The number of cards bought from the fairbooster `asset` in `block_index`:
    they are drawn in the next block, so they are not in `fairbooster_draws`
    yet."""
    cursor = db.cursor()
    cursor.execute(
        """
        SELECT COALESCE(SUM(card_count), 0) AS card_count
        FROM fairbooster_purchases
        WHERE fairbooster = ? AND block_index = ? AND status = ?
        """,
        (database.asset_index_from_name(db, asset), block_index, "valid"),
    )
    return cursor.fetchone()["card_count"]


def get_purchases_to_draw(db, block_index):
    """The valid purchases of `block_index`, in transaction order."""
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
