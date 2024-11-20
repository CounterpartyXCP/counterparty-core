import dredd_hooks as hooks


@hooks.before_each
def set_exact_fee_to_zero(transaction):
    # use 0 fee for all transactions
    transaction["fullPath"].replace("exact_fee=None", "exact_fee=0")
