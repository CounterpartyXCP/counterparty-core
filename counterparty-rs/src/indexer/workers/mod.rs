use std::thread::{self, JoinHandle};

use crossbeam_channel::{Receiver, Sender};
use tracing::{error, info};

use super::types::{
    error::Error,
    pipeline::{Done, Stopper},
};

pub mod consumer;
pub mod extractor;
pub mod fetcher;
pub mod orderer;
pub mod producer;
pub mod reporter;
pub mod writer;

pub fn new_worker_pool<R, T, F>(
    name: String,
    n: usize,
    rx: Receiver<R>,
    tx: Sender<T>,
    stopper: Stopper,
    f: F,
) -> Result<Vec<JoinHandle<Result<(), Error>>>, Error>
where
    R: Send + 'static,
    T: Send + 'static,
    F: FnMut(Receiver<R>, Sender<T>, Done) -> Result<(), Error> + Clone + Send + 'static,
{
    let mut handles = Vec::new();
    for i in 0..n {
        let rx = rx.clone();
        let tx = tx.clone();
        let mut f = f.clone();
        let stopper = stopper.clone();
        let (_, done) = stopper.subscribe()?;
        let name = name.clone();

        handles.push(thread::spawn(move || {
            if let Err(e) = f(rx, tx, done) {
                error!("{}-{} worker exited with error: {}", name, i, e);
                stopper.stop()?;
                return Err(e);
            }

            info!("{}-{} worker exited", name, i);
            Ok(())
        }));
    }

    info!("{} {} workers started", n, name);
    Ok(handles)
}
