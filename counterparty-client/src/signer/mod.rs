// Module for Bitcoin transaction signing
//
// This module provides functionality for signing Bitcoin transactions
// with various address types including P2PKH, P2WPKH, P2SH-P2WPKH, P2TR and P2WSH.

mod address;
mod signature;
mod verification;
mod taproot;
mod psbt;
mod transaction;
mod utils;
mod types;

// Re-export public API
pub use transaction::{sign_transaction, sign_reveal_transaction};