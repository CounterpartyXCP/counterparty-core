#! /usr/bin/python3
#
# What is a dispenser?
#
# A dispenser is a type of order where the holder address gives out a given amount
# of units of an asset for a given amount of BTC satoshis received.
# It's a very simple but powerful semantic to allow swaps to operate on-chain.
#

import binascii
import json
import pprint
import struct
import logging
import warnings
from math import floor
logger = logging.getLogger(__name__)

from counterpartylib.lib import config
from counterpartylib.lib import exceptions
from counterpartylib.lib import util
from counterpartylib.lib import log
from counterpartylib.lib import message_type
from counterpartylib.lib import address
from counterpartylib.lib import backend

FORMAT = '>QQQQB'
LENGTH = 33
ID = 12
DISPENSE_ID = 13

STATUS_OPEN = 0
STATUS_OPEN_EMPTY_ADDRESS = 1
#STATUS_OPEN_ORACLE_PRICE = 20
#STATUS_OPEN_ORACLE_PRICE_EMPTY_ADDRESS = 21
STATUS_CLOSED = 10
STATUS_CLOSING = 11

def initialise(db):
    cursor = db.cursor()
    cursor.execute('''CREATE TABLE IF NOT EXISTS dispensers(
                      tx_index INTEGER PRIMARY KEY,
                      tx_hash TEXT UNIQUE,
                      block_index INTEGER,
                      source TEXT,
                      asset TEXT,
                      give_quantity INTEGER,
                      escrow_quantity INTEGER,
                      satoshirate INTEGER,
                      status INTEGER,
                      give_remaining INTEGER,
                      FOREIGN KEY (tx_index, tx_hash, block_index) REFERENCES transactions(tx_index, tx_hash, block_index))
                   ''')
                      # Disallows invalids: FOREIGN KEY (order_match_id) REFERENCES order_matches(id))
    cursor.execute('''CREATE INDEX IF NOT EXISTS
                      dispensers_source_idx ON dispensers (source)
                   ''')
    cursor.execute('''CREATE INDEX IF NOT EXISTS
                      dispensers_asset_idx ON dispensers (asset)
                   ''')

    cursor.execute('''CREATE TABLE IF NOT EXISTS dispenses(
                      tx_index INTEGER,
                      dispense_index INTEGER,
                      tx_hash TEXT,
                      block_index INTEGER,
                      source TEXT,
                      destination TEXT,
                      asset TEXT,
                      dispense_quantity INTEGER,
                      dispenser_tx_hash TEXT,
                      PRIMARY KEY (tx_index, dispense_index, source, destination),
                      FOREIGN KEY (tx_index, tx_hash, block_index) REFERENCES transactions(tx_index, tx_hash, block_index))
                   ''')
                   
    cursor.execute('''CREATE TABLE IF NOT EXISTS dispenser_refills(
                      tx_index INTEGER,
                      tx_hash TEXT,
                      block_index INTEGER,
                      source TEXT,
                      destination TEXT,
                      asset TEXT,
                      dispense_quantity INTEGER,
                      dispenser_tx_hash TEXT,
                      PRIMARY KEY (tx_index, tx_hash, source, destination),
                      FOREIGN KEY (tx_index, tx_hash, block_index) REFERENCES transactions(tx_index, tx_hash, block_index))
                   ''')                
                   
    columns = [column['name'] for column in cursor.execute('''PRAGMA table_info(dispenses)''')]
    if 'dispenser_tx_hash' not in columns:
        cursor.execute('ALTER TABLE dispenses ADD COLUMN dispenser_tx_hash TEXT')
    
    columns = [column['name'] for column in cursor.execute('''PRAGMA table_info(dispensers)''')]
    if 'oracle_address' not in columns:
        cursor.execute('ALTER TABLE dispensers ADD COLUMN oracle_address TEXT')
    
    #this column will be used to know when a dispenser was marked to close
    if 'last_status_tx_hash' not in columns:
        cursor.execute('ALTER TABLE dispensers ADD COLUMN last_status_tx_hash TEXT') 
        
    if "origin" not in columns:
        cursor.execute('ALTER TABLE dispensers ADD COLUMN origin TEXT')
        
        cursor.execute("UPDATE dispensers AS d SET origin = (SELECT t.source FROM transactions t WHERE d.tx_hash = t.tx_hash)")
        
        cursor.execute('''INSERT INTO dispenser_refills 
                          SELECT t.tx_index, deb.event, deb.block_index, deb.address, dis.source, deb.asset, deb.quantity, dis.tx_hash FROM debits deb 
                          LEFT JOIN transactions t ON t.tx_hash = deb.event 
                          LEFT JOIN dispensers dis ON 
                              dis.source = deb.address 
                              AND dis.asset = deb.asset 
                              AND dis.tx_index = (SELECT max(dis2.tx_index) FROM dispensers dis2 WHERE dis2.source = deb.address AND dis2.asset = deb.asset AND dis2.block_index <= deb.block_index) 
                          WHERE deb.action = 'refill dispenser' AND dis.source IS NOT NULL''');
        
        
def validate (db, source, asset, give_quantity, escrow_quantity, mainchainrate, status, open_address, block_index, oracle_address):
    problems = []
    order_match = None
    asset_id = None

    if asset == config.BTC:
        problems.append('cannot dispense %s' % config.BTC)
        return None, problems

    # resolve subassets
    asset = util.resolve_subasset_longname(db, asset)

    if status == STATUS_OPEN or status == STATUS_OPEN_EMPTY_ADDRESS:
        if give_quantity <= 0:
            problems.append('give_quantity must be positive')
        if mainchainrate <= 0:
            problems.append('mainchainrate must be positive')
        if escrow_quantity < give_quantity:
            problems.append('escrow_quantity must be greater or equal than give_quantity')
    elif not(status == STATUS_CLOSED):
        problems.append('invalid status %i' % status)

    cursor = db.cursor()
    cursor.execute('''SELECT quantity FROM balances \
                      WHERE address = ? and asset = ?''', (source,asset,))
    available = cursor.fetchall()

    if len(available) == 0:
        problems.append('address doesn\'t has the asset %s' % asset)
    elif len(available) >= 1 and available[0]['quantity'] < escrow_quantity:
        problems.append('address doesn\'t has enough balance of %s (%i < %i)' % (asset, available[0]['quantity'], escrow_quantity))
    else:
        if status == STATUS_OPEN_EMPTY_ADDRESS and not(open_address):
            open_address = source
            status = STATUS_OPEN
        
        
        if util.enabled("dispenser_origin_permission_extended", block_index) and status == STATUS_CLOSED and open_address and open_address != source:
            cursor.execute('''SELECT * FROM dispensers WHERE source = ? AND asset = ? AND status IN (0,11) AND origin=?''', (open_address, asset, source))
        else:
            query_address = open_address if status == STATUS_OPEN_EMPTY_ADDRESS else source
            cursor.execute('''SELECT * FROM dispensers WHERE source = ? AND asset = ? AND status IN (0,11)''', (query_address, asset))
        open_dispensers = cursor.fetchall()
        if len(open_dispensers) == 0 or open_dispensers[0]["status"] != STATUS_CLOSING:
            if status == STATUS_OPEN or status == STATUS_OPEN_EMPTY_ADDRESS:
                if len(open_dispensers) > 0:
                    max_refills = util.get_value_by_block_index("max_refills", block_index)
                    refilling_count = 0                
                    if max_refills > 0:
                        cursor.execute('''SELECT count(*) cnt FROM dispenser_refills WHERE dispenser_tx_hash = ?''', (open_dispensers[0]["tx_hash"],))
                        refilling_count = cursor.fetchall()[0]['cnt']
            
                    #It's a valid refill
                    if open_dispensers[0]['satoshirate'] == mainchainrate and open_dispensers[0]['give_quantity'] == give_quantity:
                        if (max_refills > 0) and (refilling_count >= max_refills):
                            problems.append('the dispenser reached its maximum refilling')
                    else:
                        if open_dispensers[0]['satoshirate'] != mainchainrate:
                            problems.append('address has a dispenser already opened for asset %s with a different mainchainrate' % asset)
                        if open_dispensers[0]['give_quantity'] != give_quantity:
                            problems.append('address has a dispenser already opened for asset %s with a different give_quantity' % asset)
            elif status == STATUS_CLOSED:               
                if len(open_dispensers) == 0:
                    problems.append('address doesnt has an open dispenser for asset %s' % asset)

            if status == STATUS_OPEN_EMPTY_ADDRESS:
                #If an address is trying to refill a dispenser in a different address and it's the creator
                if not (util.enabled("dispenser_origin_permission_extended", block_index) and (len(open_dispensers) > 0) and (open_dispensers[0]["origin"] == source)):
                    cursor.execute('''SELECT count(*) cnt FROM dispensers WHERE source = ? AND status = ? AND origin = ?''', (query_address,STATUS_CLOSED,source))
                    dispensers_from_same_origin = cursor.fetchall()
                    
                    if not (util.enabled("dispenser_origin_permission_extended", block_index) and dispensers_from_same_origin[0]['cnt'] > 0):
                    #It means that the same origin has not opened other dispensers in this address
                        cursor.execute('''SELECT count(*) cnt FROM balances WHERE address = ?''', (query_address,))
                        existing_balances = cursor.fetchall()
                    
                        if existing_balances[0]['cnt'] > 0:
                            problems.append('cannot open on another address if it has any balance history')
                        
                        if util.enabled("dispenser_origin_permission_extended", block_index):
                            address_oldest_transaction = backend.get_oldest_tx(query_address)
                            if ("block_index" in address_oldest_transaction) and (address_oldest_transaction["block_index"] > 0) and (block_index > address_oldest_transaction["block_index"]):
                                problems.append('cannot open on another address if it has any confirmed bitcoin txs')

            if len(problems) == 0:
                asset_id = util.generate_asset_id(asset, block_index)
                if asset_id == 0:
                    problems.append('cannot dispense %s' % asset) # How can we test this on a test vector?
        else:
            problems.append('address has already a dispenser about to close, no action can be taken until it closes')
    
    cursor.close()
    
    if oracle_address is not None and util.enabled('oracle_dispensers', block_index):
        last_price, last_fee, last_label, last_updated = util.get_oracle_last_price(db, oracle_address, block_index)
        
        if last_price is None:
            problems.append('The oracle address %s has not broadcasted any price yet' % oracle_address)
    
    if give_quantity > config.MAX_INT or escrow_quantity > config.MAX_INT or mainchainrate > config.MAX_INT:
        problems.append('integer overflow')

    if len(problems) > 0:
        return None, problems
    else:
        return asset_id, None

def compose (db, source, asset, give_quantity, escrow_quantity, mainchainrate, status, open_address=None, oracle_address=None):
    assetid, problems = validate(db, source, asset, give_quantity, escrow_quantity, mainchainrate, status, open_address, util.CURRENT_BLOCK_INDEX, oracle_address)
    if problems: raise exceptions.ComposeError(problems)

    destination = []
    data = message_type.pack(ID)
    data += struct.pack(FORMAT, assetid, give_quantity, escrow_quantity, mainchainrate, status)
    if (status == STATUS_OPEN_EMPTY_ADDRESS and open_address) or (util.enabled("dispenser_origin_permission_extended") and status == STATUS_CLOSED and open_address and open_address != source):
        data += address.pack(open_address)
    if oracle_address is not None and util.enabled('oracle_dispensers'):
        oracle_fee = calculate_oracle_fee(db, escrow_quantity, give_quantity, mainchainrate, oracle_address, util.CURRENT_BLOCK_INDEX)
        
        if oracle_fee >= config.DEFAULT_REGULAR_DUST_SIZE:
            destination.append((oracle_address,oracle_fee))
        data += address.pack(oracle_address)        
        
    return (source, destination, data)

def calculate_oracle_fee(db, escrow_quantity, give_quantity, mainchainrate, oracle_address, block_index):
    last_price, last_fee, last_fiat_label, last_updated = util.get_oracle_last_price(db, oracle_address, block_index)
    last_fee_multiplier = (last_fee / config.UNIT)
        
    #Format mainchainrate to ######.##
    oracle_mainchainrate = util.satoshirate_to_fiat(mainchainrate)       
    oracle_mainchainrate_btc = oracle_mainchainrate/last_price
        
    #Calculate the total amount earned for dispenser and the fee
    remaining = int(floor(escrow_quantity / give_quantity))
    total_quantity_btc = oracle_mainchainrate_btc * remaining
    oracle_fee_btc = int(total_quantity_btc * last_fee_multiplier *config.UNIT)
    
    return oracle_fee_btc

def parse (db, tx, message):
    cursor = db.cursor()

    # Unpack message.
    try:
        action_address = tx['source']
        oracle_address = None
        assetid, give_quantity, escrow_quantity, mainchainrate, dispenser_status = struct.unpack(FORMAT, message[0:LENGTH])
        read = LENGTH
        if dispenser_status == STATUS_OPEN_EMPTY_ADDRESS or (util.enabled("dispenser_origin_permission_extended") and dispenser_status == STATUS_CLOSED and len(message) > read):
            action_address = address.unpack(message[LENGTH:LENGTH+21])
            read = LENGTH + 21
        if len(message) > read:
            oracle_address = address.unpack(message[read:read+21])
        asset = util.generate_asset_name(assetid, util.CURRENT_BLOCK_INDEX)
        status = 'valid'
    except (exceptions.UnpackError, struct.error) as e:
        assetid, give_quantity, mainchainrate, asset = None, None, None, None
        status = 'invalid: could not unpack'

    
    if status == 'valid':
        if util.enabled("dispenser_parsing_validation", util.CURRENT_BLOCK_INDEX):
            asset_id, problems = validate(db, tx['source'], asset, give_quantity, escrow_quantity, mainchainrate, dispenser_status, action_address if dispenser_status in [STATUS_OPEN_EMPTY_ADDRESS, STATUS_CLOSED] else None, tx['block_index'], oracle_address)
        else:
            problems = None
        
        if problems:
            status = 'invalid: ' + '; '.join(problems)
        else:   
            if dispenser_status == STATUS_OPEN or dispenser_status == STATUS_OPEN_EMPTY_ADDRESS:
                cursor.execute('SELECT * FROM dispensers WHERE source=:source AND asset=:asset AND status=:status', {
                    'source': action_address,
                    'asset': asset,
                    'status': STATUS_OPEN
                })
                existing = cursor.fetchall()

                if len(existing) == 0:
                    if (oracle_address != None) and util.enabled('oracle_dispensers', tx['block_index']):
                        oracle_fee = calculate_oracle_fee(db, escrow_quantity, give_quantity, mainchainrate, oracle_address, tx['block_index']) 
                           
                        if oracle_fee >= config.DEFAULT_REGULAR_DUST_SIZE:   
                            if tx["destination"] != oracle_address or tx["btc_amount"] < oracle_fee:
                                status = 'invalid: insufficient or non-existent oracle fee'
                        
                    
                    if status == 'valid':
                        # Create the new dispenser
                        try:
                            if dispenser_status == STATUS_OPEN_EMPTY_ADDRESS:
                                cursor.execute('SELECT count(*) cnt FROM balances WHERE address=:address AND quantity > 0', {
                                    'address': action_address
                                })
                                counts = cursor.fetchall()[0]

                                if counts['cnt'] == 0:
                                    util.debit(db, tx['source'], asset, escrow_quantity, action='open dispenser empty addr', event=tx['tx_hash'])
                                    util.credit(db, action_address, asset, escrow_quantity, action='open dispenser empty addr', event=tx['tx_hash'])
                                    util.debit(db, action_address, asset, escrow_quantity, action='open dispenser empty addr', event=tx['tx_hash'])
                                else:
                                    status = 'invalid: address not empty'
                            else:
                                util.debit(db, tx['source'], asset, escrow_quantity, action='open dispenser', event=tx['tx_hash'])
                        except util.DebitError as e:
                            status = 'invalid: insufficient funds'

                    if status == 'valid':
                        bindings = {
                            'tx_index': tx['tx_index'],
                            'tx_hash': tx['tx_hash'],
                            'block_index': tx['block_index'],
                            'source': action_address,
                            'asset': asset,
                            'give_quantity': give_quantity,
                            'escrow_quantity': escrow_quantity,
                            'satoshirate': mainchainrate,
                            'status': STATUS_OPEN,
                            'give_remaining': escrow_quantity,
                            'oracle_address': oracle_address,
                            'origin': tx['source']
                        }
                        
                        if util.enabled("dispenser_origin_permission_extended"):
                            bindings["origin"] = tx["source"]
                        
                        sql = '''insert into dispensers (tx_index, tx_hash, block_index, source, asset, give_quantity, escrow_quantity, satoshirate, status, give_remaining, oracle_address, origin, last_status_tx_hash)
                            values(:tx_index, :tx_hash, :block_index, :source, :asset, :give_quantity, :escrow_quantity, :satoshirate, :status, :give_remaining, :oracle_address, :origin, NULL)'''
                        cursor.execute(sql, bindings)
                elif len(existing) == 1 and existing[0]['satoshirate'] == mainchainrate and existing[0]['give_quantity'] == give_quantity:
                    if tx["source"]==action_address or (util.enabled("dispenser_origin_permission_extended", tx['block_index']) and tx["source"] == existing[0]["origin"]):
                        if (oracle_address != None) and util.enabled('oracle_dispensers', tx['block_index']):
                            oracle_fee = calculate_oracle_fee(db, escrow_quantity, give_quantity, mainchainrate, oracle_address, tx['block_index']) 
                               
                            if oracle_fee >= config.DEFAULT_REGULAR_DUST_SIZE:   
                                if tx["destination"] != oracle_address or tx["btc_amount"] < oracle_fee:
                                    status = 'invalid: insufficient or non-existent oracle fee'
                        
                        if status == 'valid':
                            # Refill the dispenser by the given amount
                            bindings = {
                                'source': tx['source'] if not util.enabled("dispenser_origin_permission_extended", tx['block_index']) else action_address,
                                'asset': asset,
                                'prev_status': dispenser_status,
                                'give_remaining': existing[0]['give_remaining'] + escrow_quantity,
                                'status': STATUS_OPEN,
                                'block_index': tx['block_index'],
                                'action':'refill dispenser',
                                'escrow_quantity':escrow_quantity
                            }
                            bindings_refill = {
                                'tx_index':tx["tx_index"],
                                'tx_hash':tx["tx_hash"],
                                'block_index':tx["block_index"],
                                'source': tx['source'],
                                'destination': action_address,
                                'asset': asset,
                                'dispenser_quantity': escrow_quantity,
                                'status': STATUS_OPEN
                            }
                            
                            try:
                                util.debit(db, tx['source'], asset, escrow_quantity, action='refill dispenser', event=tx['tx_hash'])
                                sql = 'UPDATE dispensers SET give_remaining=:give_remaining \
                                    WHERE source=:source AND asset=:asset AND status=:status'
                                cursor.execute(sql, bindings)
                                sql = "INSERT INTO dispenser_refills VALUES(:tx_index, :tx_hash, :block_index, :source, :destination, :asset, :dispenser_quantity, (SELECT tx_hash FROM dispensers WHERE source=:destination AND asset=:asset AND status=:status))"
                                cursor.execute(sql, bindings_refill)
                            except (util.DebitError):
                                status = 'insufficient funds'
                    else:
                        status = 'invalid: can only refill dispenser from source or origin'                             
                else:
                    status = 'can only have one open dispenser per asset per address'
            elif dispenser_status == STATUS_CLOSED:
                close_delay = util.get_value_by_block_index("dispenser_close_delay", tx['block_index'])
                close_from_another_address = util.enabled("dispenser_origin_permission_extended", tx['block_index']) and action_address and action_address != tx["source"]
                query_dispenser = 'SELECT tx_index, give_remaining FROM dispensers WHERE source=:source AND asset=:asset AND status=:status'
                query_bindings = {
                    'source': tx['source'],
                    'asset': asset,
                    'status': STATUS_OPEN
                }
                
                if close_from_another_address:
                    query_dispenser = query_dispenser + " AND origin=:origin"
                    query_bindings["origin"] = tx["source"]
                    query_bindings["source"] = action_address
            
                cursor.execute(query_dispenser, query_bindings)
                existing = cursor.fetchall()

                if len(existing) == 1:
                    if close_delay == 0:
                        util.credit(db, tx['source'], asset, existing[0]['give_remaining'], action='close dispenser', event=tx['tx_hash'])
                        
                        bindings = {
                            'source': tx['source'],
                            'asset': asset,
                            'status': STATUS_CLOSED,
                            'block_index': tx['block_index'],
                            'tx_index': existing[0]['tx_index']
                        }
                        sql = 'UPDATE dispensers SET give_remaining=0, status=:status WHERE source=:source AND asset=:asset'
                    else:
                        bindings = {
                            'source': tx['source'],
                            'asset': asset,
                            'status': STATUS_CLOSING,
                            'block_index': tx['block_index'],
                            'last_status_tx_hash': tx['tx_hash'],
                            'tx_index': existing[0]['tx_index']
                        }
                        sql = 'UPDATE dispensers SET status=:status, last_status_tx_hash=:last_status_tx_hash WHERE source=:source AND asset=:asset AND status IN (0,1)'

                    if close_from_another_address:
                        sql = sql + " AND origin=:origin"
                        bindings["origin"] = tx["source"]
                        bindings["source"] = action_address

                    cursor.execute(sql, bindings)
                else:
                    status = 'dispenser inexistent'
            else:
                status = 'invalid: status must be one of OPEN or CLOSE'

    if status != 'valid':
        # let use warnings.warn instead of logger.warning because we want to catch it in tests
        warnings.warn("Not storing [dispenser] tx [%s]: %s" % (tx['tx_hash'], status))

    cursor.close()

def is_dispensable(db, address, amount):
    cursor = db.cursor()
    cursor.execute('SELECT * FROM dispensers WHERE source=:source AND status IN (0,11)', {
        'source': address,
        #'status': [STATUS_OPEN, STATUS_CLOSING]
    })
    dispensers = cursor.fetchall()
    cursor.close()

    for next_dispenser in dispensers:
        if next_dispenser["oracle_address"] != None:
            last_price, last_fee, last_fiat_label, last_updated = util.get_oracle_last_price(db, next_dispenser['oracle_address'], util.CURRENT_BLOCK_INDEX)
            fiatrate = util.satoshirate_to_fiat(next_dispenser["satoshirate"])
            if amount >= fiatrate/last_price:
                return True
        else:
            if amount >= next_dispenser["satoshirate"]:
                return True

    return False

def dispense(db, tx):
    cursor = db.cursor()

    outs = []
    if util.enabled("multiple_dispenses"):
        cursor.execute('SELECT txs.source AS source, txs_outs.* FROM transaction_outputs txs_outs LEFT JOIN transactions txs ON txs.tx_hash = txs_outs.tx_hash WHERE txs_outs.tx_hash=:tx_hash ORDER BY txs_outs.out_index', {
            'tx_hash': tx['tx_hash']
        })
        outs = cursor.fetchall()
    else:
        outs = [tx]

    #if len(outs) == 0:
    #    outs = [tx]

    dispense_index = 0

    for next_out in outs:
        cursor.execute('SELECT * FROM dispensers WHERE source=:source AND status IN (0,11) ORDER BY asset', {
            'source': next_out['destination'],
            #'status': [STATUS_OPEN, STATUS_CLOSING]
        })
        dispensers = cursor.fetchall()

        for dispenser in dispensers:
            satoshirate = dispenser['satoshirate']
            give_quantity = dispenser['give_quantity']

            if satoshirate > 0 and give_quantity > 0:
                if (dispenser['oracle_address'] != None) and util.enabled('oracle_dispensers', next_out['block_index']):
                    last_price, last_fee, last_fiat_label, last_updated = util.get_oracle_last_price(db, dispenser['oracle_address'], next_out['block_index'])
                    fiatrate = util.satoshirate_to_fiat(satoshirate)
                    must_give = int(floor(((next_out['btc_amount'] / config.UNIT) * last_price)/fiatrate))
                else:
                    must_give = int(floor(next_out['btc_amount'] / satoshirate))

                remaining = int(floor(dispenser['give_remaining'] / give_quantity))
                actually_given = min(must_give, remaining) * give_quantity
                give_remaining = dispenser['give_remaining'] - actually_given

                assert give_remaining >= 0

                # Skip dispense if quantity is 0
                if util.enabled('zero_quantity_value_adjustment_1') and actually_given==0:
                    continue

                util.credit(db, next_out['source'], dispenser['asset'], actually_given, action='dispense', event=next_out['tx_hash'])

                # Checking if the dispenser reach its max dispenses limit
                max_dispenses_limit = util.get_value_by_block_index("max_dispenses_limit", next_out["block_index"])
                max_dispenser_limit_hit = False

                if max_dispenses_limit > 0:
                    sql = 'SELECT MAX(block_index) AS max_block_index FROM dispenser_refills WHERE dispenser_tx_hash = :dispenser_tx_hash'
                    cursor.execute(sql, {'dispenser_tx_hash': dispenser['tx_hash']})
                    max_block_index_result = cursor.fetchall()
                    from_block_index = 1

                    if len(max_block_index_result) > 0:
                        if max_block_index_result[0]["max_block_index"] is not None:
                            from_block_index = max_block_index_result[0]["max_block_index"]

                    sql = 'SELECT COUNT(*) AS dispenses_count FROM dispenses WHERE dispenser_tx_hash = :dispenser_tx_hash AND block_index >= :block_index'
                    cursor.execute(sql, {'dispenser_tx_hash': dispenser['tx_hash'], 'block_index': from_block_index})
                    dispenses_count_result = cursor.fetchall()[0]
                    dispenses_count = dispenses_count_result["dispenses_count"]
                    
                    if dispenses_count+1 >= max_dispenses_limit:
                        max_dispenser_limit_hit = True

                dispenser['give_remaining'] = give_remaining
                if give_remaining < dispenser['give_quantity'] or max_dispenser_limit_hit:
                    # close the dispenser
                    dispenser['give_remaining'] = 0
                    if give_remaining > 0:
                        if max_dispenser_limit_hit:
                            credit_action = 'Closed: Max dispenses reached'
                            dispenser['closing_reason'] = "max_dispenses_reached"
                        else:   
                            credit_action = 'dispenser close'
                            dispenser['closing_reason'] = "no_more_to_give"
                        
                        # return the remaining to the owner
                        util.credit(db, dispenser['source'], dispenser['asset'], give_remaining, action=credit_action, event=next_out['tx_hash'])
                    else:
                        dispenser['closing_reason'] = "depleted"
                    dispenser['status'] = STATUS_CLOSED

                dispenser['block_index'] = next_out['block_index']
                dispenser['prev_status'] = STATUS_OPEN
                cursor.execute('UPDATE DISPENSERS SET give_remaining=:give_remaining, status=:status \
                        WHERE source=:source AND asset=:asset AND satoshirate=:satoshirate AND give_quantity=:give_quantity AND status IN (0,11)', dispenser)

                bindings = {
                    'tx_index': next_out['tx_index'],
                    'tx_hash': next_out['tx_hash'],
                    'dispense_index': dispense_index,
                    'block_index': next_out['block_index'],
                    'source': next_out['destination'],
                    'destination': next_out['source'],
                    'asset': dispenser['asset'],
                    'dispense_quantity': actually_given,
                    'dispenser_tx_hash': dispenser['tx_hash']
                }
                sql = 'INSERT INTO dispenses(tx_index, dispense_index, tx_hash, block_index, source, destination, asset, dispense_quantity, dispenser_tx_hash) \
                        VALUES(:tx_index, :dispense_index, :tx_hash, :block_index, :source, :destination, :asset, :dispense_quantity, :dispenser_tx_hash);'
                cursor.execute(sql, bindings)
                dispense_index += 1

    cursor.close()

def close_pending(db, block_index):
    cursor = db.cursor()
    block_delay = util.get_value_by_block_index("dispenser_close_delay", block_index)

    if block_delay > 0:
        cursor.execute('SELECT d.*, t.source AS tx_source, t.block_index AS tx_block_index FROM dispensers d LEFT JOIN transactions t ON t.tx_hash = d.last_status_tx_hash WHERE status=:status AND last_status_tx_hash IS NOT NULL AND :block_index>=t.block_index+:delay', {
            'status': STATUS_CLOSING,
            'delay': block_delay,
            'block_index': block_index
        })
        pending_dispensers = cursor.fetchall()

        for dispenser in pending_dispensers:
            util.credit(db, dispenser['tx_source'], dispenser['asset'], dispenser['give_remaining'], action='close dispenser', event=dispenser['last_status_tx_hash'])
                        
            bindings = {
                'source': dispenser['tx_source'],
                'asset': dispenser['asset'],
                'status': STATUS_CLOSED,
                'block_index': dispenser['tx_block_index'],
                'tx_index': dispenser['tx_index']
            }
            sql = 'UPDATE dispensers SET give_remaining=0, status=:status WHERE source=:source AND asset=:asset'
            
            #closed from another address
            if dispenser['tx_source'] != dispenser['source']:
                sql = sql + " AND origin=:origin"
                bindings["origin"] = dispenser['tx_source']
                bindings["source"] = dispenser['source']
                    
            cursor.execute(sql, bindings)