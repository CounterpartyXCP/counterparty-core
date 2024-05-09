import decimal
import logging
import sys
import traceback
from datetime import datetime
from logging.handlers import RotatingFileHandler

from colorlog import ColoredFormatter
from dateutil.tz import tzlocal
from termcolor import cprint

from counterpartycore.lib import config

logging.TRACE = logging.DEBUG - 5
logging.addLevelName(logging.TRACE, "TRACE")
logger = logging.getLogger(config.LOGGER_NAME)

D = decimal.Decimal


def trace(self, msg, *args, **kwargs):
    self._log(logging.TRACE, msg, args, **kwargs)


def set_up(verbose=0, quiet=True, log_file=None, log_in_console=False):
    logging.Logger.trace = trace

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
    elif verbose > 1:
        log_level = logging.TRACE

    logger.setLevel(log_level)

    # File Logging
    if log_file:
        max_log_size = 20 * 1024 * 1024  # 20 MB
        fileh = RotatingFileHandler(log_file, maxBytes=max_log_size, backupCount=5)
        fileh.setLevel(logging.TRACE)
        log_format = "%(asctime)s [%(levelname)s] %(message)s"
        formatter = logging.Formatter(log_format, "%Y-%m-%d-T%H:%M:%S%z")
        fileh.setFormatter(formatter)
        logger.addHandler(fileh)

    if log_in_console:
        console = logging.StreamHandler()
        console.setLevel(log_level)
        log_format = "%(log_color)s[%(asctime)s][%(levelname)s] %(message)s%(reset)s"
        log_colors = {"WARNING": "yellow", "ERROR": "red", "CRITICAL": "red"}
        formatter = ColoredFormatter(log_format, "%Y-%m-%d %H:%M:%S", log_colors=log_colors)
        console.setFormatter(formatter)
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


EVENTS = {
    "NEW_BLOCK": "New block inserted %(block_index)s",
    "NEW_TRANSACTION": "New transaction inserted %(tx_hash)s",
    "NEW_TRANSACTION_OUTPUT": "New transaction output inserted %(tx_hash)s",
    "DEBIT": "Debit %(quantity)s %(asset)s from %(address)s",
    "CREDIT": "Credit %(quantity)s %(asset)s to %(address)s",
    "OPEN_BET": "Opened bet %(tx_hash)s",
    "BET_MATCH": "Bet match %(tx0_index)s for %(forward_quantity)s XCP against %(backward_quantity)s XCP on %(feed_address)s",
    "BET_EXPIRATION": "Bet %(bet_hash)s expired",
    "BET_MATCH_EXPIRATION": "Bet match %(bet_match_id)s expired",
    "BROADCAST": "Broadcast %(tx_hash)s: %(text)s",
    "BET_MATCH_RESOLUTON": "Bet match %(bet_match_id)s resolved",
    "BTC_PAY": "BTC payment for order match %(order_match_id)s",
    "BURN": "Burned %(burned)s BTC for %(earned)s XCP",
    "CANCEL_BET": "Bet %(tx_hash)s canceled",
    "CANCEL_ORDER": "Order %(tx_hash)s canceled",
    "CANCEL_RPS": "RPS %(tx_hash)s canceled",
    "INVALID_CANCEL": "Invalid cancel transaction %(tx_hash)s",
    "ASSET_DESTRUCTION": "%(quantity)s %(asset)s destroyed",
    "OPEN_DISPENSER": "Opened dispenser for %(asset)s at %(source)s",
    "REFILL_DISPENSER": "Dispenser refilled for %(asset)s at %(source)s",
    "DISPENSE": "%(dispense_quantity)s %(asset)s dispensed from %(source)s to %(destination)s",
    "ASSET_DIVIDEND": "Dividend of %(quantity_per_unit)s %(dividend_asset)s per unit of %(asset)s",
    "RESET_ISSUANCE": "Issuance of %(asset)s reset",
    "ASSET_CREATION": "Asset %(asset_name)s created",
    "ASSET_ISSUANCE": "Asset %(asset)s issued",
    "ORDER_EXPIRATION": "Order %(order_hash)s expired",
    "ORDER_MATCH_EXPIRATION": "Order match %(order_match_id)s expired",
    "OPEN_ORDER": "Order opened for %(give_quantity)s %(give_asset)s at %(source)s",
    "ORDER_MATCH": "Order match %(id)s for %(forward_quantity)s %(forward_asset)s against %(backward_quantity)s %(backward_asset)s",
    "OPEN_RPS": "Player %(source)s opened RPS game with %(possible_moves)s possible moves and a wager of %(wager)s XCP",
    "RPS_MATCH": "RPS match %(id)s for %(tx0_address)s against %(tx1_address)s with a wager of %(wager)s XCP",
    "RPS_EXPIRATION": "RPS %(rps_hash)s expired",
    "RPS_MATCH_EXPIRATION": "RPS match %(rps_match_id)s expired",
    "RPS_RESOLVE": "RPS %(tx_hash)s resolved",
    "ASSET_TRANSFER": "Asset %(asset)s transferred to %(issuer)s",
    "SWEEP": "Sweep from %(source)s to %(destination)s",
    "ENHANCED_SEND": "Send (ENHANCED) %(quantity)s %(asset)s from %(source)s to %(destination)s",
    "MPMA_SEND": "Send (MPMA) %(quantity)s %(asset)s from %(source)s to %(destination)s",
    "SEND": "Send %(quantity)s %(asset)s from %(source)s to %(destination)s",
    "DISPENSER_UPDATE": "Updated dispenser for %(asset)s at %(source)s. New status: %(status)s",
    "BET_UPDATE": "Updated bet %(tx_hash)s. New status: %(status)s",
    "BET_MATCH_UPDATE": "Updated bet match %(id)s. New status: %(status)s",
    "ORDER_UPDATE": "Updated order %(tx_hash)s. New status: %(status)s",
    "ORDER_FILLED": "Order %(tx_hash)s filled",
    "ORDER_MATCH_UPDATE": "Order match %(id)s updated. New status: %(status)s",
    "RPS_MATCH_UPDATE": "Updated RPS match %(id)s. New status: %(status)s",
    "RPS_UPDATE": "RPS %(tx_hash)s updated. New status: %(status)s",
    "BLOCK_PARSED": "Block %(block_index)s parsed, ledger hash is %(ledger_hash)s and txlist hash is %(txlist_hash)s",
    "TRANSACTION_PARSED": "Transaction %(tx_hash)s parsed. Supported: %(supported)s",
}


def log_event(event_name, bindings):
    if config.JSON_LOG:
        logger.info({"event": event_name, "bindings": bindings})
    elif event_name in EVENTS:
        logger.info(EVENTS[event_name], bindings)


def shutdown():
    logger.info("Shutting down logging...")
    logging.shutdown()
