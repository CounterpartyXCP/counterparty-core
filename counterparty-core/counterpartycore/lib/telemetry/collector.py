# INTERFACE
from counterpartycore.lib import config, blocks, ledger  # noqa: I001, F401
import os

import counterpartycore.lib.telemetry.util as util


class TelemetryCollectorI:
    def collect(self):
        raise NotImplementedError()


# DEFAULT IMPLEMENTATION
class TelemetryCollectorBase(TelemetryCollectorI):
    def __init__(self, **kwargs):
        self.static_attrs = kwargs

    def collect(self):
        return self.static_attrs


class TelemetryCollectorLive(TelemetryCollectorBase):
    def __init__(self, db, **kwargs):
        super().__init__(**kwargs)
        self.db = db

    def collect(self):
        version = util.get_version()
        addrindexrs_version = util.get_addrindexrs_version()
        uptime = util.get_uptime()
        is_docker = util.is_docker()
        network = util.get_network()
        force_enabled = util.is_force_enabled()

        block_index = ledger.last_message(self.db)["block_index"]
        cursor = self.db.cursor()
        last_block = cursor.execute(
            "SELECT * FROM blocks where block_index = ?", [block_index]
        ).fetchone()

        return {
            "version": version,
            "addrindexrs_version": addrindexrs_version,
            "uptime": f"{uptime:.2f}",
            "docker": is_docker,
            "network": network,
            "force_enabled": force_enabled,
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

    def __read_config_with_default(self, key, default):
        return getattr(config, key, default)
