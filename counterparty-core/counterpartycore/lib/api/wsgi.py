import logging
import multiprocessing
import os
import signal
import sys
import tempfile
import time
from threading import Timer

import gunicorn.app.base
import waitress
import waitress.server
from counterpartycore.lib import backend, config, ledger, util
from counterpartycore.lib.api.util import get_backend_height
from counterpartycore.lib.database import get_db_connection
from flask import request
from gunicorn import util as gunicorn_util
from gunicorn.arbiter import Arbiter
from gunicorn.errors import AppImportError
from werkzeug.serving import make_server

multiprocessing.set_start_method("spawn", force=True)

logger = logging.getLogger(config.LOGGER_NAME)

BACKEND_HEIGHT = None
CURRENT_BLOCK_TIME = None
REFRESH_BACKEND_HEIGHT_INTERVAL = 10
BACKEND_HEIGHT_TIMER = None


def is_server_ready():
    # TODO: find a way to mock this function for testing
    try:
        if request.url_root == "http://localhost:10009/":
            return True
    except RuntimeError:
        pass
    if BACKEND_HEIGHT is None:
        return False
    if util.CURRENT_BLOCK_INDEX in [BACKEND_HEIGHT, BACKEND_HEIGHT - 1]:
        return True
    if CURRENT_BLOCK_TIME is None:
        return False
    if time.time() - CURRENT_BLOCK_TIME < 60:
        return True
    return False


def refresh_current_block(db):
    # update the current block index
    global CURRENT_BLOCK_TIME  # noqa F811
    last_block = ledger.get_last_block(db)
    if last_block:
        util.CURRENT_BLOCK_INDEX = last_block["block_index"]
        CURRENT_BLOCK_TIME = last_block["block_time"]
    else:
        util.CURRENT_BLOCK_INDEX = 0
        CURRENT_BLOCK_TIME = 0


def refresh_backend_height(db, start=False):
    global BACKEND_HEIGHT, BACKEND_HEIGHT_TIMER  # noqa F811
    if not start:
        BACKEND_HEIGHT = get_backend_height()
        # print(f"BACKEND_HEIGHT: {BACKEND_HEIGHT} ({os.getpid()})")
        refresh_current_block(db)
        backend.addrindexrs.clear_raw_transactions_cache()
        if not is_server_ready():
            if BACKEND_HEIGHT > util.CURRENT_BLOCK_INDEX:
                logger.debug(
                    f"Counterparty is currently behind Bitcoin Core. ({util.CURRENT_BLOCK_INDEX} < {BACKEND_HEIGHT})"
                )
            else:
                logger.debug(
                    f"Bitcoin Core is currently behind the network. ({util.CURRENT_BLOCK_INDEX} > {BACKEND_HEIGHT})"
                )
    else:
        # starting the timer is not blocking in case of Addrindexrs is not ready
        BACKEND_HEIGHT_TIMER = Timer(0.5, refresh_backend_height, (db,))
        BACKEND_HEIGHT_TIMER.start()
        return
    if BACKEND_HEIGHT_TIMER:
        BACKEND_HEIGHT_TIMER.cancel()
    BACKEND_HEIGHT_TIMER = Timer(REFRESH_BACKEND_HEIGHT_INTERVAL, refresh_backend_height, (db,))
    BACKEND_HEIGHT_TIMER.start()


def start_refresh_backend_height(timer_db, args):
    # run the scheduler to refresh the backend height
    # `no_refresh_backend_height` used only for testing. TODO: find a way to mock it
    if "no_refresh_backend_height" not in args or not args["no_refresh_backend_height"]:
        refresh_backend_height(timer_db, start=True)
    else:
        refresh_current_block(timer_db)
        global BACKEND_HEIGHT  # noqa F811
        BACKEND_HEIGHT = 0


class GunicornArbiter(Arbiter):
    def __init__(self, app):
        super().__init__(app.cfg)
        self.app = app
        self.timeout = 30
        self.graceful_timeout = 30
        self.max_requests = 1000
        self.max_requests_jitter = 50

    def spawn_worker(self):
        self.worker_age += 1
        worker = self.worker_class(
            self.worker_age,
            self.pid,
            self.LISTENERS,
            self.app.application,
            self.timeout / 2.0,
            self.cfg,
            self.log,
        )
        self.cfg.pre_fork(self, worker)
        pid = os.fork()
        if pid != 0:
            worker.pid = pid
            self.WORKERS[pid] = worker
            return pid

        # Child process
        worker.pid = os.getpid()
        try:
            gunicorn_util._setproctitle(f"worker [{self.proc_name}]")
            logger.debug("Booting Gunicorn worker with pid: %s", worker.pid)
            self.cfg.post_fork(self, worker)
            worker.init_process()
            sys.exit(0)
        except SystemExit:
            raise
        except AppImportError:
            self.log.debug("Exception while loading the application", exc_info=True)
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

    def kill_all_workers(self):
        for pid in list(self.WORKERS.keys()):
            try:
                os.kill(pid, signal.SIGKILL)
            except ProcessLookupError:
                pass


class GunicornApplication(gunicorn.app.base.BaseApplication):
    def __init__(self, app, args=None):
        self.options = {
            "bind": "%s:%s" % (config.API_HOST, config.API_PORT),
            "workers": config.GUNICORN_WORKERS,
            "worker_class": "gthread",
            "daemon": True,
            "threads": config.GUNICORN_THREADS_PER_WORKER,
            "loglevel": "debug",
            "access-logfile": "-",
            "errorlog": "-",
            "capture_output": True,
        }
        self.application = app
        self.args = args
        self.arbiter = None
        self.timer_db = None
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
        self.timer_db = get_db_connection(config.API_DATABASE, read_only=True, check_wal=False)
        start_refresh_backend_height(self.timer_db, self.args)
        return self.application

    def run(self):
        try:
            self.arbiter = GunicornArbiter(self)
            self.arbiter.run()
        except RuntimeError as e:
            logger.error("Error in GUnicorn: %s", e)
            sys.stderr.flush()
            sys.exit(1)

    def stop(self):
        if BACKEND_HEIGHT_TIMER:
            BACKEND_HEIGHT_TIMER.cancel()
        if self.arbiter:
            self.arbiter.kill_all_workers()


class WerkzeugApplication:
    def __init__(self, app, args=None):
        self.app = app
        self.args = args
        self.timer_db = get_db_connection(config.API_DATABASE, read_only=True, check_wal=False)
        self.server = make_server(config.API_HOST, config.API_PORT, self.app, threaded=True)

    def run(self):
        start_refresh_backend_height(self.timer_db, self.args)
        self.server.serve_forever()

    def stop(self):
        self.server.shutdown()
        self.server.server_close()


class WaitressApplication:
    def __init__(self, app, args=None):
        self.app = app
        self.args = args
        self.timer_db = get_db_connection(config.API_DATABASE, read_only=True, check_wal=False)
        self.server = waitress.server.create_server(
            self.app, host=config.API_HOST, port=config.API_PORT, threads=config.WAITRESS_THREADS
        )

    def run(self):
        start_refresh_backend_height(self.timer_db, self.args)
        self.server.run()

    def stop(self):
        self.server.close()


class WSGIApplication:
    def __init__(self, app, args=None):
        self.app = app
        self.args = args
        if config.WSGI_SERVER == "gunicorn":
            self.server = GunicornApplication(self.app, self.args)
        elif config.WSGI_SERVER == "werkzeug":
            self.server = WerkzeugApplication(self.app, self.args)
        else:
            self.server = WaitressApplication(self.app, self.args)

    def run(self):
        self.server.run()

    def stop(self):
        self.server.stop()

