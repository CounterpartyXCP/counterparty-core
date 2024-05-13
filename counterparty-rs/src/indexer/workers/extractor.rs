use crossbeam_channel::{select, Receiver, Sender};

use crate::indexer::{
    config::Config,
    types::{
        error::Error,
        pipeline::{BlockHasEntries, Done, HasBlock},
    },
};

pub fn new<T, U, B>(
    config: Config,
) -> impl Fn(Receiver<Box<T>>, Sender<Box<U>>, Done) -> Result<(), Error> + Clone
where
    T: HasBlock<B, U>,
    B: BlockHasEntries,
{
    move |rx, tx, done| loop {
        select! {
            recv(done) -> _ => return Ok(()),
            recv(rx) -> result => {
                let data = match result {
                  Ok(data) => data,
                  Err(_) => return Ok(()),
              };
              let new_data = data.with_entries(config.mode)?;
              if tx.send(new_data).is_err() {
                  return Ok(());
              };
            }
        }
    }
}
