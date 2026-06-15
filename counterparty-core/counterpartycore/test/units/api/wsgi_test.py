import errno
import time
from types import SimpleNamespace
from unittest.mock import MagicMock

from counterpartycore.lib.api import wsgi


def test_format_bind_address():
    assert wsgi.format_bind_address("127.0.0.1", 4000) == "127.0.0.1:4000"
    assert wsgi.format_bind_address("localhost", 4000) == "localhost:4000"
    assert wsgi.format_bind_address("::1", 4000) == "[::1]:4000"
    assert wsgi.format_bind_address("::", 4000) == "[::]:4000"


def test_lazy_logger(caplog, test_helpers):
    lazy_logger = wsgi.LazyLogger()
    assert lazy_logger.last_message is None
    assert lazy_logger.last_print == 0
    assert lazy_logger.message_delay == 10

    with test_helpers.capture_log(caplog, "Coucou"):
        lazy_logger.debug("Coucou")
    assert lazy_logger.last_message == "Coucou"
    assert lazy_logger.last_print > 0
    last_print = lazy_logger.last_print

    caplog.clear()
    with test_helpers.capture_log(caplog, "Coucou", not_in=True):
        lazy_logger.debug("Coucou")
    assert lazy_logger.last_message == "Coucou"
    assert lazy_logger.last_print == last_print

    lazy_logger.message_delay = 0.1
    time.sleep(0.2)

    caplog.clear()
    with test_helpers.capture_log(caplog, "Coucou"):
        lazy_logger.debug("Coucou")
    assert lazy_logger.last_print > last_print
    last_print = lazy_logger.last_print

    with test_helpers.capture_log(caplog, "Hello", not_in=True):
        lazy_logger.debug("Hello")
    assert lazy_logger.last_print == last_print

    time.sleep(0.2)
    with test_helpers.capture_log(caplog, "Hello"):
        lazy_logger.debug("Hello")
    assert lazy_logger.last_print > last_print


def test_refresh_current_state_api_only(monkeypatch):
    shared_backend_height = SimpleNamespace(value=0)
    monkeypatch.setattr(wsgi.apiwatcher, "get_last_block_parsed", lambda _db: 7)
    monkeypatch.setattr(wsgi.CurrentState, "set_current_block_index", lambda _self, _idx: None)
    monkeypatch.setattr(wsgi.CurrentState, "current_block_index", lambda _self: 7)
    monkeypatch.setattr(wsgi.config, "API_ONLY", True)

    logger = wsgi.LazyLogger()
    logger.debug = MagicMock()

    wsgi.refresh_current_state(object(), shared_backend_height)

    logger.debug.assert_not_called()


def test_refresh_current_state_logs(monkeypatch):
    shared_backend_height = SimpleNamespace(value=int(5 * 10e8 + 100))
    monkeypatch.setattr(wsgi.apiwatcher, "get_last_block_parsed", lambda _db: 1)
    monkeypatch.setattr(wsgi.CurrentState, "set_current_block_index", lambda _self, _idx: None)
    monkeypatch.setattr(wsgi.CurrentState, "current_block_index", lambda _self: 1)
    monkeypatch.setattr(wsgi.config, "API_ONLY", False)
    monkeypatch.setattr(wsgi.config, "BLOCK_FIRST", 10)

    logger = wsgi.LazyLogger()
    logger.debug = MagicMock()

    wsgi.refresh_current_state(object(), shared_backend_height)
    assert logger.debug.call_count == 2

    logger.debug.reset_mock()
    shared_backend_height.value = int(1 * 10e8 + 50)
    monkeypatch.setattr(wsgi.CurrentState, "current_block_index", lambda _self: 5)
    monkeypatch.setattr(wsgi.config, "BLOCK_FIRST", 0)

    wsgi.refresh_current_state(object(), shared_backend_height)
    logger.debug.assert_called_once()


def test_node_status_checker_thread_run_and_stop(monkeypatch):
    closed = {"value": False}

    class DummyDB:
        def close(self):
            closed["value"] = True

    monkeypatch.setattr(wsgi.database, "get_db_connection", lambda _path: DummyDB())

    thread = wsgi.NodeStatusCheckerThread(SimpleNamespace(value=0))

    def fake_refresh(_state_db, _shared_backend_height):
        thread.stop_event.set()

    monkeypatch.setattr(wsgi, "refresh_current_state", fake_refresh)

    thread.run()

    assert closed["value"] is True


def test_werkzeug_application_run_and_stop(monkeypatch):
    server_ready_value = SimpleNamespace(value=0)
    shared_backend_height = SimpleNamespace(value=0)

    class DummyServer:
        def __init__(self):
            self.served = False
            self.shutdown_called = False
            self.closed = False

        def serve_forever(self):
            self.served = True

        def shutdown(self):
            self.shutdown_called = True

        def server_close(self):
            self.closed = True

    class DummyThread:
        def __init__(self, _shared_backend_height):
            self.started = False
            self.stopped = False

        def start(self):
            self.started = True

        def stop(self):
            self.stopped = True

    dummy_server = DummyServer()

    monkeypatch.setattr(wsgi, "make_server", lambda *_args, **_kwargs: dummy_server)
    monkeypatch.setattr(wsgi, "NodeStatusCheckerThread", DummyThread)
    monkeypatch.setattr(wsgi.CurrentState, "set_backend_height_value", lambda _self, _value: None)

    app = wsgi.WerkzeugApplication(lambda *_args, **_kwargs: None)
    app.run(server_ready_value, shared_backend_height)
    assert dummy_server.served is True

    app.stop()
    assert dummy_server.shutdown_called is True
    assert dummy_server.closed is True
    assert server_ready_value.value == 2


def test_waitress_application_run_ignores_bad_fd(monkeypatch):
    server_ready_value = SimpleNamespace(value=0)
    shared_backend_height = SimpleNamespace(value=0)

    class DummyServer:
        def __init__(self):
            self.closed = False

        def run(self):
            raise OSError(errno.EBADF, "Bad file descriptor")

        def close(self):
            self.closed = True

    class DummyThread:
        def __init__(self, _shared_backend_height):
            self.started = False
            self.stopped = False

        def start(self):
            self.started = True

        def stop(self):
            self.stopped = True

    dummy_server = DummyServer()

    monkeypatch.setattr(
        wsgi.waitress.server, "create_server", lambda *_args, **_kwargs: dummy_server
    )
    monkeypatch.setattr(wsgi, "NodeStatusCheckerThread", DummyThread)
    monkeypatch.setattr(wsgi.CurrentState, "set_backend_height_value", lambda _self, _value: None)

    app = wsgi.WaitressApplication(lambda *_args, **_kwargs: None)
    app.run(server_ready_value, shared_backend_height)

    app.stop()
    assert dummy_server.closed is True
    assert server_ready_value.value == 2


def test_wsgi_application_selects_server(monkeypatch):
    monkeypatch.setattr(wsgi.config, "WSGI_SERVER", "werkzeug")
    app = wsgi.WSGIApplication(lambda *_args, **_kwargs: None)
    assert isinstance(app.server, wsgi.WerkzeugApplication)

    monkeypatch.setattr(wsgi.config, "WSGI_SERVER", "gunicorn")
    app = wsgi.WSGIApplication(lambda *_args, **_kwargs: None)
    assert isinstance(app.server, wsgi.GunicornApplication)

    monkeypatch.setattr(wsgi.config, "WSGI_SERVER", "waitress")
    app = wsgi.WSGIApplication(lambda *_args, **_kwargs: None)
    assert isinstance(app.server, wsgi.WaitressApplication)


def test_gunicorn_application_run_and_stop(monkeypatch):
    server_ready_value = SimpleNamespace(value=0)
    shared_backend_height = SimpleNamespace(value=0)

    class DummyThread:
        def __init__(self, _shared_backend_height):
            self.started = False
            self.stopped = False

        def start(self):
            self.started = True

        def stop(self):
            self.stopped = True

    class DummyArbiter:
        def __init__(self, app):
            self.app = app
            self.run_called = False
            self.killed = False

        def run(self):
            self.run_called = True

        def kill_all_workers(self):
            self.killed = True

    monkeypatch.setattr(wsgi, "NodeStatusCheckerThread", DummyThread)
    monkeypatch.setattr(wsgi, "GunicornArbiter", DummyArbiter)
    monkeypatch.setattr(wsgi.CurrentState, "set_backend_height_value", lambda _self, _value: None)

    app = wsgi.GunicornApplication(lambda *_args, **_kwargs: None)
    app.load_config()
    app.run(server_ready_value, shared_backend_height)
    assert isinstance(app.arbiter, DummyArbiter)
    assert app.arbiter.run_called is True

    app.stop()
    assert app.arbiter.killed is True
    assert server_ready_value.value == 2


def test_gunicorn_application_uses_ipv6_bind(monkeypatch):
    monkeypatch.setattr(wsgi.config, "API_HOST", "::1")
    monkeypatch.setattr(wsgi.config, "API_PORT", 4000)

    app = wsgi.GunicornApplication(lambda *_args, **_kwargs: None)

    assert app.options["bind"] == "[::1]:4000"
