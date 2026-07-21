//! Wallet storage functionality.
//!
//! This module handles:
//! - Loading and saving wallet data
//! - Encryption and decryption of wallet files
//! - Managing wallet file paths
//! - Secure password management via the system keyring
//!
//! The wallet is stored as a single self-contained `cocoon` container
//! (`wallet.db`) written atomically (temp file + rename) so an interrupted
//! write can never leave the only copy of the private keys unreadable. Wallets
//! created by earlier builds used a detached-prefix format (`wallet.db` +
//! `wallet.prefix`); those are still read transparently and upgraded to the
//! single-file format on the next save.

use std::fs;
use std::path::{Path, PathBuf};

use cocoon::Cocoon;
use secrecy::ExposeSecret;
use secrecy::SecretString;
use zeroize::Zeroizing;

use super::password::PasswordManager;
use super::types::{AddressMap, Result, WalletError};
use crate::config;

/// How many times to re-prompt on a wrong password before giving up.
const MAX_PASSWORD_ATTEMPTS: usize = 3;

/// Handles wallet storage operations
pub struct WalletStorage {
    wallet_file: PathBuf,
    password_manager: PasswordManager,
}

impl WalletStorage {
    /// Initialize wallet storage
    ///
    /// Creates a new wallet or loads an existing one. `data_dir` is the
    /// network-specific directory (e.g. `.../counterparty-client/mainnet`); the
    /// wallet lives directly inside it.
    pub fn init<P: AsRef<Path>>(
        data_dir: P,
        network: config::Network,
    ) -> Result<(Self, AddressMap)> {
        let network_dir = data_dir.as_ref().to_path_buf();

        // Create the wallet directory (0700 on Unix) if it doesn't exist.
        fs::create_dir_all(&network_dir)?;
        restrict_dir_permissions(&network_dir);

        let wallet_file = network_dir.join("wallet.db");

        // Create the password manager with a unique name for this wallet.
        let wallet_name = network_dir.to_string_lossy().to_string();
        let password_manager = PasswordManager::new(network, &wallet_name);

        let storage = WalletStorage {
            wallet_file,
            password_manager,
        };

        if storage.wallet_file.exists() {
            let addresses = storage.load_with_retry()?;
            Ok((storage, addresses))
        } else {
            // New wallet: prompt for a password, write the empty wallet, then
            // persist the password (only after the write succeeds).
            let password = storage.password_manager.prompt_new_password()?;
            let addresses = AddressMap::new();
            storage.write_encrypted(&addresses, &password)?;
            storage.password_manager.persist(&password)?;
            Ok((storage, addresses))
        }
    }

    /// Clear a wallet's stored password without loading (or being able to
    /// decrypt) the wallet. Used by `disconnect` so it always works, even if the
    /// keyring somehow holds a stale password.
    pub fn clear_password_for<P: AsRef<Path>>(data_dir: P, network: config::Network) -> Result<()> {
        let network_dir = data_dir.as_ref().to_path_buf();
        let wallet_name = network_dir.to_string_lossy().to_string();
        PasswordManager::new(network, &wallet_name).clear_password()
    }

    /// Load the wallet, verifying each candidate password by actually
    /// decrypting. A cached/keyring password that fails to decrypt is forgotten
    /// so it can never lock the CLI out of an intact wallet.
    fn load_with_retry(&self) -> Result<AddressMap> {
        // 1) Try a non-interactive password (cache or keyring) once.
        if let Some(password) = self.password_manager.cached_or_stored()? {
            match self.decrypt_addresses(&password) {
                Ok(addresses) => {
                    self.password_manager.persist(&password)?;
                    return Ok(addresses);
                }
                Err(_) => self.password_manager.forget(),
            }
        }

        // 2) Prompt interactively, with a bounded number of retries.
        let mut last_err: Option<WalletError> = None;
        for attempt in 1..=MAX_PASSWORD_ATTEMPTS {
            let password = self.password_manager.prompt_existing()?;
            match self.decrypt_addresses(&password) {
                Ok(addresses) => {
                    self.password_manager.persist(&password)?;
                    return Ok(addresses);
                }
                Err(e) => {
                    if attempt < MAX_PASSWORD_ATTEMPTS {
                        eprintln!("Wrong password, please try again.");
                    }
                    last_err = Some(e);
                }
            }
        }

        Err(last_err
            .unwrap_or_else(|| WalletError::CocoonError("Failed to decrypt wallet".to_string())))
    }

    /// Decrypt the wallet file with the given password and parse the address map.
    /// Reads both the single-file container format and the legacy detached-prefix
    /// format transparently.
    fn decrypt_addresses(&self, password: &SecretString) -> Result<AddressMap> {
        let bytes = fs::read(&self.wallet_file)?;
        let cocoon = Cocoon::new(password.expose_secret().as_bytes());

        // Preferred: single self-contained container.
        let plaintext: Zeroizing<Vec<u8>> = match cocoon.unwrap(&bytes) {
            Ok(data) => Zeroizing::new(data),
            Err(container_err) => {
                // Fall back to the legacy detached-prefix format, if present.
                let prefix_file = self.wallet_file.with_extension("prefix");
                if !prefix_file.exists() {
                    return Err(WalletError::CocoonError(format!(
                        "Failed to decrypt wallet: {container_err:?}"
                    )));
                }
                let prefix = fs::read(&prefix_file)?;
                let mut encrypted = bytes;
                cocoon.decrypt(&mut encrypted, &prefix).map_err(|e| {
                    WalletError::CocoonError(format!("Failed to decrypt wallet: {e:?}"))
                })?;
                Zeroizing::new(encrypted)
            }
        };

        let json = Zeroizing::new(
            String::from_utf8(plaintext.to_vec())
                .map_err(|_| WalletError::BitcoinError("Invalid UTF-8 in wallet file".into()))?,
        );
        Ok(serde_json::from_str(&json)?)
    }

    /// Encrypt and write the address map to disk atomically with the given
    /// password. Removes any leftover legacy prefix file after a successful
    /// single-file write.
    fn write_encrypted(&self, addresses: &AddressMap, password: &SecretString) -> Result<()> {
        let json = Zeroizing::new(serde_json::to_string(addresses)?);
        let mut cocoon = Cocoon::new(password.expose_secret().as_bytes());
        let container = cocoon
            .wrap(json.as_bytes())
            .map_err(|e| WalletError::CocoonError(format!("Failed to encrypt wallet: {e:?}")))?;

        atomic_write(&self.wallet_file, &container)?;

        // The wallet is now stored single-file; drop the obsolete legacy prefix.
        let prefix_file = self.wallet_file.with_extension("prefix");
        if prefix_file.exists() {
            let _ = fs::remove_file(&prefix_file);
        }
        Ok(())
    }

    /// Saves the wallet addresses to the encrypted file using the current password.
    pub fn save(&self, addresses: &AddressMap) -> Result<()> {
        let password = self
            .password_manager
            .cached_or_stored()?
            .ok_or_else(|| WalletError::KeyringError("Wallet password not available".into()))?;
        self.write_encrypted(addresses, &password)
    }

    /// Change the wallet password: re-encrypt and persist to disk *first*, then
    /// update the keyring, so a failed write can never leave the keyring and the
    /// file out of sync.
    pub fn change_password(&self, addresses: &AddressMap) -> Result<()> {
        let new_password = self.password_manager.prompt_new_password()?;
        self.write_encrypted(addresses, &new_password)?;
        self.password_manager.persist(&new_password)?;
        Ok(())
    }

    /// Clear the wallet password from the keyring and cache
    pub fn clear_password(&self) -> Result<()> {
        self.password_manager.clear_password()
    }
}

/// Write `data` to `path` atomically: write to a sibling temp file, flush, then
/// rename over the target (rename is atomic on the same filesystem).
fn atomic_write(path: &Path, data: &[u8]) -> Result<()> {
    let tmp = path.with_extension("db.tmp");
    {
        use std::io::Write;
        let mut file = create_private_file(&tmp)?;
        file.write_all(data)?;
        file.flush()?;
        file.sync_all()?;
    }
    fs::rename(&tmp, path)?;
    Ok(())
}

/// Create (or truncate) a file, restricting it to owner-only (0600) on Unix.
fn create_private_file(path: &Path) -> Result<fs::File> {
    #[cfg(unix)]
    {
        use std::os::unix::fs::OpenOptionsExt;
        Ok(fs::OpenOptions::new()
            .write(true)
            .create(true)
            .truncate(true)
            .mode(0o600)
            .open(path)?)
    }
    #[cfg(not(unix))]
    {
        Ok(fs::File::create(path)?)
    }
}

/// Restrict a directory to owner-only (0700) on Unix. Best-effort.
fn restrict_dir_permissions(dir: &Path) {
    #[cfg(unix)]
    {
        use std::os::unix::fs::PermissionsExt;
        let _ = fs::set_permissions(dir, fs::Permissions::from_mode(0o700));
    }
    #[cfg(not(unix))]
    {
        let _ = dir;
    }
}

#[cfg(test)]
mod tests {
    //! `WalletStorage::save`/`load` are wired to the OS keyring via
    //! `PasswordManager`, so they cannot be exercised end-to-end without a
    //! keyring and an interactive password prompt. These tests instead cover the
    //! lowest-level seam those methods rely on: the `cocoon` single-file
    //! encrypt -> decrypt round-trip (and legacy detached-prefix decrypt) of the
    //! JSON-serialized address map, plus the atomic-write helper.

    use super::*;
    use secrecy::{ExposeSecret, SecretString};

    /// Build a `WalletStorage` pointing at `path` without touching the keyring
    /// (the `PasswordManager` is only used by methods we don't call here).
    fn storage_at(path: &Path) -> WalletStorage {
        WalletStorage {
            wallet_file: path.to_path_buf(),
            password_manager: PasswordManager::new(config::Network::Regtest, "test"),
        }
    }

    fn sample_map() -> AddressMap {
        let mut m = AddressMap::new();
        m.insert(
            "bcrt1qexampleaddress".to_string(),
            super::super::types::AddressInfo {
                public_key: "02aabbccddeeff00112233445566778899aabbccddeeff00112233445566778899"
                    .to_string(),
                private_key: SecretString::from("cVwifKeyExampleValue".to_string()),
                label: "test-label".to_string(),
                address_type: "bech32".to_string(),
            },
        );
        m
    }

    #[test]
    fn cocoon_single_file_roundtrip_preserves_address_map() {
        let addresses = sample_map();
        let password = "correct horse battery staple";

        // Encrypt (mirrors WalletStorage::write_encrypted).
        let json = serde_json::to_string(&addresses).unwrap();
        let mut cocoon = Cocoon::new(password.as_bytes());
        let container = cocoon.wrap(json.as_bytes()).unwrap();
        assert_ne!(
            container,
            json.as_bytes(),
            "container must differ from plaintext"
        );

        // Decrypt (mirrors WalletStorage::decrypt_addresses).
        let cocoon = Cocoon::new(password.as_bytes());
        let recovered = cocoon.unwrap(&container).unwrap();
        let recovered_map: AddressMap =
            serde_json::from_str(&String::from_utf8(recovered).unwrap()).unwrap();

        assert_eq!(recovered_map.len(), 1);
        let info = recovered_map.get("bcrt1qexampleaddress").unwrap();
        assert_eq!(info.private_key.expose_secret(), "cVwifKeyExampleValue");
        assert_eq!(info.address_type, "bech32");
    }

    #[test]
    fn cocoon_unwrap_fails_with_wrong_password() {
        let addresses = sample_map();
        let json = serde_json::to_string(&addresses).unwrap();
        let mut cocoon = Cocoon::new(b"right-password");
        let container = cocoon.wrap(json.as_bytes()).unwrap();

        let cocoon = Cocoon::new(b"wrong-password");
        assert!(cocoon.unwrap(&container).is_err());
    }

    #[test]
    fn legacy_detached_prefix_still_decrypts() {
        // Encrypt with the old detached-prefix API and confirm it round-trips
        // (this is the fallback path in decrypt_addresses).
        let addresses = sample_map();
        let json = serde_json::to_string(&addresses).unwrap();
        let mut data = json.into_bytes();
        let mut cocoon = Cocoon::new(b"pw");
        let prefix = cocoon.encrypt(&mut data).unwrap();

        let cocoon = Cocoon::new(b"pw");
        cocoon.decrypt(&mut data, &prefix).unwrap();
        let recovered: AddressMap =
            serde_json::from_str(&String::from_utf8(data).unwrap()).unwrap();
        assert_eq!(recovered.len(), 1);
    }

    #[test]
    fn write_encrypted_then_decrypt_roundtrips_via_storage_methods() {
        let dir = tempfile::tempdir().unwrap();
        let storage = storage_at(&dir.path().join("wallet.db"));
        let password = SecretString::from("correct horse battery staple".to_string());
        let addresses = sample_map();

        storage.write_encrypted(&addresses, &password).unwrap();
        let loaded = storage.decrypt_addresses(&password).unwrap();

        assert_eq!(loaded.len(), 1);
        assert_eq!(
            loaded
                .get("bcrt1qexampleaddress")
                .unwrap()
                .private_key
                .expose_secret(),
            "cVwifKeyExampleValue"
        );

        // A wrong password must fail to decrypt.
        let wrong = SecretString::from("nope nope nope nope".to_string());
        assert!(storage.decrypt_addresses(&wrong).is_err());
    }

    #[test]
    fn legacy_two_file_wallet_is_read_then_upgraded_to_single_file() {
        let dir = tempfile::tempdir().unwrap();
        let wallet_file = dir.path().join("wallet.db");
        let prefix_file = wallet_file.with_extension("prefix");
        let password = SecretString::from("pw pw pw pw".to_string());

        // Write a legacy detached-prefix wallet by hand.
        let json = serde_json::to_string(&sample_map()).unwrap();
        let mut data = json.into_bytes();
        let mut cocoon = Cocoon::new(password.expose_secret().as_bytes());
        let prefix = cocoon.encrypt(&mut data).unwrap();
        fs::write(&wallet_file, &data).unwrap();
        fs::write(&prefix_file, prefix).unwrap();

        let storage = storage_at(&wallet_file);

        // The legacy format is read transparently...
        let loaded = storage.decrypt_addresses(&password).unwrap();
        assert_eq!(loaded.len(), 1);

        // ...and a save upgrades it to single-file, dropping the prefix file.
        storage.write_encrypted(&loaded, &password).unwrap();
        assert!(!prefix_file.exists(), "legacy prefix must be removed");
        let reloaded = storage.decrypt_addresses(&password).unwrap();
        assert_eq!(reloaded.len(), 1);
    }

    #[test]
    fn atomic_write_creates_the_file_and_leaves_no_tmp() {
        let dir = tempfile::tempdir().unwrap();
        let path = dir.path().join("wallet.db");
        atomic_write(&path, b"ciphertext").unwrap();
        assert_eq!(fs::read(&path).unwrap(), b"ciphertext");
        assert!(
            !path.with_extension("db.tmp").exists(),
            "temp file must be renamed away"
        );

        #[cfg(unix)]
        {
            use std::os::unix::fs::PermissionsExt;
            let mode = fs::metadata(&path).unwrap().permissions().mode();
            assert_eq!(mode & 0o777, 0o600, "wallet file must be owner-only");
        }
    }
}
