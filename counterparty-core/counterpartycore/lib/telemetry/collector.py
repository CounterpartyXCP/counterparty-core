# INTERFACE
from counterpartycore.lib import config, blocks, ledger  # noqa: I001, F401
import os
import time


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
        self.start_time = time.time()

    def collect(self):
        version = config.__version__
        addrindexrs_version = config.ADDRINDEXRS_VERSION
        uptime = time.time() - self.start_time
        is_docker_process = self.is_running_in_docker()
        network = "TESTNET" if self.__read_config_with_default("TESTNET", False) else "MAINNET"

        force_enabled = self.__read_config_with_default("FORCE", False)

        block_index = ledger.last_message(self.db)["block_index"]

        cursor = self.db.cursor()
        last_block = cursor.execute(
            "SELECT * FROM blocks where block_index = ?", [block_index]
        ).fetchone()

        return {
            "version": version,
            "addrindexrs_version": addrindexrs_version,
            "uptime": f"{uptime:.2f}",
            "is_docker_process": is_docker_process,
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
