use std::thread::JoinHandle;

use crossbeam_channel::unbounded;
use tracing::debug;

use crate::indexer::{
    config::Config,
    stopper::Stopper,
    types::{error::Error, pipeline::ChanOut},
    workers::{consumer, new_worker_pool},
};

pub fn new(
    handles: &mut Vec<JoinHandle<Result<(), Error>>>,
    config: Config,
    stopper: Stopper,
    chan: ChanOut,
) -> Result<(), Error> {
    if stopper.stopped()? {
        return Err(Error::Stopped);
    }

    debug!("Stopping...");
    let mut consumer_handle = None;
    let consumer_stopper = Stopper::new();
    let (tx, _) = unbounded::<()>();
    if !config.consume_blocks {
        let mut handles = new_worker_pool(
            "Consumer".into(),
            1,
            chan.1,
            tx,
            consumer_stopper.clone(),
            consumer::new(),
        )?;
        consumer_handle = Some(handles.remove(0));
    }

    stopper.stop()?;
    for handle in handles.drain(..) {
        if let Err(e) = handle.join() {
            let error_message = if let Some(s) = e.downcast_ref::<String>() {
                s.clone()
            } else if let Some(&s) = e.downcast_ref::<&str>() {
                s.into()
            } else {
                "unknown error".to_string()
            };

            return Err(Error::GracefulExitFailure(error_message));
        }
    }

    if let Some(handle) = consumer_handle {
        consumer_stopper.stop()?;
        handle.join().ok();
    }

    debug!("Stopped.");
    Ok(())
}
