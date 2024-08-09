from counterpartycore.lib.messages import dispenser


def compose(db, source, destination, quantity):
    return dispenser.compose_dispense(db, source, destination, quantity, no_only_btc=True)
