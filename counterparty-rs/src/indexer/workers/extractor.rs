use crossbeam_channel::{select, Receiver, Sender};

use crate::indexer::{
    config::Config,
    stopper::Stopper,
    types::{error::Error, pipeline::Transition},
};

pub fn new<T, U>(
    config: Config,
) -> impl Fn(Receiver<Box<T>>, Sender<Box<U>>, Stopper) -> Result<(), Error> + Clone
where
    T: Transition<Box<U>, Config, ()>,
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
                  let (_, s) = data.transition(config.clone())?;
                  if tx.send(s).is_err() {
                      return Ok(());
                  };
                }
            }
        }
    }
}
