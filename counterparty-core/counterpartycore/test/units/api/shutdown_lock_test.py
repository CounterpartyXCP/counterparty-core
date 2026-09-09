"""A SQLite close holding db_lock must not defeat the API shutdown budget."""

import threading
import time
from unittest.mock import MagicMock

import pytest
from counterpartycore.lib.api import apiwatcher, wsgi


@pytest.mark.parametrize("cls", [apiwatcher.APIWatcher, wsgi.NodeStatusCheckerThread])
def test_stop_does_not_wait_for_a_slow_database_close(cls):
    worker = cls.__new__(cls)
    threading.Thread.__init__(worker)
    worker.stop_event = threading.Event()
    worker.db_lock = threading.Lock()
    worker.state_db = MagicMock()
    worker.ledger_db = MagicMock()
    worker.is_alive = MagicMock(return_value=True)
    worker.join = MagicMock()
    worker.db_lock.acquire()
    finished = threading.Event()

    def stop():
        try:
            worker.stop(deadline=time.monotonic() + 0.02)
        finally:
            finished.set()

    caller = threading.Thread(target=stop)
    caller.start()
    try:
        assert finished.wait(0.5), "stop blocked behind SQLite close despite its deadline"
        assert worker.stop_event.is_set()
        worker.state_db.interrupt.assert_not_called()
        worker.ledger_db.interrupt.assert_not_called()
    finally:
        worker.db_lock.release()
        caller.join(timeout=2)
    assert not caller.is_alive()
