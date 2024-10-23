import influxdb_client
from influxdb_client.client.write_api import SYNCHRONOUS

from counterpartycore.lib import config
from counterpartycore.lib.telemetry.util import ID

from .interface import TelemetryClientI


class TelemetryClientInfluxDB(TelemetryClientI):
    def __init__(self):
        # UUID for life of process

        self.__id = ID().id

        self.__influxdb_client = influxdb_client.InfluxDBClient(
            url=config.INFLUX_DB_URL,
            token=config.INFLUX_DB_TOKEN,
            org=config.INFLUX_DB_ORG,
        )

        self.__write_api = self.__influxdb_client.write_api(write_options=SYNCHRONOUS)

    def send(self, data):
        assert data["__influxdb"]

        tags = data["__influxdb"]["tags"]
        fields = data["__influxdb"]["fields"]

        point = influxdb_client.Point("node-heartbeat")

        point.tag("id", self.__id)

        for tag in tags:
            point.tag(tag, data[tag])

        for field in fields:
            point.field(field, data[field])

        self.__write_api.write(
            bucket=config.INFLUX_DB_BUCKET, org=config.INFLUX_DB_ORG, record=point
        )
