from counterpartycore.lib import config, blocks, ledger  # noqa: I001, F401


class TelemetryCollectorI:
    def collect(self):
        raise NotImplementedError()

    def close(self):
        raise NotImplementedError()
