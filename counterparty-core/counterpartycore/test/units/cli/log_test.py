import logging

from counterpartycore.lib import config
from counterpartycore.lib.cli.log import CustomFilter
from counterpartycore.lib.ledger.currentstate import CurrentState

logger = logging.getLogger(config.LOGGER_NAME)


def test_quiet_mode(test_helpers, caplog, monkeypatch):
    monkeypatch.setattr(config, "QUIET", True)
    monkeypatch.setattr(CurrentState, "ledger_state", lambda self: "Catching Up")

    with test_helpers.capture_log(caplog, "test urgent message"):
        logger.urgent("test urgent message")

    caplog.at_level(6, logger=config.LOGGER_NAME)
    caplog.clear()
    logger.propagate = True

    logger.info("test info message")
    assert not CustomFilter().filter(caplog.records[-1])

    logger.debug("test debug message")
    assert not CustomFilter().filter(caplog.records[-1])

    logger.trace("test trace message")
    assert not CustomFilter().filter(caplog.records[-1])

    logger.urgent("test urgent message")
    assert CustomFilter().filter(caplog.records[-1])

    logger.warning("test warning message")
    assert CustomFilter().filter(caplog.records[-1])

    logger.error("test error message")
    assert CustomFilter().filter(caplog.records[-1])
