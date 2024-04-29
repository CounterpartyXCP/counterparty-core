from .base import TelemetryCollectorBase


class TelemetryCollectorInfluxDB(TelemetryCollectorBase):
    def collect(self):
        data = super().collect()

        data["__influxdb"] = {
            "tags": [],
            "fields": [
                "network",
                "force_enabled",
                "dockerized",
                "addrindexrs_version",
                "version",
                "uptime",
                "block_hash",
                "block_index",
                "ledger_hash",
                "txlist_hash",
                "messages_hash",
            ],
        }

        data["version"] = "10.1.3"

        return data
        # Collect data and send to InfluxDB
