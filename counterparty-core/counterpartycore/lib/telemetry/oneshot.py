import logging

from counterpartycore.lib import config
from counterpartycore.lib.telemetry.clients.interface import TelemetryClientI
from counterpartycore.lib.telemetry.collectors.interface import TelemetryCollectorI

DEFAULT_INTERVAL = 60
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
        data = self.collector.collect()
        if data:
            self.client.send(data)
