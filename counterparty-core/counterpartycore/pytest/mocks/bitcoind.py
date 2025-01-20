import sys
import time

import pytest
from counterpartycore.lib import config
from counterpartycore.lib.api import composer
from counterpartycore.lib.ledger.currentstate import CurrentState
from counterpartycore.lib.parser import blocks, check, deserialize
from counterpartycore.lib.utils import helpers, multisig, script

from ..fixtures.params import DEFAULT_PARAMS


class MockTransactions(metaclass=helpers.SingletonMeta):
    def __init__(self):
        self.source_by_txid = {}

    def list_unspent(self, source, allow_unconfirmed_inputs=True):
        construct_params = {}
        if multisig.is_multisig(source):
            _signatures_required, addresses, _signatures_possible = multisig.extract_array(source)
            pubkeys = [DEFAULT_PARAMS["pubkey"][addr] for addr in addresses]
            construct_params["pubkeys"] = ",".join(pubkeys)

        script_pub_key = composer.address_to_script_pub_key(source, network="regtest").to_hex()
        print("script_pub_key:", script_pub_key)
        print("asm", script.script_to_asm(script_pub_key))

        # deterministic txid from the source
        txid = check.dhash_string(f"{source}{list(self.source_by_txid.values()).count(source)}")
        self.source_by_txid[txid] = source
        print("New txid:", txid)

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


def mine_empty_blocks(db, blocks):
    for _i in range(blocks - 1):
        mine_block(db, [])


def sendrawtransaction(db, rawtransaction):
    decoded_tx = deserialize.deserialize_tx(rawtransaction, parse_vouts=True)
    mine_block(db, [decoded_tx])


def is_valid_der(der):
    if len(der) == 71:
        return True
    return False


def search_pubkey(source, tx_hashes):
    return DEFAULT_PARAMS["pubkey"][source]


@pytest.fixture(scope="function")
def bitcoind_mock(monkeypatch):
    bitcoind_module = "counterpartycore.lib.backend.bitcoind"
    gettxinfo_module = "counterpartycore.lib.parser.gettxinfo"
    backend_module = "counterpartycore.lib.backend"
    monkeypatch.setattr(f"{bitcoind_module}.list_unspent", list_unspent)
    monkeypatch.setattr(f"{bitcoind_module}.satoshis_per_vbyte", satoshis_per_vbyte)
    monkeypatch.setattr(f"{bitcoind_module}.get_vin_info", get_vin_info)
    monkeypatch.setattr(f"{gettxinfo_module}.is_valid_der", is_valid_der)
    monkeypatch.setattr(f"{backend_module}.search_pubkey", search_pubkey)
    monkeypatch.setattr("counterpartycore.lib.messages.bet.date_passed", lambda x: False)
    return sys.modules[__name__]
