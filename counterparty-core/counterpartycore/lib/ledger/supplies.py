from counterpartycore.lib import config
from counterpartycore.lib.ledger.caches import AssetCache
from counterpartycore.lib.parser import protocol


# Ugly way to get holders but we want to preserve the order with the old query
# to not break checkpoints
def _get_holders(cursor, id_fields, hold_fields_1, exclude_empty_holders=False):
    save_records = {}
    for record in cursor:
        record_id = " ".join([str(record[field]) for field in id_fields])
        if id not in save_records:
            save_records[record_id] = record
            continue
        if save_records[record_id]["rowid"] < record["rowid"]:
            save_records[record_id] = record
            continue
    all_holders = []
    for holder in save_records.values():
        if holder[hold_fields_1["address_quantity"]] > 0 or (
            exclude_empty_holders == False and holder[hold_fields_1["address_quantity"]] == 0  # noqa: E712
        ):
            all_holders.append(
                {
                    "address": holder[hold_fields_1["address"]],
                    "address_quantity": holder[hold_fields_1["address_quantity"]],
                    "escrow": holder[hold_fields_1["escrow"]]
                    if "escrow" in hold_fields_1
                    else None,
                }
            )
    return all_holders


def holders(db, asset, exclude_empty_holders=False):
    """Return holders of the asset."""
    all_holders = []
    cursor = db.cursor()

    # Balances

    query = """
        SELECT *, rowid
        FROM balances
        WHERE asset = ? AND address IS NOT NULL
    """
    bindings = (asset,)
    cursor.execute(query, bindings)
    all_holders += _get_holders(
        cursor,
        ["asset", "address"],
        {"address": "address", "address_quantity": "quantity"},
        exclude_empty_holders=exclude_empty_holders,
    )

    query = """
        SELECT *, rowid
        FROM balances
        WHERE asset = ? AND utxo IS NOT NULL
        ORDER BY utxo
    """

    bindings = (asset,)
    cursor.execute(query, bindings)
    all_holders += _get_holders(
        cursor,
        ["asset", "utxo"],
        {"address": "utxo", "address_quantity": "quantity"},
        exclude_empty_holders=exclude_empty_holders,
    )

    # Funds escrowed in orders. (Protocol change.)
    query = """
        SELECT * FROM (
            SELECT *, MAX(rowid)
            FROM orders
            WHERE give_asset = ?
            GROUP BY tx_hash
        ) WHERE status = ?
        ORDER BY tx_index
    """
    bindings = (asset, "open")
    cursor.execute(query, bindings)
    all_holders += _get_holders(
        cursor,
        ["tx_hash"],
        {"address": "source", "address_quantity": "give_remaining", "escrow": "tx_hash"},
        # exclude_empty_holders=exclude_empty_holders,
    )

    # Funds escrowed in pending order matches. (Protocol change.)
    query = """
        SELECT * FROM (
            SELECT *, MAX(rowid)
            FROM order_matches
            WHERE forward_asset = ?
            GROUP BY id
        ) WHERE status = ?
    """
    bindings = (asset, "pending")
    cursor.execute(query, bindings)
    all_holders += _get_holders(
        cursor,
        ["id"],
        {"address": "tx0_address", "address_quantity": "forward_quantity", "escrow": "id"},
        # exclude_empty_holders=exclude_empty_holders,
    )

    query = """
        SELECT * FROM (
            SELECT *, MAX(rowid) AS rowid
            FROM order_matches
            WHERE backward_asset = ?
        ) WHERE status = ?
        ORDER BY rowid
    """
    bindings = (asset, "pending")
    cursor.execute(query, bindings)
    all_holders += _get_holders(
        cursor,
        ["id"],
        {"address": "tx1_address", "address_quantity": "backward_quantity", "escrow": "id"},
        # exclude_empty_holders=exclude_empty_holders,
    )

    # Bets and RPS (and bet/rps matches) only escrow XCP.
    if asset == config.XCP:
        query = """
            SELECT * FROM (
                SELECT *, MAX(rowid)
                FROM bets
                GROUP BY tx_hash
            ) WHERE status = ?
            ORDER BY tx_index
        """
        bindings = ("open",)
        cursor.execute(query, bindings)
        all_holders += _get_holders(
            cursor,
            ["tx_hash"],
            {"address": "source", "address_quantity": "wager_remaining", "escrow": "tx_hash"},
            # exclude_empty_holders=exclude_empty_holders,
        )

        query = """
            SELECT * FROM (
                SELECT *, MAX(rowid)
                FROM bet_matches
                GROUP BY id
            ) WHERE status = ?
        """
        bindings = ("pending",)
        cursor.execute(query, bindings)
        all_holders += _get_holders(
            cursor,
            ["id"],
            {"address": "tx0_address", "address_quantity": "forward_quantity", "escrow": "id"},
            {"address": "tx1_address", "address_quantity": "backward_quantity", "escrow": "id"},
            # exclude_empty_holders=exclude_empty_holders,
        )

        query = """
            SELECT * FROM (
                SELECT *, MAX(rowid)
                FROM rps
                GROUP BY tx_hash
            ) WHERE status = ?
            ORDER BY tx_index
        """
        bindings = ("open",)
        cursor.execute(query, bindings)
        all_holders += _get_holders(
            cursor,
            ["tx_hash"],
            {"address": "source", "address_quantity": "wager", "escrow": "tx_hash"},
            # exclude_empty_holders=exclude_empty_holders,
        )

        query = """
            SELECT * FROM (
                SELECT *, MAX(rowid)
                FROM rps_matches
                GROUP BY id
            ) WHERE status IN (?, ?, ?)
        """
        bindings = ("pending", "pending and resolved", "resolved and pending")
        cursor.execute(query, bindings)
        all_holders += _get_holders(
            cursor,
            ["id"],
            {"address": "tx0_address", "address_quantity": "wager", "escrow": "id"},
            {"address": "tx1_address", "address_quantity": "wager", "escrow": "id"},
            # exclude_empty_holders=exclude_empty_holders,
        )

    if protocol.enabled("dispensers_in_holders"):
        # Funds escrowed in dispensers.
        query = """
            SELECT * FROM (
                SELECT *, MAX(rowid)
                FROM dispensers
                WHERE asset = ?
                GROUP BY source, asset
            ) WHERE status = ?
            ORDER BY tx_index
        """
        bindings = (asset, 0)
        cursor.execute(query, bindings)
        all_holders += _get_holders(
            cursor,
            ["tx_hash", "source", "asset", "satoshirate", "give_quantity"],
            {"address": "source", "address_quantity": "give_remaining"},
            # exclude_empty_holders=exclude_empty_holders,
        )

    cursor.close()
    return holders


def xcp_created(db):
    """Return number of XCP created thus far."""
    cursor = db.cursor()
    query = """
        SELECT SUM(earned) AS total
        FROM burns
        WHERE (status = ?)
    """
    bindings = ("valid",)
    cursor.execute(query, bindings)
    total = list(cursor)[0]["total"] or 0
    cursor.close()
    return total


def xcp_destroyed(db):
    """Return number of XCP destroyed thus far."""
    cursor = db.cursor()
    # Destructions.
    query = """
        SELECT SUM(quantity) AS total
        FROM destructions
        WHERE (status = ? AND asset = ?)
    """
    bindings = ("valid", config.XCP)
    cursor.execute(query, bindings)
    destroyed_total = list(cursor)[0]["total"] or 0

    # Subtract issuance fees.
    query = """
        SELECT SUM(fee_paid) AS total
        FROM issuances
        WHERE status = ?
    """
    bindings = ("valid",)
    cursor.execute(query, bindings)
    issuance_fee_total = list(cursor)[0]["total"] or 0

    # Subtract dividend fees.
    query = """
        SELECT SUM(fee_paid) AS total
        FROM dividends
        WHERE status = ?
    """
    bindings = ("valid",)
    cursor.execute(query, bindings)
    dividend_fee_total = list(cursor)[0]["total"] or 0

    # Subtract sweep fees.
    query = """
        SELECT SUM(fee_paid) AS total
        FROM sweeps
        WHERE status = ?
    """
    bindings = ("valid",)
    cursor.execute(query, bindings)
    sweeps_fee_total = list(cursor)[0]["total"] or 0
    cursor.close()
    return destroyed_total + issuance_fee_total + dividend_fee_total + sweeps_fee_total


def xcp_supply(db):
    """Return the XCP supply."""
    return xcp_created(db) - xcp_destroyed(db)


def creations(db):
    """Return creations."""
    cursor = db.cursor()
    creations = {config.XCP: xcp_created(db)}
    query = """
        SELECT asset, SUM(quantity) AS created
        FROM issuances
        WHERE status = ?
        GROUP BY asset
    """
    bindings = ("valid",)
    cursor.execute(query, bindings)

    for issuance in cursor:
        asset = issuance["asset"]
        created = issuance["created"]
        creations[asset] = created

    cursor.close()
    return creations


def destructions(db):
    """Return destructions."""
    cursor = db.cursor()
    destructions = {config.XCP: xcp_destroyed(db)}
    query = """
        SELECT asset, SUM(quantity) AS destroyed
        FROM destructions
        WHERE (status = ? AND asset != ?)
        GROUP BY asset
    """
    bindings = ("valid", config.XCP)
    cursor.execute(query, bindings)

    for destruction in cursor:
        asset = destruction["asset"]
        destroyed = destruction["destroyed"]
        destructions[asset] = destroyed

    cursor.close()
    return destructions


def asset_issued_total_no_cache(db, asset):
    """Return asset total issued."""
    cursor = db.cursor()
    query = """
        SELECT SUM(quantity) AS total
        FROM issuances
        WHERE (status = ? AND asset = ?)
    """
    bindings = ("valid", asset)
    cursor.execute(query, bindings)
    issued_total = list(cursor)[0]["total"] or 0
    cursor.close()
    return issued_total


def asset_destroyed_total_no_cache(db, asset):
    """Return asset total destroyed."""
    cursor = db.cursor()
    query = """
        SELECT SUM(quantity) AS total
        FROM destructions
        WHERE (status = ? AND asset = ?)
    """
    bindings = ("valid", asset)
    cursor.execute(query, bindings)
    destroyed_total = list(cursor)[0]["total"] or 0
    cursor.close()
    return destroyed_total


def asset_destroyed_total(db, asset):
    return AssetCache(db).assets_total_destroyed.get(asset, 0)


def asset_issued_total(db, asset):
    return AssetCache(db).assets_total_issued.get(asset, 0)


def asset_supply(db, asset):
    """Return asset supply."""
    return asset_issued_total(db, asset) - asset_destroyed_total(db, asset)


def supplies(db):
    """Return supplies."""
    d1 = creations(db)
    d2 = destructions(db)
    return {key: d1[key] - d2.get(key, 0) for key in d1.keys()}


def held(db):
    queries = [
        """
        SELECT asset, SUM(quantity) AS total FROM (
            SELECT address, asset, quantity, (address || asset) AS aa, MAX(rowid)
            FROM balances
            WHERE address IS NOT NULL AND utxo IS NULL
            GROUP BY aa
        ) GROUP BY asset
        """,
        """
        SELECT asset, SUM(quantity) AS total FROM (
            SELECT NULL, asset, quantity
            FROM balances
            WHERE address IS NULL AND utxo IS NULL
        ) GROUP BY asset
        """,
        """
        SELECT asset, SUM(quantity) AS total FROM (
            SELECT utxo, asset, quantity, (utxo || asset) AS aa, MAX(rowid)
            FROM balances
            WHERE address IS NULL AND utxo IS NOT NULL
            GROUP BY aa
        ) GROUP BY asset
        """,
        """
        SELECT give_asset AS asset, SUM(give_remaining) AS total FROM (
            SELECT give_asset, give_remaining, status, MAX(rowid)
            FROM orders
            GROUP BY tx_hash
        ) WHERE status = 'open' GROUP BY asset
        """,
        """
        SELECT give_asset AS asset, SUM(give_remaining) AS total FROM (
            SELECT give_asset, give_remaining, status, MAX(rowid)
            FROM orders
            WHERE give_asset = 'XCP' AND get_asset = 'BTC'
            GROUP BY tx_hash
        ) WHERE status = 'filled' GROUP BY asset
        """,
        """
        SELECT forward_asset AS asset, SUM(forward_quantity) AS total FROM (
            SELECT forward_asset, forward_quantity, status, MAX(rowid)
            FROM order_matches
            GROUP BY id
        ) WHERE status = 'pending' GROUP BY asset
        """,
        """
        SELECT backward_asset AS asset, SUM(backward_quantity) AS total FROM (
            SELECT backward_asset, backward_quantity, status, MAX(rowid)
            FROM order_matches
            GROUP BY id
        ) WHERE status = 'pending' GROUP BY asset
        """,
        """
        SELECT 'XCP' AS asset, SUM(wager_remaining) AS total FROM (
            SELECT wager_remaining, status, MAX(rowid)
            FROM bets
            GROUP BY tx_hash
        ) WHERE status = 'open'
        """,
        """
        SELECT 'XCP' AS asset, SUM(forward_quantity) AS total FROM (
            SELECT forward_quantity, status, MAX(rowid)
            FROM bet_matches
            GROUP BY id
        ) WHERE status = 'pending'
        """,
        """
        SELECT 'XCP' AS asset, SUM(backward_quantity) AS total FROM (
            SELECT backward_quantity, status, MAX(rowid)
            FROM bet_matches
            GROUP BY id
        ) WHERE status = 'pending'
        """,
        """
        SELECT 'XCP' AS asset, SUM(wager) AS total FROM (
            SELECT wager, status, MAX(rowid)
            FROM rps
            GROUP BY tx_hash
        ) WHERE status = 'open'
        """,
        """
        SELECT 'XCP' AS asset, SUM(wager * 2) AS total FROM (
            SELECT wager, status, MAX(rowid)
            FROM rps_matches
            GROUP BY id
        ) WHERE status IN ('pending', 'pending and resolved', 'resolved and pending')
        """,
        """
        SELECT asset, SUM(give_remaining) AS total FROM (
            SELECT asset, give_remaining, status, MAX(rowid)
            FROM dispensers
            GROUP BY tx_hash
        ) WHERE status IN (0, 1, 11) GROUP BY asset
        """,
    ]
    # no sql injection here
    sql = (
        "SELECT asset, SUM(total) AS total FROM ("  # noqa: S608 # nosec B608
        + " UNION ALL ".join(queries)
        + ") GROUP BY asset;"
    )

    cursor = db.cursor()
    cursor.execute(sql)
    held = {}
    for row in cursor:
        asset = row["asset"]
        total = row["total"]
        held[asset] = total

    return held
