//! Module for Bitcoin transaction signing
//!
//! This module provides functionality for signing Bitcoin transactions
//! using various address types (P2PKH, P2WPKH, P2SH, P2WSH, P2TR)

pub mod common;
// The per-script-type signers are crate-internal: the ECDSA scriptPubKey-
// reconstruction guard lives in `transaction::sign_transaction` (the only public
// entry point), so exposing the individual signers would let an external caller
// sign an input without that check. Keep them `pub(crate)`.
pub(crate) mod p2pkh;
pub(crate) mod p2sh;
pub(crate) mod p2trkps;
pub(crate) mod p2trsps;
pub(crate) mod p2wpkh;
pub(crate) mod p2wsh;
pub mod psbt;
pub mod transaction;
pub mod types;

#[cfg(test)]
mod tests;

// Re-export the main API functions and types
pub use transaction::sign_transaction;
pub use types::{UTXOList, UTXOType, UTXO};
