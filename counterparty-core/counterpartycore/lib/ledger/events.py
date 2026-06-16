import binascii
import json
import time
from contextlib import contextmanager

from counterpartycore.lib import backend, config, exceptions
from counterpartycore.lib.cli import log
from counterpartycore.lib.ledger.balances import get_balance
from counterpartycore.lib.ledger.caches import AssetCache, UTXOBalancesCache
from counterpartycore.lib.ledger.currentstate import ConsensusHashBuilder, CurrentState
from counterpartycore.lib.ledger.migration_data.compact_hash_tables import ASSET_NAME_COLUMNS
from counterpartycore.lib.parser import protocol, utxosinfo
from counterpartycore.lib.utils import database, hashcodec, helpers

# Per-table list of BLOB hash columns that need automatic ``hex -> bytes``
# normalization at insert time. The values are still passed around as hex
# strings inside Python (consensus, API, tests); this mapping is consulted by
# ``insert_record`` to write the binary form to disk.
#
# Tables not listed here either have no hash columns (e.g. ``balances``) or
# their hash columns have been replaced by a ``tx_index`` FK and legacy
# ``*_tx_hash`` bindings are *resolved* before insert; see
# ``HASH_TO_TX_INDEX_FK`` below.
HASH_COLUMNS_BY_TABLE = {
    "blocks": [
        "block_hash",
        "previous_block_hash",
        "ledger_hash",
        "txlist_hash",
        "messages_hash",
    ],
    "transactions": ["tx_hash"],
    "mempool_transactions": ["tx_hash"],  # block_hash is TEXT sentinel "mempool", not a real hash
    "mempool": ["tx_hash"],
    "messages": ["event_hash"],
    "transaction_outputs": [],
    "orders": ["tx_hash"],
    "order_matches": ["tx0_hash", "tx1_hash"],
    "order_expirations": ["order_hash"],
    "bets": ["tx_hash"],
    "bet_matches": ["tx0_hash", "tx1_hash"],
    "bet_expirations": ["bet_hash"],
    "rps": ["tx_hash", "move_random_hash"],
    "rps_matches": [
        "tx0_hash",
        "tx1_hash",
        "tx0_move_random_hash",
        "tx1_move_random_hash",
    ],
    "rps_expirations": ["rps_hash"],
    "rpsresolves": ["tx_hash"],
    "issuances": ["tx_hash"],
    "broadcasts": ["tx_hash"],
    "btcpays": ["tx_hash"],
    "burns": ["tx_hash"],
    "cancels": ["tx_hash"],
    "dividends": ["tx_hash"],
    "destructions": ["tx_hash"],
    "sweeps": ["tx_hash"],
    "sends": ["tx_hash"],
    "dispensers": ["tx_hash", "last_status_tx_hash"],
    "dispenses": ["tx_hash"],
    "dispenser_refills": ["tx_hash"],
    "fairminters": ["tx_hash"],
    "fairmints": ["tx_hash"],
    "pools": ["tx_hash"],
    "pool_deposits": ["tx_hash"],
    "pool_withdrawals": ["tx_hash"],
    "pool_matches": ["tx_hash"],
}


# Legacy ``hex tx_hash`` columns that have been replaced by a ``tx_index``
# FK in the optimized schema. ``insert_record`` resolves the hex value to
# its tx_index via the ``transactions`` table just before issuing the
# INSERT, so callers (message handlers) can keep using the legacy field
# names without modification.
#
# Mapping: table -> {legacy_hex_column: new_index_column}
HASH_TO_TX_INDEX_FK = {
    "dispenses": {"dispenser_tx_hash": "dispenser_tx_index"},
    "dispenser_refills": {"dispenser_tx_hash": "dispenser_tx_index"},
    "fairmints": {"fairminter_tx_hash": "fairminter_tx_index"},
    "pool_matches": {"order_tx_hash": "order_tx_index"},
    "cancels": {"offer_hash": "offer_tx_index"},
}


# Match tables whose composite TEXT ``id`` (``tx0hash_tx1hash``) has been
# dropped in the optimized schema: the match is keyed by the existing
# ``(tx0_index, tx1_index)`` pair. ``insert_record`` strips the ``id`` binding
# before INSERT; the journal keeps it (consensus-critical).
MATCH_ID_TABLES = ("order_matches", "bet_matches", "rps_matches")


# Tables that referenced a match through a single TEXT ``*_match_id`` column.
# That column is replaced by a ``(*_tx0_index, *_tx1_index)`` integer pair;
# ``insert_record`` splits the hex id and resolves each half to its tx_index
# just before INSERT, so message handlers keep passing the legacy field.
#
# Mapping: table -> (legacy_id_column, tx0_index_column, tx1_index_column)
MATCH_ID_TO_TX_INDEX_FK = {
    "order_match_expirations": (
        "order_match_id",
        "order_match_tx0_index",
        "order_match_tx1_index",
    ),
    "bet_match_expirations": ("bet_match_id", "bet_match_tx0_index", "bet_match_tx1_index"),
    "rps_match_expirations": ("rps_match_id", "rps_match_tx0_index", "rps_match_tx1_index"),
    "bet_match_resolutions": ("bet_match_id", "bet_match_tx0_index", "bet_match_tx1_index"),
    "btcpays": ("order_match_id", "order_match_tx0_index", "order_match_tx1_index"),
    "rpsresolves": ("rps_match_id", "rps_match_tx0_index", "rps_match_tx1_index"),
}


def _resolve_tx_index(db, tx_hash_hex):
    """Look up ``tx_index`` for a hex ``tx_hash``. Returns ``None`` if the
    value is ``None`` or the tx is not (yet) in the table; callers must
    tolerate the latter (e.g. dispenser refresh references the dispenser's
    own row inserted earlier in the same block)."""
    if tx_hash_hex is None:
        return None
    blob = hashcodec.hash_to_db(tx_hash_hex)
    cursor = db.cursor()
    cursor.execute("SELECT tx_index FROM transactions WHERE tx_hash = ?", (blob,))
    row = cursor.fetchone()
    cursor.close()
    if row is None:
        return None
    return row["tx_index"]


def _resolve_match_indexes(db, match_id):
    """Split a composite ``tx0hash_tx1hash`` match id and resolve each half to
    its ``tx_index``. Returns ``(None, None)`` when the id is ``None`` or
    malformed (mirrors the permissive ``_resolve_tx_index`` contract: an
    unresolvable id -- e.g. an invalid btcpay -- yields NULL indexes)."""
    if match_id is None:
        return None, None
    parts = match_id.split(helpers.ID_SEPARATOR)
    if len(parts) != 2:
        return None, None
    return _resolve_tx_index(db, parts[0]), _resolve_tx_index(db, parts[1])


def _prepare_record_for_insert(db, table_name, record):
    """Return a copy of ``record`` with hash columns normalized to BLOB and
    any legacy hash columns resolved to their new ``*_tx_index`` FK form."""
    out = dict(record)

    # Resolve legacy hex hash -> tx_index and drop the legacy field.
    fk_map = HASH_TO_TX_INDEX_FK.get(table_name)
    if fk_map:
        for legacy_col, new_col in fk_map.items():
            if legacy_col in out and new_col not in out:
                out[new_col] = _resolve_tx_index(db, out.pop(legacy_col))
            elif legacy_col in out and new_col in out:
                out.pop(legacy_col)

    # Drop the composite TEXT ``id`` on match tables (the match is keyed by
    # the existing ``(tx0_index, tx1_index)`` pair, which the handlers already
    # supply in the bindings).
    if table_name in MATCH_ID_TABLES:
        out.pop("id", None)

    # Split the legacy composite ``*_match_id`` into its ``(tx0_index,
    # tx1_index)`` pair on referencing tables.
    match_fk = MATCH_ID_TO_TX_INDEX_FK.get(table_name)
    if match_fk:
        legacy_col, tx0_col, tx1_col = match_fk
        if legacy_col in out:
            tx0_index, tx1_index = _resolve_match_indexes(db, out.pop(legacy_col))
            out.setdefault(tx0_col, tx0_index)
            out.setdefault(tx1_col, tx1_index)

    # Convert hex strings to BLOB for known hash columns. We tolerate
    # both bytes (already converted) and None.
    hash_cols = HASH_COLUMNS_BY_TABLE.get(table_name)
    if hash_cols:
        for col in hash_cols:
            if col in out:
                out[col] = hashcodec.hash_to_db(out[col])

    # Convert asset *name* columns to the compact integer ``asset_index`` FK.
    # The journal keeps the original ``record`` (names), so the consensus
    # ``bindings_string`` stays name-based; only the stored row uses the index.
    # An unregistered name (invalid record) resolves to NULL.
    asset_cols = ASSET_NAME_COLUMNS.get(table_name)
    if asset_cols:
        for col in asset_cols:
            if col in out and isinstance(out[col], str):
                out[col] = database.asset_index_from_name(db, out[col])

    return out


@contextmanager
def get_cursor(db):
    cursor = db.cursor()
    try:
        yield cursor
    finally:
        cursor.close()


def ensure_asset(db, asset_id, asset_name, block_index, asset_longname):
    """Create the ``assets`` row (DB only, no journal) if it does not exist
    yet, so records inserted *before* their ``ASSET_CREATION`` event -- e.g. a
    fairminter referencing the asset it is about to mint -- can still resolve
    the compact ``asset_index``. The subsequent ``ASSET_CREATION`` insert is
    idempotent (``INSERT OR IGNORE`` on ``assets``), so the consensus event
    order is preserved while the storage row exists early."""
    with get_cursor(db) as cursor:
        cursor.execute(
            "INSERT OR IGNORE INTO assets (asset_id, asset_name, block_index, asset_longname) "
            "VALUES (?, ?, ?, ?)",
            (str(asset_id), asset_name, block_index, asset_longname),
        )


def insert_record(db, table_name, record, event, event_info=None):
    record_for_db = _prepare_record_for_insert(db, table_name, record)
    fields = list(record_for_db.keys())
    placeholders = ", ".join(["?" for _ in fields])
    # ``assets`` may have been pre-created (DB only) by ``ensure_asset`` so an
    # earlier record could resolve its ``asset_index``; tolerate the duplicate
    # while still emitting the ASSET_CREATION journal entry below.
    or_ignore = "OR IGNORE " if table_name == "assets" else ""
    query = f"INSERT {or_ignore}INTO {table_name} ({', '.join(fields)}) VALUES ({placeholders})"  # noqa: S608 # nosec B608

    with get_cursor(db) as cursor:
        cursor.execute(query, list(record_for_db.values()))
        if table_name in ["issuances", "destructions"] and not CurrentState().parsing_mempool():
            cursor.execute("SELECT last_insert_rowid() AS rowid")
            inserted_rowid = cursor.fetchone()["rowid"]
            new_record = cursor.execute(
                f"SELECT * FROM {table_name} WHERE rowid = ?",  # noqa: S608 # nosec B608
                (inserted_rowid,),
            ).fetchone()
            if AssetCache in AssetCache._instances:  # pylint: disable=protected-access
                if table_name == "issuances":
                    AssetCache(db).add_issuance(new_record)
                elif table_name == "destructions":
                    AssetCache(db).add_destroyed(new_record)
            else:
                AssetCache(db)  # initialization will add just created record to cache

    add_to_journal(
        db,
        CurrentState().current_block_index(),
        "insert",
        table_name,
        event,
        record | (event_info or {}),
    )


# This function allows you to update a record using an INSERT.
# The `block_index` and `rowid` fields allow you to
# order updates and retrieve the row with the current data.
def insert_update(db, table_name, id_name, id_value, update_data, event, event_info=None):  # noqa: B006
    cursor = db.cursor()
    # The id may be a hex hash and the underlying column may be BLOB; convert
    # consistently so SQLite can match the at-rest representation.
    # ``hash_to_db`` is permissive: it passes ``bytes``/``None`` through, hex
    # strings -> BLOB(32), and non-hex strings -> UTF-8 bytes (consistent
    # with INSERT paths for synthetic test fixtures). Only triggered for
    # ``id_name``s that are actually hash columns; non-hash ids like
    # ``rowid`` / ``id`` (composite text) / ``address`` are bound as-is.
    if table_name in MATCH_ID_TABLES and id_name == "id":
        # The composite TEXT ``id`` is no longer a stored column; match on the
        # ``(tx0_index, tx1_index)`` pair resolved from the text id. The
        # journal below still records the original text id (consensus).
        tx0_index, tx1_index = _resolve_match_indexes(db, id_value)
        select_query = f"""
            SELECT *, rowid
            FROM {table_name}
            WHERE tx0_index = ? AND tx1_index = ?
            ORDER BY rowid DESC
            LIMIT 1
        """  # nosec B608  # noqa: S608 # nosec B608
        bindings = (tx0_index, tx1_index)
    else:
        if id_name in hashcodec.HASH_COLUMN_NAMES:
            id_bind = hashcodec.hash_to_db(id_value)
        else:
            id_bind = id_value
        select_query = f"""
            SELECT *, rowid
            FROM {table_name}
            WHERE {id_name} = ?
            ORDER BY rowid DESC
            LIMIT 1
        """  # nosec B608  # noqa: S608 # nosec B608
        bindings = (id_bind,)
    need_update_record = cursor.execute(select_query, bindings).fetchone()

    # update record
    new_record = need_update_record.copy()
    # updade needed fields
    for key, value in update_data.items():
        new_record[key] = value
    # new block_index and tx_index
    new_record["block_index"] = CurrentState().current_block_index()
    # let's keep the original tx_index so we can preserve order
    # with the old queries (ordered by default by old primary key)
    # if 'tx_index' in new_record:
    #    new_record['tx_index'] = tx_index
    # insert new record
    if "rowid" in new_record:
        del new_record["rowid"]
    new_record = _prepare_record_for_insert(db, table_name, new_record)
    fields_name = ", ".join(new_record.keys())
    fields_values = ", ".join([f":{key}" for key in new_record.keys()])
    # no sql injection here
    insert_query = f"""INSERT INTO {table_name} ({fields_name}) VALUES ({fields_values})"""  # nosec B608  # noqa: S608 # nosec B608
    cursor.execute(insert_query, new_record)
    cursor.close()
    # Add event to journal
    event_paylod = update_data | {id_name: id_value} | (event_info or {})
    if "rowid" in event_paylod:
        del event_paylod["rowid"]
    add_to_journal(
        db, CurrentState().current_block_index(), "update", table_name, event, event_paylod
    )


def last_message(db):
    """Return latest message from the db. Exposes the legacy ``tx_hash`` hex
    string by joining on ``transactions`` (``messages.tx_index`` is the
    storage column after the compact-hash migration)."""
    cursor = db.cursor()
    query = """
        SELECT m.*, (SELECT t.tx_hash FROM transactions t WHERE t.tx_index = m.tx_index) AS tx_hash
        FROM messages m
        WHERE m.message_index = (
            SELECT MAX(message_index) from messages
        )
    """
    messages = list(cursor.execute(query))
    if messages:
        assert len(messages) == 1
        message = messages[0]
    else:
        raise exceptions.DatabaseError("No messages found.")
    cursor.close()
    return message


# we are using a function here for testing purposes
def curr_time():
    return int(time.time())


def add_to_journal(db, block_index, command, category, event, bindings):
    # Get last message index.
    try:
        previous_message = last_message(db)
        message_index = previous_message["message_index"] + 1
        # The rowtracer already converts BLOB event_hash back to hex, but be
        # defensive in case the row trace is bypassed somewhere.
        prev_eh = previous_message["event_hash"]
        previous_event_hash = (
            hashcodec.hash_from_db(prev_eh) if isinstance(prev_eh, bytes) else (prev_eh or "")
        )
    except exceptions.DatabaseError:
        message_index = 0
        previous_event_hash = ""

    # The consensus-critical ``bindings_string`` JSON MUST stay byte-identical
    # to the pre-optimization release: hashes (which the message handlers
    # always pass as hex strings) must remain hex; ``bytes`` values found in
    # ``data`` style fields must be hex-encoded; ``None`` stays None. The
    # original implementation converts bytes -> hex which already covers both
    # cases (BLOB hashes coming from row dicts and binary ``data`` payloads).
    items = {
        key: binascii.hexlify(value).decode("ascii") if isinstance(value, bytes) else value
        for key, value in bindings.items()
    }

    current_time = curr_time()
    bindings_string = json.dumps(items, sort_keys=True, separators=(",", ":"))
    event_hash_content = "".join(
        [
            str(message_index),
            str(block_index),
            command,
            category,
            bindings_string,
            event,
            CurrentState().current_tx_hash() or "",
            previous_event_hash,
        ]
    )
    event_hash = binascii.hexlify(helpers.dhash(event_hash_content)).decode("ascii")
    # ``messages.tx_hash`` has been replaced by ``messages.tx_index``
    # (INTEGER FK into ``transactions``). Resolve from the in-flight tx_hash
    # via CurrentState. For block-level events (BLOCK_PARSED, EXPIRE_*) the
    # tx context is None, so tx_index stays NULL.
    current_tx_hash_hex = CurrentState().current_tx_hash()
    tx_index = None
    if current_tx_hash_hex is not None:
        tx_index = _resolve_tx_index(db, current_tx_hash_hex)
    event_hash_blob = hashcodec.hash_to_db(event_hash)
    message_bindings = {
        "message_index": message_index,
        "block_index": block_index,
        "command": command,
        "category": category,
        "bindings": bindings_string,
        "timestamp": current_time,
        "event": event,
        "tx_index": tx_index,
        "event_hash": event_hash_blob,
    }
    query = """INSERT INTO messages (
                message_index, block_index, command, category, bindings, timestamp, event, tx_index, event_hash
            ) VALUES (
                :message_index,
                :block_index,
                :command,
                :category,
                :bindings,
                :timestamp,
                :event,
                :tx_index,
                :event_hash
            )"""
    cursor = db.cursor()
    cursor.execute(query, message_bindings)
    cursor.close()

    ConsensusHashBuilder().append_to_block_journal(f"{command}{category}{bindings_string}")

    log.log_event(block_index, message_index, event, items)


def remove_from_balance(db, address, asset, quantity, tx_index, utxo_address=None):
    balance_cursor = db.cursor()

    no_balance = False
    try:
        old_balance = get_balance(db, address, asset, raise_error_if_no_balance=True)
    except exceptions.BalanceError:
        old_balance = 0
        no_balance = True

    if old_balance < quantity:
        raise exceptions.DebitError("Insufficient funds.")

    balance = round(old_balance - quantity)
    balance = min(balance, config.MAX_INT)
    assert balance >= 0

    balance_address = address
    utxo = None
    if protocol.enabled("utxo_support") and utxosinfo.is_utxo_format(address):
        balance_address = None
        utxo = address
        if not CurrentState().parsing_mempool() and balance == 0:
            UTXOBalancesCache(db).remove_balance(utxo)

    if not no_balance:  # don't create balance if quantity is 0 and there is no balance
        bindings = {
            "quantity": balance,
            "address": balance_address,
            "utxo": utxo,
            "utxo_address": utxo_address,
            # balances stores the compact ``asset_index``; the name always
            # resolves here (a balance only exists for an issued asset).
            "asset": database.asset_index_from_name(db, asset),
            "block_index": CurrentState().current_block_index(),
            "tx_index": tx_index,
        }
        query = """
            INSERT INTO balances (address, asset, quantity, block_index, tx_index, utxo, utxo_address)
            VALUES (:address, :asset, :quantity, :block_index, :tx_index, :utxo, :utxo_address)
        """
        balance_cursor.execute(query, bindings)


def append_to_ledger_hash(block_index, address, asset, quantity):
    ConsensusHashBuilder().append_to_block_ledger(f"{block_index}{address}{asset}{quantity}")


def debit(db, address, asset, quantity, tx_index, action=None, event=None):
    """Debit given address by quantity of asset."""
    block_index = CurrentState().current_block_index()

    if not isinstance(quantity, int):  # noqa: E721
        raise exceptions.DebitError("Quantity must be an integer.")
    if quantity < 0:
        raise exceptions.DebitError("Negative quantity.")
    if quantity > config.MAX_INT:
        raise exceptions.DebitError("Quantity can't be higher than MAX_INT.")
    if asset == config.BTC:
        raise exceptions.DebitError("Cannot debit bitcoins.")

    # Contracts can only hold XCP balances.
    if protocol.enabled("contracts_only_xcp_balances"):  # Protocol change.
        if len(address) == 40:
            assert asset == config.XCP

    debit_address = address
    utxo = None
    utxo_address = None
    if protocol.enabled("utxo_support") and utxosinfo.is_utxo_format(address):
        debit_address = None
        utxo = address
        utxo_address = backend.bitcoind.safe_get_utxo_address(utxo)

    remove_from_balance(db, address, asset, quantity, tx_index, utxo_address)

    # Record debit.
    bindings = {
        "block_index": block_index,
        "address": debit_address,
        "utxo": utxo,
        "utxo_address": utxo_address,
        "asset": asset,
        "quantity": quantity,
        "action": action,
        "event": event,
        "tx_index": tx_index,
    }
    insert_record(db, "debits", bindings, "DEBIT")

    append_to_ledger_hash(block_index, address, asset, quantity)

    return utxo_address


def add_to_balance(db, address, asset, quantity, tx_index, utxo_address=None):
    balance_cursor = db.cursor()

    old_balance = get_balance(db, address, asset)
    balance = round(old_balance + quantity)
    balance = min(balance, config.MAX_INT)

    balance_address = address
    utxo = None
    if protocol.enabled("utxo_support") and utxosinfo.is_utxo_format(address):
        balance_address = None
        utxo = address
        if not CurrentState().parsing_mempool() and balance > 0:
            UTXOBalancesCache(db).add_balance(utxo)

    bindings = {
        "quantity": balance,
        "address": balance_address,
        "utxo": utxo,
        "utxo_address": utxo_address,
        # balances stores the compact ``asset_index`` (resolved from the name).
        "asset": database.asset_index_from_name(db, asset),
        "block_index": CurrentState().current_block_index(),
        "tx_index": tx_index,
    }
    query = """
        INSERT INTO balances (address, asset, quantity, block_index, tx_index, utxo, utxo_address)
        VALUES (:address, :asset, :quantity, :block_index, :tx_index, :utxo, :utxo_address)
    """
    balance_cursor.execute(query, bindings)


def credit(db, address, asset, quantity, tx_index, action=None, event=None):
    """Credit given address by quantity of asset."""
    block_index = CurrentState().current_block_index()

    if not isinstance(quantity, int):  # noqa: E721
        raise exceptions.CreditError("Quantity must be an integer.")
    if quantity < 0:
        raise exceptions.CreditError("Negative quantity.")
    if quantity > config.MAX_INT:
        raise exceptions.CreditError("Quantity can't be higher than MAX_INT.")
    if asset == config.BTC:
        raise exceptions.CreditError("Cannot debit bitcoins.")

    # Contracts can only hold XCP balances.
    if protocol.enabled("contracts_only_xcp_balances"):  # Protocol change.
        if len(address) == 40:
            assert asset == config.XCP

    credit_address = address
    utxo = None
    utxo_address = None
    if protocol.enabled("utxo_support") and utxosinfo.is_utxo_format(address):
        credit_address = None
        utxo = address
        utxo_address = backend.bitcoind.safe_get_utxo_address(utxo)

    add_to_balance(db, address, asset, quantity, tx_index, utxo_address)

    # Record credit.
    bindings = {
        "block_index": block_index,
        "address": credit_address,
        "utxo": utxo,
        "utxo_address": utxo_address,
        "asset": asset,
        "quantity": quantity,
        "calling_function": action,
        "event": event,
        "tx_index": tx_index,
    }
    insert_record(db, "credits", bindings, "CREDIT")

    append_to_ledger_hash(block_index, address, asset, quantity)

    return utxo_address


def get_messages(db, block_index=None, block_index_in=None, message_index_in=None, limit=100):
    cursor = db.cursor()
    where = []
    bindings = []
    if block_index is not None:
        where.append("m.block_index = ?")
        bindings.append(block_index)
    if block_index_in is not None:
        where.append(f"m.block_index IN ({','.join(['?' for e in range(0, len(block_index_in))])})")
        bindings += block_index_in
    if message_index_in is not None:
        where.append(
            f"m.message_index IN ({','.join(['?' for e in range(0, len(message_index_in))])})"
        )
        bindings += message_index_in
    # no sql injection here -- expose tx_hash via JOIN (messages.tx_hash
    # was dropped in favour of an FK on transactions).
    select = (
        "SELECT m.*, "
        "(SELECT t.tx_hash FROM transactions t WHERE t.tx_index = m.tx_index) AS tx_hash "
        "FROM messages m"
    )
    if len(where) == 0:
        query = f"""{select} ORDER BY m.message_index ASC LIMIT ?"""
    else:
        query = f"""{select} WHERE ({" AND ".join(where)}) ORDER BY m.message_index ASC LIMIT ?"""  # nosec B608  # noqa: S608 # nosec B608
    bindings.append(limit)
    cursor.execute(query, tuple(bindings))
    return cursor.fetchall()


def replay_event(db, event, action, table, bindings, id_name=None):
    if action == "insert":
        if event == "DEBIT":
            debit(
                db,
                bindings["address"],
                bindings["asset"],
                bindings["quantity"],
                bindings["tx_index"],
                action=bindings["action"],
                event=bindings["event"],
            )
        elif event == "CREDIT":
            credit(
                db,
                bindings["address"],
                bindings["asset"],
                bindings["quantity"],
                bindings["tx_index"],
                action=bindings["calling_function"],
                event=bindings["event"],
            )
        else:
            insert_record(db, table, bindings, event)
    elif action == "update":
        if id_name is None:
            raise exceptions.DatabaseError("id_name is required for update action")
        id_value = bindings.pop(id_name)
        insert_update(db, table, id_name, id_value, bindings, event)
    else:
        raise exceptions.DatabaseError(f"Unknown action: {action}")


def replay_events(db, events):
    for event in events:
        event_name = event[0]
        bindings = json.loads(event[3])
        if event_name.endswith("_UPDATE"):
            replay_event(db, event[0], event[1], event[2], bindings, id_name=event[4])
        else:
            replay_event(db, event[0], event[1], event[2], bindings)
