use crossbeam_channel::{Receiver, RecvTimeoutError, Sender};
use std::time::Duration;

use crate::indexer::{
    database::DatabaseOps,
    stopper::Stopper,
    types::{
        entry::ToEntry,
        error::Error,
        pipeline::{HasHeight, PipelineDataBatch, Transition},
    },
    utils::in_reorg_window,
};

pub fn new<T, U, D>(
    db: D,
    start_height: u32,
    reorg_window: u32,
    max_num_entries: usize,
) -> impl FnMut(Receiver<Box<T>>, Sender<Box<PipelineDataBatch<U>>>, Stopper) -> Result<(), Error> + Clone
where
    T: HasHeight + Transition<Box<U>, (), Vec<Box<dyn ToEntry>>>,
    D: DatabaseOps,
{
    move |rx, tx, stopper| {
        let (_, done) = stopper.subscribe()?;
        loop {
            if done.try_recv().is_ok() {
                return Ok(());
            }
            let mut entries = Vec::new();
            let mut batch = Vec::new();
            let mut height = start_height - 1;
            let mut target_height = start_height;

            while entries.len() < max_num_entries {
                match rx.recv_timeout(Duration::from_secs(1)) {
                    Ok(data) => {
                        height = data.get_height();
                        target_height = data.get_target_height();
                        let (mut new_entries, data_out) = data.transition(())?;
                        entries.append(&mut new_entries);
                        batch.push(data_out);
                    }
                    Err(RecvTimeoutError::Timeout) => break,
                    Err(RecvTimeoutError::Disconnected) => return Ok(()),
                }
            }

            if !batch.is_empty() {
                let num_entries = entries.len();
                db.write_batch(|batch| {
                    db.put_entries(
                        batch,
                        if in_reorg_window(height, target_height, reorg_window) {
                            Some(height - reorg_window)
                        } else {
                            None
                        },
                        &entries,
                    )?;
                    db.put_max_block_height(batch, height)
                })?;

                let pipeline_batch = PipelineDataBatch { batch, num_entries };
                if tx.send(Box::new(pipeline_batch)).is_err() {
                    return Ok(());
                }
            }
        }
    }
}
