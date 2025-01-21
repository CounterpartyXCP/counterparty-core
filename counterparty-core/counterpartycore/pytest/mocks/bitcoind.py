import sys
import time

import pytest
from counterpartycore.lib import config
from counterpartycore.lib.api import composer
from counterpartycore.lib.ledger.currentstate import CurrentState
from counterpartycore.lib.parser import blocks, check, deserialize
from counterpartycore.lib.utils import helpers, multisig, script

from ..fixtures.params import DEFAULT_PARAMS


class BlockchainMock(metaclass=helpers.SingletonMeta):
    def __init__(self):
        self.source_by_txid = {}
        self.address_and_value_by_utxo = {}

    def list_unspent(self, source, allow_unconfirmed_inputs=True):
        construct_params = {}
        if multisig.is_multisig(source):
            _signatures_required, addresses, _signatures_possible = multisig.extract_array(source)
            pubkeys = [DEFAULT_PARAMS["pubkey"][addr] for addr in addresses]
            construct_params["pubkeys"] = ",".join(pubkeys)

        script_pub_key = composer.address_to_script_pub_key(source, network="regtest").to_hex()

        # deterministic txid from the source
        txid = check.dhash_string(f"{source}{list(self.source_by_txid.values()).count(source)}")
        self.source_by_txid[txid] = source

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

    def get_utxo_address_and_value(self, utxo):
        txid, vout = utxo.split(":")
        return self.address_and_value_by_utxo[f"{txid}:0"]

    def save_address_and_value(self, decoded_tx):
        address = script.script_to_address2(decoded_tx["vout"][-1]["script_pub_key"])
        value = decoded_tx["vout"][-1]["value"]
        utxo = f"{decoded_tx['tx_id']}:0"
        self.address_and_value_by_utxo[utxo] = (address, value)

    def get_dummy_tx_hash(self, source):
        txid = check.dhash_string(f"{source}{list(self.source_by_txid.values()).count(source)}")
        self.source_by_txid[txid] = source
        self.address_and_value_by_utxo[f"{txid}:0"] = (source, int(10 * config.UNIT))
        return txid

    def dummy_tx(
        self,
        ledger_db,
        source,
        outputs_count=2,
        op_return_position=1,
        utxo_source=None,
        utxo_destination=None,
    ):
        # we take an existing tx to avoid foreign key constraint errors
        cursor = ledger_db.cursor()
        tx = cursor.execute(
            "SELECT * FROM transactions WHERE source = ? ORDER BY rowid DESC", (source,)
        ).fetchone()

        utxos_info = [utxo_source or ""]
        if utxo_destination is not None:
            utxos_info.append(f"{utxo_destination}")
        else:
            utxos_info.append(f"{tx['tx_hash']}:0")
        utxos_info.append(f"{outputs_count}")
        utxos_info.append(f"{op_return_position}")
        utxos_info = " ".join(utxos_info)

        return {
            "source": source,
            "block_index": tx["block_index"],
            "tx_index": tx["tx_index"],
            "tx_hash": tx["tx_hash"],
            "utxos_info": utxos_info,
        }


def list_unspent(source, allow_unconfirmed_inputs=True):
    return BlockchainMock().list_unspent(source, allow_unconfirmed_inputs)


def get_vin_info(vin):
    return BlockchainMock().get_vin_info(vin)


def get_utxo_address_and_value(utxo):
    return BlockchainMock().get_utxo_address_and_value(utxo)


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
    BlockchainMock().save_address_and_value(decoded_tx)
    mine_block(db, [decoded_tx])
    cursor = db.cursor()
    transaction = cursor.execute(
        "SELECT * FROM transactions WHERE tx_hash = ?", (decoded_tx["tx_id"],)
    ).fetchone()
    assert transaction is not None


def is_valid_der(der):
    if len(der) == 71:
        return True
    return False


def search_pubkey(source, tx_hashes):
    return DEFAULT_PARAMS["pubkey"][source]


@pytest.fixture(scope="session")
def monkeymodule():
    from _pytest.monkeypatch import MonkeyPatch

    mpatch = MonkeyPatch()
    yield mpatch
    mpatch.undo()


@pytest.fixture(scope="session")
def bitcoind_mock(monkeymodule):
    bitcoind_module = "counterpartycore.lib.backend.bitcoind"
    gettxinfo_module = "counterpartycore.lib.parser.gettxinfo"
    backend_module = "counterpartycore.lib.backend"
    monkeymodule.setattr(f"{bitcoind_module}.list_unspent", list_unspent)
    monkeymodule.setattr(f"{bitcoind_module}.satoshis_per_vbyte", satoshis_per_vbyte)
    monkeymodule.setattr(f"{bitcoind_module}.get_vin_info", get_vin_info)
    monkeymodule.setattr(
        f"{bitcoind_module}.get_utxo_address_and_value", get_utxo_address_and_value
    )
    monkeymodule.setattr(f"{gettxinfo_module}.is_valid_der", is_valid_der)
    monkeymodule.setattr(f"{backend_module}.search_pubkey", search_pubkey)
    monkeymodule.setattr("counterpartycore.lib.messages.bet.date_passed", lambda x: False)
    return sys.modules[__name__]


@pytest.fixture(scope="function")
def blockchain_mock():
    return BlockchainMock()
