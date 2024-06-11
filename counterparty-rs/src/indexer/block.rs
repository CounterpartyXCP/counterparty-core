use pyo3::{
    types::{PyAnyMethods, PyBytes, PyDict},
    IntoPy, PyObject, Python,
};

#[derive(Clone)]
pub struct Vin {
    pub hash: String, // prev output txid
    pub n: u32,       // prev output index
    pub sequence: u32,
    pub script_sig: Vec<u8>,
}

impl IntoPy<PyObject> for Vin {
    #[allow(clippy::unwrap_used)]
    fn into_py(self, py: Python<'_>) -> PyObject {
        let dict = PyDict::new_bound(py);
        dict.set_item("hash", self.hash).unwrap();
        dict.set_item("n", self.n).unwrap();
        dict.set_item("sequence", self.sequence).unwrap();
        dict.set_item("script_sig", PyBytes::new_bound(py, &self.script_sig))
            .unwrap();
        dict.unbind().into()
    }
}

#[derive(Clone)]
pub struct Vout {
    pub value: u64,
    pub script_pub_key: Vec<u8>,
}

impl IntoPy<PyObject> for Vout {
    #[allow(clippy::unwrap_used)]
    fn into_py(self, py: Python<'_>) -> PyObject {
        let dict = PyDict::new_bound(py);
        dict.set_item("value", self.value).unwrap();
        dict.set_item(
            "script_pub_key",
            PyBytes::new_bound(py, &self.script_pub_key),
        )
        .unwrap();
        dict.unbind().into()
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
    pub vtxinwit: Vec<String>,
    pub vin: Vec<Vin>,
    pub vout: Vec<Vout>,
}

impl IntoPy<PyObject> for Transaction {
    #[allow(clippy::unwrap_used)]
    fn into_py(self, py: Python<'_>) -> PyObject {
        let dict = PyDict::new_bound(py);
        dict.set_item("version", self.version).unwrap();
        dict.set_item("segwit", self.segwit).unwrap();
        dict.set_item("coinbase", self.coinbase).unwrap();
        dict.set_item("lock_time", self.lock_time).unwrap();
        dict.set_item("tx_id", self.tx_id).unwrap();
        dict.set_item("tx_hash", self.tx_hash).unwrap();
        dict.set_item("vtxinwit", self.vtxinwit).unwrap();

        let vin_list: Vec<PyObject> = self.vin.into_iter().map(|vin| vin.into_py(py)).collect();
        dict.set_item("vin", vin_list).unwrap();

        let vout_list: Vec<PyObject> = self.vout.into_iter().map(|vout| vout.into_py(py)).collect();
        dict.set_item("vout", vout_list).unwrap();

        dict.unbind().into()
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

impl IntoPy<PyObject> for Block {
    #[allow(clippy::unwrap_used)]
    fn into_py(self, py: Python<'_>) -> PyObject {
        let dict = PyDict::new_bound(py);
        dict.set_item("height", self.height).unwrap();
        dict.set_item("version", self.version).unwrap();
        dict.set_item("hash_prev", self.hash_prev).unwrap();
        dict.set_item("hash_merkle_root", self.hash_merkle_root)
            .unwrap();
        dict.set_item("block_time", self.block_time).unwrap();
        dict.set_item("bits", self.bits).unwrap();
        dict.set_item("nonce", self.nonce).unwrap();
        dict.set_item("block_hash", self.block_hash).unwrap();
        dict.set_item("transaction_count", self.transaction_count)
            .unwrap();

        let transactions_list: Vec<PyObject> = self
            .transactions
            .into_iter()
            .map(|tx| tx.into_py(py))
            .collect();
        dict.set_item("transactions", transactions_list).unwrap();

        dict.unbind().into()
    }
}

pub trait ToBlock {
    fn to_block(&self, height: u32) -> Block;
}
