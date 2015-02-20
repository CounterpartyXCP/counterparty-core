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

def set_up(logger, verbose=False, logfile=None):
    log_level = logging.DEBUG if verbose else logging.INFO
    logger.setLevel(log_level)

    # Console Logging
    console = logging.StreamHandler()
    console.setLevel(log_level)
    LOGFORMAT = '%(log_color)s[%(levelname)s] %(message)s%(reset)s'
    LOGCOLORS = {'WARNING': 'yellow', 'ERROR': 'red', 'CRITICAL': 'red'}
    formatter = ColoredFormatter(LOGFORMAT, log_colors=LOGCOLORS)
    console.setFormatter(formatter)
    logger.addHandler(console)

    # File Logging
    if logfile:
        max_log_size = 20 * 1024 * 1024 # 20 MB
        if os.name == 'nt':
            from counterpartylib.lib import util_windows
            fileh = util_windows.SanitizedRotatingFileHandler(logfile, maxBytes=max_log_size, backupCount=5)
        else:
            fileh = logging.handlers.RotatingFileHandler(logfile, maxBytes=max_log_size, backupCount=5)
        fileh.setLevel(logging.DEBUG)
        LOGFORMAT = '%(asctime)s [%(levelname)s] %(message)s'
        formatter = logging.Formatter(LOGFORMAT, '%Y-%m-%d-T%H:%M:%S%z')
        fileh.setFormatter(formatter)
        logger.addHandler(fileh)

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

def curr_time():
    return int(time.time())

def isodt (epoch_time):
    try:
        return datetime.fromtimestamp(epoch_time, tzlocal()).isoformat()
    except OSError:
        return '<datetime>'

def message(db, block_index, command, category, bindings, tx_hash=None):
    cursor = db.cursor()

    # Get last message index.
    messages = list(cursor.execute('''SELECT * FROM messages
                                      WHERE message_index = (SELECT MAX(message_index) from messages)'''))
    if messages:
        assert len(messages) == 1
        message_index = messages[0]['message_index'] + 1
    else:
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
    for item in sorted(bindings.items()):
        if type(item[1]) == bytes:
            items.append((item[0], binascii.hexlify(item[1]).decode('ascii')))
        else:
            items.append(item)

    bindings_string = json.dumps(collections.OrderedDict(items))
    cursor.execute('insert into messages values(:message_index, :block_index, :command, :category, :bindings, :timestamp)',
                   (message_index, block_index, command, category, bindings_string, curr_time()))

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

    # Slow?!
    def output (quantity, asset):
        try:
            if asset not in ('fraction', 'leverage'):
                return str(util.value_out(db, quantity, asset)) + ' ' + asset
            else:
                return str(util.value_out(db, quantity, asset))
        except exceptions.AssetError:
            return '<AssetError>'
        except decimal.DivisionByZero:
            return '<DivisionByZero>'
        except TypeError:
            return '<None>'

    if command == 'update':
        if category == 'order':
            logger.debug('Database: set status of order {} to {}.'.format(bindings['tx_hash'], bindings['status']))
        elif category == 'bet':
            logger.debug('Database: set status of bet {} to {}.'.format(bindings['tx_hash'], bindings['status']))
        elif category == 'order_matches':
            logger.debug('Database: set status of order_match {} to {}.'.format(bindings['order_match_id'], bindings['status']))
        elif category == 'bet_matches':
            logger.debug('Database: set status of bet_match {} to {}.'.format(bindings['bet_match_id'], bindings['status']))
        # TODO: elif category == 'balances':
            # logger.debug('Database: set balance of {} in {} to {}.'.format(bindings['address'], bindings['asset'], output(bindings['quantity'], bindings['asset']).split(' ')[0]))

    elif command == 'insert':

        if category == 'credits':
            logger.debug('Credit: {} to {} #{}# <{}>'.format(output(bindings['quantity'], bindings['asset']), bindings['address'], bindings['action'], bindings['event']))

        elif category == 'debits':
            logger.debug('Debit: {} from {} #{}# <{}>'.format(output(bindings['quantity'], bindings['asset']), bindings['address'], bindings['action'], bindings['event']))

        elif category == 'sends':
            logger.info('Send: {} from {} to {} ({}) [{}]'.format(output(bindings['quantity'], bindings['asset']), bindings['source'], bindings['destination'], bindings['tx_hash'], bindings['status']))

        elif category == 'orders':
            logger.info('Order: {} ordered {} for {} in {} blocks, with a provided fee of {} {} and a required fee of {} {} ({}) [{}]'.format(bindings['source'], output(bindings['give_quantity'], bindings['give_asset']), output(bindings['get_quantity'], bindings['get_asset']), bindings['expiration'], bindings['fee_provided'] / config.UNIT, config.BTC, bindings['fee_required'] / config.UNIT, config.BTC, bindings['tx_hash'], bindings['status']))

        elif category == 'order_matches':
            logger.info('Order Match: {} for {} ({}) [{}]'.format(output(bindings['forward_quantity'], bindings['forward_asset']), output(bindings['backward_quantity'], bindings['backward_asset']), bindings['id'], bindings['status']))

        elif category == 'btcpays':
            logger.info('{} Payment: {} paid {} to {} for order match {} ({}) [{}]'.format(config.BTC, bindings['source'], output(bindings['btc_amount'], config.BTC), bindings['destination'], bindings['order_match_id'], bindings['tx_hash'], bindings['status']))

        elif category == 'issuances':
            if bindings['transfer']:
                logger.info('Issuance: {} transfered asset {} to {} ({}) [{}]'.format(bindings['source'], bindings['asset'], bindings['issuer'], bindings['tx_hash'], bindings['status']))
            elif bindings['locked']:
                logger.info('Issuance: {} locked asset {} ({}) [{}]'.format(bindings['issuer'], bindings['asset'], bindings['tx_hash'], bindings['status']))
            else:
                if bindings['divisible']:
                    divisibility = 'divisible'
                    unit = config.UNIT
                else:
                    divisibility = 'indivisible'
                    unit = 1
                try:
                    quantity = util.value_out(db, bindings['quantity'], None, divisible=bindings['divisible'])
                except Exception as e:
                    quantity = '?'
                logger.info('Issuance: {} created {} of {} asset {} ({}) [{}]'.format(bindings['issuer'], quantity, divisibility, bindings['asset'], bindings['tx_hash'], bindings['status']))

        elif category == 'broadcasts':
            if bindings['locked']:
                logger.info('Broadcast: {} locked his feed ({}) [{}]'.format(bindings['source'], bindings['tx_hash'], bindings['status']))
            else:
                logger.info('Broadcast: ' + bindings['source'] + ' at ' + isodt(bindings['timestamp']) + ' with a fee of {}%'.format(output(D(bindings['fee_fraction_int'] / 1e8) * D(100), 'fraction')) + ' (' + bindings['tx_hash'] + ')' + ' [{}]'.format(bindings['status']))

        elif category == 'bets':
            logger.info('Bet: {} against {}, by {}, on {}'.format(output(bindings['wager_quantity'], config.XCP), output(bindings['counterwager_quantity'], config.XCP), bindings['source'], bindings['feed_address']))

        elif category == 'bet_matches':
            placeholder = ''
            if bindings['target_value'] >= 0:    # Only non‐negative values are valid.
                placeholder = ' that ' + str(output(bindings['target_value'], 'value'))
            if bindings['leverage']:
                placeholder += ', leveraged {}x'.format(output(bindings['leverage'] / 5040, 'leverage'))
            logger.info('Bet Match: {} for {} against {} for {} on {} at {}{} ({}) [{}]'.format(util.BET_TYPE_NAME[bindings['tx0_bet_type']], output(bindings['forward_quantity'], config.XCP), util.BET_TYPE_NAME[bindings['tx1_bet_type']], output(bindings['backward_quantity'], config.XCP), bindings['feed_address'], isodt(bindings['deadline']), placeholder, bindings['id'], bindings['status']))

        elif category == 'dividends':
            logger.info('Dividend: {} paid {} per unit of {} ({}) [{}]'.format(bindings['source'], output(bindings['quantity_per_unit'], bindings['dividend_asset']), bindings['asset'], bindings['tx_hash'], bindings['status']))

        elif category == 'burns':
            logger.info('Burn: {} burned {} for {} ({}) [{}]'.format(bindings['source'], output(bindings['burned'], config.BTC), output(bindings['earned'], config.XCP), bindings['tx_hash'], bindings['status']))

        elif category == 'cancels':
            logger.info('Cancel: {} ({}) [{}]'.format(bindings['offer_hash'], bindings['tx_hash'], bindings['status']))

        elif category == 'rps':
            log_message = 'RPS: {} opens game with {} possible moves and a wager of {}'.format(bindings['source'], bindings['possible_moves'], output(bindings['wager'], 'XCP'))
            logger.info(log_message)

        elif category == 'rps_matches':
            log_message = 'RPS Match: {} is playing a {}-moves game with {} with a wager of {} ({}) [{}]'.format(bindings['tx0_address'], bindings['possible_moves'], bindings['tx1_address'], output(bindings['wager'], 'XCP'), bindings['id'], bindings['status'])
            logger.info(log_message)

        elif category == 'rpsresolves':

            if bindings['status'] == 'valid':
                rps_matches = list(cursor.execute('''SELECT * FROM rps_matches WHERE id = ?''', (bindings['rps_match_id'],)))
                assert len(rps_matches) == 1
                rps_match = rps_matches[0]
                log_message = 'RPS Resolved: {} is playing {} on a {}-moves game with {} with a wager of {} ({}) [{}]'.format(rps_match['tx0_address'], bindings['move'], rps_match['possible_moves'], rps_match['tx1_address'], output(rps_match['wager'], 'XCP'), rps_match['id'], rps_match['status'])
            else:
                log_message = 'RPS Resolved: {} [{}]'.format(bindings['tx_hash'], bindings['status'])
            logger.info(log_message)

        elif category == 'order_expirations':
            logger.info('Expired order: {}'.format(bindings['order_hash']))

        elif category == 'order_match_expirations':
            logger.info('Expired Order Match awaiting payment: {}'.format(bindings['order_match_id']))

        elif category == 'bet_expirations':
            logger.info('Expired bet: {}'.format(bindings['bet_hash']))

        elif category == 'bet_match_expirations':
            logger.info('Expired Bet Match: {}'.format(bindings['bet_match_id']))

        elif category == 'bet_match_resolutions':
            # DUPE
            cfd_type_id = util.BET_TYPE_ID['BullCFD'] + util.BET_TYPE_ID['BearCFD']
            equal_type_id = util.BET_TYPE_ID['Equal'] + util.BET_TYPE_ID['NotEqual']

            if bindings['bet_match_type_id'] == cfd_type_id:
                if bindings['settled']:
                    logger.info('Bet Match Settled: {} credited to the bull, {} credited to the bear, and {} credited to the feed address ({})'.format(output(bindings['bull_credit'], config.XCP), output(bindings['bear_credit'], config.XCP), output(bindings['fee'], config.XCP), bindings['bet_match_id']))
                else:
                    logger.info('Bet Match Force‐Liquidated: {} credited to the bull, {} credited to the bear, and {} credited to the feed address ({})'.format(output(bindings['bull_credit'], config.XCP), output(bindings['bear_credit'], config.XCP), output(bindings['fee'], config.XCP), bindings['bet_match_id']))

            elif bindings['bet_match_type_id'] == equal_type_id:
                logger.info('Bet Match Settled: {} won the pot of {}; {} credited to the feed address ({})'.format(bindings['winner'], output(bindings['escrow_less_fee'], config.XCP), output(bindings['fee'], config.XCP), bindings['bet_match_id']))

        elif category == 'rps_expirations':
            logger.info('Expired RPS: {}'.format(bindings['rps_hash']))

        elif category == 'rps_match_expirations':
            logger.info('Expired RPS Match: {}'.format(bindings['rps_match_id']))

        elif category == 'contracts':
            logger.info('New Contract: {}'.format(bindings['contract_id']))

        elif category == 'executions':
            """
            try:
                payload_hex = binascii.hexlify(bindings['payload']).decode('ascii')
            except TypeError:
                payload_hex = '<None>'
            try:
                output_hex = binascii.hexlify(bindings['output']).decode('ascii')
            except TypeError:
                output_hex = '<None>'
            logger.info('Execution: {} executed contract {}, funded with {}, at a price of {} (?), at a final cost of {}, reclaiming {}, and also sending {}, with a data payload of {}, yielding {} ({}) [{}]'.format(bindings['source'], bindings['contract_id'], output(bindings['gas_start'], config.XCP), bindings['gas_price'], output(bindings['gas_cost'], config.XCP), output(bindings['gas_remaining'], config.XCP), output(bindings['value'], config.XCP), payload_hex, output_hex, bindings['tx_hash'], bindings['status']))
            """
            if bindings['contract_id']:
                logger.info('Execution: {} executed contract {} ({}) [{}]'.format(bindings['source'], bindings['contract_id'], bindings['tx_hash'], bindings['status']))
            else:
                logger.info('Execution: {} created contract {} ({}) [{}]'.format(bindings['source'], bindings['output'], bindings['tx_hash'], bindings['status']))

        elif category == 'destructions':
            logger.info('Destruction: {} destroyed {} {} with tag ‘{}’({}) [{}]'.format(bindings['source'], bindings['quantity'], bindings['asset'], bindings['tag'], bindings['tx_hash'], bindings['status']))

    cursor.close()

# vim: tabstop=8 expandtab shiftwidth=4 softtabstop=4
