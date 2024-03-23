import logging
import fractions
import json
import os
from decimal import Decimal as D

from counterpartylib.lib import exceptions
from counterpartylib.lib import config
from counterpartylib.lib import util

logger = logging.getLogger(config.LOGGER_NAME)

CURRENT_BLOCK_INDEX = None
BLOCK_LEDGER = []

CURR_DIR = os.path.dirname(os.path.realpath(__file__))
with open(CURR_DIR + '/../protocol_changes.json') as f:
    PROTOCOL_CHANGES = json.load(f)


###########################
#         MESSAGES        #
###########################


def last_message(db):
    """Return latest message from the db."""
    cursor = db.cursor()
    query = '''
        SELECT * FROM messages
        WHERE message_index = (
            SELECT MAX(message_index) from messages
        )
    '''
    messages = list(cursor.execute(query))
    if messages:
        assert len(messages) == 1
        last_message = messages[0]
    else:
        raise exceptions.DatabaseError('No messages found.')
    cursor.close()
    return last_message


def get_messages(db, block_index=None, block_index_in=None, message_index_in=None):
    cursor = db.cursor()
    where = []
    bindings = []
    if block_index is not None:
        where.append('block_index = ?')
        bindings.append(block_index)
    if block_index_in is not None:
        where.append(f"block_index IN ({','.join(['?' for e in range(0, len(block_index_in))])})")
        bindings += block_index_in
    if message_index_in is not None:
        where.append(f"message_index IN ({','.join(['?' for e in range(0, len(message_index_in))])})")
        bindings += message_index_in
    # no sql injection here
    query = f'''SELECT * FROM messages WHERE ({" AND ".join(where)}) ORDER BY message_index ASC''' # nosec B608
    cursor.execute(query, tuple(bindings))
    return cursor.fetchall()


###########################
#         BALANCES        #
###########################


def remove_from_balance(db, address, asset, quantity, tx_index):
    balance_cursor = db.cursor()

    no_balance = False
    try:
        old_balance = get_balance(db, address, asset, raise_error_if_no_balance=True)
    except exceptions.BalanceError:
        old_balance = 0
        no_balance = True

    if old_balance < quantity:
        raise DebitError('Insufficient funds.')

    balance = round(old_balance - quantity)
    balance = min(balance, config.MAX_INT)
    assert balance >= 0

    if not no_balance: # don't create balance if quantity is 0 and there is no balance
        bindings = {
            'quantity': balance,
            'address': address,
            'asset': asset,
            'block_index': CURRENT_BLOCK_INDEX,
            'tx_index': tx_index,
        }
        query = '''
            INSERT INTO balances
            VALUES (:address, :asset, :quantity, :block_index, :tx_index)
        '''
        balance_cursor.execute(query, bindings)


class DebitError (Exception): pass
def debit (db, address, asset, quantity, tx_index, action=None, event=None):
    """Debit given address by quantity of asset."""
    block_index = CURRENT_BLOCK_INDEX

    if type(quantity) != int:
        raise DebitError('Quantity must be an integer.')
    if quantity < 0:
        raise DebitError('Negative quantity.')
    if quantity > config.MAX_INT:
        raise DebitError('Quantity can\'t be higher than MAX_INT.')
    if asset == config.BTC:
        raise DebitError('Cannot debit bitcoins.')

    debit_cursor = db.cursor()

    # Contracts can only hold XCP balances.
    if enabled('contracts_only_xcp_balances'): # Protocol change.
        if len(address) == 40:
            assert asset == config.XCP

    if asset == config.BTC:
        raise exceptions.BalanceError(f'Cannot debit bitcoins from a {config.XCP_NAME} address!')

    remove_from_balance(db, address, asset, quantity, tx_index)

    # Record debit.
    bindings = {
        'block_index': block_index,
        'address': address,
        'asset': asset,
        'quantity': quantity,
        'action': action,
        'event': event,
        'tx_index': tx_index,
    }
    query = '''
        INSERT INTO debits
        VALUES (:block_index, :address, :asset, :quantity, :action, :event, :tx_index)
    '''
    debit_cursor.execute(query, bindings)
    debit_cursor.close()

    BLOCK_LEDGER.append(f'{block_index}{address}{asset}{quantity}')


def add_to_balance(db, address, asset, quantity, tx_index):
    balance_cursor = db.cursor()

    old_balance = get_balance(db, address, asset)
    balance = round(old_balance + quantity)
    balance = min(balance, config.MAX_INT)

    bindings = {
        'quantity': balance,
        'address': address,
        'asset': asset,
        'block_index': CURRENT_BLOCK_INDEX,
        'tx_index': tx_index,
    }
    query = '''
        INSERT INTO balances
        VALUES (:address, :asset, :quantity, :block_index, :tx_index)
    '''
    balance_cursor.execute(query, bindings)


class CreditError (Exception): pass
def credit (db, address, asset, quantity, tx_index, action=None, event=None):
    """Credit given address by quantity of asset."""
    block_index = CURRENT_BLOCK_INDEX

    if type(quantity) != int:
        raise CreditError('Quantity must be an integer.')
    if quantity < 0:
        raise CreditError('Negative quantity.')
    if quantity > config.MAX_INT:
        raise CreditError('Quantity can\'t be higher than MAX_INT.')
    if asset == config.BTC:
        raise CreditError('Cannot debit bitcoins.')

    credit_cursor = db.cursor()

    # Contracts can only hold XCP balances.
    if enabled('contracts_only_xcp_balances'): # Protocol change.
        if len(address) == 40:
            assert asset == config.XCP

    add_to_balance(db, address, asset, quantity, tx_index)

    # Record credit.
    bindings = {
        'block_index': block_index,
        'address': address,
        'asset': asset,
        'quantity': quantity,
        'action': action,
        'event': event,
        'tx_index': tx_index,
    }
    query = '''
        INSERT INTO credits
        VALUES (:block_index, :address, :asset, :quantity, :action, :event, :tx_index)
    '''
    credit_cursor.execute(query, bindings)
    credit_cursor.close()

    BLOCK_LEDGER.append(f'{block_index}{address}{asset}{quantity}')


def transfer(db, source, destination, asset, quantity, action, event):
    """Transfer quantity of asset from source to destination."""
    debit(db, source, asset, quantity, action=action, event=event)
    credit(db, destination, asset, quantity, action=action, event=event)


def get_balance(db, address, asset, raise_error_if_no_balance=False, return_list=False):
    """Get balance of contract or address."""
    cursor = db.cursor()
    query = '''
        SELECT * FROM balances
        WHERE (address = ? AND asset = ?)
        ORDER BY rowid DESC LIMIT 1
    '''
    bindings = (address, asset)
    balances = list(cursor.execute(query, bindings))
    cursor.close()
    if return_list:
        return balances
    if not balances and raise_error_if_no_balance:
        raise exceptions.BalanceError(f'No balance for this address and asset: {address}, {asset}.')
    if not balances:
        return 0
    return balances[0]['quantity']


def get_address_balances(db, address):
    cursor = db.cursor()
    query = '''
        SELECT address, asset, quantity, MAX(rowid)
        FROM balances
        WHERE address = ?
        GROUP BY address, asset
    '''
    bindings = (address,)
    cursor.execute(query, bindings)
    return cursor.fetchall()


def get_address_assets(db, address):
    cursor = db.cursor()
    query = '''
        SELECT DISTINCT asset
        FROM balances
        WHERE address=:address
        GROUP BY asset
    '''
    bindings = {'address': address}
    cursor.execute(query, bindings)
    return cursor.fetchall()


def get_balances_count(db, address):
    cursor = db.cursor()
    query = '''
        SELECT COUNT(*) AS cnt FROM (
            SELECT DISTINCT asset
            FROM balances
            WHERE address=:address
            GROUP BY asset
        )
    '''
    bindings = {'address': address}
    cursor.execute(query, bindings)
    return cursor.fetchall()


#####################
#     ISSUANCES     #
#####################


def generate_asset_id(asset_name, block_index):
    """Create asset_id from asset_name."""
    if asset_name == config.BTC: return 0
    elif asset_name == config.XCP: return 1

    if len(asset_name) < 4:
        raise exceptions.AssetNameError('too short')

    # Numeric asset names.
    if enabled('numeric_asset_names'):  # Protocol change.
        if asset_name[0] == 'A':
            # Must be numeric.
            try:
                asset_id = int(asset_name[1:])
            except ValueError:
                raise exceptions.AssetNameError('non‐numeric asset name starts with ‘A’')

            # Number must be in range.
            if not (26**12 + 1 <= asset_id <= 2**64 - 1):
                raise exceptions.AssetNameError('numeric asset name not in range')

            return asset_id
        elif len(asset_name) >= 13:
            raise exceptions.AssetNameError('long asset names must be numeric')

    if asset_name[0] == 'A': raise exceptions.AssetNameError('non‐numeric asset name starts with ‘A’')

    # Convert the Base 26 string to an integer.
    n = 0
    for c in asset_name:
        n *= 26
        if c not in util.B26_DIGITS:
            raise exceptions.AssetNameError('invalid character:', c)
        digit = util.B26_DIGITS.index(c)
        n += digit
    asset_id = n

    if asset_id < 26**3:
        raise exceptions.AssetNameError('too short')

    return asset_id


def generate_asset_name (asset_id, block_index):
    """Create asset_name from asset_id."""
    if asset_id == 0: return config.BTC
    elif asset_id == 1: return config.XCP

    if asset_id < 26**3:
        raise exceptions.AssetIDError('too low')

    if enabled('numeric_asset_names'):  # Protocol change.
        if asset_id <= 2**64 - 1:
            if 26**12 + 1 <= asset_id:
                asset_name = 'A' + str(asset_id)
                return asset_name
        else:
            raise exceptions.AssetIDError('too high')

    # Divide that integer into Base 26 string.
    res = []
    n = asset_id
    while n > 0:
        n, r = divmod (n, 26)
        res.append(util.B26_DIGITS[r])
    asset_name = ''.join(res[::-1])

    """
    return asset_name + checksum.compute(asset_name)
    """
    return asset_name


def get_asset_id (db, asset_name, block_index):
    """Return asset_id from asset_name."""
    if not enabled('hotfix_numeric_assets'):
        return generate_asset_id(asset_name, block_index)
    cursor = db.cursor()
    query = '''
        SELECT * FROM assets
        WHERE asset_name = ?
    '''
    bindings = (asset_name,)
    cursor.execute(query, bindings)
    assets = list(cursor)
    if len(assets) == 1:
        return int(assets[0]['asset_id'])
    else:
        raise exceptions.AssetError(f'No such asset: {asset_name}')


def get_asset_name (db, asset_id, block_index):
    """Return asset_name from asset_id."""
    if not enabled('hotfix_numeric_assets'):
        return generate_asset_name(asset_id, block_index)
    cursor = db.cursor()
    query = '''
        SELECT * FROM assets
        WHERE asset_id = ?
    '''
    bindings = (str(asset_id),)
    cursor.execute(query, bindings)
    assets = list(cursor)
    if len(assets) == 1:
        return assets[0]['asset_name']
    elif not assets:
        return 0    # Strange, I know…


# If asset_name is an existing subasset (PARENT.child) then return the corresponding numeric asset name (A12345)
#   If asset_name is not an existing subasset, then return the unmodified asset_name
def resolve_subasset_longname(db, asset_name):
    if enabled('subassets'):
        subasset_longname = None
        try:
            subasset_parent, subasset_longname = util.parse_subasset_from_asset_name(asset_name)
        except Exception as e:
            logger.warning(f"Invalid subasset {asset_name}")
            subasset_longname = None

        if subasset_longname is not None:
            cursor = db.cursor()
            query = '''
                SELECT asset_name FROM assets
                WHERE asset_longname = ?
            '''
            bindings = (subasset_longname,)
            cursor.execute(query, bindings)
            assets = list(cursor)
            cursor.close()
            if len(assets) == 1:
                return assets[0]['asset_name']

    return asset_name


def is_divisible(db, asset):
    """Check if the asset is divisible."""
    if asset in (config.BTC, config.XCP):
        return True
    else:
        cursor = db.cursor()
        query = '''
            SELECT * FROM issuances
            WHERE (status = ? AND asset = ?)
            ORDER BY tx_index DESC
        '''
        bindings = ('valid', asset)
        cursor.execute(query, bindings)
        issuances = cursor.fetchall()
        if not issuances: raise exceptions.AssetError(f'No such asset: {asset}')
        return issuances[0]['divisible']


def value_out(db, quantity, asset, divisible=None):
    if asset not in ['leverage', 'value', 'fraction', 'price', 'odds'] and divisible == None:
        divisible = is_divisible(db, asset)
    return util.value_output(quantity, asset, divisible)


def value_in(db, quantity, asset, divisible=None):
    if asset not in ['leverage', 'value', 'fraction', 'price', 'odds'] and divisible == None:
        divisible = is_divisible(db, asset)
    return util.value_input(quantity, asset, divisible)


def price (numerator, denominator):
    """Return price as Fraction or Decimal."""
    if CURRENT_BLOCK_INDEX >= 294500 or config.TESTNET or config.REGTEST: # Protocol change.
        return fractions.Fraction(numerator, denominator)
    else:
        numerator = D(numerator)
        denominator = D(denominator)
        return D(numerator / denominator)


def get_asset_issuer(db, asset):
    """Check if the asset is divisible."""
    if asset in (config.BTC, config.XCP):
        return True
    else:
        cursor = db.cursor()
        query = '''
            SELECT * FROM issuances
            WHERE (status = ? AND asset = ?)
            ORDER BY tx_index DESC
        '''
        bindings = ('valid', asset)
        cursor.execute(query, bindings)
        issuances = cursor.fetchall()
        if not issuances: raise exceptions.AssetError(f'No such asset: {asset}')
        return issuances[0]['issuer']


def get_asset_description(db, asset):
    if asset in (config.BTC, config.XCP):
        return ''
    else:
        cursor = db.cursor()
        query = '''
            SELECT * FROM issuances
            WHERE (status = ? AND asset = ?)
            ORDER BY tx_index DESC
        '''
        bindings = ('valid', asset)
        cursor.execute(query, bindings)
        issuances = cursor.fetchall()
        if not issuances: raise exceptions.AssetError(f'No such asset: {asset}')
        return issuances[0]['description']


def get_issuances_count(db, address):
    cursor = db.cursor()
    query = '''
        SELECT COUNT(DISTINCT(asset)) cnt
        FROM issuances
        WHERE issuer = ?
    '''
    bindings = (address,)
    cursor.execute(query, bindings)
    return cursor.fetchall()[0]['cnt']


def get_asset_issued(db, address):
    cursor = db.cursor()
    query = '''
        SELECT DISTINCT(asset)
        FROM issuances
        WHERE issuer = ?
    '''
    bindings = (address,)
    cursor.execute(query, bindings)
    return cursor.fetchall()


def get_asset_balances(db, asset, exclude_zero_balances=True):
    cursor = db.cursor()
    query = '''
        SELECT address, asset, quantity, MAX(rowid)
        FROM balances
        WHERE asset = ?
        GROUP BY address, asset
        ORDER BY address
    '''
    if exclude_zero_balances:
        query = f'''
            SELECT * FROM (
                {query}
            ) WHERE quantity > 0
        ''' # nosec B608
    bindings = (asset,)
    cursor.execute(query, bindings)
    return cursor.fetchall()


def get_asset_issuances_quantity(db, asset):
    cursor = db.cursor()
    query = '''
        SELECT COUNT(*) AS issuances_count
        FROM issuances
        WHERE (status = ? AND asset = ?)
        ORDER BY tx_index DESC
    '''
    bindings = ('valid', asset)
    cursor.execute(query, bindings)
    issuances = cursor.fetchall()
    return issuances[0]['issuances_count']


def get_asset_info(db, asset):
    if asset == config.BTC or asset == config.XCP:
        return {'divisible':True}
    cursor = db.cursor()
    query = '''
        SELECT * FROM issuances
        WHERE (status = ? AND asset = ?)
        ORDER BY tx_index DESC
    '''
    bindings = ('valid', asset)
    cursor.execute(query, bindings)
    issuances = cursor.fetchall()
    return issuances[0]


def get_issuances(db, asset=None, status=None, locked=None, first=False, last=False):
    cursor = db.cursor()
    cursor = db.cursor()
    where = []
    bindings = []
    if status is not None:
        where.append('status = ?')
        bindings.append(status)
    if asset is not None:
        where.append('asset = ?')
        bindings.append(asset)
    if locked is not None:
        where.append('locked = ?')
        bindings.append(locked)
    # no sql injection here
    query = f'''SELECT * FROM issuances WHERE ({" AND ".join(where)})''' # nosec B608
    if first:
        query += f''' ORDER BY tx_index ASC'''
    elif last:
        query += f''' ORDER BY tx_index DESC'''
    cursor.execute(query, tuple(bindings))
    return cursor.fetchall()


def get_assets_by_longname(db, asset_longname):
    cursor = db.cursor()
    query = '''
        SELECT * FROM assets
        WHERE (asset_longname = ?)
    '''
    bindings = (asset_longname,)
    cursor.execute(query, bindings)
    return cursor.fetchall()


def get_valid_assets(db):
    cursor = db.cursor()
    query = '''
        SELECT asset, asset_longname
        FROM issuances
        WHERE status = 'valid'
        GROUP BY asset
        ORDER BY asset ASC
    '''
    cursor.execute(query)
    return cursor.fetchall()


#####################
#    BROADCASTS     #
#####################


def get_oracle_last_price(db, oracle_address, block_index):
    cursor = db.cursor()
    query = '''
        SELECT * FROM broadcasts
        WHERE source = :source AND status = :status AND block_index < :block_index
        ORDER by tx_index DESC LIMIT 1
    '''
    bindings = {
        'source': oracle_address,
        'status': 'valid',
        'block_index': block_index
    }
    cursor.execute(query, bindings)
    broadcasts = cursor.fetchall()
    cursor.close()

    if len(broadcasts) == 0:
        return None, None, None, None

    oracle_broadcast = broadcasts[0]
    oracle_label = oracle_broadcast["text"].split("-")
    if len(oracle_label) == 2:
        fiat_label = oracle_label[1]
    else:
        fiat_label = ""

    return oracle_broadcast['value'], oracle_broadcast['fee_fraction_int'], fiat_label, oracle_broadcast['block_index']


def get_broadcasts_by_source(db, source, status):
    cursor = db.cursor()
    query = '''
        SELECT * FROM broadcasts
        WHERE (status = ? AND source = ?)
        ORDER BY tx_index ASC
    '''
    bindings = (status, source)
    cursor.execute(query, bindings)
    return cursor.fetchall()


#####################
#       BURNS       #
#####################


def get_burns(db, status=None, source=None):
    cursor = db.cursor()
    where = []
    bindings = []
    if status is not None:
        where.append('status = ?')
        bindings.append(status)
    if source is not None:
        where.append('source = ?')
        bindings.append(source)
    # no sql injection here
    query = f'''SELECT * FROM burns WHERE ({" AND ".join(where)})''' # nosec B608
    cursor.execute(query, tuple(bindings))
    return cursor.fetchall()


###########################
#       TRANSACTIONS      #
###########################


def get_vouts(db, tx_hash):
    cursor = db.cursor()
    query = '''
        SELECT txs.source AS source, txs_outs.*
        FROM transaction_outputs txs_outs
        LEFT JOIN transactions txs ON txs.tx_hash = txs_outs.tx_hash
        WHERE txs_outs.tx_hash=:tx_hash
        ORDER BY txs_outs.out_index
    '''
    bindings = {'tx_hash': tx_hash}
    cursor.execute(query, bindings)
    return cursor.fetchall()


def get_transactions(db, tx_hash=None):
    cursor = db.cursor()
    where = []
    bindings = []
    if tx_hash is not None:
        where.append('tx_hash = ?')
        bindings.append(tx_hash)
    # no sql injection here
    query = f'''SELECT * FROM transactions WHERE ({" AND ".join(where)})''' # nosec B608
    cursor.execute(query, tuple(bindings))
    return cursor.fetchall()


def get_transaction_source(db, tx_hash):
    cursor = db.cursor()
    query = '''SELECT source FROM transactions WHERE tx_hash = ?'''
    bindings = (tx_hash,)
    cursor.execute(query, tuple(bindings))
    return cursor.fetchone()['source']


def get_addresses(db, address=None):
    cursor = db.cursor()
    where = []
    bindings = []
    if address is not None:
        where.append('address = ?')
        bindings.append(address)
    # no sql injection here
    query = f'''SELECT * FROM addresses WHERE ({" AND ".join(where)})''' # nosec B608
    cursor.execute(query, tuple(bindings))
    return cursor.fetchall()


###############################
#       UTIL FUNCTIONS        #
###############################


def insert_record(db, table_name, record):
    cursor = db.cursor()
    fields_name = ', '.join(record.keys())
    fields_values = ', '.join([f':{key}' for key in record.keys()])
    # no sql injection here
    query = f'''INSERT INTO {table_name} ({fields_name}) VALUES ({fields_values})''' # nosec B608
    cursor.execute(query, record)
    cursor.close()


# This function allows you to update a record using an INSERT.
# The `block_index` and `rowid` fields allow you to
# order updates and retrieve the row with the current data.
def insert_update(db, table_name, id_name, id_value, update_data):
    cursor = db.cursor()
    # select records to update
    select_query = f'''
        SELECT *, rowid
        FROM {table_name}
        WHERE {id_name} = ?
        ORDER BY rowid DESC
        LIMIT 1
    ''' # nosec B608
    bindings = (id_value,)
    need_update_record = cursor.execute(select_query, bindings).fetchone()

    # update record
    new_record = need_update_record.copy()
    # updade needed fields
    for key, value in update_data.items():
        new_record[key] = value
    # new block_index and tx_index
    new_record['block_index'] = CURRENT_BLOCK_INDEX
    # let's keep the original tx_index so we can preserve order
    # with the old queries (ordered by default by old primary key)
    # TODO: restore with protocol change and checkpoints update
    #if 'tx_index' in new_record:
    #    new_record['tx_index'] = tx_index
    # insert new record
    if 'rowid' in new_record:
        del new_record['rowid']
    fields_name = ', '.join(new_record.keys())
    fields_values = ', '.join([f':{key}' for key in new_record.keys()])
    # no sql injection here
    insert_query = f'''INSERT INTO {table_name} ({fields_name}) VALUES ({fields_values})''' # nosec B608
    cursor.execute(insert_query, new_record)

    cursor.close()


MUTABLE_FIELDS = {
    'balances': ['quantity'],
    'orders': ['give_remaining', 'get_remaining', 'fee_required_remaining', 'fee_provided_remaining', 'status'],
    'order_matches': ['status'],
    'bets': ['wager_remaining', 'counterwager_remaining', 'status'],
    'bet_matches': ['status'],
    'rps': ['status'],
    'rps_matches': ['status'],
    'dispensers': ['give_remaining', 'status', 'last_status_tx_hash'],
}
ID_FIELDS = {
    'balances': ['address', 'asset'],
    'orders': ['tx_hash'],
    'order_matches': ['id'],
    'bets': ['tx_hash'],
    'bet_matches': ['id'],
    'rps': ['tx_hash'],
    'rps_matches': ['id'],
    'dispensers': ['tx_hash'],
}

def _gen_where_and_binding(key, value):
    where = ''
    bindings = []
    _key = key.replace('_in', '')
    if key.endswith('_in'):
        assert isinstance(value, list)
        where = f'{_key} IN ({",".join(["?" for e in range(0, len(value))])})'
        bindings += value
    else:
        where = f'{_key} = ?'
        bindings.append(value)
    return where, bindings


def select_last_revision(db, table_name, where_data):
    cursor = db.cursor()
    if table_name not in MUTABLE_FIELDS.keys():
        raise exceptions.UnknownTable(f'Unknown table: {table_name}')
    query = '''
        PRAGMA table_info(?)
    '''
    bindings = (table_name,)
    columns = [column['name'] for column in cursor.execute(query, bindings)]
    for key in where_data.keys():
        _key = key.replace('_in', '')
        if _key not in columns:
            raise exceptions.UnknownField(f'Unknown field: {key}')

    where_immutable = []
    where_mutable = []
    bindings = []
    for key, value in where_data.items():
        if key.replace('_in', '') not in MUTABLE_FIELDS[table_name]:
            _where, _bindings = _gen_where_and_binding(key, value)
            where_immutable.append(_where)
            bindings += _bindings
    for key, value in where_data.items():
        if key.replace('_in', '') in MUTABLE_FIELDS[table_name]:
            _where, _bindings = _gen_where_and_binding(key, value)
            where_mutable.append(_where)
            bindings += _bindings
    # no sql injection here
    query = f'''SELECT * FROM (
        SELECT *, MAX(rowid)
        FROM {table_name}
        WHERE ({" AND ".join(where_immutable)})
        GROUP BY {", ".join(ID_FIELDS[table_name])}
    ) WHERE ({" AND ".join(where_mutable)})
    ''' # nosec B608
    cursor.execute(query, tuple(bindings))
    return cursor.fetchall()


#####################
#     DISPENSERS    #
#####################

### SELECTS ###

def get_dispenser_info(db, tx_hash=None, tx_index=None):
    cursor = db.cursor()
    where = []
    bindings = []
    if tx_hash is not None:
        where.append('tx_hash = ?')
        bindings.append(tx_hash)
    if tx_index is not None:
        where.append('tx_index = ?')
        bindings.append(tx_index)
    # no sql injection here
    query = f'''
        SELECT d.*, a.asset_longname
        FROM dispensers d
        LEFT JOIN assets a ON a.asset_name = d.asset
        WHERE ({" AND ".join(where)})
        ORDER BY d.rowid DESC LIMIT 1
    ''' # nosec B608
    cursor.execute(query, tuple(bindings))
    return cursor.fetchall()


def get_refilling_count(db, dispenser_tx_hash):
    cursor = db.cursor()
    query = '''
        SELECT count(*) cnt
        FROM dispenser_refills
        WHERE dispenser_tx_hash = ?
    '''
    bindings = (dispenser_tx_hash,)
    cursor.execute(query, bindings)
    return cursor.fetchall()[0]['cnt']


def get_pending_dispensers_old(db, status, delay, block_index):
    cursor = db.cursor()
    query = '''
        SELECT * FROM
            (SELECT d.*, t.source AS tx_source, t.block_index AS tx_block_index, MAX(d.rowid) AS rowid
            FROM dispensers AS d
            LEFT JOIN transactions t ON t.tx_hash = d.last_status_tx_hash
            WHERE :block_index = t.block_index + :delay
            GROUP BY d.source, d.asset)
        WHERE status = :status
        AND last_status_tx_hash IS NOT NULL
        ORDER BY tx_index
    '''
    bindings = {
        'status': status,
        'delay': delay,
        'block_index': block_index
    }
    cursor.execute(query, bindings)
    return cursor.fetchall()


def get_pending_dispensers(db, delay, block_index):
    status_closed = 10
    status_closing = 11

    cursor = db.cursor()
    # we assume here that the status_closed and status_closing are the last statuses
    # and that dispenser with status_closing can be closed before the delay if it's empty
    query = '''
        SELECT d.*, t.source AS tx_source, t.block_index AS tx_block_index, MAX(d.rowid) AS rowid
        FROM dispensers AS d
        LEFT JOIN transactions t ON t.tx_hash = d.last_status_tx_hash
        WHERE :block_index = t.block_index + :delay
        AND status IN (:status_closed, :status_closing)
        GROUP BY d.source, d.asset
        ORDER BY tx_index
    '''
    bindings = {
        'status_closed': status_closed,
        'status_closing': status_closing,
        'delay': delay,
        'block_index': block_index
    }
    cursor.execute(query, bindings)
    return [dispenser for dispenser in cursor.fetchall() if dispenser['status'] == status_closing]


def get_dispensers_count(db, source, status, origin):
    cursor = db.cursor()
    query = '''
        SELECT count(*) cnt FROM (
            SELECT *, MAX(rowid)
            FROM dispensers
            WHERE source = ? AND origin = ?
            GROUP BY tx_hash
        ) WHERE status = ?
        ORDER BY tx_index
    '''
    bindings = (source, origin, status)
    cursor.execute(query, bindings)
    return cursor.fetchall()[0]['cnt']


def get_dispenses_count(db, dispenser_tx_hash, from_block_index):
    cursor = db.cursor()
    query = '''
        SELECT COUNT(*) AS dispenses_count
        FROM dispenses
        WHERE dispenser_tx_hash = :dispenser_tx_hash
        AND block_index >= :block_index
    '''
    bindings = {
        'dispenser_tx_hash': dispenser_tx_hash,
        'block_index': from_block_index
    }
    cursor.execute(query, bindings)
    dispenses_count_result = cursor.fetchall()[0]
    return dispenses_count_result["dispenses_count"]


def get_last_refills_block_index(db, dispenser_tx_hash):
    cursor = db.cursor()
    query = '''
        SELECT MAX(block_index) AS max_block_index
        FROM dispenser_refills
        WHERE dispenser_tx_hash = :dispenser_tx_hash
    '''
    bindings = {
        'dispenser_tx_hash': dispenser_tx_hash
    }
    cursor.execute(query, bindings)
    return cursor.fetchall()


def get_dispenser(db, tx_hash):
    cursor = db.cursor()
    query = '''
        SELECT * FROM dispensers
        WHERE tx_hash = ?
        ORDER BY rowid DESC LIMIT 1
    '''
    bindings = (tx_hash,)
    cursor.execute(query, bindings)
    return cursor.fetchall()


def get_dispensers(db, status_in=None, source_in=None, source=None, asset=None, origin=None, status=None, tx_hash=None, order_by=None, group_by=None):
    cursor = db.cursor()
    bindings = []
    # where for immutable fields
    first_where = []
    if source is not None:
        first_where.append('source = ?')
        bindings.append(source)
    if source_in is not None:
        first_where.append(f"source IN ({','.join(['?' for e in range(0, len(source_in))])})")
        bindings += source_in
    if asset is not None:
        first_where.append('asset = ?')
        bindings.append(asset)
    if origin is not None:
        first_where.append('origin = ?')
        bindings.append(origin)
    # where for mutable fields
    second_where = []
    if status is not None:
        second_where.append('status = ?')
        bindings.append(status)
    if status_in is not None:
        second_where.append(f"status IN ({','.join(['?' for e in range(0, len(status_in))])})")
        bindings += status_in
    # build query
    first_where_str = ' AND '.join(first_where)
    if first_where_str != '':
        first_where_str = f'WHERE ({first_where_str})'
    second_where_str = ' AND '.join(second_where)
    if second_where_str != '':
        second_where_str = f'WHERE ({second_where_str})'
    order_clause = f'ORDER BY {order_by}' if order_by is not None else 'ORDER BY tx_index'
    group_clause = f'GROUP BY {group_by}' if group_by is not None else 'GROUP BY asset, source'
    # no sql injection here
    query = f'''
        SELECT *, rowid FROM (
            SELECT *, MAX(rowid) as rowid
            FROM dispensers
            {first_where_str}
            {group_clause}
        ) {second_where_str}
        {order_clause}
    ''' # nosec B608
    cursor.execute(query, tuple(bindings))
    return cursor.fetchall()


### UPDATES ###

def update_dispenser(db, rowid, update_data):
    insert_update(db, 'dispensers', 'rowid', rowid, update_data)


#####################
#       BETS        #
#####################

### SELECTS ###

def get_pending_bet_matches(db, feed_address, order_by=None):
    cursor = db.cursor()
    query = '''
        SELECT * FROM (
            SELECT *, MAX(rowid) as rowid
            FROM bet_matches
            WHERE feed_address = ?
            GROUP BY id
        ) WHERE status = ?
    '''
    if order_by is not None:
        query += f''' ORDER BY {order_by}'''
    else:
        query += f''' ORDER BY rowid'''
    bindings = (feed_address, 'pending')
    cursor.execute(query, bindings)
    return cursor.fetchall()


def get_bet_matches_to_expire(db, block_time):
    cursor = db.cursor()
    query = '''
        SELECT * FROM (
            SELECT *, MAX(rowid) as rowid
            FROM bet_matches
            WHERE deadline < ? AND deadline > ?
            GROUP BY id
        ) WHERE status = ?
        ORDER BY rowid
    '''
    bindings = (
        block_time - config.TWO_WEEKS,
        block_time - 2 * config.TWO_WEEKS, # optimize query: assuming before that we have already expired
        'pending'
    )
    cursor.execute(query, bindings)
    return cursor.fetchall()


def get_bet(db, tx_hash):
    cursor = db.cursor()
    query = '''
        SELECT * FROM bets
        WHERE tx_hash = ?
        ORDER BY rowid DESC LIMIT 1
    '''
    bindings = (tx_hash,)
    cursor.execute(query, bindings)
    return cursor.fetchall()


def get_bets_to_expire(db, block_index):
    cursor = db.cursor()
    query = '''
        SELECT * FROM (
            SELECT *, MAX(rowid)
            FROM bets
            WHERE expire_index = ? - 1
            GROUP BY tx_hash
        ) WHERE status = ?
        ORDER BY tx_index, tx_hash
    '''
    bindings = (block_index, 'open')
    cursor.execute(query, bindings)
    return cursor.fetchall()


def get_matching_bets(db, feed_address, bet_type):
    cursor = db.cursor()
    query = '''
        SELECT * FROM (
            SELECT *, MAX(rowid)
            FROM bets
            WHERE (feed_address = ? AND bet_type = ?)
            GROUP BY tx_hash
        ) WHERE status = ?
        ORDER BY tx_index, tx_hash
    '''
    bindings = (feed_address, bet_type, 'open')
    cursor.execute(query, bindings)
    return cursor.fetchall()


def get_open_bet_by_feed(db, feed_address):
    cursor = db.cursor()
    query = '''
        SELECT * FROM (
            SELECT *, MAX(rowid)
            FROM bets
            WHERE feed_address = ?
            GROUP BY tx_hash
        ) WHERE status = ?
        ORDER BY tx_index, tx_hash
    '''
    bindings = (feed_address, 'open')
    cursor.execute(query, bindings)
    return cursor.fetchall()


### UPDATES ###

def update_bet(db, tx_hash, update_data):
    insert_update(db, 'bets', 'tx_hash', tx_hash, update_data)


def update_bet_match_status(db, id, status):
    update_data = {
        'status': status
    }
    insert_update(db, 'bet_matches', 'id', id, update_data)


#####################
#       ORDERS      #
#####################

### SELECTS ###

def get_pending_order_matches(db, tx0_hash, tx1_hash):
    cursor = db.cursor()
    query = '''
        SELECT * FROM (
            SELECT *, MAX(rowid) as rowid FROM order_matches
            WHERE (
                tx0_hash in (:tx0_hash, :tx1_hash) OR
                tx1_hash in (:tx0_hash, :tx1_hash)
            )
            GROUP BY id
        ) WHERE status = :status
        ORDER BY rowid
    '''
    bindings = {
        'status': 'pending',
        'tx0_hash': tx0_hash,
        'tx1_hash': tx1_hash
    }
    cursor.execute(query, bindings)
    return cursor.fetchall()


def get_pending_btc_order_matches(db, address):
    cursor = db.cursor()
    query = '''
        SELECT * FROM (
            SELECT *, MAX(rowid) AS rowid
            FROM order_matches
            WHERE (tx0_address = ? AND forward_asset = ?) OR (tx1_address = ? AND backward_asset = ?)
        ) WHERE status = ?
        ORDER BY rowid
    '''
    bindings = (address, config.BTC, address, config.BTC, 'pending')
    cursor.execute(query, bindings)
    return cursor.fetchall()


def get_order_match(db, id):
    cursor = db.cursor()
    query = '''
        SELECT *, rowid
        FROM order_matches
        WHERE id = ?
        ORDER BY rowid DESC LIMIT 1'''
    bindings = (id,)
    cursor.execute(query, bindings)
    return cursor.fetchall()


def get_order_matches_to_expire(db, block_index):
    cursor = db.cursor()
    query = '''SELECT * FROM (
        SELECT *, MAX(rowid) AS rowid
        FROM order_matches
        WHERE match_expire_index = ? - 1
        GROUP BY id
    ) WHERE status = ?
    ORDER BY rowid
    '''
    bindings = (block_index, 'pending')
    cursor.execute(query, bindings)
    return cursor.fetchall()


def get_order(db, tx_hash):
    cursor = db.cursor()
    query = '''
        SELECT * FROM orders
        WHERE tx_hash = ?
        ORDER BY rowid DESC LIMIT 1
    '''
    bindings = (tx_hash,)
    cursor.execute(query, bindings)
    return cursor.fetchall()


def get_order_first_block_index(cursor, tx_hash):
    query = '''
        SELECT block_index FROM orders
        WHERE tx_hash = ?
        ORDER BY rowid ASC LIMIT 1
    '''
    bindings = (tx_hash,)
    cursor.execute(query, bindings)
    return cursor.fetchone()['block_index']


def get_orders_to_expire(db, block_index):
    cursor = db.cursor()
    query = '''
        SELECT * FROM (
            SELECT *, MAX(rowid)
            FROM orders
            WHERE expire_index = ? - 1
            GROUP BY tx_hash
        ) WHERE status = ?
        ORDER BY tx_index, tx_hash
    '''
    bindings = (block_index, 'open')
    cursor.execute(query, bindings)
    return cursor.fetchall()


def get_open_btc_orders(db, address):
    cursor = db.cursor()
    query = '''
        SELECT * FROM (
            SELECT *, MAX(rowid)
            FROM orders
            WHERE (source = ? AND give_asset = ?)
            GROUP BY tx_hash
        ) WHERE status = ?
        ORDER BY tx_index, tx_hash
    '''
    bindings = (address, config.BTC, 'open')
    cursor.execute(query, bindings)
    return cursor.fetchall()


def get_matching_orders(db, tx_hash, give_asset, get_asset):
    cursor = db.cursor()
    query = '''
        SELECT * FROM (
            SELECT *, MAX(rowid)
            FROM orders
            WHERE (tx_hash != ? AND give_asset = ? AND get_asset = ?)
            GROUP BY tx_hash
        ) WHERE status = ?
        ORDER BY tx_index, tx_hash
    '''
    bindings = (tx_hash, get_asset, give_asset, 'open')
    cursor.execute(query, bindings)
    return cursor.fetchall()

def get_orders_by_asset(db, asset, status='open'):
    cursor = db.cursor()
    query = '''
        SELECT * FROM (
            SELECT *, MAX(rowid)
            FROM orders
            WHERE (give_asset = ? OR get_asset = ?)
            GROUP BY tx_hash
        ) WHERE status = ?
    '''
    bindings = (asset, asset, status)
    cursor.execute(query, bindings)
    return cursor.fetchall()


def get_order_matches_by_order(db, tx_hash, status='pending'):
    cursor = db.cursor()
    query = '''
        SELECT * FROM (
            SELECT *, MAX(rowid)
            FROM order_matches
            WHERE (tx0_hash = ? OR tx1_hash = ?)
            GROUP BY id
        ) WHERE status = ?
    '''
    bindings = (tx_hash, tx_hash, status)
    cursor.execute(query, bindings)
    return cursor.fetchall()


### UPDATES ###

def update_order(db, tx_hash, update_data):
    insert_update(db, 'orders', 'tx_hash', tx_hash, update_data)


def mark_order_as_filled(db, tx0_hash, tx1_hash, source=None):

    select_bindings = {
        'tx0_hash': tx0_hash,
        'tx1_hash': tx1_hash
    }

    where_source = ''
    if source is not None:
        where_source = f' AND source = :source'
        select_bindings['source'] = source

    # no sql injection here
    select_query = f'''
        SELECT * FROM (
            SELECT *, MAX(rowid) as rowid
            FROM orders
            WHERE
                tx_hash in (:tx0_hash, :tx1_hash)
                {where_source}
            GROUP BY tx_hash
        ) WHERE give_remaining = 0 OR get_remaining = 0
    ''' # nosec B608

    cursor = db.cursor()
    cursor.execute(select_query, select_bindings)
    for order in cursor:
        update_data = {
            'status': 'filled'
        }
        insert_update(db, 'orders', 'rowid', order['rowid'], update_data)


def update_order_match_status(db, id, status):
    update_data = {
        'status': status
    }
    insert_update(db, 'order_matches', 'id', id, update_data)


#####################
#       RPS         #
#####################

### SELECTS ###

def get_matched_not_expired_rps(db, tx0_hash, tx1_hash, expire_index):
    cursor = db.cursor()
    query = '''
        SELECT * FROM (
            SELECT *, MAX(rowid) as rowid
            FROM rps
            WHERE tx_hash IN (?, ?)
            AND expire_index >= ?
            GROUP BY tx_hash
        ) WHERE status = ?
    '''
    bindings = (tx0_hash, tx1_hash, expire_index, 'matched')
    cursor.execute(query, bindings)
    return cursor.fetchall()


def get_already_matched_rps(db, tx_hash):
    cursor = db.cursor()
    query = '''
        SELECT *, MAX(rowid) AS rowid
        FROM rps_matches
        WHERE tx0_hash = ? OR tx1_hash = ?
        GROUP BY id
        ORDER BY rowid
    '''
    bindings = (tx_hash, tx_hash)
    cursor.execute(query, bindings)
    return cursor.fetchall()


def get_matching_rps(db, possible_moves, wager, source, already_matched_tx_hashes):
    cursor = db.cursor()
    bindings = (possible_moves, wager, source)
    already_matched_cond = ''
    if already_matched_tx_hashes:
        place_holders = ','.join(['?' for e in range(0, len(already_matched_tx_hashes))])
        already_matched_cond = f'''AND tx_hash NOT IN ({place_holders})'''
        bindings += tuple(already_matched_tx_hashes)
    bindings += ('open',)
    # no sql injection here
    query = f'''
        SELECT * FROM (
            SELECT *, MAX(rowid) FROM rps
            WHERE (possible_moves = ? AND wager = ? AND source != ? {already_matched_cond})
            GROUP BY tx_hash
        ) WHERE status = ?
        ORDER BY tx_index LIMIT 1
    ''' # nosec B608
    cursor.execute(query, bindings)
    return cursor.fetchall()


def get_rps_to_expire(db, block_index):
    cursor = db.cursor()
    query = '''
        SELECT * FROM (
            SELECT *, MAX(rowid)
            FROM rps
            WHERE expire_index = ? - 1
            GROUP BY tx_hash
        ) WHERE status = ?
        ORDER BY tx_index, tx_hash
    '''
    bindings = (block_index, 'open')
    cursor.execute(query, bindings)
    return cursor.fetchall()


def get_rps(db, tx_hash):
    cursor = db.cursor()
    query = '''
        SELECT * FROM rps
        WHERE tx_hash = ?
        ORDER BY rowid DESC
        LIMIT 1
    '''
    bindings = (tx_hash,)
    cursor.execute(query, bindings)
    return cursor.fetchall()


def get_rps_matches_to_expire(db, block_index):
    cursor = db.cursor()
    query = '''
        SELECT * FROM (
            SELECT *, MAX(rowid) AS rowid
            FROM rps_matches
            WHERE match_expire_index < ?
            GROUP BY id
        ) WHERE status IN (?, ? , ?)
        ORDER BY rowid
    '''
    bindings = (block_index, 'pending', 'pending and resolved', 'resolved and pending')
    cursor.execute(query, bindings)
    return cursor.fetchall()


def get_rps_match(db, id):
    cursor = db.cursor()
    query = '''
        SELECT * FROM rps_matches
        WHERE id = ?
        ORDER BY rowid
        DESC LIMIT 1
    '''
    bindings = (id,)
    cursor.execute(query, bindings)
    return cursor.fetchall()


def get_rpsresolves(db, source=None, status=None, rps_match_id=None):
    cursor = db.cursor()
    where = []
    bindings = []
    if source is not None:
        where.append('source = ?')
        bindings.append(source)
    if status is not None:
        where.append('status = ?')
        bindings.append(status)
    if rps_match_id is not None:
        where.append('rps_match_id = ?')
        bindings.append(rps_match_id)
    # no sql injection here
    query = f'''SELECT * FROM rpsresolves WHERE ({" AND ".join(where)})''' # nosec B608
    cursor.execute(query, tuple(bindings))
    return cursor.fetchall()


### UPDATES ###

def update_rps_match_status(db, id, status):
    update_data = {
        'status': status
    }
    insert_update(db, 'rps_matches', 'id', id, update_data)


def update_rps_status(db, tx_hash, status):
    update_data = {
        'status': status
    }
    insert_update(db, 'rps', 'tx_hash', tx_hash, update_data)


#####################
#     SUPPLIES      #
#####################

# Ugly way to get holders but we want to preserve the order with the old query
# to not break checkpoints
def _get_holders(cursor, id_fields, hold_fields_1, hold_fields_2=None, exclude_empty_holders=False, table=None):
    save_records = {}
    for record in cursor:
        id = ' '.join([str(record[field]) for field in id_fields])
        if id not in save_records:
            save_records[id] = record
            continue
        if save_records[id]['rowid'] < record['rowid']:
            save_records[id] = record
            continue
    holders = []
    for holder in save_records.values():
        if holder[hold_fields_1['address_quantity']] > 0 or \
            (exclude_empty_holders == False and holder[hold_fields_1['address_quantity']] == 0):
            holders.append({
                'address': holder[hold_fields_1['address']],
                'address_quantity': holder[hold_fields_1['address_quantity']],
                'escrow': holder[hold_fields_1['escrow']] if 'escrow' in hold_fields_1 else None,
                #'table': table # for debugging purposes
            })
        if hold_fields_2 is not None:
            if holder[hold_fields_2['address_quantity']] > 0 or \
                (exclude_empty_holders == False and holder[hold_fields_2['address_quantity']] == 0):
                holders.append({
                    'address': holder[hold_fields_2['address']],
                    'address_quantity': holder[hold_fields_2['address_quantity']],
                    'escrow': holder[hold_fields_2['escrow']] if 'escrow' in hold_fields_2 else None,
                    #'table': table # for debugging purposes
                })
    return holders


def holders(db, asset, exclude_empty_holders=False):
    """Return holders of the asset."""
    holders = []
    cursor = db.cursor()

    # Balances

    query = '''
        SELECT *, rowid
        FROM balances
        WHERE asset = ?
    '''
    bindings = (asset,)
    cursor.execute(query, bindings)
    holders += _get_holders(
        cursor,
        ['asset', 'address'],
        {'address': 'address', 'address_quantity': 'quantity'},
        exclude_empty_holders=exclude_empty_holders,
        table='balances'
    )

    # Funds escrowed in orders. (Protocol change.)
    query = '''
        SELECT * FROM (
            SELECT *, MAX(rowid)
            FROM orders
            WHERE give_asset = ?
            GROUP BY tx_hash
        ) WHERE status = ?
        ORDER BY tx_index
    '''
    bindings = (asset, 'open')
    cursor.execute(query, bindings)
    holders += _get_holders(
        cursor,
        ['tx_hash'],
        {'address': 'source', 'address_quantity': 'give_remaining', 'escrow': 'tx_hash'},
        #exclude_empty_holders=exclude_empty_holders,
        table='orders'
    )

    # Funds escrowed in pending order matches. (Protocol change.)
    query = '''
        SELECT * FROM (
            SELECT *, MAX(rowid)
            FROM order_matches
            WHERE forward_asset = ?
            GROUP BY id
        ) WHERE status = ?
    '''
    bindings = (asset, 'pending')
    cursor.execute(query, bindings)
    holders += _get_holders(
        cursor,
        ['id'],
        {'address': 'tx0_address', 'address_quantity': 'forward_quantity', 'escrow': 'id'},
        #exclude_empty_holders=exclude_empty_holders,
        table='order_matches1'
    )

    query = '''
        SELECT * FROM (
            SELECT *, MAX(rowid) AS rowid
            FROM order_matches
            WHERE backward_asset = ?
        ) WHERE status = ?
        ORDER BY rowid
    '''
    bindings = (asset, 'pending')
    cursor.execute(query, bindings)
    holders += _get_holders(
        cursor,
        ['id'],
        {'address': 'tx1_address', 'address_quantity': 'backward_quantity', 'escrow': 'id'},
        #exclude_empty_holders=exclude_empty_holders,
        table='order_matches2'
    )

    # Bets and RPS (and bet/rps matches) only escrow XCP.
    if asset == config.XCP:
        query = '''
            SELECT * FROM (
                SELECT *, MAX(rowid)
                FROM bets
                GROUP BY tx_hash
            ) WHERE status = ?
            ORDER BY tx_index
        '''
        bindings = ('open',)
        cursor.execute(query, bindings)
        holders += _get_holders(
            cursor,
            ['tx_hash'],
            {'address': 'source', 'address_quantity': 'wager_remaining', 'escrow': 'tx_hash'},
            #exclude_empty_holders=exclude_empty_holders,
            table='bets'
        )

        query = '''
            SELECT * FROM (
                SELECT *, MAX(rowid)
                FROM bet_matches
                GROUP BY id
            ) WHERE status = ?
        '''
        bindings = ('pending',)
        cursor.execute(query, bindings)
        holders += _get_holders(
            cursor,
            ['id'],
            {'address': 'tx0_address', 'address_quantity': 'forward_quantity', 'escrow': 'id'},
            {'address': 'tx1_address', 'address_quantity': 'backward_quantity', 'escrow': 'id'},
            #exclude_empty_holders=exclude_empty_holders,
            table='bet_matches'
        )

        query = '''
            SELECT * FROM (
                SELECT *, MAX(rowid)
                FROM rps
                GROUP BY tx_hash
            ) WHERE status = ?
            ORDER BY tx_index
        '''
        bindings = ('open',)
        cursor.execute(query, bindings)
        holders += _get_holders(
            cursor,
            ['tx_hash'],
            {'address': 'source', 'address_quantity': 'wager', 'escrow': 'tx_hash'},
            #exclude_empty_holders=exclude_empty_holders,
            table='rps'
        )

        query = '''
            SELECT * FROM (
                SELECT *, MAX(rowid)
                FROM rps_matches
                GROUP BY id
            ) WHERE status IN (?, ?, ?)
        '''
        bindings = ('pending', 'pending and resolved', 'resolved and pending')
        cursor.execute(query, bindings)
        holders += _get_holders(
            cursor,
            ['id'],
            {'address': 'tx0_address', 'address_quantity': 'wager', 'escrow': 'id'},
            {'address': 'tx1_address', 'address_quantity': 'wager', 'escrow': 'id'},
            #exclude_empty_holders=exclude_empty_holders,
            table='rps_matches'
        )

    if enabled('dispensers_in_holders'):
        # Funds escrowed in dispensers.
        query = '''
            SELECT * FROM (
                SELECT *, MAX(rowid)
                FROM dispensers
                WHERE asset = ?
                GROUP BY source, asset
            ) WHERE status = ?
            ORDER BY tx_index
        '''
        bindings = (asset, 0)
        cursor.execute(query, bindings)
        holders += _get_holders(
            cursor,
            ['tx_hash', 'source', 'asset', 'satoshirate', 'give_quantity'],
            {'address': 'source', 'address_quantity': 'give_remaining'},
            #exclude_empty_holders=exclude_empty_holders,
            table='dispensers'
        )

    cursor.close()
    return holders


def xcp_created (db):
    """Return number of XCP created thus far."""
    cursor = db.cursor()
    query = '''
        SELECT SUM(earned) AS total
        FROM burns
        WHERE (status = ?)
    '''
    bindings = ('valid',)
    cursor.execute(query, bindings)
    total = list(cursor)[0]['total'] or 0
    cursor.close()
    return total


def xcp_destroyed (db):
    """Return number of XCP destroyed thus far."""
    cursor = db.cursor()
    # Destructions.
    query = '''
        SELECT SUM(quantity) AS total
        FROM destructions
        WHERE (status = ? AND asset = ?)
    '''
    bindings = ('valid', config.XCP)
    cursor.execute(query, bindings)
    destroyed_total = list(cursor)[0]['total'] or 0

    # Subtract issuance fees.
    query = '''
        SELECT SUM(fee_paid) AS total
        FROM issuances
        WHERE status = ?
    '''
    bindings = ('valid',)
    cursor.execute(query, bindings)
    issuance_fee_total = list(cursor)[0]['total'] or 0

    # Subtract dividend fees.
    query = '''
        SELECT SUM(fee_paid) AS total
        FROM dividends
        WHERE status = ?
    '''
    bindings = ('valid',)
    cursor.execute(query, bindings)
    dividend_fee_total = list(cursor)[0]['total'] or 0

    # Subtract sweep fees.
    query = '''
        SELECT SUM(fee_paid) AS total
        FROM sweeps
        WHERE status = ?
    '''
    bindings = ('valid',)
    cursor.execute(query, bindings)
    sweeps_fee_total = list(cursor)[0]['total'] or 0
    cursor.close()
    return destroyed_total + issuance_fee_total + dividend_fee_total + sweeps_fee_total


def xcp_supply (db):
    """Return the XCP supply."""
    return xcp_created(db) - xcp_destroyed(db)


def creations (db):
    """Return creations."""
    cursor = db.cursor()
    creations = {config.XCP: xcp_created(db)}
    query = '''
        SELECT asset, SUM(quantity) AS created
        FROM issuances
        WHERE status = ?
        GROUP BY asset
    '''
    bindings = ('valid',)
    cursor.execute(query, bindings)

    for issuance in cursor:
        asset = issuance['asset']
        created = issuance['created']
        creations[asset] = created

    cursor.close()
    return creations


def destructions (db):
    """Return destructions."""
    cursor = db.cursor()
    destructions = {config.XCP: xcp_destroyed(db)}
    query = '''
        SELECT asset, SUM(quantity) AS destroyed
        FROM destructions
        WHERE (status = ? AND asset != ?)
        GROUP BY asset
    '''
    bindings = ('valid', config.XCP)
    cursor.execute(query, bindings)

    for destruction in cursor:
        asset = destruction['asset']
        destroyed = destruction['destroyed']
        destructions[asset] = destroyed

    cursor.close()
    return destructions


def asset_issued_total (db, asset):
    """Return asset total issued."""
    cursor = db.cursor()
    query = '''
        SELECT SUM(quantity) AS total
        FROM issuances
        WHERE (status = ? AND asset = ?)
    '''
    bindings = ('valid', asset)
    cursor.execute(query, bindings)
    issued_total = list(cursor)[0]['total'] or 0
    cursor.close()
    return issued_total


def asset_destroyed_total (db, asset):
    """Return asset total destroyed."""
    cursor = db.cursor()
    query = '''
        SELECT SUM(quantity) AS total
        FROM destructions
        WHERE (status = ? AND asset = ?)
    '''
    bindings = ('valid', asset)
    cursor.execute(query, bindings)
    destroyed_total = list(cursor)[0]['total'] or 0
    cursor.close()
    return destroyed_total


def asset_supply (db, asset):
    """Return asset supply."""
    return asset_issued_total(db, asset) - asset_destroyed_total(db, asset)


def supplies (db):
    """Return supplies."""
    d1 = creations(db)
    d2 = destructions(db)
    return {key: d1[key] - d2.get(key, 0) for key in d1.keys()}


def held (db): #TODO: Rename ?

    queries = [
        '''
        SELECT asset, SUM(quantity) AS total FROM (
            SELECT address, asset, quantity, (address || asset) AS aa, MAX(rowid)
            FROM balances
            WHERE address IS NOT NULL
            GROUP BY aa
        ) GROUP BY asset
        ''',
        '''
        SELECT asset, SUM(quantity) AS total FROM (
            SELECT NULL, asset, quantity
            FROM balances
            WHERE address IS NULL
        ) GROUP BY asset
        ''',
        '''
        SELECT give_asset AS asset, SUM(give_remaining) AS total FROM (
            SELECT give_asset, give_remaining, status, MAX(rowid)
            FROM orders
            GROUP BY tx_hash
        ) WHERE status = 'open' GROUP BY asset
        ''',
        '''
        SELECT give_asset AS asset, SUM(give_remaining) AS total FROM (
            SELECT give_asset, give_remaining, status, MAX(rowid)
            FROM orders
            WHERE give_asset = 'XCP' AND get_asset = 'BTC'
            GROUP BY tx_hash
        ) WHERE status = 'filled' GROUP BY asset
        ''',
        '''
        SELECT forward_asset AS asset, SUM(forward_quantity) AS total FROM (
            SELECT forward_asset, forward_quantity, status, MAX(rowid)
            FROM order_matches
            GROUP BY id
        ) WHERE status = 'pending' GROUP BY asset
        ''',
        '''
        SELECT backward_asset AS asset, SUM(backward_quantity) AS total FROM (
            SELECT backward_asset, backward_quantity, status, MAX(rowid)
            FROM order_matches
            GROUP BY id
        ) WHERE status = 'pending' GROUP BY asset
        ''',
        '''
        SELECT 'XCP' AS asset, SUM(wager_remaining) AS total FROM (
            SELECT wager_remaining, status, MAX(rowid)
            FROM bets
            GROUP BY tx_hash
        ) WHERE status = 'open'
        ''',
        '''
        SELECT 'XCP' AS asset, SUM(forward_quantity) AS total FROM (
            SELECT forward_quantity, status, MAX(rowid)
            FROM bet_matches
            GROUP BY id
        ) WHERE status = 'pending'
        ''',
        '''
        SELECT 'XCP' AS asset, SUM(backward_quantity) AS total FROM (
            SELECT backward_quantity, status, MAX(rowid)
            FROM bet_matches
            GROUP BY id
        ) WHERE status = 'pending'
        ''',
        '''
        SELECT 'XCP' AS asset, SUM(wager) AS total FROM (
            SELECT wager, status, MAX(rowid)
            FROM rps
            GROUP BY tx_hash
        ) WHERE status = 'open'
        ''',
        '''
        SELECT 'XCP' AS asset, SUM(wager * 2) AS total FROM (
            SELECT wager, status, MAX(rowid)
            FROM rps_matches
            GROUP BY id
        ) WHERE status IN ('pending', 'pending and resolved', 'resolved and pending')
        ''',
        '''
        SELECT asset, SUM(give_remaining) AS total FROM (
            SELECT asset, give_remaining, status, MAX(rowid)
            FROM dispensers
            GROUP BY tx_hash
        ) WHERE status IN (0, 1, 11) GROUP BY asset
        ''',
    ]
    # no sql injection here
    sql = "SELECT asset, SUM(total) AS total FROM (" + " UNION ALL ".join(queries) + ") GROUP BY asset;" # nosec B608

    cursor = db.cursor()
    cursor.execute(sql)
    held = {}
    for row in cursor:
        asset = row['asset']
        total = row['total']
        held[asset] = total

    return held


#############################
#     PROTOCOL CHANGES      #
#############################


def enabled(change_name, block_index=None):
    """Return True if protocol change is enabled."""
    if config.REGTEST:
        return True # All changes are always enabled on REGTEST

    if config.TESTNET:
        index_name = 'testnet_block_index'
    else:
        index_name = 'block_index'

    enable_block_index = PROTOCOL_CHANGES[change_name][index_name]

    if not block_index:
        block_index = CURRENT_BLOCK_INDEX

    if block_index >= enable_block_index:
        return True
    else:
        return False


def get_value_by_block_index(change_name, block_index=None):

    if not block_index:
        block_index = CURRENT_BLOCK_INDEX

    max_block_index = -1

    if config.REGTEST:
        for key, value in PROTOCOL_CHANGES[change_name]["testnet"]:
            if int(key) > int(max_block_index):
                max_block_index = key
        return PROTOCOL_CHANGES[change_name]["testnet"][max_block_index]["value"]

    if config.TESTNET:
        index_name = 'testnet'
    else:
        index_name = 'mainnet'

    for key in PROTOCOL_CHANGES[change_name][index_name]:
        if int(key) > int(max_block_index) and block_index >= int(key):
            max_block_index = key

    return PROTOCOL_CHANGES[change_name][index_name][max_block_index]["value"]
