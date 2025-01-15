from counterpartycore.lib.utils import helpers


class CurrentState(metaclass=helpers.SingletonMeta):
    def __init__(self):
        self.state = {}

    def set(self, key, value):
        self.state[key] = value

    def get(self, key):
        return self.state.get(key)

    def set_current_block_index(self, block_index):
        self.state["CURRENT_BLOCK_INDEX"] = block_index

    def current_block_index(self):
        return self.state.get("CURRENT_BLOCK_INDEX")
