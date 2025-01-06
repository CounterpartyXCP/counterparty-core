from counterparty_rs import indexer

from counterpartycore.lib import config, util


def deserialize_tx(tx_hex, use_txid, parse_vouts=False, block_index=None):
    deserializer = indexer.Deserializer(
        {
            "rpc_address": "",
            "rpc_user": "",
            "rpc_password": "",
            "network": config.NETWORK_NAME,
            "db_dir": "",
            "log_file": "",
            "prefix": config.PREFIX,
        }
    )
    return deserializer.parse_transaction(
        tx_hex, block_index or util.CURRENT_BLOCK_INDEX, parse_vouts, use_txid
    )


def deserialize_block(block_hex, use_txid, parse_vouts=False, block_index=None):
    # block_hex = ("00" * 8) + block_hex  # fake magic bytes and block size
    deserializer = indexer.Deserializer(
        {
            "rpc_address": "",
            "rpc_user": "",
            "rpc_password": "",
            "network": config.NETWORK_NAME,
            "db_dir": "",
            "log_file": "",
            "prefix": config.PREFIX,
        }
    )
    return deserializer.parse_block(
        block_hex, block_index or util.CURRENT_BLOCK_INDEX, parse_vouts, use_txid
    )
