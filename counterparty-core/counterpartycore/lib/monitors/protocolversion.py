"""Refresh upgrade metadata independently of parsing and API requests."""

import logging
import threading

from counterpartycore.lib import config, exceptions
from counterpartycore.lib.ledger.currentstate import CurrentState
from counterpartycore.lib.parser import check
from counterpartycore.lib.utils import protocolstatus

logger = logging.getLogger(config.LOGGER_NAME)


class ProtocolVersionMonitor(threading.Thread):
    def __init__(self):
        super().__init__(name="ProtocolVersionMonitor", daemon=True)
        self.stop_event = threading.Event()
        self.last_warning = None

    def refresh(self):
        try:
            check.software_version(enforce=False)
            height = CurrentState().current_block_count() or CurrentState().current_block_index()
            status = protocolstatus.summary(height)
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
            state = protocolstatus.current()
            if state is not None:
                try:
                    state.unavailable()
                except exceptions.VersionCheckError:
                    # A broken shared-state lock is already exposed as unknown
                    # by its readers. Keep the monitor alive to retry.
                    logger.error("Could not publish protocol metadata failure")
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
