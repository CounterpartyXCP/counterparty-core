import _thread
import binascii
import decimal
import logging
import multiprocessing
import os
import signal
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
from counterpartycore.lib.backend import rsfetcher
from counterpartycore.lib.cli import bootstrap, log
from counterpartycore.lib.ledger.backendheight import BackendHeight
from counterpartycore.lib.ledger.currentstate import CurrentState
from counterpartycore.lib.monitors import memory_profiler, slack
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
        self.join(timeout=5)
        if self.is_alive():
            logger.warning("Asset Conservation Checker thread did not stop in time, continuing...")
        else:
            logger.info("Asset Conservation Checker thread stopped.")
        if self.db is not None:
            self.db.close()
            self.db = None


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
        self.mem_profiler = None
        self.pool_monitor = None
        self.stop_when_ready = stop_when_ready
        self.stopped = False
        # True as soon as stop() has started (set before any blocking join()),
        # so the run() finally block knows the shutdown was requested
        # explicitly and must NOT raise KeyboardInterrupt in the main thread.
        self.stop_requested = False

        # Log all config parameters, sorted by key
        # Filter out default values, these should be set in a different way
        # Redact secrets so DEBUG logs / Sentry breadcrumbs don't leak the
        # bitcoind RPC password, API password, or auth cookies.
        secret_substrings = ("PASSWORD", "SECRET", "COOKIE", "TOKEN", "KEY")
        custom_config = {
            k: ("***" if any(s in k.upper() for s in secret_substrings) and v else v)
            for k, v in sorted(config.__dict__.items())
            if not k.startswith("__") and not k.startswith("DEFAULT_")
        }
        logger.debug("Config: %s", custom_config)

    def _start_pool_monitor(self):
        """Start connection pool monitor for MainProcess."""

        class MainProcessPoolMonitor(threading.Thread):
            def __init__(self, interval_seconds=60):
                super().__init__(name="MainProcessPoolMonitor", daemon=True)
                self.interval = interval_seconds
                self.stop_event = threading.Event()

            def run(self):
                while not self.stop_event.is_set():
                    self.stop_event.wait(self.interval)
                    if self.stop_event.is_set():
                        break
                    try:
                        ledger_stats = database.LedgerDBConnectionPool().get_stats()
                        state_stats = database.StateDBConnectionPool().get_stats()
                        logger.info(
                            "MAINPROCESS_POOL ledger=%d/%d (%.0f%%, peak=%d) state=%d/%d (%.0f%%, peak=%d)",
                            ledger_stats["current"],
                            ledger_stats["max"],
                            ledger_stats["utilization"],
                            ledger_stats["peak"],
                            state_stats["current"],
                            state_stats["max"],
                            state_stats["utilization"],
                            state_stats["peak"],
                        )
                    except Exception as e:  # pylint: disable=broad-exception-caught
                        logger.error("Error logging MainProcess pool stats: %s", e)

            def stop(self):
                self.stop_event.set()

        monitor = MainProcessPoolMonitor(interval_seconds=60)
        monitor.start()
        return monitor

    def run_server(self):
        # Start memory profiler if enabled via --memory-profile flag
        if getattr(config, "MEMORY_PROFILE", False):
            self.mem_profiler = memory_profiler.start_memory_profiler(
                interval_seconds=60,
                enable_tracemalloc=False,
            )

        # download bootstrap if necessary
        if (
            not os.path.exists(config.DATABASE) and self.args.catch_up == "bootstrap"
        ) or self.args.catch_up == "bootstrap-always":
            bootstrap.bootstrap(no_confirm=True, snapshot_url=self.args.bootstrap_url)

        # Initialise database
        database.apply_outstanding_migration(config.DATABASE, config.LEDGER_DB_MIGRATIONS_DIR)
        self.db = database.initialise_db()
        # Ensure the ``messages`` table has its read indexes even when
        # ``--api-only`` skips the parser's ``catch_up()`` path. Migration
        # 0010 rebuilt the table without these indexes for legacy DBs
        # carrying the ``EVENTS_INDEXES_CREATED`` flag, so without this
        # call the API would full-scan ``messages`` on every read.
        # ``CREATE INDEX IF NOT EXISTS`` is idempotent, so this is a no-op
        # for fully-indexed databases.
        blocks.create_events_indexes(self.db)
        CurrentState().set_current_block_index(ledger.blocks.last_db_index(self.db))
        blocks.check_database_version(self.db)
        database.optimize(self.db)

        # Check software version
        check.software_version()

        self.backend_height_thread = BackendHeight()
        self.backend_height_thread.daemon = True
        self.backend_height_thread.start()
        CurrentState().set_backend_height_value(self.backend_height_thread.shared_backend_height)

        # Start MainProcess connection pool monitor
        logger.info("Starting MainProcess Connection Pool Monitor thread...")
        self.pool_monitor = self._start_pool_monitor()

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
            # Loop must check the event so stop() actually exits the loop;
            # without this, even after self.api_stop_event.set() the wait()
            # just returns and we re-enter the wait. Daemon=True eventually
            # tears the process down, but there's no clean SIGTERM round.
            while not self.api_stop_event.is_set():
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
        blocks.catch_up(self.db)

        if self.stop_when_ready:
            self.stop()  # stop here
            return

        # Blockchain Watcher
        rsfetcher.RSFetcher()
        logger.info("Watching for new blocks...")
        self.follower_daemon = follow.start_blockchain_watcher(self.db)
        self.follower_daemon.start()

    def run(self):
        try:
            self.run_server()
        except Exception as e:  # pylint: disable=broad-except
            # import traceback
            # print(traceback.format_exc())
            logger.error("Error in server thread: %s", e, stack_info=True)
        finally:
            # Signal main thread to stop when server thread ends unexpectedly
            # (exception or early return like API startup failure).
            # If stop() was already called from outside (e.g. SIGTERM handler),
            # the main thread is already shutting down and is likely blocked
            # in a join(); raising KeyboardInterrupt there would crash the
            # shutdown sequence half-way through.
            if not self.stop_requested:
                _thread.interrupt_main()

    def stop(self):
        if self.stopped:
            return
        # Mark the shutdown as explicitly requested BEFORE doing any blocking
        # work, so the run() finally block does not raise KeyboardInterrupt
        # in the main thread while we are joining sub-threads.
        self.stop_requested = True
        logger.info("Shutting down...")

        CurrentState().set_stopping()
        rsfetcher.RSFetcher().stop()

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

        if self.pool_monitor:
            logger.info("Stopping MainProcess Connection Pool Monitor thread...")
            self.pool_monitor.stop()

        if self.periodic_profiler:
            logger.info("Stopping periodic profiler...")
            self.periodic_profiler.stop()

        if self.mem_profiler:
            logger.info("Stopping memory profiler...")
            memory_profiler.stop_memory_profiler()

        self.stopped = True
        logger.info("Shutdown complete.")


def start_all(args, log_stream=None, stop_when_ready=False):
    server = CounterpartyServer(args, log_stream, stop_when_ready=stop_when_ready)
    shutdown_event = threading.Event()

    def handle_sigterm(signum, frame):  # pylint: disable=unused-argument
        logger.warning("SIGTERM received. Shutting down...")
        shutdown_event.set()

    signal.signal(signal.SIGTERM, handle_sigterm)

    try:
        server.start()
        while not shutdown_event.is_set() and not server.stopped:
            server.join(1)
    except KeyboardInterrupt:
        logger.warning("Interruption received. Shutting down...")
    finally:
        # Shield the shutdown from a late KeyboardInterrupt (e.g. a second
        # SIGINT, or interrupt_main() racing with the SIGTERM handler).
        # stop() is safe to call multiple times: every sub-stop() is
        # idempotent, and a fully-completed stop() is short-circuited by
        # the `if self.stopped: return` guard at the top.
        while True:
            try:
                server.stop()
                break
            except KeyboardInterrupt:
                logger.warning("KeyboardInterrupt received during shutdown, retrying stop...")


def rebuild(args):
    slack.send_slack_message("Starting new rebuild.")
    try:
        bootstrap.clean_data_dir(config.DATA_DIR)
        start_all(args, stop_when_ready=True)
    except Exception as e:  # pylint: disable=broad-except
        slack.send_slack_message(f"Rebuild failed: {e}")
        raise e
    slack.send_slack_message("Rebuild complete.")


def reparse(block_index):
    database.apply_outstanding_migration(config.DATABASE, config.LEDGER_DB_MIGRATIONS_DIR)
    ledger_db = database.initialise_db()
    CurrentState().set_current_block_index(ledger.blocks.last_db_index(ledger_db))
    blocks.check_database_version(ledger_db)

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
    database.apply_outstanding_migration(config.DATABASE, config.LEDGER_DB_MIGRATIONS_DIR)
    ledger_db = database.initialise_db()
    CurrentState().set_current_block_index(ledger.blocks.last_db_index(ledger_db))
    blocks.check_database_version(ledger_db)

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
