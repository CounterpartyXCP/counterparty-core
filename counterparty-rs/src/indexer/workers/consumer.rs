use std::{
    fs::File,
    sync::Arc,
    time::{Duration, Instant},
};

use bitcoin::hashes::hex::ToHex;
use bitcoincore_rpc::bitcoin::{hashes::Hash, Block};
use crossbeam_channel::{select, Receiver, Sender};
use std::io::Write;

use crate::indexer::{
    bitcoin_client::BitcoinClient,
    database::DatabaseOps,
    types::{error::Error, pipeline::Done},
};

fn block_handler<D: DatabaseOps>(
    f: Arc<File>,
    client: BitcoinClient,
    db: D,
    last_time: Instant,
    block: Box<Block>,
) -> Result<Instant, Error> {
    if let Some(script_hash) = block
        .txdata
        .iter()
        .find_map(|tx| tx.output.first())
        .map(|o| o.script_pubkey.script_hash().as_byte_array().to_owned())
    {
        if last_time.elapsed() >= Duration::from_secs(1) {
            writeln!(f.clone(), "{:?}", script_hash.to_hex())?;
            return Ok(Instant::now());
        }
    }
    Ok(last_time)
}

pub fn new<U, D: DatabaseOps>(
    f: Arc<File>,
    client: BitcoinClient,
    db: D,
) -> impl Fn(Receiver<Box<Block>>, Sender<U>, Done) -> Result<(), Error> + Clone {
    move |rx, _, done| {
        let mut last_time = Instant::now();
        loop {
            select! {
              recv(done) -> _ => return Ok(()),
              recv(rx) -> result => {
                  let block = match result {
                    Ok(block) => block,
                    Err(_) => return Ok(()),
                  };

                  last_time = block_handler(f.clone(), client.clone(), db.clone(), last_time, block)?;
              }
            }
        }
    }
}
