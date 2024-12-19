import json

import dredd_hooks as hooks
import requests
import sh
from counterpartycore.lib import config
from counterpartycore.lib.backend.bitcoind import pubkey_from_inputs_set

config.BACKEND_URL = "http://rpc:rpc@localhost:18443"
config.BACKEND_SSL_NO_VERIFY = True
config.REQUESTS_TIMEOUT = 20
config.ADDRESSVERSION = config.ADDRESSVERSION_REGTEST
config.NETWORK_NAME = "regtest"

API_ROOT = "http://localhost:24000"


def get_inputs_set(address):
    bitcoin_cli = sh.bitcoin_cli.bake(
        "-regtest",
        "-rpcuser=rpc",
        "-rpcpassword=rpc",
        "-rpcconnect=localhost",
    )
    list_unspent = json.loads(bitcoin_cli("listunspent", 0, 9999999, json.dumps([address])).strip())
    sorted(list_unspent, key=lambda x: -x["amount"])
    inputs = []
    for utxo in list_unspent[0:99]:
        inputs.append(f"{utxo['txid']}:{utxo['vout']}")
    return ",".join(inputs)


@hooks.before_each
def my_before_all_hook(transaction):
    if "/compose" in transaction["fullPath"]:
        source = None
        if "/addresses/" in transaction["fullPath"]:
            source = transaction["fullPath"].split("/addresses/")[1].split("/")[0]
        elif "/utxos/" in transaction["fullPath"]:
            utxo = transaction["fullPath"].split("/utxos/")[1].split("/")[0]
            source = requests.get(f"{API_ROOT}/v2/utxos/{utxo}/balances?limit=1").json()["result"][  # noqa S113
                0
            ]["utxo_address"]
        if source is not None:
            inputs_set = get_inputs_set(source)
            transaction["fullPath"] += f"&inputs_set={inputs_set}"
            transaction["fullPath"] += f"&pubkeys={pubkey_from_inputs_set(inputs_set, source)}"
            transaction["fullPath"] = transaction["fullPath"].replace("&inputs_set=None", "")
            transaction["fullPath"] = transaction["fullPath"].replace("&pubkeys=None", "")
            transaction["fullPath"] = transaction["fullPath"].replace(
                "exclude_utxos_with_balances=False", "exclude_utxos_with_balances=True"
            )

    return transaction
