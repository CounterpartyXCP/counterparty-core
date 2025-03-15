import os
import pprint

import apsw
from counterpartycore.lib.messages.data import checkpoints

# db_name = "counterparty.testnet4.db"
# checkpoints = checkpoints.CHECKPOINTS_TESTNET4

# db_name = "counterparty.testnet3.db"
# checkpoints = checkpoints.CHECKPOINTS_TESTNET3

db_name = "evanblocks.db"
checkpoints = checkpoints.CHECKPOINTS_MAINNET

db = apsw.Connection(os.path.join(os.path.expanduser("~"), ".local/share/counterparty/", db_name))

new_checkpoints = {}
for block_index in checkpoints.keys():
    new_checkpoints[block_index] = {}
    block = db.execute(
        "SELECT ledger_hash, txlist_hash FROM blocks WHERE block_index = ?", (block_index,)
    ).fetchone()
    new_checkpoints[block_index]["ledger_hash"] = block[0]
    new_checkpoints[block_index]["txlist_hash"] = block[1]

pp = pprint.PrettyPrinter(indent=4)
pp.pprint(new_checkpoints)
