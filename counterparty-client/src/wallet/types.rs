//! Common types and error definitions for the wallet module.

use serde::{Deserialize, Serialize};
use std::collections::HashMap;
use thiserror::Error;

/// Error types that can occur in wallet operations
#[derive(Error, Debug)]
pub enum WalletError {
    #[error("IO error: {0}")]
    IoError(#[from] std::io::Error),

    #[error("JSON error: {0}")]
    JsonError(#[from] serde_json::Error),

    #[error("Encryption error: {0}")]
    CocoonError(String),

    #[error("Bitcoin error: {0}")]
    BitcoinError(String),

    #[error("BIP39 error: {0}")]
    Bip39Error(String),

    #[error("Address not found: {0}")]
    AddressNotFound(String),
}

/// Type alias for our result type
pub type Result<T> = std::result::Result<T, WalletError>;

/// Structure to hold wallet address information
#[derive(Serialize, Deserialize, Clone, Debug)]
pub struct AddressInfo {
    pub public_key: String,
    pub private_key: String,
    pub mnemonic: Option<String>,
    pub path: Option<String>,
    pub label: String,
    pub address_type: String, // Address type (p2pkh, p2wpkh/bech32)
}

/// Address collection type
pub type AddressMap = HashMap<String, AddressInfo>;
