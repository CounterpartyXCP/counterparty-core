// Module for Bitcoin transaction signing
//
// This module provides functionality for signing Bitcoin transactions
// using various address types (P2PKH, P2WPKH, P2SH, P2WSH, P2TR)

pub mod types;
pub mod utils;
pub mod p2pkh;
pub mod p2wpkh;
pub mod p2sh;
pub mod p2wsh;
pub mod p2trkps;
pub mod p2trsps;
pub mod psbt;
pub mod transaction;

// Re-export the main API functions
pub use transaction::sign_transaction;
pub use transaction::sign_transaction_legacy;
pub use types::{UTXO, UTXOList, UTXOType};
