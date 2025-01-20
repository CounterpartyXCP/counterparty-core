import os
import shutil
import tempfile

from bitcoinutils.transactions import Transaction
from counterpartycore.lib import config
from counterpartycore.lib.api import composer
from counterpartycore.lib.cli import server
from counterpartycore.lib.cli.main import arg_parser
from counterpartycore.lib.ledger.currentstate import CurrentState
from counterpartycore.lib.utils import database

from ..mocks import bitcoind
from .scenarios import UNITTEST_FIXTURE

DATA_DIR = os.path.join(
    tempfile.gettempdir(), "counterparty-pytest-data", "counterparty.testnet.db"
)


def buid_unitest_db(bitcoind_mock):
    if os.path.exists(DATA_DIR):
        shutil.rmtree(DATA_DIR)
    os.makedirs(DATA_DIR)

    parser = arg_parser()
    args = parser.parse_args(
        [
            "--regtest",
            "--data-dir",
            DATA_DIR,
        ]
    )
    server.initialise_log_and_config(args)

    db = database.get_db_connection(config.DATABASE, read_only=False)
    db.close()

    database.apply_outstanding_migration(config.DATABASE, config.LEDGER_DB_MIGRATIONS_DIR)
    db = database.get_db_connection(config.DATABASE, read_only=False)

    CurrentState().set_current_block_index(100)
    bitcoind_mock.mine_block(db, [])

    for tx_params in UNITTEST_FIXTURE[0:1]:
        name, params, construct_params = tx_params
        tx = composer.compose_transaction(db, name, params, construct_params)
        assert "rawtransaction" in tx
        tx = Transaction.from_raw(tx["rawtransaction"])
        unspent = bitcoind.list_unspent(params["source"])
        signed_tx = composer.generate_dummy_signed_tx(tx, unspent).serialize()
        print("Signed tx:", signed_tx)
        bitcoind_mock.sendrawtransaction(db, signed_tx)

    return db
