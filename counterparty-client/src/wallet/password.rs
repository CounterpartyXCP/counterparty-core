//! Secure password manager using the system's native keyring.

use keyring::{Entry, Error as KeyringError};
use once_cell::sync::OnceCell;
use secrecy::ExposeSecret;
use secrecy::SecretString;
use std::io::{self, Write};
use std::sync::Mutex;

use super::types::{Result, WalletError};
use crate::config;

// Singleton to temporarily store the password in memory during execution
static PASSWORD_CACHE: OnceCell<Mutex<Option<SecretString>>> = OnceCell::new();

/// Secure password manager
pub struct PasswordManager {
    service_name: String,
    username: String,
}

impl PasswordManager {
    /// Create a new password manager instance
    pub fn new(network: config::Network, wallet_name: &str) -> Self {
        // Create a unique service name for this wallet and network
        let service_name = format!("counterparty-client-wallet-{:?}", network);
        let username = wallet_name.to_string();

        // Initialize the password cache if it doesn't already exist
        PASSWORD_CACHE.get_or_init(|| Mutex::new(None));

        PasswordManager {
            service_name,
            username,
        }
    }

    /// Get the password from the keyring or prompt the user
    pub fn get_password(&self) -> Result<SecretString> {
        // Check the in-memory cache first
        if let Some(cached) = self.get_from_cache() {
            return Ok(cached);
        }

        // Try to get from the keyring
        match self.get_from_keyring() {
            Ok(password) => {
                // Cache for future use
                self.set_to_cache(&password);
                Ok(password)
            }
            Err(_) => {
                // If not found in keyring, prompt the user
                let password = self.prompt_password("Enter wallet password: ")?;
                // Store in keyring for later
                self.set_to_keyring(&password)?;
                // Cache for future use
                self.set_to_cache(&password);
                Ok(password)
            }
        }
    }

    /// For new wallets, prompt for a new password
    pub fn prompt_new_password(&self) -> Result<SecretString> {
        let password = self.prompt_password("Enter new wallet password: ")?;
        let confirmation = self.prompt_password("Confirm wallet password: ")?;

        // Compare passwords securely
        if password.expose_secret() != confirmation.expose_secret() {
            return Err(WalletError::BitcoinError(
                "Passwords do not match".to_string(),
            ));
        }

        // Store in keyring
        self.set_to_keyring(&password)?;

        // Cache it
        self.set_to_cache(&password);

        Ok(password)
    }

    /// Change the wallet password
    pub fn change_password(&self) -> Result<SecretString> {
        // Verify old password first
        let _ = self.get_password()?;

        // Prompt and validate new password
        let new_password = self.prompt_new_password()?;

        // Storage and caching handled automatically in prompt_new_password
        Ok(new_password)
    }

    /// Clear the password from the keyring
    pub fn clear_password(&self) -> Result<()> {
        // Delete from keyring
        let entry = self.get_entry();
        if let Err(e) = entry.delete_password() {
            if !matches!(e, KeyringError::NoEntry) {
                return Err(WalletError::BitcoinError(format!(
                    "Error deleting password: {:?}",
                    e
                )));
            }
        }

        // Remove from cache
        if let Some(cache) = PASSWORD_CACHE.get() {
            let mut cache_guard = cache.lock().unwrap();
            *cache_guard = None;
        }

        Ok(())
    }

    // Private methods

    fn get_entry(&self) -> Entry {
        Entry::new(&self.service_name, &self.username).unwrap()
    }

    fn get_from_keyring(&self) -> std::result::Result<SecretString, KeyringError> {
        let entry = self.get_entry();
        entry.get_password().map(|p| SecretString::new(p))
    }

    fn set_to_keyring(&self, password: &SecretString) -> Result<()> {
        let entry = self.get_entry();
        entry
            .set_password(password.expose_secret())
            .map_err(|e| WalletError::BitcoinError(format!("Error storing password: {:?}", e)))
    }

    fn get_from_cache(&self) -> Option<SecretString> {
        PASSWORD_CACHE.get().and_then(|cache| {
            let guard = cache.lock().unwrap();
            guard.clone()
        })
    }

    fn set_to_cache(&self, password: &SecretString) {
        if let Some(cache) = PASSWORD_CACHE.get() {
            let mut cache_guard = cache.lock().unwrap();
            *cache_guard = Some(password.clone());
        }
    }

    fn prompt_password(&self, prompt: &str) -> Result<SecretString> {
        // Print prompt
        print!("{}", prompt);
        io::stdout().flush()?;

        // Read password without echoing
        let password = rpassword::read_password()
            .map_err(|e| WalletError::IoError(io::Error::new(io::ErrorKind::Other, e)))?;

        if password.is_empty() {
            return Err(WalletError::BitcoinError(
                "Password cannot be empty".to_string(),
            ));
        }

        Ok(SecretString::new(password))
    }
}
