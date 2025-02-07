import errno
import logging
import multiprocessing
import os
import signal
import sys
import threading

import gunicorn.app.base
import waitress
import waitress.server
from gunicorn import util as gunicorn_util
from gunicorn.arbiter import Arbiter
from gunicorn.errors import AppImportError, HaltServer
from werkzeug.serving import make_server

from counterpartycore.lib import config
from counterpartycore.lib.api import apiwatcher
from counterpartycore.lib.cli import log
from counterpartycore.lib.ledger.currentstate import CurrentState
from counterpartycore.lib.utils import database, helpers

multiprocessing.set_start_method("spawn", force=True)

logger = logging.getLogger(config.LOGGER_NAME)


def refresh_current_state(ledger_db, state_db):
    CurrentState().set_current_block_index(apiwatcher.get_last_block_parsed(state_db))

    current_block_index = CurrentState().current_block_index()
    current_backend_height = CurrentState().current_backend_height()

    if current_backend_height > current_block_index:
        logger.debug(
            f"Counterparty is currently behind Bitcoin Core. ({current_block_index} < {current_backend_height})"
        )
    elif current_backend_height < current_block_index:
        logger.debug(
            f"Bitcoin Core is currently behind the network. ({current_block_index} > {current_backend_height})"
        )


class NodeStatusCheckerThread(threading.Thread):
    def __init__(self):
        threading.Thread.__init__(self, name="NodeStatusChecker")
        self.state_db = database.get_db_connection(config.STATE_DATABASE)
        self.ledger_db = database.get_db_connection(config.DATABASE)
        self.stop_event = threading.Event()

    def run(self):
        logger.debug("Starting NodeStatusChecker thread...")
        try:
            while not self.stop_event.is_set():
                refresh_current_state(self.ledger_db, self.state_db)
                self.stop_event.wait(timeout=1)
        finally:
            self.state_db.close()
            self.ledger_db.close()

    def stop(self):
        self.stop_event.set()
        if self.is_alive():
            self.join()


class GunicornArbiter(Arbiter):
    def __init__(self, app):
        super().__init__(app)  # Pass 'app' instead of 'app.cfg'
        self.app = app
        self.timeout = 30
        self.graceful_timeout = 30
        self.max_requests = 1000
        self.max_requests_jitter = 50
        self.workers_pids = []
        self.init_loggers()

    def init_loggers(self):
        for handler in self.log.error_log.handlers:
            self.log.error_log.handlers.remove(handler)
        for handler in logger.handlers:
            self.log.error_log.addHandler(handler)

    def handle_winch(self):
        pass

    def spawn_worker(self):
        self.worker_age += 1
        worker = self.worker_class(
            self.worker_age,
            self.pid,
            self.LISTENERS,
            self.app,
            self.timeout / 2.0,
            self.cfg,
            self.log,
        )
        self.cfg.pre_fork(self, worker)
        pid = os.fork()
        if pid != 0:
            worker.pid = pid
            self.WORKERS[pid] = worker
            self.workers_pids.append(pid)
            return pid

        # Child process
        global logger  # noqa F811
        worker.pid = os.getpid()
        logger = log.re_set_up(f".gunicorn.{worker.pid}", api=True)
        self.init_loggers()
        try:
            gunicorn_util._setproctitle(f"worker [{self.proc_name}]")
            logger.debug("Booting Gunicorn worker with pid: %s", worker.pid)
            self.cfg.post_fork(self, worker)
            worker.init_process()
            sys.exit(0)
        except SystemExit:
            raise
        except AppImportError:
            self.log.warning("Exception while loading the application", exc_info=True)
            sys.stderr.flush()
            sys.exit(self.APP_LOAD_ERROR)
        except Exception:
            self.log.exception("Exception in worker process")
            if not worker.booted:
                sys.exit(self.WORKER_BOOT_ERROR)
            sys.exit(-1)
        finally:
            logger.info("Worker exiting (pid: %s)", worker.pid)
            try:
                worker.tmp.close()
                self.cfg.worker_exit(self, worker)
            except Exception:
                logger.warning("Exception during worker exit")

    def reap_workers(self):
        """\
        Reap workers to avoid zombie processes
        """
        try:
            while True:
                wpid, status = os.waitpid(-1, os.WNOHANG)
                if not wpid:
                    break
                if self.reexec_pid == wpid:
                    self.reexec_pid = 0
                else:
                    # A worker was terminated. If the termination reason was
                    # that it could not boot, we'll shut it down to avoid
                    # infinite start/stop cycles.
                    exitcode = status >> 8
                    if exitcode != 0:
                        self.log.error("Worker (pid:%s) exited with code %s", wpid, exitcode)
                    if exitcode == self.WORKER_BOOT_ERROR:
                        reason = "Worker failed to boot."
                        raise HaltServer(reason, self.WORKER_BOOT_ERROR)
                    if exitcode == self.APP_LOAD_ERROR:
                        reason = "App failed to load."
                        raise HaltServer(reason, self.APP_LOAD_ERROR)

                    worker = self.WORKERS.pop(wpid, None)
                    if not worker:
                        continue
                    worker.tmp.close()
                    self.cfg.child_exit(self, worker)
        except OSError as e:
            if e.errno != errno.ECHILD:
                raise

    def kill_all_workers(self):
        if len(self.workers_pids) == 0:
            return
        for pid in self.workers_pids:
            try:
                os.kill(pid, signal.SIGTERM)
            except ProcessLookupError:
                pass
        while True:
            stopped = [not helpers.is_process_alive(pid) for pid in self.workers_pids]
            if all(stopped):
                break
        logger.info(f"All workers killed: {self.workers_pids}")
        self.workers_pids = []


class GunicornApplication(gunicorn.app.base.BaseApplication):
    def __init__(self, app, args=None):
        self.options = {
            "bind": "%s:%s" % (config.API_HOST, config.API_PORT),
            "workers": config.GUNICORN_WORKERS,
            "worker_class": "gthread",
            "daemon": True,
            "threads": config.GUNICORN_THREADS_PER_WORKER,
            "loglevel": "trace",
            "access-logfile": "-",
            "errorlog": "-",
            "capture_output": True,
        }
        self.application = app
        self.args = args
        self.arbiter = None
        self.ledger_db = None
        self.state_db = None
        self.current_state_thread = NodeStatusCheckerThread()
        self.master_pid = os.getpid()
        super().__init__()

    def load_config(self):
        gunicorn_config = {
            key: value
            for key, value in self.options.items()
            if key in self.cfg.settings and value is not None
        }
        for key, value in gunicorn_config.items():
            self.cfg.set(key.lower(), value)

    def load(self):
        self.current_state_thread.start()
        return self.application

    def run(self, server_ready_value):
        try:
            self.server_ready_value = server_ready_value
            self.arbiter = GunicornArbiter(self)
            self.arbiter.run()
        except RuntimeError as e:
            logger.error("Error in GUnicorn: %s", e)
            sys.stderr.flush()
            sys.exit(1)

    def stop(self):
        self.current_state_thread.stop()
        if self.arbiter and self.master_pid == os.getpid():
            logger.info("Stopping Gunicorn")
            self.arbiter.kill_all_workers()
            self.server_ready_value.value = 2


class WerkzeugApplication:
    def __init__(self, app, args=None):
        self.app = app
        self.args = args
        self.current_state_thread = NodeStatusCheckerThread()
        self.server = make_server(config.API_HOST, config.API_PORT, self.app, threaded=True)

    def run(self, server_ready_value=None):
        self.current_state_thread.start()
        self.server.serve_forever()

    def stop(self):
        self.current_state_thread.stop()
        self.server.shutdown()
        self.server.server_close()


class WaitressApplication:
    def __init__(self, app, args=None):
        self.app = app
        self.args = args
        self.current_state_thread = NodeStatusCheckerThread()
        self.server = waitress.server.create_server(
            self.app, host=config.API_HOST, port=config.API_PORT, threads=config.WAITRESS_THREADS
        )

    def run(self, server_ready_value=None):
        self.current_state_thread.start()
        self.server.run()

    def stop(self):
        self.current_state_thread.stop()
        self.server.close()


class WSGIApplication:
    def __init__(self, app, args=None):
        self.app = app
        self.args = args
        logger.info(f"Starting WSGI Server: {config.WSGI_SERVER}")
        if config.WSGI_SERVER == "gunicorn":
            self.server = GunicornApplication(self.app, self.args)
        elif config.WSGI_SERVER == "werkzeug":
            self.server = WerkzeugApplication(self.app, self.args)
        else:
            self.server = WaitressApplication(self.app, self.args)

    def run(self, server_ready_value):
        logger.info("Starting WSGI Server thread...")
        self.server.run(server_ready_value)

    def stop(self):
        logger.info("Stopping WSGI Server thread...")
        self.server.stop()
