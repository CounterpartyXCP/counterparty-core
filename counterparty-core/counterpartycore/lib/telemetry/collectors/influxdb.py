from .base import TelemetryCollectorBase


class TelemetryCollectorInfluxDB(TelemetryCollectorBase):
    def collect(self):
        data = super().collect()

        data = data | data["last_block"]

        if data is None:
            return None

        data["__influxdb"] = {
            "tags": [],
            "fields": [
                "network",
                "platform",
                "force_enabled",
                "dockerized",
                "version",
                "uptime",
                "block_hash",
                "block_index",
                "ledger_hash",
                "txlist_hash",
                "messages_hash",
            ],
        }

        return data
        # Collect data and send to InfluxDB
