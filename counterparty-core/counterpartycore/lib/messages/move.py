import logging

from counterpartycore.lib import config, ledger, util

logger = logging.getLogger(config.LOGGER_NAME)


# call on each transaction
def move_assets(db, tx):
    if "utxos_info" not in tx or not tx["utxos_info"]:
        return

    sources, destination, _outputs_count, _op_return_output = util.parse_utxos_info(
        tx["utxos_info"]
    )

    # do nothing if no source or destination
    if len(sources) == 0 or not destination:
        return

    # we move all assets from the sources to the destination
    action = "utxo move"
    msg_index = 0
    # we move all assets from each source to the destination
    for source in sources:
        balances = ledger.get_utxo_balances(db, source)
        for balance in balances:
            if balance["quantity"] == 0:
                continue
            # debit asset from source
            ledger.debit(
                db,
                source,
                balance["asset"],
                balance["quantity"],
                tx["tx_index"],
                action=action,
                event=tx["tx_hash"],
            )
            # credit asset to destination
            ledger.credit(
                db,
                destination,
                balance["asset"],
                balance["quantity"],
                tx["tx_index"],
                action=action,
                event=tx["tx_hash"],
            )
            # store the move in the `sends` table
            bindings = {
                "tx_index": tx["tx_index"],
                "tx_hash": tx["tx_hash"],
                "block_index": tx["block_index"],
                "status": "valid",
                "source": source,
                "destination": destination,
                "asset": balance["asset"],
                "quantity": balance["quantity"],
                "msg_index": msg_index,
            }

            ledger.insert_record(db, "sends", bindings, "UTXO_MOVE")
            msg_index += 1

            # log the move
            logger.info(
                f"Move {balance['asset']} from utxo: {source} to utxo: {destination} ({tx['tx_hash']})"
            )
