import os
import pprint

import apsw
from counterpartycore.lib.messages.data import checkpoints

# db_name = "counterparty.testnet4.db"
# checkpoints = checkpoints.CHECKPOINTS_TESTNET4

db_name = "counterparty.testnet3.db"
checkpoints = checkpoints.CHECKPOINTS_TESTNET3

# db_name = "blocks.db"
# checkpoints = checkpoints.CHECKPOINTS_MAINNET

db = apsw.Connection(os.path.join(os.path.expanduser("~"), ".local/share/counterparty/", db_name))

new_checkpoints = {}
for block_index, checkpoint in checkpoints.items():
    new_checkpoints[block_index] = checkpoint
    print(f"block_index: {block_index}")
    migration_hash = db.execute(
        "SELECT migration_hash FROM blocks WHERE block_index = ?", (block_index,)
    ).fetchone()[0]
    new_checkpoints[block_index]["migration_hash"] = migration_hash

pp = pprint.PrettyPrinter(indent=4)
pp.pprint(new_checkpoints)
