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
from counterpartylib.lib import ledger
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
    cursor.execute('''CREATE INDEX IF NOT EXISTS
                      source_status_dix ON dispensers (source, status)
                   ''')
    cursor.execute('''CREATE INDEX IF NOT EXISTS
                      source_asset_status_idx ON dispensers (source, asset, status)
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
    cursor.execute('''CREATE INDEX IF NOT EXISTS
                        dispenses_tx_hash_idx ON dispenses (tx_hash)
                    ''')
    cursor.execute('''CREATE INDEX IF NOT EXISTS
                        dispenses_block_index_idx ON dispenses (block_index)
                    ''')
    cursor.execute('''CREATE INDEX IF NOT EXISTS
                        dispenser_refills_tx_hash_idx ON dispenser_refills (tx_hash)
                    ''')
    cursor.execute('''CREATE INDEX IF NOT EXISTS
                        dispenser_refills_block_index_idx ON dispenser_refills (block_index)
                    ''')
    cursor.execute('''CREATE INDEX IF NOT EXISTS
                        dispensers_status_idx ON dispensers (status)
                    ''')
    cursor.execute('''CREATE INDEX IF NOT EXISTS
                    dispensers_asset_idx ON dispensers (asset)
                ''')
    cursor.execute('''CREATE INDEX IF NOT EXISTS
                    dispensers_source_idx ON dispensers (source)
                ''')
    cursor.execute('''CREATE INDEX IF NOT EXISTS
                    dispensers_give_remaining_idx ON dispensers (give_remaining)
                ''')
    cursor.execute('''CREATE INDEX IF NOT EXISTS
                    dispensers_status_block_index_idx ON dispensers (status, block_index)
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
        cursor.execute('''CREATE INDEX IF NOT EXISTS
                        dispensers_last_status_tx_hash_idx ON dispensers (last_status_tx_hash)
                    ''')
        
    if "origin" not in columns:
        cursor.execute('ALTER TABLE dispensers ADD COLUMN origin TEXT')
        cursor.execute('''CREATE INDEX IF NOT EXISTS
                      source_status_origin_idx ON dispensers (source, status, origin)
                   ''')
        cursor.execute('''CREATE INDEX IF NOT EXISTS
                        source_asset_status_origin_idx ON dispensers (source, asset, status, origin)
                    ''')
        
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
    asset = ledger.resolve_subasset_longname(db, asset)

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
    available = ledger.get_balance(db, source, asset)

    if available == 0:
        problems.append('address doesn\'t has the asset %s' % asset)
    elif available < escrow_quantity:
        problems.append('address doesn\'t has enough balance of %s (%i < %i)' % (asset, available, escrow_quantity))
    else:
        if status == STATUS_OPEN_EMPTY_ADDRESS and not(open_address):
            open_address = source
            status = STATUS_OPEN

        open_dispensers = []
        if ledger.enabled("dispenser_origin_permission_extended", block_index) and status == STATUS_CLOSED and open_address and open_address != source:
            open_dispensers = ledger.get_dispensers(db, status_in=[0, 11], source=open_address, asset=asset, origin=source)
        else:
            query_address = open_address if status == STATUS_OPEN_EMPTY_ADDRESS else source
            open_dispensers = ledger.get_dispensers(db, status_in=[0, 11], source=query_address, asset=asset)

        if len(open_dispensers) == 0 or open_dispensers[0]["status"] != STATUS_CLOSING:
            if status == STATUS_OPEN or status == STATUS_OPEN_EMPTY_ADDRESS:
                if len(open_dispensers) > 0:
                    max_refills = ledger.get_value_by_block_index("max_refills", block_index)
                    refilling_count = 0                
                    if max_refills > 0:
                        refilling_count = ledger.get_refilling_count(db, dispenser_tx_hash=open_dispensers[0]["tx_hash"])
            
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
                if not (ledger.enabled("dispenser_origin_permission_extended", block_index) and (len(open_dispensers) > 0) and (open_dispensers[0]["origin"] == source)):
                    dispensers_from_same_origin_count = ledger.get_dispensers_count(db,
                                                                                    source=query_address,
                                                                                    status=STATUS_CLOSED,
                                                                                    origin=source)
                    
                    if not (ledger.enabled("dispenser_origin_permission_extended", block_index) and dispensers_from_same_origin_count > 0):
                    #It means that the same origin has not opened other dispensers in this address
                        existing_balances = ledger.get_balances_count(db, query_address)

                        if existing_balances[0]['cnt'] > 0:
                            problems.append('cannot open on another address if it has any balance history')
                        
                        if ledger.enabled("dispenser_origin_permission_extended", block_index):
                            address_oldest_transaction = backend.get_oldest_tx(query_address)
                            if ("block_index" in address_oldest_transaction) and (address_oldest_transaction["block_index"] > 0) and (block_index > address_oldest_transaction["block_index"]):
                                problems.append('cannot open on another address if it has any confirmed bitcoin txs')

            if len(problems) == 0:
                asset_id = ledger.generate_asset_id(asset, block_index)
                if asset_id == 0:
                    problems.append('cannot dispense %s' % asset) # How can we test this on a test vector?
        else:
            problems.append('address has already a dispenser about to close, no action can be taken until it closes')

    cursor.close()

    if oracle_address is not None and ledger.enabled('oracle_dispensers', block_index):
        last_price, last_fee, last_label, last_updated = ledger.get_oracle_last_price(db, oracle_address, block_index)
        
        if last_price is None:
            problems.append('The oracle address %s has not broadcasted any price yet' % oracle_address)
    
    if give_quantity > config.MAX_INT or escrow_quantity > config.MAX_INT or mainchainrate > config.MAX_INT:
        problems.append('integer overflow')

    if len(problems) > 0:
        return None, problems
    else:
        return asset_id, None

def compose (db, source, asset, give_quantity, escrow_quantity, mainchainrate, status, open_address=None, oracle_address=None):
    assetid, problems = validate(db, source, asset, give_quantity, escrow_quantity, mainchainrate, status, open_address, ledger.CURRENT_BLOCK_INDEX, oracle_address)
    if problems: raise exceptions.ComposeError(problems)

    destination = []
    data = message_type.pack(ID)
    data += struct.pack(FORMAT, assetid, give_quantity, escrow_quantity, mainchainrate, status)
    if (status == STATUS_OPEN_EMPTY_ADDRESS and open_address) or (ledger.enabled("dispenser_origin_permission_extended") and status == STATUS_CLOSED and open_address and open_address != source):
        data += address.pack(open_address)
    if oracle_address is not None and ledger.enabled('oracle_dispensers'):
        oracle_fee = calculate_oracle_fee(db, escrow_quantity, give_quantity, mainchainrate, oracle_address, ledger.CURRENT_BLOCK_INDEX)
        
        if oracle_fee >= config.DEFAULT_REGULAR_DUST_SIZE:
            destination.append((oracle_address,oracle_fee))
        data += address.pack(oracle_address)        
        
    return (source, destination, data)

def calculate_oracle_fee(db, escrow_quantity, give_quantity, mainchainrate, oracle_address, block_index):
    last_price, last_fee, last_fiat_label, last_updated = ledger.get_oracle_last_price(db, oracle_address, block_index)
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
        if dispenser_status == STATUS_OPEN_EMPTY_ADDRESS or (ledger.enabled("dispenser_origin_permission_extended") and dispenser_status == STATUS_CLOSED and len(message) > read):
            action_address = address.unpack(message[LENGTH:LENGTH+21])
            read = LENGTH + 21
        if len(message) > read:
            oracle_address = address.unpack(message[read:read+21])
        asset = ledger.generate_asset_name(assetid, ledger.CURRENT_BLOCK_INDEX)
        status = 'valid'
    except (exceptions.UnpackError, struct.error) as e:
        assetid, give_quantity, mainchainrate, asset = None, None, None, None
        status = 'invalid: could not unpack'

    
    if status == 'valid':
        if ledger.enabled("dispenser_parsing_validation", ledger.CURRENT_BLOCK_INDEX):
            asset_id, problems = validate(db, tx['source'], asset, give_quantity, escrow_quantity, mainchainrate, dispenser_status, action_address if dispenser_status in [STATUS_OPEN_EMPTY_ADDRESS, STATUS_CLOSED] else None, tx['block_index'], oracle_address)
        else:
            problems = None
        
        if problems:
            status = 'invalid: ' + '; '.join(problems)
        else:   
            if dispenser_status == STATUS_OPEN or dispenser_status == STATUS_OPEN_EMPTY_ADDRESS:
                existing = ledger.get_dispensers(db, source=action_address, asset=asset, status=STATUS_OPEN)

                if len(existing) == 0:
                    if (oracle_address != None) and ledger.enabled('oracle_dispensers', tx['block_index']):
                        oracle_fee = calculate_oracle_fee(db, escrow_quantity, give_quantity, mainchainrate, oracle_address, tx['block_index']) 
                           
                        if oracle_fee >= config.DEFAULT_REGULAR_DUST_SIZE:   
                            if tx["destination"] != oracle_address or tx["btc_amount"] < oracle_fee:
                                status = 'invalid: insufficient or non-existent oracle fee'
                        
                    
                    if status == 'valid':
                        # Create the new dispenser
                        try:
                            if dispenser_status == STATUS_OPEN_EMPTY_ADDRESS:
                                is_empty_address = True
                                address_assets = ledger.get_address_assets(db, action_address)
                                if len(address_assets) > 0:
                                    for asset_name in address_assets:
                                        asset_balance = ledger.get_balance(db, action_address, asset_name['asset'])
                                        if asset_balance > 0:
                                            is_empty_address = False
                                            break

                                if is_empty_address:
                                    ledger.debit(db, tx['source'], asset, escrow_quantity, tx['tx_index'], action='open dispenser empty addr', event=tx['tx_hash'])
                                    ledger.credit(db, action_address, asset, escrow_quantity, tx['tx_index'], action='open dispenser empty addr', event=tx['tx_hash'])
                                    ledger.debit(db, action_address, asset, escrow_quantity, tx['tx_index'], action='open dispenser empty addr', event=tx['tx_hash'])
                                else:
                                    status = 'invalid: address not empty'
                            else:
                                ledger.debit(db, tx['source'], asset, escrow_quantity, tx['tx_index'], action='open dispenser', event=tx['tx_hash'])
                        except ledger.DebitError as e:
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
                        
                        if ledger.enabled("dispenser_origin_permission_extended"):
                            bindings["origin"] = tx["source"]
                        
                        sql = '''insert into dispensers (tx_index, tx_hash, block_index, source, asset, give_quantity, escrow_quantity, satoshirate, status, give_remaining, oracle_address, origin, last_status_tx_hash)
                            values(:tx_index, :tx_hash, :block_index, :source, :asset, :give_quantity, :escrow_quantity, :satoshirate, :status, :give_remaining, :oracle_address, :origin, NULL)'''
                        cursor.execute(sql, bindings)
                elif len(existing) == 1 and existing[0]['satoshirate'] == mainchainrate and existing[0]['give_quantity'] == give_quantity:
                    if tx["source"]==action_address or (ledger.enabled("dispenser_origin_permission_extended", tx['block_index']) and tx["source"] == existing[0]["origin"]):
                        if (oracle_address != None) and ledger.enabled('oracle_dispensers', tx['block_index']):
                            oracle_fee = calculate_oracle_fee(db, escrow_quantity, give_quantity, mainchainrate, oracle_address, tx['block_index']) 
                               
                            if oracle_fee >= config.DEFAULT_REGULAR_DUST_SIZE:   
                                if tx["destination"] != oracle_address or tx["btc_amount"] < oracle_fee:
                                    status = 'invalid: insufficient or non-existent oracle fee'
                        
                        if status == 'valid':
                            # Refill the dispenser by the given amount
                            try:
                                ledger.debit(db, tx['source'], asset, escrow_quantity, tx['tx_index'], action='refill dispenser', event=tx['tx_hash'])
                                
                                set_data = {
                                    'give_remaining': existing[0]['give_remaining'] + escrow_quantity,
                                }
                                where_data = {
                                    'source': tx['source'] if not ledger.enabled("dispenser_origin_permission_extended", tx['block_index']) else action_address,
                                    'asset': asset,
                                    'status': STATUS_OPEN
                                }
                                ledger.update_dispensers(db, set_data, where_data)

                                dispenser_tx_hash = ledger.get_dispensers(db, source=action_address, asset=asset, status=STATUS_OPEN)[0]["tx_hash"]
                                bindings_refill = {
                                    'tx_index':tx["tx_index"],
                                    'tx_hash':tx["tx_hash"],
                                    'block_index':tx["block_index"],
                                    'source': tx['source'],
                                    'dispenser_quantity': escrow_quantity,
                                    'dispenser_tx_hash': dispenser_tx_hash
                                }
                                sql = '''INSERT INTO dispenser_refills 
                                         VALUES (
                                            :tx_index, 
                                            :tx_hash, 
                                            :block_index, 
                                            :source, 
                                            :destination, 
                                            :asset, 
                                            :dispenser_quantity, 
                                            :dispenser_tx_hash
                                         )'''
                                cursor.execute(sql, bindings_refill)
                            except (ledger.DebitError):
                                status = 'insufficient funds'
                    else:
                        status = 'invalid: can only refill dispenser from source or origin'                             
                else:
                    status = 'can only have one open dispenser per asset per address'
            elif dispenser_status == STATUS_CLOSED:
                close_delay = ledger.get_value_by_block_index("dispenser_close_delay", tx['block_index'])
                close_from_another_address = ledger.enabled("dispenser_origin_permission_extended", tx['block_index']) and action_address and action_address != tx["source"]

                existing = []
                if close_from_another_address:
                    existing = ledger.get_dispensers(db, 
                                                     source=action_address, 
                                                     asset=asset, 
                                                     status=STATUS_OPEN, 
                                                     origin=tx["source"])
                else:
                    existing = ledger.get_dispensers(db, 
                                                     source=tx['source'], 
                                                     asset=asset, 
                                                     status=STATUS_OPEN)

                if len(existing) == 1:
                    if close_delay == 0:
                        ledger.credit(db, tx['source'], asset, existing[0]['give_remaining'], tx['tx_index'], action='close dispenser', event=tx['tx_hash'])

                        set_data = {
                            'give_remaining': 0,
                            'status': STATUS_CLOSED,
                        }
                        where_data = {
                            'source': tx['source'],
                            'asset': asset
                        }
                    else:
                        set_data = {
                            'status': STATUS_CLOSING,
                            'last_status_tx_hash': tx['tx_hash']
                        }
                        where_data = {
                            'source': tx['source'],
                            'asset': asset,
                            'status_in': [0, 1]
                        }

                    if close_from_another_address:
                        where_data['origin'] = tx['source']
                        where_data['source'] = action_address

                    ledger.update_dispensers(db, set_data, where_data)
                else:
                    status = 'dispenser inexistent'
            else:
                status = 'invalid: status must be one of OPEN or CLOSE'

    if status != 'valid':
        # let use warnings.warn instead of logger.warning because we want to catch it in tests
        warnings.warn("Not storing [dispenser] tx [%s]: %s" % (tx['tx_hash'], status))

    cursor.close()

def is_dispensable(db, address, amount):
    dispensers = ledger.get_dispensers(db, source=address, status_in=[0, 11])

    for next_dispenser in dispensers:
        if next_dispenser["oracle_address"] != None:
            last_price, last_fee, last_fiat_label, last_updated = ledger.get_oracle_last_price(db, next_dispenser['oracle_address'], ledger.CURRENT_BLOCK_INDEX)
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
    if ledger.enabled("multiple_dispenses"):
        outs = ledger.get_vouts(db, tx['tx_hash'])
    else:
        outs = [tx]

    #if len(outs) == 0:
    #    outs = [tx]
    # or
    # assert len(outs) > 0 ?

    dispense_index = 0

    for next_out in outs:
        dispensers = ledger.get_dispensers(db, source=next_out['destination'], status_in=[0, 11])

        for dispenser in dispensers:
            satoshirate = dispenser['satoshirate']
            give_quantity = dispenser['give_quantity']

            if satoshirate > 0 and give_quantity > 0:
                if (dispenser['oracle_address'] != None) and ledger.enabled('oracle_dispensers', next_out['block_index']):
                    last_price, last_fee, last_fiat_label, last_updated = ledger.get_oracle_last_price(db, dispenser['oracle_address'], next_out['block_index'])
                    fiatrate = util.satoshirate_to_fiat(satoshirate)
                    must_give = int(floor(((next_out['btc_amount'] / config.UNIT) * last_price)/fiatrate))
                else:
                    must_give = int(floor(next_out['btc_amount'] / satoshirate))

                remaining = int(floor(dispenser['give_remaining'] / give_quantity))
                actually_given = min(must_give, remaining) * give_quantity
                give_remaining = dispenser['give_remaining'] - actually_given

                assert give_remaining >= 0

                # Skip dispense if quantity is 0
                if ledger.enabled('zero_quantity_value_adjustment_1') and actually_given==0:
                    continue

                ledger.credit(db, next_out['source'], dispenser['asset'], actually_given, tx['tx_index'], action='dispense', event=next_out['tx_hash'])

                # Checking if the dispenser reach its max dispenses limit
                max_dispenses_limit = ledger.get_value_by_block_index("max_dispenses_limit", next_out["block_index"])
                max_dispenser_limit_hit = False

                if max_dispenses_limit > 0:
                    max_block_index_result = ledger.get_last_refills_block_index(db, dispenser['tx_hash'])
                    from_block_index = 1
                    if len(max_block_index_result) > 0:
                        if max_block_index_result[0]["max_block_index"] is not None:
                            from_block_index = max_block_index_result[0]["max_block_index"]

                    dispenses_count = ledger.get_dispenses_count(db, dispenser['tx_hash'], from_block_index)
                    
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
                        ledger.credit(db, dispenser['source'], dispenser['asset'], give_remaining, tx['tx_index'], action=credit_action, event=next_out['tx_hash'])
                    else:
                        dispenser['closing_reason'] = "depleted"
                    dispenser['status'] = STATUS_CLOSED

                dispenser['block_index'] = next_out['block_index']
                dispenser['prev_status'] = STATUS_OPEN

                set_data = {
                    'give_remaining': dispenser['give_remaining'],
                    'status': dispenser['status'],
                }
                where_data = {
                    'source': dispenser['source'],
                    'asset': dispenser['asset'],
                    'satoshirate': dispenser['satoshirate'],
                    'give_quantity': dispenser['give_quantity'],
                    'status_in': [0, 11]
                }
                ledger.update_dispensers(db, set_data, where_data)

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
    block_delay = ledger.get_value_by_block_index("dispenser_close_delay", block_index)

    if block_delay > 0:
        pending_dispensers = ledger.get_pending_dispensers(db, status=STATUS_CLOSING, delay=block_delay, block_index=block_index)

        for dispenser in pending_dispensers:
            # use tx_index=0 for block actions
            ledger.credit(db, dispenser['tx_source'], dispenser['asset'], dispenser['give_remaining'], 0, action='close dispenser', event=dispenser['last_status_tx_hash'])

            set_data = {
                'give_remaining': 0,
                'status': STATUS_CLOSED,
            }
            where_data = {
                'asset': dispenser['asset'],
            }
            if dispenser['tx_source'] != dispenser['source']:
                where_data["source"] = dispenser['source']
                where_data["origin"] = dispenser['tx_source']
            else:
                where_data["source"] = dispenser['tx_source']
            ledger.update_dispensers(db, set_data, where_data)
