import logging
import os

import counterpartycore.lib.monitors.telemetry.util as util
from counterpartycore.lib import config, ledger
from counterpartycore.lib.monitors.telemetry.collectors.interface import TelemetryCollectorI

logger = logging.getLogger(config.LOGGER_NAME)


# DEFAULT IMPLEMENTATION
class TelemetryCollectorKwargs(TelemetryCollectorI):
    def __init__(self, **kwargs):
        self.static_attrs = kwargs

    def collect(self):
        return self.static_attrs


class TelemetryCollectorBase(TelemetryCollectorKwargs):
    def __init__(self, db, **kwargs):
        super().__init__(**kwargs)
        self.db = db

    def collect(self):
        version = util.get_version()
        uptime = util.get_uptime()
        is_docker = util.is_docker()
        network = util.get_network()
        force_enabled = util.is_force_enabled()
        platform = util.get_system()

        block_index = ledger.events.last_message(self.db)["block_index"]
        cursor = self.db.cursor()
        last_block = cursor.execute(
            "SELECT * FROM blocks where block_index = ?", [block_index]
        ).fetchone()

        if not last_block:
            return None

        return {
            "version": version,
            "uptime": int(uptime),
            "dockerized": is_docker,
            "network": network,
            "force_enabled": force_enabled,
            "platform": platform,
            "last_block": last_block,
            **self.static_attrs,
        }

    def is_running_in_docker(self):
        """
        Checks if the current process is running inside a Docker container.
        Returns:
            bool: True if running inside a Docker container, False otherwise.
        """
        return (
            os.path.exists("/.dockerenv")
            or "DOCKER_HOST" in os.environ
            or "KUBERNETES_SERVICE_HOST" in os.environ
        )

    def close(self):
        pass
