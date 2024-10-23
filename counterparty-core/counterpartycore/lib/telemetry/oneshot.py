import logging

from sentry_sdk import capture_exception

from counterpartycore.lib import config, database
from counterpartycore.lib.telemetry.clients.influxdb import TelemetryClientInfluxDB
from counterpartycore.lib.telemetry.collectors.influxdb import (
    TelemetryCollectorInfluxDB,
)
from counterpartycore.lib.util import SingletonMeta

logger = logging.getLogger(config.LOGGER_NAME)


class TelemetryOneShot(metaclass=SingletonMeta):
    def __init__(self):
        logger.debug("Initializing TelemetryOneShot")
        self.db = database.get_connection(read_only=True)
        self.collector = TelemetryCollectorInfluxDB(db=self.db)
        self.client = TelemetryClientInfluxDB()

    def submit(self):
        try:
            data = self.collector.collect()
            if data:
                self.client.send(data)
        except Exception as e:
            capture_exception(e)
            logger.warning(f"Error in telemetry one shot: {e}")

    def close(self):
        self.db.close()
        self.db = None
        self.collector.close()
        self.collector = None
        self.client = None

    @classmethod
    def close_instance(cls):
        instance = SingletonMeta._instances.get(cls)
        if instance:
            instance.close()
            del SingletonMeta._instances[cls]
