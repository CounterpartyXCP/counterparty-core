use bitcoincore_rpc::bitcoin::BlockHash;
use crossbeam_channel::{select, Receiver, Sender};

use crate::indexer::{
    bitcoin_client::BitcoinRpc,
    stopper::Stopper,
    types::{
        error::Error,
        pipeline::{BlockHasEntries, HasHeight, Transition},
    },
    utils::with_retry,
};

pub fn new<T, U, B, C>(
    client: C,
) -> impl Fn(Receiver<Box<T>>, Sender<Box<U>>, Stopper) -> Result<(), Error> + Clone
where
    T: HasHeight + Transition<Box<U>, (BlockHash, Box<B>), ()>,
    B: BlockHasEntries,
    C: BitcoinRpc<B>,
{
    move |rx, tx, stopper| {
        let (_, done) = stopper.subscribe()?;
        loop {
            select! {
              recv(done) -> _ => return Ok(()),
              recv(rx) -> result => {
                let data = match result {
                    Ok(data) => data,
                    Err(_) => return Ok(()),
                };

                let height = data.get_height();
                let hash = with_retry(
                    stopper.clone(),
                    || client.get_block_hash(height),
                    format!("Error fetching block hash for height {}", height),
                )?;

                let block = with_retry(
                    stopper.clone(),
                    || client.get_block(&hash),
                    format!("Error fetching block for hash {}", &hash),
                )?;

                let (_, s) = data.transition((hash, block))?;
                if tx.send(s).is_err() {
                    return Ok(());
                };
              }
            }
        }
    }
}
