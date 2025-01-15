import time

from flask import request

from counterpartycore.lib import backend, ledger
from counterpartycore.lib.utils import helpers
from counterpartycore.lib.utils.database import LedgerDBConnectionPool

BACKEND_HEIGHT_REFRSH_INTERVAL = 3


def get_backend_height():
    # TODO: find a way to mock this function for testing
    try:
        if request.url_root == "http://localhost:10009/":
            return 0
    except RuntimeError:
        pass

    block_count = backend.bitcoind.getblockcount()
    blocks_behind = backend.bitcoind.get_blocks_behind()
    return block_count + blocks_behind


class CurrentState(metaclass=helpers.SingletonMeta):
    def __init__(self):
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
                last_block = ledger.ledger.get_block(
                    ledger_db, CurrentState().current_block_index()
                )
            if last_block:
                self.state["CURRENT_BLOCK_TIME"] = last_block["block_time"]
            else:
                self.state["CURRENT_BLOCK_TIME"] = 0

    def current_block_index(self):
        return self.state.get("CURRENT_BLOCK_INDEX")

    def current_block_time(self):
        return self.state.get("CURRENT_BLOCK_TIME")

    def current_backend_height(self):
        if time.time() - self.last_update >= BACKEND_HEIGHT_REFRSH_INTERVAL:
            self.backend_height = get_backend_height()
            self.last_update = time.time()
        return self.backend_height
