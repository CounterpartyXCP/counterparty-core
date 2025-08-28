//! Wallet storage functionality.
//!
//! This module handles:
//! - Loading and saving wallet data
//! - Encryption and decryption of wallet files
//! - Managing wallet file paths
//! - Secure password management via the system keyring
//!
//! See instruction to Setting Up Gnome Keyring on Ubuntu 22.04 Headless/Server
//! https://claude.ai/public/artifacts/e893899f-9cd1-4972-ae37-30c7d8b8cd70

use std::fs;
use std::path::{Path, PathBuf};

use cocoon::Cocoon;
use secrecy::ExposeSecret;
use secrecy::SecretString;
use serde_json;

use super::password::PasswordManager;
use super::types::{AddressMap, Result, WalletError};
use super::utils::get_network_dir;
use crate::config;

/// Handles wallet storage operations
pub struct WalletStorage {
    wallet_file: PathBuf,
    password_manager: PasswordManager,
}

impl WalletStorage {
    /// Initialize wallet storage
    ///
    /// This creates a new wallet storage or loads an existing one from the specified data directory.
    /// The system automatically manages password storage using the system's native keyring.
    ///
    /// # Arguments
    ///
    /// * `data_dir` - Directory where wallet data will be stored
    /// * `network` - Bitcoin network to use (mainnet, testnet, regtest)
    ///
    /// # Returns
    ///
    /// * `Result<(WalletStorage, AddressMap)>` - Storage instance and loaded addresses, or error
    pub fn init<P: AsRef<Path>>(
        data_dir: P,
        network: config::Network,
    ) -> Result<(Self, AddressMap)> {
        let data_dir = data_dir.as_ref().to_path_buf();

        // Create network-specific subdirectory using utility function
        let network_dir = get_network_dir(&data_dir, network);

        // Create the data directory if it doesn't exist
        fs::create_dir_all(&network_dir)?;

        let wallet_file = network_dir.join("wallet.db");

        // Create the password manager with a unique name for this wallet
        let wallet_name = network_dir.to_string_lossy().to_string();
        let password_manager = PasswordManager::new(network, &wallet_name);

        let wallet_exists = wallet_file.exists();

        // Get or set password
        let password = if wallet_exists {
            // Try to get the password from the keyring or prompt the user
            password_manager.get_password()?
        } else {
            // New wallet, prompt for a new password with confirmation
            password_manager.prompt_new_password()?
        };

        // Initialize or load addresses
        let addresses = if wallet_exists {
            Self::load_addresses(&wallet_file, &password)?
        } else {
            AddressMap::new()
        };

        let storage = WalletStorage {
            wallet_file,
            password_manager,
        };

        if !wallet_exists {
            storage.save(&addresses)?;
        }

        Ok((storage, addresses))
    }

    /// Load addresses from encrypted wallet file
    fn load_addresses(wallet_file: &Path, password: &SecretString) -> Result<AddressMap> {
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
        let cocoon = Cocoon::new(password.expose_secret().as_bytes());
        cocoon
            .decrypt(&mut encrypted_data, &prefix)
            .map_err(|e| WalletError::CocoonError(format!("Failed to decrypt wallet: {:?}", e)))?;

        // Convert to UTF-8 string and parse JSON
        let json_data = String::from_utf8(encrypted_data)
            .map_err(|_| WalletError::BitcoinError("Invalid UTF-8 in wallet file".to_string()))?;

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
        // Get the password from the keyring/cache
        let password = self.password_manager.get_password()?;

        let json_data = serde_json::to_string(addresses)?;
        let mut cocoon = Cocoon::new(password.expose_secret().as_bytes());

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

    /// Change the wallet password
    ///
    /// # Arguments
    ///
    /// * `addresses` - Current address map (needed to re-encrypt the wallet)
    ///
    /// # Returns
    ///
    /// * `Result<()>` - Success or error
    pub fn change_password(&self, addresses: &AddressMap) -> Result<()> {
        // Change the password
        let new_password = self.password_manager.change_password()?;

        // Re-encrypt and save the wallet with the new password
        let json_data = serde_json::to_string(addresses)?;
        let mut cocoon = Cocoon::new(new_password.expose_secret().as_bytes());

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

    /// Clear the wallet password from the keyring and cache
    ///
    /// # Returns
    ///
    /// * `Result<()>` - Success or error
    pub fn clear_password(&self) -> Result<()> {
        self.password_manager.clear_password()
    }
}
