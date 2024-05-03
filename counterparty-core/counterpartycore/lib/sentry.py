import os

import sentry_sdk

from counterpartycore.lib import config, database
from counterpartycore.lib.telemetry.collector import TelemetryCollectorLive

environment = os.environ.get("SENTRY_ENVIRONMENT", "development")

release = os.environ.get("SENTRY_RELEASE", config.__version__)

EXCLUDED_URL = ["/healthz"]


def before_send(event, _hint):
    db = database.get_connection(read_only=True)
    data = TelemetryCollectorLive(db).collect()
    db.close()

    event["tags"] = event.get("tags", {})

    event["tags"]["core_version"] = data["version"]
    event["tags"]["addrindexrs_version"] = data["addrindexrs_version"]
    event["tags"]["docker"] = data["docker"]
    event["tags"]["network"] = data["network"]
    event["tags"]["force_enabled"] = data["force_enabled"]

    event["extra"] = event.get("extra", {})
    event["extra"]["last_block"] = data["last_block"]

    return event


def filter_transactions(event, _hint):
    if "transaction" not in event:
        return event
    if "request" not in event:
        return event
    for excluded in EXCLUDED_URL:
        if excluded in event["request"]["url"]:
            return None
    return event


def init():
    # No-op if SENTRY_DSN is not set
    if not os.environ.get("SENTRY_DSN"):
        return

    sentry_sdk.init(
        dsn=os.environ.get("SENTRY_DSN"),
        environment=environment,
        release=release,
        traces_sample_rate=1.0,
        before_send=before_send,
        before_send_transaction=filter_transactions,
    )
