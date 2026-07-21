use super::config::Config;
use pyo3::{
    exceptions::PyException,
    prelude::*,
    types::{PyAny, PyBytes, PyDict},
};

#[derive(Clone)]
pub struct VinOutput {
    pub script_pub_key: Vec<u8>,
    pub value: u64,
    pub is_segwit: bool,
}

#[derive(Clone)]
pub struct Vin {
    pub hash: String, // prev output txid
    pub n: u32,       // prev output index
    pub sequence: u32,
    pub script_sig: Vec<u8>,
    pub info: Option<VinOutput>,
}

impl<'py> IntoPyObject<'py> for Vin {
    type Target = PyAny;
    type Output = Bound<'py, PyAny>;
    type Error = PyErr;

    fn into_pyobject(self, py: Python<'py>) -> Result<Self::Output, Self::Error> {
        let dict = PyDict::new(py);
        dict.set_item("hash", self.hash)?;
        dict.set_item("n", self.n)?;
        dict.set_item("sequence", self.sequence)?;
        dict.set_item("script_sig", PyBytes::new(py, &self.script_sig))?;

        if let Some(info) = self.info {
            let info_dict = PyDict::new(py);
            info_dict.set_item("script_pub_key", PyBytes::new(py, &info.script_pub_key))?;
            info_dict.set_item("value", info.value)?;
            info_dict.set_item("is_segwit", info.is_segwit)?;
            dict.set_item("info", info_dict)?;
        } else {
            dict.set_item("info", py.None())?;
        }

        Ok(dict.into_any())
    }
}

#[derive(Clone)]
pub struct Vout {
    pub value: u64,
    pub script_pub_key: Vec<u8>,
    //pub is_segwit: bool,
}

impl<'py> IntoPyObject<'py> for Vout {
    type Target = PyAny;
    type Output = Bound<'py, PyAny>;
    type Error = PyErr;

    fn into_pyobject(self, py: Python<'py>) -> Result<Self::Output, Self::Error> {
        let dict = PyDict::new(py);
        dict.set_item("value", self.value)?;
        dict.set_item("script_pub_key", PyBytes::new(py, &self.script_pub_key))?;
        //dict.set_item("is_segwit", self.is_segwit)?;
        Ok(dict.into_any())
    }
}

#[derive(Clone)]
pub struct PotentialDispenser {
    pub destination: Option<String>,
    pub value: Option<u64>,
}

impl<'py> IntoPyObject<'py> for PotentialDispenser {
    type Target = PyAny;
    type Output = Bound<'py, PyAny>;
    type Error = PyErr;

    fn into_pyobject(self, py: Python<'py>) -> Result<Self::Output, Self::Error> {
        (self.destination, self.value)
            .into_pyobject(py)
            .map(|t| t.into_any())
    }
}

#[derive(Clone)]
pub struct ParsedVouts {
    pub destinations: Vec<String>,
    pub btc_amount: i64,
    pub fee: i64,
    pub data: Vec<u8>,
    pub potential_dispensers: Vec<Option<PotentialDispenser>>,
    pub is_reveal_tx: bool,
}

impl<'py> IntoPyObject<'py> for ParsedVouts {
    type Target = PyAny;
    type Output = Bound<'py, PyAny>;
    type Error = PyErr;

    fn into_pyobject(self, py: Python<'py>) -> Result<Self::Output, Self::Error> {
        (
            self.destinations,
            self.btc_amount,
            self.fee,
            PyBytes::new(py, &self.data),
            self.potential_dispensers,
            self.is_reveal_tx,
        )
            .into_pyobject(py)
            .map(|t| t.into_any())
    }
}

#[derive(Clone)]
pub struct Transaction {
    pub version: i32,
    pub segwit: bool,
    pub coinbase: bool,
    pub lock_time: u32,
    pub tx_id: String,
    pub tx_hash: String,
    pub vtxinwit: Vec<Vec<String>>,
    pub parsed_vouts: Result<ParsedVouts, String>,
    pub vin: Vec<Vin>,
    pub vout: Vec<Vout>,
}

impl<'py> IntoPyObject<'py> for Transaction {
    type Target = PyAny;
    type Output = Bound<'py, PyAny>;
    type Error = PyErr;

    fn into_pyobject(self, py: Python<'py>) -> Result<Self::Output, Self::Error> {
        let dict = PyDict::new(py);
        dict.set_item("version", self.version)?;
        dict.set_item("segwit", self.segwit)?;
        dict.set_item("coinbase", self.coinbase)?;
        dict.set_item("lock_time", self.lock_time)?;
        dict.set_item("tx_id", self.tx_id)?;
        dict.set_item("tx_hash", self.tx_hash)?;
        dict.set_item("vtxinwit", self.vtxinwit)?;

        match self.parsed_vouts {
            Ok(parsed_vouts) => {
                dict.set_item("parsed_vouts", parsed_vouts)?;
            }
            Err(error) => {
                let exception = PyException::new_err(error);
                dict.set_item("parsed_vouts", exception.value(py))?;
            }
        }

        dict.set_item("vin", self.vin)?;
        dict.set_item("vout", self.vout)?;

        Ok(dict.into_any())
    }
}

#[derive(Clone)]
pub struct Block {
    pub height: u32,
    pub version: i32,
    pub hash_prev: String,
    pub hash_merkle_root: String,
    pub block_time: u32,
    pub bits: u32,
    pub nonce: u32,
    pub block_hash: String,
    pub transaction_count: usize,
    pub transactions: Vec<Transaction>,
}

impl<'py> IntoPyObject<'py> for Block {
    type Target = PyAny;
    type Output = Bound<'py, PyAny>;
    type Error = PyErr;

    fn into_pyobject(self, py: Python<'py>) -> Result<Self::Output, Self::Error> {
        let dict = PyDict::new(py);
        dict.set_item("height", self.height)?;
        dict.set_item("block_index", self.height)?;
        dict.set_item("version", self.version)?;
        dict.set_item("hash_prev", self.hash_prev)?;
        dict.set_item("hash_merkle_root", self.hash_merkle_root)?;
        dict.set_item("block_time", self.block_time)?;
        dict.set_item("bits", self.bits)?;
        dict.set_item("nonce", self.nonce)?;
        dict.set_item("block_hash", self.block_hash)?;
        dict.set_item("transaction_count", self.transaction_count)?;
        dict.set_item("transactions", self.transactions)?;

        Ok(dict.into_any())
    }
}

pub trait ToBlock {
    fn to_block(&self, config: Config, height: u32) -> Block;
}
