use crossbeam_channel::{select, Receiver, Sender};

use crate::indexer::{
    config::{Config, Mode},
    stopper::Done,
    types::{error::Error, pipeline::Transition},
};

pub fn new<T, U>(
    config: Config,
) -> impl Fn(Receiver<Box<T>>, Sender<Box<U>>, Done) -> Result<(), Error> + Clone
where
    T: Transition<Box<U>, Mode, ()>,
{
    move |rx, tx, done| loop {
        select! {
            recv(done) -> _ => return Ok(()),
            recv(rx) -> result => {
                let data = match result {
                  Ok(data) => data,
                  Err(_) => return Ok(()),
              };
              let (_, s) = data.transition(config.mode)?;
              if tx.send(s).is_err() {
                  return Ok(());
              };
            }
        }
    }
}
