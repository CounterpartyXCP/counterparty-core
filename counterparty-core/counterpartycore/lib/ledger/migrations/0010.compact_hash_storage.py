"""Compact hash storage migration.

This migration compacts the on-disk size of every hash-typed column on the
ledger schema. It applies two independent storage optimizations in a single
table-rewrite pass:

  1. Hex -> binary: every ``*_hash`` column (and derivatives like
     ``*_random_hash``/``offer_hash``) is converted from ``TEXT(64 hex)`` to
     ``BLOB(32)``. Indexes on those columns are rebuilt against the new
     binary representation. Approximate savings: 32 bytes per hash on the
     value, plus ~50% on every hash-related index.

  2. Hash -> tx_index foreign keys: a handful of tables that already store
     a ``tx_index`` no longer need to carry the duplicate ``tx_hash`` text
     column. The legacy column is dropped and, where it referenced another
     table's transaction, replaced by an integer ``*_tx_index`` foreign key
     resolved via a JOIN on ``transactions.tx_hash``. Affected tables:
     ``messages`` (drop ``tx_hash``, add ``tx_index``), ``transactions``
     (drop ``block_hash``), ``transaction_outputs`` (drop ``tx_hash``),
     ``cancels`` (``offer_hash`` -> ``offer_tx_index``), ``dispenses``,
     ``dispenser_refills`` (``dispenser_tx_hash`` -> ``dispenser_tx_index``),
     ``fairmints`` (``fairminter_tx_hash`` -> ``fairminter_tx_index``),
     ``pool_matches`` (``order_tx_hash`` -> ``order_tx_index``).

The PK ``transactions(tx_index, tx_hash, block_index)`` is reduced to
``(tx_index)`` to keep the composite-key story simple after ``block_hash``
is dropped.

Because the schema is enforced by ``BEFORE UPDATE ... RAISE(FAIL, ...)``
triggers on many tables, we use the create-new + INSERT SELECT + DROP +
RENAME pattern; the triggers themselves are dropped at the top of the
migration and recreated at the end against the new tables.

The data transformation relies on a tiny ``__hex_to_blob`` SQLite UDF that
the migration registers on the apsw/yoyo connection at the start of ``apply``.

This migration is idempotent in the sense that if it has already run, the
column types are BLOB and re-application is short-circuited via a version
sentinel stored in the ``config`` table.
"""

import logging

from counterpartycore.lib import config
from counterpartycore.lib.utils import hashcodec
from yoyo import step

logger = logging.getLogger(config.LOGGER_NAME)


SENTINEL_NAME = "COMPACT_HASH_STORAGE_APPLIED"


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------


def _register_udfs(db):
    hashcodec.register_db_functions(db)


def _table_has_column(cursor, table, column):
    rows = cursor.execute(f"PRAGMA table_info({table})").fetchall()
    if not rows:
        return False
    if isinstance(rows[0], dict):
        names = {r["name"] for r in rows}
    else:
        names = {r[1] for r in rows}
    return column in names


def _column_affinity(cursor, table, column):
    rows = cursor.execute(f"PRAGMA table_info({table})").fetchall()
    for r in rows:
        if isinstance(r, dict):
            if r["name"] == column:
                return (r["type"] or "").upper()
        else:
            if r[1] == column:
                return (r[2] or "").upper()
    return None


def _index_definitions(cursor, table):
    """Return a list of (name, sql) for every index on ``table`` that isn't an
    auto index for the table's primary key."""
    rows = cursor.execute(
        "SELECT name, sql FROM sqlite_master "
        "WHERE type='index' AND tbl_name = ? AND sql IS NOT NULL",
        (table,),
    ).fetchall()
    out = []
    for r in rows:
        name = r["name"] if isinstance(r, dict) else r[0]
        sql = r["sql"] if isinstance(r, dict) else r[1]
        out.append((name, sql))
    return out


# Trigger names that must be dropped before a table recreate. Many of the
# BEFORE UPDATE triggers in the schema would block any plain UPDATE we issue
# on the new tables, but they also block CREATE TABLE ... RENAME inside a
# busy migration if APSW upgrades them to deferred checks. Drop them at the
# start, recreate at the end.
NO_UPDATE_TRIGGERS = [
    "block_update_balances",
    "block_update_credits",
    "block_update_debits",
    "block_update_messages",
    "block_update_order_match_expirations",
    "block_update_order_matches",
    "block_update_order_expirations",
    "block_update_orders",
    "block_update_bet_match_expirations",
    "block_update_bet_matches",
    "block_update_bet_match_resolutions",
    "block_update_bet_expirations",
    "block_update_bets",
    "block_update_broadcasts",
    "block_update_btcpays",
    "block_update_burns",
    "block_update_cancels",
    "block_update_dividends",
    "block_update_rps_match_expirations",
    "block_update_rps_expirations",
    "block_update_rpsresolves",
    "block_update_rps_matches",
    "block_update_rps",
    "block_update_destructions",
    "block_update_assets",
    "block_update_addresses",
    "block_update_sweeps",
    "block_update_dispensers",
    "block_update_dispenser_refills",
    "block_update_fairmints",
    "block_update_transaction_count",
    "block_update_fairminters",
    "block_update_dispenses",
    "block_update_sends",
    "block_update_issuances",
]


def _drop_views(cursor):
    """Drop legacy views; they reference tables we are about to recreate.
    We recreate them at the end of the migration with the new column types."""
    for view in (
        "all_holders",
        "all_expirations",
        "all_transactions",
        "all_transactions_with_status",
        "transactions_with_status",
    ):
        cursor.execute(f"DROP VIEW IF EXISTS {view}")  # nosec B608


def _drop_triggers(cursor):
    for trig in NO_UPDATE_TRIGGERS:
        cursor.execute(f"DROP TRIGGER IF EXISTS {trig}")  # nosec B608


# ---------------------------------------------------------------------------
# Table rewrites. Each entry contains:
#   - new CREATE TABLE statement (column types reflect BLOB(32) for hashes)
#   - the INSERT ... SELECT clause that converts hex -> BLOB via __hex_to_blob
#
# Most rewrites only touch column *types* and indexes (hex -> binary). The
# few tables that also drop a legacy hash column or replace it with a
# ``*_tx_index`` foreign key use a CUSTOM_INSERT_SELECT clause below.
# ---------------------------------------------------------------------------

# (table_name, columns_to_recreate, full_create_sql_with_new_types,
#  hex_columns, original_create_for_rollback)
#
# ``hex_columns`` is the subset of columns that need ``__hex_to_blob`` in the
# INSERT SELECT; all other columns are copied verbatim.

TABLE_REWRITES = [
    # blocks: 5 hash columns
    (
        "blocks",
        (
            "block_index",
            "block_hash",
            "block_time",
            "ledger_hash",
            "txlist_hash",
            "messages_hash",
            "previous_block_hash",
            "difficulty",
            "transaction_count",
        ),
        """CREATE TABLE blocks(
                          block_index INTEGER UNIQUE,
                          block_hash BLOB UNIQUE,
                          block_time INTEGER,
                          ledger_hash BLOB,
                          txlist_hash BLOB,
                          messages_hash BLOB,
                          previous_block_hash BLOB UNIQUE,
                          difficulty INTEGER,
                          transaction_count INTEGER,
                          PRIMARY KEY (block_index, block_hash))""",
        ("block_hash", "ledger_hash", "txlist_hash", "messages_hash", "previous_block_hash"),
    ),
    # transactions: tx_hash BLOB; block_hash dropped. Doing the column drop
    # in the same pass avoids a second table-rewrite of the largest table
    # in the schema.
    (
        "transactions",
        (
            "tx_index",
            "tx_hash",
            "block_index",
            "block_time",
            "source",
            "destination",
            "btc_amount",
            "fee",
            "data",
            "supported",
            "utxos_info",
            "transaction_type",
        ),
        """CREATE TABLE transactions(
                          tx_index INTEGER UNIQUE,
                          tx_hash BLOB UNIQUE,
                          block_index INTEGER,
                          block_time INTEGER,
                          source TEXT,
                          destination TEXT,
                          btc_amount INTEGER,
                          fee INTEGER,
                          data BLOB,
                          supported BOOL DEFAULT 1,
                          utxos_info TEXT,
                          transaction_type TEXT,
                          FOREIGN KEY (block_index) REFERENCES blocks(block_index),
                          PRIMARY KEY (tx_index))""",
        ("tx_hash",),
    ),
    # mempool_transactions: tx_hash + block_hash BLOB; rest unchanged.
    (
        "mempool_transactions",
        (
            "tx_index",
            "tx_hash",
            "block_index",
            "block_hash",
            "block_time",
            "source",
            "destination",
            "btc_amount",
            "fee",
            "data",
            "supported",
            "utxos_info",
            "transaction_type",
        ),
        """CREATE TABLE mempool_transactions(
                          tx_index INTEGER UNIQUE,
                          tx_hash BLOB UNIQUE,
                          block_index INTEGER,
                          block_hash BLOB,
                          block_time INTEGER,
                          source TEXT,
                          destination TEXT,
                          btc_amount INTEGER,
                          fee INTEGER,
                          data BLOB,
                          supported BOOL DEFAULT 1,
                          utxos_info TEXT, transaction_type TEXT)""",
        ("tx_hash", "block_hash"),
    ),
    # mempool: tx_hash BLOB.
    (
        "mempool",
        ("tx_hash", "command", "category", "bindings", "timestamp", "event", "addresses"),
        """CREATE TABLE mempool(
                          tx_hash BLOB,
                          command TEXT,
                          category TEXT,
                          bindings TEXT,
                          timestamp INTEGER,
                          event TEXT, addresses TEXT)""",
        ("tx_hash",),
    ),
    # messages: tx_hash dropped (replaced by tx_index FK), event_hash BLOB.
    # Insert from the old row picking tx_index via JOIN on transactions.tx_hash.
    # The messages table requires the BLOB conversion for event_hash in any
    # case, so doing the column drop at the same time avoids two separate
    # full-table rewrites on heavy installs.
    (
        "messages",
        (
            "message_index",
            "block_index",
            "command",
            "category",
            "bindings",
            "timestamp",
            "event",
            "tx_index",
            "event_hash",
        ),
        """CREATE TABLE messages(
                          message_index INTEGER PRIMARY KEY,
                          block_index INTEGER,
                          command TEXT,
                          category TEXT,
                          bindings TEXT,
                          timestamp INTEGER,
                          event TEXT,
                          tx_index INTEGER,
                          event_hash BLOB)""",
        ("event_hash",),
        # custom insert: ``tx_index`` is resolved from the old hex
        # ``tx_hash`` via a join below.
    ),
    # orders
    (
        "orders",
        (
            "tx_index",
            "tx_hash",
            "block_index",
            "source",
            "give_asset",
            "give_quantity",
            "give_remaining",
            "get_asset",
            "get_quantity",
            "get_remaining",
            "expiration",
            "expire_index",
            "fee_required",
            "fee_required_remaining",
            "fee_provided",
            "fee_provided_remaining",
            "status",
        ),
        """CREATE TABLE orders(
                            tx_index INTEGER,
                            tx_hash BLOB,
                            block_index INTEGER,
                            source TEXT,
                            give_asset TEXT,
                            give_quantity INTEGER,
                            give_remaining INTEGER,
                            get_asset TEXT,
                            get_quantity INTEGER,
                            get_remaining INTEGER,
                            expiration INTEGER,
                            expire_index INTEGER,
                            fee_required INTEGER,
                            fee_required_remaining INTEGER,
                            fee_provided INTEGER,
                            fee_provided_remaining INTEGER,
                            status TEXT)""",
        ("tx_hash",),
    ),
    # order_matches: tx0_hash, tx1_hash BLOB; ``id`` stays TEXT (composite
    # match-id compaction is out of scope for this migration).
    (
        "order_matches",
        (
            "id",
            "tx0_index",
            "tx0_hash",
            "tx0_address",
            "tx1_index",
            "tx1_hash",
            "tx1_address",
            "forward_asset",
            "forward_quantity",
            "backward_asset",
            "backward_quantity",
            "tx0_block_index",
            "tx1_block_index",
            "block_index",
            "tx0_expiration",
            "tx1_expiration",
            "match_expire_index",
            "fee_paid",
            "status",
        ),
        """CREATE TABLE order_matches(
                                    id TEXT,
                                    tx0_index INTEGER,
                                    tx0_hash BLOB,
                                    tx0_address TEXT,
                                    tx1_index INTEGER,
                                    tx1_hash BLOB,
                                    tx1_address TEXT,
                                    forward_asset TEXT,
                                    forward_quantity INTEGER,
                                    backward_asset TEXT,
                                    backward_quantity INTEGER,
                                    tx0_block_index INTEGER,
                                    tx1_block_index INTEGER,
                                    block_index INTEGER,
                                    tx0_expiration INTEGER,
                                    tx1_expiration INTEGER,
                                    match_expire_index INTEGER,
                                    fee_paid INTEGER,
                                    status TEXT)""",
        ("tx0_hash", "tx1_hash"),
    ),
    (
        "order_expirations",
        ("order_hash", "source", "block_index"),
        """CREATE TABLE order_expirations(
                                        order_hash BLOB PRIMARY KEY,
                                        source TEXT,
                                        block_index INTEGER,
                                        FOREIGN KEY (block_index) REFERENCES blocks(block_index))""",
        ("order_hash",),
    ),
    (
        "btcpays",
        (
            "tx_index",
            "tx_hash",
            "block_index",
            "source",
            "destination",
            "btc_amount",
            "order_match_id",
            "status",
        ),
        """CREATE TABLE btcpays(
                          tx_index INTEGER PRIMARY KEY,
                          tx_hash BLOB UNIQUE,
                          block_index INTEGER,
                          source TEXT,
                          destination TEXT,
                          btc_amount INTEGER,
                          order_match_id TEXT,
                          status TEXT,
                          FOREIGN KEY (tx_index) REFERENCES transactions(tx_index))""",
        ("tx_hash",),
    ),
    (
        "issuances",
        (
            "tx_index",
            "tx_hash",
            "msg_index",
            "block_index",
            "asset",
            "quantity",
            "divisible",
            "source",
            "issuer",
            "transfer",
            "callable",
            "call_date",
            "call_price",
            "description",
            "fee_paid",
            "status",
            "asset_longname",
            "description_locked",
            "fair_minting",
            "asset_events",
            "locked",
            "reset",
            "mime_type",
        ),
        """CREATE TABLE issuances(
                tx_index INTEGER,
                tx_hash BLOB,
                msg_index INTEGER DEFAULT 0,
                block_index INTEGER,
                asset TEXT,
                quantity INTEGER,
                divisible BOOL,
                source TEXT,
                issuer TEXT,
                transfer BOOL,
                callable BOOL,
                call_date INTEGER,
                call_price REAL,
                description TEXT,
                fee_paid INTEGER,
                status TEXT,
                asset_longname TEXT,
                description_locked BOOL,
                fair_minting BOOL DEFAULT 0,
                asset_events TEXT,
                locked BOOL DEFAULT FALSE,
                reset BOOL DEFAULT FALSE,
                mime_type TEXT DEFAULT "text/plain",
                PRIMARY KEY (tx_index, msg_index),
                UNIQUE (tx_hash, msg_index)
            )""",
        ("tx_hash",),
    ),
    (
        "broadcasts",
        (
            "tx_index",
            "tx_hash",
            "block_index",
            "source",
            "timestamp",
            "value",
            "fee_fraction_int",
            "text",
            "locked",
            "status",
            "mime_type",
        ),
        """CREATE TABLE broadcasts(
                          tx_index INTEGER PRIMARY KEY,
                          tx_hash BLOB UNIQUE,
                          block_index INTEGER,
                          source TEXT,
                          timestamp INTEGER,
                          value REAL,
                          fee_fraction_int INTEGER,
                          text TEXT,
                          locked BOOL,
                          status TEXT,
                          mime_type TEXT DEFAULT "text/plain",
                          FOREIGN KEY (tx_index) REFERENCES transactions(tx_index))""",
        ("tx_hash",),
    ),
    (
        "bets",
        (
            "tx_index",
            "tx_hash",
            "block_index",
            "source",
            "feed_address",
            "bet_type",
            "deadline",
            "wager_quantity",
            "wager_remaining",
            "counterwager_quantity",
            "counterwager_remaining",
            "target_value",
            "leverage",
            "expiration",
            "expire_index",
            "fee_fraction_int",
            "status",
        ),
        """CREATE TABLE bets(
                            tx_index INTEGER,
                            tx_hash BLOB,
                            block_index INTEGER,
                            source TEXT,
                            feed_address TEXT,
                            bet_type INTEGER,
                            deadline INTEGER,
                            wager_quantity INTEGER,
                            wager_remaining INTEGER,
                            counterwager_quantity INTEGER,
                            counterwager_remaining INTEGER,
                            target_value REAL,
                            leverage INTEGER,
                            expiration INTEGER,
                            expire_index INTEGER,
                            fee_fraction_int INTEGER,
                            status TEXT)""",
        ("tx_hash",),
    ),
    (
        "bet_matches",
        (
            "id",
            "tx0_index",
            "tx0_hash",
            "tx0_address",
            "tx1_index",
            "tx1_hash",
            "tx1_address",
            "tx0_bet_type",
            "tx1_bet_type",
            "feed_address",
            "initial_value",
            "deadline",
            "target_value",
            "leverage",
            "forward_quantity",
            "backward_quantity",
            "tx0_block_index",
            "tx1_block_index",
            "block_index",
            "tx0_expiration",
            "tx1_expiration",
            "match_expire_index",
            "fee_fraction_int",
            "status",
        ),
        """CREATE TABLE bet_matches(
                                id TEXT,
                                tx0_index INTEGER,
                                tx0_hash BLOB,
                                tx0_address TEXT,
                                tx1_index INTEGER,
                                tx1_hash BLOB,
                                tx1_address TEXT,
                                tx0_bet_type INTEGER,
                                tx1_bet_type INTEGER,
                                feed_address TEXT,
                                initial_value INTEGER,
                                deadline INTEGER,
                                target_value REAL,
                                leverage INTEGER,
                                forward_quantity INTEGER,
                                backward_quantity INTEGER,
                                tx0_block_index INTEGER,
                                tx1_block_index INTEGER,
                                block_index INTEGER,
                                tx0_expiration INTEGER,
                                tx1_expiration INTEGER,
                                match_expire_index INTEGER,
                                fee_fraction_int INTEGER,
                                status TEXT)""",
        ("tx0_hash", "tx1_hash"),
    ),
    (
        "bet_expirations",
        ("bet_index", "bet_hash", "source", "block_index"),
        """CREATE TABLE bet_expirations(
                                    bet_index INTEGER PRIMARY KEY,
                                    bet_hash BLOB UNIQUE,
                                    source TEXT,
                                    block_index INTEGER,
                                    FOREIGN KEY (block_index) REFERENCES blocks(block_index))""",
        ("bet_hash",),
    ),
    (
        "dividends",
        (
            "tx_index",
            "tx_hash",
            "block_index",
            "source",
            "asset",
            "dividend_asset",
            "quantity_per_unit",
            "fee_paid",
            "status",
        ),
        """CREATE TABLE dividends(
                          tx_index INTEGER PRIMARY KEY,
                          tx_hash BLOB UNIQUE,
                          block_index INTEGER,
                          source TEXT,
                          asset TEXT,
                          dividend_asset TEXT,
                          quantity_per_unit INTEGER,
                          fee_paid INTEGER,
                          status TEXT,
                          FOREIGN KEY (tx_index) REFERENCES transactions(tx_index))""",
        ("tx_hash",),
    ),
    (
        "burns",
        ("tx_index", "tx_hash", "block_index", "source", "burned", "earned", "status"),
        """CREATE TABLE burns(
                          tx_index INTEGER PRIMARY KEY,
                          tx_hash BLOB UNIQUE,
                          block_index INTEGER,
                          source TEXT,
                          burned INTEGER,
                          earned INTEGER,
                          status TEXT,
                          FOREIGN KEY (tx_index) REFERENCES transactions(tx_index))""",
        ("tx_hash",),
    ),
    # cancels: ``offer_hash`` becomes ``offer_tx_index``; resolved from the
    # old hex offer_hash via a JOIN below.
    (
        "cancels",
        (
            "tx_index",
            "tx_hash",
            "block_index",
            "source",
            "offer_tx_index",
            "status",
        ),
        """CREATE TABLE cancels(
                          tx_index INTEGER PRIMARY KEY,
                          tx_hash BLOB UNIQUE,
                          block_index INTEGER,
                          source TEXT,
                          offer_tx_index INTEGER,
                          status TEXT,
                          FOREIGN KEY (tx_index) REFERENCES transactions(tx_index))""",
        ("tx_hash",),
    ),
    (
        "rps",
        (
            "tx_index",
            "tx_hash",
            "block_index",
            "source",
            "possible_moves",
            "wager",
            "move_random_hash",
            "expiration",
            "expire_index",
            "status",
        ),
        """CREATE TABLE rps(
                            tx_index INTEGER,
                            tx_hash BLOB,
                            block_index INTEGER,
                            source TEXT,
                            possible_moves INTEGER,
                            wager INTEGER,
                            move_random_hash BLOB,
                            expiration INTEGER,
                            expire_index INTEGER,
                            status TEXT)""",
        ("tx_hash", "move_random_hash"),
    ),
    (
        "rps_matches",
        (
            "id",
            "tx0_index",
            "tx0_hash",
            "tx0_address",
            "tx1_index",
            "tx1_hash",
            "tx1_address",
            "tx0_move_random_hash",
            "tx1_move_random_hash",
            "wager",
            "possible_moves",
            "tx0_block_index",
            "tx1_block_index",
            "block_index",
            "tx0_expiration",
            "tx1_expiration",
            "match_expire_index",
            "status",
        ),
        """CREATE TABLE rps_matches(
                                id TEXT,
                                tx0_index INTEGER,
                                tx0_hash BLOB,
                                tx0_address TEXT,
                                tx1_index INTEGER,
                                tx1_hash BLOB,
                                tx1_address TEXT,
                                tx0_move_random_hash BLOB,
                                tx1_move_random_hash BLOB,
                                wager INTEGER,
                                possible_moves INTEGER,
                                tx0_block_index INTEGER,
                                tx1_block_index INTEGER,
                                block_index INTEGER,
                                tx0_expiration INTEGER,
                                tx1_expiration INTEGER,
                                match_expire_index INTEGER,
                                status TEXT)""",
        ("tx0_hash", "tx1_hash", "tx0_move_random_hash", "tx1_move_random_hash"),
    ),
    (
        "rps_expirations",
        ("rps_index", "rps_hash", "source", "block_index"),
        """CREATE TABLE rps_expirations(
                                    rps_index INTEGER PRIMARY KEY,
                                    rps_hash BLOB UNIQUE,
                                    source TEXT,
                                    block_index INTEGER,
                                    FOREIGN KEY (block_index) REFERENCES blocks(block_index))""",
        ("rps_hash",),
    ),
    (
        "rpsresolves",
        (
            "tx_index",
            "tx_hash",
            "block_index",
            "source",
            "move",
            "random",
            "rps_match_id",
            "status",
        ),
        """CREATE TABLE rpsresolves(
                          tx_index INTEGER PRIMARY KEY,
                          tx_hash BLOB UNIQUE,
                          block_index INTEGER,
                          source TEXT,
                          move INTEGER,
                          random TEXT,
                          rps_match_id TEXT,
                          status TEXT,
                          FOREIGN KEY (tx_index) REFERENCES transactions(tx_index))""",
        ("tx_hash",),
    ),
    (
        "sweeps",
        (
            "tx_index",
            "tx_hash",
            "block_index",
            "source",
            "destination",
            "flags",
            "status",
            "memo",
            "fee_paid",
        ),
        """CREATE TABLE sweeps(
                          tx_index INTEGER PRIMARY KEY,
                          tx_hash BLOB UNIQUE,
                          block_index INTEGER,
                          source TEXT,
                          destination TEXT,
                          flags INTEGER,
                          status TEXT,
                          memo BLOB,
                          fee_paid INTEGER,
                          FOREIGN KEY (tx_index) REFERENCES transactions(tx_index))""",
        ("tx_hash",),
    ),
    (
        "dispensers",
        (
            "tx_index",
            "tx_hash",
            "block_index",
            "source",
            "asset",
            "give_quantity",
            "escrow_quantity",
            "satoshirate",
            "status",
            "give_remaining",
            "oracle_address",
            "last_status_tx_hash",
            "origin",
            "dispense_count",
            "last_status_tx_source",
            "close_block_index",
        ),
        """CREATE TABLE dispensers(
                                tx_index INTEGER,
                                tx_hash BLOB,
                                block_index INTEGER,
                                source TEXT,
                                asset TEXT,
                                give_quantity INTEGER,
                                escrow_quantity INTEGER,
                                satoshirate INTEGER,
                                status INTEGER,
                                give_remaining INTEGER,
                                oracle_address TEXT,
                                last_status_tx_hash BLOB,
                                origin TEXT,
                                dispense_count INTEGER DEFAULT 0,
                                last_status_tx_source TEXT,
                                close_block_index INTEGER)""",
        ("tx_hash", "last_status_tx_hash"),
    ),
    (
        "dispenses",
        (
            "tx_index",
            "dispense_index",
            "tx_hash",
            "block_index",
            "source",
            "destination",
            "asset",
            "dispense_quantity",
            "dispenser_tx_index",
            "btc_amount",
        ),
        """CREATE TABLE dispenses (
                                tx_index INTEGER,
                                dispense_index INTEGER,
                                tx_hash BLOB,
                                block_index INTEGER,
                                source TEXT,
                                destination TEXT,
                                asset TEXT,
                                dispense_quantity INTEGER,
                                dispenser_tx_index INTEGER,
                                btc_amount INTEGER,
                                PRIMARY KEY (tx_index, dispense_index, source, destination),
                                FOREIGN KEY (tx_index) REFERENCES transactions(tx_index))""",
        ("tx_hash",),
    ),
    (
        "dispenser_refills",
        (
            "tx_index",
            "tx_hash",
            "block_index",
            "source",
            "destination",
            "asset",
            "dispense_quantity",
            "dispenser_tx_index",
        ),
        """CREATE TABLE dispenser_refills(
                                        tx_index INTEGER,
                                        tx_hash BLOB,
                                        block_index INTEGER,
                                        source TEXT,
                                        destination TEXT,
                                        asset TEXT,
                                        dispense_quantity INTEGER,
                                        dispenser_tx_index INTEGER,
                                        PRIMARY KEY (tx_index, source, destination),
                                        FOREIGN KEY (tx_index)
                                            REFERENCES transactions(tx_index))""",
        ("tx_hash",),
    ),
    (
        "fairminters",
        (
            "tx_hash",
            "tx_index",
            "block_index",
            "source",
            "asset",
            "asset_parent",
            "asset_longname",
            "description",
            "price",
            "quantity_by_price",
            "hard_cap",
            "burn_payment",
            "max_mint_per_tx",
            "premint_quantity",
            "start_block",
            "end_block",
            "minted_asset_commission_int",
            "soft_cap",
            "soft_cap_deadline_block",
            "lock_description",
            "lock_quantity",
            "divisible",
            "pre_minted",
            "status",
            "max_mint_per_address",
            "mime_type",
        ),
        """CREATE TABLE fairminters (
            tx_hash BLOB,
            tx_index INTEGER,
            block_index INTEGER,
            source TEXT,
            asset TEXT,
            asset_parent TEXT,
            asset_longname TEXT,
            description TEXT,
            price INTEGER,
            quantity_by_price INTEGER,
            hard_cap INTEGER,
            burn_payment BOOL,
            max_mint_per_tx INTEGER,
            premint_quantity INTEGER,
            start_block INTEGER,
            end_block INTEGER,
            minted_asset_commission_int INTEGER,
            soft_cap INTEGER,
            soft_cap_deadline_block INTEGER,
            lock_description BOOL,
            lock_quantity BOOL,
            divisible BOOL,
            pre_minted BOOL DEFAULT 0,
            status TEXT,
            max_mint_per_address INTEGER,
            mime_type TEXT DEFAULT "text/plain"
        )""",
        ("tx_hash",),
    ),
    (
        "fairmints",
        (
            "tx_hash",
            "tx_index",
            "block_index",
            "source",
            "fairminter_tx_index",
            "asset",
            "earn_quantity",
            "paid_quantity",
            "commission",
            "status",
        ),
        """CREATE TABLE fairmints (
            tx_hash BLOB PRIMARY KEY,
            tx_index INTEGER,
            block_index INTEGER,
            source TEXT,
            fairminter_tx_index INTEGER,
            asset TEXT,
            earn_quantity INTEGER,
            paid_quantity INTEGER,
            commission INTEGER,
            status TEXT
        )""",
        ("tx_hash",),
    ),
    (
        "sends",
        (
            "tx_index",
            "tx_hash",
            "block_index",
            "source",
            "destination",
            "asset",
            "quantity",
            "status",
            "msg_index",
            "memo",
            "fee_paid",
            "send_type",
            "source_address",
            "destination_address",
        ),
        """CREATE TABLE "sends"(
                              tx_index INTEGER,
                              tx_hash BLOB,
                              block_index INTEGER,
                              source TEXT,
                              destination TEXT,
                              asset TEXT,
                              quantity INTEGER,
                              status TEXT,
                              msg_index INTEGER DEFAULT 0,
                              memo BLOB,
                              fee_paid INTEGER DEFAULT 0,
                              send_type TEXT,
                              source_address TEXT,
                              destination_address TEXT,
                              PRIMARY KEY (tx_index, msg_index),
                              FOREIGN KEY (tx_index) REFERENCES transactions(tx_index),
                              UNIQUE (tx_hash, msg_index) ON CONFLICT FAIL)""",
        ("tx_hash",),
    ),
    (
        "destructions",
        (
            "tx_index",
            "tx_hash",
            "block_index",
            "source",
            "asset",
            "quantity",
            "tag",
            "status",
        ),
        """CREATE TABLE destructions(
            tx_index INTEGER,
            tx_hash BLOB,
            block_index INTEGER,
            source TEXT,
            asset INTEGER,
            quantity INTEGER,
            tag TEXT,
            status TEXT
        )""",
        ("tx_hash",),
    ),
    (
        "transaction_outputs",
        ("tx_index", "block_index", "out_index", "destination", "btc_amount"),
        """CREATE TABLE transaction_outputs(
                        tx_index INTEGER,
                        block_index INTEGER,
                        out_index INTEGER,
                        destination TEXT,
                        btc_amount INTEGER,
                        PRIMARY KEY (tx_index, out_index),
                        FOREIGN KEY (tx_index) REFERENCES transactions(tx_index))""",
        (),
    ),
    (
        "pools",
        (
            "tx_index",
            "tx_hash",
            "block_index",
            "source",
            "asset_a",
            "asset_b",
            "reserve_a",
            "reserve_b",
            "lp_asset",
        ),
        """CREATE TABLE pools(
    tx_index INTEGER,
    tx_hash BLOB,
    block_index INTEGER,
    source TEXT,
    asset_a TEXT,
    asset_b TEXT,
    reserve_a INTEGER,
    reserve_b INTEGER,
    lp_asset TEXT
)""",
        ("tx_hash",),
    ),
    (
        "pool_deposits",
        (
            "tx_index",
            "tx_hash",
            "block_index",
            "source",
            "asset_a",
            "asset_b",
            "quantity_a",
            "quantity_b",
            "quantity_minted",
            "status",
        ),
        """CREATE TABLE pool_deposits(
    tx_index INTEGER,
    tx_hash BLOB,
    block_index INTEGER,
    source TEXT,
    asset_a TEXT,
    asset_b TEXT,
    quantity_a INTEGER,
    quantity_b INTEGER,
    quantity_minted INTEGER,
    status TEXT
)""",
        ("tx_hash",),
    ),
    (
        "pool_withdrawals",
        (
            "tx_index",
            "tx_hash",
            "block_index",
            "source",
            "asset_a",
            "asset_b",
            "quantity_destroyed",
            "quantity_a",
            "quantity_b",
            "status",
        ),
        """CREATE TABLE pool_withdrawals(
    tx_index INTEGER,
    tx_hash BLOB,
    block_index INTEGER,
    source TEXT,
    asset_a TEXT,
    asset_b TEXT,
    quantity_destroyed INTEGER,
    quantity_a INTEGER,
    quantity_b INTEGER,
    status TEXT
)""",
        ("tx_hash",),
    ),
    (
        "pool_matches",
        (
            "tx_index",
            "tx_hash",
            "block_index",
            "source",
            "asset_a",
            "asset_b",
            "forward_asset",
            "forward_quantity",
            "backward_asset",
            "backward_quantity",
            "fee_quantity",
            "fee_bps",
            "order_tx_index",
            "status",
        ),
        """CREATE TABLE pool_matches(
    tx_index INTEGER,
    tx_hash BLOB,
    block_index INTEGER,
    source TEXT,
    asset_a TEXT,
    asset_b TEXT,
    forward_asset TEXT,
    forward_quantity INTEGER,
    backward_asset TEXT,
    backward_quantity INTEGER,
    fee_quantity INTEGER,
    fee_bps INTEGER,
    order_tx_index INTEGER,
    status TEXT
)""",
        ("tx_hash",),
    ),
]


# Indexes that need to be recreated on the new (BLOB) tables. These mirror the
# index set from ``0001.initial_migration.sql`` plus the messages_tx_index_idx
# replacement for the runtime ``messages_tx_hash_idx``.
INDEXES_AFTER_REWRITE = [
    # blocks
    "CREATE INDEX IF NOT EXISTS blocks_block_index_idx ON blocks (block_index)",
    "CREATE INDEX IF NOT EXISTS blocks_block_index_block_hash_idx ON blocks (block_index, block_hash)",
    "CREATE INDEX IF NOT EXISTS blocks_ledger_hash_idx ON blocks (ledger_hash)",
    # transactions
    "CREATE INDEX IF NOT EXISTS transactions_block_index_idx ON transactions (block_index)",
    "CREATE INDEX IF NOT EXISTS transactions_tx_index_idx ON transactions (tx_index)",
    "CREATE INDEX IF NOT EXISTS transactions_tx_hash_idx ON transactions (tx_hash)",
    "CREATE INDEX IF NOT EXISTS transactions_block_index_tx_index_idx ON transactions (block_index, tx_index)",
    "CREATE INDEX IF NOT EXISTS transactions_tx_index_tx_hash_block_index_idx ON transactions (tx_index, tx_hash, block_index)",
    "CREATE INDEX IF NOT EXISTS transactions_source_idx ON transactions (source)",
    "CREATE INDEX IF NOT EXISTS transactions_transaction_type_idx ON transactions (transaction_type)",
    # mempool_transactions
    "CREATE INDEX IF NOT EXISTS mempool_transactions_block_index_idx ON mempool_transactions (block_index)",
    "CREATE INDEX IF NOT EXISTS mempool_transactions_tx_index_idx ON mempool_transactions (tx_index)",
    "CREATE INDEX IF NOT EXISTS mempool_transactions_tx_hash_idx ON mempool_transactions (tx_hash)",
    "CREATE INDEX IF NOT EXISTS mempool_transactions_block_index_tx_index_idx ON mempool_transactions (block_index, tx_index)",
    "CREATE INDEX IF NOT EXISTS mempool_transactions_tx_index_tx_hash_block_index_idx ON mempool_transactions (tx_index, tx_hash, block_index)",
    "CREATE INDEX IF NOT EXISTS mempool_transactions_source_idx ON mempool_transactions (source)",
    # messages: indexes are created lazily by ``create_events_indexes`` once
    # the catch-up parser has populated the table, mirroring the original
    # behaviour from 0001 + the runtime helper. We deliberately skip them
    # here so the runtime path remains the single source of truth.
    # orders
    "CREATE INDEX IF NOT EXISTS orders_block_index_idx ON orders (block_index)",
    "CREATE INDEX IF NOT EXISTS orders_tx_index_tx_hash_idx ON orders (tx_index, tx_hash)",
    "CREATE INDEX IF NOT EXISTS orders_give_asset_idx ON orders (give_asset)",
    "CREATE INDEX IF NOT EXISTS orders_tx_hash_idx ON orders (tx_hash)",
    "CREATE INDEX IF NOT EXISTS orders_expire_index_idx ON orders (expire_index)",
    "CREATE INDEX IF NOT EXISTS orders_get_asset_give_asset_idx ON orders (get_asset, give_asset)",
    "CREATE INDEX IF NOT EXISTS orders_status_idx ON orders (status)",
    "CREATE INDEX IF NOT EXISTS orders_source_give_asset_idx ON orders (source, give_asset)",
    "CREATE INDEX IF NOT EXISTS orders_get_quantity_idx ON orders (get_quantity)",
    "CREATE INDEX IF NOT EXISTS orders_give_quantity_idx ON orders (give_quantity)",
    # order_matches
    "CREATE INDEX IF NOT EXISTS order_matches_block_index_idx ON order_matches (block_index)",
    "CREATE INDEX IF NOT EXISTS order_matches_forward_asset_idx ON order_matches (forward_asset)",
    "CREATE INDEX IF NOT EXISTS order_matches_backward_asset_idx ON order_matches (backward_asset)",
    "CREATE INDEX IF NOT EXISTS order_matches_id_idx ON order_matches (id)",
    "CREATE INDEX IF NOT EXISTS order_matches_tx0_address_forward_asset_idx ON order_matches (tx0_address, forward_asset)",
    "CREATE INDEX IF NOT EXISTS order_matches_tx1_address_backward_asset_idx ON order_matches (tx1_address, backward_asset)",
    "CREATE INDEX IF NOT EXISTS order_matches_match_expire_index_idx ON order_matches (match_expire_index)",
    "CREATE INDEX IF NOT EXISTS order_matches_status_idx ON order_matches (status)",
    "CREATE INDEX IF NOT EXISTS order_matches_tx0_hash_idx ON order_matches (tx0_hash)",
    "CREATE INDEX IF NOT EXISTS order_matches_tx1_hash_idx ON order_matches (tx1_hash)",
    # order_expirations
    "CREATE INDEX IF NOT EXISTS order_expirations_block_index_idx ON order_expirations (block_index)",
    "CREATE INDEX IF NOT EXISTS order_expirations_source_idx ON order_expirations (source)",
    # btcpays
    "CREATE INDEX IF NOT EXISTS btcpays_block_index_idx ON btcpays (block_index)",
    "CREATE INDEX IF NOT EXISTS btcpays_source_idx ON btcpays (source)",
    "CREATE INDEX IF NOT EXISTS btcpays_destination_idx ON btcpays (destination)",
    # issuances
    "CREATE INDEX IF NOT EXISTS issuances_block_index_idx ON issuances (block_index)",
    "CREATE INDEX IF NOT EXISTS issuances_asset_status_idx ON issuances (asset, status)",
    "CREATE INDEX IF NOT EXISTS issuances_status_idx ON issuances (status)",
    "CREATE INDEX IF NOT EXISTS issuances_source_idx ON issuances (source)",
    "CREATE INDEX IF NOT EXISTS issuances_asset_longname_idx ON issuances (asset_longname)",
    "CREATE INDEX IF NOT EXISTS issuances_status_asset_tx_index_idx ON issuances (status, asset, tx_index DESC)",
    "CREATE INDEX IF NOT EXISTS issuances_issuer_idx ON issuances (issuer)",
    "CREATE INDEX IF NOT EXISTS issuances_status_asset_longname_tx_index_idx ON issuances (status, asset_longname, tx_index DESC)",
    # broadcasts
    "CREATE INDEX IF NOT EXISTS broadcasts_block_index_idx ON broadcasts (block_index)",
    "CREATE INDEX IF NOT EXISTS broadcasts_status_source_idx ON broadcasts (status, source)",
    "CREATE INDEX IF NOT EXISTS broadcasts_status_source_tx_index_idx ON broadcasts (status, source, tx_index)",
    "CREATE INDEX IF NOT EXISTS broadcasts_timestamp_idx ON broadcasts (timestamp)",
    # bets
    "CREATE INDEX IF NOT EXISTS bets_block_index_idx ON bets (block_index)",
    "CREATE INDEX IF NOT EXISTS bets_tx_index_tx_hash_idx ON bets (tx_index, tx_hash)",
    "CREATE INDEX IF NOT EXISTS bets_status_idx ON bets (status)",
    "CREATE INDEX IF NOT EXISTS bets_tx_hash_idx ON bets (tx_hash)",
    "CREATE INDEX IF NOT EXISTS bets_feed_address_idx ON bets (feed_address)",
    "CREATE INDEX IF NOT EXISTS bets_expire_index_idx ON bets (expire_index)",
    "CREATE INDEX IF NOT EXISTS bets_feed_address_bet_type_idx ON bets (feed_address, bet_type)",
    # bet_matches
    "CREATE INDEX IF NOT EXISTS bet_matches_block_index_idx ON bet_matches (block_index)",
    "CREATE INDEX IF NOT EXISTS bet_matches_id_idx ON bet_matches (id)",
    "CREATE INDEX IF NOT EXISTS bet_matches_status_idx ON bet_matches (status)",
    "CREATE INDEX IF NOT EXISTS bet_matches_deadline_idx ON bet_matches (deadline)",
    "CREATE INDEX IF NOT EXISTS bet_matches_tx0_address_idx ON bet_matches (tx0_address)",
    "CREATE INDEX IF NOT EXISTS bet_matches_tx1_address_idx ON bet_matches (tx1_address)",
    # bet_expirations
    "CREATE INDEX IF NOT EXISTS bet_expirations_block_index_idx ON bet_expirations (block_index)",
    "CREATE INDEX IF NOT EXISTS bet_expirations_source_idx ON bet_expirations (source)",
    # dividends
    "CREATE INDEX IF NOT EXISTS dividends_block_index_idx ON dividends (block_index)",
    "CREATE INDEX IF NOT EXISTS dividends_source_idx ON dividends (source)",
    "CREATE INDEX IF NOT EXISTS dividends_asset_idx ON dividends (asset)",
    # burns
    "CREATE INDEX IF NOT EXISTS burns_status_idx ON burns (status)",
    "CREATE INDEX IF NOT EXISTS burns_source_idx ON burns (source)",
    # cancels
    "CREATE INDEX IF NOT EXISTS cancels_block_index_idx ON cancels (block_index)",
    "CREATE INDEX IF NOT EXISTS cancels_source_idx ON cancels (source)",
    "CREATE INDEX IF NOT EXISTS cancels_offer_tx_index_idx ON cancels (offer_tx_index)",
    # rps
    "CREATE INDEX IF NOT EXISTS rps_source_idx ON rps (source)",
    "CREATE INDEX IF NOT EXISTS rps_wager_possible_moves_idx ON rps (wager, possible_moves)",
    "CREATE INDEX IF NOT EXISTS rps_status_idx ON rps (status)",
    "CREATE INDEX IF NOT EXISTS rps_tx_index_idx ON rps (tx_index)",
    "CREATE INDEX IF NOT EXISTS rps_tx_hash_idx ON rps (tx_hash)",
    "CREATE INDEX IF NOT EXISTS rps_expire_index_idx ON rps (expire_index)",
    "CREATE INDEX IF NOT EXISTS rps_tx_index_tx_hash_idx ON rps (tx_index, tx_hash)",
    # rps_matches
    "CREATE INDEX IF NOT EXISTS rps_matches_tx0_address_idx ON rps_matches (tx0_address)",
    "CREATE INDEX IF NOT EXISTS rps_matches_tx1_address_idx ON rps_matches (tx1_address)",
    "CREATE INDEX IF NOT EXISTS rps_matches_status_idx ON rps_matches (status)",
    "CREATE INDEX IF NOT EXISTS rps_matches_id_idx ON rps_matches (id)",
    "CREATE INDEX IF NOT EXISTS rps_matches_match_expire_index_idx ON rps_matches (match_expire_index)",
    # rps_expirations
    "CREATE INDEX IF NOT EXISTS rps_expirations_block_index_idx ON rps_expirations (block_index)",
    "CREATE INDEX IF NOT EXISTS rps_expirations_source_idx ON rps_expirations (source)",
    # rpsresolves
    "CREATE INDEX IF NOT EXISTS rpsresolves_block_index_idx ON rpsresolves (block_index)",
    "CREATE INDEX IF NOT EXISTS rpsresolves_source_idx ON rpsresolves (source)",
    "CREATE INDEX IF NOT EXISTS rpsresolves_rps_match_id_idx ON rpsresolves (rps_match_id)",
    # sweeps
    "CREATE INDEX IF NOT EXISTS sweeps_block_index_idx ON sweeps (block_index)",
    "CREATE INDEX IF NOT EXISTS sweeps_source_idx ON sweeps (source)",
    "CREATE INDEX IF NOT EXISTS sweeps_destination_idx ON sweeps (destination)",
    "CREATE INDEX IF NOT EXISTS sweeps_memo_idx ON sweeps (memo)",
    # dispensers
    "CREATE INDEX IF NOT EXISTS dispensers_block_index_idx ON dispensers (block_index)",
    "CREATE INDEX IF NOT EXISTS dispensers_source_idx ON dispensers (source)",
    "CREATE INDEX IF NOT EXISTS dispensers_asset_idx ON dispensers (asset)",
    "CREATE INDEX IF NOT EXISTS dispensers_tx_index_idx ON dispensers (tx_index)",
    "CREATE INDEX IF NOT EXISTS dispensers_tx_hash_idx ON dispensers (tx_hash)",
    "CREATE INDEX IF NOT EXISTS dispensers_status_idx ON dispensers (status)",
    "CREATE INDEX IF NOT EXISTS dispensers_give_remaining_idx ON dispensers (give_remaining)",
    "CREATE INDEX IF NOT EXISTS dispensers_status_block_index_idx ON dispensers (status, block_index)",
    "CREATE INDEX IF NOT EXISTS dispensers_source_origin_idx ON dispensers (source, origin)",
    "CREATE INDEX IF NOT EXISTS dispensers_source_asset_origin_status_idx ON dispensers (source, asset, origin, status)",
    "CREATE INDEX IF NOT EXISTS dispensers_last_status_tx_hash_idx ON dispensers (last_status_tx_hash)",
    "CREATE INDEX IF NOT EXISTS dispensers_close_block_index_status_idx ON dispensers (close_block_index, status)",
    "CREATE INDEX IF NOT EXISTS dispensers_give_quantity_idx ON dispensers (give_quantity)",
    # dispenses
    "CREATE INDEX IF NOT EXISTS dispenses_tx_hash_idx ON dispenses (tx_hash)",
    "CREATE INDEX IF NOT EXISTS dispenses_block_index_idx ON dispenses (block_index)",
    "CREATE INDEX IF NOT EXISTS dispenses_dispenser_tx_index_idx ON dispenses (dispenser_tx_index)",
    "CREATE INDEX IF NOT EXISTS dispenses_asset_idx ON dispenses (asset)",
    "CREATE INDEX IF NOT EXISTS dispenses_source_idx ON dispenses (source)",
    "CREATE INDEX IF NOT EXISTS dispenses_destination_idx ON dispenses (destination)",
    "CREATE INDEX IF NOT EXISTS dispenses_dispense_quantity_idx ON dispenses (dispense_quantity)",
    # dispenser_refills
    "CREATE INDEX IF NOT EXISTS dispenser_refills_tx_hash_idx ON dispenser_refills (tx_hash)",
    "CREATE INDEX IF NOT EXISTS dispenser_refills_block_index_idx ON dispenser_refills (block_index)",
    # fairminters
    "CREATE INDEX IF NOT EXISTS fairminters_tx_hash_idx ON fairminters (tx_hash)",
    "CREATE INDEX IF NOT EXISTS fairminters_block_index_idx ON fairminters (block_index)",
    "CREATE INDEX IF NOT EXISTS fairminters_asset_idx ON fairminters (asset)",
    "CREATE INDEX IF NOT EXISTS fairminters_asset_longname_idx ON fairminters (asset_longname)",
    "CREATE INDEX IF NOT EXISTS fairminters_asset_parent_idx ON fairminters (asset_parent)",
    "CREATE INDEX IF NOT EXISTS fairminters_source_idx ON fairminters (source)",
    "CREATE INDEX IF NOT EXISTS fairminters_status_idx ON fairminters (status)",
    # fairmints
    "CREATE INDEX IF NOT EXISTS fairmints_tx_hash_idx ON fairmints (tx_hash)",
    "CREATE INDEX IF NOT EXISTS fairmints_block_index_idx ON fairmints (block_index)",
    "CREATE INDEX IF NOT EXISTS fairmints_fairminter_tx_index_idx ON fairmints (fairminter_tx_index)",
    "CREATE INDEX IF NOT EXISTS fairmints_asset_idx ON fairmints (asset)",
    "CREATE INDEX IF NOT EXISTS fairmints_source_idx ON fairmints (source)",
    "CREATE INDEX IF NOT EXISTS fairmints_status_idx ON fairmints (status)",
    # sends
    "CREATE INDEX IF NOT EXISTS sends_block_index_idx ON sends (block_index)",
    "CREATE INDEX IF NOT EXISTS sends_source_idx ON sends (source)",
    "CREATE INDEX IF NOT EXISTS sends_destination_idx ON sends (destination)",
    "CREATE INDEX IF NOT EXISTS sends_asset_idx ON sends (asset)",
    "CREATE INDEX IF NOT EXISTS sends_memo_idx ON sends (memo)",
    "CREATE INDEX IF NOT EXISTS sends_block_index_send_type_idx ON sends (block_index, send_type)",
    "CREATE INDEX IF NOT EXISTS sends_asset_send_type_idx ON sends (asset, send_type)",
    "CREATE INDEX IF NOT EXISTS sends_status_idx ON sends (status)",
    "CREATE INDEX IF NOT EXISTS sends_send_type_idx ON sends (send_type)",
    "CREATE INDEX IF NOT EXISTS sends_send_type ON sends (send_type)",
    "CREATE INDEX IF NOT EXISTS sends_source_address ON sends (source_address)",
    "CREATE INDEX IF NOT EXISTS sends_destination_address ON sends (destination_address)",
    # destructions
    "CREATE INDEX IF NOT EXISTS destructions_status_idx ON destructions (status)",
    "CREATE INDEX IF NOT EXISTS destructions_source_idx ON destructions (source)",
    "CREATE INDEX IF NOT EXISTS destructions_asset_idx ON destructions (asset)",
    # pools
    "CREATE INDEX IF NOT EXISTS pools_asset_a_asset_b_idx ON pools (asset_a, asset_b)",
    "CREATE INDEX IF NOT EXISTS pools_lp_asset_idx ON pools (lp_asset)",
    "CREATE INDEX IF NOT EXISTS pools_block_index_idx ON pools (block_index)",
    # pool_deposits
    "CREATE INDEX IF NOT EXISTS pool_deposits_tx_hash_idx ON pool_deposits (tx_hash)",
    "CREATE INDEX IF NOT EXISTS pool_deposits_source_status_idx ON pool_deposits (source, status)",
    "CREATE INDEX IF NOT EXISTS pool_deposits_block_index_idx ON pool_deposits (block_index)",
    "CREATE INDEX IF NOT EXISTS pool_deposits_asset_a_asset_b_status_idx ON pool_deposits (asset_a, asset_b, status)",
    # pool_withdrawals
    "CREATE INDEX IF NOT EXISTS pool_withdrawals_tx_hash_idx ON pool_withdrawals (tx_hash)",
    "CREATE INDEX IF NOT EXISTS pool_withdrawals_source_status_idx ON pool_withdrawals (source, status)",
    "CREATE INDEX IF NOT EXISTS pool_withdrawals_block_index_idx ON pool_withdrawals (block_index)",
    "CREATE INDEX IF NOT EXISTS pool_withdrawals_asset_a_asset_b_status_idx ON pool_withdrawals (asset_a, asset_b, status)",
    # pool_matches
    "CREATE INDEX IF NOT EXISTS pool_matches_tx_hash_idx ON pool_matches (tx_hash)",
    "CREATE INDEX IF NOT EXISTS pool_matches_source_idx ON pool_matches (source)",
    "CREATE INDEX IF NOT EXISTS pool_matches_block_index_idx ON pool_matches (block_index)",
    "CREATE INDEX IF NOT EXISTS pool_matches_asset_a_asset_b_idx ON pool_matches (asset_a, asset_b)",
    "CREATE INDEX IF NOT EXISTS pool_matches_order_tx_index_idx ON pool_matches (order_tx_index)",
]


# Triggers we recreate at the end (every BEFORE UPDATE trigger from
# 0001+0006). ``messages`` and others now reference the new tables; SQLite
# doesn't care that the table was recreated as long as the trigger names are
# unique.
TRIGGERS_AFTER_REWRITE = [
    f"CREATE TRIGGER IF NOT EXISTS {name} BEFORE UPDATE ON {name.replace('block_update_', '')} "
    'BEGIN SELECT RAISE(FAIL, "UPDATES NOT ALLOWED"); END'
    for name in NO_UPDATE_TRIGGERS
]


VIEWS_AFTER_REWRITE = [
    # all_transactions: same shape as 0002 but rebuilt against the new schema.
    # ``block_hash`` is no longer a column on ``transactions``; rebuild it via
    # JOIN against ``blocks``.
    """CREATE VIEW IF NOT EXISTS all_transactions AS
    SELECT
        tx_index,
        tx_hash,
        block_index,
        block_hash,
        block_time,
        source,
        destination,
        btc_amount,
        fee,
        data,
        supported,
        utxos_info,
        transaction_type,
        FALSE as confirmed
    FROM mempool_transactions
    UNION ALL
    SELECT
        t.tx_index,
        t.tx_hash,
        t.block_index,
        b.block_hash AS block_hash,
        t.block_time,
        t.source,
        t.destination,
        t.btc_amount,
        t.fee,
        t.data,
        t.supported,
        t.utxos_info,
        t.transaction_type,
        TRUE as confirmed
    FROM transactions t
    LEFT JOIN blocks b ON b.block_index = t.block_index""",
    """CREATE VIEW IF NOT EXISTS transactions_with_status AS
    SELECT
        t.tx_index as rowid,
        t.tx_index,
        t.tx_hash,
        t.block_index,
        b.block_hash AS block_hash,
        t.block_time,
        t.source,
        t.destination,
        t.btc_amount,
        t.fee,
        t.data,
        t.supported,
        t.utxos_info,
        t.transaction_type,
        ts.valid
    FROM transactions t
    LEFT JOIN blocks b ON b.block_index = t.block_index
    LEFT JOIN transactions_status ts ON t.tx_index = ts.tx_index""",
    """CREATE VIEW IF NOT EXISTS all_transactions_with_status AS
    SELECT
        t.tx_index as rowid,
        t.tx_index,
        t.tx_hash,
        t.block_index,
        t.block_hash,
        t.block_time,
        t.source,
        t.destination,
        t.btc_amount,
        t.fee,
        t.data,
        t.supported,
        t.utxos_info,
        t.transaction_type,
        t.confirmed,
        ts.valid
    FROM all_transactions t
    LEFT JOIN transactions_status ts ON t.tx_index = ts.tx_index""",
    # all_expirations: BLOB hashes; expose hex for clients via hex_lower UDF.
    """CREATE VIEW IF NOT EXISTS all_expirations AS
        SELECT 'order' AS type, hex_lower(order_hash) AS object_id, block_index,
        CONCAT(CAST(block_index AS VARCHAR), '_order_', CAST(rowid AS VARCHAR)) AS cursor_id
        FROM order_expirations
         UNION ALL
        SELECT 'order_match' AS type, order_match_id AS object_id, block_index,
        CONCAT(CAST(block_index AS VARCHAR), '_order_match_', CAST(rowid AS VARCHAR)) AS cursor_id
        FROM order_match_expirations
         UNION ALL
        SELECT 'bet' AS type, hex_lower(bet_hash) AS object_id, block_index,
        CONCAT(CAST(block_index AS VARCHAR), '_bet_', CAST(rowid AS VARCHAR)) AS cursor_id
        FROM bet_expirations
         UNION ALL
        SELECT 'bet_match' AS type, bet_match_id AS object_id, block_index,
        CONCAT(CAST(block_index AS VARCHAR), '_bet_match_', CAST(rowid AS VARCHAR)) AS cursor_id
        FROM bet_match_expirations
         UNION ALL
        SELECT 'rps' AS type, hex_lower(rps_hash) AS object_id, block_index,
        CONCAT(CAST(block_index AS VARCHAR), '_rps_', CAST(rowid AS VARCHAR)) AS cursor_id
        FROM rps_expirations
         UNION ALL
        SELECT 'rps_match' AS type, rps_match_id AS object_id, block_index,
        CONCAT(CAST(block_index AS VARCHAR), '_rps_match_', CAST(rowid AS VARCHAR)) AS cursor_id
        FROM rps_match_expirations""",
    """CREATE VIEW IF NOT EXISTS all_holders AS
        SELECT asset, address, quantity, NULL AS escrow, MAX(rowid) AS rowid,
            CONCAT('balances_', CAST(rowid AS VARCHAR)) AS cursor_id, 'balances' AS holding_type, NULL AS status
        FROM balances
        GROUP BY asset, address
         UNION ALL
        SELECT * FROM (
            SELECT give_asset AS asset, source AS address, give_remaining AS quantity, hex_lower(tx_hash) AS escrow,
                MAX(rowid) AS rowid, CONCAT('open_order_', CAST(rowid AS VARCHAR)) AS cursor_id,
                'open_order' AS holding_type, status
            FROM orders
            GROUP BY tx_hash
        ) WHERE status = 'open'
         UNION ALL
        SELECT * FROM (
            SELECT forward_asset AS asset, tx0_address AS address, forward_quantity AS quantity,
                id AS escrow, MAX(rowid) AS rowid, CONCAT('order_match_', CAST(rowid AS VARCHAR)) AS cursor_id,
                'pending_order_match' AS holding_type, status
            FROM order_matches
            GROUP BY id
        ) WHERE status = 'pending'
         UNION ALL
        SELECT * FROM (
            SELECT backward_asset AS asset, tx1_address AS address, backward_quantity AS quantity,
                id AS escrow, MAX(rowid) AS rowid, CONCAT('order_match_', CAST(rowid AS VARCHAR)) AS cursor_id,
                'pending_order_match' AS holding_type, status
            FROM order_matches
            GROUP BY id
        ) WHERE status = 'pending'
         UNION ALL
        SELECT * FROM (
            SELECT 'XCP' AS asset, source AS address, wager_remaining AS quantity,
            hex_lower(tx_hash) AS escrow, MAX(rowid) AS rowid, CONCAT('open_bet_', CAST(rowid AS VARCHAR)) AS cursor_id,
            'open_bet' AS holding_type, status
            FROM bets
            GROUP BY tx_hash
        ) WHERE status = 'open'
         UNION ALL
        SELECT * FROM (
            SELECT 'XCP' AS asset, tx0_address AS address, forward_quantity AS quantity,
            id AS escrow, MAX(rowid) AS rowid, CONCAT('bet_match_', CAST(rowid AS VARCHAR)) AS cursor_id,
            'pending_bet_match' AS holding_type, status
            FROM bet_matches
            GROUP BY id
        ) WHERE status = 'pending'
         UNION ALL
        SELECT * FROM (
            SELECT 'XCP' AS asset, tx1_address AS address, backward_quantity AS quantity,
            id AS escrow, MAX(rowid) AS rowid, CONCAT('bet_match_', CAST(rowid AS VARCHAR)) AS cursor_id,
            'pending_bet_match' AS holding_type, status
            FROM bet_matches
            GROUP BY id
        ) WHERE status = 'pending'
         UNION ALL
        SELECT * FROM (
            SELECT 'XCP' AS asset, source AS address, wager AS quantity,
            hex_lower(tx_hash) AS escrow, MAX(rowid) AS rowid, CONCAT('open_rps_', CAST(rowid AS VARCHAR)) AS cursor_id,
            'open_rps' AS holding_type, status
            FROM rps
            GROUP BY tx_hash
        ) WHERE status = 'open'
         UNION ALL
        SELECT * FROM (
            SELECT 'XCP' AS asset, tx0_address AS address, wager AS quantity,
            id AS escrow, MAX(rowid) AS rowid, CONCAT('rps_match_', CAST(rowid AS VARCHAR)) AS cursor_id,
            'pending_rps_match' AS holding_type, status
            FROM rps_matches
            GROUP BY id
        ) WHERE status IN ('pending', 'pending and resolved', 'resolved and pending')
         UNION ALL
        SELECT * FROM (
            SELECT 'XCP' AS asset, tx1_address AS address, wager AS quantity,
            id AS escrow, MAX(rowid) AS rowid, CONCAT('rps_match_', CAST(rowid AS VARCHAR)) AS cursor_id,
            'pending_rps_match' AS holding_type, status
            FROM rps_matches
            GROUP BY id
        ) WHERE status IN ('pending', 'pending and resolved', 'resolved and pending')
         UNION ALL
        SELECT * FROM (
            SELECT asset, source AS address, give_remaining AS quantity,
            hex_lower(tx_hash) AS escrow, MAX(rowid) AS rowid, CONCAT('open_dispenser_', CAST(rowid AS VARCHAR)) AS cursor_id,
            'open_dispenser' AS holding_type, status
            FROM dispensers
            GROUP BY source, asset
        ) WHERE status = 0""",
]


# ---------------------------------------------------------------------------
# Custom INSERT SELECT logic for tables whose row shape changes between the
# old and new schema (column drops / ``*_tx_hash`` -> ``*_tx_index`` FKs).
# ---------------------------------------------------------------------------

CUSTOM_INSERT_SELECT = {
    # messages: drop tx_hash, add tx_index via JOIN; convert event_hash hex
    # to BLOB.
    "messages": (
        # SELECT clause (must produce rows in the same column order as the
        # new CREATE TABLE)
        """
        SELECT
            m.message_index,
            m.block_index,
            m.command,
            m.category,
            m.bindings,
            m.timestamp,
            m.event,
            t.tx_index AS tx_index,
            __hex_to_blob(m.event_hash) AS event_hash
        FROM messages_old m
        LEFT JOIN transactions_old t ON t.tx_hash = m.tx_hash
        """
    ),
    # transactions: drop block_hash
    "transactions": (
        """
        SELECT
            tx_index,
            __hex_to_blob(tx_hash) AS tx_hash,
            block_index,
            block_time,
            source,
            destination,
            btc_amount,
            fee,
            data,
            supported,
            utxos_info,
            transaction_type
        FROM transactions_old
        """
    ),
    # cancels: replace offer_hash with offer_tx_index via JOIN
    "cancels": (
        """
        SELECT
            c.tx_index,
            __hex_to_blob(c.tx_hash) AS tx_hash,
            c.block_index,
            c.source,
            t.tx_index AS offer_tx_index,
            c.status
        FROM cancels_old c
        LEFT JOIN transactions_old t ON t.tx_hash = c.offer_hash
        """
    ),
    # dispenses: replace dispenser_tx_hash with dispenser_tx_index
    "dispenses": (
        """
        SELECT
            d.tx_index,
            d.dispense_index,
            __hex_to_blob(d.tx_hash) AS tx_hash,
            d.block_index,
            d.source,
            d.destination,
            d.asset,
            d.dispense_quantity,
            t.tx_index AS dispenser_tx_index,
            d.btc_amount
        FROM dispenses_old d
        LEFT JOIN transactions_old t ON t.tx_hash = d.dispenser_tx_hash
        """
    ),
    # dispenser_refills: replace dispenser_tx_hash with dispenser_tx_index
    "dispenser_refills": (
        """
        SELECT
            r.tx_index,
            __hex_to_blob(r.tx_hash) AS tx_hash,
            r.block_index,
            r.source,
            r.destination,
            r.asset,
            r.dispense_quantity,
            t.tx_index AS dispenser_tx_index
        FROM dispenser_refills_old r
        LEFT JOIN transactions_old t ON t.tx_hash = r.dispenser_tx_hash
        """
    ),
    # fairmints: replace fairminter_tx_hash with fairminter_tx_index
    "fairmints": (
        """
        SELECT
            __hex_to_blob(f.tx_hash) AS tx_hash,
            f.tx_index,
            f.block_index,
            f.source,
            t.tx_index AS fairminter_tx_index,
            f.asset,
            f.earn_quantity,
            f.paid_quantity,
            f.commission,
            f.status
        FROM fairmints_old f
        LEFT JOIN transactions_old t ON t.tx_hash = f.fairminter_tx_hash
        """
    ),
    # pool_matches: replace order_tx_hash with order_tx_index
    "pool_matches": (
        """
        SELECT
            p.tx_index,
            __hex_to_blob(p.tx_hash) AS tx_hash,
            p.block_index,
            p.source,
            p.asset_a,
            p.asset_b,
            p.forward_asset,
            p.forward_quantity,
            p.backward_asset,
            p.backward_quantity,
            p.fee_quantity,
            p.fee_bps,
            t.tx_index AS order_tx_index,
            p.status
        FROM pool_matches_old p
        LEFT JOIN transactions_old t ON t.tx_hash = p.order_tx_hash
        """
    ),
    # transaction_outputs: drop tx_hash entirely (resolved via tx_index FK)
    "transaction_outputs": (
        """
        SELECT
            tx_index,
            block_index,
            out_index,
            destination,
            btc_amount
        FROM transaction_outputs_old
        """
    ),
}


# ---------------------------------------------------------------------------
# Main migration entry points
# ---------------------------------------------------------------------------


def apply(conn):
    """Apply the compact-hash storage migration to the ledger DB.

    ``conn`` is the yoyo-provided connection (a stock sqlite3 connection wrapped
    in apsw on some versions). We coerce to the same row-factory contract as
    the rest of the codebase by extracting the underlying connection.
    """
    db = conn
    # yoyo sometimes passes the apsw Connection directly; sometimes a sqlite3
    # connection. Both expose ``cursor()``.
    cursor = db.cursor()

    if hasattr(cursor, "fetchone"):
        # sqlite3 stdlib path: rows come back as tuples by default.
        pass

    # Idempotency: bail if already applied (the rerun-safe shape avoids
    # double work on dev DBs).
    try:
        row = cursor.execute(
            "SELECT value FROM config WHERE name = ?", (SENTINEL_NAME,)
        ).fetchone()
    except Exception:  # noqa: BLE001
        row = None
    if row:
        logger.info("Compact-hash storage migration already applied, skipping.")
        return

    # Register the apsw UDF for hex -> BLOB; yoyo on apsw exposes
    # ``createscalarfunction`` on the connection.
    try:
        db.createscalarfunction("__hex_to_blob", _hex_to_blob_udf, 1)
    except AttributeError:
        # stdlib sqlite3 path
        db.create_function("__hex_to_blob", 1, _hex_to_blob_udf)

    # Make sure we can recreate tables freely. ``legacy_alter_table = ON``
    # prevents SQLite from auto-rewriting FK references in *other* tables
    # when we RENAME a parent table -- without it, ``ALTER TABLE blocks
    # RENAME TO blocks_old`` will silently retarget every dependent FK
    # (credits, debits, ...) to ``blocks_old`` and then crash when the
    # legacy table is dropped at the end of the migration.
    cursor.execute("PRAGMA foreign_keys = OFF")
    cursor.execute("PRAGMA defer_foreign_keys = ON")
    cursor.execute("PRAGMA legacy_alter_table = ON")

    _drop_views(cursor)
    _drop_triggers(cursor)

    # Phase 1: rename all existing tables to ``<table>_old`` so cross-table
    # JOINs (resolution of hex tx_hash -> tx_index for the FK-conversion
    # tables) can run against the legacy data after individual rewrites
    # complete.
    renamed_tables = []
    for entry in TABLE_REWRITES:
        table = entry[0]
        new_create_sql = entry[2]
        existing = cursor.execute(
            "SELECT name FROM sqlite_master WHERE type='table' AND name = ?",
            (table,),
        ).fetchone()
        if not existing:
            cursor.execute(new_create_sql)
            continue
        cursor.execute(f"ALTER TABLE {table} RENAME TO {table}_old")  # nosec B608
        cursor.execute(new_create_sql)
        renamed_tables.append(table)

    # Phase 2: copy data from each ``_old`` into the new tables. JOINs against
    # ``transactions_old`` work because all old tables are still present.
    for entry in TABLE_REWRITES:
        if len(entry) == 4:
            table, columns, _new_create_sql, hex_columns = entry
        else:
            table, columns, _new_create_sql, hex_columns, *_ = entry

        if table not in renamed_tables:
            continue

        if table in CUSTOM_INSERT_SELECT:
            select_sql = CUSTOM_INSERT_SELECT[table]
            cursor.execute(
                f"INSERT INTO {table} ({', '.join(columns)}) {select_sql}"  # nosec B608  # noqa: S608
            )
        else:
            select_cols = []
            for col in columns:
                if col in hex_columns:
                    select_cols.append(f"__hex_to_blob({col}) AS {col}")
                else:
                    select_cols.append(col)
            cursor.execute(
                f"INSERT INTO {table} ({', '.join(columns)}) "  # nosec B608  # noqa: S608
                f"SELECT {', '.join(select_cols)} FROM {table}_old"
            )

    # Phase 3: drop all the renamed legacy tables.
    for table in renamed_tables:
        cursor.execute(f"DROP TABLE {table}_old")  # nosec B608

    # 5. Recreate triggers and indexes.
    for trig_sql in TRIGGERS_AFTER_REWRITE:
        cursor.execute(trig_sql)
    for idx_sql in INDEXES_AFTER_REWRITE:
        cursor.execute(idx_sql)

    # 6. Recreate views referencing the new tables.
    for view_sql in VIEWS_AFTER_REWRITE:
        cursor.execute(view_sql)

    # 7. Sentinel so we don't re-run.
    cursor.execute(
        "INSERT OR REPLACE INTO config (name, value) VALUES (?, ?)",
        (SENTINEL_NAME, "1"),
    )

    cursor.execute("PRAGMA legacy_alter_table = OFF")
    cursor.execute("PRAGMA foreign_keys = ON")
    logger.info("Compact-hash storage migration applied.")


def rollback(conn):
    # Rollback is not supported for this migration: the data transformation
    # is one-directional. Operators should restore from bootstrap.
    raise NotImplementedError(
        "Compact-hash storage migration cannot be rolled back; restore from bootstrap."
    )


def _hex_to_blob_udf(value):
    """SQLite UDF: convert a hex string to BLOB, or NULL to NULL."""
    if value is None:
        return None
    if isinstance(value, bytes):
        return value
    if value == "":
        return None
    return bytes.fromhex(value)


if not __name__.startswith("apsw_"):
    steps = [step(apply, rollback)]
