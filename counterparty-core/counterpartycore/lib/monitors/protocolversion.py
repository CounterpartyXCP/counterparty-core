"""Refresh upgrade metadata independently of parsing and API requests."""

import logging
import threading

from counterpartycore.lib import config, exceptions
from counterpartycore.lib.parser import check
from counterpartycore.lib.utils import protocolstatus

logger = logging.getLogger(config.LOGGER_NAME)


class ProtocolVersionMonitor(threading.Thread):
    def __init__(self):
        super().__init__(name="ProtocolVersionMonitor", daemon=True)
        self.stop_event = threading.Event()
        self.last_warning = None

    def refresh(self, *, required=False):
        try:
            check.software_version(enforce=False)
            status = protocolstatus.summary()
            warning = (status["status"], status["required_version"], status["activation_height"])
            if (
                status["status"] in ("upgrade_pending", "incompatible")
                and warning != self.last_warning
            ):
                logger.warning(
                    "Protocol status %s: v%s required at block %s (%s)",
                    *warning,
                    status["change_name"],
                )
                self.last_warning = warning
            return protocolstatus.CHECK_INTERVAL
        except exceptions.VersionCheckError as error:
            if required:
                raise
            logger.warning(
                "Protocol metadata refresh failed; retaining cached requirements: %s", error
            )
            return protocolstatus.RETRY_INTERVAL

    def run(self):
        delay = protocolstatus.CHECK_INTERVAL
        state = protocolstatus.current()
        if state is not None and not (state.read() or {}).get("last_successful_check"):
            delay = 0
        while not self.stop_event.wait(delay):
            delay = self.refresh()

    def stop(self):
        self.stop_event.set()
        if self.is_alive():
            self.join(timeout=1)
