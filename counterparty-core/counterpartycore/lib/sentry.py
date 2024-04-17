import os

import sentry_sdk

from counterpartycore.lib import config, database
from counterpartycore.lib.telemetry.collector import TelemetryCollectorLive


def send_exception(exception):
    sentry_sdk.capture_exception(exception)


environment = os.environ.get("SENTRY_ENVIRONMENT", "development")

release = os.environ.get("SENTRY_RELEASE", config.__version__)


def before_send(event, _hint):
    db = database.get_connection(read_only=True)

    data = TelemetryCollectorLive(db).collect()

    event["tags"] = event.get("tags", {})

    event["tags"]["core_version"] = data["version"]
    event["tags"]["addrindexrs_version"] = data["addrindexrs_version"]
    event["tags"]["docker"] = data["is_docker_process"]
    event["tags"]["network"] = data["network"]
    event["tags"]["force_enabled"] = data["force_enabled"]

    event["extra"] = event.get("extra", {})
    event["extra"]["last_block"] = data["last_block"]

    return event


sentry_sdk.init(
    dsn=os.environ.get("SENTRY_DSN"),
    environment=environment,
    release=release,
    traces_sample_rate=1.0,
    before_send=before_send,
)
