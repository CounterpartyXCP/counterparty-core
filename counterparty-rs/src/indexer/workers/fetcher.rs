use crossbeam_channel::{select, Receiver, Sender};

use crate::indexer::{
    bitcoin_client::BitcoinRpc,
    types::{
        error::Error,
        pipeline::{BlockHasEntries, Done, HasHeight, SetBlock},
    },
    utils::with_retry,
};

pub fn new<T, U, B, C>(
    client: C,
) -> impl Fn(Receiver<Box<T>>, Sender<Box<U>>, Done) -> Result<(), Error> + Clone
where
    T: HasHeight + SetBlock<B, U>,
    B: BlockHasEntries,
    C: BitcoinRpc<B>,
{
    move |rx, tx, done| loop {
        select! {
          recv(rx) -> result => {
            let data = match result {
                Ok(data) => data,
                Err(_) => return Ok(()),
            };

            let height = data.get_height();
            let hash = with_retry(
                done.clone(),
                || client.get_block_hash(height),
                format!("Error fetching block hash for height {}", height),
            )?;

            let block =with_retry(
                done.clone(),
                || client.get_block(&hash),
                format!("Error fetching block for hash {}", &hash),
            )?;

            if tx.send(data.set_block(hash, block)).is_err() {
                return Ok(());
            };
          }
        }
    }
}
