import getpass
import binascii
from functools import lru_cache

import bitcoin as bitcoinlib

def wallet_unlock ():
    getinfo = rpc.getinfo()
    if 'unlocked_until' in getinfo:
        if getinfo['unlocked_until'] >= 60:
            return True # Wallet is unlocked for at least the next 60 seconds.
        else:
            passphrase = getpass.getpass('Enter your Bitcoind[‐Qt] wallet passhrase: ')
            print('Unlocking wallet for 60 (more) seconds.')
            rpc('walletpassphrase', [passphrase, 60])
    else:
        return True    # Wallet is unencrypted.

def deserialize(data):
    return bitcoinlib.core.CTransaction.deserialize(binascii.unhexlify(data))

@lru_cache(maxsize=4096)
def get_cached_raw_transaction(tx_hash):
    return rpc.getrawtransaction(tx_hash, verbose=True)

# vim: tabstop=8 expandtab shiftwidth=4 softtabstop=4
