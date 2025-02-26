import logging
import time

from counterpartycore.lib import config
from counterpartycore.lib.monitors.telemetry.clients.influxdb import TelemetryClientInfluxDB
from counterpartycore.lib.monitors.telemetry.collectors.influxdb import (
    TelemetryCollectorInfluxDB,
)
from counterpartycore.lib.utils.database import LedgerDBConnectionPool
from counterpartycore.lib.utils.helpers import SingletonMeta
from sentry_sdk import capture_exception

logger = logging.getLogger(config.LOGGER_NAME)


class TelemetryOneShot(metaclass=SingletonMeta):
    def __init__(self):
        logger.debug("Initializing TelemetryOneShot")
        self.client = TelemetryClientInfluxDB()

    def send(self, data, retry=0):
        try:
            self.client.send(data)
        except Exception as e:  # pylint: disable=broad-except
            if retry < 10:
                logger.trace(f"Error in telemetry one shot: {e}. Retrying in 2 seconds...")
                time.sleep(2)
                self.send(data, retry=retry + 1)
            else:
                raise e

    def submit(self):
        try:
            with LedgerDBConnectionPool().connection() as ledger_db:
                collector = TelemetryCollectorInfluxDB(db=ledger_db)
                data = collector.collect()
                collector.close()
            if data:
                self.send(data)
        except Exception as e:  # pylint: disable=broad-except
            capture_exception(e)
            logger.warning("Error in telemetry one shot: %s", e)
