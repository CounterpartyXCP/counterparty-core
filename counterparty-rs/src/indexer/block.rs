use serde::Serialize;

#[derive(Serialize)]
pub struct Vin {
    pub hash: String, // prev output txid
    pub n: u32,       // prev output index
    pub sequence: u32,
    pub script_sig: String,
}

#[derive(Serialize)]
pub struct Vout {
    pub value: u64,
    pub script_pub_key: String,
}

#[derive(Serialize)]
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

#[derive(Serialize)]
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

pub trait ToSerializedBlock {
    fn to_serialized_block(&self, height: u32) -> Vec<u8>;
}
