import os
import time
from uuid import uuid4

from counterpartycore.lib import config

start_time = time.time()


def get_version():
    return config.__version__


def get_addrindexrs_version():
    return config.ADDRINDEXRS_VERSION


def get_uptime():
    return time.time() - start_time


def is_docker():
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


def get_network():
    return "TESTNET" if __read_config_with_default("TESTNET", False) else "MAINNET"


def is_force_enabled():
    return __read_config_with_default("FORCE", False)


def __read_config_with_default(key, default):
    return getattr(config, key, default)


TELEMETRY_FILE_PATH = ".counterparty-node-uuid"


class ID:
    def __init__(self):
        # if file exists, read id from file
        # else create new id and write to file
        id = None
        if os.path.exists(TELEMETRY_FILE_PATH):
            with open(TELEMETRY_FILE_PATH, "r") as f:
                id = f.read()
        else:
            id = str(uuid4())
            with open(TELEMETRY_FILE_PATH, "w") as f:
                f.write(id)

        self.id = id
