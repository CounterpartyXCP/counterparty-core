#! /usr/bin/python3

"""Based on pyethereum <https://github.com/ethereum/pyethereum>."""

from counterpartylib.lib import util
from counterpartylib.lib import config
from counterpartylib.lib import log
from counterpartylib.lib.messages.scriptlib import rlp
from counterpartylib.lib.messages.scriptlib import utils

import logging
logger = logging.getLogger(__name__)
import pickle

# NOTE: Not logging most of the specifics here.

class Block(object):

    def __init__(self, db, block_hash):
        self.db = db

        cursor = db.cursor()
        block = list(cursor.execute('''SELECT * FROM blocks WHERE block_hash = ?''', (block_hash,)))[0]
        self.timestamp = block['block_time']
        self.number = block['block_index']
        self.prevhash = block['previous_block_hash']
        self.difficulty = block['difficulty']

        return

    def postqueue_delete(self):
        cursor = self.db.cursor()
        cursor.execute('''DELETE FROM postqueue''')

    def postqueue_insert(self, message):
        cursor = self.db.cursor()
        cursor.execute('''INSERT INTO postqueue VALUES(:message)''', {'message': pickle.dumps(message)})

    def postqueue_get(self):
        cursor = self.db.cursor()
        return list(cursor.execute('''SELECT * FROM postqueue'''))

    def postqueue_append(self, post_msg):
        cursor = self.db.cursor()
        cursor.execute('''INSERT INTO postqueue VALUES(:message)''', {'message': pickle.dumps(post_msg)})

    def postqueue_pop(self):
        cursor = self.db.cursor()
        postqueues = list(cursor.execute('''SELECT * FROM postqueue ORDER BY rowid ASC'''))
        first_message_pickled = postqueues[0]['message']                                                # Get first entry.
        cursor.execute('''DELETE FROM postqueue WHERE rowid = (SELECT MIN(rowid) FROM postqueue)''')    # Delete first entry.
        return pickle.loads(first_message_pickled)


    def suicides_append(self, contract_id):
        cursor = self.db.cursor()
        cursor.execute('''INSERT INTO suicides VALUES(:contract_id)''', {'contract_id': contract_id})

    def suicides_get(self):
        cursor = self.db.cursor()
        return list(cursor.execute('''SELECT * FROM suicides'''))

    def suicides_delete(self):
        cursor = self.db.cursor()
        cursor.execute('''DELETE FROM suicides''')

    def revert(self):
        logger.debug('### REVERTING ###')

    def get_storage_data(self, contract_id, key=None):
        cursor = self.db.cursor()

        if key == None:
            cursor.execute('''SELECT * FROM storage WHERE contract_id = ? ''', (contract_id,))
            storages = list(cursor)
            return storages

        # print('prekey', key)
        key = key.to_bytes(32, byteorder='big')
        cursor.execute('''SELECT * FROM storage WHERE contract_id = ? AND key = ?''', (contract_id, key))
        storages = list(cursor)
        # print('key', key)
        if not storages:
            return 0
        value = storages[0]['value']

        value = rlp.big_endian_to_int(value)
        return value

    def set_storage_data(self, contract_id, key, value):
        # NOTE: This could all be done more elegantly, I think.

        key = key.to_bytes(32, byteorder='big')
        value = value.to_bytes(32, byteorder='big')

        cursor = self.db.cursor()
        cursor.execute('''SELECT * FROM storage WHERE contract_id = ? AND key = ?''', (contract_id, key))
        storages = list(cursor)
        if storages:    # Update value.
            bindings = {
                'contract_id': contract_id,
                'key': key,
                'value': value
                }
            log.message(self.db, self.number, 'update', 'storage', bindings)
            sql='''UPDATE storage SET value = :value WHERE contract_id = :contract_id AND key = :key'''
            cursor.execute(sql, bindings)
        else:           # Insert value.
            bindings = {
                'contract_id': contract_id,
                'key': key,
                'value': value
                }
            log.message(self.db, self.number, 'insert', 'storage', bindings)
            sql='''INSERT INTO storage VALUES (:contract_id, :key, :value)'''
            cursor.execute(sql, bindings)

        storages = cursor.execute('''SELECT * FROM storage WHERE contract_id = ? AND key = ?''', (contract_id, key))

        return value


    def account_to_dict(self, address):
        return {'nonce': Block.get_nonce(self, address), 'balance': Block.get_balance(self, address), 'storage': Block.get_storage_data(self, address), 'code': utils.hexprint(Block.get_code(self, address))}

    def get_code (self, contract_id):
        cursor = self.db.cursor()
        cursor.execute('''SELECT * FROM contracts WHERE contract_id = ?''', (contract_id,))
        contracts = list(cursor)

        if not contracts:
            return b''
        else: code = contracts[0]['code']

        return code

    def get_nonce(self, address):
        cursor = self.db.cursor()
        nonces = list(cursor.execute('''SELECT * FROM nonces WHERE (address = ?)''', (address,)))
        if not nonces: return 0
        else: return nonces[0]['nonce']

    def set_nonce(self, address, nonce):
        cursor = self.db.cursor()
        cursor.execute('''SELECT * FROM nonces WHERE (address = :address)''', {'address': address})
        nonces = list(cursor)
        bindings = {'address': address, 'nonce': nonce}
        if not nonces:
            log.message(self.db, self.number, 'insert', 'nonces', bindings)
            cursor.execute('''INSERT INTO nonces VALUES(:address, :nonce)''', bindings)
        else:
            log.message(self.db, self.number, 'update', 'nonces', bindings)
            cursor.execute('''UPDATE nonces SET nonce = :nonce WHERE (address = :address)''', bindings)

    def increment_nonce(self, address):
        nonce = Block.get_nonce(self, address)
        Block.set_nonce(self, address, nonce + 1)

    def decrement_nonce(self, address):
        nonce = Block.get_nonce(self, address)
        Block.set_nonce(self, address, nonce - 1)

    def get_balance(self, address, asset=config.XCP):
        return util.get_balance(self.db, address, asset)

    def transfer_value(self, tx, source, destination, quantity, asset=config.XCP):
        if source:
            util.debit(self.db, source, asset, quantity, action='transfer value', event=tx.tx_hash)
        if destination:
            util.credit(self.db, destination, asset, quantity, action='transfer value', event=tx.tx_hash)
        return True

    def del_account(self, contract_id):
        cursor = self.db.cursor()
        logger.debug('SUICIDING {}'.format(contract_id))
        bindings = {'contract_id': contract_id}
        log.message(self.db, self.number, 'delete', 'contracts', bindings)
        cursor.execute('''DELETE FROM contracts WHERE contract_id = :contract_id''', bindings)
        log.message(self.db, self.number, 'delete', 'storage', bindings)
        cursor.execute('''DELETE FROM storage WHERE contract_id = :contract_id''', bindings)

# vim: tabstop=8 expandtab shiftwidth=4 softtabstop=4
