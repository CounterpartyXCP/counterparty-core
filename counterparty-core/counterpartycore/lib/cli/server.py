import _thread
import binascii
import decimal
import logging
import multiprocessing
import os
import threading
import time

import apsw
from termcolor import colored, cprint

from counterpartycore.lib import (
    backend,
    config,
    exceptions,
    ledger,
)
from counterpartycore.lib.api import apiserver as api_v2
from counterpartycore.lib.api import apiv1, dbbuilder
from counterpartycore.lib.cli import bootstrap, log
from counterpartycore.lib.ledger.backendheight import BackendHeight
from counterpartycore.lib.ledger.currentstate import CurrentState
from counterpartycore.lib.monitors import profiler, slack
from counterpartycore.lib.parser import blocks, check, follow
from counterpartycore.lib.utils import database, helpers

logger = logging.getLogger(config.LOGGER_NAME)
D = decimal.Decimal

OK_GREEN = colored("[OK]", "green")
SPINNER_STYLE = "bouncingBar"


def ensure_backend_is_up():
    if not config.FORCE:
        backend.bitcoind.getblockcount()


class AssetConservationChecker(threading.Thread):
    def __init__(self):
        threading.Thread.__init__(self, name="AssetConservationChecker")
        self.daemon = True
        self.last_check = 0
        self.db = None
        self.stop_event = threading.Event()

    def run(self):
        self.db = database.get_db_connection(config.DATABASE, read_only=True, check_wal=False)
        while not self.stop_event.is_set():
            if time.time() - self.last_check > 60 * 60 * 12:
                try:
                    check.asset_conservation(self.db, self.stop_event)
                except exceptions.SanityError as e:
                    logger.error("Asset conservation check failed: %s", e)
                    _thread.interrupt_main()
                except apsw.InterruptError:
                    break
                self.last_check = time.time()
            time.sleep(1)

    def stop(self):
        logger.info("Stopping Asset Conservation Checker thread...")
        self.stop_event.set()
        if self.db is not None:
            self.db.interrupt()
        self.join()
        if self.db is not None:
            self.db.close()
            self.db = None
        logger.info("Asset Conservation Checker thread stopped.")


class CounterpartyServer(threading.Thread):
    def __init__(self, args, log_stream=None, stop_when_ready=False):
        threading.Thread.__init__(self, name="CounterpartyServer")
        self.daemon = True
        self.args = args
        self.api_status_poller = None
        self.apiserver_v1 = None
        self.apiserver_v2 = None
        self.follower_daemon = None
        self.asset_conservation_checker = None
        self.db = None
        self.api_stop_event = None
        self.backend_height_thread = None
        self.log_stream = log_stream
        self.periodic_profiler = None
        self.stop_when_ready = stop_when_ready
        self.stopped = False

        # Log all config parameters, sorted by key
        # Filter out default values, these should be set in a different way
        custom_config = {
            k: v
            for k, v in sorted(config.__dict__.items())
            if not k.startswith("__") and not k.startswith("DEFAULT_")
        }
        logger.debug("Config: %s", custom_config)

    def run_server(self):
        # download bootstrap if necessary
        if (
            not os.path.exists(config.DATABASE) and self.args.catch_up == "bootstrap"
        ) or self.args.catch_up == "bootstrap-always":
            bootstrap.bootstrap(no_confirm=True, snapshot_url=self.args.bootstrap_url)

        # Initialise database
        database.apply_outstanding_migration(config.DATABASE, config.LEDGER_DB_MIGRATIONS_DIR)
        self.db = database.initialise_db()
        CurrentState().set_current_block_index(ledger.blocks.last_db_index(self.db))
        blocks.check_database_version(self.db)
        database.optimize(self.db)

        if self.args.rebuild_state_db:
            dbbuilder.build_state_db()
        elif self.args.refresh_state_db:
            state_db = database.get_db_connection(config.STATE_DATABASE, read_only=False)
            dbbuilder.refresh_state_db(state_db)
            state_db.close()

        # Check software version
        check.software_version()

        self.backend_height_thread = BackendHeight()
        self.backend_height_thread.daemon = True
        self.backend_height_thread.start()
        CurrentState().set_backend_height_value(self.backend_height_thread.shared_backend_height)

        # API Server v2
        self.api_stop_event = multiprocessing.Event()
        self.apiserver_v2 = api_v2.APIServer(
            self.api_stop_event, self.backend_height_thread.shared_backend_height
        )
        self.apiserver_v2.start(self.args, self.log_stream)
        while not self.apiserver_v2.is_ready():
            logger.trace("Waiting for API server to start...")
            if self.apiserver_v2.has_stopped():
                logger.error("API server stopped unexpectedly.")
                return
            time.sleep(0.1)

        if self.args.api_only:
            while True:
                self.api_stop_event.wait(1)
            return

        # Backend
        ensure_backend_is_up()

        # API Status Poller
        self.api_status_poller = apiv1.APIStatusPoller()
        self.api_status_poller.daemon = True
        self.api_status_poller.start()

        # API Server v1
        self.apiserver_v1 = apiv1.APIServer()
        self.apiserver_v1.daemon = True
        self.apiserver_v1.start()

        # delete blocks with no ledger hashes
        # in case of reparse interrupted
        blocks.rollback_empty_block(self.db)

        # Asset conservation checker
        if config.CHECK_ASSET_CONSERVATION:
            self.asset_conservation_checker = AssetConservationChecker()
            self.asset_conservation_checker.start()

        # Reset (delete) rust fetcher database
        blocks.reset_rust_fetcher_database()

        # Catch Up
        if config.PROFILE:
            self.periodic_profiler = profiler.PeriodicProfilerThread(
                interval_minutes=config.PROFILE_INTERVAL_MINUTES
            )
            self.periodic_profiler.start()

        blocks.catch_up(self.db)

        if self.stop_when_ready:
            slack.trigger_webhook()
            self.stop()  # stop here
            return

        # Blockchain Watcher
        logger.info("Watching for new blocks...")
        self.follower_daemon = follow.start_blockchain_watcher(self.db)
        self.follower_daemon.start()

    def run(self):
        try:
            self.run_server()
        except Exception as e:  # pylint: disable=broad-except
            logger.error("Error in server thread: %s", e)
            _thread.interrupt_main()

    def stop(self):
        if self.stopped:
            return
        logger.info("Shutting down...")
        if self.db:
            CurrentState().set_ledger_state(self.db, "Stopping")

        # Ensure all threads are stopped
        if self.follower_daemon:
            self.follower_daemon.stop()
        if self.asset_conservation_checker:
            self.asset_conservation_checker.stop()
        if self.backend_height_thread:
            self.backend_height_thread.stop()
        if self.api_stop_event:
            self.api_stop_event.set()
        if self.api_status_poller:
            self.api_status_poller.stop()
        if self.apiserver_v1:
            self.apiserver_v1.stop()
        if self.apiserver_v2:
            self.apiserver_v2.stop()

        if self.periodic_profiler:
            logger.info("Stopping periodic profiler...")
            self.periodic_profiler.stop()

        self.stopped = True
        logger.info("Shutdown complete.")


def start_all(args, log_stream=None, stop_when_ready=False):
    server = CounterpartyServer(args, log_stream, stop_when_ready=stop_when_ready)
    try:
        server.start()
        while True:
            if not server.stopped:
                server.join(1)
            else:
                break
    except KeyboardInterrupt:
        logger.warning("Interruption received. Shutting down...")
    finally:
        server.stop()


def rebuild(args):
    bootstrap.clean_data_dir(config.DATA_DIR)
    start_all(args, stop_when_ready=True)


def reparse(block_index):
    ledger_db = database.initialise_db()
    CurrentState().set_current_block_index(ledger.blocks.last_db_index(ledger_db))

    last_block = ledger.blocks.get_last_block(ledger_db)
    if last_block is None or block_index > last_block["block_index"]:
        print(colored("Block index is higher than current block index. No need to reparse.", "red"))
        ledger_db.close()
        return

    state_db = database.get_db_connection(config.STATE_DATABASE, read_only=False)
    try:
        blocks.reparse(ledger_db, block_index=block_index)
        dbbuilder.rollback_state_db(state_db, block_index)
    finally:
        database.optimize(ledger_db)
        database.optimize(state_db)
        ledger_db.close()
        state_db.close()


def rollback(block_index=None):
    ledger_db = database.initialise_db()
    CurrentState().set_current_block_index(ledger.blocks.last_db_index(ledger_db))

    last_block = ledger.blocks.get_last_block(ledger_db)
    if last_block is None or block_index > last_block["block_index"]:
        print(
            colored("Block index is higher than current block index. No need to rollback.", "red")
        )
        ledger_db.close()
        return

    state_db = database.get_db_connection(config.STATE_DATABASE, read_only=False)
    try:
        blocks.rollback(ledger_db, block_index=block_index)
        dbbuilder.rollback_state_db(state_db, block_index)
        follow.NotSupportedTransactionsCache().clear()
    finally:
        database.optimize(ledger_db)
        database.optimize(state_db)
        ledger_db.close()
        state_db.close()


def vacuum():
    db = database.initialise_db()
    with log.Spinner("Vacuuming database..."):
        database.vacuum(db)


def check_database():
    db = database.initialise_db()
    CurrentState().set_current_block_index(ledger.blocks.last_db_index(db))

    start_all_time = time.time()

    with log.Spinner("Checking asset conservation..."):
        check.asset_conservation(db)

    with log.Spinner("Checking database foreign keys...."):
        database.check_foreign_keys(db)

    with log.Spinner("Checking database integrity..."):
        database.intergrity_check(db)

    cprint(f"Database checks complete in {time.time() - start_all_time:.2f}s.", "green")


def show_params():
    output = vars(config)
    for k in list(output.keys()):
        if k.isupper():
            print(f"{k}: {output[k]}")


def generate_move_random_hash(move):
    move = int(move).to_bytes(2, byteorder="big")
    random_bin = os.urandom(16)
    move_random_hash_bin = helpers.dhash(random_bin + move)
    return binascii.hexlify(random_bin).decode("utf8"), binascii.hexlify(
        move_random_hash_bin
    ).decode("utf8")
