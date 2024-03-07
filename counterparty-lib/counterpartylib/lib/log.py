import logging
logger = logging.getLogger(__name__)
import decimal
D = decimal.Decimal
import binascii
import collections
import json
import time
from datetime import datetime
from dateutil.tz import tzlocal
import os
from colorlog import ColoredFormatter

from counterpartylib.lib import config
from counterpartylib.lib import exceptions
from counterpartylib.lib import util
from counterpartylib.lib import ledger

class ModuleLoggingFilter(logging.Filter):
    """
    module level logging filter (NodeJS-style), ie:
        filters="*,-counterpartylib.lib,counterpartylib.lib.api"

        will log:
         - counterpartycli.server
         - counterpartylib.lib.api

        but will not log:
         - counterpartylib.lib
         - counterpartylib.lib.backend.indexd
    """

    def __init__(self, filters):
        self.filters = str(filters).split(",")

        self.catchall = "*" in self.filters
        if self.catchall:
            self.filters.remove("*")

    def filter(self, record):
        """
        Determine if specified record should be logged or not
        """
        result = None

        for filter in self.filters:
            if filter[:1] == "-":
                if result is None and ModuleLoggingFilter.ismatch(record, filter[1:]):
                    result = False
            else:
                if ModuleLoggingFilter.ismatch(record, filter):
                    result = True

        if result is None:
            return self.catchall

        return result

    @classmethod
    def ismatch(cls, record, name):
        """
        Determine if the specified record matches the name, in the same way as original logging.Filter does, ie:
            'counterpartylib.lib' will match 'counterpartylib.lib.check'
        """
        nlen = len(name)
        if nlen == 0:
            return True
        elif name == record.name:
            return True
        elif record.name.find(name, 0, nlen) != 0:
            return False
        return record.name[nlen] == "."


ROOT_LOGGER = None
def set_logger(logger):
    global ROOT_LOGGER
    if ROOT_LOGGER is None:
        ROOT_LOGGER = logger


LOGGING_SETUP = False
LOGGING_TOFILE_SETUP = False
def set_up(logger, verbose=False, logfile=None, console_logfilter=None, quiet=True):
    global LOGGING_SETUP
    global LOGGING_TOFILE_SETUP

    def set_up_file_logging():
        assert logfile
        max_log_size = 20 * 1024 * 1024 # 20 MB
        if os.name == 'nt':
            from counterpartylib.lib import util_windows
            fileh = util_windows.SanitizedRotatingFileHandler(logfile, maxBytes=max_log_size, backupCount=5)
        else:
            fileh = logging.handlers.RotatingFileHandler(logfile, maxBytes=max_log_size, backupCount=5)
        fileh.setLevel(logging.DEBUG)
        log_format = '%(asctime)s [%(levelname)s] %(message)s'
        formatter = logging.Formatter(log_format, '%Y-%m-%d-T%H:%M:%S%z')
        fileh.setFormatter(formatter)
        logger.addHandler(fileh)

    if LOGGING_SETUP:
        if logfile and not LOGGING_TOFILE_SETUP:
            set_up_file_logging()
            LOGGING_TOFILE_SETUP = True
        logger.getChild('log.set_up').debug('logging already setup')
        return
    LOGGING_SETUP = True

    if verbose and not quiet:
        log_level = logging.DEBUG
    elif verbose and quiet:
        log_level = logging.INFO
    else:
        log_level = logging.ERROR
    logger.setLevel(log_level)

    # Console Logging
    console = logging.StreamHandler()
    console.setLevel(log_level)

    # only add [%(name)s] to log_format if we're using console_logfilter
    log_format = '%(log_color)s[%(asctime)s][%(levelname)s]' + ('' if console_logfilter is None else '[%(name)s]') + ' %(message)s%(reset)s'
    log_colors = {'WARNING': 'yellow', 'ERROR': 'red', 'CRITICAL': 'red'}
    formatter = ColoredFormatter(log_format, "%Y-%m-%d %H:%M:%S", log_colors=log_colors)
    console.setFormatter(formatter)
    logger.addHandler(console)

    if console_logfilter:
        console.addFilter(ModuleLoggingFilter(console_logfilter))

    # File Logging
    if logfile:
        set_up_file_logging()
        LOGGING_TOFILE_SETUP = True

    # Quieten noisy libraries.
    requests_log = logging.getLogger("requests")
    requests_log.setLevel(log_level)
    requests_log.propagate = False
    urllib3_log = logging.getLogger('urllib3')
    urllib3_log.setLevel(log_level)
    urllib3_log.propagate = False

    # Disable InsecureRequestWarning
    import requests
    requests.packages.urllib3.disable_warnings()

# we are using a function here for testing purposes
def curr_time():
    return int(time.time())

def isodt (epoch_time):
    try:
        return datetime.fromtimestamp(epoch_time, tzlocal()).isoformat()
    except OSError:
        return '<datetime>'

def message(db, block_index, command, category, bindings, tx_hash=None):
    if command == '\n':
        return

    cursor = db.cursor()

    # Get last message index.
    try:
        message = ledger.last_message(db)
        message_index = message['message_index'] + 1
    except exceptions.DatabaseError:
        message_index = 0

    # Not to be misleading…
    if block_index == config.MEMPOOL_BLOCK_INDEX:
        try:
            del bindings['status']
            del bindings['block_index']
            del bindings['tx_index']
        except KeyError:
            pass

    # Handle binary data.
    items = []
    for item in sorted(bindings):
        if type(item) == bytes:
            items.append(binascii.hexlify(item).decode('ascii'))
        else:
            items.append(item)

    current_time = curr_time()
    bindings_string = str(items)
    cursor.execute('insert into messages values(:message_index, :block_index, :command, :category, :bindings, :timestamp)',
                   (message_index, block_index, command, category, bindings_string, current_time))

    # Log only real transactions.
    if block_index != config.MEMPOOL_BLOCK_INDEX:
        log(db, command, category, bindings)

    cursor.close()


def log (db, command, category, bindings):

    cursor = db.cursor()

    for element in bindings.keys():
        try:
            str(bindings[element])
        except KeyError:
            bindings[element] = '<Error>'

    def output (quantity, asset):

        try:
            if asset not in ('fraction', 'leverage'):
                # Only log quantity at `DEBUG`, for speed.
                if logging.DEBUG <= logger.getEffectiveLevel():
                    return asset
                else:
                    return str(util.value_out(db, quantity, asset)) + ' ' + asset
            else:
                return str(ledger.value_out(db, quantity, asset))
        except exceptions.AssetError:
            return '<AssetError>'
        except decimal.DivisionByZero:
            return '<DivisionByZero>'
        except TypeError:
            return '<None>'

    if command == 'update':
        if category == 'order':
            logger.debug(f"Database: set status of order {bindings['tx_hash']} to {bindings['status']}.")
        elif category == 'bet':
            logger.debug(f"Database: set status of bet {bindings['tx_hash']} to {bindings['status']}.")
        elif category == 'order_matches':
            logger.debug(f"Database: set status of order_match {bindings['order_match_id']} to {bindings['status']}.")
        elif category == 'bet_matches':
            logger.debug(f"Database: set status of bet_match {bindings['bet_match_id']} to {bindings['status']}.")
        elif category == 'dispensers':
            escrow_quantity = ''
            divisible = ledger.get_asset_info(db, bindings['asset'])['divisible']

            if "escrow_quantity" in bindings:
                if divisible:
                    quantity = bindings["escrow_quantity"]/config.UNIT
                    escrow_quantity = f"{quantity:.8f}"
                else:
                    escrow_quantity = bindings["escrow_quantity"]

            if ("action" in bindings) and bindings["action"] == 'refill dispenser':
                logger.info(f"Dispenser: {bindings['source']} refilled a dispenser with {escrow_quantity} {bindings['asset']}")
            elif "prev_status" in bindings: #There was a dispense
                if bindings["prev_status"] == 0:
                    if bindings["status"] == 10:
                        if bindings["closing_reason"] == "no_more_to_give" or bindings["closing_reason"] == "depleted":
                            logger.info(f"Dispenser: {bindings['source']} closed dispenser for {bindings['asset']} (dispenser empty)")
                        elif bindings["closing_reason"] == "max_dispenses_reached":
                            logger.info(f"Dispenser: {bindings['source']} closed dispenser for {bindings['asset']} (dispenser reached max dispenses limit)")

            elif bindings["status"] == 10 or bindings["status"] == 11: #Address closed the dispenser

                if bindings["status"] == 10:
                    operator_string = "operator closed"
                else:
                    operator_string = "operator marked the dispenser to close it"

                if ledger.enabled("dispenser_origin_permission_extended", bindings['block_index']) and ("origin" in bindings) and bindings['source'] != bindings['origin']:
                    if bindings["status"] == 10:
                        operator_string = "closed by origin"
                    else:
                        operator_string = "marked to close by origin"

                logger.info(f"Dispenser: {bindings['source']} closed dispenser for {bindings['asset']} ({operator_string})")
        # TODO: elif category == 'balances':
            # logger.debug(f"Database: set balance of {bindings['address']} in {bindings['asset']} to {output(bindings['quantity']}."")

    elif command == 'insert':

        if category == 'credits':
            logger.debug(f"Credit: {output(bindings['quantity'], bindings['asset'])} to {bindings['address']} #{bindings['action']}# <{bindings['event']}>")

        elif category == 'debits':
            logger.debug(f"Debit: {output(bindings['quantity'], bindings['asset'])} from {bindings['address']} #{bindings['action']}# <{bindings['event']}>")

        elif category == 'sends':
            logger.info(f"Send: {output(bindings['quantity'], bindings['asset'])} from {bindings['source']} to {bindings['destination']} ({bindings['tx_hash']}) [{bindings['status']}]")

        elif category == 'orders':
            logger.info(f"Order: {bindings['source']} ordered {output(bindings['give_quantity'], bindings['give_asset'])} for {output(bindings['get_quantity'], bindings['get_asset'])} in {bindings['expiration']} blocks, with a provided fee of {bindings['fee_provided'] / config.UNIT:.8f} {config.BTC} and a required fee of {bindings['fee_required'] / config.UNIT:.8f} {config.BTC} ({bindings['tx_hash']}) [{bindings['status']}]")

        elif category == 'order_matches':
            logger.info(f"Order Match: {output(bindings['forward_quantity'], bindings['forward_asset'])} for {output(bindings['backward_quantity'], bindings['backward_asset'])} ({bindings['id']}) [{bindings['status']}]")

        elif category == 'btcpays':
            logger.info(f"{config.BTC} Payment: {bindings['source']} paid {output(bindings['btc_amount'], config.BTC)} to {bindings['destination']} for order match {bindings['order_match_id']} ({bindings['tx_hash']}) [{bindings['status']}]")

        elif category == 'issuances':
            if (ledger.get_asset_issuances_quantity(db, bindings["asset"]) == 0) or (bindings['quantity'] > 0): #This is the first issuance or the creation of more supply, so we have to log the creation of the token
                if bindings['divisible']:
                    divisibility = 'divisible'
                    unit = config.UNIT
                else:
                    divisibility = 'indivisible'
                    unit = 1
                try:
                    quantity = ledger.value_out(db, bindings['quantity'], None, divisible=bindings['divisible'])
                except Exception as e:
                    quantity = '?'

                if 'asset_longname' in bindings and bindings['asset_longname'] is not None:
                    logger.info(f"Subasset Issuance: {bindings['source']} created {quantity} of {divisibility} subasset {bindings['asset_longname']} as numeric asset {bindings['asset']} ({bindings['tx_hash']}) [{bindings['status']}]")
                else:
                    logger.info(f"Issuance: {bindings['source']} created {quantity} of {divisibility} asset {bindings['asset']} ({bindings['tx_hash']}) [{bindings['status']}]")

            if bindings['locked']:
                lock_issuance = get_lock_issuance(db, bindings["asset"])

                if (lock_issuance == None) or (lock_issuance['tx_hash'] == bindings['tx_hash']):
                    logger.info(f"Issuance: {bindings['source']} locked asset {bindings['asset']} ({bindings['tx_hash']}) [{bindings['status']}]")

            if bindings['transfer']:
                logger.info(f"Issuance: {bindings['source']} transfered asset {bindings['asset']} to {bindings['issuer']} ({bindings['tx_hash']}) [{bindings['status']}]")

        elif category == 'broadcasts':
            if bindings['locked']:
                logger.info(f"Broadcast: {bindings['source']} locked his feed ({bindings['tx_hash']}) [{bindings['status']}]")
            else:
                logger.info(f"Broadcast: {bindings['source']} at {isodt(bindings['timestamp'])} with a fee of {output(D(bindings['fee_fraction_int'] / 1e8), 'fraction')}% ({bindings['tx_hash']}) [{bindings['status']}]")

        elif category == 'bets':
            logger.info(f"Bet: {output(bindings['wager_quantity'], config.XCP)} against {output(bindings['counterwager_quantity'], config.XCP)}, by {bindings['source']}, on {bindings['feed_address']}")

        elif category == 'bet_matches':
            placeholder = ''
            if bindings['target_value'] >= 0:    # Only non‐negative values are valid.
                placeholder = ' that ' + str(output(bindings['target_value'], 'value'))
            if bindings['leverage']:
                placeholder += f", leveraged {output(bindings['leverage'] / 5040, 'leverage')}x"
            logger.info(f"Bet Match: {util.BET_TYPE_NAME[bindings['tx0_bet_type']]} for {output(bindings['forward_quantity'], config.XCP)} against {util.BET_TYPE_NAME[bindings['tx1_bet_type']]} for {output(bindings['backward_quantity'], config.XCP)} on {bindings['feed_address']} at {isodt(bindings['deadline'])}{placeholder} ({bindings['id']}) [{bindings['status']}]")

        elif category == 'dividends':
            logger.info(f"Dividend: {bindings['source']} paid {output(bindings['quantity_per_unit'], bindings['dividend_asset'])} per unit of {bindings['asset']} ({bindings['tx_hash']}) [{bindings['status']}]")

        elif category == 'burns':
            logger.info(f"Burn: {bindings['source']} burned {output(bindings['burned'], config.BTC)} for {output(bindings['earned'], config.XCP)} ({bindings['tx_hash']}) [{bindings['status']}]")

        elif category == 'cancels':
            logger.info(f"Cancel: {bindings['offer_hash']} ({bindings['tx_hash']}) [{bindings['status']}]")

        elif category == 'rps':
            log_message = f"RPS: {bindings['source']} opens game with {bindings['possible_moves']} possible moves and a wager of {output(bindings['wager'], 'XCP')}"
            logger.info(log_message)

        elif category == 'rps_matches':
            log_message = f"RPS Match: {bindings['tx0_address']} is playing a {bindings['possible_moves']}-moves game with {bindings['tx1_address']} with a wager of {output(bindings['wager'], 'XCP')} ({bindings['id']}) [{bindings['status']}]"
            logger.info(log_message)

        elif category == 'rpsresolves':

            if bindings['status'] == 'valid':
                rps_matches = ledger.get_rps_match(db, id=bindings['rps_match_id'])
                assert len(rps_matches) == 1
                rps_match = rps_matches[0]
                log_message = f"RPS Resolved: {rps_match['tx0_address']} is playing {bindings['move']} on a {rps_match['possible_moves']}-moves game with {rps_match['tx1_address']} with a wager of {output(rps_match['wager'], 'XCP')} ({rps_match['id']}) [{rps_match['status']}]"
            else:
                log_message = f"RPS Resolved: {bindings['tx_hash']} [{bindings['status']}]"
            logger.info(log_message)

        elif category == 'order_expirations':
            logger.info(f"Expired order: {bindings['order_hash']}")

        elif category == 'order_match_expirations':
            logger.info(f"Expired Order Match awaiting payment: {bindings['order_match_id']}")

        elif category == 'bet_expirations':
            logger.info(f"Expired bet: {bindings['bet_hash']}")

        elif category == 'bet_match_expirations':
            logger.info(f"Expired Bet Match: {bindings['bet_match_id']}")

        elif category == 'bet_match_resolutions':
            # DUPE
            cfd_type_id = util.BET_TYPE_ID['BullCFD'] + util.BET_TYPE_ID['BearCFD']
            equal_type_id = util.BET_TYPE_ID['Equal'] + util.BET_TYPE_ID['NotEqual']

            if bindings['bet_match_type_id'] == cfd_type_id:
                if bindings['settled']:
                    logger.info(f"Bet Match Settled: {output(bindings['bull_credit'], config.XCP)} credited to the bull, {output(bindings['bear_credit'], config.XCP)} credited to the bear, and {output(bindings['fee'], config.XCP)} credited to the feed address ({bindings['bet_match_id']})")
                else:
                    logger.info(f"Bet Match Force‐Liquidated: {output(bindings['bull_credit'], config.XCP)} credited to the bull, {output(bindings['bear_credit'], config.XCP)} credited to the bear, and {output(bindings['fee'], config.XCP)} credited to the feed address ({bindings['bet_match_id']})")

            elif bindings['bet_match_type_id'] == equal_type_id:
                logger.info(f"Bet Match Settled: {bindings['winner']} won the pot of {output(bindings['escrow_less_fee'], config.XCP)}; {output(bindings['fee'], config.XCP)} credited to the feed address ({bindings['bet_match_id']})")

        elif category == 'rps_expirations':
            logger.info(f"Expired RPS: {bindings['rps_hash']}")

        elif category == 'rps_match_expirations':
            logger.info(f"Expired RPS Match: {bindings['rps_match_id']}")

        elif category == 'destructions':

            try:
                asset_info = ledger.get_asset_info(db, bindings['asset'])
                quantity = bindings['quantity']
                if asset_info['divisible']:
                    quantity = f"{quantity/config.UNIT:.8f}"
            except IndexError as e:
                quantity = '?'

            logger.info(f"Destruction: {bindings['source']} destroyed {quantity} {bindings['asset']} with tag ‘{bindings['tag']}’({bindings['tx_hash']}) [{bindings['status']}]")

        elif category == 'dispensers':
            each_price = bindings['satoshirate']
            currency = config.BTC
            dispenser_label = 'dispenser'
            escrow_quantity = bindings['escrow_quantity']
            give_quantity = bindings['give_quantity']

            if (bindings['oracle_address'] != None) and ledger.enabled('oracle_dispensers'):
                each_price = f"{each_price/100.0:.2f}"
                oracle_last_price, oracle_fee, currency, oracle_last_updated = ledger.get_oracle_last_price(db, bindings['oracle_address'], bindings['block_index'])
                dispenser_label = f"oracle dispenser using {bindings['oracle_address']}"
            else:
                each_price = f"{each_price/config.UNIT:.8f}"

            divisible = ledger.get_asset_info(db, bindings['asset'])['divisible']

            if divisible:
                escrow_quantity = f"{escrow_quantity/config.UNIT:.8f}"
                give_quantity = f"{give_quantity/config.UNIT:.8f}"

            if bindings['status'] == 0:
                logger.info(f"Dispenser: {bindings['source']} opened a {dispenser_label} for asset {bindings['asset']} with {escrow_quantity} balance, giving {give_quantity} {bindings['asset']} for each {each_price} {currency}")
            elif bindings['status'] == 1:
                logger.info(f"Dispenser: {bindings['source']} (empty address) opened a {dispenser_label} for asset {bindings['asset']} with {escrow_quantity} balance, giving {give_quantity} {bindings['asset']} for each {each_price} {currency}")
            elif bindings['status'] == 10:
                logger.info(f"Dispenser: {bindings['source']} closed a {dispenser_label} for asset {bindings['asset']}")

        elif category == 'dispenses':
            dispensers = ledger.get_dispenser(db, tx_hash=bindings['dispenser_tx_hash'])
            dispenser = dispensers[0]

            if (dispenser["oracle_address"] != None) and ledger.enabled('oracle_dispensers'):
                tx_btc_amount = get_tx_info(db, bindings['tx_hash'])/config.UNIT
                oracle_last_price, oracle_fee, oracle_fiat_label, oracle_last_price_updated = ledger.get_oracle_last_price(db, dispenser["oracle_address"], bindings['block_index'])
                fiatpaid = round(tx_btc_amount*oracle_last_price,2)

                logger.info(f"Dispense: {output(bindings['dispense_quantity'], bindings['asset'])} from {bindings['source']} to {bindings['destination']} for {tx_btc_amount:.8f} {config.BTC} ({fiatpaid} {oracle_fiat_label}) ({bindings['tx_hash']})")
            else:
                logger.info(f"Dispense: {output(bindings['dispense_quantity'], bindings['asset'])} from {bindings['source']} to {bindings['destination']} ({bindings['tx_hash']})")

    cursor.close()

def get_lock_issuance(db, asset):
    issuances = ledger.get_issuances(db, status='valid', asset=asset, locked=True, first=True)

    if len(issuances) > 0:
        return issuances[0]

    return None


def get_tx_info(db, tx_hash):
    transactions = ledger.get_transactions(db, tx_hash=tx_hash)
    transaction = transactions[0]

    return transaction["btc_amount"]
