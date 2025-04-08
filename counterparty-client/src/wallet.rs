// Bitcoin Wallet Module
// A simple module to manage Bitcoin addresses, keys and mnemonics.
// This module uses Cocoon for encryption and Bitcoin libraries for key management.

use std::collections::HashMap;
use std::fs::{self, File};
use std::io::{Read, Write};
use std::path::{Path, PathBuf};

use bitcoin::secp256k1::Secp256k1;
use bitcoin::Network;
use cocoon::Cocoon;
use rand::distributions::Alphanumeric;
use rand::{thread_rng, Rng};
use serde::{Deserialize, Serialize};
use serde_json::{self, json, Value};
use thiserror::Error;

use crate::signer;
use crate::keys;
use crate::config;

// Error types that can occur in wallet operations
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

// Type alias for our result type
type Result<T> = std::result::Result<T, WalletError>;

// Structure to hold wallet address information
#[derive(Serialize, Deserialize, Clone, Debug)]
pub struct AddressInfo {
    pub public_key: String,
    pub private_key: String,
    pub mnemonic: Option<String>,
    pub path: Option<String>,
    pub label: String,
    pub address_type: String, // Address type (p2pkh, p2wpkh/bech32)
}

// Main wallet structure
#[derive(Debug)]
pub struct BitcoinWallet {
    wallet_file: PathBuf,
    password: String,
    addresses: HashMap<String, AddressInfo>,
    network: bitcoin::Network, // Bitcoin network type
}

impl BitcoinWallet {
    /// Initialize a new Bitcoin wallet
    ///
    /// This creates a new wallet or loads an existing one from the specified data directory.
    /// If the wallet doesn't exist, it generates a random password and stores it in a .cookie file.
    ///
    /// # Arguments
    ///
    /// * `data_dir` - Directory where wallet data will be stored
    /// * `network` - Bitcoin network to use (mainnet, testnet, regtest)
    ///
    /// # Returns
    ///
    /// * `Result<BitcoinWallet>` - New wallet instance or error
    pub fn init<P: AsRef<Path>>(data_dir: P, network: config::Network) -> Result<Self> {
        let data_dir = data_dir.as_ref().to_path_buf();

        // Create network-specific subdirectory
        let network_dir = match network {
            config::Network::Mainnet => data_dir.join("mainnet"),
            config::Network::Testnet4 => data_dir.join("testnet4"),
            config::Network::Regtest => data_dir.join("regtest"),
        };

        // Convert config::Network to bitcoin::Network
        let bitcoin_network = match network {
            config::Network::Mainnet => bitcoin::Network::Bitcoin,
            config::Network::Testnet4 => bitcoin::Network::Testnet,
            config::Network::Regtest => bitcoin::Network::Regtest,
        };

        // Create the data directory if it doesn't exist
        fs::create_dir_all(&network_dir)?;

        let wallet_file = network_dir.join("wallet.db");
        let cookie_file = network_dir.join(".cookie");

        // Get or create password
        let password = if cookie_file.exists() {
            // Read existing password from cookie file
            let mut password_buf = String::new();
            File::open(&cookie_file)?.read_to_string(&mut password_buf)?;
            password_buf
        } else {
            // Generate new random password
            let new_password: String = thread_rng()
                .sample_iter(&Alphanumeric)
                .take(32)
                .map(char::from)
                .collect();

            // Write password to cookie file
            let mut file = File::create(&cookie_file)?;
            file.write_all(new_password.as_bytes())?;

            new_password
        };

        // Initialize or load addresses
        let addresses = if wallet_file.exists() {
            // Check if prefix file exists
            let prefix_file = wallet_file.with_extension("prefix");
            if !prefix_file.exists() {
                return Err(WalletError::BitcoinError(
                    "Prefix file not found".to_string(),
                ));
            }

            // Read prefix and encrypted data
            let prefix = fs::read(&prefix_file)?;
            let mut encrypted_data = fs::read(&wallet_file)?;

            // Create a new Cocoon and decrypt
            let cocoon = Cocoon::new(password.as_bytes());
            cocoon.decrypt(&mut encrypted_data, &prefix).map_err(|e| {
                WalletError::CocoonError(format!("Failed to decrypt wallet: {:?}", e))
            })?;

            // Convert to UTF-8 string and parse JSON
            let json_data = String::from_utf8(encrypted_data).map_err(|_| {
                WalletError::BitcoinError("Invalid UTF-8 in wallet file".to_string())
            })?;

            serde_json::from_str(&json_data)?
        } else {
            HashMap::new()
        };

        Ok(BitcoinWallet {
            wallet_file,
            password,
            addresses,
            network: bitcoin_network,
        })
    }

    /// Saves the wallet to the encrypted file
    fn save(&self) -> Result<()> {
        let json_data = serde_json::to_string(&self.addresses)?;
        let mut cocoon = Cocoon::new(self.password.as_bytes());

        // Convert data to mutable vector
        let mut data = json_data.into_bytes();

        // Encrypt data in place and get the prefix
        let prefix = cocoon
            .encrypt(&mut data)
            .map_err(|e| WalletError::CocoonError(format!("Failed to encrypt wallet: {:?}", e)))?;

        // Save encrypted data
        fs::write(&self.wallet_file, &data)?;

        // Save prefix in a separate file
        let prefix_file = self.wallet_file.with_extension("prefix");
        fs::write(&prefix_file, prefix)?;

        Ok(())
    }

    /// Add a new address to the wallet
    ///
    /// # Arguments
    ///
    /// * `private_key` - Optional private key as string
    /// * `mnemonic` - Optional mnemonic phrase
    /// * `path` - Optional derivation path
    /// * `label` - Optional label for the address
    /// * `address_type` - Optional address type ("bech32" or "p2pkh")
    ///
    /// # Returns
    ///
    /// * `Result<String>` - The Bitcoin address created or error
    pub fn add_address(
        &mut self,
        private_key: Option<&str>,
        mnemonic: Option<&str>,
        path: Option<&str>,
        label: Option<&str>,
        address_type: Option<&str>,
    ) -> Result<String> {
        let secp = Secp256k1::new();

        // Determine address type (bech32/p2wpkh by default)
        let addr_type = match address_type {
            Some("p2pkh") => "p2pkh",
            _ => "bech32", // By default, we use bech32
        };

        // Generate keys based on provided parameters
        let key_data = match (private_key, mnemonic) {
            (Some(pk_str), _) => keys::generate_keys_from_private_key(pk_str, self.network, &secp)?,
            (None, Some(mnemonic_str)) => keys::generate_keys_from_mnemonic(mnemonic_str, path, addr_type, self.network, &secp)?,
            (None, None) => keys::generate_new_keys(addr_type, self.network, &secp)?,
        };

        // Generate Bitcoin address
        let address = keys::create_bitcoin_address(&key_data.public_key, addr_type, self.network)?;
        let address_str = address.to_string();

        // Create the label
        let final_label = match label {
            Some(l) => l.to_string(),
            None => format!("Address {}", self.addresses.len() + 1),
        };

        // Store the address information
        let address_info = AddressInfo {
            public_key: key_data.public_key.to_string(),
            private_key: key_data.private_key.to_string(),
            mnemonic: key_data.mnemonic,
            path: key_data.path,
            label: final_label,
            address_type: addr_type.to_string(),
        };

        self.addresses.insert(address_str.clone(), address_info);
        self.save()?;

        Ok(address_str)
    }

    /// Show details of a specific address
    ///
    /// # Arguments
    ///
    /// * `address` - The Bitcoin address to show
    /// * `show_private_key` - Whether to include private key and mnemonic in output
    ///
    /// # Returns
    ///
    /// * `Result<Value>` - JSON object with address details or error
    pub fn show_address(&self, address: &str, show_private_key: Option<bool>) -> Result<Value> {
        let show_private_key = show_private_key.unwrap_or(false);
        let address_info = self
            .addresses
            .get(address)
            .ok_or_else(|| WalletError::AddressNotFound(address.to_string()))?;

        let mut result = json!({
            "address": address,
            "public_key": address_info.public_key,
            "label": address_info.label,
            "address_type": address_info.address_type,
            "network": match self.network {
                Network::Bitcoin => "mainnet",
                Network::Testnet => "testnet4",
                Network::Regtest => "regtest",
                _ => "unknown",
            },
        });

        if show_private_key {
            result["private_key"] = json!(address_info.private_key);
            if let Some(ref mnemonic) = address_info.mnemonic {
                result["mnemonic"] = json!(mnemonic);
            }
            if let Some(ref path) = address_info.path {
                result["path"] = json!(path);
            }
        }

        Ok(result)
    }

    /// List all addresses in the wallet
    ///
    /// # Returns
    ///
    /// * `Result<Vec<Value>>` - List of addresses with labels or error
    pub fn list_addresses(&self) -> Result<Vec<Value>> {
        let mut result = Vec::new();

        for (address, info) in &self.addresses {
            result.push(json!({
                "address": address,
                "label": info.label,
                "address_type": info.address_type,
                "network": match self.network {
                    Network::Bitcoin => "mainnet",
                    Network::Testnet => "testnet4",
                    Network::Regtest => "regtest",
                    _ => "unknown",
                },
            }));
        }

        Ok(result)
    }

    /// Sign a raw Bitcoin transaction
    ///
    /// This method signs an unsigned transaction with private keys from the wallet.
    /// It supports P2PKH and P2WPKH (bech32) inputs.
    ///
    /// # Arguments
    ///
    /// * `raw_tx_hex` - Unsigned transaction in hexadecimal format
    /// * `utxos` - Vector of (script_pubkey_hex, amount_in_satoshis) pairs for each input
    ///
    /// # Returns
    ///
    /// * `Result<String>` - Signed transaction in hexadecimal format or error
    pub fn sign_transaction(&self, raw_tx_hex: &str, utxos: Vec<(&str, u64)>) -> Result<String> {
        signer::sign_transaction(&self.addresses, raw_tx_hex, utxos, self.network)
    }
}