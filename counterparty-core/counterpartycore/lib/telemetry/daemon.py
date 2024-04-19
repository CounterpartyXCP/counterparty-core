import threading  # noqa: I001
import time

from .collector import TelemetryCollectorI
from .client import TelemetryClientI

DEFAULT_INTERVAL = 60


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
        self.interval = interval
        self.is_running = False

    def start(self):
        self.is_running = True
        self.thread.start()

    def _run(self):
        while self.is_running:
            data = self.collector.collect()
            self.client.send(data)
            time.sleep(self.interval)

    def stop(self):
        self.is_running = False
        self.thread.join()
