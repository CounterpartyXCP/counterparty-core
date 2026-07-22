//! Secure password manager using the system's native keyring.
//!
//! A password is only persisted to the keyring (and the in-memory cache) after
//! the caller has confirmed it actually decrypts the wallet — see
//! [`PasswordManager::persist`] and its use in `storage::WalletStorage`. This
//! avoids caching a mistyped password, which would otherwise lock the CLI out
//! of an intact wallet.

use keyring::{Entry, Error as KeyringError};
use secrecy::ExposeSecret;
use secrecy::SecretString;
use std::collections::HashMap;
use std::io::{self, Write};
use std::sync::{Mutex, OnceLock};

use super::types::{Result, WalletError};
use crate::config;

/// Minimum length enforced for a new wallet password. `cocoon` derives the
/// file-encryption key with a fixed PBKDF2 work factor, so passphrase length is
/// the main defence for a stolen `wallet.db`; require a reasonably long one.
const MIN_PASSWORD_LEN: usize = 12;

// In-memory password cache, keyed by wallet (service + username) so distinct
// wallets/networks in the same process never share a password.
static PASSWORD_CACHE: OnceLock<Mutex<HashMap<String, SecretString>>> = OnceLock::new();

fn cache() -> &'static Mutex<HashMap<String, SecretString>> {
    PASSWORD_CACHE.get_or_init(|| Mutex::new(HashMap::new()))
}

/// Reject a new password that is shorter than [`MIN_PASSWORD_LEN`] characters.
fn check_password_strength(password: &SecretString) -> Result<()> {
    if password.expose_secret().chars().count() < MIN_PASSWORD_LEN {
        return Err(WalletError::Validation(format!(
            "Password too short: use at least {MIN_PASSWORD_LEN} characters."
        )));
    }
    Ok(())
}

/// Secure password manager
pub struct PasswordManager {
    service_name: String,
    username: String,
    /// Whether the OS keyring may be touched. Always `true` in production; unit
    /// tests build a cache-only manager so they never pop a keychain dialog or
    /// depend on a Secret Service being present.
    use_keyring: bool,
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
            use_keyring: true,
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
        // Check strength before asking to confirm, so a too-short password fails
        // fast.
        check_password_strength(&password)?;

        let confirmation = self.prompt_password("Confirm wallet password: ")?;
        if password.expose_secret() != confirmation.expose_secret() {
            return Err(WalletError::Validation(
                "Passwords do not match".to_string(),
            ));
        }

        Ok(password)
    }

    /// Persist a verified password to the in-memory cache and (best-effort) the
    /// system keyring.
    ///
    /// The cache always succeeds and covers the rest of this run. Storing in the
    /// keyring is a cross-run convenience, so a keyring that is unavailable (e.g.
    /// no Secret Service on a headless server) is reported but does not fail the
    /// operation — otherwise an intact wallet could not be created or unlocked
    /// there at all.
    pub fn persist(&self, password: &SecretString) -> Result<()> {
        self.set_to_cache(password);
        if let Err(e) = self.set_to_keyring(password) {
            eprintln!("Note: could not save the wallet password to the system keyring ({e}). It is kept in memory for this session only.");
        }
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
        if !self.use_keyring {
            return Ok(None);
        }
        let entry = self.get_entry()?;
        match entry.get_password() {
            Ok(p) => Ok(Some(SecretString::from(p))),
            Err(KeyringError::NoEntry) => Ok(None),
            Err(e) => Err(WalletError::KeyringError(format!(
                "Failed to read password from keyring: {e}"
            ))),
        }
    }

    fn set_to_keyring(&self, password: &SecretString) -> Result<()> {
        if !self.use_keyring {
            return Ok(());
        }
        let entry = self.get_entry()?;
        entry.set_password(password.expose_secret()).map_err(|e| {
            WalletError::KeyringError(format!("Failed to store password in keyring: {e}"))
        })
    }

    fn delete_from_keyring(&self) -> Result<()> {
        if !self.use_keyring {
            return Ok(());
        }
        let entry = self.get_entry()?;
        match entry.delete_credential() {
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
            return Err(WalletError::Validation(
                "Password cannot be empty".to_string(),
            ));
        }

        Ok(SecretString::from(password))
    }
}

#[cfg(test)]
impl PasswordManager {
    /// Test-only: a password manager that never touches the OS keyring, so unit
    /// tests exercising `persist`/`forget`/`load_with_retry` run without popping a
    /// keychain dialog (macOS) or needing a Secret Service (headless Linux).
    pub(crate) fn new_cache_only(network: config::Network, wallet_name: &str) -> Self {
        let mut pm = Self::new(network, wallet_name);
        pm.use_keyring = false;
        pm
    }

    /// Test-only: seed the in-memory password cache so higher-level wallet
    /// operations (`save`, decrypt-on-load) work without the OS keyring or an
    /// interactive prompt. Never touches the keyring.
    pub(crate) fn cache_for_test(&self, password: &str) {
        self.set_to_cache(&SecretString::from(password.to_string()));
    }

    /// Test-only: whether this wallet currently has a password in the in-memory
    /// cache. Lets other modules assert cache state (e.g. that a wrong password
    /// was forgotten) without touching the OS keyring.
    pub(crate) fn is_cached(&self) -> bool {
        self.get_from_cache().is_some()
    }
}

#[cfg(test)]
mod tests {
    //! These tests deliberately exercise only the in-memory cache paths (never
    //! the OS keyring), so they run identically on macOS/Linux/headless CI.
    //! Each test uses a unique wallet name so the process-global cache can't
    //! leak state between tests.
    use super::*;
    use crate::config::Network;

    #[test]
    fn cache_key_combines_service_and_username() {
        let pm = PasswordManager::new_cache_only(Network::Regtest, "wallet-ck");
        assert_eq!(
            pm.cache_key(),
            "counterparty-client-wallet-Regtest:wallet-ck"
        );
    }

    #[test]
    fn set_get_remove_cache_roundtrip() {
        let pm = PasswordManager::new_cache_only(Network::Signet, "wallet-sgr");
        assert!(pm.get_from_cache().is_none());

        pm.set_to_cache(&SecretString::from("hunter2xx".to_string()));
        assert_eq!(pm.get_from_cache().unwrap().expose_secret(), "hunter2xx");

        pm.remove_from_cache();
        assert!(pm.get_from_cache().is_none());
    }

    #[test]
    fn distinct_wallets_do_not_share_cache() {
        let a = PasswordManager::new_cache_only(Network::Regtest, "wallet-iso-a");
        let b = PasswordManager::new_cache_only(Network::Regtest, "wallet-iso-b");
        a.set_to_cache(&SecretString::from("secretaaa".to_string()));
        // Different username -> different cache key -> isolated.
        assert!(b.get_from_cache().is_none());
        // Different network is also a different key for the same username.
        let c = PasswordManager::new_cache_only(Network::Signet, "wallet-iso-a");
        assert!(c.get_from_cache().is_none());
    }

    #[test]
    fn cached_or_stored_returns_cache_hit_without_touching_keyring() {
        let pm = PasswordManager::new_cache_only(Network::Testnet4, "wallet-cos");
        pm.cache_for_test("cachedpw123");
        // A cache hit short-circuits before any keyring access.
        let got = pm.cached_or_stored().unwrap().unwrap();
        assert_eq!(got.expose_secret(), "cachedpw123");
    }

    #[test]
    fn password_strength_enforces_minimum_length() {
        // 11 chars: below the 12-char minimum.
        assert!(check_password_strength(&SecretString::from("short-pass1".to_string())).is_err());
        // Exactly 12 chars: accepted.
        assert!(check_password_strength(&SecretString::from("twelve-chars".to_string())).is_ok());
    }
}
