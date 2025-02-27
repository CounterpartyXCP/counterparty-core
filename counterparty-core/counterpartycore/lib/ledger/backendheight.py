import ctypes
import logging
import threading
import time
from multiprocessing import Value

from counterpartycore.lib import backend, config

logger = logging.getLogger(config.LOGGER_NAME)

BACKEND_HEIGHT_REFRSH_INTERVAL = 3


class BackendHeight(threading.Thread):
    def __init__(self):
        threading.Thread.__init__(self, name="BackendHeight")
        self.last_check = 0
        self.stop_event = threading.Event()
        self.shared_backend_height = Value(ctypes.c_ulong, 0)
        self.refresh()

    def run(self):
        if config.API_ONLY:
            return
        try:
            while not self.stop_event.is_set():
                if time.time() - self.last_check > BACKEND_HEIGHT_REFRSH_INTERVAL:
                    self.refresh()
                self.stop_event.wait(0.1)
        finally:
            logger.info("BackendHeight Thread stopped.")

    def refresh(self):
        if config.API_ONLY:
            return
        logger.trace("Updating backend height...")
        tip = backend.bitcoind.get_chain_tip()
        block_count = backend.bitcoind.getblockcount()
        value = int(tip * 10e8 + block_count)  # let use only one shared value
        self.shared_backend_height.value = value
        self.last_check = time.time()

    def stop(self):
        self.stop_event.set()
        logger.info("Stopping BackendHeight thread...")
        self.join()
