import logging

from counterpartycore.lib import config
from counterpartycore.lib.telemetry.clients.interface import TelemetryClientI
from counterpartycore.lib.telemetry.collectors.interface import TelemetryCollectorI

logger = logging.getLogger(config.LOGGER_NAME)


class TelemetryOneShot:
    def __init__(
        self,
        collector: TelemetryCollectorI,
        client: TelemetryClientI,
    ):
        self.client = client
        self.collector = collector

    def submit(self):
        try:
            data = self.collector.collect()
            if data:
                self.client.send(data)
        except Exception as e:
            logger.error(f"Error in telemetry one shot: {e}")
