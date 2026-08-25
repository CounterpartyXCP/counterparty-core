import logging
import time

from counterpartycore.lib import config
from counterpartycore.lib.ledger import blocks
from counterpartycore.lib.utils import helpers
from counterpartycore.lib.utils.database import (
    LedgerDBConnectionPool,
    get_config_value,
    set_config_value,
)

logger = logging.getLogger(config.LOGGER_NAME)


class CurrentState(metaclass=helpers.SingletonMeta):
    def __init__(self):
        self.init()

    def init(self):
        self.state = {
            "CATCHING_UP": False,
        }
        self.last_update = 0

    def set(self, key, value):
        self.state[key] = value

    def get(self, key):
        return self.state.get(key)

    def set_current_block_index(self, block_index, skip_lock_time=False):
        self.state["CURRENT_BLOCK_INDEX"] = block_index
        if block_index and not skip_lock_time:
            with LedgerDBConnectionPool().connection() as ledger_db:
                last_block = blocks.get_block(ledger_db, CurrentState().current_block_index())
            if last_block:
                self.state["CURRENT_BLOCK_TIME"] = last_block["block_time"]
            else:
                self.state["CURRENT_BLOCK_TIME"] = 0

    def set_current_tx_hash(self, tx_hash, tx_index=None):
        self.state["CURRENT_TX_HASH"] = tx_hash
        # Keep the matching tx_index in lockstep so ``add_to_journal`` can stamp
        # ``messages.tx_index`` without re-querying ``transactions`` for every
        # event. ``None`` (block-level events) clears it.
        self.state["CURRENT_TX_INDEX"] = tx_index

    def set_parsing_mempool(self, parsing_mempool):
        self.state["PARSING_MEMPOOL"] = parsing_mempool

    def set_ledger_state(self, ledger_db, status):
        # use db to share Ledger state with other processes
        self.state["CATCHING_UP"] = status == "Catching Up"
        set_config_value(ledger_db, "LEDGER_STATE", status)

    def current_block_index(self):
        return self.state.get("CURRENT_BLOCK_INDEX")

    def current_block_time(self):
        return self.state.get("CURRENT_BLOCK_TIME")

    def set_backend_height_value(self, shared_backend_height):
        self.state["BACKEND_HEIGHT_VALUE"] = shared_backend_height

    def current_backend_height(self):
        if "BACKEND_HEIGHT_VALUE" not in self.state:
            return None
        return int(self.state["BACKEND_HEIGHT_VALUE"].value // 10e8)

    def current_block_count(self):
        if "BACKEND_HEIGHT_VALUE" not in self.state:
            return None
        return int(self.state["BACKEND_HEIGHT_VALUE"].value % 10e8)

    def current_tx_hash(self):
        return self.state.get("CURRENT_TX_HASH")

    def current_tx_index(self):
        return self.state.get("CURRENT_TX_INDEX")

    def parsing_mempool(self):
        return self.state.get("PARSING_MEMPOOL")

    def ledger_state(self):
        with LedgerDBConnectionPool().connection() as ledger_db:
            return get_config_value(ledger_db, "LEDGER_STATE") or "Starting"

    def set_stopping(self):
        self.state["STOPPING"] = True

    def stopping(self):
        return self.state.get("STOPPING", False)

    def set_state_db_rebuilding(self, rebuilding):
        shared_value = self.state.get("STATE_DB_REBUILDING_VALUE")
        shared_started_at = self.state.get("STATE_DB_REBUILD_STARTED_AT_VALUE")
        shared_cache_cold = self.state.get("STATE_DB_REBUILD_CACHE_COLD_VALUE")
        if shared_value is not None:
            if rebuilding:
                if not shared_value.value or not shared_started_at.value:
                    shared_started_at.value = time.time()
                shared_value.value = True
            else:
                shared_value.value = False
                shared_started_at.value = 0.0
                if shared_cache_cold is not None:
                    shared_cache_cold.value = False
        else:
            if rebuilding:
                if not self.state.get("STATE_DB_REBUILDING", False):
                    self.state["STATE_DB_REBUILD_STARTED_AT"] = time.time()
                self.state["STATE_DB_REBUILDING"] = True
            else:
                self.state["STATE_DB_REBUILDING"] = False
                self.state["STATE_DB_REBUILD_STARTED_AT"] = 0.0

    def set_state_db_rebuild_shared_values(
        self,
        rebuilding_value,
        started_at_value,
        cache_cold_value=None,
    ):
        self.state["STATE_DB_REBUILDING_VALUE"] = rebuilding_value
        self.state["STATE_DB_REBUILD_STARTED_AT_VALUE"] = started_at_value
        self.state["STATE_DB_REBUILD_CACHE_COLD_VALUE"] = cache_cold_value

    def state_db_rebuilding(self):
        shared_value = self.state.get("STATE_DB_REBUILDING_VALUE")
        if shared_value is not None:
            return bool(shared_value.value)
        return self.state.get("STATE_DB_REBUILDING", False)

    def state_db_rebuild_age(self):
        shared_started_at = self.state.get("STATE_DB_REBUILD_STARTED_AT_VALUE")
        started_at = (
            shared_started_at.value
            if shared_started_at is not None
            else self.state.get("STATE_DB_REBUILD_STARTED_AT", 0.0)
        )
        return max(0.0, time.time() - started_at) if started_at else 0.0

    def state_db_rebuild_cache_cold(self):
        shared_cache_cold = self.state.get("STATE_DB_REBUILD_CACHE_COLD_VALUE")
        return bool(shared_cache_cold.value) if shared_cache_cold is not None else False


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
