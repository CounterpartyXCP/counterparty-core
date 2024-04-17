import logging


# INTERFACE
class TelemetryClientI:
    def send(self, data):
        raise NotImplementedError()


# IMPLEMENTATIONS
class TelemetryClientLocal(TelemetryClientI):
    def __init__(self):
        self.logger = logging.getLogger(__name__)

    def send(self, data):
        self.logger.info(data)
