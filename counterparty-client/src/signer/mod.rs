// Module for Bitcoin transaction signing
//
// This module provides functionality for signing Bitcoin transactions
// with various address types including P2PKH, P2WPKH, P2SH-P2WPKH, P2TR and P2WSH.

mod address;
mod psbt;
mod signature;
mod taproot;
mod transaction;
mod types;
mod utils;
mod verification;

// Re-export public API
pub use transaction::{sign_reveal_transaction, sign_transaction};
