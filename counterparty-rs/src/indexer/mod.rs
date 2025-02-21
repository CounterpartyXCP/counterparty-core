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
mod rpc_client;

use std::thread::JoinHandle;

use bitcoin;
use bitcoin::consensus::deserialize;
use bitcoin::{blockdata::transaction::Transaction, Block};

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

    pub fn parse_transaction(
        &self,
        tx_hex: &str,
        height: u32,
        parse_vouts: bool,
        py: Python<'_>,
    ) -> PyResult<PyObject> {
        let decoded_tx = hex::decode(tx_hex).map_err(|_| PyErr::new::<pyo3::exceptions::PyValueError, _>("Failed to decode hex transaction"))?;
        let transaction: Transaction =
            deserialize(&decoded_tx).map_err(|_| PyErr::new::<pyo3::exceptions::PyValueError, _>("Failed to deserialize transaction"))?;

        let deserialized_transaction = self::bitcoin_client::parse_transaction(
            &transaction,
            &self.config,
            height,
            parse_vouts,
        );
        return Ok(deserialized_transaction.into_py(py));
    }

    pub fn parse_block(
        &self,
        block_hex: &str,
        height: u32,
        parse_vouts: bool,
        py: Python<'_>,
    ) -> PyResult<PyObject> {
        let decoded_block = hex::decode(block_hex).map_err(|_| PyErr::new::<pyo3::exceptions::PyValueError, _>("Failed to decode hex block"))?;
        let block: Block = deserialize(&decoded_block).map_err(|_| PyErr::new::<pyo3::exceptions::PyValueError, _>("Failed to deserialize transaction"))?;

        let deserialized_block =
            self::bitcoin_client::parse_block(block, &self.config, height, parse_vouts);
        return Ok(deserialized_block?.into_py(py));
    }
}

pub fn register_indexer_module(parent_module: &Bound<'_, PyModule>) -> PyResult<()> {
    let m = PyModule::new_bound(parent_module.py(), "indexer")?;
    m.add_class::<Indexer>()?;
    m.add_class::<Deserializer>()?;
    parent_module.add_submodule(&m)?;
    Ok(())
}
