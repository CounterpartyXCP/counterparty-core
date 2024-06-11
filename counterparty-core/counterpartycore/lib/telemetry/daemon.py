import threading  # noqa: I001
import time
import logging


from counterpartycore.lib.telemetry.collectors.interface import TelemetryCollectorI
from counterpartycore.lib.telemetry.clients.interface import TelemetryClientI


from counterpartycore.lib import config

DEFAULT_INTERVAL = 60

logger = logging.getLogger(config.LOGGER_NAME)


class TelemetryDaemon:
    def __init__(
        self,
        collector: TelemetryCollectorI,
        client: TelemetryClientI,
        interval=DEFAULT_INTERVAL,
    ):
        self.thread = threading.Thread(target=self._run)
        self.thread.daemon = True
        self.client = client
        self.collector = collector
        self.interval = interval  # must be greater than 0.5
        self.is_running = False

    def start(self):
        self.is_running = True
        self.thread.start()

    def _run(self):
        last_run = time.time()
        while self.is_running:
            try:
                if time.time() - last_run < self.interval:
                    time.sleep(0.5)
                    continue
                data = self.collector.collect()
                if data:
                    self.client.send(data)
                    last_run = time.time()
            except Exception as e:
                logger.error(f"Error in telemetry daemon: {e}")
                time.sleep(0.5)

    def stop(self):
        logger.info("Stopping telemetry daemon...")
        self.is_running = False
        self.collector.close()
        self.thread.join()
