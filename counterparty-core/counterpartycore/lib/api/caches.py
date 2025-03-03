import logging
import time

from counterpartycore.lib import config
from counterpartycore.lib.utils import database, helpers

logger = logging.getLogger(config.LOGGER_NAME)


class AddressEventsCache(metaclass=helpers.SingletonMeta):
    def __init__(self) -> None:
        start_time = time.time()
        logger.debug("Initialising address events cache...")
        self.cache_db = database.get_db_connection(":memory:", read_only=False, check_wal=False)
        self.cache_db.execute("ATTACH DATABASE ? AS state_db", (config.STATE_DATABASE,))
        self.cache_db.execute("""
            CREATE TABLE address_events (
                address TEXT,
                event_index INTEGER
            );
            INSERT INTO address_events (address, event_index) SELECT address, event_index FROM state_db.address_events;
            CREATE INDEX address_events_address_idx ON address_events (address);
            CREATE INDEX address_events_event_index_idx ON address_events (event_index);
        """)

        duration = time.time() - start_time
        logger.debug("Address events cache initialised in %.2f seconds", duration)

    def insert(self, address, event_index):
        self.cache_db.execute("INSERT INTO address_events VALUES (?, ?)", (address, event_index))
