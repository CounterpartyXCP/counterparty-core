#![warn(clippy::unwrap_used, clippy::expect_used, clippy::panic)]

mod bitcoin_client;
mod block;
mod config;
mod constants;
mod database;
mod handlers;
mod logging;
mod stopper;
#[cfg(test)]
mod test_utils;
mod types;
mod utils;
mod workers;

use std::thread::JoinHandle;

use pyo3::prelude::*;
use types::pipeline::ChanOut;

use self::{
    bitcoin_client::BitcoinClient,
    config::Config,
    database::Database,
    handlers::{get_block, new, start, stop},
    stopper::Stopper,
    types::error::Error,
};

#[pyclass]
pub struct Indexer {
    pub config: Config,
    pub parallelism: usize,
    stopper: Stopper,
    client: BitcoinClient,
    db: Database,
    chan: ChanOut,
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
        Ok(stop::new(
            &mut self.handles,
            self.config.clone(),
            self.stopper.clone(),
            self.chan.clone(),
        )?)
    }

    pub fn get_block(&self, py: Python<'_>) -> PyResult<PyObject> {
        let block =
            py.allow_threads(|| get_block::new(self.stopper.clone(), self.chan.1.clone()))?;
        Ok(block.into_py(py))
    }

    pub fn get_block_non_blocking(&self, py: Python<'_>) -> PyResult<PyObject> {
        let block = get_block::new_non_blocking(self.stopper.clone(), self.chan.1.clone())?;
        Ok(block.map(|b| b.into_py(py)).into_py(py))
    }

    pub fn get_version(&self) -> PyResult<String> {
        Ok(env!("CARGO_PKG_VERSION").to_string())
    }
}


#[pyclass]
pub struct Deserializer {
    pub config: Config,
}

#[pymethods]
impl Deserializer {
    #[new]
    pub fn new(config: Config) -> PyResult<Self> {
        Ok(Deserializer { config })
    }

    pub fn parse(&self, tx_hex: &str, height: u32, parse_vouts: bool, py: Python<'_>) -> PyResult<PyObject> {
        let transaction = self::bitcoin_client::parse_transaction(tx_hex, &self.config, height, parse_vouts);
        Ok(transaction.into_py(py))
    }
}

pub fn register_indexer_module(parent_module: &Bound<'_, PyModule>) -> PyResult<()> {
    let m = PyModule::new_bound(parent_module.py(), "indexer")?;
    m.add_class::<Indexer>()?;
    m.add_class::<Deserializer>()?;
    parent_module.add_submodule(&m)?;
    Ok(())
}
