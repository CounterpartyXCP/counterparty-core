//! Secure password manager using the system's native keyring.
//!
//! A password is only persisted to the keyring (and the in-memory cache) after
//! the caller has confirmed it actually decrypts the wallet — see
//! [`PasswordManager::persist`] and its use in `storage::WalletStorage`. This
//! avoids caching a mistyped password, which would otherwise lock the CLI out
//! of an intact wallet.

use keyring::{Entry, Error as KeyringError};
use once_cell::sync::OnceCell;
use secrecy::ExposeSecret;
use secrecy::SecretString;
use std::collections::HashMap;
use std::io::{self, Write};
use std::sync::Mutex;

use super::types::{Result, WalletError};
use crate::config;

/// Minimum length enforced for a new wallet password.
const MIN_PASSWORD_LEN: usize = 8;

// In-memory password cache, keyed by wallet (service + username) so distinct
// wallets/networks in the same process never share a password.
static PASSWORD_CACHE: OnceCell<Mutex<HashMap<String, SecretString>>> = OnceCell::new();

fn cache() -> &'static Mutex<HashMap<String, SecretString>> {
    PASSWORD_CACHE.get_or_init(|| Mutex::new(HashMap::new()))
}

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

        PasswordManager {
            service_name,
            username,
        }
    }

    /// Return a non-interactive password for an existing wallet: the cached
    /// value, else the keyring value, else `None`. Never prompts and never
    /// persists — the caller verifies it decrypts the wallet before calling
    /// [`persist`](Self::persist).
    pub fn cached_or_stored(&self) -> Result<Option<SecretString>> {
        if let Some(cached) = self.get_from_cache() {
            return Ok(Some(cached));
        }
        self.get_from_keyring()
    }

    /// Prompt the user for an existing wallet's password. Not persisted here.
    pub fn prompt_existing(&self) -> Result<SecretString> {
        self.prompt_password("Enter wallet password: ")
    }

    /// Prompt for a brand-new wallet password (with confirmation and a minimum
    /// strength check). Not persisted here — the caller persists after the
    /// initial encrypted write succeeds.
    pub fn prompt_new_password(&self) -> Result<SecretString> {
        let password = self.prompt_password("Enter new wallet password: ")?;

        if password.expose_secret().chars().count() < MIN_PASSWORD_LEN {
            return Err(WalletError::BitcoinError(format!(
                "Password too short: use at least {MIN_PASSWORD_LEN} characters."
            )));
        }

        let confirmation = self.prompt_password("Confirm wallet password: ")?;
        if password.expose_secret() != confirmation.expose_secret() {
            return Err(WalletError::BitcoinError(
                "Passwords do not match".to_string(),
            ));
        }

        Ok(password)
    }

    /// Persist a verified password to the keyring and the in-memory cache.
    pub fn persist(&self, password: &SecretString) -> Result<()> {
        self.set_to_keyring(password)?;
        self.set_to_cache(password);
        Ok(())
    }

    /// Forget a password after a failed decrypt so the next attempt re-prompts
    /// instead of reusing the bad value.
    pub fn forget(&self) {
        self.remove_from_cache();
        // Best-effort: drop the keyring entry too, so a stale/wrong stored
        // password cannot brick subsequent runs.
        let _ = self.delete_from_keyring();
    }

    /// Clear the password from the keyring and cache
    pub fn clear_password(&self) -> Result<()> {
        self.delete_from_keyring()?;
        self.remove_from_cache();
        Ok(())
    }

    // Private methods

    fn cache_key(&self) -> String {
        format!("{}:{}", self.service_name, self.username)
    }

    fn get_entry(&self) -> Result<Entry> {
        Entry::new(&self.service_name, &self.username).map_err(|e| {
            WalletError::KeyringError(format!(
                "Could not access the system keyring: {e}. On a headless server \
                 you may need to run a Secret Service provider (e.g. gnome-keyring)."
            ))
        })
    }

    /// Read the stored password, returning `Ok(None)` when there is no entry.
    fn get_from_keyring(&self) -> Result<Option<SecretString>> {
        let entry = self.get_entry()?;
        match entry.get_password() {
            Ok(p) => Ok(Some(SecretString::new(p))),
            Err(KeyringError::NoEntry) => Ok(None),
            Err(e) => Err(WalletError::KeyringError(format!(
                "Failed to read password from keyring: {e}"
            ))),
        }
    }

    fn set_to_keyring(&self, password: &SecretString) -> Result<()> {
        let entry = self.get_entry()?;
        entry.set_password(password.expose_secret()).map_err(|e| {
            WalletError::KeyringError(format!("Failed to store password in keyring: {e}"))
        })
    }

    fn delete_from_keyring(&self) -> Result<()> {
        let entry = self.get_entry()?;
        match entry.delete_password() {
            Ok(()) | Err(KeyringError::NoEntry) => Ok(()),
            Err(e) => Err(WalletError::KeyringError(format!(
                "Failed to delete password from keyring: {e}"
            ))),
        }
    }

    fn get_from_cache(&self) -> Option<SecretString> {
        let guard = cache().lock().unwrap_or_else(|e| e.into_inner());
        guard.get(&self.cache_key()).cloned()
    }

    fn set_to_cache(&self, password: &SecretString) {
        let mut guard = cache().lock().unwrap_or_else(|e| e.into_inner());
        guard.insert(self.cache_key(), password.clone());
    }

    fn remove_from_cache(&self) {
        let mut guard = cache().lock().unwrap_or_else(|e| e.into_inner());
        guard.remove(&self.cache_key());
    }

    fn prompt_password(&self, prompt: &str) -> Result<SecretString> {
        // Print prompt
        print!("{}", prompt);
        io::stdout().flush()?;

        // Read password without echoing
        let password =
            rpassword::read_password().map_err(|e| WalletError::IoError(io::Error::other(e)))?;

        if password.is_empty() {
            return Err(WalletError::BitcoinError(
                "Password cannot be empty".to_string(),
            ));
        }

        Ok(SecretString::new(password))
    }
}
