use bitcoincore_rpc::bitcoin::{hashes::Hash, BlockHash};

use crate::indexer::{
    bitcoin_client::BitcoinRpc,
    database::DatabaseOps,
    types::{entry::TxidVoutPrefix, error::Error, pipeline::BlockHasOutputs},
};

pub fn new<B, C, D>(
    client: C,
    db: D,
    script_hash: [u8; 20],
) -> Result<Vec<(TxidVoutPrefix, u64)>, Error>
where
    B: BlockHasOutputs,
    C: BitcoinRpc<B>,
    D: DatabaseOps,
{
    let mut unspent = Vec::new();
    let entries = db.get_funding_block_entries(script_hash)?;
    for entry in entries {
        #[allow(clippy::expect_used)]
        let block = client.get_block(
            &BlockHash::from_slice(&entry.hash).expect("Could not convert [u8;32] to BlockHash"),
        )?;
        let outputs = block.get_script_hash_outputs(script_hash);
        unspent.append(&mut db.filter_spent(outputs)?);
    }
    Ok(unspent)
}
