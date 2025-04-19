//! Common types and error definitions for the wallet module.

use serde::{Deserialize, Serialize};
use secrecy::Secret;
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
#[derive(Serialize, Deserialize, Clone)]
pub struct AddressInfo {
    pub public_key: String,
    #[serde(with = "serde_secret")]
    pub private_key: Secret<String>,
    #[serde(with = "serde_optional_secret")]
    pub mnemonic: Option<Secret<String>>,
    pub path: Option<String>,
    pub label: String,
    pub address_type: String, // Address type (p2pkh, p2wpkh/bech32)
}

// Serialization helpers for Secret<String>
mod serde_secret {
    use serde::{Deserialize, Deserializer, Serialize, Serializer};
    use secrecy::{Secret, ExposeSecret};
    
    pub fn serialize<S>(secret: &Secret<String>, serializer: S) -> Result<S::Ok, S::Error>
    where
        S: Serializer,
    {
        secret.expose_secret().serialize(serializer)
    }
    
    pub fn deserialize<'de, D>(deserializer: D) -> Result<Secret<String>, D::Error>
    where
        D: Deserializer<'de>,
    {
        let s = String::deserialize(deserializer)?;
        Ok(Secret::new(s))
    }
}

// Serialization helpers for Option<Secret<String>>
mod serde_optional_secret {
    use serde::{Deserialize, Deserializer, Serialize, Serializer};
    use secrecy::{Secret, ExposeSecret};
    
    pub fn serialize<S>(secret: &Option<Secret<String>>, serializer: S) -> Result<S::Ok, S::Error>
    where
        S: Serializer,
    {
        match secret {
            Some(s) => Some(s.expose_secret().as_str()).serialize(serializer),
            None => None::<String>.serialize(serializer),
        }
    }
    
    pub fn deserialize<'de, D>(deserializer: D) -> Result<Option<Secret<String>>, D::Error>
    where
        D: Deserializer<'de>,
    {
        let opt_s: Option<String> = Option::deserialize(deserializer)?;
        Ok(opt_s.map(Secret::new))
    }
}

// Override Debug implementation to protect sensitive data
impl std::fmt::Debug for AddressInfo {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        f.debug_struct("AddressInfo")
            .field("public_key", &self.public_key)
            .field("private_key", &"[REDACTED]")
            .field("mnemonic", &self.mnemonic.as_ref().map(|_| "[REDACTED]"))
            .field("path", &self.path)
            .field("label", &self.label)
            .field("address_type", &self.address_type)
            .finish()
    }
}

/// Address collection type
pub type AddressMap = HashMap<String, AddressInfo>;
