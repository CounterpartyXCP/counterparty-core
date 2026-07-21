//! Common types and error definitions for the wallet module.

use secrecy::SecretString;
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

    #[error("Keyring error: {0}")]
    KeyringError(String),

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
    pub private_key: SecretString,
    pub label: String,
    pub address_type: String, // Address type (p2pkh, p2wpkh/bech32)
}

// Serialization helpers for SecretString
mod serde_secret {
    use secrecy::{ExposeSecret, SecretString};
    use serde::{Deserialize, Deserializer, Serialize, Serializer};

    pub fn serialize<S>(secret: &SecretString, serializer: S) -> Result<S::Ok, S::Error>
    where
        S: Serializer,
    {
        secret.expose_secret().serialize(serializer)
    }

    pub fn deserialize<'de, D>(deserializer: D) -> Result<SecretString, D::Error>
    where
        D: Deserializer<'de>,
    {
        let s = String::deserialize(deserializer)?;
        Ok(SecretString::from(s))
    }
}

// Override Debug implementation to protect sensitive data
impl std::fmt::Debug for AddressInfo {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        f.debug_struct("AddressInfo")
            .field("public_key", &self.public_key)
            .field("private_key", &"[REDACTED]")
            .field("label", &self.label)
            .field("address_type", &self.address_type)
            .finish()
    }
}

/// Address collection type
pub type AddressMap = HashMap<String, AddressInfo>;

#[cfg(test)]
mod tests {
    use super::*;
    use secrecy::ExposeSecret;

    fn sample() -> AddressInfo {
        AddressInfo {
            public_key: "02aabb".to_string(),
            private_key: SecretString::from("cWifSecretValue".to_string()),
            label: "primary".to_string(),
            address_type: "bech32".to_string(),
        }
    }

    #[test]
    fn debug_redacts_private_key() {
        let dbg = format!("{:?}", sample());
        assert!(dbg.contains("[REDACTED]"), "debug output: {dbg}");
        assert!(!dbg.contains("cWifSecretValue"), "secret leaked: {dbg}");
        // Non-secret fields are still shown.
        assert!(dbg.contains("primary"));
    }

    #[test]
    fn serde_roundtrip_preserves_all_fields_including_secret() {
        let json = serde_json::to_string(&sample()).unwrap();
        // The WIF is serialized in clear (the file as a whole is encrypted at rest).
        assert!(json.contains("cWifSecretValue"));

        let back: AddressInfo = serde_json::from_str(&json).unwrap();
        assert_eq!(back.public_key, "02aabb");
        assert_eq!(back.label, "primary");
        assert_eq!(back.address_type, "bech32");
        assert_eq!(back.private_key.expose_secret(), "cWifSecretValue");
    }

    #[test]
    fn wallet_error_display_messages() {
        // The user-facing Display strings are part of the CLI's error UX.
        assert_eq!(
            WalletError::AddressNotFound("bcrt1qx".to_string()).to_string(),
            "Address not found: bcrt1qx"
        );
        assert_eq!(
            WalletError::BitcoinError("boom".to_string()).to_string(),
            "Bitcoin error: boom"
        );
        assert_eq!(
            WalletError::KeyringError("no service".to_string()).to_string(),
            "Keyring error: no service"
        );
    }
}
