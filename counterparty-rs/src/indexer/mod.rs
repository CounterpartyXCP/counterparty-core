#![warn(clippy::unwrap_used, clippy::expect_used, clippy::panic)]

mod bitcoin_client;
mod config;
mod constants;
mod database;
mod handlers;
mod logging;
#[cfg(test)]
mod test_utils;
mod types;
mod utils;
mod workers;

use std::thread::JoinHandle;

use bitcoincore_rpc::bitcoin::Block;
use crossbeam_channel::{Receiver, Sender};
use pyo3::prelude::*;

use self::{
    bitcoin_client::BitcoinClient,
    config::Config,
    database::Database,
    handlers::{new, start, stop},
    types::{error::Error, pipeline::Stopper},
};

#[pyclass]
pub struct Indexer {
    pub config: Config,
    pub parallelism: usize,
    stopper: Stopper,
    client: BitcoinClient,
    db: Database,
    chan: (Sender<Box<Block>>, Receiver<Box<Block>>),
    handles: Vec<JoinHandle<Result<(), Error>>>,
}

#[pymethods]
impl Indexer {
    #[new]
    pub fn new(config: Config) -> PyResult<Self> {
        Ok(new::new(config)?)
    }

    pub fn start(&mut self) -> PyResult<()> {
        self.handles.append(&mut start::new(
            self.parallelism,
            self.config.clone(),
            self.client.clone(),
            self.stopper.clone(),
            self.chan.clone(),
            self.db.clone(),
        )?);
        Ok(())
    }

    pub fn stop(&mut self) -> PyResult<()> {
        Ok(stop::new(&mut self.handles, self.stopper.clone())?)
    }

    pub fn query(&self) -> PyResult<()> {
        todo!()
    }
}

pub fn create_indexer_module(py: Python) -> PyResult<&'_ PyModule> {
    let m = PyModule::new(py, "indexer")?;
    m.add_class::<Indexer>()?;
    Ok(m)
}
