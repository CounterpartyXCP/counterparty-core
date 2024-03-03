import binascii, os, math, json, hashlib
from multiprocessing import resource_tracker

from counterparty_rs import utils as pycoin_rs_utils

bytes_from_int = chr if bytes == str else lambda x: bytes([x])

def b2h(b):
    return binascii.hexlify(b).decode('utf-8')

def random_hex(length):
    return binascii.b2a_hex(os.urandom(length))

def double_hash(b): 
    return hashlib.sha256(hashlib.sha256(b).digest()).digest()

def inverse_hash(hashstring):
    return pycoin_rs_utils.inverse_hash(hashstring)

def ib2h(b):
    return inverse_hash(b2h(b))

class JsonDecimalEncoder(json.JSONEncoder):
    def default(self, o):
        if isinstance(o,  decimal.Decimal):
            return str(o)
        return super(DecimalEncoder, self).default(o)

def decode_value(key, value):
    #Repeated key to make both same length
    adjusted_key = key* int(math.ceil(float(len(value))/len(key)))
    adjusted_key = adjusted_key[:len(value)]
    return bytes([_a ^ _b for _a, _b in zip(adjusted_key, value)])


def remove_shm_from_resource_tracker():
    """Monkey-patch multiprocessing.resource_tracker so SharedMemory won't be tracked

    More details at: https://bugs.python.org/issue38119
    """

    def fix_register(name, rtype):
        if rtype == "shared_memory":
            return
        return resource_tracker._resource_tracker.register(name, rtype)
    resource_tracker.register = fix_register

    def fix_unregister(name, rtype):
        if rtype == "shared_memory":
            return
        return resource_tracker._resource_tracker.unregister(name, rtype)
    resource_tracker.unregister = fix_unregister

    if "shared_memory" in resource_tracker._CLEANUP_FUNCS:
        del resource_tracker._CLEANUP_FUNCS["shared_memory"]
