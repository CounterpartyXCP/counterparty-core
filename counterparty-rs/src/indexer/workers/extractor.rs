use crossbeam_channel::{select, Receiver, Sender};

use crate::indexer::types::{
    error::Error,
    pipeline::{BlockHasEntries, Done, HasBlock},
};

pub fn new<T, U, S, B>(
) -> impl Fn(Receiver<Box<T>>, Sender<Box<U>>, Done) -> Result<(), Error> + Clone
where
    T: HasBlock<B, U, S>,
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
              let new_data = data.with_entries();
              if tx.send(new_data).is_err() {
                  return Ok(());
              };
            }
        }
    }
}
