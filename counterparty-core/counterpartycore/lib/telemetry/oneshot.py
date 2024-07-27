import logging

from counterpartycore.lib import config, database
from counterpartycore.lib.telemetry.clients.influxdb import TelemetryClientInfluxDB
from counterpartycore.lib.telemetry.collectors.influxdb import (
    TelemetryCollectorInfluxDB,
)
from counterpartycore.lib.util import SingletonMeta
from sentry_sdk import capture_exception

logger = logging.getLogger(config.LOGGER_NAME)


class TelemetryOneShot(metaclass=SingletonMeta):
    def __init__(self):
        self.db = (database.get_connection(read_only=True),)
        self.collector = TelemetryCollectorInfluxDB(db=self.db)
        self.client = TelemetryClientInfluxDB()

    def submit(self):
        try:
            data = self.collector.collect()
            if data:
                self.client.send(data)
        except Exception as e:
            capture_exception(e)
            logger.error(f"Error in telemetry one shot: {e}")

    def close(self):
        self.db.close()
        self.db = None
        self.collector.close()
        self.collector = None
        self.client = None
