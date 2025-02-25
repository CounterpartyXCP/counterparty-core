import logging
import time

from counterpartycore.lib import config
from counterpartycore.lib.ledger.currentstate import CurrentState
from counterpartycore.lib.utils import database, helpers

logger = logging.getLogger(config.LOGGER_NAME)


class AssetCache(metaclass=helpers.SingletonMeta):
    def __init__(self, db) -> None:
        self.assets = {}
        self.assets_total_issued = {}
        self.assets_total_destroyed = {}
        start = time.time()
        logger.debug("Initialising asset cache...")
        # asset info
        sql = """
            SELECT *, MAX(rowid) AS rowid FROM issuances
            WHERE status = 'valid'
            GROUP BY asset
        """
        cursor = db.cursor()
        all_assets = cursor.execute(sql)
        self.assets = {}
        for asset in all_assets:
            del asset["rowid"]
            if asset["asset_longname"] is not None:
                self.assets[asset["asset_longname"]] = asset
            self.assets[asset["asset"]] = asset
        duration = time.time() - start
        # asset total issued
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
        # asset total destroyed
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

        logger.debug(f"Asset cache initialised in {duration:.2f} seconds")

    def add_issuance(self, issuance):
        if "rowid" in issuance:
            del issuance["rowid"]
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
        if destroyed["quantity"] is not None:
            if destroyed["asset"] in self.assets_total_destroyed:
                self.assets_total_destroyed[destroyed["asset"]] += destroyed["quantity"]
            else:
                self.assets_total_destroyed[destroyed["asset"]] = destroyed["quantity"]


class UTXOBalancesCache(metaclass=helpers.SingletonMeta):
    def __init__(self, db):
        logger.debug("Initialising utxo balances cache...")
        sql = "SELECT utxo, asset, quantity, MAX(rowid) FROM balances WHERE utxo IS NOT NULL GROUP BY utxo, asset"
        cursor = db.cursor()
        cursor.execute(sql)
        utxo_balances = cursor.fetchall()
        self.utxos_with_balance = {}
        for utxo_balance in utxo_balances:
            self.utxos_with_balance[utxo_balance["utxo"]] = True

    def has_balance(self, utxo):
        return utxo in self.utxos_with_balance

    def add_balance(self, utxo):
        self.utxos_with_balance[utxo] = True

    def remove_balance(self, utxo):
        self.utxos_with_balance.pop(utxo, None)


class OrdersCache(metaclass=helpers.SingletonMeta):
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
