import decimal
import logging
import sys
import time
import traceback
from datetime import datetime
from logging.handlers import RotatingFileHandler

import zmq
from dateutil.tz import tzlocal
from halo import Halo
from json_log_formatter import VerboseJSONFormatter
from termcolor import colored, cprint

from counterpartycore.lib import config, util
from counterpartycore.lib.api.util import inject_details, to_json

logging.TRACE = logging.DEBUG - 5
logging.addLevelName(logging.TRACE, "TRACE")
logging.EVENT = logging.DEBUG - 4
logging.addLevelName(logging.EVENT, "EVENT")

logger = logging.getLogger(config.LOGGER_NAME)

D = decimal.Decimal

OK_GREEN = colored("[OK]", "green")
SPINNER_STYLE = "bouncingBar"


def trace(self, msg, *args, **kwargs):
    self._log(logging.TRACE, msg, args, **kwargs)


def event(self, msg, *args, **kwargs):
    self._log(logging.EVENT, msg, args, **kwargs)


def debug(self, msg, *args, **kwargs):
    self._log(logging.DEBUG, msg, args, **kwargs)


def formatTime(record, datefmt=None):
    date = datetime.fromtimestamp(record.created, tzlocal())
    date_string = date.strftime("%Y-%m-%dT%H:%M:%S.%f000%z")
    # same as Rust log format
    date_string = date_string[0:-2] + ":" + date_string[-2:]
    return date_string


class CustomFormatter(logging.Formatter):
    FORMAT = "%(asctime)s - [%(levelname)8s] - %(message)s"

    COLORS = {
        logging.TRACE: "cyan",
        logging.DEBUG: "light_blue",  # D695FB 214 149 251
        logging.WARNING: "yellow",
        logging.ERROR: "red",
        logging.CRITICAL: "red",
        logging.EVENT: "light_grey",
    }

    def format(self, record):
        attrs = ["bold"] if hasattr(record, "bold") else []
        level_name_format = colored("%(levelname)8s", self.COLORS.get(record.levelno), attrs=attrs)

        if (
            record.levelno != logging.EVENT
            and util.CURRENT_BLOCK_INDEX is not None
            and "/counterpartycore/lib/messages/" in record.pathname
        ):
            if util.PARSING_MEMPOOL:
                log_format = f"%(asctime)s - [{level_name_format}] - Mempool - %(message)s"
            else:
                log_format = f"%(asctime)s - [{level_name_format}] - Block {util.CURRENT_BLOCK_INDEX} - %(message)s"
        else:
            log_format = f"%(asctime)s - [{level_name_format}] - %(message)s"

        formatter = logging.Formatter(log_format)
        if isinstance(record.args, dict):
            record.args = truncate_fields(record.args)
        formatter.formatTime = formatTime
        return formatter.format(record)


def set_up(verbose=0, quiet=True, log_file=None):
    logging.Logger.trace = trace
    logging.Logger.event = event

    loggers = [logging.getLogger(name) for name in logging.root.manager.loggerDict]
    for logger in loggers:
        logger.handlers.clear()
        logger.setLevel(logging.CRITICAL)
        logger.propagate = False

    logger = logging.getLogger(config.LOGGER_NAME)

    log_level = logging.ERROR
    if quiet:
        log_level = logging.ERROR
    elif verbose == 0:
        log_level = logging.INFO
    elif verbose == 1:
        log_level = logging.DEBUG
    elif verbose == 2:
        log_level = logging.EVENT
    elif verbose >= 3:
        log_level = logging.TRACE

    logger.setLevel(log_level)

    # File Logging
    if log_file:
        max_log_size = 20 * 1024 * 1024  # 20 MB
        fileh = RotatingFileHandler(log_file, maxBytes=max_log_size, backupCount=5)
        fileh.setLevel(logging.TRACE)
        fileh.setFormatter(VerboseJSONFormatter())
        logger.addHandler(fileh)

    if config.LOG_IN_CONSOLE:
        console = logging.StreamHandler()
        console.setLevel(log_level)
        console.setFormatter(CustomFormatter())
        logger.addHandler(console)

    # Log unhandled errors.
    def handle_exception(exc_type, exc_value, exc_traceback):
        logger.error("Unhandled Exception", exc_info=(exc_type, exc_value, exc_traceback))
        cprint("Unhandled Exception", "red", attrs=["bold"])
        traceback.print_exception(exc_type, exc_value, exc_traceback, file=sys.stderr)

    sys.excepthook = handle_exception


def isodt(epoch_time):
    try:
        return datetime.fromtimestamp(epoch_time, tzlocal()).isoformat()
    except OSError:
        return "<datetime>"


ADDRESS_FIELD = [
    "address",
    "source",
    "destination",
    "feed_address",
    "tx0_address",
    "tx1_address",
    "issuer",
]
HASH_FIELD = [
    "tx_hash",
    "bet_hash",
    "order_hash",
    "rps_hash",
    "ledger_hash",
    "txlist_hash",
    "messages_hash",
    "offer_hash",
]


def truncate_fields(bindings):
    truncated_bindings = bindings.copy()
    for key, value in truncated_bindings.items():
        if value is None:
            continue
        if key in ADDRESS_FIELD:
            truncated_bindings[key] = value[:8]
        elif key in HASH_FIELD:
            truncated_bindings[key] = value[:7]
        elif key.endswith("id") and isinstance(value, str) and "_" in value:
            part1, part2 = value.split("_")
            truncated_bindings[key] = f"{part1[:7]}_{part2[:7]}"
    return truncated_bindings


def log_event(db, block_index, event_index, event_name, bindings):
    block_name = "Mempool" if util.PARSING_MEMPOOL else f"Block {block_index}"
    log_bindings = truncate_fields(bindings)
    log_bindings = " ".join([f"{key}={value}" for key, value in log_bindings.items()])
    log_message = f"{block_name} - {event_name} [{log_bindings}]"
    logger.event(
        log_message,
        extra={"event": {"name": event_name, "block_index": block_index, **bindings}},
    )
    # Publish event to ZMQ
    if config.ENABLE_ZMQ_PUBLISHER:
        zmq_publisher = ZmqPublisher()
        zmq_event = {
            "event": event_name,
            "params": bindings,
            "mempool": util.PARSING_MEMPOOL,
        }
        if not util.PARSING_MEMPOOL:
            zmq_event["block_index"] = block_index
            zmq_event["event_index"] = event_index
        zmq_publisher.publish_event(db, zmq_event)


class Spinner:
    def __init__(self, step, done_message=None):
        self.halo = None
        self.done_message = done_message
        if not config.LOG_IN_CONSOLE:
            self.step = step
            self.halo = Halo(text=step, spinner=SPINNER_STYLE)
        logger.info(step)

    def __enter__(self):
        self.start()
        return self

    def __exit__(self, exc_type, exc_value, traceback):
        self.stop()

    def start(self):
        self.start_time = time.time()
        if self.halo:
            self.halo.start()

    def stop(self):
        duration = time.time() - self.start_time
        if self.halo:
            self.halo.stop()
            print(f"{OK_GREEN} {self.step} (in {duration:.2f}s)")
        if self.done_message:
            logger.info(self.done_message.format(duration))
        self.halo = None
        self.done_message = None

    def set_messsage(self, message):
        if self.halo:
            self.halo.text = message
            self.step = message


def shutdown():
    logger.info("Shutting down logging...")
    logging.shutdown()


class ZmqPublisher(metaclass=util.SingletonMeta):
    def __init__(self):
        self.context = zmq.Context()
        self.socket = self.context.socket(zmq.PUB)
        self.socket.bind("tcp://*:%s" % config.ZMQ_PUBLISHER_PORT)

    def publish_event(self, db, event):
        logger.trace("Publishing event: %s", event["event"])
        event = inject_details(db, event)
        self.socket.send_multipart([event["event"].encode("utf-8"), to_json(event).encode("utf-8")])

    def close(self):
        if self.socket:
            self.socket.close(linger=0)
            self.context.term()
