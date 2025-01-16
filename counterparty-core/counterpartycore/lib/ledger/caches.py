import logging
import time

from counterpartycore.lib import config
from counterpartycore.lib.utils import helpers

logger = logging.getLogger(config.LOGGER_NAME)


class AssetCache(metaclass=helpers.SingletonMeta):
    def __init__(self, db) -> None:
        self.assets = {}
        self.assets_total_issued = {}
        self.assets_total_destroyed = {}
        self.init(db)

    def init(self, db):
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
