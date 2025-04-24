// Module for Bitcoin transaction signing
//
// This module provides functionality for signing Bitcoin transactions
// using various address types (P2PKH, P2WPKH, P2SH, P2WSH, P2TR)

pub mod common;
pub mod p2pkh;
pub mod p2sh;
pub mod p2trkps;
pub mod p2trsps;
pub mod p2wpkh;
pub mod p2wsh;
pub mod psbt;
pub mod transaction;
pub mod types;

// Re-export the main API functions and types
pub use transaction::sign_transaction;
pub use types::{UTXOList, UTXO};
