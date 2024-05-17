use crossbeam_channel::{select, Receiver};

use crate::indexer::{stopper::Stopper, types::error::Error};

pub fn new(stopper: Stopper, rx: Receiver<Vec<u8>>) -> Result<Vec<u8>, Error> {
    let (_, done) = stopper.subscribe()?;
    select! {
        recv(done) -> _ => Err(Error::Stopped),
        recv(rx) -> result => Ok(result?)
    }
}
