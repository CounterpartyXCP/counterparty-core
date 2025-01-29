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
from counterpartycore.lib.ledger import caches
from counterpartycore.lib.ledger.currentstate import CurrentState
from counterpartycore.lib.utils import database, helpers

from ..fixtures.defaults import DEFAULT_PARAMS
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


def get_disabled_protocol_changes():
    regtest_protocole_file = os.path.join(DATA_DIR, "regtest_disabled_changes.json")
    if os.path.exists(regtest_protocole_file):
        with open(regtest_protocole_file) as f:
            return json.load(f)
    return []


class ProtocolChangesDisabled:
    def __init__(self, change_names):
        self.disabled_changes = change_names

    def __enter__(self):
        disable_protocol_changes(self.disabled_changes)

    def __exit__(self, type, value, traceback):
        enable_all_protocol_changes()


def initialise_config():
    # prepare empty directory
    if os.path.exists(DATA_DIR):
        shutil.rmtree(DATA_DIR)
    os.makedirs(DATA_DIR)

    # initialise config variables
    parser = arg_parser(no_config_file=True)
    args = parser.parse_args(["--regtest", "--data-dir", DATA_DIR, "-vv"])
    server.initialise_log_and_config(args)


def prepare_empty_database(bitcoind_mock):
    # initialise database
    db = database.get_db_connection(config.DATABASE, read_only=False)
    db.close()
    database.apply_outstanding_migration(config.DATABASE, config.LEDGER_DB_MIGRATIONS_DIR)
    db = database.get_db_connection(config.DATABASE, read_only=False)

    # mine first block
    CurrentState().set_current_block_index(config.BLOCK_FIRST - 1)
    bitcoind_mock.mine_block(db, [])
    db.close()


def run_scenario(db, bitcoind_mock, scenario):
    for tx_params in scenario:
        if isinstance(tx_params[1], tuple):
            return db
        if tx_params[0] == "mine_empty_blocks":
            bitcoind_mock.mine_empty_blocks(db, tx_params[1])
            continue
        name, params, construct_params = tx_params[0:3]
        # disable protocol changes if needed
        disabled_change_before = get_disabled_protocol_changes()
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
        if len(disabled_change_before) > 0:
            disable_protocol_changes(disabled_change_before)


def backup_databases(backup_name):
    backup_dir = os.path.join(DATA_DIR, backup_name)
    if os.path.exists(backup_dir):
        shutil.rmtree(backup_dir)
    os.makedirs(backup_dir)
    for db_name in ["counterparty", "state"]:
        os.rename(
            os.path.join(DATA_DIR, f"{db_name}.regtest.db"),
            os.path.join(backup_dir, f"{db_name}.regtest.db"),
        )


@pytest.fixture(scope="session", autouse=True)
def build_dbs(bitcoind_mock):
    print("Building databases...")
    initialise_config()
    prepare_empty_database(bitcoind_mock)
    db = database.get_db_connection(config.DATABASE, read_only=False)
    run_scenario(db, bitcoind_mock, UNITTEST_FIXTURE)
    db.close()
    dbbuilder.build_state_db()
    backup_databases("backup_dir")

    prepare_empty_database(bitcoind_mock)
    dbbuilder.build_state_db()
    backup_databases("backup_empties_dir")


def get_tmp_connection(db_name, backup_name):
    backup_dir = os.path.join(DATA_DIR, backup_name)
    backup_path = os.path.join(backup_dir, f"{db_name}.regtest.db")
    database_path = config.DATABASE if db_name == "counterparty" else config.STATE_DATABASE

    shutil.copyfile(backup_path, database_path)
    db = database.get_db_connection(database_path, read_only=False)
    return db


@pytest.fixture(scope="function")
def ledger_db(build_dbs):
    db = get_tmp_connection("counterparty", "backup_dir")
    current_block_index = db.execute(
        "SELECT MAX(block_index) AS block_index FROM blocks"
    ).fetchone()["block_index"]
    CurrentState().set_current_block_index(current_block_index)
    caches.init_caches(db)
    yield db
    db.close()
    database.LedgerDBConnectionPool().close()
    os.remove(config.DATABASE)


@pytest.fixture(scope="function")
def state_db(build_dbs):
    db = get_tmp_connection("state", "backup_dir")
    caches.init_caches(db)
    yield db
    db.close()
    database.StateDBConnectionPool().close()
    os.remove(config.STATE_DATABASE)


@pytest.fixture(scope="function")
def empty_ledger_db(build_dbs):
    db = get_tmp_connection("counterparty", "backup_empties_dir")
    current_block_index = db.execute(
        "SELECT MAX(block_index) AS block_index FROM blocks"
    ).fetchone()["block_index"]
    CurrentState().set_current_block_index(current_block_index)
    caches.init_caches(db)
    yield db
    db.close()
    database.LedgerDBConnectionPool().close()
    os.remove(config.DATABASE)


def check_record(ledger_db, record):
    """Allow direct record access to the db."""
    cursor = ledger_db.cursor()

    if record["table"] == "pragma":
        field = record["field"]
        sql = f"""PRAGMA {field}"""
        value = cursor.execute(sql).fetchall()[0][field]
        assert value == record["value"]
    else:
        sql = f"SELECT COUNT(*) AS count FROM {record['table']} WHERE "  # noqa: S608
        bindings = []
        conditions = []
        fields = []
        for field in record["values"]:
            if record["values"][field] is not None:
                fields.append(field)
                conditions.append(f"{field} = ?")
                bindings.append(record["values"][field])
        sql += " AND ".join(conditions)
        count = cursor.execute(sql, tuple(bindings)).fetchone()["count"]
        ok = (record.get("not", False) and count == 0) or count == 1
        if not ok:
            last_record = cursor.execute(
                f"SELECT {', '.join(fields)} FROM {record['table']} ORDER BY rowid DESC LIMIT 1"  # noqa: S608
            ).fetchone()
            print("test output", helpers.to_json(last_record, sort_keys=True))
            print("expected output", helpers.to_json(record["values"], sort_keys=True))
            assert ok, f"Record not found in {record['table']}: {record['values']}"


def check_records(ledger_db, records):
    for record in records:
        check_record(ledger_db, record)


@pytest.fixture(scope="function")
def current_block_index():
    return CurrentState().current_block_index()


@pytest.fixture(scope="function")
def defaults():
    return DEFAULT_PARAMS
