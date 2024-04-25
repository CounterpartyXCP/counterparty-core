from .base import TelemetryCollectorBase


class TelemetryCollectorInfluxDB(TelemetryCollectorBase):
    def collect(self):
        data = super().collect()

        data["__influxdb"] = {
            "tags": [
                "version",
                "addrindexrs_version",
                "dockerized",
                "network",
                "force_enabled",
            ],
            "fields": ["uptime"],
        }

        return data
        # Collect data and send to InfluxDB
