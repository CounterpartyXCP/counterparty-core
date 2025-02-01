import dredd_hooks as hooks


@hooks.before_each
def my_before_all_hook(transaction):
    if "/compose" in transaction["fullPath"]:
        transaction["fullPath"] = transaction["fullPath"].replace(
            "exclude_utxos_with_balances=False", "exclude_utxos_with_balances=True"
        )

    return transaction
