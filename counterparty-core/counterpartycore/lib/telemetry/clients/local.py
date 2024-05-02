import logging

from interface import TelemetryClientI

# IMPLEMENTATIONS


class TelemetryClientLocal(TelemetryClientI):
    def __init__(self):
        self.logger = logging.getLogger(__name__)

    def send(self, data):
        self.logger.info(data)
