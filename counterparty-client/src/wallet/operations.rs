//! Wallet operations module.
//!
//! This module handles high-level operations on the wallet:
//! - Adding addresses
//! - Viewing addresses
//! - Listing all addresses
//! - Signing transactions

use bitcoin::secp256k1::Secp256k1;
use bitcoin::Network;
use secrecy::{ExposeSecret, SecretString};
use serde_json::{self, json, Value};
use std::path::Path;
use zeroize::Zeroizing;

use super::keys::{self, create_bitcoin_address};
use super::storage::WalletStorage;
use super::types::{AddressInfo, AddressMap, Result, WalletError};
use super::utils::{network_to_string, to_bitcoin_network};
use crate::bitcoinsigner;
use crate::config;

/// Main wallet structure for Bitcoin operations
pub struct BitcoinWallet {
    storage: WalletStorage,
    addresses: AddressMap,
    network: Network, // Bitcoin network type
}

impl BitcoinWallet {
    /// Initialize a new Bitcoin wallet
    ///
    /// This creates a new wallet or loads an existing one from the specified data directory.
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
        let (storage, addresses) = WalletStorage::init(data_dir, network)?;

        // Convert config::Network to bitcoin::Network using utility function
        let bitcoin_network = to_bitcoin_network(network);

        Ok(BitcoinWallet {
            storage,
            addresses,
            network: bitcoin_network,
        })
    }

    /// Add a new address to the wallet
    ///
    /// # Arguments
    ///
    /// * `private_key` - Optional private key as string
    /// * `mnemonic` - Optional mnemonic phrase
    /// * `path` - Optional derivation path
    /// * `label` - Optional label for the address
    /// * `address_type` - Optional address type ("bech32", "p2pkh", or "taproot")
    ///
    /// # Returns
    ///
    /// * `Result<(String, Option<Zeroizing<String>>)>` - The Bitcoin address
    ///   created, plus the freshly generated BIP39 mnemonic when the key was
    ///   randomly generated (so the caller can show it to the user for backup);
    ///   `None` for imported keys. The mnemonic is zeroized on drop.
    pub fn add_address(
        &mut self,
        private_key: Option<&str>,
        mnemonic: Option<&str>,
        path: Option<&str>,
        label: Option<&str>,
        address_type: Option<&str>,
    ) -> Result<(String, Option<Zeroizing<String>>)> {
        let secp = Secp256k1::new();

        // Determine the address type. An unrecognised value is rejected rather
        // than silently coerced to bech32, so a typo (e.g. "segwit", "P2PKH")
        // never yields a different address type than intended.
        let addr_type = match address_type {
            None | Some("bech32") => "bech32",
            Some("p2pkh") => "p2pkh",
            Some("taproot") => "taproot",
            Some(other) => {
                return Err(WalletError::Validation(format!(
                    "Unknown address type '{other}'. Use one of: bech32, p2pkh, taproot."
                )));
            }
        };

        // Generate keys based on provided parameters
        let mut key_data = match (private_key, mnemonic) {
            (Some(pk_str), _) => keys::generate_keys_from_private_key(pk_str, self.network, &secp)?,
            (None, Some(mnemonic_str)) => keys::generate_keys_from_mnemonic(
                mnemonic_str,
                path,
                addr_type,
                self.network,
                &secp,
            )?,
            (None, None) => keys::generate_new_keys(addr_type, self.network, &secp)?,
        };

        // Generate Bitcoin address
        let address = create_bitcoin_address(&key_data.public_key, addr_type, self.network)?;
        let address_str = address.to_string();

        // Create the label
        let final_label = match label {
            Some(l) => l.to_string(),
            None => format!("address{}", self.addresses.len() + 1),
        };

        // Labels double as `--address`/`--destination` aliases, so they must be
        // unambiguous: reject a label already used by a different address rather
        // than let it resolve to a HashMap-iteration-order-dependent (i.e.
        // non-deterministic) address on a later command. Re-importing the *same*
        // address keeps its existing label, so that is not a collision.
        if let Some((existing_addr, _)) = self
            .addresses
            .iter()
            .find(|(addr, info)| info.label == final_label && *addr != &address_str)
        {
            return Err(WalletError::Validation(format!(
                "label '{final_label}' is already used by address {existing_addr}; \
                 choose a different --label."
            )));
        }

        // Store the address information
        let address_info = AddressInfo {
            public_key: key_data.public_key.to_string(),
            private_key: SecretString::from(key_data.private_key.to_string()),
            label: final_label,
            address_type: addr_type.to_string(),
        };

        // The WIF now lives in `address_info.private_key` (a zeroizing
        // `SecretString`); wipe the raw secret still held in `key_data.private_key`
        // (`PrivateKey`/`SecretKey` are `Copy`, not zeroize-on-drop). The mnemonic
        // (returned below) is a separate, already-`Zeroizing` field.
        key_data.private_key.inner.non_secure_erase();

        self.addresses.insert(address_str.clone(), address_info);
        self.storage.save(&self.addresses)?;

        Ok((address_str, key_data.mnemonic))
    }

    /// Show details of a specific address
    ///
    /// # Arguments
    ///
    /// * `address` - The Bitcoin address to show
    /// # Returns
    ///
    /// * `Result<Value>` - JSON object with the address's **non-secret** details.
    ///   The private key is never embedded here — use [`export_wif`](Self::export_wif)
    ///   for the explicit, confirmation-gated reveal, so a WIF never lands in a
    ///   long-lived, un-zeroized `serde_json::Value`.
    pub fn show_address(&self, address: &str) -> Result<Value> {
        let address_info = self
            .addresses
            .get(address)
            .ok_or_else(|| WalletError::AddressNotFound(address.to_string()))?;

        Ok(json!({
            "address": address,
            "public_key": address_info.public_key,
            "label": address_info.label,
            "address_type": address_info.address_type,
            "network": network_to_string(self.network),
        }))
    }

    /// Resolve a user-supplied `--address`/`--source`/`--destination` value that
    /// may be a wallet *label* into the underlying address.
    ///
    /// * If `input` is already a wallet address, it is returned unchanged.
    /// * If `input` uniquely matches the label of one wallet address, that
    ///   address is returned.
    /// * Otherwise (no match, or — defensively — an ambiguous match) `input` is
    ///   returned unchanged, so a raw address or an *external* destination that is
    ///   not in the wallet passes straight through.
    ///
    /// Labels are unique per wallet (enforced in [`add_address`](Self::add_address)),
    /// so the ambiguous case does not arise in practice; passing the input through
    /// unchanged is the safe fallback either way.
    pub fn resolve_label_or_address(&self, input: &str) -> String {
        if self.addresses.contains_key(input) {
            return input.to_string();
        }
        let mut matches = self
            .addresses
            .iter()
            .filter(|(_, info)| info.label == input)
            .map(|(addr, _)| addr);
        match (matches.next(), matches.next()) {
            (Some(addr), None) => addr.clone(),
            _ => input.to_string(),
        }
    }

    /// Return an address's private key (WIF) in a [`Zeroizing`] buffer that is
    /// wiped on drop. Kept separate from [`show_address`](Self::show_address) so
    /// the secret is copied out of its `SecretString` only on the explicit,
    /// confirmation-gated export path, and the caller can serialize it at the last
    /// moment and drop it promptly. (Exporting inherently prints the WIF, so the
    /// final on-screen/serialized output is plaintext by design; this just keeps
    /// the in-memory handling tight.)
    pub fn export_wif(&self, address: &str) -> Result<Zeroizing<String>> {
        let address_info = self
            .addresses
            .get(address)
            .ok_or_else(|| WalletError::AddressNotFound(address.to_string()))?;
        Ok(Zeroizing::new(
            address_info.private_key.expose_secret().to_string(),
        ))
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
                "network": network_to_string(self.network),
            }));
        }

        Ok(result)
    }

    /// Sign a raw Bitcoin transaction
    ///
    /// This method signs an unsigned transaction with private keys from the wallet.
    /// It supports P2PKH, P2WPKH (bech32), P2SH, P2SH-P2WPKH, P2WSH and P2TR
    /// (key- and script-path) inputs.
    ///
    /// # Arguments
    ///
    /// * `raw_tx_hex` - Unsigned transaction in hexadecimal format
    /// * `utxos` - Vector of (script_pubkey_hex, amount_in_satoshis) pairs for each input
    ///
    /// # Returns
    ///
    /// * `Result<String>` - Signed transaction in hexadecimal format or error
    pub fn sign_transaction(
        &self,
        raw_tx_hex: &str,
        utxos: &bitcoinsigner::UTXOList,
    ) -> Result<String> {
        bitcoinsigner::sign_transaction(&self.addresses, raw_tx_hex, utxos, self.network)
    }

    /// Change the wallet encryption password.
    ///
    /// The wallet was already unlocked when it was loaded (via the keyring, the
    /// `XCP_WALLET_PASSWORD` env var, or an interactive prompt), so this does
    /// **not** re-prompt for the current password. It prompts for the new
    /// password (twice, with a confirmation and the strength check), re-encrypts
    /// the wallet to disk with it, and only then updates the stored password — so
    /// a failed write can never leave the keyring and the file out of sync.
    ///
    /// # Returns
    ///
    /// * `Result<()>` - Success or error
    pub fn change_password(&mut self) -> Result<()> {
        self.storage.change_password(&self.addresses)
    }

    /// Disconnect the wallet by clearing the password
    ///
    /// This method removes the wallet password from the system keyring
    /// and from the in-memory cache, effectively "disconnecting" the wallet.
    ///
    /// # Returns
    ///
    /// * `Result<()>` - Success or error
    pub fn disconnect(&mut self) -> Result<()> {
        self.storage.clear_password()
    }
}

#[cfg(test)]
impl BitcoinWallet {
    /// Test-only: build a wallet backed by a temp `data_dir` with its password
    /// seeded into the in-memory cache, so `add_address`/`save` work without the
    /// OS keyring or an interactive prompt.
    pub(crate) fn new_for_test<P: AsRef<Path>>(data_dir: P, network: config::Network) -> Self {
        let (storage, addresses) =
            WalletStorage::new_for_test(&data_dir, network, "test-pass-123456");
        BitcoinWallet {
            storage,
            addresses,
            network: to_bitcoin_network(network),
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::config::Network;

    // The canonical all-zero BIP39 test vector; derives deterministic addresses.
    const TEST_MNEMONIC: &str =
        "abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about";

    fn wallet() -> (BitcoinWallet, tempfile::TempDir) {
        let dir = tempfile::tempdir().unwrap();
        let w = BitcoinWallet::new_for_test(dir.path(), Network::Regtest);
        (w, dir)
    }

    /// A deterministic regtest WIF, derived from a fixed secret.
    fn regtest_wif(seed: u8) -> String {
        let sk = bitcoin::secp256k1::SecretKey::from_slice(&[seed; 32]).unwrap();
        bitcoin::PrivateKey::new(sk, bitcoin::Network::Regtest).to_wif()
    }

    #[test]
    fn add_random_bech32_address_returns_mnemonic_and_persists() {
        let (mut w, _dir) = wallet();
        let (addr, mnemonic) = w.add_address(None, None, None, None, None).unwrap();

        assert!(
            addr.starts_with("bcrt1q"),
            "expected regtest p2wpkh, got {addr}"
        );
        // A fresh random key surfaces its backup mnemonic exactly once.
        assert!(mnemonic.is_some());

        let list = w.list_addresses().unwrap();
        assert_eq!(list.len(), 1);
        assert_eq!(list[0]["address"], addr);
        assert_eq!(list[0]["address_type"], "bech32");
        assert_eq!(list[0]["network"], "regtest");
        // Auto-generated label when none supplied.
        assert_eq!(list[0]["label"], "address1");
    }

    #[test]
    fn add_random_p2pkh_and_taproot_addresses() {
        let (mut w, _dir) = wallet();

        let (p2pkh, _) = w
            .add_address(None, None, None, Some("legacy"), Some("p2pkh"))
            .unwrap();
        // Regtest legacy addresses start with m or n.
        assert!(
            p2pkh.starts_with('m') || p2pkh.starts_with('n'),
            "expected regtest p2pkh, got {p2pkh}"
        );

        let (taproot, _) = w
            .add_address(None, None, None, Some("tr"), Some("taproot"))
            .unwrap();
        assert!(
            taproot.starts_with("bcrt1p"),
            "expected regtest p2tr, got {taproot}"
        );
    }

    #[test]
    fn add_address_rejects_unknown_address_type() {
        let (mut w, _dir) = wallet();
        // A typo must be rejected, not silently coerced to bech32.
        let err = w
            .add_address(None, None, None, None, Some("segwit"))
            .unwrap_err();
        assert!(
            err.to_string().contains("Unknown address type"),
            "got: {err}"
        );
        // Nothing was persisted.
        assert_eq!(w.list_addresses().unwrap().len(), 0);
    }

    #[test]
    fn import_from_private_key_has_no_mnemonic() {
        let (mut w, _dir) = wallet();
        let (addr, mnemonic) = w
            .add_address(Some(&regtest_wif(7)), None, None, None, None)
            .unwrap();
        assert!(addr.starts_with("bcrt1q"), "got {addr}");
        // Imported keys never echo a mnemonic back.
        assert!(mnemonic.is_none());
    }

    #[test]
    fn passing_a_mnemonic_as_a_private_key_is_rejected() {
        // The mnemonic must go through the dedicated `mnemonic` parameter; it is
        // not a valid WIF and must not be silently accepted as a private key.
        let (mut w, _dir) = wallet();
        assert!(w
            .add_address(Some(TEST_MNEMONIC), None, None, None, None)
            .is_err());
    }

    #[test]
    fn import_from_mnemonic_is_deterministic_and_has_no_mnemonic() {
        let (mut w1, _d1) = wallet();
        let (a1, m1) = w1
            .add_address(None, Some(TEST_MNEMONIC), None, None, None)
            .unwrap();
        // The user already holds this seed; it is not echoed back.
        assert!(m1.is_none());

        // The same mnemonic in a fresh wallet yields the same address.
        let (mut w2, _d2) = wallet();
        let (a2, _) = w2
            .add_address(None, Some(TEST_MNEMONIC), None, None, None)
            .unwrap();
        assert_eq!(a1, a2);
    }

    #[test]
    fn labels_default_incrementally_and_respect_overrides() {
        let (mut w, _dir) = wallet();
        w.add_address(None, None, None, None, None).unwrap();
        w.add_address(None, None, None, Some("savings"), None)
            .unwrap();
        w.add_address(None, None, None, None, None).unwrap();

        let labels: Vec<String> = w
            .list_addresses()
            .unwrap()
            .iter()
            .map(|e| e["label"].as_str().unwrap().to_string())
            .collect();
        assert!(labels.contains(&"address1".to_string()));
        assert!(labels.contains(&"savings".to_string()));
        // The third address is numbered by the current wallet size (3).
        assert!(labels.contains(&"address3".to_string()));
    }

    #[test]
    fn duplicate_label_on_a_different_address_is_rejected() {
        let (mut w, _dir) = wallet();
        w.add_address(None, None, None, Some("cold"), None).unwrap();
        // A second, different address reusing the same label must be refused, so
        // `--address cold` can never resolve ambiguously.
        let err = w
            .add_address(None, None, None, Some("cold"), None)
            .unwrap_err();
        assert!(err.to_string().contains("already used"), "got: {err}");
        // Only the first address was stored.
        assert_eq!(w.list_addresses().unwrap().len(), 1);
    }

    #[test]
    fn reimporting_the_same_address_keeps_its_label_without_a_collision() {
        // Re-importing the identical key/label is idempotent, not a collision.
        let (mut w, _dir) = wallet();
        let wif = regtest_wif(3);
        w.add_address(Some(&wif), None, None, Some("savings"), None)
            .unwrap();
        w.add_address(Some(&wif), None, None, Some("savings"), None)
            .unwrap();
        assert_eq!(w.list_addresses().unwrap().len(), 1);
    }

    #[test]
    fn show_address_never_includes_private_key() {
        let (mut w, _dir) = wallet();
        let (addr, _) = w.add_address(None, None, None, None, None).unwrap();

        let public = w.show_address(&addr).unwrap();
        assert_eq!(public["address"], addr);
        assert_eq!(public["network"], "regtest");
        assert!(
            public.get("private_key").is_none(),
            "show_address must never embed the private key"
        );
    }

    #[test]
    fn resolve_label_or_address_maps_labels_and_passes_through_others() {
        let (mut w, _dir) = wallet();
        let (addr, _) = w
            .add_address(None, None, None, Some("savings"), None)
            .unwrap();

        // A label resolves to its address.
        assert_eq!(w.resolve_label_or_address("savings"), addr);
        // An existing address passes through unchanged.
        assert_eq!(w.resolve_label_or_address(&addr), addr);
        // An unknown value (e.g. an external destination address) passes through.
        assert_eq!(
            w.resolve_label_or_address("bcrt1qexternaldestination"),
            "bcrt1qexternaldestination"
        );
    }

    #[test]
    fn export_wif_returns_the_private_key() {
        let (mut w, _dir) = wallet();
        let (addr, _) = w.add_address(None, None, None, None, None).unwrap();

        let wif = w.export_wif(&addr).unwrap();
        assert!(!wif.is_empty(), "export_wif must return the WIF");
        // It must match the stored secret for that address.
        assert_eq!(
            wif.as_str(),
            w.addresses.get(&addr).unwrap().private_key.expose_secret()
        );
    }

    #[test]
    fn show_address_unknown_returns_not_found() {
        let (w, _dir) = wallet();
        let err = w.show_address("bcrt1qdoesnotexist").unwrap_err();
        assert!(matches!(err, WalletError::AddressNotFound(_)));
        assert!(matches!(
            w.export_wif("bcrt1qdoesnotexist").unwrap_err(),
            WalletError::AddressNotFound(_)
        ));
    }

    #[test]
    fn add_address_persists_encrypted_wallet_to_disk() {
        // NB: the reload/decrypt path is exercised in `storage.rs`; here we stay
        // keyring-free (the whole suite must run on headless Linux CI, which has
        // no Secret Service) and only assert that `add_address` -> `save` wrote
        // an encrypted store to disk.
        let dir = tempfile::tempdir().unwrap();
        let mut w = BitcoinWallet::new_for_test(dir.path(), Network::Regtest);
        w.add_address(None, None, None, Some("keep"), None).unwrap();

        let bytes = std::fs::read(dir.path().join("wallet.db")).unwrap();
        assert!(!bytes.is_empty(), "wallet file should have been written");
        // A cocoon container is binary, not the plaintext JSON address map.
        assert!(
            !bytes.starts_with(b"{"),
            "wallet file must be encrypted, not plaintext JSON"
        );
    }

    #[test]
    fn sign_transaction_rejects_garbage_hex() {
        let (w, _dir) = wallet();
        let utxos = bitcoinsigner::UTXOList::new();
        assert!(w.sign_transaction("not-hex", &utxos).is_err());
    }
}
