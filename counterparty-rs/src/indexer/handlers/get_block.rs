use crossbeam_channel::{select, Receiver};

use crate::indexer::{block::Block, stopper::Stopper, types::error::Error};

pub fn new(stopper: Stopper, rx: Receiver<Box<Block>>) -> Result<Box<Block>, Error> {
    let (_, done) = stopper.subscribe()?;
    select! {
        recv(done) -> _ => Err(Error::Stopped),
        recv(rx) -> result => Ok(result?)
    }
}

pub fn new_non_blocking(
    stopper: Stopper,
    rx: Receiver<Box<Block>>,
) -> Result<Option<Box<Block>>, Error> {
    let (_, done) = stopper.subscribe()?;
    select! {
        recv(done) -> _ => Err(Error::Stopped),
        recv(rx) -> result => Ok(Some(result?)),
        default() => Ok(None)
    }
}
