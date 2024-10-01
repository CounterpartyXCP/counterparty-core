import hashlib
import json
import sys
import time
import urllib.parse

import sh
from bitcoin import SelectParams
from bitcoin.core import (
    CMutableTransaction,
    CScriptWitness,
    CTxIn,
    CTxInWitness,
    CTxWitness,
    Hash160,
    b2lx,
)
from bitcoin.core.script import OP_0, SIGHASH_ALL, SIGVERSION_WITNESS_V0, CScript, SignatureHash
from bitcoin.wallet import CBitcoinSecret, P2WPKHBitcoinAddress

SelectParams("regtest")

SERVER = "http://localhost:24000/v2/"


def api_call(route, params=None):
    params = params or {}
    params_in_url = []
    for key, value in params.items():
        if f"<{key}>" in route:
            route = route.replace(f"<{key}>", value)
            params_in_url.append(key)
    for key in params_in_url:
        del params[key]
    query_string = urllib.parse.urlencode(params)
    url = f"{SERVER}{route}?{query_string}"
    return json.loads(sh.curl(url).strip())


def bake_bitcoin_clients():
    bitcoin_cli = sh.bitcoin_cli.bake(
        "-rpcuser=rpc",
        "-rpcpassword=rpc",
        "-rpcconnect=localhost",
        "-regtest",
    )
    return bitcoin_cli


def get_tx_out_amount(tx_hash, vout):
    raw_tx = json.loads(bitcoin_cli("getrawtransaction", tx_hash, 1).strip())
    return raw_tx["vout"][vout]["value"]


def get_new_address(seed: str):
    secret_key = CBitcoinSecret.from_secret_bytes(hashlib.sha256(bytes(seed, "utf-8")).digest())
    public_key = secret_key.pub
    scriptPubKey = CScript([OP_0, Hash160(public_key)])
    address = P2WPKHBitcoinAddress.from_scriptPubKey(scriptPubKey)
    print(
        {
            "address": str(address),
            "secret_key": str(secret_key),
            "public_key": public_key.hex(),
        }
    )
    return address, secret_key


def sign_rawtransaction(rawtransaction, address, secret_key, amount=None):
    tx = CMutableTransaction.deserialize(bytes.fromhex(rawtransaction))
    txin_index = 0
    redeem_script = address.to_redeemScript()
    prev_txid = b2lx(tx.vin[txin_index].prevout.hash)
    if not amount:
        amount = get_tx_out_amount(prev_txid, tx.vin[txin_index].prevout.n)
        amount = int(amount * 10e8)
    # amount = int(10 * 10e8)
    print("AMount", amount)
    sighash = SignatureHash(
        redeem_script, tx, txin_index, SIGHASH_ALL, amount=amount, sigversion=SIGVERSION_WITNESS_V0
    )
    signature = secret_key.sign(sighash) + bytes([SIGHASH_ALL])
    witness = [signature, secret_key.pub]
    ctxinwitnesses = [CTxInWitness(CScriptWitness(witness))]
    # clean scriptSig
    vins = [CTxIn(tx.vin[0].prevout, CScript())]
    signed_tx = CMutableTransaction(vins, tx.vout)
    signed_tx.wit = CTxWitness(ctxinwitnesses)
    return signed_tx.serialize().hex()


def send_funds_to_address(address):
    source_with_xcp = api_call("assets/XCP/balances", {"limit": 1})["result"][0]["address"]
    sh.python3(
        "tools/xcpcli.py",
        "send_send",
        "--address",
        source_with_xcp,
        "--asset",
        "XCP",
        "--quantity",
        int(10 * 10e8),
        "--destination",
        str(address),
        _out=sys.stdout,
        _err=sys.stdout,
    )
    sh.python3(
        "tools/xcpcli.py",
        "send_send",
        "--address",
        source_with_xcp,
        "--asset",
        "BTC",
        "--quantity",
        int(10 * 10e8),
        "--destination",
        str(address),
        _out=sys.stdout,
        _err=sys.stdout,
    )
    return source_with_xcp


bitcoin_cli = bake_bitcoin_clients()

# generate a new address
address, secret_key = get_new_address("correct horse battery staple")
# send XCP and BTC to this address
destination_address = send_funds_to_address(address)
# mine a block
bitcoin_cli("generatetoaddress", 1, destination_address)
time.sleep(10)

# generate unsigned pretx
unsigned_pretx_hex = api_call(
    f"addresses/{str(address)}/compose/send",
    {
        "asset": "XCP",
        "quantity": 5000,
        "destination": destination_address,
        "encoding": "p2sh",
        "fee_per_kb": 1000,
        "pubkeys": secret_key.pub.hex(),
    },
)["result"]["unsigned_pretx_hex"]
print("unsigned_pretx_hex:", unsigned_pretx_hex)

# sign pretx
signed_pretx_hex = sign_rawtransaction(unsigned_pretx_hex, address, secret_key, int(10 * 10e8))
print("signed_pretx_hex:", signed_pretx_hex)

# broadcast pretx and get pretx_txid
pretx_txid = bitcoin_cli("sendrawtransaction", signed_pretx_hex).strip()
print("pretx_txid", pretx_txid)
# mine a block
bitcoin_cli("generatetoaddress", 1, destination_address)
time.sleep(10)

# generate final tx
unsigned_finaltx_hex = api_call(
    f"addresses/{str(address)}/compose/send",
    {
        "asset": "XCP",
        "quantity": 5000,
        "destination": destination_address,
        "encoding": "p2sh",
        "fee_per_kb": 1000,
        "pubkeys": secret_key.pub.hex(),
        "p2sh_pretx_txid": pretx_txid,
    },
)["result"]["rawtransaction"]
print("unsigned_finaltx_hex:", unsigned_finaltx_hex)

# sign and broadcast final tx
signed_finaltx_hex = sign_rawtransaction(unsigned_finaltx_hex, address, secret_key)
print("signed_finaltx_hex:", signed_finaltx_hex)
txid = bitcoin_cli("sendrawtransaction", signed_finaltx_hex).strip()
