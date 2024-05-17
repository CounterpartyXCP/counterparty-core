use crossbeam_channel::{select, Receiver};

use crate::indexer::types::error::Error;

pub fn new(rx: Receiver<Vec<u8>>, done: Receiver<()>) -> Result<Vec<u8>, Error> {
    select! {
        recv(done) -> _ => Err(Error::Stopped),
        recv(rx) -> result => Ok(result?)
    }
}
