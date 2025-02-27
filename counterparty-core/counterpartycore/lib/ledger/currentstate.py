import logging
import threading
import time
from multiprocessing import Value

from counterpartycore.lib import backend, config
from counterpartycore.lib.ledger import blocks
from counterpartycore.lib.utils import helpers
from counterpartycore.lib.utils.database import LedgerDBConnectionPool

logger = logging.getLogger(config.LOGGER_NAME)

BACKEND_HEIGHT_REFRSH_INTERVAL = 3


def get_backend_height():
    block_count = backend.bitcoind.getblockcount()
    blocks_behind = backend.bitcoind.get_blocks_behind()
    return block_count + blocks_behind


class BackendHeight(threading.Thread):
    def __init__(self):
        threading.Thread.__init__(self, name="BackendHeight")
        self.last_check = 0
        self.stop_event = threading.Event()
        self.shared_backend_height = Value("i", 0)
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
        self.shared_backend_height.value = get_backend_height()
        self.last_check = time.time()

    def stop(self):
        self.stop_event.set()
        logger.info("Stopping BackendHeight thread...")
        self.join()


class CurrentState(metaclass=helpers.SingletonMeta):
    def __init__(self):
        self.init()

    def init(self):
        self.state = {}
        self.last_update = 0

    def set(self, key, value):
        self.state[key] = value

    def get(self, key):
        return self.state.get(key)

    def set_current_block_index(self, block_index):
        self.state["CURRENT_BLOCK_INDEX"] = block_index
        if block_index:
            with LedgerDBConnectionPool().connection() as ledger_db:
                last_block = blocks.get_block(ledger_db, CurrentState().current_block_index())
            if last_block:
                self.state["CURRENT_BLOCK_TIME"] = last_block["block_time"]
            else:
                self.state["CURRENT_BLOCK_TIME"] = 0

    def set_current_tx_hash(self, tx_hash):
        self.state["CURRENT_TX_HASH"] = tx_hash

    def set_parsing_mempool(self, parsing_mempool):
        self.state["PARSING_MEMPOOL"] = parsing_mempool

    def set_block_parser_status(self, status):
        self.state["BLOCK_PARSER_STATUS"] = status

    def current_block_index(self):
        return self.state.get("CURRENT_BLOCK_INDEX")

    def current_block_time(self):
        return self.state.get("CURRENT_BLOCK_TIME")

    def set_backend_height_value(self, shared_backend_height):
        self.state["BACKEND_HEIGHT_VALUE"] = shared_backend_height

    def current_backend_height(self):
        if "BACKEND_HEIGHT_VALUE" not in self.state:
            return None
        return self.state["BACKEND_HEIGHT_VALUE"].value

    def current_tx_hash(self):
        return self.state.get("CURRENT_TX_HASH")

    def parsing_mempool(self):
        return self.state.get("PARSING_MEMPOOL")

    def block_parser_status(self):
        return self.state.get("BLOCK_PARSER_STATUS", "starting")


class ConsensusHashBuilder(metaclass=helpers.SingletonMeta):
    def __init__(self):
        self.reset()

    def append_to_block_ledger(self, item):
        self.ledger.append(item)

    def append_to_block_journal(self, item):
        self.journal.append(item)

    def block_ledger(self):
        return self.ledger

    def block_journal(self):
        return self.journal

    def reset(self):
        self.ledger = []
        self.journal = []
