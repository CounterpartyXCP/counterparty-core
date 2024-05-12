use crossbeam_channel::Receiver;

use crate::indexer::types::error::Error;

pub fn new(chan: Receiver<Vec<u8>>) -> Result<Vec<u8>, Error> {
    Ok(chan.recv()?)
}
