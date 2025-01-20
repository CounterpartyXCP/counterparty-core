import time

from counterpartycore.lib import config
from counterpartycore.lib.api import composer
from counterpartycore.lib.ledger.currentstate import CurrentState
from counterpartycore.lib.parser import blocks, check, deserialize
from counterpartycore.lib.utils import helpers, multisig

from ..fixtures.params import DEFAULT_PARAMS


class MockTransactions(metaclass=helpers.SingletonMeta):
    def __init__(self):
        self.source_by_txid = {}

    def list_unspent(self, source, allow_unconfirmed_inputs=True):
        print("list_unspent")

        construct_params = {}
        if multisig.is_multisig(source):
            signatures_required, addresses, signatures_possible = multisig.extract_array(source)
            pubkeys = [DEFAULT_PARAMS["pubkey"][addr] for addr in addresses]
            construct_params["pubkeys"] = ",".join(pubkeys)

        script_pub_key = composer.address_to_script_pub_key(source, network="regtest").to_hex()
        # deterministic txid from the source
        txid = check.dhash_string(source)
        self.source_by_txid[txid] = source
        print("TXID1:", txid)

        return [
            {
                "txid": txid,
                "vout": 0,
                "amount": int(10 * config.UNIT),
                "value": int(10 * config.UNIT),
                "script_pub_key": script_pub_key,
            }
        ]

    def get_vin_info(self, vin):
        source = self.source_by_txid[vin["hash"]]
        value = int(10 * config.UNIT)
        script_pub_key = composer.address_to_script_pub_key(source, network="regtest").to_hex()
        is_segwit = composer.is_segwit_output(script_pub_key)
        return value, script_pub_key, is_segwit


def list_unspent(source, allow_unconfirmed_inputs=True):
    return MockTransactions().list_unspent(source, allow_unconfirmed_inputs)


def get_vin_info(vin):
    return MockTransactions().get_vin_info(vin)


def satoshis_per_vbyte():
    return 2


def mine_block(db, transactions):
    block_index = CurrentState().current_block_index() + 1
    decoded_block = {
        "block_index": block_index,
        "block_time": time.time(),
        "block_hash": check.dhash_string(f"block_hash_{block_index}"),
        "hash_prev": check.dhash_string(f"block_hash_{block_index - 1}"),
        "bits": 419628831,
        "transactions": transactions,
    }
    blocks.parse_new_block(db, decoded_block)


def sendrawtransaction(db, rawtransaction):
    print("sendrawtransaction", rawtransaction)
    decoded_tx = deserialize.deserialize_tx(rawtransaction, parse_vouts=True)
    mine_block(db, [decoded_tx])
