import logging
import os

import sentry_sdk

from counterpartycore.lib import config, database
from counterpartycore.lib.telemetry.collectors.base import TelemetryCollectorBase

logger = logging.getLogger(config.LOGGER_NAME)

environment = os.environ.get("SENTRY_ENVIRONMENT", "development")
release = os.environ.get("SENTRY_RELEASE", config.__version__)


def before_send(event, _hint):
    db = database.get_connection(read_only=True)
    data = TelemetryCollectorBase(db).collect()
    db.close()

    event["tags"] = event.get("tags", [])

    event["tags"].append(["core_version", data["version"]])
    event["tags"].append(["addrindexrs_version", data["addrindexrs_version"]])
    event["tags"].append(["docker", data["dockerized"]])
    event["tags"].append(["network", data["network"]])
    event["tags"].append(["force_enabled", data["force_enabled"]])

    event["extra"] = event.get("extra", {})
    event["extra"]["last_block"] = data["last_block"]

    return event


def init():
    dsn = os.environ.get("SENTRY_DSN")
    # No-op if SENTRY_DSN is not set
    if not dsn:
        return

    logger.info(f"Initializing Sentry with {dsn}...")

    sentry_sdk.init(
        dsn=dsn,
        environment=environment,
        release=release,
        traces_sample_rate=1.0,
        before_send=before_send,
    )
