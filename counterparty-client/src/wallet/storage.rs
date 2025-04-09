//! Wallet storage functionality.
//!
//! This module handles:
//! - Loading and saving wallet data
//! - Encryption and decryption of wallet files
//! - Managing wallet file paths

use std::fs::{self, File};
use std::io::{Read, Write};
use std::path::{Path, PathBuf};

use cocoon::Cocoon;
use rand::distributions::Alphanumeric;
use rand::{thread_rng, Rng};
use serde_json;

use crate::config;
use super::types::{AddressMap, Result, WalletError};
use super::utils::get_network_dir;

/// Handles wallet storage operations
pub struct WalletStorage {
    wallet_file: PathBuf,
    password: String,
}

impl WalletStorage {
    /// Initialize wallet storage
    ///
    /// This creates a new wallet storage or loads an existing one from the specified data directory.
    /// If the wallet doesn't exist, it generates a random password and stores it in a .cookie file.
    ///
    /// # Arguments
    ///
    /// * `data_dir` - Directory where wallet data will be stored
    /// * `network` - Bitcoin network to use (mainnet, testnet, regtest)
    ///
    /// # Returns
    ///
    /// * `Result<(WalletStorage, AddressMap)>` - Storage instance and loaded addresses, or error
    pub fn init<P: AsRef<Path>>(data_dir: P, network: config::Network) -> Result<(Self, AddressMap)> {
        let data_dir = data_dir.as_ref().to_path_buf();

        // Create network-specific subdirectory using utility function
        let network_dir = get_network_dir(&data_dir, network);

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
            WalletStorage::load_addresses(&wallet_file, &password)?
        } else {
            AddressMap::new()
        };

        let storage = WalletStorage {
            wallet_file,
            password,
        };

        Ok((storage, addresses))
    }

    /// Load addresses from encrypted wallet file
    fn load_addresses(wallet_file: &Path, password: &str) -> Result<AddressMap> {
        // Check if prefix file exists
        let prefix_file = wallet_file.with_extension("prefix");
        if !prefix_file.exists() {
            return Err(WalletError::BitcoinError(
                "Prefix file not found".to_string(),
            ));
        }

        // Read prefix and encrypted data
        let prefix = fs::read(&prefix_file)?;
        let mut encrypted_data = fs::read(wallet_file)?;

        // Create a new Cocoon and decrypt
        let cocoon = Cocoon::new(password.as_bytes());
        cocoon.decrypt(&mut encrypted_data, &prefix).map_err(|e| {
            WalletError::CocoonError(format!("Failed to decrypt wallet: {:?}", e))
        })?;

        // Convert to UTF-8 string and parse JSON
        let json_data = String::from_utf8(encrypted_data).map_err(|_| {
            WalletError::BitcoinError("Invalid UTF-8 in wallet file".to_string())
        })?;

        Ok(serde_json::from_str(&json_data)?)
    }

    /// Saves the wallet addresses to the encrypted file
    ///
    /// # Arguments
    ///
    /// * `addresses` - Address map to save
    ///
    /// # Returns
    ///
    /// * `Result<()>` - Success or error
    pub fn save(&self, addresses: &AddressMap) -> Result<()> {
        let json_data = serde_json::to_string(addresses)?;
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
}
