import time

from counterpartycore.lib.api import wsgi


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

    with test_helpers.capture_log(caplog, "Hello"):
        lazy_logger.debug("Hello")
    assert lazy_logger.last_print > last_print
