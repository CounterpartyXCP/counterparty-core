import logging
import os

import sentry_sdk

from counterpartycore.lib import config, database
from counterpartycore.lib.tools.telemetry.collectors.base import TelemetryCollectorBase

logger = logging.getLogger(config.LOGGER_NAME)

environment = os.environ.get("SENTRY_ENVIRONMENT", "development")
release = os.environ.get("SENTRY_RELEASE", config.__version__)


def before_send(event, _hint):
    db = database.get_connection(read_only=True)
    data = TelemetryCollectorBase(db).collect()
    db.close()

    event["tags"] = event.get("tags", [])

    event["tags"].append(["core_version", data["version"]])
    event["tags"].append(["docker", data["dockerized"]])
    event["tags"].append(["network", data["network"]])
    event["tags"].append(["force_enabled", data["force_enabled"]])

    event["extra"] = event.get("extra", {})
    event["extra"]["last_block"] = data["last_block"]

    return event


def before_send_transaction(event, _hint):
    if event.get("transaction") == "RedirectToRpcV1":
        return None
    return event


def init():
    dsn = os.environ.get("SENTRY_DSN")
    # No-op if SENTRY_DSN is not set
    if not dsn:
        return

    sample_rate = float(os.environ.get("SENTRY_SAMPLE_RATE", 0.01))

    logger.info(f"Initializing Sentry with {dsn} and sample rate of {sample_rate}...")

    sentry_sdk.init(
        dsn=dsn,
        environment=environment,
        release=release,
        traces_sample_rate=sample_rate,
        before_send=before_send,
        before_send_transaction=before_send_transaction,
    )
