import json
import os
import shutil
import tempfile

import pytest
from bitcoinutils.transactions import Transaction
from counterpartycore.lib import config
from counterpartycore.lib.api import composer, dbbuilder
from counterpartycore.lib.cli import server
from counterpartycore.lib.cli.main import arg_parser
from counterpartycore.lib.ledger.currentstate import CurrentState
from counterpartycore.lib.utils import database

from ..fixtures.ledgerdb import UNITTEST_FIXTURE

DATA_DIR = os.path.join(tempfile.gettempdir(), "counterparty-pytest-data")


def disable_protocol_changes(change_names):
    regtest_protocole_file = os.path.join(DATA_DIR, "regtest_disabled_changes.json")
    with open(regtest_protocole_file, "w") as f:
        f.write(json.dumps(change_names))


def enable_all_protocol_changes():
    regtest_protocole_file = os.path.join(DATA_DIR, "regtest_disabled_changes.json")
    if os.path.exists(regtest_protocole_file):
        os.remove(regtest_protocole_file)


@pytest.fixture(scope="session", autouse=True)
def build_dbs(bitcoind_mock):
    print("Building databases...")
    # prepare empty directory
    if os.path.exists(DATA_DIR):
        shutil.rmtree(DATA_DIR)
    os.makedirs(DATA_DIR)

    # initialise config variables
    parser = arg_parser()
    args = parser.parse_args(
        [
            "--regtest",
            "--data-dir",
            DATA_DIR,
        ]
    )
    print("args", args)
    server.initialise_log_and_config(args)

    # initialise database
    db = database.get_db_connection(config.DATABASE, read_only=False)
    db.close()
    database.apply_outstanding_migration(config.DATABASE, config.LEDGER_DB_MIGRATIONS_DIR)
    db = database.get_db_connection(config.DATABASE, read_only=False)

    # mine first block
    CurrentState().set_current_block_index(config.BLOCK_FIRST - 1)
    bitcoind_mock.mine_block(db, [])

    for tx_params in UNITTEST_FIXTURE:
        # print("tx_params", tx_params)
        if isinstance(tx_params[1], tuple):
            return db

        if tx_params[0] == "mine_empty_blocks":
            bitcoind_mock.mine_empty_blocks(db, tx_params[1])
            continue

        name, params, construct_params = tx_params[0:3]
        # disable protocol changes if needed
        if len(tx_params) > 3:
            disable_protocol_changes(tx_params[3])
        # complete params
        if "skip_validation" not in params:
            params["skip_validation"] = False
        if "disable_utxo_locks" not in construct_params:
            construct_params["disable_utxo_locks"] = True
        # compose transaction
        tx = composer.compose_transaction(db, name, params, construct_params)
        # dummy sign the transaction
        tx = Transaction.from_raw(tx["rawtransaction"])
        unspent = bitcoind_mock.list_unspent(params["source"])
        signed_tx = composer.generate_dummy_signed_tx(tx, unspent)
        signed_tx = signed_tx.serialize()
        # broadcast transaction
        bitcoind_mock.sendrawtransaction(db, signed_tx)
        # re-enable all protocol changes
        enable_all_protocol_changes()

    dbbuilder.build_state_db()


@pytest.fixture(scope="function")
def ledger_db(build_dbs):
    tmpdir = os.path.join(DATA_DIR, "tmp")
    if os.path.exists(tmpdir):
        shutil.rmtree(tmpdir)
    os.makedirs(tmpdir)

    database_path = os.path.join(tmpdir, "counterparty.regtest.db")
    shutil.copyfile(config.DATABASE, database_path)

    db = database.get_db_connection(database_path, read_only=False)

    yield db

    db.close()
    shutil.rmtree(tmpdir)
