from counterparty_rs import indexer  # pylint: disable=no-name-in-module

from counterpartycore.lib import config
from counterpartycore.lib.ledger.currentstate import CurrentState
from counterpartycore.lib.utils.helpers import SingletonMeta


class Deserializer(metaclass=SingletonMeta):
    def __init__(self):
        rpc_address = f"://{config.BACKEND_CONNECT}:{config.BACKEND_PORT}"
        if config.BACKEND_SSL:
            rpc_address = f"https{rpc_address}"
        else:
            rpc_address = f"http{rpc_address}"
        self.deserializer = indexer.Deserializer(
            {
                "rpc_address": rpc_address,
                "rpc_user": config.BACKEND_USER,
                "rpc_password": config.BACKEND_PASSWORD,
                "db_dir": config.FETCHER_DB,
                "log_file": config.FETCHER_LOG,
                "json_format": config.JSON_LOGS,
                "only_write_in_reorg_window": True,
                "network": config.NETWORK_NAME,
                "prefix": config.PREFIX,
                "enable_all_protocol_changes": config.ENABLE_ALL_PROTOCOL_CHANGES,
            }
        )

    def parse_transaction(self, tx_hex, block_index, parse_vouts=False):
        return self.deserializer.parse_transaction(tx_hex, block_index, parse_vouts)

    def parse_block(self, block_hex, block_index, parse_vouts=False):
        return self.deserializer.parse_block(block_hex, block_index, parse_vouts)


def deserialize_tx(tx_hex, parse_vouts=False, block_index=None):
    current_block_index = block_index or CurrentState().current_block_index()
    decoded_tx = Deserializer().parse_transaction(tx_hex, current_block_index, parse_vouts)
    return decoded_tx


def deserialize_block(block_hex, parse_vouts=False, block_index=None):
    current_block_index = block_index or CurrentState().current_block_index()
    decoded_block = Deserializer().parse_block(block_hex, current_block_index, parse_vouts)
    return decoded_block
