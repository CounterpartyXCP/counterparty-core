import logging
import time

from counterpartycore.lib import config
from counterpartycore.lib.ledger.currentstate import CurrentState
from counterpartycore.lib.parser.known_sources import KNOWN_SOURCES
from counterpartycore.lib.utils import database, hashcodec, helpers

logger = logging.getLogger(config.LOGGER_NAME)


class AssetCache(metaclass=helpers.SingletonMeta):
    def __init__(self, db) -> None:
        # Store db reference for lazy loading on cache miss
        self.db = db
        # Load all assets into memory (unbounded dict)
        # AssetCache LRU caused 10x slowdown on mainnet: 56MB memory savings not worth it
        self.assets = {}
        # Keep full dicts for supply calculations (these are just numbers, much smaller)
        self.assets_total_issued = {}
        self.assets_total_destroyed = {}
        start = time.time()
        logger.debug("Initialising asset cache...")
        # asset info - load all assets
        sql = """
            SELECT *, MAX(rowid) AS rowid FROM issuances
            WHERE status = 'valid'
            GROUP BY asset
        """
        cursor = db.cursor()
        all_assets = cursor.execute(sql)
        for asset in all_assets:
            del asset["rowid"]
            if asset["asset_longname"] is not None:
                self.assets[asset["asset_longname"]] = asset
            self.assets[asset["asset"]] = asset
        duration = time.time() - start
        # asset total issued - load fully (needed for supply calculations)
        sql = """
            SELECT SUM(quantity) AS total, asset
            FROM issuances
            WHERE status = 'valid'
            GROUP BY asset
        """
        cursor.execute(sql)
        all_counts = cursor.fetchall()
        self.assets_total_issued = {}
        for count in all_counts:
            self.assets_total_issued[count["asset"]] = count["total"]
        # asset total destroyed - load fully (needed for supply calculations)
        sql = """
            SELECT SUM(quantity) AS total, asset
            FROM destructions
            WHERE status = 'valid'
            GROUP BY asset
        """
        cursor.execute(sql)
        all_counts = cursor.fetchall()
        self.assets_total_destroyed = {}
        for count in all_counts:
            self.assets_total_destroyed[count["asset"]] = count["total"]

        logger.debug(
            "Asset cache initialised in %.2f seconds (loaded=%d assets)",
            duration,
            len(self.assets),
        )

    def get_asset(self, asset_name):
        """Get asset info from cache, falling back to DB on cache miss."""
        # Check cache first
        if asset_name in self.assets:
            return self.assets[asset_name]

        # Cache miss - query database
        cursor = self.db.cursor()
        name_field = "asset_longname" if "." in asset_name else "asset"
        sql = f"""
            SELECT * FROM issuances
            WHERE ({name_field} = ? AND status = 'valid')
            ORDER BY tx_index DESC
            LIMIT 1
        """  # nosec B608  # noqa: S608
        # ``asset_longname`` stays TEXT; the ``asset`` column is now the compact
        # ``asset_index`` FK, so resolve the name to its index before binding
        # (mirrors ``issuances.get_asset``). An unregistered asset resolves to
        # NULL and matches nothing, correctly returning no issuance.
        bind_asset = (
            asset_name
            if name_field == "asset_longname"
            else database.asset_index_from_name(self.db, asset_name)
        )
        cursor.execute(sql, (bind_asset,))
        result = cursor.fetchone()

        if result:
            # Cache the result for future lookups
            self.assets[asset_name] = result

        return result

    def add_issuance(self, issuance):
        if "rowid" in issuance:
            del issuance["rowid"]
        if issuance["status"] == "valid":
            if issuance["asset_longname"] is not None:
                self.assets[issuance["asset_longname"]] = issuance
            self.assets[issuance["asset"]] = issuance
            if issuance["quantity"] is not None:
                if issuance["asset"] in self.assets_total_issued:
                    self.assets_total_issued[issuance["asset"]] += issuance["quantity"]
                else:
                    self.assets_total_issued[issuance["asset"]] = issuance["quantity"]

    def add_destroyed(self, destroyed):
        if "rowid" in destroyed:
            del destroyed["rowid"]
        if destroyed["status"] == "valid" and destroyed["quantity"] is not None:
            if destroyed["asset"] in self.assets_total_destroyed:
                self.assets_total_destroyed[destroyed["asset"]] += destroyed["quantity"]
            else:
                self.assets_total_destroyed[destroyed["asset"]] = destroyed["quantity"]


class UTXOBalancesCache(metaclass=helpers.SingletonMeta):
    def __init__(self, db):
        # Store db reference for lazy loading on cache miss
        self.db = db
        logger.debug("Initialising utxo balances cache...")
        # Simple dict containing only UTXOs that currently have a balance
        # Size bounded by active UTXO set with balances (not historical)
        self.utxos_with_balance = {}

        cursor = db.cursor()

        # Load UTXOs with balance from the balances table. ``utxo`` is stored as
        # the compact ``(utxo_tx_hash, utxo_vout)`` pair; selecting both lets
        # the rowtracer reconstruct the ``utxo`` string so the cache key is
        # unchanged.
        sql = (
            "SELECT utxo_tx_hash, utxo_vout, asset, quantity, MAX(rowid) FROM balances "
            "WHERE utxo_tx_hash IS NOT NULL GROUP BY utxo_tx_hash, utxo_vout, asset"
        )
        cursor.execute(sql)
        utxo_balances = cursor.fetchall()
        for utxo_balance in utxo_balances:
            self.utxos_with_balance[utxo_balance["utxo"]] = True

        # Add destinations from invalid attachs
        # (see gettxinfo.update_utxo_balances_cache())
        sql = "SELECT tx_hash, utxos_info FROM transactions_with_status WHERE valid IS FALSE AND transaction_type = ?"
        cursor.execute(sql, ("attach",))
        invalid_attach_transactions = cursor.fetchall()
        for transaction in invalid_attach_transactions:
            utxos_info = transaction["utxos_info"].split(" ")
            if len(utxos_info) >= 2 and utxos_info[1] != "":
                self.utxos_with_balance[utxos_info[1]] = True

        # Add destinations from KNOWN_SOURCES transactions and their descendants
        # KNOWN_SOURCES forces a source even when the source has no balance in the balances table,
        # which adds the destination to cache during parsing but not to the balances table.
        # We must follow the chain of transactions that consume these destinations.
        self._add_known_sources_descendants(cursor)

        logger.debug(
            "UTXO balances cache initialised (loaded=%d)",
            len(self.utxos_with_balance),
        )

    def _add_known_sources_descendants(self, cursor):
        """Add to cache the destinations from KNOWN_SOURCES and all descendant transactions."""
        pending_utxos = set()

        # Start with destinations from KNOWN_SOURCES
        for tx_hash, source in KNOWN_SOURCES.items():
            if source != "":
                tx = cursor.execute(
                    "SELECT utxos_info, transaction_type FROM transactions WHERE tx_hash = ?",
                    (hashcodec.hash_to_db(tx_hash),),
                ).fetchone()
                if tx:
                    utxos_info = tx["utxos_info"].split(" ")
                    if len(utxos_info) >= 2 and utxos_info[1] != "":
                        self.utxos_with_balance[utxos_info[1]] = True
                        pending_utxos.add(utxos_info[1])

        # Follow the chain: find transactions that consume these UTXOs
        processed = set()
        while pending_utxos:
            utxo = pending_utxos.pop()
            if utxo in processed:
                continue
            processed.add(utxo)

            # Find transactions where this UTXO is a source
            # utxos_info format: "sources destination num_outputs [op_return_index]"
            # We search for transactions where utxos_info starts with this UTXO
            txs = cursor.execute(
                """SELECT utxos_info, transaction_type FROM transactions
                   WHERE transaction_type IN ('utxomove', 'attach', 'detach')
                   AND utxos_info LIKE ?
                   ORDER BY tx_index""",
                (f"{utxo}%",),
            ).fetchall()

            for tx in txs:
                utxos_info = tx["utxos_info"].split(" ")
                transaction_type = tx["transaction_type"]
                if len(utxos_info) >= 2:
                    sources = utxos_info[0].split(",")
                    if utxo in sources:
                        # This UTXO is consumed, remove from cache
                        self.utxos_with_balance.pop(utxo, None)
                        # Add destination if not a detach
                        if utxos_info[1] != "" and transaction_type != "detach":
                            self.utxos_with_balance[utxos_info[1]] = True
                            if utxos_info[1] not in processed:
                                pending_utxos.add(utxos_info[1])

    def has_balance(self, utxo):
        # Check cache first
        if utxo in self.utxos_with_balance:
            return self.utxos_with_balance[utxo]

        # Cache miss - query database. ``utxo`` is stored as the compact
        # ``(utxo_tx_hash, utxo_vout)`` pair; split the string to filter.
        cursor = self.db.cursor()
        utxo_tx_hash, utxo_vout = database.split_utxo(utxo)
        cursor.execute(
            "SELECT 1 FROM balances WHERE utxo_tx_hash = ? AND utxo_vout = ? AND quantity > 0 LIMIT 1",
            (utxo_tx_hash, utxo_vout),
        )
        result = cursor.fetchone() is not None

        # Only cache positive results to avoid unbounded memory growth
        # (negative results from DB queries are not cached - they would accumulate indefinitely)
        if result:
            self.utxos_with_balance[utxo] = True
        return result

    def add_balance(self, utxo):
        self.utxos_with_balance[utxo] = True

    def remove_balance(self, utxo):
        # Mark as no balance (needed during parsing before DB is updated)
        self.utxos_with_balance[utxo] = False

    def cleanup_spent_utxos(self):
        """
        Remove entries marked as spent (False) from the cache.
        Should be called after each block is parsed to prevent unbounded memory growth.
        """
        # Build list of keys to remove (can't modify dict during iteration)
        spent_utxos = [
            utxo for utxo, has_balance in self.utxos_with_balance.items() if not has_balance
        ]
        for utxo in spent_utxos:
            del self.utxos_with_balance[utxo]
        if spent_utxos:
            logger.trace("Cleaned up %d spent UTXOs from cache", len(spent_utxos))

    @classmethod
    def cleanup_if_exists(cls):
        """
        Clean up spent UTXOs only if the cache singleton already exists.
        This avoids creating the singleton with a potentially stale DB connection.
        """
        instances = helpers.SingletonMeta._instances  # pylint: disable=protected-access
        if cls in instances:
            instances[cls].cleanup_spent_utxos()


class OrdersCache(metaclass=helpers.SingletonMeta):
    """In-memory shadow of the ``orders`` table for fast matching.

    NOTE on hash encoding: the cache table keeps ``tx_hash`` as ``TEXT``
    (64-char lowercase hex), unlike the persisted ledger schema which stores
    it as ``BLOB(32)`` after the compact-hash storage migration. This is
    intentional because the cache is populated and consumed exclusively
    via the rowtracer / Python layer where hashes are already normalised
    to hex strings (see ``utils/database.rowtracer``).

    Callers MUST pass hex strings to ``insert_order``, ``update_order``,
    ``get_matching_orders``, etc. Passing raw ``bytes`` would silently
    fail to match (SQLite would compare a BLOB against a TEXT column).
    If a caller ever needs to bind a value coming from a raw SQL fetch
    that bypassed the rowtracer, normalise it first via
    ``hashcodec.hash_from_db``.
    """

    def __init__(self, db) -> None:
        logger.debug("Initialising orders cache...")
        self.last_cleaning_block_index = 0
        self.cache_db = database.get_db_connection(":memory:", read_only=False, check_wal=False)
        cache_cursor = self.cache_db.cursor()
        create_orders_query = """
            CREATE TABLE IF NOT EXISTS orders(
            tx_index INTEGER,
            tx_hash TEXT,
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
            status TEXT)
        """
        cache_cursor.execute(create_orders_query)
        cache_cursor.execute(
            "CREATE INDEX IF NOT EXISTS orders_expire_index_idx ON orders (tx_hash)"
        )
        cache_cursor.execute(
            "CREATE INDEX IF NOT EXISTS orders_get_asset_give_asset_idx ON orders (get_asset, give_asset, status)"
        )

        select_orders_query = """
            SELECT * FROM (
                SELECT *, MAX(rowid) FROM orders GROUP BY tx_hash
            ) WHERE status != 'expired'
        """

        with db:
            db_cursor = db.cursor()
            db_cursor.execute(select_orders_query)
            for order in db_cursor:
                self.insert_order(order)
        self.clean_filled_orders()

    def clean_filled_orders(self):
        if CurrentState().current_block_index() - self.last_cleaning_block_index < 50:
            return
        self.last_cleaning_block_index = CurrentState().current_block_index()
        cursor = self.cache_db.cursor()
        cursor.execute(
            "DELETE FROM orders WHERE status = 'filled' AND block_index < ?",
            (CurrentState().current_block_index() - 50,),
        )

    def insert_order(self, order):
        if order["block_index"] == config.MEMPOOL_BLOCK_INDEX:
            return
        sql = """
            INSERT INTO orders VALUES (
                :tx_index, :tx_hash, :block_index, :source, :give_asset, :give_quantity,
                :give_remaining, :get_asset, :get_quantity, :get_remaining, :expiration,
                :expire_index, :fee_required, :fee_required_remaining, :fee_provided,
                :fee_provided_remaining, :status
            )
        """
        cursor = self.cache_db.cursor()
        cursor.execute(sql, order)
        self.clean_filled_orders()

    def update_order(self, tx_hash, order):
        if order["status"] == "expired":
            self.cache_db.cursor().execute("DELETE FROM orders WHERE tx_hash = ?", (tx_hash,))
            return
        set_data = []
        bindings = {"tx_hash": tx_hash}
        for key, value in order.items():
            set_data.append(f"{key} = :{key}")
            bindings[key] = value
        if "block_index" not in bindings:
            set_data.append("block_index = :block_index")
        bindings["block_index"] = CurrentState().current_block_index()
        set_data = ", ".join(set_data)
        sql = f"""UPDATE orders SET {set_data} WHERE tx_hash = :tx_hash"""  # noqa S608 # nosec B608
        cursor = self.cache_db.cursor()
        cursor.execute(sql, bindings)
        self.clean_filled_orders()

    def get_matching_orders(self, tx_hash, give_asset, get_asset):
        cursor = self.cache_db.cursor()
        query = """
            SELECT *
            FROM orders
            WHERE (tx_hash != :tx_hash AND give_asset = :give_asset AND get_asset = :get_asset AND status = :status)
            ORDER BY tx_index, tx_hash
        """
        bindings = {
            "tx_hash": tx_hash,
            "give_asset": get_asset,
            "get_asset": give_asset,
            "status": "open",
        }
        cursor.execute(query, bindings)
        return cursor.fetchall()


def reset_caches():
    AssetCache.reset_instance()
    OrdersCache.reset_instance()
    UTXOBalancesCache.reset_instance()
