use bitcoincore_rpc::bitcoin::Block;
use crossbeam_channel::{select, Receiver, Sender};

use crate::indexer::types::{error::Error, pipeline::Done};

pub fn new<U>() -> impl Fn(Receiver<Box<Block>>, Sender<U>, Done) -> Result<(), Error> + Clone {
    move |rx, _, done| loop {
        select! {
          recv(done) -> _ => return Ok(()),
          recv(rx) -> result => {
              if result.is_err() {
                  return Ok(())
              }
          }
        }
    }
}
