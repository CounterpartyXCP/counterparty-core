import dredd_hooks as hooks
from counterpartycore.lib import config

config.BACKEND_URL = "http://rpc:rpc@localhost:18443"
config.BACKEND_SSL_NO_VERIFY = True
config.REQUESTS_TIMEOUT = 20
config.ADDRESSVERSION = config.ADDRESSVERSION_REGTEST
config.NETWORK_NAME = "regtest"

API_ROOT = "http://localhost:24000"


@hooks.before_each
def my_before_all_hook(transaction):
    if "/compose" in transaction["fullPath"]:
        transaction["fullPath"] = transaction["fullPath"].replace(
            "exclude_utxos_with_balances=False", "exclude_utxos_with_balances=True"
        )

    return transaction
