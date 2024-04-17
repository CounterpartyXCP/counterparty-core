use std::thread::JoinHandle;

use crate::indexer::types::{error::Error, pipeline::Stopper};

pub fn new(
    handles: &mut Vec<JoinHandle<Result<(), Error>>>,
    stopper: Stopper,
) -> Result<(), Error> {
    if stopper.stopped() {
        return Err(Error::Stopped);
    }
    stopper.stop()?;
    for handle in handles.drain(..) {
        handle.join().map_err(|e| {
            Error::GracefulExitFailure(if let Some(s) = e.downcast_ref::<String>() {
                s.to_owned()
            } else if let Some(&s) = e.downcast_ref::<&str>() {
                s.into()
            } else {
                "unknown error".to_string()
            })
        })??;
    }
    Ok(())
}
