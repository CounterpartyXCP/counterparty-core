import pprint
import pytest
import logging

from counterpartylib.lib.evm import slogging


class DebugFilter(logging.Filter):
    def __init__(self):
        self.records = []

    def filter(self, record):
        self.records.append(record)
        return True


def setup_new_slogger():
    logger = logging.getLogger()

    slogger = slogging.get_logger('TEST', logger=logger)

    assert isinstance(slogger.logger, logging.getLoggerClass())
    assert slogger.logger.name == "TEST"

    debugger = DebugFilter()
    streamhandler = logging.StreamHandler()
    streamhandler.addFilter(debugger)
    slogger.logger.addHandler(streamhandler)

    return slogger, logger, debugger


def test_slogging_setup():
    slogger = slogging.get_logger('TEST')

    assert isinstance(slogger.logger, logging.getLoggerClass())
    assert slogger.logger.name == "slogging_test.TEST"


def test_slogging_levels():
    slogger, logger, debugger = setup_new_slogger()

    assert len(debugger.records) == 0

    # when the root logger is set to DEBUG we should see DEBUG
    logger.setLevel(logging.DEBUG)
    slogger.debug("TESTING1")
    assert len(debugger.records) == 1 and \
           debugger.records[0].msg == "TESTING1"

    # when the root logger is set to INFO we shouldn't see DEBUG
    logger.setLevel(logging.INFO)
    slogger.debug("TESTING2")
    assert len(debugger.records) == 1

    # but still see WARN
    slogger.warn("TESTING3")
    assert len(debugger.records) == 2 and \
           debugger.records[1].msg == "TESTING3"

    # when the root logger is set to DEBUG we should see TRACE, because we don't differentiate
    logger.setLevel(logging.DEBUG)
    slogger.trace("TESTING4")
    assert len(debugger.records) == 3 and \
           debugger.records[2].msg == "TESTING4"


def test_slogging_kwargs():
    slogger, logger, debugger = setup_new_slogger()
    logger.setLevel(logging.DEBUG)

    # kwargs only
    slogger.debug("", test1=1, test2=2)
    assert len(debugger.records) == 1 and \
           debugger.records[0].msg == " test1=1, test2=2"

    # test1 in msg
    slogger.debug("{test1}", test1=1, test2=2)
    assert len(debugger.records) == 2 and \
           debugger.records[1].msg == "1 test1=1, test2=2"

    # test1 and test2 in msg
    slogger.debug("{test1}//{test2}:", test1=1, test2=2)
    assert len(debugger.records) == 3 and \
           debugger.records[2].msg == "1//2: test1=1, test2=2"

    # alphabetic order of kwargs
    slogger.debug("", a=1, b=2)
    assert len(debugger.records) == 4 and \
           debugger.records[3].msg == " a=1, b=2"

    # alphabetic order of kwargs
    slogger.debug("", b=1, a=2)
    assert len(debugger.records) == 5 and \
           debugger.records[4].msg == " a=2, b=1"

    # fixated order of sender before data
    slogger.debug("", data=1, sender=2)
    assert len(debugger.records) == 6 and \
           debugger.records[5].msg == " sender=2, data=1"

    # fixated order of sender before data, before non fixated
    slogger.debug("", data=1, sender=2, a=3)
    assert len(debugger.records) == 7 and \
           debugger.records[6].msg == " sender=2, data=1, a=3"
