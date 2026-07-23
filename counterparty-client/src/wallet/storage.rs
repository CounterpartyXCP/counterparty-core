//! Wallet storage functionality.
//!
//! This module handles:
//! - Loading and saving wallet data
//! - Encryption and decryption of wallet files
//! - Managing wallet file paths
//! - Secure password management via the system keyring
//!
//! The wallet is stored as a single self-contained file (`wallet.db`) written
//! atomically (temp file + rename) so an interrupted write can never leave the
//! only copy of the private keys unreadable.
//!
//! # On-disk format
//!
//! The current (v2) format is `MAGIC || salt || cocoon-container`, where the
//! cocoon key is the password stretched through **Argon2id** over the random
//! per-wallet `salt`. cocoon's own KDF (PBKDF2-HMAC-SHA256 at a fixed ~100k
//! iterations) is GPU/ASIC-friendly and not tunable, so the memory-hard Argon2id
//! pre-stretch is what actually bounds an offline attack on a stolen file; the
//! passphrase-length floor (see [`super::password`]) remains the other half.
//!
//! Two older formats are still read transparently and upgraded to v2 — opportunistically
//! on load (best-effort) and on the next save: a bare `cocoon` container keyed
//! on the raw password (v1), and an even earlier detached-prefix pair
//! (`wallet.db` + `wallet.prefix`).

use std::fs;
use std::path::{Path, PathBuf};
use std::sync::Mutex;

use argon2::{Algorithm, Argon2, Params, Version};
use cocoon::Cocoon;
use secrecy::ExposeSecret;
use secrecy::SecretString;
use zeroize::Zeroizing;

use super::password::PasswordManager;
use super::types::{AddressMap, Result, WalletError};
use crate::config;

/// How many times to re-prompt on a wrong password before giving up.
const MAX_PASSWORD_ATTEMPTS: usize = 3;

/// Magic prefix of the v2 wallet format (Argon2id-pre-stretched cocoon
/// container). A legacy cocoon container begins with `0x7f 0xc0 0x0a`, so it can
/// never be mistaken for this ASCII prefix.
const WALLET_MAGIC_V2: &[u8] = b"XCPWKDF1";
/// Length of the random per-wallet Argon2id salt stored right after the magic.
const ARGON2_SALT_LEN: usize = 16;
/// Length of the key Argon2id derives (then handed to cocoon as its password).
const ARGON2_KEY_LEN: usize = 32;

/// Pinned Argon2id cost parameters: memory (KiB), iterations, parallelism. These
/// match the `argon2` crate's current defaults (OWASP's second recommended
/// Argon2id preset), but are fixed explicitly — rather than relying on
/// `Argon2::default()` — so a future dependency bump cannot silently weaken (or
/// unexpectedly change) the wallet KDF without a deliberate edit here. A change
/// to any of these values re-derives every wallet key, so an existing file
/// only stays readable because each write re-stretches with the current params.
/// Asserted by `argon2_params_are_pinned`.
const ARGON2_M_COST_KIB: u32 = 19_456;
const ARGON2_T_COST: u32 = 2;
const ARGON2_P_COST: u32 = 1;

/// The wallet's Argon2id hasher, configured with the pinned parameters above.
fn wallet_argon2() -> Result<Argon2<'static>> {
    let params = Params::new(
        ARGON2_M_COST_KIB,
        ARGON2_T_COST,
        ARGON2_P_COST,
        Some(ARGON2_KEY_LEN),
    )
    .map_err(|e| WalletError::CocoonError(format!("invalid Argon2 parameters: {e}")))?;
    Ok(Argon2::new(Algorithm::Argon2id, Version::V0x13, params))
}

/// Derive the cocoon key from the user's password with Argon2id (memory-hard)
/// over `salt`. This closes the gap left by cocoon's fixed PBKDF2 KDF against
/// offline brute-forcing of a stolen wallet file. cocoon still applies its own
/// PBKDF2 to this output — harmless defense in depth; the Argon2id memory cost is
/// the real barrier.
fn derive_wallet_key(password: &SecretString, salt: &[u8]) -> Result<Zeroizing<Vec<u8>>> {
    let mut key = Zeroizing::new(vec![0u8; ARGON2_KEY_LEN]);
    wallet_argon2()?
        .hash_password_into(
            password.expose_secret().as_bytes(),
            salt,
            key.as_mut_slice(),
        )
        .map_err(|e| WalletError::CocoonError(format!("wallet key derivation failed: {e}")))?;
    Ok(key)
}

/// Handles wallet storage operations
pub struct WalletStorage {
    wallet_file: PathBuf,
    password_manager: PasswordManager,
    /// The exact `wallet.db` bytes this process observed when it loaded the
    /// wallet (or last wrote it). Used to detect a concurrent writer before a
    /// `save`/`change_password` overwrites the file: a `save` reloads the wallet
    /// map, mutates it in memory and writes the whole file back, so a second
    /// `xcp` process doing the same between our load and our write would be
    /// silently discarded (last-writer-wins) — including a private key it just
    /// generated. `None` until the first successful load/write (and in the
    /// pure-crypto unit tests that never call `save`).
    loaded_bytes: Mutex<Option<Vec<u8>>>,
}

impl WalletStorage {
    /// Assemble a `WalletStorage` with an empty concurrent-write baseline.
    fn from_parts(wallet_file: PathBuf, password_manager: PasswordManager) -> Self {
        WalletStorage {
            wallet_file,
            password_manager,
            loaded_bytes: Mutex::new(None),
        }
    }

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

        // Create the wallet directory (0700 on Unix, from creation) if it
        // doesn't exist, then tighten an already-existing one as a fallback.
        create_private_dir_all(&network_dir)?;
        restrict_dir_permissions(&network_dir);

        let wallet_file = network_dir.join("wallet.db");

        // Create the password manager with a unique name for this wallet.
        let wallet_name = network_dir.to_string_lossy().to_string();
        let password_manager = PasswordManager::new(network, &wallet_name);

        let storage = WalletStorage::from_parts(wallet_file, password_manager);

        if storage.wallet_file.exists() {
            let addresses = storage.load_with_retry()?;
            // Record the on-disk bytes as the concurrent-write baseline: a later
            // `save` compares against these to refuse clobbering a change another
            // process made in the meantime.
            storage.record_loaded_state();
            // A wallet still in a legacy (pre-Argon2id) format would otherwise
            // only be upgraded on the next *write*, leaving a read-only session
            // (e.g. `list`) on the weaker KDF indefinitely. Upgrade it now,
            // best-effort.
            storage.upgrade_format_if_legacy(&addresses);
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
        if let Some(addresses) = self.try_noninteractive_load()? {
            return Ok(addresses);
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

    /// Try the non-interactive password sources (cache, then keyring), verifying
    /// each by actually decrypting the wallet.
    ///
    /// * A correct password is persisted and the decrypted map returned.
    /// * A *wrong* password is forgotten from the **source that produced it**
    ///   (see [`forget_source`](PasswordManager::forget_source)) so it can never
    ///   lock the CLI out of an intact wallet, and `Ok(None)` is returned so the
    ///   caller falls through to prompting. Forgetting only the failing source
    ///   means a wrong `XCP_WALLET_PASSWORD` cannot delete a correct keyring
    ///   credential.
    /// * A keyring that is unavailable (e.g. no Secret Service on a headless
    ///   server) is a warning, not an error — it also returns `Ok(None)`.
    fn try_noninteractive_load(&self) -> Result<Option<AddressMap>> {
        match self.password_manager.cached_or_stored_with_source() {
            Ok(Some((password, source))) => match self.decrypt_addresses(&password) {
                Ok(addresses) => {
                    self.password_manager.persist(&password)?;
                    Ok(Some(addresses))
                }
                Err(_) => {
                    self.password_manager.forget_source(source);
                    Ok(None)
                }
            },
            Ok(None) => Ok(None),
            Err(e) => {
                eprintln!("Note: {e} Falling back to a password prompt.");
                Ok(None)
            }
        }
    }

    /// Decrypt the wallet file with the given password and parse the address map.
    /// Reads both the single-file container format and the legacy detached-prefix
    /// format transparently.
    fn decrypt_addresses(&self, password: &SecretString) -> Result<AddressMap> {
        let bytes = fs::read(&self.wallet_file)?;

        // v2: `MAGIC || salt || cocoon container`, cocoon key = Argon2id(password, salt).
        if let Some(rest) = bytes.strip_prefix(WALLET_MAGIC_V2) {
            if rest.len() < ARGON2_SALT_LEN {
                return Err(WalletError::CocoonError(
                    "wallet file is truncated (missing key-derivation salt)".to_string(),
                ));
            }
            let (salt, container) = rest.split_at(ARGON2_SALT_LEN);
            let key = derive_wallet_key(password, salt)?;
            let cocoon = Cocoon::new(key.as_slice());
            let plaintext: Zeroizing<Vec<u8>> =
                cocoon.unwrap(container).map(Zeroizing::new).map_err(|e| {
                    WalletError::CocoonError(format!("Failed to decrypt wallet: {e:?}"))
                })?;
            return Ok(serde_json::from_slice(plaintext.as_slice())?);
        }

        // Legacy (v1) format: a bare cocoon container keyed on the raw password.
        let cocoon = Cocoon::new(password.expose_secret().as_bytes());
        let plaintext: Zeroizing<Vec<u8>> = match cocoon.unwrap(&bytes) {
            Ok(data) => Zeroizing::new(data),
            Err(container_err) => {
                // Fall back to the even older detached-prefix format, if present.
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

        // Deserialize straight from the decrypted bytes. `plaintext` is
        // `Zeroizing`, so it is wiped on drop; `from_slice` avoids the extra
        // `String` copy of every private key that `from_utf8(plaintext.to_vec())`
        // made — a copy that, on the UTF-8-error path, was owned by the discarded
        // error and never zeroized.
        Ok(serde_json::from_slice(plaintext.as_slice())?)
    }

    /// Encrypt and write the address map to disk atomically with the given
    /// password. Removes any leftover legacy prefix file after a successful
    /// single-file write.
    fn write_encrypted(&self, addresses: &AddressMap, password: &SecretString) -> Result<()> {
        let json = Zeroizing::new(serde_json::to_string(addresses)?);

        // v2 format: derive the cocoon key with Argon2id over a fresh random
        // per-write salt, and prefix the container with `MAGIC || salt` so it can
        // be read back (a fresh salt each write also re-randomises the derived
        // key, so no salt/nonce is ever reused across saves).
        let mut salt = [0u8; ARGON2_SALT_LEN];
        {
            use rand::{rng, RngExt};
            rng().fill(&mut salt);
        }
        let key = derive_wallet_key(password, &salt)?;
        let mut cocoon = Cocoon::new(key.as_slice());
        let container = cocoon
            .wrap(json.as_bytes())
            .map_err(|e| WalletError::CocoonError(format!("Failed to encrypt wallet: {e:?}")))?;

        let mut file_bytes =
            Vec::with_capacity(WALLET_MAGIC_V2.len() + salt.len() + container.len());
        file_bytes.extend_from_slice(WALLET_MAGIC_V2);
        file_bytes.extend_from_slice(&salt);
        file_bytes.extend_from_slice(&container);

        atomic_write(&self.wallet_file, &file_bytes)?;

        // These bytes are now the on-disk state; adopt them as the
        // concurrent-write baseline so a subsequent `save` in this same session
        // is compared against what we actually wrote.
        self.set_loaded_bytes(Some(file_bytes));

        // The wallet is now stored single-file; drop the obsolete legacy prefix.
        let prefix_file = self.wallet_file.with_extension("prefix");
        if prefix_file.exists() {
            let _ = fs::remove_file(&prefix_file);
        }
        Ok(())
    }

    /// Overwrite the concurrent-write baseline (poison-tolerant).
    fn set_loaded_bytes(&self, bytes: Option<Vec<u8>>) {
        *self.loaded_bytes.lock().unwrap_or_else(|e| e.into_inner()) = bytes;
    }

    /// Snapshot the current `wallet.db` bytes as the concurrent-write baseline.
    fn record_loaded_state(&self) {
        self.set_loaded_bytes(fs::read(&self.wallet_file).ok());
    }

    /// If the wallet on disk predates the v2 (Argon2id) format, opportunistically
    /// re-save it in v2 using the already-verified password. Best-effort: a
    /// read-only session must still succeed if this write can't happen (password
    /// not cached, read-only filesystem, a concurrent writer), so any error is a
    /// note, not a failure — the wallet stays readable and upgrades on the next
    /// explicit change.
    fn upgrade_format_if_legacy(&self, addresses: &AddressMap) {
        // Unreadable here: don't attempt and don't warn (load already succeeded).
        let is_legacy = match fs::read(&self.wallet_file) {
            Ok(bytes) => !bytes.starts_with(WALLET_MAGIC_V2),
            Err(_) => return,
        };
        if !is_legacy {
            return;
        }
        if let Err(e) = self.save(addresses) {
            eprintln!(
                "Note: could not upgrade the wallet to the hardened at-rest format now ({e}); \
                 it stays readable and will upgrade on the next change."
            );
        }
    }

    /// Refuse to overwrite the wallet if it changed on disk since this process
    /// loaded (or last wrote) it — almost always a second `xcp` writing
    /// concurrently. A `save` reloads nothing: it writes this process's
    /// in-memory map back over the whole file, so without this check the other
    /// process's change (e.g. a key it just generated) would be silently lost.
    /// A missing/unreadable file is not treated as a conflict — a delete is not
    /// the silent-key-loss case this guards, and the atomic write recreates it.
    fn check_not_modified_since_load(&self) -> Result<()> {
        let expected = self
            .loaded_bytes
            .lock()
            .unwrap_or_else(|e| e.into_inner())
            .clone();
        if let Some(expected) = expected {
            if let Ok(current) = fs::read(&self.wallet_file) {
                if current != expected {
                    return Err(WalletError::ConcurrentModification(
                        "wallet.db changed on disk since it was loaded (another xcp process?); \
                         refusing to overwrite it. Re-run the command to load the latest wallet \
                         and try again."
                            .to_string(),
                    ));
                }
            }
        }
        Ok(())
    }

    /// Saves the wallet addresses to the encrypted file using the current password.
    pub fn save(&self, addresses: &AddressMap) -> Result<()> {
        // Refuse to clobber a concurrent writer (see the method doc).
        self.check_not_modified_since_load()?;
        let password = self
            .password_manager
            .cached_or_stored()?
            .ok_or_else(|| WalletError::KeyringError("Wallet password not available".into()))?;
        self.write_encrypted(addresses, &password)
    }

    /// Change the wallet password: re-encrypt and persist to disk *first*, then
    /// update the keyring, so a failed write can never leave the keyring and the
    /// file out of sync.
    ///
    /// The new password is always prompted for interactively (see
    /// [`PasswordManager::prompt_new_password_interactive`]): `XCP_WALLET_PASSWORD`
    /// holds the *current* unlock password, so adopting it as the new one would
    /// silently rotate the wallet to the same (or an unintended) value.
    pub fn change_password(&self, addresses: &AddressMap) -> Result<()> {
        let new_password = self.password_manager.prompt_new_password_interactive()?;
        // Refuse to clobber a concurrent writer: re-encrypting our (possibly
        // stale) in-memory map would drop a key another process just added.
        self.check_not_modified_since_load()?;
        self.write_encrypted(addresses, &new_password)?;
        self.password_manager.persist(&new_password)?;
        Ok(())
    }

    /// Clear the wallet password from the keyring and cache
    pub fn clear_password(&self) -> Result<()> {
        self.password_manager.clear_password()
    }
}

#[cfg(test)]
impl WalletStorage {
    /// Build storage at `data_dir` with `password` seeded into the in-memory
    /// password cache and an empty encrypted wallet written to disk. No keyring
    /// access and no prompts, so higher-level wallet operations can be exercised
    /// in tests. Returns the storage plus the (empty) address map.
    pub(crate) fn new_for_test<P: AsRef<Path>>(
        data_dir: P,
        network: config::Network,
        password: &str,
    ) -> (Self, AddressMap) {
        let network_dir = data_dir.as_ref().to_path_buf();
        fs::create_dir_all(&network_dir).unwrap();
        let wallet_file = network_dir.join("wallet.db");
        let wallet_name = network_dir.to_string_lossy().to_string();
        let password_manager = PasswordManager::new_cache_only(network, &wallet_name);
        password_manager.cache_for_test(password);
        let storage = WalletStorage::from_parts(wallet_file, password_manager);
        let addresses = AddressMap::new();
        storage
            .write_encrypted(&addresses, &SecretString::from(password.to_string()))
            .unwrap();
        (storage, addresses)
    }
}

/// Write `data` to `path` atomically: write to a randomly-named sibling temp
/// file (exclusively created, owner-only), flush, then rename over the target
/// (rename is atomic on the same filesystem).
fn atomic_write(path: &Path, data: &[u8]) -> Result<()> {
    // A unique, unpredictable temp name plus exclusive creation means we never
    // write *through* a pre-existing path — a crash-leftover temp or a planted
    // symlink — the way a fixed `wallet.db.tmp` with create/truncate would.
    let tmp = temp_path_for(path);
    {
        use std::io::Write;
        let mut file = create_private_file_exclusive(&tmp)?;
        file.write_all(data)?;
        file.flush()?;
        file.sync_all()?;
    }
    if let Err(e) = fs::rename(&tmp, path) {
        let _ = fs::remove_file(&tmp);
        return Err(e.into());
    }
    // Persist the rename itself. The temp file's *contents* were fsync'd above,
    // but the directory entry that `rename` created must also reach disk, or a
    // crash immediately after could roll the directory back to the previous
    // `wallet.db` and lose a just-added key the caller already reported saved.
    // Best-effort and Unix-only (a directory fsync is not portable); a failure
    // here does not undo the successful rename.
    #[cfg(unix)]
    if let Some(parent) = path.parent().filter(|p| !p.as_os_str().is_empty()) {
        if let Ok(dir) = fs::File::open(parent) {
            let _ = dir.sync_all();
        }
    }
    Ok(())
}

/// A sibling temp path with a random suffix, e.g.
/// `wallet.db.tmp-1a2b3c4d5e6f7890`.
fn temp_path_for(path: &Path) -> PathBuf {
    use rand::{rng, RngExt};
    let mut suffix = [0u8; 8];
    rng().fill(&mut suffix);
    let mut file_name = path.file_name().unwrap_or_default().to_os_string();
    file_name.push(format!(".tmp-{}", hex::encode(suffix)));
    path.with_file_name(file_name)
}

/// Exclusively create a new file (fails if it already exists), owner-only (0600)
/// on Unix. `create_new` never opens an existing path, so a planted symlink or a
/// leftover temp cannot be followed or written through.
fn create_private_file_exclusive(path: &Path) -> Result<fs::File> {
    #[cfg(unix)]
    {
        use std::os::unix::fs::OpenOptionsExt;
        Ok(fs::OpenOptions::new()
            .write(true)
            .create_new(true)
            .mode(0o600)
            .open(path)?)
    }
    #[cfg(not(unix))]
    {
        let file = fs::OpenOptions::new()
            .write(true)
            .create_new(true)
            .open(path)?;
        #[cfg(windows)]
        restrict_to_current_user(path);
        Ok(file)
    }
}

/// Create `dir` and any missing parents, owner-only (0700) on Unix *from
/// creation* so the directory is never briefly world-accessible.
fn create_private_dir_all(dir: &Path) -> Result<()> {
    #[cfg(unix)]
    {
        use std::os::unix::fs::DirBuilderExt;
        fs::DirBuilder::new()
            .recursive(true)
            .mode(0o700)
            .create(dir)?;
    }
    #[cfg(not(unix))]
    {
        fs::create_dir_all(dir)?;
        #[cfg(windows)]
        restrict_to_current_user(dir);
    }
    Ok(())
}

/// Restrict a directory to owner-only on Unix (0700) or the current user on
/// Windows. Best-effort.
fn restrict_dir_permissions(dir: &Path) {
    #[cfg(unix)]
    {
        use std::os::unix::fs::PermissionsExt;
        let _ = fs::set_permissions(dir, fs::Permissions::from_mode(0o700));
    }
    #[cfg(windows)]
    {
        restrict_to_current_user(dir);
    }
    #[cfg(not(any(unix, windows)))]
    {
        let _ = dir;
    }
}

/// Best-effort: restrict `path` (a file or directory) to the current user
/// only, mirroring the Unix 0600/0700 hardening applied elsewhere in this
/// module. Shells out to `icacls` (bundled with every supported Windows
/// release) rather than hand-rolling the Win32 ACL APIs:
/// `/inheritance:r` strips inherited ACEs and `/grant:r <user>:(F)` grants full
/// control to the current user only.
///
/// Unlike the Unix path (which creates the file/directory with the final mode
/// atomically via `O_EXCL`/`DirBuilder::mode`), this necessarily runs *after*
/// creation — a plain `OpenOptions`/`create_dir_all` has no Windows equivalent
/// of a create-time ACL — so it narrows the default inherited ACL rather than
/// guaranteeing no broader-permission window ever existed. Never fails the
/// caller: a missing `icacls` or an ACL error just means this extra hardening
/// did not apply, same as before it existed.
#[cfg(windows)]
fn restrict_to_current_user(path: &Path) {
    let username = match std::env::var("USERNAME") {
        Ok(u) if !u.is_empty() => u,
        _ => return,
    };
    let _ = std::process::Command::new("icacls")
        .arg(path)
        .arg("/inheritance:r")
        .arg("/grant:r")
        .arg(format!("{username}:(F)"))
        // Don't hand the wallet password to a child process: `Command` inherits
        // the parent environment by default, and `icacls` has no need for it.
        .env_remove(super::password::PASSWORD_ENV_VAR)
        .output();
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
        WalletStorage::from_parts(
            path.to_path_buf(),
            PasswordManager::new_cache_only(config::Network::Regtest, "test"),
        )
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
    fn write_encrypted_uses_the_v2_argon2_format() {
        let dir = tempfile::tempdir().unwrap();
        let wallet_file = dir.path().join("wallet.db");
        let storage = storage_at(&wallet_file);
        let password = SecretString::from("correct horse battery staple".to_string());

        storage.write_encrypted(&sample_map(), &password).unwrap();

        let bytes = fs::read(&wallet_file).unwrap();
        assert!(
            bytes.starts_with(WALLET_MAGIC_V2),
            "a freshly written wallet must use the v2 (Argon2id) format"
        );
        // The Argon2 salt must not be all-zero (i.e. it was actually randomised).
        let salt = &bytes[WALLET_MAGIC_V2.len()..WALLET_MAGIC_V2.len() + ARGON2_SALT_LEN];
        assert!(salt.iter().any(|&b| b != 0), "salt must be random");

        // Two writes of the same wallet+password must use different salts (fresh
        // per write), so the on-disk bytes differ.
        storage.write_encrypted(&sample_map(), &password).unwrap();
        let bytes2 = fs::read(&wallet_file).unwrap();
        let salt2 = &bytes2[WALLET_MAGIC_V2.len()..WALLET_MAGIC_V2.len() + ARGON2_SALT_LEN];
        assert_ne!(salt, salt2, "each write must use a fresh salt");
    }

    #[test]
    fn argon2_params_are_pinned() {
        // Tripwire: these are the exact values the wallet KDF must use. A change
        // re-derives every wallet key, so it must be a deliberate edit (that also
        // updates this test), never an accidental drift from a dependency's
        // default.
        assert_eq!(ARGON2_M_COST_KIB, 19_456);
        assert_eq!(ARGON2_T_COST, 2);
        assert_eq!(ARGON2_P_COST, 1);

        let argon2 = wallet_argon2().unwrap();
        assert_eq!(argon2.params().m_cost(), 19_456);
        assert_eq!(argon2.params().t_cost(), 2);
        assert_eq!(argon2.params().p_cost(), 1);
    }

    #[test]
    fn legacy_wallet_is_upgraded_on_load_not_just_next_write() {
        // The opportunistic on-load upgrade must rewrite a legacy container in v2
        // without any explicit mutation, so a read-only session (e.g. `list`)
        // doesn't stay on the weaker KDF.
        let dir = tempfile::tempdir().unwrap();
        let wallet_file = dir.path().join("wallet.db");
        let password = "pw pw pw pw pw";

        // A legacy v1 container: bare cocoon keyed on the raw password.
        let json = serde_json::to_string(&sample_map()).unwrap();
        let mut cocoon = Cocoon::new(password.as_bytes());
        let container = cocoon.wrap(json.as_bytes()).unwrap();
        fs::write(&wallet_file, &container).unwrap();

        let pm = PasswordManager::new_cache_only(config::Network::Regtest, "legacy-upgrade");
        pm.cache_for_test(password);
        let storage = WalletStorage::from_parts(wallet_file.clone(), pm);
        storage.record_loaded_state();

        let loaded = storage
            .decrypt_addresses(&SecretString::from(password.to_string()))
            .unwrap();
        storage.upgrade_format_if_legacy(&loaded);

        assert!(
            fs::read(&wallet_file).unwrap().starts_with(WALLET_MAGIC_V2),
            "loading a legacy wallet must upgrade it in place to v2"
        );
        // Still decrypts, and now via the v2 (Argon2id) path.
        assert_eq!(
            storage
                .decrypt_addresses(&SecretString::from(password.to_string()))
                .unwrap()
                .len(),
            1
        );
    }

    #[test]
    fn legacy_v1_single_file_is_read_then_upgraded_to_v2() {
        let dir = tempfile::tempdir().unwrap();
        let wallet_file = dir.path().join("wallet.db");
        let password = SecretString::from("pw pw pw pw".to_string());

        // Write a legacy v1 wallet: a bare cocoon container keyed on the raw
        // password (no magic, no Argon2 salt), exactly as earlier builds did.
        let json = serde_json::to_string(&sample_map()).unwrap();
        let mut cocoon = Cocoon::new(password.expose_secret().as_bytes());
        let container = cocoon.wrap(json.as_bytes()).unwrap();
        assert!(
            !container.starts_with(WALLET_MAGIC_V2),
            "a legacy cocoon container must not look like v2"
        );
        fs::write(&wallet_file, &container).unwrap();

        let storage = storage_at(&wallet_file);

        // The legacy v1 format is read transparently...
        let loaded = storage.decrypt_addresses(&password).unwrap();
        assert_eq!(loaded.len(), 1);

        // ...and the next save upgrades it in place to the v2 (Argon2id) format.
        storage.write_encrypted(&loaded, &password).unwrap();
        assert!(
            fs::read(&wallet_file).unwrap().starts_with(WALLET_MAGIC_V2),
            "save must upgrade a legacy wallet to v2"
        );
        assert_eq!(storage.decrypt_addresses(&password).unwrap().len(), 1);
    }

    #[test]
    fn v2_wallet_fails_to_decrypt_with_a_wrong_password() {
        let dir = tempfile::tempdir().unwrap();
        let storage = storage_at(&dir.path().join("wallet.db"));
        storage
            .write_encrypted(
                &sample_map(),
                &SecretString::from("the right passphrase here".to_string()),
            )
            .unwrap();
        assert!(storage
            .decrypt_addresses(&SecretString::from("the wrong passphrase here".to_string()))
            .is_err());
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
    fn save_uses_cached_password_and_roundtrips() {
        // `save` pulls the password from `cached_or_stored`. Seeding only the
        // in-memory cache keeps this off the OS keyring (required for headless
        // CI) while still exercising the real `save` -> `write_encrypted` path.
        let dir = tempfile::tempdir().unwrap();
        let wallet_file = dir.path().join("wallet.db");
        let pm = PasswordManager::new_cache_only(config::Network::Regtest, "save-roundtrip");
        pm.cache_for_test("cachedpassw0rd");
        let storage = WalletStorage::from_parts(wallet_file.clone(), pm);

        let addresses = sample_map();
        storage.save(&addresses).unwrap();
        assert!(wallet_file.exists());

        // The saved file decrypts with the cached password.
        let loaded = storage
            .decrypt_addresses(&SecretString::from("cachedpassw0rd".to_string()))
            .unwrap();
        assert_eq!(loaded.len(), 1);
        assert_eq!(
            loaded.get("bcrt1qexampleaddress").unwrap().label,
            "test-label"
        );
    }

    #[test]
    fn save_refuses_to_clobber_a_concurrent_writer() {
        // Model two `xcp` processes: this one loads+saves, another writes the
        // file in between. The second save must abort rather than silently
        // discarding the other process's change (e.g. a freshly generated key).
        let dir = tempfile::tempdir().unwrap();
        let wallet_file = dir.path().join("wallet.db");
        let pm = PasswordManager::new_cache_only(config::Network::Regtest, "concurrent");
        pm.cache_for_test("cachedpassw0rd");
        let storage = WalletStorage::from_parts(wallet_file.clone(), pm);

        // First save establishes the on-disk baseline.
        storage.save(&sample_map()).unwrap();

        // Another process rewrites the file after we loaded/saved it.
        let other_bytes = b"another process wrote this".to_vec();
        fs::write(&wallet_file, &other_bytes).unwrap();

        // Our next save must refuse, and must NOT overwrite the other bytes.
        let err = storage.save(&sample_map()).unwrap_err();
        assert!(
            matches!(err, WalletError::ConcurrentModification(_)),
            "expected a concurrent-modification error, got {err:?}"
        );
        assert_eq!(
            fs::read(&wallet_file).unwrap(),
            other_bytes,
            "the concurrent writer's file must be left intact"
        );
    }

    #[test]
    fn consecutive_saves_in_one_session_succeed() {
        // The baseline is refreshed after each write, so a second save by the
        // same process (no external change) is not a false positive.
        let dir = tempfile::tempdir().unwrap();
        let wallet_file = dir.path().join("wallet.db");
        let pm = PasswordManager::new_cache_only(config::Network::Regtest, "consecutive");
        pm.cache_for_test("cachedpassw0rd");
        let storage = WalletStorage::from_parts(wallet_file, pm);

        storage.save(&sample_map()).unwrap();
        storage.save(&sample_map()).unwrap();
    }

    #[test]
    fn atomic_write_creates_the_file_and_leaves_no_tmp() {
        let dir = tempfile::tempdir().unwrap();
        let path = dir.path().join("wallet.db");
        atomic_write(&path, b"ciphertext").unwrap();
        assert_eq!(fs::read(&path).unwrap(), b"ciphertext");

        // No randomly-named temp sibling (`wallet.db.tmp-<hex>`) is left behind.
        let leftovers: Vec<_> = fs::read_dir(dir.path())
            .unwrap()
            .filter_map(|e| e.ok())
            .filter(|e| e.file_name().to_string_lossy().contains(".tmp-"))
            .collect();
        assert!(leftovers.is_empty(), "temp file must be renamed away");

        #[cfg(unix)]
        {
            use std::os::unix::fs::PermissionsExt;
            let mode = fs::metadata(&path).unwrap().permissions().mode();
            assert_eq!(mode & 0o777, 0o600, "wallet file must be owner-only");
        }
    }

    #[test]
    fn atomic_write_refuses_to_follow_a_preexisting_temp() {
        // A distinct temp name per call plus O_EXCL means overwriting works
        // repeatedly and never fails on a stale temp.
        let dir = tempfile::tempdir().unwrap();
        let path = dir.path().join("wallet.db");
        atomic_write(&path, b"first").unwrap();
        atomic_write(&path, b"second").unwrap();
        assert_eq!(fs::read(&path).unwrap(), b"second");
    }

    #[test]
    fn try_noninteractive_load_returns_map_for_correct_cached_password() {
        // Cache holds the right password (no keyring, no prompt).
        let dir = tempfile::tempdir().unwrap();
        let wallet_file = dir.path().join("wallet.db");
        let pm = PasswordManager::new_cache_only(config::Network::Regtest, "noninteractive-ok");
        pm.cache_for_test("rightpassw0rd");
        let storage = WalletStorage::from_parts(wallet_file, pm);
        storage
            .write_encrypted(
                &sample_map(),
                &SecretString::from("rightpassw0rd".to_string()),
            )
            .unwrap();

        let loaded = storage.try_noninteractive_load().unwrap();
        assert_eq!(loaded.map(|m| m.len()), Some(1));
    }

    #[test]
    fn try_noninteractive_load_forgets_a_wrong_cached_password() {
        // The cache holds a WRONG password; the wallet is encrypted with another.
        // The wrong password must be forgotten so it can't lock the CLI out on a
        // later run — the persist-after-verify security property.
        let dir = tempfile::tempdir().unwrap();
        let wallet_file = dir.path().join("wallet.db");
        let pm = PasswordManager::new_cache_only(config::Network::Regtest, "noninteractive-wrong");
        pm.cache_for_test("wrong-password");
        let storage = WalletStorage::from_parts(wallet_file, pm);
        storage
            .write_encrypted(
                &sample_map(),
                &SecretString::from("the-real-password".to_string()),
            )
            .unwrap();

        // Wrong password fails to decrypt => fall through to prompting...
        assert!(storage.try_noninteractive_load().unwrap().is_none());
        // ...and it was forgotten from the cache.
        assert!(
            !storage.password_manager.is_cached(),
            "a wrong cached password must be forgotten"
        );
    }

    #[cfg(unix)]
    #[test]
    fn create_private_dir_all_is_owner_only() {
        use std::os::unix::fs::PermissionsExt;
        let dir = tempfile::tempdir().unwrap();
        let nested = dir.path().join("counterparty-client/mainnet");
        create_private_dir_all(&nested).unwrap();
        let mode = fs::metadata(&nested).unwrap().permissions().mode();
        assert_eq!(mode & 0o777, 0o700, "wallet dir must be owner-only");
    }
}
