class TelemetryCollectorI:
    def collect(self):
        raise NotImplementedError()

    def close(self):
        raise NotImplementedError()
