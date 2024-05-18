use crossbeam_channel::{select, Receiver, Sender};

use crate::indexer::{stopper::Stopper, types::error::Error};

pub fn new<U, V>() -> impl Fn(Receiver<U>, Sender<V>, Stopper) -> Result<(), Error> + Clone {
    move |rx, _, stopper| {
        let (_, done) = stopper.subscribe()?;
        loop {
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
}
